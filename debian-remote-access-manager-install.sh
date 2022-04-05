#!/bin/bash

#Requisitos

#1 - Reservar IP externo fixo ao futuro servidor
#2 - Ter definido o dominio que será usando no manager. Ex.: manager.devops.gpa.digital
#3 - Criar entrada do domínio escolhido no DNS apontando para o IP fixo reservado
#4 - Abrir as portas 80 e 443 para a internet


# Variáveis de ambiente

GUACVERSION=`curl -s https://raw.githubusercontent.com/apache/guacamole-server/master/configure.ac | grep 'AC_INIT([guacamole-server]*' | awk -F'[][]' -v n=2 '{ print $(2*n) }'` # Latest is 1.4.0
TOTP_TITLE="GPA Remote Access Manager"
GUACPWD="brpassHGd36fy6q6eu4438"
MYSQLPWD="HGd36fy6q6eu4438"
HOME_PAGE_DIR=/var/lib/tomcat9/webapps
DOMAIN=manager.devops.gpa.digital
EMAIL="fernando.sousa@brlink.com.br"

#### Início do script ####

## Atualizando servidor e instalando pacotes necessários.

sudo bash -c 'echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list.d/backports.list'
sudo apt update
apt -y -t buster-backports install freerdp2-dev libpulse-dev xrdp
sudo apt-get install -y lxde-core chromium nginx python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface python3-certbot-nginx 
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp

###########

## Instalando Guacamole

echo "Instalando o Guacamole..."
wget https://git.io/fxZq5 -O guac-install.sh
sudo chmod +x guac-install.sh
sudo ./guac-install.sh --mysqlpwd $MYSQLPWD --guacpwd $GUACPWD  --totp --installmysql


## Instalando plugin LDAP

echo " Instalando LDAP plugin..."
wget https://apache.org/dyn/closer.lua/guacamole/$GUACVERSION/binary/guacamole-auth-ldap-$GUACVERSION.tar.gz?action=download -O /tmp/guacamole-auth-ldap-$GUACVERSION.tar.gz
tar -zxvf /tmp/guacamole-auth-ldap-$GUACVERSION.tar.gz -C /tmp/
mv /tmp/guacamole-auth-ldap-$GUACVERSION/guacamole-auth-ldap-$GUACVERSION.jar /etc/guacamole/extensions/
rm -rf /tmp/guacamole-auth-ldap-$GUACVERSION*

## Customizando Home Page

echo "Configurações customizadas..."
sudo chmod 666 /etc/guacamole/guacamole.properties
echo "totp-issuer: $TOTP_TITLE" >> /etc/guacamole/guacamole.properties
sudo chmod 544 /etc/guacamole/guacamole.properties

sudo mv $HOME_PAGE_DIR/ROOT $HOME_PAGE_DIR/ROOT-default
sudo mv $HOME_PAGE_DIR/guacamole $HOME_PAGE_DIR/ROOT

sudo chmod 666 $HOME_PAGE_DIR/ROOT/translations/en.json
sudo sed -i "s,Apache Guacamole,$TOTP_TITLE,g" $HOME_PAGE_DIR/ROOT/translations/en.json
sudo chmod 544 $HOME_PAGE_DIR/ROOT/translations/en.json

echo "Reinciando serviços..."
sudo service tomcat9 restart
sleep 5
sudo service guacd restart

## Configurando NGINX

echo "Configurando NGINX com proxy reverso..."


sudo chmod 777 /etc/nginx/sites-available
cat <<"EOF" > /etc/nginx/sites-available/$DOMAIN.conf
server {
  listen 80;

  server_name  DOMAIN;
  access_log /var/log/nginx/DOMAIN-access.log;
  error_log /var/log/nginx/DOMAIN-error.log;

  location / {
        proxy_pass http://127.0.0.1:8080;
  }
}
EOF

sudo sed -i "s,DOMAIN,$DOMAIN,g" /etc/nginx/sites-available/$DOMAIN.conf
sudo chmod 755 /etc/nginx/sites-available

sudo ln -fs /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

###

echo "Configurando ambiente..."
sudo ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
sudo chmod 666 /etc/profile
sudo echo 'alias l="ls -la --color"' >> /etc/profile
sudo chmod 544 /etc/profile


###

echo "Instalando certificado digital com Let's Encrypt"
sudo certbot --nginx -d $DOMAIN -m $EMAIL --agree-tos -n

cat <<"EOF" > /etc/nginx/sites-available/$DOMAIN.conf
server {
    listen       35443 ssl http2;
    listen       [::]:35443 ssl http2; 
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  DOMAIN;

    access_log  /var/log/nginx/guacamole.access.log;
    error_log   /var/log/nginx/guacamole.error.log;
    
    # SSL
    ssl_certificate      /etc/letsencrypt/live/DOMAIN/fullchain.pem;
    ssl_certificate_key  /etc/letsencrypt/live/DOMAIN/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/DOMAIN/chain.pem;
    ssl_session_timeout  5m;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_ecdh_curve X25519:prime256v1:secp384r1:secp521r1;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8;

    location / {
      proxy_pass http://127.0.0.1:8080;
      proxy_buffering off;
      proxy_http_version 1.1;
      proxy_set_header Host              $host;
      proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header X-Real-IP         $remote_addr;
      proxy_set_header X-Forwarded-Host  $host;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Port  $server_port;
      client_max_body_size 1g;
      access_log off;
  }
}
# enforce HTTPS
server {
    listen       80;
    listen       [::]:80;
    server_name  DOMAIN;
    return 301   https://$host$request_uri;
}
EOF

sudo sed -i "s,DOMAIN,$DOMAIN,g" /etc/nginx/sites-available/$DOMAIN.conf
sudo sed -i "s,# server_tokens off;,server_tokens off;,g" /etc/nginx/nginx.conf

sudo chmod 755 /etc/nginx/sites-available 
sudo service nginx restart 


###
echo "Criando usuários locais no servidor Manager..."

BR_USERS="brlink1 brlink2 brlink3"

for i in $BR_USERS; do
    sudo useradd $i --group netdev -m
done

#### Fim do script ####
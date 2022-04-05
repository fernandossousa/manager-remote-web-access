#!/bin/bash

#Requisitos

#1 - Ativar o SSO na Azure, seguido este post: https://sintax.medium.com/apache-guacamole-with-azure-ad-using-saml-5d890c7e08bf
#2 - Manter o mesmo dominio/URL que será usando no manager. Ex.: https://manager.exemplo.com
#3 - Adquirir o URL do Login Azure. Vide procedmento no link acima
#4 - Para ativar o SSO é preciso remover o plugin do TOPT para MFA.

# Variáveis de ambiente

DOMAIN="manager.devops.gpa.digital"
AZURE_LOGIN_URL="https://login.microsoftonline.com/359e86d1-c21e-4cf1-bccd-904360e711c1/saml2"

### NÃO ALTERAR NADA DAQUI PARA BAIXO

# Variáveis Globais # 
GUAC_PLUGIN_VERSION="1.3.0"
GUAC_PLUGIN_LINK="https://archive.apache.org/dist/guacamole/$GUAC_PLUGIN_VERSION/binary/guacamole-auth-saml-$GUAC_PLUGIN_VERSION.tar.gz"
GUAC_HOME_DIR="/etc/guacamole"
DIR_TMP="/tmp"
HOME_PAGE_DIR="/var/lib/tomcat9/webapps"


#### Início do script ####

## Instalando plugin para aunteticação SSO.

wget $GUAC_PLUGIN_LINK -O $DIR_TMP/guacamole-auth-saml-$GUAC_PLUGIN_VERSION.tar.gz
tar zxvf $DIR_TMP/guacamole-auth-saml-$GUAC_PLUGIN_VERSION.tar.gz -C $DIR_TMP/
mv -f /tmp/guacamole-auth-saml-$GUAC_PLUGIN_VERSION/guacamole-auth-saml-$GUAC_PLUGIN_VERSION.jar $GUAC_HOME_DIR/extensions
rm -rf /tmp/guacamole-auth-saml-$GUAC_PLUGIN_VERSION* 

## Configurando arquivo para aunteticação SSO

sudo chmod 777 $GUAC_HOME_DIR/guacamole.properties
cat <<EOF >> $GUAC_HOME_DIR/guacamole.properties

# SSO Configuration
saml-idp-url: $AZURE_LOGIN_URL
saml-entity-id: https://$DOMAIN
saml-callback-url: https://$DOMAIN
extension-priority: *, saml
EOF

## Desativando TOTP (MFA)

sudo sed -i "s,totp-issuer:,#totp-issuer,g" $GUAC_HOME_DIR/guacamole.properties
sudo mkdir $GUAC_HOME_DIR/extensions-unused
sudo mv $GUAC_HOME_DIR/extensions/guacamole-auth-totp* $GUAC_HOME_DIR/extensions-unused/
sudo chmod 644 $GUAC_HOME_DIR/guacamole.properties
sudo systemctl restart tomcat9 && sudo systemctl restart guacd
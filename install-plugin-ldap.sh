#!/bin/bash

#Requisitos

#1 - Configuração básica de LDAP seguindo este post: https://traviswhitney.com/2019/08/21/configuring-apache-guacamole-with-ldap-and-2fa/
#2 - Manter o mesmo dominio/URL que será usando no manager. Ex.: https://manager.exemple.com


# Variáveis de ambiente

DOMAIN="manager.exemple.com"
LDAP_DOMAIN="dc.example.com"
LDAP_PORT="389"
LDAP_USER_BASE_DN="OU=Users,DC=dc,DC=exemple,DC=com"
LDAP_CONFIG_BASE_DN="OU=Users,DC=dc,DC=exemple,DC=com"
LDAP_SEARCH_BIND_PASS_READONLY="US3rP4$$w0rD"
LDAP_SEARCH_BIND_DN="CN=ReadOnly,OU=Users,DC=dc,DC=exemple,DC=com"



### NÃO ALTERAR NADA DAQUI PARA BAIXO

# Variáveis Globais # 
GUAC_HOME_DIR="/etc/guacamole"
DIR_TMP="/tmp"
HOME_PAGE_DIR="/var/lib/tomcat9/webapps"


#### Início do script ####

## Configurando arquivo para aunteticação LDAP

sudo chmod 777 $GUAC_HOME_DIR/guacamole.properties
cat <<EOF >> $GUAC_HOME_DIR/guacamole.properties

# LDAP Configuration
auth-provider: net.sourceforge.guacamole.net.auth.ldap.LDAPAuthenticationProvider
ldap-hostname:           $LDAP_DOMAIN
ldap-port:               $LDAP_PORT
ldap-user-base-dn:       $LDAP_USER_BASE_DN
ldap-username-attribute: samAccountName
ldap-config-base-dn:     $LDAP_CONFIG_BASE_DN
ldap-encryption-method:  none
ldap-search-bind-password: $LDAP_SEARCH_BIND_PASS_READONLY AAAQAKUoBo4ys/ZjHNhY0eAyLAyH3t8BIky1iDZZgKZ511R1YmuRNjvGo4bCgoZJ2ZyVY23aezy7L5x8wJQvHlzZ2r4AAQID
ldap-search-bind-dn:     $LDAP_SEARCH_BIND_DN

EOF

sudo chmod 644 $GUAC_HOME_DIR/guacamole.properties
sudo systemctl restart tomcat9 && sudo systemctl restart guacd
#!/usr/bin/bash

sudo apt update

DOMAIN="meg.corp"
BASEDN="dc=meg,dc=corp"
ADMINPW="admin"

# Préconfiguration
echo "slapd slapd/internal/adminpw password $ADMINPW" | debconf-set-selections
echo "slapd slapd/internal/generated_adminpw password $ADMINPW" | debconf-set-selections
echo "slapd slapd/password1 password $ADMINPW" | debconf-set-selections
echo "slapd slapd/password2 password $ADMINPW" | debconf-set-selections
echo "slapd slapd/domain string $DOMAIN" | debconf-set-selections
echo "slapd shared/organization string Example Inc." | debconf-set-selections
echo "slapd slapd/backend select MDB" | debconf-set-selections
echo "slapd slapd/no_configuration boolean false" | debconf-set-selections
echo "slapd slapd/purge_database boolean true" | debconf-set-selections
echo "slapd slapd/move_old_database boolean true" | debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils

ldapadd -x -D "cn=admin,dc=meg,dc=corp" -W -f base.ldif
ldapadd -x -D "cn=admin,dc=meg,dc=corp" -W -f users.ldif
ldapadd -x -D "cn=admin,dc=meg,dc=corp" -W -f groups.ldif


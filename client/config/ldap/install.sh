#!usr/bin/bash

# Variables LDAP (à personnaliser)
LDAP_SERVER="ldap://192.168.1.1"
BASE_DN="dc=meg,dc=corp"
LDAP_BINDDN="cn=admin,dc=meg,dc=corp"
LDAP_PASSWORD="admin"
LDAP_VERSION="3"

echo "ldap-auth-config    ldap-auth-config/ldapns/ldap-server    string  $LDAP_SERVER" | debconf-set-selections
echo "ldap-auth-config    ldap-auth-config/ldapns/base-dn        string  $BASE_DN" | debconf-set-selections
echo "ldap-auth-config    ldap-auth-config/ldapns/ldap_version   select  $LDAP_VERSION" | debconf-set-selections
echo "ldap-auth-config    ldap-auth-config/dbrootlogin           boolean false" | debconf-set-selections
echo "ldap-auth-config    ldap-auth-config/rootbinddn            string  $LDAP_BINDDN" | debconf-set-selections
echo "ldap-auth-config    ldap-auth-config/pam_password          select  md5" | debconf-set-selections
echo "libpam-runtime      libpam-runtime/profiles                select  [unix, ldap]" | debconf-set-selections

echo "libnss-ldap        libnss-ldap/rootbindpw password $LDAP_PASSWORD" | debconf-set-selections
echo "libpam-ldap        libpam-ldap/rootbindpw password $LDAP_PASSWORD" | debconf-set-selections

export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt install -y libnss-ldap libpam-ldap ldap-utils nscd

systemctl enable nscd
systemctl restart nscd


sudo echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session

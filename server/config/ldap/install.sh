!/usr/bin/bash

sudo apt update
sudo apt install requirements.txt

ldapadd -x -D "cn=admin,dc=meg,dc=corp" -W -f base.ldif
ldapadd -x -D "cn=admin,dc=meg,dc=corp" -W -f users.ldif
ldapadd -x -D "cn=admin,dc=meg,dc=corp" -W -f groups.ldif


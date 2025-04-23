#!/bin/bash

echo "================================================"
echo "Début installation paquets htop net-tools dnsmasq pxelinux"
echo "================================================"

apt -y update
apt install -y htop net-tools dnsmasq pxelinux

systemctl start dnsmasq

echo -n "Vérification de l'état du service dnsmasq: "
if systemctl is-active dnsmasq > /dev/null; then
  echo -e "OK"
else
  echo -e "ECHEC dnsmasq"
fi

# Copier les fichiers d'amorçage PXE
cp /usr/lib/PXELINUX/pxelinux.0 /srv/tftp/
cp /usr/lib/syslinux/modules/bios/*.c32 /srv/tftp/

cp dnsmasq.conf /etc/dnsmasq.conf
cp pxe-tftp.conf /srv/tftp/pxelinux.cfg/default
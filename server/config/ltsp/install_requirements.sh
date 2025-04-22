#!/usr/bin/env bash

echo "Installing requirements..."

wget https://ltsp.org/misc/ltsp-ubuntu-ppa-focal.list -O /etc/apt/sources.list.d/ltsp-ubuntu-ppa-focal.list
wget https://ltsp.org/misc/ltsp_ubuntu_ppa.gpg -O /etc/apt/trusted.gpg.d/ltsp_ubuntu_ppa.gpg

apt update

apt install --install-recommends -yy \
    ltsp \
    ltsp-binaries \
    dnsmasq \
    nfs-kernel-server \
    openssh-server \
    squashfs-tools \
    ethtool \
    net-tools \
    epoptes

echo -e "\nDone!"
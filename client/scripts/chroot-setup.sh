#!/bin/bash
# scripts/chroot-setup.sh - Sets up the system inside the chroot with non-interactive configuration

set -e

echo "Setting up Debian 12 with LXQT in chroot environment..."

# Configure environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Pre-configure console-setup to avoid interactive prompts
echo "console-setup console-setup/charmap select UTF-8" | debconf-set-selections
echo "console-setup console-setup/codeset47 select Guess optimal character set" | debconf-set-selections
echo "console-setup console-setup/fontface47 select Fixed" | debconf-set-selections
echo "console-setup console-setup/fontsize-text47 select 16" | debconf-set-selections
echo "console-setup console-setup/fontsize-fb47 select 16" | debconf-set-selections
echo "console-setup console-setup/fontsize string 16" | debconf-set-selections
echo "console-setup console-setup/codesetcode string guess" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/variant select English (US)" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/layout select English (US)" | debconf-set-selections
echo "keyboard-configuration keyboard-configuration/model select Generic 105-key PC" | debconf-set-selections

# Update package information
apt-get update

# Install debconf-utils first to help with non-interactive setup
apt-get install -y --no-install-recommends debconf-utils

# Install essential system packages
apt-get install -y --no-install-recommends \
  linux-image-amd64 \
  locales \
  console-setup \
  keyboard-configuration \
  network-manager \
  openssh-server \
  sudo \
  systemd-sysv \
  dbus \
  iproute2 \
  firmware-linux-free \
  zstd \
  firmware-realtek

# Configure locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/default/locale

# Install LXQT desktop (minimal installation)
apt-get install -y --no-install-recommends \
  lxqt-core \
  lxqt-admin \
  lxqt-panel \
  lxqt-qtplugin \
  lxqt-session \
  lxqt-themes \
  qterminal \
  pcmanfm-qt \
  sddm \
  xserver-xorg-core \
  xserver-xorg-input-all \
  xserver-xorg-video-all \
  mesa-utils

# LTSP specific packages
apt-get install -y --no-install-recommends \
  ethtool \
  nfs-common \
  ldap-utils \
  openssl \
  ca-certificates

# Enable SDDM display manager
systemctl enable sddm.service

# Create a regular user for testing (optional)
adduser --gecos "" --disabled-password ltsp-user
echo "ltsp-user:password" | chpasswd
usermod -aG sudo ltsp-user

# Update initramfs
update-initramfs -u

# Install GRUB for EFI boot (preferred for LTSP)
apt-get install -y --no-install-recommends grub-efi-amd64
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --no-nvram

# Update GRUB configuration
update-grub

# Enable SSH access
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl enable ssh

# Configure network-manager
cat > /etc/NetworkManager/NetworkManager.conf << ENDNM
[main]
plugins=ifupdown,keyfile
dhcp=internal

[ifupdown]
managed=true
ENDNM

# Add firmware for Realtek adapters
mkdir -p /lib/firmware/rtl_nic/
# Note: In a production environment, you would download the actual firmware files
# This is just to prevent the warnings during image build

# Disable unnecessary services
systemctl disable ModemManager.service || true
systemctl disable wpa_supplicant.service || true
systemctl disable bluetooth.service || true

# Remove unnecessary packages
apt-get autoremove -y
apt-get clean

# Clean up system
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/apt/archives/*.deb

echo "Chroot setup completed!"
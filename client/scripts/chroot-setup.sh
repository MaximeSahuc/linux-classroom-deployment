#!/bin/bash
# scripts/chroot-setup.sh - Sets up the system inside the chroot with proper boot configuration

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

# Read the loop device name passed from the build script
LOOP_DEVICE=$(cat /loop_device_info)
DISK_DEVICE=$(echo $LOOP_DEVICE | sed 's/\/dev\///')

# Install both GRUB for BIOS and EFI for maximum compatibility
echo "Installing GRUB for BIOS and EFI boot..."

# Install for BIOS boot
apt-get install -y --no-install-recommends grub-pc
grub-install --target=i386-pc --boot-directory=/boot --recheck "${LOOP_DEVICE}"

# Install for EFI boot
apt-get install -y --no-install-recommends grub-efi-amd64
grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot --bootloader-id=debian --no-nvram --recheck

# Update GRUB configuration with correct parameters for VirtualBox
cat > /etc/default/grub << ENDGRUB
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL=console
# Disable os-prober to avoid warnings
GRUB_DISABLE_OS_PROBER=true
ENDGRUB

# Update GRUB configuration
update-grub

# Create a script to configure VirtualBox guest additions (for better performance)
cat > /etc/kernel/postinst.d/vbox-update-x11 << ENDVBOX
#!/bin/sh
if [ -x /usr/bin/update-desktop-database ]; then
    update-desktop-database -q
fi
ENDVBOX
chmod +x /etc/kernel/postinst.d/vbox-update-x11

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
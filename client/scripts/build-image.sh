#!/bin/bash
# scripts/build-image.sh - Creates and sets up the disk image

set -e

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Get environment variables
HOSTNAME=${HOSTNAME:-ltsp-client}
IMAGE_SIZE=${IMAGE_SIZE:-5G}
IMAGE_NAME=${IMAGE_NAME:-debian12-lxqt-ltsp.img}
OUTPUT_PATH="/output/${IMAGE_NAME}"

echo "Building Debian 12 LXQT image with hostname: $HOSTNAME"
echo "Image size: $IMAGE_SIZE"
echo "Output path: $OUTPUT_PATH"

# Create an empty disk image
dd if=/dev/zero of=$OUTPUT_PATH bs=1 count=0 seek=$IMAGE_SIZE

# Create partition table and partitions
parted $OUTPUT_PATH mklabel gpt
parted -a optimal $OUTPUT_PATH mkpart primary fat32 1MiB 513MiB
parted -a optimal $OUTPUT_PATH set 1 esp on
parted -a optimal $OUTPUT_PATH mkpart primary ext4 513MiB 100%

# Set up loopback device
LOOP_DEVICE=$(losetup -f --show $OUTPUT_PATH)
echo "Loop device: $LOOP_DEVICE"

# Map partitions
kpartx -a $LOOP_DEVICE
LOOP_NAME=$(echo $LOOP_DEVICE | cut -d "/" -f 3)
EFI_PART="/dev/mapper/${LOOP_NAME}p1"
ROOT_PART="/dev/mapper/${LOOP_NAME}p2"

# Format partitions
mkfs.fat -F32 $EFI_PART
mkfs.ext4 -F $ROOT_PART

# Mount root partition
mkdir -p /mnt/debian
mount $ROOT_PART /mnt/debian

# Bootstrap minimal Debian 12 (Bookworm)
debootstrap --variant=minbase --arch=amd64 bookworm /mnt/debian http://deb.debian.org/debian/

# Mount EFI partition and other necessary filesystems
mkdir -p /mnt/debian/boot/efi
mount $EFI_PART /mnt/debian/boot/efi

mount -o bind /proc /mnt/debian/proc
mount -o bind /sys /mnt/debian/sys
mount -o bind /dev /mnt/debian/dev
mount -o bind /dev/pts /mnt/debian/dev/pts

# Configure apt sources
cat > /mnt/debian/etc/apt/sources.list << ENDSOURCES
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
ENDSOURCES

# Configure hostname
echo "$HOSTNAME" > /mnt/debian/etc/hostname
cat > /mnt/debian/etc/hosts << ENDHOSTS
127.0.0.1       localhost
127.0.1.1       $HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ENDHOSTS

# Generate fstab
ROOT_UUID=$(blkid -s UUID -o value $ROOT_PART)
EFI_UUID=$(blkid -s UUID -o value $EFI_PART)

cat > /mnt/debian/etc/fstab << ENDFSTAB
# /etc/fstab: static file system information.
UUID=$ROOT_UUID /               ext4    errors=remount-ro 0       1
UUID=$EFI_UUID  /boot/efi       vfat    umask=0077      0       1
ENDFSTAB

# Copy chroot setup script
cp /usr/local/bin/chroot-setup.sh /mnt/debian/chroot-setup.sh

# Set non-interactive environment in chroot
cat > /mnt/debian/etc/environment << ENDENV
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
ENDENV

# Execute setup script in chroot
chroot /mnt/debian /chroot-setup.sh

# Clean up
rm /mnt/debian/chroot-setup.sh
rm -f /mnt/debian/etc/environment

# Unmount all filesystems
umount /mnt/debian/dev/pts || true
umount /mnt/debian/dev || true
umount /mnt/debian/sys || true
umount /mnt/debian/proc || true
umount /mnt/debian/boot/efi || true
umount /mnt/debian || true

# Detach loop device
kpartx -d $LOOP_DEVICE || true
losetup -d $LOOP_DEVICE || true

echo "Image build completed successfully!"
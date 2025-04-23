#!/bin/bash
# scripts/build-image.sh - Creates and sets up the disk image for VirtualBox compatibility

set -e

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Get environment variables
HOSTNAME=${HOSTNAME:-ltsp-client}
IMAGE_SIZE=${IMAGE_SIZE:-8G}  # Increased size for better compatibility
IMAGE_NAME=${IMAGE_NAME:-debian12-lxqt-ltsp.img}
OUTPUT_PATH="/output/${IMAGE_NAME}"

echo "Building Debian 12 LXQT image with hostname: $HOSTNAME"
echo "Image size: $IMAGE_SIZE"
echo "Output path: $OUTPUT_PATH"

# Create an empty disk image
dd if=/dev/zero of=$OUTPUT_PATH bs=1 count=0 seek=$IMAGE_SIZE

# Create partition table and partitions
echo "Creating partitions..."
parted $OUTPUT_PATH mklabel gpt

# Create a BIOS boot partition for GRUB (1MB)
parted -a optimal $OUTPUT_PATH mkpart primary 1MiB 2MiB
parted $OUTPUT_PATH set 1 bios_grub on

# Create EFI partition
parted -a optimal $OUTPUT_PATH mkpart primary fat32 2MiB 514MiB
parted -a optimal $OUTPUT_PATH set 2 esp on

# Create root partition
parted -a optimal $OUTPUT_PATH mkpart primary ext4 514MiB 100%

# Update the partition references
LOOP_DEVICE=$(losetup -f --show $OUTPUT_PATH)
echo "Loop device: $LOOP_DEVICE"

# Create loop device info file with explicit path and verify it exists
echo "${LOOP_DEVICE}" > /loop_device_info
ls -la /loop_device_info  # Debug: verify file exists and check permissions
cat /loop_device_info     # Debug: verify file contents

# Map partitions
kpartx -a $LOOP_DEVICE
LOOP_NAME=$(echo $LOOP_DEVICE | cut -d "/" -f 3)
EFI_PART="/dev/mapper/${LOOP_NAME}p2"  # Now p2 instead of p1
ROOT_PART="/dev/mapper/${LOOP_NAME}p3"  # Now p3 instead of p2

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 $EFI_PART
mkfs.ext4 -F $ROOT_PART

# Mount root partition
mkdir -p /mnt/debian
mount $ROOT_PART /mnt/debian

# Bootstrap minimal Debian 12 (Bookworm)
echo "Bootstrapping Debian 12..."
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

# Copy the loop device info file
if [ -f "/loop_device_info" ]; then
    cp /loop_device_info /mnt/debian/loop_device_info
    echo "Copied loop device info to chroot"
else
    echo "WARNING: /loop_device_info does not exist!"
    # Create it directly in the chroot environment as fallback
    echo "${LOOP_DEVICE}" > /mnt/debian/loop_device_info
fi

# Copy chroot setup script
cp /usr/local/bin/chroot-setup.sh /mnt/debian/chroot-setup.sh

# Set non-interactive environment in chroot
cat > /mnt/debian/etc/environment << ENDENV
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
ENDENV

# Execute setup script in chroot
echo "Running chroot setup..."
chroot /mnt/debian /chroot-setup.sh

# Clean up
rm -f /mnt/debian/chroot-setup.sh
rm -f /mnt/debian/loop_device_info
rm -f /mnt/debian/etc/environment

# Sync filesystem before unmounting
sync

# Unmount all filesystems with proper order and error handling
echo "Unmounting filesystems..."
umount /mnt/debian/dev/pts || echo "Failed to unmount /mnt/debian/dev/pts"
umount /mnt/debian/dev || echo "Failed to unmount /mnt/debian/dev"
umount /mnt/debian/sys || echo "Failed to unmount /mnt/debian/sys"
umount /mnt/debian/proc || echo "Failed to unmount /mnt/debian/proc"
umount /mnt/debian/boot/efi || echo "Failed to unmount /mnt/debian/boot/efi"
umount /mnt/debian || echo "Failed to unmount /mnt/debian"

# Detach loop device
echo "Detaching loop device..."
kpartx -d $LOOP_DEVICE || echo "Failed to detach partition mappings"
losetup -d $LOOP_DEVICE || echo "Failed to detach loop device"

# Add script to convert the image to VDI format if VirtualBox is installed
echo "Image build completed! Creating conversion script..."
cat > /output/convert-to-vdi.sh << ENDCONV
#!/bin/bash
# Script to convert raw image to VDI format for VirtualBox

if command -v VBoxManage &> /dev/null; then
    echo "Converting $IMAGE_NAME to VDI format..."
    VBoxManage convertfromraw "$IMAGE_NAME" "${IMAGE_NAME%.*}.vdi" --format VDI
    echo "Conversion complete. VDI file created: ${IMAGE_NAME%.*}.vdi"
else
    echo "VBoxManage not found. Please install VirtualBox to convert the image to VDI format."
    echo "You can manually convert the image using:"
    echo "VBoxManage convertfromraw $IMAGE_NAME ${IMAGE_NAME%.*}.vdi --format VDI"
fi
ENDCONV

chmod +x /output/convert-to-vdi.sh

echo "Image build completed successfully!"
echo "Raw disk image is available at: $OUTPUT_PATH"
echo "To convert to VDI format for VirtualBox, run the convert-to-vdi.sh script in the output directory."
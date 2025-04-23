#!/bin/bash
# virtualbox-setup.sh - Script to prepare the raw image for VirtualBox

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 raw_image_file"
    exit 1
fi

RAW_IMAGE="$1"
VDI_IMAGE="${RAW_IMAGE%.*}.vdi"

# Check if VBoxManage exists
if ! command -v VBoxManage &> /dev/null; then
    echo "VBoxManage not found. Please install VirtualBox."
    exit 1
fi

echo "Converting raw image to VDI format..."
VBoxManage convertfromraw "$RAW_IMAGE" "$VDI_IMAGE" --format VDI

echo "Setting up VirtualBox VM..."
VM_NAME="Debian12-LTSP"

# Create VM (remove if exists)
VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register

# Setup memory and CPU
VBoxManage modifyvm "$VM_NAME" --memory 2048 --cpus 2

# Enable EFI
# VBoxManage modifyvm "$VM_NAME" --firmware efi

# Setup storage controllers
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAHCI
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI_IMAGE"

# Set boot order (hard disk first)
VBoxManage modifyvm "$VM_NAME" --boot1 disk --boot2 none --boot3 none --boot4 none

# Enable PAE/NX
VBoxManage modifyvm "$VM_NAME" --pae on

# Enable 3D acceleration for better graphics performance
VBoxManage modifyvm "$VM_NAME" --accelerate3d on

# Setup network
VBoxManage modifyvm "$VM_NAME" --nic1 nat

echo "VirtualBox VM setup complete!"
echo "You can now start the VM with: VBoxManage startvm \"$VM_NAME\""
echo "Or open VirtualBox GUI and start it from there."
#!/bin/bash
# Script to convert raw image to VDI format for VirtualBox

if command -v VBoxManage &> /dev/null; then
    echo "Converting debian12-lxqt-ltsp.img to VDI format..."
    VBoxManage convertfromraw "debian12-lxqt-ltsp.img" "debian12-lxqt-ltsp.vdi" --format VDI
    echo "Conversion complete. VDI file created: debian12-lxqt-ltsp.vdi"
else
    echo "VBoxManage not found. Please install VirtualBox to convert the image to VDI format."
    echo "You can manually convert the image using:"
    echo "VBoxManage convertfromraw debian12-lxqt-ltsp.img debian12-lxqt-ltsp.vdi --format VDI"
fi

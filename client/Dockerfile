FROM debian:bookworm

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

# Install necessary packages for image creation
RUN apt-get update && apt-get install -y \
    debootstrap \
    fdisk \
    gdisk \
    parted \
    dosfstools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    kpartx \
    rsync \
    uuid-runtime \
    systemd-container \
    debconf-utils \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY scripts/build-image.sh /usr/local/bin/build-image.sh
COPY scripts/chroot-setup.sh /usr/local/bin/chroot-setup.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/build-image.sh /usr/local/bin/chroot-setup.sh

# Set build-image.sh as entrypoint
ENTRYPOINT ["/usr/local/bin/build-image.sh"]
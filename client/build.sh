#!/bin/bash
# build.sh - Main script to orchestrate the build process

set -e

# Configuration variables
HOSTNAME="ltsp-client"
IMAGE_SIZE=5G  # Reduced size for a lightweight image
OUTPUT_DIR="$(pwd)/output"
IMAGE_NAME="debian12-lxqt-ltsp.img"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build the Docker image
echo "Building Docker image for Debian 12 LTSP builder..."
docker build -t debian12-ltsp-builder .

# Run the container to build the image
echo "Starting image build process..."
docker run --rm \
  --privileged \
  -v "$OUTPUT_DIR:/output" \
  -e HOSTNAME="$HOSTNAME" \
  -e IMAGE_SIZE="$IMAGE_SIZE" \
  -e IMAGE_NAME="$IMAGE_NAME" \
  debian12-ltsp-builder

echo "Image build completed!"
echo "Your image is available at: $OUTPUT_DIR/$IMAGE_NAME"

#!/bin/bash

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Install Docker and Docker Compose
sudo apt update && sudo apt install -y docker.io docker-compose
sudo systemctl enable --now docker

# Define Windows Custom Image URL
WINDOWS_IMAGE_URL="159.65.128.155/win10.gz"
WINDOWS_IMAGE_PATH="/root/windows-custom.gz"

# Extract name from URL (remove path and extension)
CONTAINER_NAME=$(basename "$WINDOWS_IMAGE_URL" .gz)
IMAGE_PATH="/root/$CONTAINER_NAME.img"

# Download Windows Custom Image
wget -O "$WINDOWS_IMAGE_PATH" "$WINDOWS_IMAGE_URL"

# Extract Windows Custom Image
gunzip -c "$WINDOWS_IMAGE_PATH" > "$IMAGE_PATH"

# Detect extracted file type
FILE_TYPE=$(file --mime-type -b "$IMAGE_PATH")

# Validate extracted file type
if [[ "$FILE_TYPE" != "application/octet-stream" ]]; then
  echo "Error: Extracted file is not a valid disk image. Detected type: $FILE_TYPE"
  exit 1
fi

# Pull the Windows Docker image
docker pull dockurr/windows

# Run Windows Server container with custom image
docker run -d \
  --name "$CONTAINER_NAME" \
  --env IMG_PATH="/mnt/windows.img" \
  --env RAM_SIZE="2G" \
  --device /dev/kvm \
  --cap-add NET_ADMIN \
  -v "$IMAGE_PATH":/mnt/windows.img \
  -p 8006:8006 \
  -p 55555:55555/tcp \
  -p 55555:55555/udp \
  dockurr/windows

echo "Windows Server container ($CONTAINER_NAME) with custom image is running. Access it via http://IP_VPS:8006 or RDP at IP_VPS:55555"

#!/bin/bash

# Install Docker and Docker Compose
sudo apt update && sudo apt install -y docker.io docker-compose
sudo systemctl enable --now docker

# Pull the Windows Docker image
docker pull dockurr/windows

# Run Windows Server 2012 container with adjusted RAM size
docker run -d \
  --name windows2012 \
  --env VERSION="2012" \
  --env USERNAME="Administrator" \
  --env PASSWORD="SYRA@STORE" \
  --env RAM_SIZE="2G" \
  --device /dev/kvm \
  --cap-add NET_ADMIN \
  -p 8006:8006 \
  -p 3389:3389/tcp \
  -p 3389:3389/udp \
  dockurr/windows

echo "Windows Server 2012 container is running. Access it via http://IP_VPS:8006 or RDP at IP_VPS:3389"

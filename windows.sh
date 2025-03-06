#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set noninteractive mode for apt
export DEBIAN_FRONTEND=noninteractive

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to check and install KVM
check_and_install_kvm() {
    # Check if CPU supports virtualization
    if grep -E 'vmx|svm' /proc/cpuinfo > /dev/null; then
        print_status "CPU supports virtualization"
        
        # Install KVM packages with auto accept
        print_status "Installing KVM packages..."
        apt-get install -y \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            bridge-utils \
            cpu-checker < /dev/null

        # Add current user to libvirt group
        usermod -aG libvirt $USER
        usermod -aG kvm $USER

        # Start and enable libvirtd
        systemctl enable --now libvirtd

        # Verify KVM installation
        if kvm-ok > /dev/null 2>&1; then
            print_status "KVM installation successful"
            return 0
        else
            print_warning "KVM installation completed but may not be working properly"
            print_warning "Please ensure virtualization is enabled in BIOS/UEFI"
            return 1
        fi
    else
        print_error "CPU does not support virtualization"
        print_error "This VPS provider may not support KVM virtualization"
        return 1
    fi
}

# Function to print menu
print_menu() {
    echo -e "${BLUE}Select Windows Version:${NC}"
    echo "1) Windows 11 Pro"
    echo "2) Windows 10 Pro"
    echo "3) Windows Server 2012"
    echo -n "Enter choice [1-3]: "
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

# Select Windows Version
print_menu
read choice

case $choice in
    1)
        WIN_VERSION="11"
        ;;
    2)
        WIN_VERSION="10"
        ;;
    3)
        WIN_VERSION="2012"
        ;;
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Install required packages with auto accept
print_status "Installing required packages..."
apt-get update
apt-get install -y \
    curl \
    docker.io \
    docker-compose < /dev/null

# Start and enable Docker service
print_status "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Create directory for Windows VM
print_status "Creating directory structure..."
mkdir -p /opt/windows-vm

# Get VPS hostname
VPS_NAME=$(hostname)

# Create docker-compose.yml
print_status "Creating Docker Compose configuration..."
cat > /opt/windows-vm/docker-compose.yml << EOL
version: '3'
services:
  windows:
    image: dockurr/windows
    container_name: ${VPS_NAME}
    environment:
      RAM_SIZE: "512M"
      CPU_CORES: "1"
      USERNAME: "administrator"
      PASSWORD: "SYRA@STORE"
      LANGUAGE: "English"
      DISK_SIZE: "256G"
      VERSION: "${WIN_VERSION}"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 55555:3389/tcp
      - 55555:3389/udp
    restart: always
    stop_grace_period: 2m
EOL

# Check if KVM is available and try to install if not
if [ ! -e /dev/kvm ]; then
    print_warning "KVM is not detected. Attempting to install KVM..."
    if ! check_and_install_kvm; then
        print_error "Failed to setup KVM. This VPS might not support nested virtualization."
        print_error "Please contact your VPS provider to ensure KVM/nested virtualization is enabled."
        exit 1
    fi
fi

# Start the container
print_status "Starting Windows container..."
cd /opt/windows-vm
docker-compose up -d

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

# Clear screen before showing connection info
clear

# Print connection information
print_status "----------------------------------------"
print_status "IP: ${SERVER_IP}:55555"
print_status "Username: administrator"
print_status "Password: SYRA@STORE"
print_status "----------------------------------------"
print_status "Note:"
print_status "Silahkan cek proses instalasi di browser [http://${SERVER_IP}:8006]"
print_status "Proses instalasi memakan waktu 10-30 menit" 

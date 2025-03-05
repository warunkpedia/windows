#!/bin/bash

# Cek informasi CPU dan RAM VPS
CPU_AVAILABLE=$(nproc)
RAM_AVAILABLE=$(free -g | awk '/^Mem:/ {print $2}')

# Menentukan jumlah CPU dan RAM yang dibutuhkan
CPU_REQUIRED=2
RAM_REQUIRED=4

echo "Informasi VPS:"
echo "CPU tersedia: $CPU_AVAILABLE"
echo "RAM tersedia: $RAM_AVAILABLE GB"

# Memeriksa apakah CPU dan RAM VPS sudah sesuai dengan yang dibutuhkan
if [[ $CPU_AVAILABLE -ge $CPU_REQUIRED && $RAM_AVAILABLE -ge $RAM_REQUIRED ]]; then
    echo "VPS memenuhi syarat: CPU >= $CPU_REQUIRED dan RAM >= $RAM_REQUIRED."
else
    echo "VPS tidak memenuhi syarat: membutuhkan setidaknya $CPU_REQUIRED CPU dan $RAM_REQUIRED GB RAM."
    exit 1
fi

# Cek apakah Docker sudah terinstal
if ! command -v docker &> /dev/null; then
    echo "Docker tidak ditemukan. Menginstal Docker..."
    
    # Perbarui daftar paket dan instal Docker
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    sudo apt update
    sudo apt install -y docker-ce
    
    echo "Docker telah diinstal."
else
    echo "Docker sudah terinstal."
fi

# Cek apakah KVM tersedia
if [[ ! -e /dev/kvm ]]; then
    echo "KVM tidak ditemukan. Menginstal KVM..."
    sudo apt update
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
    sudo systemctl enable --now libvirtd
    echo "KVM telah diinstal. Silakan reboot VPS jika diperlukan."
else
    echo "KVM sudah tersedia."
fi

# Menanyakan versi Windows kepada pengguna
echo "Pilih versi Windows:"
echo "1: Windows 11 Pro"
echo "2: Windows 10 Pro"
echo "3: Windows Server 2012"
read -p "Masukkan nomor pilihan (1/2/3): " WINDOWS_CHOICE

case $WINDOWS_CHOICE in
    1) WINDOWS_VERSION="11" ;;
    2) WINDOWS_VERSION="10" ;;
    3) WINDOWS_VERSION="2012" ;;
    *) echo "Pilihan tidak valid, menggunakan Windows 11 Pro sebagai default."; WINDOWS_VERSION="11" ;;
esac

# Default konfigurasi
CPU_COUNT=2  # CPU yang dibutuhkan
RAM_SIZE=2   # RAM yang dibutuhkan
WINDOWS_LANG="en-US"
WINDOWS_USER="Administrator"
WINDOWS_PASS="SYRA@STORE"  # Password default Windows

# Menjalankan Docker dengan konfigurasi yang dipilih
docker run -it --rm -p 8006:8006 \
  --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN \
  --stop-timeout 120 \
  --cpus=$CPU_COUNT --memory=${RAM_SIZE}g \
  -e VERSION="$WINDOWS_VERSION" \
  -e USERNAME=$WINDOWS_USER \
  -e PASSWORD=$WINDOWS_PASS \
  -e LANG=$WINDOWS_LANG \
  dockurr/windows

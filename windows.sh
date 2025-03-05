#!/bin/bash

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

# Menanyakan password Windows
echo "Masukkan password Windows:"
read -s WINDOWS_PASS

# Default CPU, RAM, bahasa, dan username
CPU_COUNT=1
RAM_SIZE=1
WINDOWS_LANG="en-US"
WINDOWS_USER="Administrator"

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

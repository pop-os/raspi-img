#!/usr/bin/env bash

set -ex

# Set up DNS
if [ ! -f /run/systemd/resolve/stub-resolv.conf ]
then
    mkdir -p /run/systemd/resolve
    echo "nameserver 1.1.1.1" > /run/systemd/resolve/stub-resolv.conf
fi

# Update and upgrade prior to installing Pop default settings
apt-get update
apt-get dist-upgrade --yes

# Install distribution packages
apt-get install --yes \
    pop-desktop-raspi

# Clean apt caches
apt-get autoremove --purge --yes
apt-get autoclean
apt-get clean

# Copy firmware
cp --verbose /boot/initrd.img /boot/firmware/
cp --verbose /boot/vmlinuz /boot/firmware/
cp --verbose /lib/firmware/*-raspi/device-tree/broadcom/* /boot/firmware/
cp --recursive --verbose /lib/firmware/*-raspi/device-tree/overlays/ /boot/firmware/
cp --verbose /usr/lib/linux-firmware-raspi/* /boot/firmware/
cp --verbose /usr/lib/u-boot/rpi_3/u-boot.bin /boot/firmware/uboot_rpi_3.bin
cp --verbose /usr/lib/u-boot/rpi_4/u-boot.bin /boot/firmware/uboot_rpi_4.bin
cp --verbose /usr/lib/u-boot/rpi_arm64/u-boot.bin /boot/firmware/uboot_rpi_arm64.bin

# Create missing network-manager file
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

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

# Install default packages
apt-get install --yes \
    linux-raspi \
    pop-default-settings

bash

# Clean apt caches
apt-get autoremove --purge --yes
apt-get autoclean
apt-get clean

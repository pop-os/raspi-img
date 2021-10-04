#!/usr/bin/env bash

set -eE

if [ -z "$1" -o -z "$2" -o ! -d "$3" ]
then
    echo "$0 [image] [mount] [debootstrap]" >&2
    exit 1
fi
IMAGE="$(realpath "$1")"
MOUNT="$(realpath "$2")"
DEBOOTSTRAP="$(realpath "$3")"

function cleanup {
    set +x

    # Unmount all mounted partitions
    if [ -n "$(mount | grep "${MOUNT}")" ]
    then
        umount "${MOUNT}/boot/firmware"
        umount "${MOUNT}"
    fi

    # Ensure there are no mounted partitions
    if [ -n "$(mount | grep "${MOUNT}")" ]
    then
        echo "${MOUNT} still mounted" >&2
        exit 1
    fi

    # Detach all loopback devices
    losetup --associated "${IMAGE}" | cut -d ':' -f1 | while read LODEV
    do
        losetup --detach "${LODEV}"
    done

    # Ensure there are no attached loopback devices
    losetup --associated "${IMAGE}" | cut -d ':' -f1 | while read LODEV
    do
        echo "${IMAGE} still has loopback device ${LODEV}" >&2
        exit 1
    done
}

# Run cleanup on error
trap cleanup ERR

# Run cleanup prior to the script
cleanup

# Remove old mount
rm --recursive --force --one-file-system "${MOUNT}"

# Remove old image
rm --recursive --force --verbose "${IMAGE}"

set -x

# Allocate image (8GiB)
fallocate --verbose --length 8GiB "${IMAGE}"

# Partition image
parted "${IMAGE}" mktable msdos
parted "${IMAGE}" mkpart primary fat32 1MiB 256MiB
parted "${IMAGE}" set 1 boot on
parted "${IMAGE}" mkpart primary ext4 256MiB 100%

# Loopback mount image file
LODEV="$(losetup --find --show --partscan "${IMAGE}")"

# Format boot partition
#TODO: other parameters?
mkfs.vfat -n system-boot "${LODEV}p1"

# Format root partition
#TODO: other parameters?
mkfs.ext4 -L writable "${LODEV}p2"

# Create mount directory
mkdir -pv "${MOUNT}"

# Mount root partition
mount "${LODEV}p2" "${MOUNT}"

# Copy debootstrap
rsync \
    --archive \
    --acls \
    --hard-links \
    --numeric-ids \
    --sparse \
    --whole-file \
    --xattrs \
    --stats \
    "${DEBOOTSTRAP}/" "${MOUNT}/"

# Copy modified configuration files
rsync \
    --recursive \
    --verbose \
    "data/etc/" \
    "${MOUNT}/etc/"

# Mount boot partition
mkdir -p "${MOUNT}/boot/firmware"
mount "${LODEV}p1" "${MOUNT}/boot/firmware"

# Copy modified firmware files
rsync \
    --recursive \
    --verbose \
    "data/boot/firmware/" \
    "${MOUNT}/boot/firmware/"

# Copy chroot script
cp -v data/chroot.sh "${MOUNT}/chroot.sh"

# Run chroot script in container
systemd-nspawn \
	--machine=pop-os \
	--resolv-conf=off \
	--directory="${MOUNT}" \
    bash /chroot.sh

# Remove chroot script
rm -v "${MOUNT}/chroot.sh"

# Run cleanup after the script
cleanup

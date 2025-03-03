#!/bin/bash

set -e

source .env

# Functions
infecho () {
    echo "[Info] $1"
}
errecho () {
    echo $1 1>&2
}

infecho "Uncompressing image to mount"

if test -f "$OPENSUSE_RAW_FILE"; then
    xz -d ${OPENSUSE_RAW_FILE}
fi

infecho "Mounting the image to loop..."
losetup
#losetup -d /dev/loop0
losetup /dev/loop3 $( basename -s .xz ${OPENSUSE_RAW_FILE})
partprobe -s /dev/loop3

mkdir imgfs
mount /dev/loop3p2 imgfs

#FIXME: We extract rootfs partition from RAW image to convert to sparse image, so we need to edit fstab
infecho "Change fstab to avoid EFI partition"
sed -i "/efi/d" imgfs/etc/fstab


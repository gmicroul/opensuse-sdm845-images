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


infecho "Umounting image"
umount /dev/loop3p2
losetup -d /dev/loop3

infecho "Deleting unused directories"
rmdir imgfs

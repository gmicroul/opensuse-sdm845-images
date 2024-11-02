#!bin/bash
set -e

source .env 

# Functions
infecho () {
    echo "[Info] $1"
}
errecho () {
    echo $1 1>&2
}


infecho "Downloading image"

#bash download-image.sh

echo "Download ${OPENSUSE_RAW_SOURCE}/${OPENSUSE_RAW_FILE}"

wget -c "${OPENSUSE_RAW_SOURCE}/${OPENSUSE_RAW_FILE}"

infecho "Mounting the image"

#bash mount-image.sh

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
losetup /dev/loop0 $( basename -s .xz ${OPENSUSE_RAW_FILE})
partprobe -s /dev/loop0

mkdir imgfs
mount /dev/loop0p2 imgfs

#FIXME: We extract rootfs partition from RAW image to convert to sparse image, so we need to edit fstab
infecho "Change fstab to avoid EFI partition"
sed -i "/efi/d" imgfs/etc/fstab

infecho "Creating Boot Image"

#bash bootloader.sh 

MOUNTED_IMAGE_DIR="imgfs"
OFFSET=0

ROOTPART=$(grep -vE '^#' ${MOUNTED_IMAGE_DIR}/etc/fstab | grep -E '[[:space:]]/[[:space:]]' | awk '{ print $1; }')
echo "ROOTPART: ${ROOTPART}"
#KERNEL_VERSION=$(linux-version list)

case "${DEVICE}" in
    "oneplus6")
        DTB_VENDOR="oneplus"
        DTB_VARIANTS="enchilada fajita"
        ;;
    "pocof1")
        DTB_VENDOR="xiaomi"
        DTB_VARIANTS="beryllium-tianma beryllium-ebbg"
        ;;
    *)
        echo "ERROR: unsupported device ${DEVICE}"
        exit 1
        ;;
esac

# Create a bootimg for each variant
for variant in ${DTB_VARIANTS}; do
    echo "Creating boot image for variant ${variant}"

    # Append DTB to kernel
    cat ${MOUNTED_IMAGE_DIR}/usr/lib/modules/*-sdm845/Image.gz ${MOUNTED_IMAGE_DIR}/boot/dtb/qcom/sdm845-${DTB_VENDOR}-${variant}.dtb > /tmp/kernel-dtb

    # Create the bootimg as it's the only format recognized by the Android bootloader
    abootimg --create ./openSUSE-Tumbleweed-ARM-PHOSH-${DEVICE}${variant}.aarch64.boot.img -c kerneladdr=0x8000 \
        -c ramdiskaddr=0x1000000 -c secondaddr=0x0 -c tagsaddr=0x100 -c pagesize=4096 \
        -c cmdline="BOOT_IMAGE=/boot/Image root=${ROOTPART} quiet splash" \
        -k /tmp/kernel-dtb -r ${MOUNTED_IMAGE_DIR}/boot/initrd

    #mkbootimg --kernel ${MOUNTED_IMAGE_DIR}/boot/Image --dtb ${MOUNTED_IMAGE_DIR}/boot/dtb/qcom/sdm845-${DTB_VENDOR}-${variant}.dtb --pagesize 4096 \
    #    --base 0x00000000 --kernel_offset 0x00008000 --second_offset 0x00f00000 --tags_offset 0x00000100 \
    #    --cmdline "root=/dev/block/sda21" --output bootimg-${variant}.img

done

infecho "Cleaning all temporal files and dirs"

#bash umount-image.sh

# Functions
infecho () {
    echo "[Info] $1"
}
errecho () {
    echo $1 1>&2
}


infecho "Umounting image"
umount /dev/loop0p2
losetup -d /dev/loop0

infecho "Deleting unused directories"
rmdir imgfs

infecho "Creating RootFS Image"

#bash extract-rootfs.sh

DEVICE=oneplus6
IMAGE=$(basename -s .raw.xz ${OPENSUSE_RAW_FILE})

# Functions
infecho () {
    echo "[Info] $1"
}
errecho () {
    echo $1 1>&2
}


[ "$IMAGE" ] || exit 1

# On an Android device, we can't simply flash a full bootable image: we can only
# flash one partition at a time using fastboot.

# Extract rootfs partition
PART_OFFSET=`/sbin/fdisk -lu $IMAGE.raw | tail -1 | awk '{ print $2; }'` &&
infecho "Extracting rootfs @ $PART_OFFSET"
dd if=$IMAGE.raw of=$IMAGE.root.img bs=512 skip=$PART_OFFSET && rm $IMAGE.raw

# Filesystem images need to be converted to Android sparse images first
infecho "Converting rootfs to sparse image"
img2simg $IMAGE.root.img $IMAGE.root.simg && mv $IMAGE.root.simg $IMAGE.root.img


infecho "Now you can install in your device"
infecho "Put your device in fastboot mode, and execute:"
infecho "  fastboot flash boot openSUSE-Tumbleweed-ARM-PHOSH-<device><variant>.aarch64.boot.img"
infecho "  fastboot -S 100M flash userdata openSUSE-Tumbleweed-ARM-PHOSH-<device>.aarch64.root.img"
infecho "  fastboot erase dtbo"

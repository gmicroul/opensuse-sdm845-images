#!/bin/sh
set -e

source .env

MOUNTED_IMAGE_DIR="imgfs"
OFFSET=0

ROOTPART=$(grep -vE '^#' ${MOUNTED_IMAGE_DIR}/etc/fstab | grep -E '[[:space:]]/[[:space:]]' | awk '{ print $1; }')
echo "ROOTPART: ${ROOTPART}"
#KERNEL_VERSION=$(linux-version list)

case "${DEVICE}" in
    "oneplus6")
        DTB_VENDOR="oneplus"
        DTB_VARIANTS="enchilada fajita"
        #DTB_VARIANTS="fajita"
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
    ls -ltrh ${MOUNTED_IMAGE_DIR}/usr/lib/modules/*-sdm845/
    cat ${MOUNTED_IMAGE_DIR}/usr/lib/modules/*-sdm845/Image ${MOUNTED_IMAGE_DIR}/boot/dtb/qcom/sdm845-${DTB_VENDOR}-${variant}.dtb > /tmp/kernel-dtb
    # cat ${MOUNTED_IMAGE_DIR}/usr/lib/modules/*-sdm845/Image.gz ${MOUNTED_IMAGE_DIR}/boot/dtb/qcom/sdm845-${DTB_VENDOR}-${variant}.dtb > /tmp/kernel-dtb
    ls -ltrh imgfs/boot/
    ls -ltrh /tmp/kernel-dtb
    # Create the bootimg as it's the only format recognized by the Android bootloader
    #abootimg --create ./openSUSE-Tumbleweed-ARM-PHOSH-${DEVICE}${variant}.aarch64.boot.img -c kerneladdr=0x8000 \
    #    -c ramdiskaddr=0x1000000 -c secondaddr=0x0 -c tagsaddr=0x100 -c pagesize=4096 \
    #    -c cmdline="BOOT_IMAGE=/boot/Image root=${ROOTPART} quiet splash" \
    #    -k /tmp/kernel-dtb -r ${MOUNTED_IMAGE_DIR}/boot/initrd-6.11.0-36.gb87e886-sdm845

    mkbootimg --kernel ${MOUNTED_IMAGE_DIR}/boot/Image-6.11.0-37.gb87e886-sdm845 --dtb ${MOUNTED_IMAGE_DIR}/boot/dtb/qcom/sdm845-${DTB_VENDOR}-${variant}.dtb --pagesize 4096 \
        --base 0x00000000 --kernel_offset 0x00008000 --second_offset 0x00f00000 --tags_offset 0x00000100 \
        --cmdline "root=/dev/block/sda21" --output bootimg-${variant}.img

done

#!/usr/bin/env bash

set -o pipefail
source create_base_rootfs.sh

usage() {
    echo "Usage: $0 -d <OUT_DIR> -b <BUSYBOX_INSTALL_DIR> -v <VMLINUZ_IMAGE_FILE> -o <OUTPUT_ROOTFS_IMAGE_FILE> -t <DTB_FILE> [-i <INITRD_IMAGE_FILE>]"
    cat <<-EOF
  -d <OUT_DIR>                     ... files and dirs that will be created by this script and baked into the image
  -b <BUSYBOX_INSTALL_DIR>         ... dir where to find the install-dir of a busybox build
  -v <VMLINUZ_IMAGE_FILE>          ... vmlinuz image file to boot
  -o <OUTPUT_ROOTFS_IMAGE_FILE>    ... final rootfs image
  -t <DTB_FILE>                    ... device tree file
  -i <INITRD_IMAGE_FILE>           ... initrd image to use in boot (default: uInitrd.busybox)
EOF
    exit 1
}

# Defaults
INITRD_IMAGE_FILE="uInitrd.busybox"
ROOTFS_IMAGE_OUTPUT_FILE="rootfs.busybox"            # initrd image file to get loaded by uBoot

# Parse args
while getopts "o:d:b:v:i:h:t:" opt; do
    case "$opt" in
        o) ROOTFS_IMAGE_OUTPUT_FILE="$OPTARG" ;;
        d) OUT_DIR="$OPTARG" ;;
        b) BUSYBOX_INSTALL_DIR="$OPTARG" ;;
        v) VMLINUZ_IMAGE_FILE="$OPTARG" ;;
        i) INITRD_IMAGE_FILE="$OPTARG" ;;
        t) DTB_FILE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check required args
if [[ -z "$OUT_DIR" || -z "$BUSYBOX_INSTALL_DIR" || -z "$VMLINUZ_IMAGE_FILE" || -z "$DTB_FILE" ]]; then
    echo "Error: missing required argument(s)"
    echo "OUT_DIR=$OUT_DIR"
    echo "BUSYBOX_INSTALL_DIR=$BUSYBOX_INSTALL_DIR"
    echo "VMLINUZ_IMAGE_FILE=$VMLINUZ_IMAGE_FILE"
    echo "DTB_FILE=$DTB_FILE"
    echo "INITRD_IMAGE_FILE=$INITRD_IMAGE_FILE"
    usage
fi

set -euo pipefail

create_base_rootfs "${OUT_DIR}" "${BUSYBOX_INSTALL_DIR}"
echo "Successfully created base rootfs in \"${OUT_DIR}\""

# write the init script that is the entrypoint of the system
cat > ${OUT_DIR}/sbin/init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "Hello from rootfs!"
exec /bin/bash
EOF
chmod +x ${OUT_DIR}/sbin/init

mkdir -p ${OUT_DIR}/boot

# write the boot.cmd (legacy) that tells u-boot how to boot the system
cat > ${OUT_DIR}/boot/boot.cmd << EOF
ext4load mmc 1 \${kernel_addr_r} boot/$(basename "${VMLINUZ_IMAGE_FILE}")
ext4load mmc 1 \${fdt_addr_r} boot/$(basename "${DTB_FILE}")
ext4load mmc 1 \${ramdisk_addr_r} boot/$(basename "${INITRD_IMAGE_FILE}")
setenv bootargs "rdinit=/init splash=verbose earlycon console=ttyS2,1500000n8 loglevel=7 raid=noautodetect clk_ignore_unused"
booti \${kernel_addr_r} \${ramdisk_addr_r} \${fdt_addr_r}
EOF
mkimage -A arm64 -T script -C none -n "Boot Script" -d "${OUT_DIR}/boot/boot.cmd" "${OUT_DIR}/boot/boot.scr"

pushd ${OUT_DIR}
sudo chown -R root:root ./*
popd

echo "#### ${OUT_DIR}/boot/boot.cmd ####"
cat ${OUT_DIR}/boot/boot.cmd
echo "##################################"

echo "Successfully created ${ROOTFS_IMAGE_OUTPUT_FILE} file!"

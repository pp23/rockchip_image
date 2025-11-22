#!/bin/bash

set -euo pipefail

source create_base_rootfs.sh

INITRD_IMAGE_OUTPUT_FILE="uInitrd.busybox"            # initrd image file to get loaded by uBoot
OUT_DIR="${1:-initramfs/}"                            # files and dirs that will be baked into the initrd image
BUSYBOX_INSTALL_DIR="${2}"                            # dir where to find the install-dir of a busybox build

create_base_rootfs "${OUT_DIR}" "${BUSYBOX_INSTALL_DIR}"
echo "Successfully created base rootfs in \"${OUT_DIR}\""

cat > ${OUT_DIR}/init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "Hello from initramfs!"
exec /bin/sh
EOF

chmod +x ${OUT_DIR}/init

pushd ${OUT_DIR}
sudo chown -R root:root ./*
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
popd

mkimage -A arm64 -T ramdisk -C gzip \
  -d initramfs.cpio.gz uInitrd.busybox

echo "Successfully created uInitrd.busybox file!"

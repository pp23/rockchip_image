#!/bin/bash

set -euo pipefail

source create_base_rootfs.sh

INITRD_IMAGE_OUTPUT_FILE="uInitrd.busybox"            # initrd image file to get loaded by uBoot
OUT_DIR="${1:-initramfs/}"                            # files and dirs that will be baked into the initrd image
BUSYBOX_INSTALL_DIR="${2}"                            # dir where to find the install-dir of a busybox build

create_base_rootfs "${OUT_DIR}" "${BUSYBOX_INSTALL_DIR}"
echo "Successfully created base rootfs in \"${OUT_DIR}\""
cp -rv "${BUSYBOX_INSTALL_DIR}"/sbin "${OUT_DIR}"/

cat > ${OUT_DIR}/init << 'EOF'
#!/bin/sh

# Fail-safe: drop to shell on ANY error
fail() {
    echo "ERROR: $1"
    echo "Dropping to emergency shell..."
    exec /bin/sh
}

mount -t proc none /proc || fail "Cannot mount /proc"
mount -t sysfs none /sys || fail "Cannot mount /sys"
mount -t devtmpfs none /dev || fail "Cannot mount /dev"

# mount the rootfs. Retry if it could not get immediately mounted.
{
mkdir -p /mnt || fail "Cannot create /mnt directory"
max=10
s=1
i=0
ret=0
rootdev=/dev/mmcblk1p1
echo "Trying to mount $rootdev each $s second max $max times..."
while ! $(mount -t ext4 -o rw $rootdev /mnt);do
i=$((i+1))
[ $i -lt $max ] || { ret=1;break; }
sleep $s
done
}; test $ret -eq 0 || fail "Cannot mount $rootdev"

echo "Hello from initramfs!"
exec switch_root /mnt /sbin/init || fail "switch_root failed"

# If switch_root ever returned (it shouldn't), fail
fail "switch_root unexpectedly returned"
EOF

chmod +x ${OUT_DIR}/init

pushd ${OUT_DIR}
sudo chown -R root:root ./*
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
popd

mkimage -A arm64 -T ramdisk -C gzip \
  -d initramfs.cpio.gz "${INITRD_IMAGE_OUTPUT_FILE}"

echo "Successfully created ${INITRD_IMAGE_OUTPUT_FILE} file!"

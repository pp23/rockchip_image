#!/bin/bash

set -euo pipefail

OUT_DIR="${1:-initramfs/}"
BUSYBOX_INSTALL_DIR="${2}"

mkdir -vp ${OUT_DIR}/{bin,sbin,etc,proc,sys,dev}
cp -aPv ${BUSYBOX_INSTALL_DIR}/bin/* ${OUT_DIR}/bin/
rm -vf ${OUT_DIR}/bin/sh
ln -s busybox ${OUT_DIR}/bin/sh

cat > ${OUT_DIR}/init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

echo "Hello from initramfs!"
exec /bin/sh
EOF

chmod +x ${OUT_DIR}/init

sudo rm -vf ${OUT_DIR}/dev/console
sudo mknod -m 622 ${OUT_DIR}/dev/console c 5 1

sudo rm -vf ${OUT_DIR}/dev/null
sudo mknod -m 666 ${OUT_DIR}/dev/null    c 1 3

pushd ${OUT_DIR}
sudo chown -R root:root ./*
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
popd

mkimage -A arm64 -T ramdisk -C gzip \
  -d initramfs.cpio.gz uInitrd.busybox

echo "Successfully created uInitrd.busybox file!"

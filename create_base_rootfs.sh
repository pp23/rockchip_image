#!/bin/bash

# creates dirs and files to be used as base for a full rootfs or an initrd image

set -euo pipefail

create_base_rootfs() {

OUT_DIR="${1}"                    # files and dirs of the rootfs
BUSYBOX_INSTALL_DIR="${2}"        # dir where to find the install-dir of a busybox build

test $(ls -1 "${OUT_DIR}"|wc -l) -eq 0 || { echo "Error: Base rootfs output dir \"${OUT_DIR}\" is not empty."; exit 1; }
test -d "${BUSYBOX_INSTALL_DIR}" || { echo "Error: 2nd positional parameter \"${BUSYBOX_INSTALL_DIR}\" is no directory. It has to be a Busybox install directory."; exit 1; }

mkdir -p ${OUT_DIR}/{bin,sbin,etc,proc,sys,dev}
cp -rP ${BUSYBOX_INSTALL_DIR}/bin/* ${OUT_DIR}/bin/
rm -f ${OUT_DIR}/bin/sh
ln -s busybox ${OUT_DIR}/bin/sh

sudo rm -f ${OUT_DIR}/dev/console
sudo mknod -m 622 ${OUT_DIR}/dev/console c 5 1

sudo rm -f ${OUT_DIR}/dev/null
sudo mknod -m 666 ${OUT_DIR}/dev/null    c 1 3

sudo chown -R root:root ${OUT_DIR}/*
}

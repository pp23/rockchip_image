#!/bin/bash

OUT_DIR=image/
BINS="/bin/dash
/bin/ls
/usr/bin/dpkg
/usr/bin/dpkg-deb
/bin/tar
"

function copy_to_chroot_dir() {
  test -f "$1" || { echo "File $1 not found."; exit 1; }
  mkdir -pv "${OUT_DIR}${1%/*}"
  cp -v "$1" "${OUT_DIR}${1%/*}/"
}

mkdir -pv $OUT_DIR

for f in $BINS;do
  echo "$f"
  test -f "$f" || { echo "File $f not found."; exit 1; }
  for l in `ldd $f | grep -oE '/[^ ]+'`;do
    copy_to_chroot_dir "$l"
  done
  copy_to_chroot_dir "$f"
done

# Kernel tools for OrangePi 5 Plus

Collection of scripts and readme files that help to understand, build and run a Linux kernel on the OrangePi5 Plus.

## Install custom U-Boot-Loader

The OrangePi 5 Plus board has a 16MB SPI-Flash for the bootloader. A custom U-Boot SPI-Image can be written to it.

### Build U-Boot SPI-Image

* Clone official U-Boot repo:

  `git clone https://github.com/u-boot/u-boot`

* Switch to a release:

  `git checkout v2025.07`

* Clone the `rkbin` repo, it contains firmware binaries that are required for U-Boot to work:

  `git clone https://github.com/rockchip-linux/rkbin`

* I could build and run U-Boot successfully with this rkbin commit:

  `git checkout f43a462e7a1429a9d407ae52b4745033034a6cf9`

* Change back to the `u-boot` directory and set the location to the required `rkbin` files:

  ```
  export ROCKCHIP_TPL=../rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin
  export BL31=../rkbin/bin/rk35/rk3588_bl31_v1.48.elf
  ```

* Create the `.config` based on the board defconfig `configs/orangepi-5-plus-rk3588_defconfig`

  `make CROSS_COMPILE=aarch64-linux-gnu- orangepi-5-plus-rk3588_defconfig`

>**Note:** You can also use the example U-Boot build config for an OrangePi 5 Plus board:

          cp ./config.u-boot.orangepi5plus ./.config

* Build U-Boot:

  `make CROSS_COMPILE=aarch64-linux-gnu- all`

* You should have the file `u-boot-rockchip-spi.bin` in your directory now. If not, check the `.config` whether `CONFIG_ROCKCHIP_SPI_IMAGE=y` is set.

* Flash `u-boot-rockchip-spi.bin` to the SPI-Flash (see section [Flash the U-Boot SPI-Image])

#### Troubleshooting

* In case you get such an error, check whether `ROCKCHIP_TPL` and `BL31` is set (TEE for OP-TEE is not mandatory):
  ```
  Image 'simple-bin' is missing external blobs and is non-functional: rockchip-tpl atf-bl31

  /binman/simple-bin/mkimage/rockchip-tpl (rockchip-tpl):
     An external TPL is required to initialize DRAM. Get the external TPL
     binary and build with ROCKCHIP_TPL=/path/to/ddr.bin. One possible source
     for the external TPL binary is https://github.com/rockchip-linux/rkbin.

  /binman/simple-bin/fit/images/@atf-SEQ/atf-bl31 (atf-bl31):
     See the documentation for your board. You may need to build ARM Trusted
     Firmware and build with BL31=/path/to/bl31.bin

  Image 'simple-bin' has faked external blobs and is non-functional: rockchip-tpl

  Image 'simple-bin' is missing optional external blobs but is still functional: tee-os

  /binman/simple-bin/fit/images/@tee-SEQ/tee-os (tee-os):
     See the documentation for your board. You may need to build Open Portable
     Trusted Execution Environment (OP-TEE) and build with TEE=/path/to/tee.bin

  Image 'simple-bin-spi' is missing external blobs and is non-functional: rockchip-tpl atf-bl31

  /binman/simple-bin-spi/mkimage/rockchip-tpl (rockchip-tpl):
     An external TPL is required to initialize DRAM. Get the external TPL
     binary and build with ROCKCHIP_TPL=/path/to/ddr.bin. One possible source
     for the external TPL binary is https://github.com/rockchip-linux/rkbin.

  /binman/simple-bin-spi/fit/images/@atf-SEQ/atf-bl31 (atf-bl31):
     See the documentation for your board. You may need to build ARM Trusted
     Firmware and build with BL31=/path/to/bl31.bin

  Image 'simple-bin-spi' has faked external blobs and is non-functional: rockchip-tpl

  Image 'simple-bin-spi' is missing optional external blobs but is still functional: tee-os

  /binman/simple-bin-spi/fit/images/@tee-SEQ/tee-os (tee-os):
     See the documentation for your board. You may need to build Open Portable
     Trusted Execution Environment (OP-TEE) and build with TEE=/path/to/tee.bin

  Some images are invalid
  make: *** [Makefile:1135: .binman_stamp] Fehler 103
  ```

### Flash the U-Boot SPI-Image

* ssh into a running image on the OrangePi5 Plus
* Delete the SPI-Flash (Note: This can take up to 5mins without response):
  ```
  dd if=/dev/zero of=/dev/mtdblock0 bs=512k status=progress
  ```
  * It can happen, that it responds with an error `dd: error writing '/dev/mtdblock0': No space left on device`, this seems to be no real error, after up to 5mins the dd command returns with success
* Flash the new U-Boot-SPI-Image (TODO: Document how to build the SPI-Image!)
  ```
  dd if=./u-boot-rockchip-spi.bin of=/dev/mtdblock0 bs=512k status=progress
  ```

### How to restore the Bootloader in case of breaking it

* Clone the [rkdeveloptool}(https://github.com/rockchip-linux/rkdeveloptool)
  * Used working commit-sha: 304f073752fd25c854e1bcf05d8e7f925b1f4e14
* Build it:
  ```
  sudo apt-get install libudev-dev libusb-1.0-0-dev dh-autoreconf
  ./autogen.sh
  ./configure --prefix=./
  make
  make install
  ```
* The rkdeveloptool should be in the root folder of the cloned repository
* Prepare the board:
  * Remove all attached devices (SD-Card, USB-Debugger, HDMI, etc.)
  * Plugin the USB-C next to the MASKROM-Button and connect it to your computer
  * Press the MASKROM-Button of OrangePi5 Plus and turn on the board while keeping the button pressed
  * Release the button after 5s
* List the found devices `rkdeveloptool ld`:
  ```bash
  ./rkdeveloptool ld
  DevNo=1 Vid=0x2207,Pid=0x350b,LocationID=202  Maskrom
  ```
* Get the rescue bootloader image `MiniLoaderAll.bin`: https://drive.google.com/drive/folders/19SMZHj1Y8l_Vvr6_SMDHYdJHi41hMgsI
* Download it to the device:
  ```
  sudo ./rkdeveloptool db MiniLoaderAll.bin
  Downloading bootloader succeeded.
  ```
  * In case you get such an error: `Creating Comm Object failed!`, there should be a `./log/` directory with more detailed logs next to the rkdeveloptool-bin
  * usually, accessing USB requires sudo rights
  * In case of getting this error: `Opening loader failed, exiting download boot!`, the `MiniLoaderAll.bin` was probably not valid (I do not know what a .bin makes it a loader for the rkdeveloptool)
* Upgrade the loader:
  ```
  sudo ./rkdeveloptool ul MiniLoaderAll.bin
  Upgrading loader succeeded.
  ```
* Test the device:
  ```
  sudo ./rkdeveloptool td
  Test Device OK.
  ```
* Reset the device:
  ```
  sudo ./rkdeveloptool rd
  Reset Device OK.
  ```
* Insert a SD-Card with the i.e. OrangePi5 Debian Bookworm image and start the device

# Boot the OrangePi 5 Plus board

It is beneficial to use a USB-UART-Adapter that supports 1500000 bauds datarate. Pay attention to the correct wiring! OrangePi 5 Plus needs to connect the TX-wire with RX on the board, see also http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_5_Plus#How_to_use_the_debugging_serial_port

Start a TTY console on your host machine where the serial-adapter is plugged in:

`picocom -b 1500000 /dev/ttyUSB0`

When you start the Opi5Plus board, you should see log outputs of the boot loader on your screen.

## U-Boot

* list files from sdcard:

`ext4ls mmc 1`

* Print the environment variables to see the required load addresses:

`env print`

```
arch=arm
baudrate=1500000
board=evb_rk3588
board_name=evb_rk3588
boot_targets=mmc1 mmc0 nvme scsi usb pxe dhcp spi
bootcmd=bootflow scan -lb
bootdelay=1
cpu=armv8
cpuid#=4132524432000000000000000012160b
eth1addr=ba:f7:b7:02:bb:0f
ethact=eth_rtl8169
ethaddr=ba:f7:b7:02:bb:0e
fdt_addr_r=0x12000000
fdtcontroladdr=edbe5a40
fdtfile=rockchip/rk3588-orangepi-5-plus.dtb
fdtoverlay_addr_r=0x12100000
kernel_addr_r=0x02000000
kernel_comp_addr_r=0x0a000000
kernel_comp_size=0x8000000
loadaddr=0xc00800
partitions=uuid_disk=${uuid_gpt_disk};name=loader1,start=32K,size=4000K,uuid=${uuid_gpt_loader1};name=loader2,start=8MB,size=4MB,uuid=${uuid_gpt_loader2};name=trust,size=4M,uuid=${uuid_gpt_atf};name=boot,size=112M,bootable,uuid=${uuid_gpt_boot};name=rootfs,size=-,uuid=B921B045-1DF0-41C3-AF44-4C6F280D3FAE;
pxefile_addr_r=0x00e00000
ramdisk_addr_r=0x12180000
script_offset_f=0xffe000
script_size_f=0x2000
scriptaddr=0x00c00000
serial#=7b2a988c988aac31
soc=rk3588
stderr=serial@feb50000
stdin=serial@feb50000
stdout=serial@feb50000
vendor=rockchip

Environment size: 1042/126972 bytes
```

* load the kernel and device tree into memory (based on original OrangePi5 Kernel build):

```
# Original Opi5 Plus Kernel:
# Load addresses are defined in u-boots environment variables. They get set by the board config on u-boots build. See https://docs.u-boot.org/en/latest/usage/environment.html#image-locations
ext4load mmc 1 ${kernel_addr_r} boot/vmlinuz-6.1.43-rockchip-rk3588
ext4load mmc 1 ${fdt_addr_r} boot/dtb-6.1.43-rockchip-rk3588/rockchip/rk3588-orangepi-5-plus.dtb
```

* set bootargs to boot directly with permanent rootfs

```
setenv bootargs "root=/dev/mmcblk1p1 rw rootwait init=/bin/sh"
```

* start the kernel

```
booti ${kernel_addr_r} - ${fdt_addr_r}
```

The `booti` command should start the kernel:

```
=> booti ${kernel_addr_r} - ${fdt_addr_r}
## Flattened Device Tree blob at 12000000
   Booting using the fdt blob at 0x12000000
Working FDT set to 12000000
ERROR: reserving fdt memory region failed (addr=0 size=0 flags=0)
ERROR: reserving fdt memory region failed (addr=0 size=0 flags=0)
   Loading Device Tree to 00000000ecb92000, end 00000000ecbd9f76 ... OK
Working FDT set to ecb92000

Starting kernel ...

[  515.720281] Booting Linux on physical CPU 0x0000000000 [0x412fd050]
[  515.720315] Linux version 6.1.43-rockchip-rk3588 (root@f55fae764dbe) (aarch64-none-linux-gnu-gcc (GNU Toolchain for the Arm Architecture 11.2-2022.02 (arm-11.14)) 11.2.1 20220111, GNU ld (GNU Toolchain for the Arm Architecture 11.2-2022.02 (arm-11.14)) 2.37.20220122) #1.2.0 SMP Sun Aug 17 18:45:41 UTC 2025
...
```

# Build an upstream kernel

This was tested with kernel version 6.15.7

## Build the kernel

### Get the kernel

* Get source code from kernel.org. Choose a kernel .tar.xz from https://www.kernel.org/pub/linux/kernel/v6.x/ like https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.15.7.tar.xz
* Verify the signature, see https://www.kernel.org/category/signatures.html
  ```
  gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org
  curl -OL https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.15.7.tar.sign
  gpg2 --tofu-policy good 38DBBDC86092693E
  xz -cd linux-6.15.7.tar.xz | gpg2 --trust-model tofu --verify linux-6.15.7.tar.sign -
  ```
* or simply use [get-verified-tarball](https://git.kernel.org/pub/scm/linux/kernel/git/mricon/korg-helpers.git/tree/get-verified-tarball)

### Compile the kernel

* Configure the kernel manually or use the [prepared kernel-config](./config.kernel.6.15.7.orangepi5plus)

#### Manual configuration

* Run menuconfig:
  ```
  make -j16 \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    KERNEL_IMAGE_TYPE="zImage" \
    ATF_COMPILE=yes \
    SKIP_BOOTSPLASH=yes \
    IMAGE_PARTITION_TABLE=gpt \
    BUILD_KSRC=no \
    ROOTFS_TYPE=ext4 \
    DEB_COMPRESS=xz \
    ROOTPWD=orangepi \
    PLYMOUTH=yes \
    KBUILD_IMAGE=Image.gz \
    INSTALL_PATH=./_install \
    menuconfig
  ```
  Make sure to enable the Rockchip platform and the 8250-serial-console. The console is required to have an initial console over serial on ttyS2. These configs need to be set in the `.config` file:
  ```
  CONFIG_SERIAL_CORE=y
  CONFIG_SERIAL_CORE_CONSOLE=y
  CONFIG_SERIAL_8250=y
  CONFIG_SERIAL_8250_CONSOLE=y
  CONFIG_SERIAL_8250_EXTENDED=y
  CONFIG_SERIAL_8250_SHARE_IRQ=y
  CONFIG_SERIAL_ARM_CONSOLE=y        # if on ARM SoC
  CONFIG_SERIAL_AMBA_PL011=y         # if using PL011 UART (Rockchip/ARM)
  CONFIG_SERIAL_AMBA_PL011_CONSOLE=y # optional
  CONFIG_SERIAL_8250_NR_UARTS=4      # ensure at least 3 (ttyS0-S2), OrangePi5 supports 32 UARTs
  CONFIG_SERIAL_EARLYCON=y           # early console output of printk
  ```

* Build the compressed kernel image:

  >**Note:**  For signature checking, the kernel build process requires certificates from Canonical.
              See also: https://stackoverflow.com/a/72528175

              # install linux sources where the debian certificates are usually included
              sudo apt install linux-source-6.5.0
              # create a debian/ dir in the kernel source dir and copy the pem-certs into it:
              mkdir -p debian/
              cp -v /usr/src/linux-source-6.5.0/debian/canonical-*.pem debian/

  The target `Image.gz` builds a compressed image which will be copied to a `vmlinuz` file on install
  ```
  make -j16 \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    KERNEL_IMAGE_TYPE="zImage" \
    ATF_COMPILE=yes \
    SKIP_BOOTSPLASH=yes \
    IMAGE_PARTITION_TABLE=gpt \
    BUILD_KSRC=no \
    ROOTFS_TYPE=ext4 \
    DEB_COMPRESS=xz \
    ROOTPWD=orangepi \
    PLYMOUTH=yes \
    KBUILD_IMAGE=Image.gz \
    INSTALL_PATH=./_install \
    Image.gz
  ```

* Install the kernel image:

  >**Note:** For any reason, the install target expects the Image.gz file in the root path of the repository, but the make command above created in arch/arm64/boot/Image.gz. That requires to copy the Image.gz beforehand manually to the root of the repositoy: cp arch/arm64/boot/Image.gz ./

  ```
  make -j16 \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    KERNEL_IMAGE_TYPE="zImage" \
    ATF_COMPILE=yes \
    SKIP_BOOTSPLASH=yes \
    IMAGE_PARTITION_TABLE=gpt \
    BUILD_KSRC=no \
    ROOTFS_TYPE=ext4 \
    DEB_COMPRESS=xz \
    ROOTPWD=orangepi \
    PLYMOUTH=yes \
    KBUILD_IMAGE=Image.gz \
    INSTALL_PATH=./_install \
    install
  ```

  * The install command creates the specified install directory `./_install` with the `vmlinuz` compressed image file
    ```
    _install/
    ├── config-6.15.7
    ├── System.map-6.15.7
    └── vmlinuz-6.15.7

    ```
* Install the `dtb` files of the specified platform:

  ```
  make -j16 \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    KERNEL_IMAGE_TYPE="zImage" \
    ATF_COMPILE=yes \
    SKIP_BOOTSPLASH=yes \
    IMAGE_PARTITION_TABLE=gpt \
    BUILD_KSRC=no \
    ROOTFS_TYPE=ext4 \
    DEB_COMPRESS=xz \
    ROOTPWD=orangepi \
    PLYMOUTH=yes \
    KBUILD_IMAGE=Image.gz \
    INSTALL_PATH=./_install \
    dtbs_install
  ```
  * The dtb file of the OrangePi 5 Plus can be found in

    `_install/dtbs/6.15.7/rockchip/rk3588-orangepi-5-plus.dtb`

# Create a rootfs
(credits to: https://hechao.li/posts/Boot-Raspberry-Pi-4-Using-uboot-and-Initramfs)

After the kernel booted it requires a rootfs or initramfs where it can find the tools and programs of the system after boot.
The rootfs in this example is based on [busybox](https://github.com/mirror/busybox.git).

## Build busybox

* Clone busybox

  `git clone https://github.com/mirror/busybox.git`

* Checkout to a stable branch

  `git checkout 1_36_stable`

* Configure busybox or use the [prepared configuration](./.config.busybox)

  `make ARCH=arm64 menuconfig`

  * Make sure that these build options are set:

    ```
    CONFIG_STATIC=y               # static linked binary, without the aarch64 libs need to get added to the image
    CONFIG_STATIC_LIBGCC=y
    CONFIG_PREFIX="./_install"    # writes the busybox binaries to ./_install
    CONFIG_SH_IS_ASH=y            # use ash for sh alias
    CONFIG_ASH=y                  # enable ash shell
    ```

    >**Note:** If you decide for a dynamically linked busybox, you need to copy the shared libs too:

        sudo cp -v -L /usr/aarch64-linux-gnu/lib/{ld-linux-aarch64.so.1, libm.so.6, libresolv.so.2, libc.so.6} /mnt/sdcard/lib64/

* Build busybox:

  `make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- all`

* Install the rootfs binaries:

  `make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- install`

* The `./_install` directory should have the following structure now:
  <details>
    <summary>busybox structure</summary>

    ```
    _install/
    ├── bin
    │   ├── arch -> busybox
    │   ├── ash -> busybox
    │   ├── base32 -> busybox
    │   ├── base64 -> busybox
    │   ├── busybox
    │   ├── cat -> busybox
    │   ├── chattr -> busybox
    │   ├── chgrp -> busybox
    │   ├── chmod -> busybox
    │   ├── chown -> busybox
    │   ├── conspy -> busybox
    │   ├── cp -> busybox
    │   ├── cpio -> busybox
    │   ├── cttyhack -> busybox
    │   ├── date -> busybox
    │   ├── dd -> busybox
    │   ├── df -> busybox
    │   ├── dmesg -> busybox
    │   ├── dnsdomainname -> busybox
    │   ├── dumpkmap -> busybox
    │   ├── echo -> busybox
    │   ├── ed -> busybox
    │   ├── egrep -> busybox
    │   ├── false -> busybox
    │   ├── fatattr -> busybox
    │   ├── fdflush -> busybox
    │   ├── fgrep -> busybox
    │   ├── fsync -> busybox
    │   ├── getopt -> busybox
    │   ├── grep -> busybox
    │   ├── gunzip -> busybox
    │   ├── gzip -> busybox
    │   ├── hostname -> busybox
    │   ├── hush -> busybox
    │   ├── ionice -> busybox
    │   ├── iostat -> busybox
    │   ├── ipcalc -> busybox
    │   ├── kbd_mode -> busybox
    │   ├── kill -> busybox
    │   ├── link -> busybox
    │   ├── linux32 -> busybox
    │   ├── linux64 -> busybox
    │   ├── ln -> busybox
    │   ├── login -> busybox
    │   ├── ls -> busybox
    │   ├── lsattr -> busybox
    │   ├── lzop -> busybox
    │   ├── makemime -> busybox
    │   ├── mkdir -> busybox
    │   ├── mknod -> busybox
    │   ├── mktemp -> busybox
    │   ├── more -> busybox
    │   ├── mount -> busybox
    │   ├── mountpoint -> busybox
    │   ├── mpstat -> busybox
    │   ├── mt -> busybox
    │   ├── mv -> busybox
    │   ├── netstat -> busybox
    │   ├── nice -> busybox
    │   ├── pidof -> busybox
    │   ├── ping -> busybox
    │   ├── ping6 -> busybox
    │   ├── pipe_progress -> busybox
    │   ├── printenv -> busybox
    │   ├── ps -> busybox
    │   ├── pwd -> busybox
    │   ├── reformime -> busybox
    │   ├── resume -> busybox
    │   ├── rev -> busybox
    │   ├── rm -> busybox
    │   ├── rmdir -> busybox
    │   ├── run-parts -> busybox
    │   ├── scriptreplay -> busybox
    │   ├── sed -> busybox
    │   ├── setarch -> busybox
    │   ├── setpriv -> busybox
    │   ├── setserial -> busybox
    │   ├── sh -> busybox
    │   ├── sleep -> busybox
    │   ├── stat -> busybox
    │   ├── stty -> busybox
    │   ├── su -> busybox
    │   ├── sync -> busybox
    │   ├── tar -> busybox
    │   ├── touch -> busybox
    │   ├── true -> busybox
    │   ├── umount -> busybox
    │   ├── uname -> busybox
    │   ├── usleep -> busybox
    │   ├── vi -> busybox
    │   ├── watch -> busybox
    │   └── zcat -> busybox
    ├── linuxrc -> bin/busybox
    ├── sbin
    │   ├── acpid -> ../bin/busybox
    │   ├── adjtimex -> ../bin/busybox
    │   ├── arp -> ../bin/busybox
    │   ├── blkid -> ../bin/busybox
    │   ├── blockdev -> ../bin/busybox
    │   ├── bootchartd -> ../bin/busybox
    │   ├── depmod -> ../bin/busybox
    │   ├── devmem -> ../bin/busybox
    │   ├── fbsplash -> ../bin/busybox
    │   ├── fdisk -> ../bin/busybox
    │   ├── findfs -> ../bin/busybox
    │   ├── freeramdisk -> ../bin/busybox
    │   ├── fsck -> ../bin/busybox
    │   ├── fsck.minix -> ../bin/busybox
    │   ├── fstrim -> ../bin/busybox
    │   ├── getty -> ../bin/busybox
    │   ├── halt -> ../bin/busybox
    │   ├── hdparm -> ../bin/busybox
    │   ├── hwclock -> ../bin/busybox
    │   ├── ifconfig -> ../bin/busybox
    │   ├── ifdown -> ../bin/busybox
    │   ├── ifenslave -> ../bin/busybox
    │   ├── ifup -> ../bin/busybox
    │   ├── init -> ../bin/busybox
    │   ├── insmod -> ../bin/busybox
    │   ├── ip -> ../bin/busybox
    │   ├── ipaddr -> ../bin/busybox
    │   ├── iplink -> ../bin/busybox
    │   ├── ipneigh -> ../bin/busybox
    │   ├── iproute -> ../bin/busybox
    │   ├── iprule -> ../bin/busybox
    │   ├── iptunnel -> ../bin/busybox
    │   ├── klogd -> ../bin/busybox
    │   ├── loadkmap -> ../bin/busybox
    │   ├── logread -> ../bin/busybox
    │   ├── losetup -> ../bin/busybox
    │   ├── lsmod -> ../bin/busybox
    │   ├── makedevs -> ../bin/busybox
    │   ├── mdev -> ../bin/busybox
    │   ├── mkdosfs -> ../bin/busybox
    │   ├── mke2fs -> ../bin/busybox
    │   ├── mkfs.ext2 -> ../bin/busybox
    │   ├── mkfs.minix -> ../bin/busybox
    │   ├── mkfs.vfat -> ../bin/busybox
    │   ├── mkswap -> ../bin/busybox
    │   ├── modinfo -> ../bin/busybox
    │   ├── modprobe -> ../bin/busybox
    │   ├── nameif -> ../bin/busybox
    │   ├── pivot_root -> ../bin/busybox
    │   ├── poweroff -> ../bin/busybox
    │   ├── raidautorun -> ../bin/busybox
    │   ├── reboot -> ../bin/busybox
    │   ├── rmmod -> ../bin/busybox
    │   ├── route -> ../bin/busybox
    │   ├── run-init -> ../bin/busybox
    │   ├── runlevel -> ../bin/busybox
    │   ├── setconsole -> ../bin/busybox
    │   ├── slattach -> ../bin/busybox
    │   ├── start-stop-daemon -> ../bin/busybox
    │   ├── sulogin -> ../bin/busybox
    │   ├── swapoff -> ../bin/busybox
    │   ├── swapon -> ../bin/busybox
    │   ├── switch_root -> ../bin/busybox
    │   ├── sysctl -> ../bin/busybox
    │   ├── syslogd -> ../bin/busybox
    │   ├── tc -> ../bin/busybox
    │   ├── tunctl -> ../bin/busybox
    │   ├── udhcpc -> ../bin/busybox
    │   ├── uevent -> ../bin/busybox
    │   ├── vconfig -> ../bin/busybox
    │   ├── watchdog -> ../bin/busybox
    │   └── zcip -> ../bin/busybox
    └── usr
        ├── bin
        │   ├── [ -> ../../bin/busybox
        │   ├── [[ -> ../../bin/busybox
        │   ├── ascii -> ../../bin/busybox
        │   ├── awk -> ../../bin/busybox
        │   ├── basename -> ../../bin/busybox
        │   ├── bc -> ../../bin/busybox
        │   ├── beep -> ../../bin/busybox
        │   ├── blkdiscard -> ../../bin/busybox
        │   ├── bunzip2 -> ../../bin/busybox
        │   ├── bzcat -> ../../bin/busybox
        │   ├── bzip2 -> ../../bin/busybox
        │   ├── cal -> ../../bin/busybox
        │   ├── chpst -> ../../bin/busybox
        │   ├── chrt -> ../../bin/busybox
        │   ├── chvt -> ../../bin/busybox
        │   ├── cksum -> ../../bin/busybox
        │   ├── clear -> ../../bin/busybox
        │   ├── cmp -> ../../bin/busybox
        │   ├── comm -> ../../bin/busybox
        │   ├── crc32 -> ../../bin/busybox
        │   ├── crontab -> ../../bin/busybox
        │   ├── cryptpw -> ../../bin/busybox
        │   ├── cut -> ../../bin/busybox
        │   ├── dc -> ../../bin/busybox
        │   ├── deallocvt -> ../../bin/busybox
        │   ├── diff -> ../../bin/busybox
        │   ├── dirname -> ../../bin/busybox
        │   ├── dos2unix -> ../../bin/busybox
        │   ├── dpkg -> ../../bin/busybox
        │   ├── dpkg-deb -> ../../bin/busybox
        │   ├── du -> ../../bin/busybox
        │   ├── dumpleases -> ../../bin/busybox
        │   ├── eject -> ../../bin/busybox
        │   ├── env -> ../../bin/busybox
        │   ├── envdir -> ../../bin/busybox
        │   ├── envuidgid -> ../../bin/busybox
        │   ├── expand -> ../../bin/busybox
        │   ├── expr -> ../../bin/busybox
        │   ├── factor -> ../../bin/busybox
        │   ├── fallocate -> ../../bin/busybox
        │   ├── fgconsole -> ../../bin/busybox
        │   ├── find -> ../../bin/busybox
        │   ├── flock -> ../../bin/busybox
        │   ├── fold -> ../../bin/busybox
        │   ├── free -> ../../bin/busybox
        │   ├── ftpget -> ../../bin/busybox
        │   ├── ftpput -> ../../bin/busybox
        │   ├── fuser -> ../../bin/busybox
        │   ├── groups -> ../../bin/busybox
        │   ├── hd -> ../../bin/busybox
        │   ├── head -> ../../bin/busybox
        │   ├── hexdump -> ../../bin/busybox
        │   ├── hexedit -> ../../bin/busybox
        │   ├── hostid -> ../../bin/busybox
        │   ├── id -> ../../bin/busybox
        │   ├── install -> ../../bin/busybox
        │   ├── ipcrm -> ../../bin/busybox
        │   ├── ipcs -> ../../bin/busybox
        │   ├── killall -> ../../bin/busybox
        │   ├── last -> ../../bin/busybox
        │   ├── less -> ../../bin/busybox
        │   ├── logger -> ../../bin/busybox
        │   ├── logname -> ../../bin/busybox
        │   ├── lpq -> ../../bin/busybox
        │   ├── lpr -> ../../bin/busybox
        │   ├── lsof -> ../../bin/busybox
        │   ├── lspci -> ../../bin/busybox
        │   ├── lsscsi -> ../../bin/busybox
        │   ├── lsusb -> ../../bin/busybox
        │   ├── lzcat -> ../../bin/busybox
        │   ├── lzma -> ../../bin/busybox
        │   ├── man -> ../../bin/busybox
        │   ├── md5sum -> ../../bin/busybox
        │   ├── mesg -> ../../bin/busybox
        │   ├── microcom -> ../../bin/busybox
        │   ├── mkfifo -> ../../bin/busybox
        │   ├── mkpasswd -> ../../bin/busybox
        │   ├── nc -> ../../bin/busybox
        │   ├── nl -> ../../bin/busybox
        │   ├── nmeter -> ../../bin/busybox
        │   ├── nohup -> ../../bin/busybox
        │   ├── nproc -> ../../bin/busybox
        │   ├── nsenter -> ../../bin/busybox
        │   ├── nslookup -> ../../bin/busybox
        │   ├── od -> ../../bin/busybox
        │   ├── openvt -> ../../bin/busybox
        │   ├── passwd -> ../../bin/busybox
        │   ├── paste -> ../../bin/busybox
        │   ├── patch -> ../../bin/busybox
        │   ├── pgrep -> ../../bin/busybox
        │   ├── pkill -> ../../bin/busybox
        │   ├── pmap -> ../../bin/busybox
        │   ├── printf -> ../../bin/busybox
        │   ├── pscan -> ../../bin/busybox
        │   ├── pstree -> ../../bin/busybox
        │   ├── pwdx -> ../../bin/busybox
        │   ├── readlink -> ../../bin/busybox
        │   ├── realpath -> ../../bin/busybox
        │   ├── renice -> ../../bin/busybox
        │   ├── reset -> ../../bin/busybox
        │   ├── resize -> ../../bin/busybox
        │   ├── runsv -> ../../bin/busybox
        │   ├── runsvdir -> ../../bin/busybox
        │   ├── rx -> ../../bin/busybox
        │   ├── script -> ../../bin/busybox
        │   ├── seq -> ../../bin/busybox
        │   ├── setfattr -> ../../bin/busybox
        │   ├── setkeycodes -> ../../bin/busybox
        │   ├── setsid -> ../../bin/busybox
        │   ├── setuidgid -> ../../bin/busybox
        │   ├── sha1sum -> ../../bin/busybox
        │   ├── sha256sum -> ../../bin/busybox
        │   ├── sha3sum -> ../../bin/busybox
        │   ├── sha512sum -> ../../bin/busybox
        │   ├── showkey -> ../../bin/busybox
        │   ├── shred -> ../../bin/busybox
        │   ├── shuf -> ../../bin/busybox
        │   ├── smemcap -> ../../bin/busybox
        │   ├── softlimit -> ../../bin/busybox
        │   ├── sort -> ../../bin/busybox
        │   ├── split -> ../../bin/busybox
        │   ├── ssl_client -> ../../bin/busybox
        │   ├── strings -> ../../bin/busybox
        │   ├── sum -> ../../bin/busybox
        │   ├── sv -> ../../bin/busybox
        │   ├── svc -> ../../bin/busybox
        │   ├── svok -> ../../bin/busybox
        │   ├── tac -> ../../bin/busybox
        │   ├── tail -> ../../bin/busybox
        │   ├── taskset -> ../../bin/busybox
        │   ├── tcpsvd -> ../../bin/busybox
        │   ├── tee -> ../../bin/busybox
        │   ├── telnet -> ../../bin/busybox
        │   ├── test -> ../../bin/busybox
        │   ├── tftp -> ../../bin/busybox
        │   ├── time -> ../../bin/busybox
        │   ├── timeout -> ../../bin/busybox
        │   ├── top -> ../../bin/busybox
        │   ├── tr -> ../../bin/busybox
        │   ├── traceroute -> ../../bin/busybox
        │   ├── traceroute6 -> ../../bin/busybox
        │   ├── tree -> ../../bin/busybox
        │   ├── truncate -> ../../bin/busybox
        │   ├── ts -> ../../bin/busybox
        │   ├── tsort -> ../../bin/busybox
        │   ├── tty -> ../../bin/busybox
        │   ├── ttysize -> ../../bin/busybox
        │   ├── udhcpc6 -> ../../bin/busybox
        │   ├── udpsvd -> ../../bin/busybox
        │   ├── unexpand -> ../../bin/busybox
        │   ├── uniq -> ../../bin/busybox
        │   ├── unix2dos -> ../../bin/busybox
        │   ├── unlink -> ../../bin/busybox
        │   ├── unlzma -> ../../bin/busybox
        │   ├── unshare -> ../../bin/busybox
        │   ├── unxz -> ../../bin/busybox
        │   ├── unzip -> ../../bin/busybox
        │   ├── uptime -> ../../bin/busybox
        │   ├── users -> ../../bin/busybox
        │   ├── uudecode -> ../../bin/busybox
        │   ├── uuencode -> ../../bin/busybox
        │   ├── vlock -> ../../bin/busybox
        │   ├── volname -> ../../bin/busybox
        │   ├── w -> ../../bin/busybox
        │   ├── wall -> ../../bin/busybox
        │   ├── wc -> ../../bin/busybox
        │   ├── wget -> ../../bin/busybox
        │   ├── which -> ../../bin/busybox
        │   ├── who -> ../../bin/busybox
        │   ├── whoami -> ../../bin/busybox
        │   ├── whois -> ../../bin/busybox
        │   ├── xargs -> ../../bin/busybox
        │   ├── xxd -> ../../bin/busybox
        │   ├── xz -> ../../bin/busybox
        │   ├── xzcat -> ../../bin/busybox
        │   └── yes -> ../../bin/busybox
        └── sbin
            ├── addgroup -> ../../bin/busybox
            ├── add-shell -> ../../bin/busybox
            ├── adduser -> ../../bin/busybox
            ├── arping -> ../../bin/busybox
            ├── brctl -> ../../bin/busybox
            ├── chat -> ../../bin/busybox
            ├── chpasswd -> ../../bin/busybox
            ├── chroot -> ../../bin/busybox
            ├── crond -> ../../bin/busybox
            ├── delgroup -> ../../bin/busybox
            ├── deluser -> ../../bin/busybox
            ├── dhcprelay -> ../../bin/busybox
            ├── dnsd -> ../../bin/busybox
            ├── ether-wake -> ../../bin/busybox
            ├── fakeidentd -> ../../bin/busybox
            ├── fbset -> ../../bin/busybox
            ├── fdformat -> ../../bin/busybox
            ├── fsfreeze -> ../../bin/busybox
            ├── ftpd -> ../../bin/busybox
            ├── httpd -> ../../bin/busybox
            ├── i2cdetect -> ../../bin/busybox
            ├── i2cdump -> ../../bin/busybox
            ├── i2cget -> ../../bin/busybox
            ├── i2cset -> ../../bin/busybox
            ├── i2ctransfer -> ../../bin/busybox
            ├── ifplugd -> ../../bin/busybox
            ├── inetd -> ../../bin/busybox
            ├── killall5 -> ../../bin/busybox
            ├── loadfont -> ../../bin/busybox
            ├── lpd -> ../../bin/busybox
            ├── mim -> ../../bin/busybox
            ├── nanddump -> ../../bin/busybox
            ├── nandwrite -> ../../bin/busybox
            ├── nbd-client -> ../../bin/busybox
            ├── nologin -> ../../bin/busybox
            ├── ntpd -> ../../bin/busybox
            ├── partprobe -> ../../bin/busybox
            ├── popmaildir -> ../../bin/busybox
            ├── powertop -> ../../bin/busybox
            ├── rdate -> ../../bin/busybox
            ├── rdev -> ../../bin/busybox
            ├── readahead -> ../../bin/busybox
            ├── readprofile -> ../../bin/busybox
            ├── remove-shell -> ../../bin/busybox
            ├── rtcwake -> ../../bin/busybox
            ├── seedrng -> ../../bin/busybox
            ├── sendmail -> ../../bin/busybox
            ├── setfont -> ../../bin/busybox
            ├── setlogcons -> ../../bin/busybox
            ├── svlogd -> ../../bin/busybox
            ├── telnetd -> ../../bin/busybox
            ├── tftpd -> ../../bin/busybox
            ├── ubiattach -> ../../bin/busybox
            ├── ubidetach -> ../../bin/busybox
            ├── ubimkvol -> ../../bin/busybox
            ├── ubirename -> ../../bin/busybox
            ├── ubirmvol -> ../../bin/busybox
            ├── ubirsvol -> ../../bin/busybox
            ├── ubiupdatevol -> ../../bin/busybox
            └── udhcpd -> ../../bin/busybox

    5 directories, 401 files
    ```
  </details>

* Copy the files to an `./rootfs` directory

  ```
  mkdir -p ./rootfs
  cp -a ./_install/* ./rootfs/
  ```

* Create the required device files and directories for a rootfs (see also https://hechao.li/posts/Boot-Raspberry-Pi-4-Using-uboot-and-Initramfs/#61-create-directories):

  ```
  mkdir -vp rootfs/{bin,dev,etc,home,lib64,proc,sbin,sys,tmp,usr,var}    # creates missing directories
  mkdir -vp rootfs/usr/{bin,lib,sbin}
  mkdir -vp rootfs/var/log
  ln -s lib64 rootfs/lib
  sudo mknod -m 622 rootfs/dev/console c 5 1      # required for the initial console
  sudo mknod -m 666 rootfs/dev/null    c 1 3
  sudo chown -R root:root ./rootfs/*              # the first user is root
  ```

* Copying the `rootfs/` content to a SD is already sufficient if the kernel boots from the SD rather than using an initramfs. However, booting from an initramfs can be beneficial in case the rootfs cannot get mounted. The initramfs provides a TTY shell as fallback for further debugging.
### Build initramfs

* Based on the rootfs, we can easily build an initramfs:
  ```
  pushd rootfs/
  # create a simple init script:
  cat > ./init << 'EOF'
  #!/bin/sh
  mount -t proc none /proc
  mount -t sysfs none /sys
  mount -t devtmpfs none /dev

  echo "Hello from initramfs!"
  exec /bin/sh
  EOF
  chmod +x ./init
  find . | cpio -H newc -ov --owner root:root -F ../initramfs.cpio
  popd
  gzip initramfs.cpio
  mkimage -A arm64 -O linux -T ramdisk -d initramfs.cpio.gz uInitrd.busybox
  ```

# Testing self-compiled kernel 6.15.7

* Copy the rootfs to a SDCard
* Copy the kernel install files to a `/boot/` directory on the SDCard
* Copy the initramfs to the `/boot/` of the SDCard

  ```
  cp -v vmlinuz-6.15.7 /mnt/sdcard/boot/
  cp -v dtbs/6.15.7/rockchip/rk3588-orangepi-5-plus.dtb /mnt/sdcard/boot/
  cp -v uInitrd.busybox /mnt/sdcard/boot/
  ```
* Put the SDCard into OrangePi, attach the serial adapter to the UART and power up the board
* You should see U-Boot logs in picocom. Stop the boot process when the request to hit any key and a 3 second timer appears. You should now have a tty shell in U-Boot.
* Run these commands to get the kernel, dtb and initramfs loaded into ram:

  ```
  ext4load mmc 1 ${kernel_addr_r} boot/vmlinuz-6.15.7
  ext4load mmc 1 ${fdt_addr_r} boot/rk3588-orangepi-5-plus.dtb
  ext4load mmc 1 ${ramdisk_addr_r} boot/uInitrd.busybox
  setenv bootargs "rdinit=/init splash=verbose earlycon console=ttyS2,1500000n8 loglevel=7 raid=noautodetect clk_ignore_unused"
  booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
  ```
  * `bootargs` define the cmdline passed to the kernel
  * `rdinit=/init` define the executable to run in the initramfs. This should switch the root to mmc and start the system or provide a fallback tty on error.
  * `earlycon` enables the early console output if it is enabled in the kernel config (`CONFIG_SERIAL_EARLYCON=y`)
  * `raid=noautodetect` was simply added to speed up boot and output less logs
  * `clk_ignore_unused` skips the disabling of unused clocks. I encountered that the kernel 6.15.7 stucked at that point in boot when it tried to disable unused clocks. For further debugging see: https://blog.dowhile0.org/2024/06/02/some-useful-linux-kernel-cmdline-debug-parameters-to-troubleshoot-driver-issues/
* Boot directly from rootfs without initramfs:
  ```
  ext4load mmc 1 ${kernel_addr_r} boot/vmlinuz-6.15.7
  ext4load mmc 1 ${fdt_addr_r} boot/rk3588-orangepi-5-plus.dtb
  setenv bootargs "root=/dev/mmcblk1p1 rootwait init=/bin/sh splash=verbose earlycon console=ttyS2,1500000n8 loglevel=7 raid=noautodetect clk_ignore_unused"
  booti ${kernel_addr_r} - ${fdt_addr_r}
  ```
  * `rootwait` can be omitted in case the kernel hangs up here to see further errors why the root device could not get mounted
* If everything worked as expected, a ash-shell of the initramfs-busybox should appear over the serial

## Troubleshooting


* Problems detected: clk_ignore_unused required to avoid hangup at

   `[    1.027387] clk: Disabling unused clocks`

  (see https://www.kernel.org/doc/html/v6.1/driver-api/clk.html#disabling-clock-gating-of-unused-clocks)
* The DTB seems to have a wrong sdcontroller config (or maybe the mmc driver was not properly configured in kernel build). Without `rootwait`, this error gets printed:
  <details>
    <summary>Logs</summary>

      [    1.029646] /dev/root: Can't open blockdev
      [    1.030042] VFS: Cannot open root device "/dev/mmcblk1p1" or unknown-block(0,0): error -6
      [    1.030807] Please append a correct "root=" boot option; here are the available partitions:
      [    1.031594] List of all bdev filesystems:
      [    1.031969]  ext3
      [    1.031972]  ext2
      [    1.032153]  ext4
      [    1.032334]  squashfs
      [    1.032514]  fuseblk
      [    1.032727]  bcachefs
      [    1.032933]
      [    1.033296] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
      [    1.034072] CPU: 5 UID: 0 PID: 1 Comm: swapper/0 Not tainted 6.15.7 #8 PREEMPT(voluntary)
      [    1.034848] Hardware name: Xunlong Orange Pi 5 Plus (DT)
      [    1.035347] Call trace:
      [    1.035578]  show_stack+0x20/0x38 (C)
      [    1.035931]  dump_stack_lvl+0x38/0x90
      [    1.036283]  dump_stack+0x18/0x28
      [    1.036599]  panic+0x3c8/0x458
      [    1.036893]  mount_root_generic+0x194/0x318
      [    1.037294]  mount_root+0x154/0x220
      [    1.037626]  prepare_namespace+0x78/0x2b0
      [    1.038009]  kernel_init_freeable+0x468/0x530
      [    1.038424]  kernel_init+0x38/0x228
      [    1.038755]  ret_from_fork+0x10/0x20
      [    1.039097] SMP: stopping secondary CPUs
      [    1.039473] Kernel Offset: 0x3ddfe7800000 from 0xffff800080000000
      [    1.040044] PHYS_OFFSET: 0xfff0fae880000000
      [    1.040437] CPU features: 0x0c00,000002e0,01202650,8200720b
      [    1.040961] Memory Limit: none
      [    1.041250] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
  </details>

  * Next: Try to use initrd to have a backup shell for further debugging (see https://forums.gentoo.org/viewtopic-p-8800427.html?sid=4a68621caaebb872815e3408f05cf4da)

#### Kernel Debug Log with tp_printk traces of serial/tty:

```
setenv bootargs "rdinit=/init splash=verbose earlycon console=ttyS2,1500000n8 loglevel=8 raid=noautodetect clk_ignore_unused pd_ignore_unused regulator_ignore_unused tp_printk trace_event=tty:* trace_event=serial:* initcall_debug"
```
<details>
  <summary>Logs</summary>

    [    0.000000] Booting Linux on physical CPU 0x0000000000 [0x412fd050]
    [    0.000000] Linux version 6.15.7 (paul@Gameboy) (aarch64-linux-gnu-gcc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0, GNU ld (GNU Binutils for Ubuntu) 2.38) #8 SMP PREEMPT_DYNAMIC Sat Aug 30 14:45:26 CEST 2025
    [    0.000000] KASLR enabled
    [    0.000000] Machine model: Xunlong Orange Pi 5 Plus
    [    0.000000] earlycon: uart0 at MMIO32 0x00000000feb50000 (options '1500000n8')
    [    0.000000] printk: legacy bootconsole [uart0] enabled
    [    0.000000] OF: reserved mem: 0x000000000010f000..0x000000000010f0ff (0 KiB) nomap non-reusable shmem@10f000
    [    0.000000] NUMA: Faking a node at [mem 0x0000000000200000-0x00000007ffffffff]
    [    0.000000] NODE_DATA(0) allocated [mem 0x7fbfa8c80-0x7fbfd2eff]
    [    0.000000] Zone ranges:
    [    0.000000]   DMA      [mem 0x0000000000200000-0x00000000ffffffff]
    [    0.000000]   DMA32    empty
    [    0.000000]   Normal   [mem 0x0000000100000000-0x00000007ffffffff]
    [    0.000000]   Device   empty
    [    0.000000] Movable zone start for each node
    [    0.000000] Early memory node ranges
    [    0.000000]   node   0: [mem 0x0000000000200000-0x00000000efffffff]
    [    0.000000]   node   0: [mem 0x0000000100000000-0x00000003fbffffff]
    [    0.000000]   node   0: [mem 0x00000003fc500000-0x00000003ffefffff]
    [    0.000000]   node   0: [mem 0x0000000400000000-0x00000007ffffffff]
    [    0.000000] Initmem setup node 0 [mem 0x0000000000200000-0x00000007ffffffff]
    [    0.000000] On node 0, zone DMA: 512 pages in unavailable ranges
    [    0.000000] On node 0, zone Normal: 1280 pages in unavailable ranges
    [    0.000000] On node 0, zone Normal: 256 pages in unavailable ranges
    [    0.000000] psci: probing for conduit method from DT.
    [    0.000000] psci: PSCIv1.1 detected in firmware.
    [    0.000000] psci: Using standard PSCI v0.2 function IDs
    [    0.000000] psci: MIGRATE_INFO_TYPE not supported.
    [    0.000000] psci: SMC Calling Convention v1.2
    [    0.000000] percpu: Embedded 33 pages/cpu s95448 r8192 d31528 u135168
    [    0.000000] pcpu-alloc: s95448 r8192 d31528 u135168 alloc=33*4096
    [    0.000000] pcpu-alloc: [0] 0 [0] 1 [0] 2 [0] 3 [0] 4 [0] 5 [0] 6 [0] 7
    [    0.000000] Detected VIPT I-cache on CPU0
    [    0.000000] CPU features: detected: GIC system register CPU interface
    [    0.000000] CPU features: detected: Virtualization Host Extensions
    [    0.000000] CPU features: kernel page table isolation forced ON by KASLR
    [    0.000000] CPU features: detected: Kernel page table isolation (KPTI)
    [    0.000000] CPU features: detected: ARM errata 1165522, 1319367, or 1530923
    [    0.000000] alternatives: applying boot alternatives
    [    0.000000] Kernel command line: rdinit=/init splash=verbose earlycon console=ttyS2,1500000n8 loglevel=8 raid=noautodetect clk_ignore_unused pd_ignore_unused regulator_ignore_unused tp_printk trace_event=tty:* trace_event=serial:* initcall_debug
    [    0.000000] Unknown kernel command line parameters "splash=verbose", will be passed to user space.
    [    0.000000] printk: log buffer data + meta data: 262144 + 917504 = 1179648 bytes
    [    0.000000] Dentry cache hash table entries: 4194304 (order: 13, 33554432 bytes, linear)
    [    0.000000] Inode-cache hash table entries: 2097152 (order: 12, 16777216 bytes, linear)
    [    0.000000] software IO TLB: area num 8.
    [    0.000000] software IO TLB: mapped [mem 0x00000000e89ff000-0x00000000ec9ff000] (64MB)
    [    0.000000] Fallback order for Node 0: 0
    [    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 8321024
    [    0.000000] Policy zone: Normal
    [    0.000000] mem auto-init: stack:off, heap alloc:on, heap free:off
    [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
    [    0.000000] ftrace: allocating 49900 entries in 196 pages
    [    0.000000] ftrace: allocated 196 pages with 3 groups
    [    0.000000] Dynamic Preempt: voluntary
    [    0.000000] rcu: Preemptible hierarchical RCU implementation.
    [    0.000000] rcu: 	RCU restricting CPUs from NR_CPUS=512 to nr_cpu_ids=8.
    [    0.000000] 	Trampoline variant of Tasks RCU enabled.
    [    0.000000] 	Rude variant of Tasks RCU enabled.
    [    0.000000] 	Tracing variant of Tasks RCU enabled.
    [    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
    [    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=8
    [    0.000000] RCU Tasks: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=8.
    [    0.000000] RCU Tasks Rude: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=8.
    [    0.000000] RCU Tasks Trace: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=8.
    [    0.000000] Failed to enable trace event: serial:*
    [    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
    [    0.000000] GIC: enabling workaround for GICv3: non-coherent attribute
    [    0.000000] GICv3: GIC: Using split EOI/Deactivate mode
    [    0.000000] GICv3: 480 SPIs implemented
    [    0.000000] GICv3: 0 Extended SPIs implemented
    [    0.000000] GICv3: MBI range [424:479]
    [    0.000000] GICv3: Using MBI frame 0x00000000fe610000
    [    0.000000] Root IRQ handler: gic_handle_irq
    [    0.000000] GICv3: GICv3 features: 16 PPIs
    [    0.000000] GICv3: GICD_CTRL.DS=0, SCR_EL3.FIQ=1
    [    0.000000] GICv3: CPU0: found redistributor 0 region 0:0x00000000fe680000
    [    0.000000] ITS [mem 0xfe640000-0xfe65ffff]
    [    0.000000] GIC: enabling workaround for ITS: Rockchip erratum RK3588001
    [    0.000000] GIC: enabling workaround for ITS: non-coherent attribute
    [    0.000000] ITS@0x00000000fe640000: allocated 8192 Devices @100280000 (indirect, esz 8, psz 64K, shr 0)
    [    0.000000] ITS@0x00000000fe640000: allocated 32768 Interrupt Collections @100290000 (flat, esz 2, psz 64K, shr 0)
    [    0.000000] ITS: using cache flushing for cmd queue
    [    0.000000] ITS [mem 0xfe660000-0xfe67ffff]
    [    0.000000] GIC: enabling workaround for ITS: Rockchip erratum RK3588001
    [    0.000000] GIC: enabling workaround for ITS: non-coherent attribute
    [    0.000000] ITS@0x00000000fe660000: allocated 8192 Devices @1002b0000 (indirect, esz 8, psz 64K, shr 0)
    [    0.000000] ITS@0x00000000fe660000: allocated 32768 Interrupt Collections @1002c0000 (flat, esz 2, psz 64K, shr 0)
    [    0.000000] ITS: using cache flushing for cmd queue
    [    0.000000] GICv3: using LPI property table @0x00000001002d0000
    [    0.000000] GIC: using cache flushing for LPI property table
    [    0.000000] GICv3: CPU0: using allocated LPI pending table @0x00000001002e0000
    [    0.000000] GICv3: GIC: PPI partition interrupt-partition-0[0] { /cpus/cpu@0[0] /cpus/cpu@100[1] /cpus/cpu@200[2] /cpus/cpu@300[3] }
    [    0.000000] GICv3: GIC: PPI partition interrupt-partition-1[1] { /cpus/cpu@400[4] /cpus/cpu@500[5] /cpus/cpu@600[6] /cpus/cpu@700[7] }
    [    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
    [    0.000000] arch_timer: cp15 timer(s) running at 24.00MHz (phys).
    [    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x588fe9dc0, max_idle_ns: 440795202592 ns
    [    0.000001] sched_clock: 56 bits at 24MHz, resolution 41ns, wraps every 4398046511097ns
    [    0.002108] calling  con_init+0x0/0x270 @ 0
    [    0.002657] Console: colour dummy device 80x25
    [    0.003090] initcall con_init+0x0/0x270 returned 0 after 0 usecs
    [    0.003668] calling  hvc_console_init+0x0/0x40 @ 0
    [    0.004133] initcall hvc_console_init+0x0/0x40 returned 0 after 0 usecs
    [    0.004766] calling  univ8250_console_init+0x0/0x58 @ 0
    [    0.005298] initcall univ8250_console_init+0x0/0x58 returned 0 after 0 usecs
    [    0.005972] calling  kgdboc_earlycon_late_init+0x0/0x80 @ 0
    [    0.006509] initcall kgdboc_earlycon_late_init+0x0/0x80 returned 0 after 0 usecs
    [    0.008571] Calibrating delay loop (skipped), value calculated using timer frequency.. 48.00 BogoMIPS (lpj=96000)
    [    0.009554] pid_max: default: 32768 minimum: 301
    [    0.013256] LSM: initializing lsm=lockdown,capability,landlock,yama,apparmor,ima,evm
    [    0.015235] landlock: Up and running.
    [    0.015602] Yama: becoming mindful.
    [    0.016268] AppArmor: AppArmor initialized
    [    0.018755] Mount-cache hash table entries: 65536 (order: 7, 524288 bytes, linear)
    [    0.019575] Mountpoint-cache hash table entries: 65536 (order: 7, 524288 bytes, linear)
    [    0.028787] calling  trace_init_flags_sys_enter+0x0/0x30 @ 1
    [    0.029347] initcall trace_init_flags_sys_enter+0x0/0x30 returned 0 after 0 usecs
    [    0.030063] calling  trace_init_flags_sys_exit+0x0/0x30 @ 1
    [    0.030599] initcall trace_init_flags_sys_exit+0x0/0x30 returned 0 after 0 usecs
    [    0.031305] calling  cpu_suspend_init+0x0/0x98 @ 1
    [    0.031796] initcall cpu_suspend_init+0x0/0x98 returned 0 after 0 usecs
    [    0.032433] calling  prevent_bootmem_remove_init+0x0/0x78 @ 1
    [    0.032989] initcall prevent_bootmem_remove_init+0x0/0x78 returned 0 after 0 usecs
    [    0.033713] calling  asids_init+0x0/0x128 @ 1
    [    0.034176] initcall asids_init+0x0/0x128 returned 0 after 0 usecs
    [    0.034777] calling  spawn_ksoftirqd+0x0/0x88 @ 1
    [    0.035387] initcall spawn_ksoftirqd+0x0/0x88 returned 0 after 0 usecs
    [    0.036039] calling  init_signal_sysctls+0x0/0x50 @ 1
    [    0.036537] initcall init_signal_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.037199] calling  init_umh_sysctls+0x0/0x50 @ 1
    [    0.037671] initcall init_umh_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.038307] calling  kthreads_init+0x0/0x50 @ 1
    [    0.038754] initcall kthreads_init+0x0/0x50 returned 0 after 0 usecs
    [    0.039367] calling  migration_init+0x0/0x98 @ 1
    [    0.039818] initcall migration_init+0x0/0x98 returned 0 after 0 usecs
    [    0.040454] calling  printk_set_kthreads_ready+0x0/0x68 @ 1
    [    0.041011] initcall printk_set_kthreads_ready+0x0/0x68 returned 0 after 0 usecs
    [    0.041720] calling  srcu_bootup_announce+0x0/0xa8 @ 1
    [    0.042216] rcu: Hierarchical SRCU implementation.
    [    0.042671] rcu: 	Max phase no-delay instances is 1000.
    [    0.043167] initcall srcu_bootup_announce+0x0/0xa8 returned 0 after 0 usecs
    [    0.043833] calling  rcu_spawn_gp_kthread+0x0/0x320 @ 1
    [    0.044755] initcall rcu_spawn_gp_kthread+0x0/0x320 returned 0 after 4000 usecs
    [    0.045465] calling  check_cpu_stall_init+0x0/0x48 @ 1
    [    0.045963] initcall check_cpu_stall_init+0x0/0x48 returned 0 after 0 usecs
    [    0.046630] calling  rcu_sysrq_init+0x0/0x88 @ 1
    [    0.047077] initcall rcu_sysrq_init+0x0/0x88 returned 0 after 0 usecs
    [    0.047693] calling  tmigr_init+0x0/0x1b8 @ 1
    [    0.048118] Timer migration: 1 hierarchy levels; 8 children per group; 1 crossnode level
    [    0.048948] initcall tmigr_init+0x0/0x1b8 returned 0 after 4000 usecs
    [    0.049572] calling  insert_crashkernel_resources+0x0/0xa8 @ 1
    [    0.050136] initcall insert_crashkernel_resources+0x0/0xa8 returned 0 after 0 usecs
    [    0.050868] calling  cpu_stop_init+0x0/0x140 @ 1
    [    0.051474] initcall cpu_stop_init+0x0/0x140 returned 0 after 0 usecs
    [    0.052103] calling  init_kprobes+0x0/0x1b8 @ 1
    [    0.052800] initcall init_kprobes+0x0/0x1b8 returned 0 after 0 usecs
    [    0.053451] calling  init_trace_printk+0x0/0x28 @ 1
    [    0.053955] initcall init_trace_printk+0x0/0x28 returned 0 after 0 usecs
    [    0.054602] calling  event_trace_enable_again+0x0/0x60 @ 1
    [    0.055715] Failed to enable trace event: serial:*
    [    0.056175] initcall event_trace_enable_again+0x0/0x60 returned 0 after 0 usecs
    [    0.056877] calling  irq_work_init_threads+0x0/0x10 @ 1
    [    0.057381] initcall irq_work_init_threads+0x0/0x10 returned 0 after 0 usecs
    [    0.058073] calling  jump_label_init_module+0x0/0x38 @ 1
    [    0.058589] initcall jump_label_init_module+0x0/0x38 returned 0 after 0 usecs
    [    0.059272] calling  init_zero_pfn+0x0/0x38 @ 1
    [    0.059712] initcall init_zero_pfn+0x0/0x38 returned 0 after 0 usecs
    [    0.060322] calling  init_fs_inode_sysctls+0x0/0x50 @ 1
    [    0.060832] initcall init_fs_inode_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.061506] calling  init_fs_locks_sysctls+0x0/0x50 @ 1
    [    0.062014] initcall init_fs_locks_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.062700] calling  init_fs_sysctls+0x0/0x50 @ 1
    [    0.063160] initcall init_fs_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.063791] calling  init_security_keys_sysctls+0x0/0x50 @ 1
    [    0.064350] initcall init_security_keys_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.065067] calling  dynamic_debug_init+0x0/0x2b0 @ 1
    [    0.065910] initcall dynamic_debug_init+0x0/0x2b0 returned 0 after 0 usecs
    [    0.066581] calling  dummy_timer_register+0x0/0x50 @ 1
    [    0.067102] initcall dummy_timer_register+0x0/0x50 returned 0 after 0 usecs
    [    0.067771] calling  idle_inject_init+0x0/0x38 @ 1
    [    0.068411] initcall idle_inject_init+0x0/0x38 returned 0 after 0 usecs
    [    0.069737] smp: Bringing up secondary CPUs ...
    [    0.072325] Detected VIPT I-cache on CPU1
    [    0.072420] GICv3: CPU1: found redistributor 100 region 0:0x00000000fe6a0000
    [    0.072439] GICv3: CPU1: using allocated LPI pending table @0x00000001002f0000
    [    0.072494] CPU1: Booted secondary processor 0x0000000100 [0x412fd050]
    [    0.075107] Detected VIPT I-cache on CPU2
    [    0.075204] GICv3: CPU2: found redistributor 200 region 0:0x00000000fe6c0000
    [    0.075223] GICv3: CPU2: using allocated LPI pending table @0x0000000100300000
    [    0.075278] CPU2: Booted secondary processor 0x0000000200 [0x412fd050]
    [    0.077359] Detected VIPT I-cache on CPU3
    [    0.077448] GICv3: CPU3: found redistributor 300 region 0:0x00000000fe6e0000
    [    0.077465] GICv3: CPU3: using allocated LPI pending table @0x0000000100310000
    [    0.077515] CPU3: Booted secondary processor 0x0000000300 [0x412fd050]
    [    0.079658] CPU features: detected: Spectre-v4
    [    0.079666] CPU features: detected: Spectre-BHB
    [    0.079672] CPU features: detected: SSBS not fully self-synchronizing
    [    0.079675] Detected PIPT I-cache on CPU4
    [    0.079723] GICv3: CPU4: found redistributor 400 region 0:0x00000000fe700000
    [    0.079733] GICv3: CPU4: using allocated LPI pending table @0x0000000100320000
    [    0.079764] CPU4: Booted secondary processor 0x0000000400 [0x414fd0b0]
    [    0.082597] Detected PIPT I-cache on CPU5
    [    0.082655] GICv3: CPU5: found redistributor 500 region 0:0x00000000fe720000
    [    0.082666] GICv3: CPU5: using allocated LPI pending table @0x0000000100330000
    [    0.082698] CPU5: Booted secondary processor 0x0000000500 [0x414fd0b0]
    [    0.084771] Detected PIPT I-cache on CPU6
    [    0.084827] GICv3: CPU6: found redistributor 600 region 0:0x00000000fe740000
    [    0.084836] GICv3: CPU6: using allocated LPI pending table @0x0000000100340000
    [    0.084867] CPU6: Booted secondary processor 0x0000000600 [0x414fd0b0]
    [    0.086845] Detected PIPT I-cache on CPU7
    [    0.086901] GICv3: CPU7: found redistributor 700 region 0:0x00000000fe760000
    [    0.086911] GICv3: CPU7: using allocated LPI pending table @0x0000000100350000
    [    0.086941] CPU7: Booted secondary processor 0x0000000700 [0x414fd0b0]
    [    0.087102] smp: Brought up 1 node, 8 CPUs
    [    0.105277] SMP: Total of 8 processors activated.
    [    0.105727] CPU: All CPU(s) started at EL2
    [    0.106119] CPU features: detected: 32-bit EL0 Support
    [    0.106609] CPU features: detected: Data cache clean to the PoU not required for I/D coherence
    [    0.107423] CPU features: detected: Common not Private translations
    [    0.108017] CPU features: detected: CRC32 instructions
    [    0.108521] CPU features: detected: RCpc load-acquire (LDAPR)
    [    0.109069] CPU features: detected: LSE atomic instructions
    [    0.109598] CPU features: detected: Privileged Access Never
    [    0.110127] CPU features: detected: PMUv3
    [    0.110508] CPU features: detected: RAS Extension Support
    [    0.111025] CPU features: detected: Speculative Store Bypassing Safe (SSBS)
    [    0.111796] alternatives: applying system-wide alternatives
    [    0.115681] CPU features: detected: Hardware dirty bit management on CPU4-7
    [    0.117051] Memory: 32511992K/33284096K available (17600K kernel code, 3616K rwdata, 10412K rodata, 8256K init, 1646K bss, 746308K reserved, 0K cma-reserved)
    [    0.123709] devtmpfs: initialized
    [    0.142145] calling  bpf_jit_charge_init+0x0/0x60 @ 1
    [    0.142631] initcall bpf_jit_charge_init+0x0/0x60 returned 0 after 0 usecs
    [    0.143278] calling  ipc_ns_init+0x0/0x58 @ 1
    [    0.143699] initcall ipc_ns_init+0x0/0x58 returned 0 after 0 usecs
    [    0.144289] calling  init_mmap_min_addr+0x0/0x60 @ 1
    [    0.144773] initcall init_mmap_min_addr+0x0/0x60 returned 0 after 0 usecs
    [    0.145415] calling  pci_realloc_setup_params+0x0/0x78 @ 1
    [    0.145935] initcall pci_realloc_setup_params+0x0/0x78 returned 0 after 0 usecs
    [    0.146624] calling  inet_frag_wq_init+0x0/0x68 @ 1
    [    0.147254] initcall inet_frag_wq_init+0x0/0x68 returned 0 after 0 usecs
    [    0.148001] calling  fpsimd_init+0x0/0xd8 @ 1
    [    0.148420] initcall fpsimd_init+0x0/0xd8 returned 0 after 0 usecs
    [    0.149000] calling  tagged_addr_init+0x0/0x50 @ 1
    [    0.149453] initcall tagged_addr_init+0x0/0x50 returned 0 after 0 usecs
    [    0.150073] calling  init_amu_fie+0x0/0x38 @ 1
    [    0.150493] initcall init_amu_fie+0x0/0x38 returned 0 after 0 usecs
    [    0.151083] calling  map_entry_trampoline+0x0/0x238 @ 1
    [    0.151587] initcall map_entry_trampoline+0x0/0x238 returned 0 after 0 usecs
    [    0.152251] calling  alloc_frozen_cpus+0x0/0x50 @ 1
    [    0.152718] initcall alloc_frozen_cpus+0x0/0x50 returned 0 after 0 usecs
    [    0.153350] calling  cpu_hotplug_pm_sync_init+0x0/0x40 @ 1
    [    0.153870] initcall cpu_hotplug_pm_sync_init+0x0/0x40 returned 0 after 0 usecs
    [    0.154558] calling  wq_sysfs_init+0x0/0x48 @ 1
    [    0.155035] initcall wq_sysfs_init+0x0/0x48 returned 0 after 0 usecs
    [    0.155637] calling  ksysfs_init+0x0/0xe0 @ 1
    [    0.156075] initcall ksysfs_init+0x0/0xe0 returned 0 after 0 usecs
    [    0.156660] calling  schedutil_gov_init+0x0/0x38 @ 1
    [    0.157131] initcall schedutil_gov_init+0x0/0x38 returned 0 after 0 usecs
    [    0.157769] calling  pm_init+0x0/0xe8 @ 1
    [    0.158187] initcall pm_init+0x0/0xe8 returned 0 after 0 usecs
    [    0.158735] calling  pm_disk_init+0x0/0x40 @ 1
    [    0.159167] initcall pm_disk_init+0x0/0x40 returned 0 after 0 usecs
    [    0.159756] calling  swsusp_header_init+0x0/0x50 @ 1
    [    0.160225] initcall swsusp_header_init+0x0/0x50 returned 0 after 0 usecs
    [    0.160862] calling  rcu_set_runtime_mode+0x0/0x40 @ 1
    [    0.161351] initcall rcu_set_runtime_mode+0x0/0x40 returned 0 after 0 usecs
    [    0.162005] calling  rcu_init_tasks_generic+0x0/0x100 @ 1
    [    0.162917] initcall rcu_init_tasks_generic+0x0/0x100 returned 0 after 0 usecs
    [    0.163597] calling  init_jiffies_clocksource+0x0/0x40 @ 1
    [    0.164115] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
    [    0.165029] initcall init_jiffies_clocksource+0x0/0x40 returned 0 after 0 usecs
    [    0.165722] calling  posixtimer_init+0x0/0x158 @ 1
    [    0.166185] posixtimers hash table entries: 4096 (order: 4, 65536 bytes, linear)
    [    0.166890] initcall posixtimer_init+0x0/0x158 returned 0 after 0 usecs
    [    0.167513] calling  futex_init+0x0/0x160 @ 1
    [    0.167939] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
    [    0.168611] initcall futex_init+0x0/0x160 returned 0 after 0 usecs
    [    0.169194] calling  cgroup_wq_init+0x0/0x50 @ 1
    [    0.169637] initcall cgroup_wq_init+0x0/0x50 returned 0 after 0 usecs
    [    0.170248] calling  cgroup1_wq_init+0x0/0x50 @ 1
    [    0.170708] initcall cgroup1_wq_init+0x0/0x50 returned 0 after 0 usecs
    [    0.171325] calling  ftrace_mod_cmd_init+0x0/0x28 @ 1
    [    0.171806] initcall ftrace_mod_cmd_init+0x0/0x28 returned 0 after 0 usecs
    [    0.172454] calling  init_wakeup_tracer+0x0/0x58 @ 1
    [    0.172929] initcall init_wakeup_tracer+0x0/0x58 returned 0 after 0 usecs
    [    0.173570] calling  init_graph_trace+0x0/0x98 @ 1
    [    0.174027] initcall init_graph_trace+0x0/0x98 returned 0 after 0 usecs
    [    0.174651] calling  trace_events_eprobe_init_early+0x0/0x60 @ 1
    [    0.175216] initcall trace_events_eprobe_init_early+0x0/0x60 returned 0 after 0 usecs
    [    0.175951] calling  trace_events_synth_init_early+0x0/0x58 @ 1
    [    0.176508] initcall trace_events_synth_init_early+0x0/0x58 returned 0 after 0 usecs
    [    0.177233] calling  init_kprobe_trace_early+0x0/0x48 @ 1
    [    0.177742] initcall init_kprobe_trace_early+0x0/0x48 returned 0 after 0 usecs
    [    0.178420] calling  cpu_pm_init+0x0/0x38 @ 1
    [    0.178837] initcall cpu_pm_init+0x0/0x38 returned 0 after 0 usecs
    [    0.179419] calling  bpf_offload_init+0x0/0x40 @ 1
    [    0.179876] initcall bpf_offload_init+0x0/0x40 returned 0 after 0 usecs
    [    0.180500] calling  cgroup_bpf_wq_init+0x0/0x58 @ 1
    [    0.180972] initcall cgroup_bpf_wq_init+0x0/0x58 returned 0 after 0 usecs
    [    0.181609] calling  init_events_core_sysctls+0x0/0x50 @ 1
    [    0.182141] initcall init_events_core_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.182829] calling  init_callchain_sysctls+0x0/0x50 @ 1
    [    0.183348] initcall init_callchain_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.184018] calling  memory_failure_init+0x0/0x120 @ 1
    [    0.184506] initcall memory_failure_init+0x0/0x120 returned 0 after 0 usecs
    [    0.185159] calling  execmem_late_init+0x0/0x2f8 @ 1
    [    0.185626] 2G module region forced by RANDOMIZE_MODULE_REGION_FULL
    [    0.186216] 0 pages in range for non-PLT usage
    [    0.186218] 513840 pages in range for PLT usage
    [    0.186636] initcall execmem_late_init+0x0/0x2f8 returned 0 after 0 usecs
    [    0.187701] calling  fsnotify_init+0x0/0xa8 @ 1
    [    0.188848] initcall fsnotify_init+0x0/0xa8 returned 0 after 0 usecs
    [    0.189447] calling  filelock_init+0x0/0x188 @ 1
    [    0.190083] initcall filelock_init+0x0/0x188 returned 0 after 0 usecs
    [    0.190691] calling  init_script_binfmt+0x0/0x40 @ 1
    [    0.191165] initcall init_script_binfmt+0x0/0x40 returned 0 after 0 usecs
    [    0.191804] calling  init_elf_binfmt+0x0/0x40 @ 1
    [    0.192249] initcall init_elf_binfmt+0x0/0x40 returned 0 after 0 usecs
    [    0.192863] calling  configfs_init+0x0/0x100 @ 1
    [    0.193496] initcall configfs_init+0x0/0x100 returned 0 after 0 usecs
    [    0.194105] calling  debugfs_init+0x0/0x128 @ 1
    [    0.194641] initcall debugfs_init+0x0/0x128 returned 0 after 0 usecs
    [    0.195245] calling  tracefs_init+0x0/0xd8 @ 1
    [    0.195768] initcall tracefs_init+0x0/0xd8 returned 0 after 0 usecs
    [    0.196361] calling  securityfs_init+0x0/0xd8 @ 1
    [    0.196948] initcall securityfs_init+0x0/0xd8 returned 0 after 0 usecs
    [    0.197567] calling  lockdown_secfs_init+0x0/0x50 @ 1
    [    0.198046] initcall lockdown_secfs_init+0x0/0x50 returned 0 after 0 usecs
    [    0.198691] calling  register_xor_blocks+0x0/0x68 @ 1
    [    0.199168] initcall register_xor_blocks+0x0/0x68 returned 0 after 0 usecs
    [    0.199818] calling  pinctrl_init+0x0/0xf0 @ 1
    [    0.200239] pinctrl core: initialized pinctrl subsystem
    [    0.200783] initcall pinctrl_init+0x0/0xf0 returned 0 after 0 usecs
    [    0.201375] calling  gpiolib_dev_init+0x0/0x1b8 @ 1
    [    0.201863] initcall gpiolib_dev_init+0x0/0x1b8 returned 0 after 0 usecs
    [    0.202496] calling  rk_clk_gate_link_drv_register+0x0/0x38 @ 1
    [    0.203065] initcall rk_clk_gate_link_drv_register+0x0/0x38 returned 0 after 0 usecs
    [    0.203796] calling  rockchip_clk_rk3588_drv_register+0x0/0x38 @ 1
    [    0.204389] initcall rockchip_clk_rk3588_drv_register+0x0/0x38 returned 0 after 0 usecs
    [    0.205139] calling  genpd_bus_init+0x0/0x38 @ 1
    [    0.205583] initcall genpd_bus_init+0x0/0x38 returned 0 after 0 usecs
    [    0.206189] calling  virtio_init+0x0/0x48 @ 1
    [    0.206620] initcall virtio_init+0x0/0x48 returned 0 after 0 usecs
    [    0.207202] calling  regulator_init+0x0/0x118 @ 1
    [    0.207766] probe of reg-dummy returned 0 after 0 usecs
    [    0.208260] initcall regulator_init+0x0/0x118 returned 0 after 4000 usecs
    [    0.208905] calling  iommu_init+0x0/0x58 @ 1
    [    0.209310] initcall iommu_init+0x0/0x58 returned 0 after 0 usecs
    [    0.209884] calling  component_debug_init+0x0/0x48 @ 1
    [    0.210372] initcall component_debug_init+0x0/0x48 returned 0 after 0 usecs
    [    0.211026] calling  soc_bus_register+0x0/0x68 @ 1
    [    0.211492] initcall soc_bus_register+0x0/0x68 returned 0 after 0 usecs
    [    0.212116] calling  register_cpufreq_notifier+0x0/0xd0 @ 1
    [    0.212642] initcall register_cpufreq_notifier+0x0/0xd0 returned 0 after 0 usecs
    [    0.213341] calling  opp_debug_init+0x0/0x48 @ 1
    [    0.213780] initcall opp_debug_init+0x0/0x48 returned 0 after 0 usecs
    [    0.214384] calling  cpufreq_core_init+0x0/0x128 @ 1
    [    0.214855] initcall cpufreq_core_init+0x0/0x128 returned 0 after 0 usecs
    [    0.215493] calling  cpufreq_gov_performance_init+0x0/0x38 @ 1
    [    0.216043] initcall cpufreq_gov_performance_init+0x0/0x38 returned 0 after 0 usecs
    [    0.216762] calling  cpufreq_gov_powersave_init+0x0/0x38 @ 1
    [    0.217295] initcall cpufreq_gov_powersave_init+0x0/0x38 returned 0 after 0 usecs
    [    0.218001] calling  cpufreq_gov_userspace_init+0x0/0x38 @ 1
    [    0.218534] initcall cpufreq_gov_userspace_init+0x0/0x38 returned 0 after 0 usecs
    [    0.219235] calling  CPU_FREQ_GOV_ONDEMAND_init+0x0/0x38 @ 1
    [    0.219769] initcall CPU_FREQ_GOV_ONDEMAND_init+0x0/0x38 returned 0 after 0 usecs
    [    0.220471] calling  CPU_FREQ_GOV_CONSERVATIVE_init+0x0/0x38 @ 1
    [    0.221036] initcall CPU_FREQ_GOV_CONSERVATIVE_init+0x0/0x38 returned 0 after 0 usecs
    [    0.221770] calling  cpuidle_init+0x0/0x40 @ 1
    [    0.222199] initcall cpuidle_init+0x0/0x40 returned 0 after 0 usecs
    [    0.222788] calling  arch_timer_evtstrm_register+0x0/0xa8 @ 1
    [    0.223520] initcall arch_timer_evtstrm_register+0x0/0xa8 returned 0 after 0 usecs
    [    0.224233] calling  sock_init+0x0/0x108 @ 1
    [    0.227021] initcall sock_init+0x0/0x108 returned 0 after 0 usecs
    [    0.227602] calling  net_inuse_init+0x0/0x48 @ 1
    [    0.228044] initcall net_inuse_init+0x0/0x48 returned 0 after 0 usecs
    [    0.228652] calling  sock_struct_check+0x0/0x18 @ 1
    [    0.229114] initcall sock_struct_check+0x0/0x18 returned 0 after 0 usecs
    [    0.229745] calling  init_default_flow_dissectors+0x0/0x78 @ 1
    [    0.230301] initcall init_default_flow_dissectors+0x0/0x78 returned 0 after 0 usecs
    [    0.231021] calling  netlink_proto_init+0x0/0x1a8 @ 1
    [    0.231663] NET: Registered PF_NETLINK/PF_ROUTE protocol family
    [    0.232241] initcall netlink_proto_init+0x0/0x1a8 returned 0 after 4000 usecs
    [    0.232916] calling  genl_init+0x0/0x80 @ 1
    [    0.233323] initcall genl_init+0x0/0x80 returned 0 after 0 usecs
    [    0.233891] calling  trace_boot_init+0x0/0x128 @ 1
    [    0.234348] initcall trace_boot_init+0x0/0x128 returned 0 after 0 usecs
    [    0.235094] calling  debug_monitors_init+0x0/0x50 @ 1
    [    0.235730] initcall debug_monitors_init+0x0/0x50 returned 0 after 0 usecs
    [    0.236377] calling  irq_sysfs_init+0x0/0x128 @ 1
    [    0.237096] initcall irq_sysfs_init+0x0/0x128 returned 0 after 0 usecs
    [    0.237712] calling  dma_atomic_pool_init+0x0/0x168 @ 1
    [    0.238972] DMA: preallocated 4096 KiB GFP_KERNEL pool for atomic allocations
    [    0.240391] DMA: preallocated 4096 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations
    [    0.241871] DMA: preallocated 4096 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
    [    0.242654] initcall dma_atomic_pool_init+0x0/0x168 returned 0 after 4000 usecs
    [    0.243345] calling  audit_init+0x0/0x1c8 @ 1
    [    0.243764] audit: initializing netlink subsys (disabled)
    [    0.244455] initcall audit_init+0x0/0x1c8 returned 0 after 4000 usecs
    [    0.244472] audit: type=2000 audit(0.236:1): state=initialized audit_enabled=0 res=1
    [    0.245064] calling  bdi_class_init+0x0/0x60 @ 1
    [    0.246236] initcall bdi_class_init+0x0/0x60 returned 0 after 0 usecs
    [    0.246849] calling  mm_sysfs_init+0x0/0x50 @ 1
    [    0.247280] initcall mm_sysfs_init+0x0/0x50 returned 0 after 0 usecs
    [    0.247877] calling  init_per_zone_wmark_min+0x0/0x48 @ 1
    [    0.248402] initcall init_per_zone_wmark_min+0x0/0x48 returned 0 after 0 usecs
    [    0.249083] calling  rockchip_pinctrl_drv_register+0x0/0x40 @ 1
    [    0.249656] initcall rockchip_pinctrl_drv_register+0x0/0x40 returned 0 after 0 usecs
    [    0.250385] calling  gpiolib_sysfs_init+0x0/0x50 @ 1
    [    0.250867] initcall gpiolib_sysfs_init+0x0/0x50 returned 0 after 0 usecs
    [    0.251507] calling  rockchip_gpio_init+0x0/0x38 @ 1
    [    0.251993] initcall rockchip_gpio_init+0x0/0x38 returned 0 after 0 usecs
    [    0.252634] calling  pcibus_class_init+0x0/0x38 @ 1
    [    0.253101] initcall pcibus_class_init+0x0/0x38 returned 0 after 0 usecs
    [    0.253733] calling  pci_driver_init+0x0/0x50 @ 1
    [    0.254211] initcall pci_driver_init+0x0/0x50 returned 0 after 0 usecs
    [    0.254828] calling  rio_bus_init+0x0/0x88 @ 1
    [    0.255270] initcall rio_bus_init+0x0/0x88 returned 0 after 0 usecs
    [    0.255863] calling  backlight_class_init+0x0/0x98 @ 1
    [    0.256355] initcall backlight_class_init+0x0/0x98 returned 0 after 0 usecs
    [    0.257012] calling  amba_init+0x0/0x38 @ 1
    [    0.257420] initcall amba_init+0x0/0x38 returned 0 after 0 usecs
    [    0.257988] calling  rockchip_grf_init+0x0/0x1a8 @ 1
    [    0.258588] initcall rockchip_grf_init+0x0/0x1a8 returned 0 after 0 usecs
    [    0.259226] calling  tty_class_init+0x0/0x38 @ 1
    [    0.259678] initcall tty_class_init+0x0/0x38 returned 0 after 0 usecs
    [    0.260285] calling  vtconsole_class_init+0x0/0x130 @ 1
    [    0.260812] initcall vtconsole_class_init+0x0/0x130 returned 0 after 0 usecs
    [    0.261474] calling  serdev_init+0x0/0x48 @ 1
    [    0.261895] initcall serdev_init+0x0/0x48 returned 0 after 0 usecs
    [    0.262476] calling  iommu_dev_init+0x0/0x38 @ 1
    [    0.262916] initcall iommu_dev_init+0x0/0x38 returned 0 after 0 usecs
    [    0.263522] calling  devlink_class_init+0x0/0x80 @ 1
    [    0.264000] initcall devlink_class_init+0x0/0x80 returned 0 after 0 usecs
    [    0.264639] calling  software_node_init+0x0/0x58 @ 1
    [    0.265110] initcall software_node_init+0x0/0x58 returned 0 after 0 usecs
    [    0.265749] calling  wakeup_sources_debugfs_init+0x0/0x50 @ 1
    [    0.266296] initcall wakeup_sources_debugfs_init+0x0/0x50 returned 0 after 0 usecs
    [    0.267007] calling  wakeup_sources_sysfs_init+0x0/0x48 @ 1
    [    0.267537] initcall wakeup_sources_sysfs_init+0x0/0x48 returned 0 after 0 usecs
    [    0.268237] calling  regmap_initcall+0x0/0x30 @ 1
    [    0.268725] initcall regmap_initcall+0x0/0x30 returned 0 after 0 usecs
    [    0.269341] calling  sram_init+0x0/0x38 @ 1
    [    0.269754] initcall sram_init+0x0/0x38 returned 0 after 0 usecs
    [    0.270321] calling  spi_init+0x0/0xe0 @ 1
    [    0.270728] initcall spi_init+0x0/0xe0 returned 0 after 0 usecs
    [    0.271287] calling  i2c_init+0x0/0xf0 @ 1
    [    0.271695] initcall i2c_init+0x0/0xf0 returned 0 after 0 usecs
    [    0.272256] calling  thermal_init+0x0/0x1d0 @ 1
    [    0.272716] thermal_sys: Registered thermal governor 'fair_share'
    [    0.272720] thermal_sys: Registered thermal governor 'bang_bang'
    [    0.273291] thermal_sys: Registered thermal governor 'step_wise'
    [    0.273853] thermal_sys: Registered thermal governor 'user_space'
    [    0.274416] thermal_sys: Registered thermal governor 'power_allocator'
    [    0.274992] initcall thermal_init+0x0/0x1d0 returned 0 after 0 usecs
    [    0.276197] calling  init_ladder+0x0/0x70 @ 1
    [    0.276664] cpuidle: using governor ladder
    [    0.277049] initcall init_ladder+0x0/0x70 returned 0 after 0 usecs
    [    0.277630] calling  init_menu+0x0/0x38 @ 1
    [    0.278053] cpuidle: using governor menu
    [    0.278422] initcall init_menu+0x0/0x38 returned 0 after 0 usecs
    [    0.278987] calling  teo_governor_init+0x0/0x38 @ 1
    [    0.279446] initcall teo_governor_init+0x0/0x38 returned 0 after 0 usecs
    [    0.280075] calling  kobject_uevent_init+0x0/0x28 @ 1
    [    0.280559] initcall kobject_uevent_init+0x0/0x28 returned 0 after 0 usecs
    [    0.281326] calling  reserve_memblock_reserved_regions+0x0/0x190 @ 1
    [    0.281954] initcall reserve_memblock_reserved_regions+0x0/0x190 returned 0 after 0 usecs
    [    0.282722] calling  vdso_init+0x0/0x108 @ 1
    [    0.283124] initcall vdso_init+0x0/0x108 returned 0 after 0 usecs
    [    0.283697] calling  arm64_create_dummy_rsi_dev+0x0/0x58 @ 1
    [    0.284232] initcall arm64_create_dummy_rsi_dev+0x0/0x58 returned 0 after 0 usecs
    [    0.284936] calling  arch_hw_breakpoint_init+0x0/0x128 @ 1
    [    0.285459] hw-breakpoint: found 6 breakpoint and 4 watchpoint registers.
    [    0.286269] initcall arch_hw_breakpoint_init+0x0/0x128 returned 0 after 0 usecs
    [    0.286959] calling  adjust_protection_map+0x0/0xe0 @ 1
    [    0.287454] initcall adjust_protection_map+0x0/0xe0 returned 0 after 0 usecs
    [    0.288117] calling  asids_update_limit+0x0/0xe8 @ 1
    [    0.288593] ASID allocator initialised with 32768 entries
    [    0.289099] initcall asids_update_limit+0x0/0xe8 returned 0 after 0 usecs
    [    0.289746] calling  hugetlbpage_init+0x0/0x50 @ 1
    [    0.290215] initcall hugetlbpage_init+0x0/0x50 returned 0 after 0 usecs
    [    0.290838] calling  kcmp_cookies_init+0x0/0xb8 @ 1
    [    0.291304] initcall kcmp_cookies_init+0x0/0xb8 returned 0 after 0 usecs
    [    0.291935] calling  cryptomgr_init+0x0/0x38 @ 1
    [    0.292372] initcall cryptomgr_init+0x0/0x38 returned 0 after 0 usecs
    [    0.292978] calling  crc_t10dif_arm64_init+0x0/0x90 @ 1
    [    0.293487] initcall crc_t10dif_arm64_init+0x0/0x90 returned 0 after 0 usecs
    [    0.294154] calling  dma_channel_table_init+0x0/0x228 @ 1
    [    0.294680] initcall dma_channel_table_init+0x0/0x228 returned 0 after 0 usecs
    [    0.295357] calling  dma_bus_init+0x0/0x138 @ 1
    [    0.296075] initcall dma_bus_init+0x0/0x138 returned 0 after 4000 usecs
    [    0.296698] calling  serial_base_init+0x0/0xa8 @ 1
    [    0.297184] initcall serial_base_init+0x0/0xa8 returned 0 after 0 usecs
    [    0.297807] calling  iommu_dma_init+0x0/0x48 @ 1
    [    0.298389] initcall iommu_dma_init+0x0/0x48 returned 0 after 0 usecs
    [    0.298997] calling  sdei_init+0x0/0x38 @ 1
    [    0.299401] initcall sdei_init+0x0/0x38 returned 0 after 0 usecs
    [    0.299965] calling  of_platform_default_populate_init+0x0/0xf8 @ 1
    [    0.303692] probe of fd600000.sram returned 0 after 0 usecs
    [    0.305806] probe of rockchip-gate-link-clk.701 returned 0 after 0 usecs
    [    0.307795] probe of rockchip-gate-link-clk.702 returned 0 after 0 usecs
    [    0.309716] probe of rockchip-gate-link-clk.703 returned 0 after 0 usecs
    [    0.311614] probe of rockchip-gate-link-clk.704 returned 0 after 0 usecs
    [    0.313452] probe of rockchip-gate-link-clk.705 returned 0 after 0 usecs
    [    0.315222] probe of rockchip-gate-link-clk.706 returned 0 after 0 usecs
    [    0.316885] probe of rockchip-gate-link-clk.707 returned 0 after 4000 usecs
    [    0.318526] probe of rockchip-gate-link-clk.708 returned 0 after 0 usecs
    [    0.320102] probe of rockchip-gate-link-clk.709 returned 0 after 4000 usecs
    [    0.321684] probe of rockchip-gate-link-clk.710 returned 0 after 0 usecs
    [    0.323245] probe of rockchip-gate-link-clk.711 returned 0 after 0 usecs
    [    0.324756] probe of rockchip-gate-link-clk.712 returned 0 after 4000 usecs
    [    0.326288] probe of rockchip-gate-link-clk.713 returned 0 after 0 usecs
    [    0.327777] probe of rockchip-gate-link-clk.714 returned 0 after 0 usecs
    [    0.329191] probe of rockchip-gate-link-clk.715 returned 0 after 0 usecs
    [    0.330550] probe of rockchip-gate-link-clk.716 returned 0 after 0 usecs
    [    0.331734] probe of rockchip-gate-link-clk.717 returned 0 after 0 usecs
    [    0.332771] probe of rockchip-gate-link-clk.718 returned 0 after 0 usecs
    [    0.333803] probe of rockchip-gate-link-clk.719 returned 0 after 0 usecs
    [    0.334819] probe of rockchip-gate-link-clk.720 returned 0 after 0 usecs
    [    0.335823] probe of rockchip-gate-link-clk.489 returned 0 after 0 usecs
    [    0.336825] probe of rockchip-gate-link-clk.721 returned 0 after 0 usecs
    [    0.337967] probe of fd7c0000.clock-controller returned 0 after 32000 usecs
    [    0.342019] /vop@fdd90000: Fixed dependency cycle(s) with /hdmi@fde80000
    [    0.342691] /hdmi@fde80000: Fixed dependency cycle(s) with /vop@fdd90000
    [    0.346410] /pcie@fe180000: Fixed dependency cycle(s) with /pcie@fe180000/legacy-interrupt-controller
    [    0.347541] /pcie@fe190000: Fixed dependency cycle(s) with /pcie@fe190000/legacy-interrupt-controller
    [    0.351263] /i2c@fec80000/usb-typec@22/connector: Fixed dependency cycle(s) with /usb@fc000000
    [    0.352841] /i2c@fec80000/usb-typec@22/connector: Fixed dependency cycle(s) with /phy@fed80000
    [    0.353678] /usb@fc000000: Fixed dependency cycle(s) with /phy@fed80000
    [    0.354330] /phy@fed80000: Fixed dependency cycle(s) with /i2c@fec80000/usb-typec@22/connector
    [    0.355611] probe of ff001000.sram returned 0 after 0 usecs
    [    0.358328] gpio gpiochip0: Static allocation of GPIO base is deprecated, use dynamic allocation.
    [    0.359723] rockchip-gpio fd8a0000.gpio: probed /pinctrl/gpio@fd8a0000
    [    0.360370] probe of fd8a0000.gpio returned 0 after 4000 usecs
    [    0.361078] gpio gpiochip1: Static allocation of GPIO base is deprecated, use dynamic allocation.
    [    0.362109] rockchip-gpio fec20000.gpio: probed /pinctrl/gpio@fec20000
    [    0.362734] probe of fec20000.gpio returned 0 after 0 usecs
    [    0.363420] gpio gpiochip2: Static allocation of GPIO base is deprecated, use dynamic allocation.
    [    0.364440] rockchip-gpio fec30000.gpio: probed /pinctrl/gpio@fec30000
    [    0.365066] probe of fec30000.gpio returned 0 after 4000 usecs
    [    0.365817] gpio gpiochip3: Static allocation of GPIO base is deprecated, use dynamic allocation.
    [    0.366829] rockchip-gpio fec40000.gpio: probed /pinctrl/gpio@fec40000
    [    0.367453] probe of fec40000.gpio returned 0 after 0 usecs
    [    0.368184] gpio gpiochip4: Static allocation of GPIO base is deprecated, use dynamic allocation.
    [    0.369212] rockchip-gpio fec50000.gpio: probed /pinctrl/gpio@fec50000
    [    0.369837] probe of fec50000.gpio returned 0 after 0 usecs
    [    0.370909] probe of pinctrl returned 0 after 12000 usecs
    [    0.372535] /vop@fdd90000: Fixed dependency cycle(s) with /hdmi@fdea0000
    [    0.373229] /hdmi@fdea0000: Fixed dependency cycle(s) with /vop@fdd90000
    [    0.374314] /pcie@fe150000: Fixed dependency cycle(s) with /pcie@fe150000/legacy-interrupt-controller
    [    0.375517] /pcie@fe170000: Fixed dependency cycle(s) with /pcie@fe170000/legacy-interrupt-controller
    [    0.378811] /hdmi@fde80000: Fixed dependency cycle(s) with /hdmi0-con
    [    0.379448] /hdmi0-con: Fixed dependency cycle(s) with /hdmi@fde80000
    [    0.380147] /hdmi@fdea0000: Fixed dependency cycle(s) with /hdmi1-con
    [    0.380795] /hdmi1-con: Fixed dependency cycle(s) with /hdmi@fdea0000
    [    0.381752] initcall of_platform_default_populate_init+0x0/0xf8 returned 0 after 80000 usecs
    [    0.382671] calling  register_mte_tcf_preferred_sysctl+0x0/0xd8 @ 1
    [    0.383263] initcall register_mte_tcf_preferred_sysctl+0x0/0xd8 returned 0 after 0 usecs
    [    0.384024] calling  uid_cache_init+0x0/0x108 @ 1
    [    0.384483] initcall uid_cache_init+0x0/0x108 returned 0 after 0 usecs
    [    0.385099] calling  pid_namespace_sysctl_init+0x0/0x40 @ 1
    [    0.385651] initcall pid_namespace_sysctl_init+0x0/0x40 returned 0 after 0 usecs
    [    0.386350] calling  param_sysfs_init+0x0/0x78 @ 1
    [    0.386809] initcall param_sysfs_init+0x0/0x78 returned 0 after 0 usecs
    [    0.387434] calling  user_namespace_sysctl_init+0x0/0xf8 @ 1
    [    0.387986] initcall user_namespace_sysctl_init+0x0/0xf8 returned 0 after 0 usecs
    [    0.388693] calling  proc_schedstat_init+0x0/0x58 @ 1
    [    0.389172] initcall proc_schedstat_init+0x0/0x58 returned 0 after 0 usecs
    [    0.389822] calling  pm_sysrq_init+0x0/0x40 @ 1
    [    0.390296] initcall pm_sysrq_init+0x0/0x40 returned 0 after 0 usecs
    [    0.390895] calling  create_proc_profile+0x0/0x78 @ 1
    [    0.391374] initcall create_proc_profile+0x0/0x78 returned 0 after 0 usecs
    [    0.392020] calling  crash_save_vmcoreinfo_init+0x0/0x6b0 @ 1
    [    0.392637] initcall crash_save_vmcoreinfo_init+0x0/0x6b0 returned 0 after 0 usecs
    [    0.393348] calling  crash_notes_memory_init+0x0/0x68 @ 1
    [    0.393869] initcall crash_notes_memory_init+0x0/0x68 returned 0 after 0 usecs
    [    0.394550] calling  cgroup_sysfs_init+0x0/0x40 @ 1
    [    0.395016] initcall cgroup_sysfs_init+0x0/0x40 returned 0 after 0 usecs
    [    0.395647] calling  user_namespaces_init+0x0/0x88 @ 1
    [    0.396246] initcall user_namespaces_init+0x0/0x88 returned 0 after 0 usecs
    [    0.396902] calling  hung_task_init+0x0/0xa8 @ 1
    [    0.397495] initcall hung_task_init+0x0/0xa8 returned 0 after 0 usecs
    [    0.398109] calling  trace_eval_init+0x0/0xb8 @ 1
    [    0.398575] initcall trace_eval_init+0x0/0xb8 returned 0 after 0 usecs
    [    0.399192] calling  send_signal_irq_work_init+0x0/0xc8 @ 1
    [    0.399714] initcall send_signal_irq_work_init+0x0/0xc8 returned 0 after 0 usecs
    [    0.400409] calling  dev_map_init+0x0/0x40 @ 1
    [    0.400830] initcall dev_map_init+0x0/0x40 returned 0 after 0 usecs
    [    0.401418] calling  netns_bpf_init+0x0/0x38 @ 1
    [    0.401855] initcall netns_bpf_init+0x0/0x38 returned 0 after 0 usecs
    [    0.402464] calling  oom_init+0x0/0x78 @ 1
    [    0.403004] initcall oom_init+0x0/0x78 returned 0 after 0 usecs
    [    0.403563] calling  init_user_buckets+0x0/0x58 @ 1
    [    0.408845] initcall init_user_buckets+0x0/0x58 returned 0 after 8000 usecs
    [    0.409501] calling  init_vm_util_sysctls+0x0/0x50 @ 1
    [    0.409992] initcall init_vm_util_sysctls+0x0/0x50 returned 0 after 0 usecs
    [    0.410650] calling  default_bdi_init+0x0/0x50 @ 1
    [    0.411300] initcall default_bdi_init+0x0/0x50 returned 0 after 0 usecs
    [    0.411925] calling  cgwb_init+0x0/0x50 @ 1
    [    0.412326] initcall cgwb_init+0x0/0x50 returned 0 after 0 usecs
    [    0.412892] calling  percpu_enable_async+0x0/0x28 @ 1
    [    0.413369] initcall percpu_enable_async+0x0/0x28 returned 0 after 0 usecs
    [    0.414016] calling  kcompactd_init+0x0/0xb8 @ 1
    [    0.414588] initcall kcompactd_init+0x0/0xb8 returned 0 after 0 usecs
    [    0.415200] calling  init_user_reserve+0x0/0x40 @ 1
    [    0.415662] initcall init_user_reserve+0x0/0x40 returned 0 after 0 usecs
    [    0.416291] calling  init_admin_reserve+0x0/0x38 @ 1
    [    0.416758] initcall init_admin_reserve+0x0/0x38 returned 0 after 0 usecs
    [    0.417396] calling  init_reserve_notifier+0x0/0x60 @ 1
    [    0.417888] initcall init_reserve_notifier+0x0/0x60 returned 0 after 0 usecs
    [    0.418550] calling  swap_init_sysfs+0x0/0xa0 @ 1
    [    0.419001] initcall swap_init_sysfs+0x0/0xa0 returned 0 after 0 usecs
    [    0.419621] calling  swapfile_init+0x0/0x118 @ 1
    [    0.420060] initcall swapfile_init+0x0/0x118 returned 0 after 0 usecs
    [    0.420668] calling  hugetlb_init+0x0/0x940 @ 1
    [    0.421101] HugeTLB: allocation took 0ms with hugepage_allocation_threads=2
    [    0.421753] HugeTLB: allocation took 0ms with hugepage_allocation_threads=2
    [    0.422408] HugeTLB: registered 1.00 GiB page size, pre-allocated 0 pages
    [    0.423044] HugeTLB: 0 KiB vmemmap can be freed for a 1.00 GiB page
    [    0.423635] HugeTLB: registered 32.0 MiB page size, pre-allocated 0 pages
    [    0.424270] HugeTLB: 0 KiB vmemmap can be freed for a 32.0 MiB page
    [    0.424857] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages
    [    0.425492] HugeTLB: 0 KiB vmemmap can be freed for a 2.00 MiB page
    [    0.426079] HugeTLB: registered 64.0 KiB page size, pre-allocated 0 pages
    [    0.426714] HugeTLB: 0 KiB vmemmap can be freed for a 64.0 KiB page
    [    0.427437] initcall hugetlb_init+0x0/0x940 returned 0 after 4000 usecs
    [    0.428072] calling  ksm_init+0x0/0x208 @ 1
    [    0.428675] initcall ksm_init+0x0/0x208 returned 0 after 0 usecs
    [    0.429245] calling  memory_tier_init+0x0/0x108 @ 1
    [    0.429739] initcall memory_tier_init+0x0/0x108 returned 0 after 0 usecs
    [    0.430372] calling  numa_init_sysfs+0x0/0xa0 @ 1
    [    0.430822] initcall numa_init_sysfs+0x0/0xa0 returned 0 after 0 usecs
    [    0.431439] calling  hugepage_init+0x0/0x428 @ 1
    [    0.432299] initcall hugepage_init+0x0/0x428 returned 0 after 4000 usecs
    [    0.432935] calling  mem_cgroup_init+0x0/0x1a0 @ 1
    [    0.433386] initcall mem_cgroup_init+0x0/0x1a0 returned 0 after 0 usecs
    [    0.434007] calling  mem_cgroup_swap_init+0x0/0x80 @ 1
    [    0.434501] initcall mem_cgroup_swap_init+0x0/0x80 returned 0 after 0 usecs
    [    0.435154] calling  page_idle_init+0x0/0x70 @ 1
    [    0.435592] initcall page_idle_init+0x0/0x70 returned 0 after 0 usecs
    [    0.436202] calling  init_msg_buckets+0x0/0x58 @ 1
    [    0.441643] initcall init_msg_buckets+0x0/0x58 returned 0 after 4000 usecs
    [    0.442295] calling  sel_ib_pkey_init+0x0/0xc8 @ 1
    [    0.442750] initcall sel_ib_pkey_init+0x0/0xc8 returned 0 after 0 usecs
    [    0.443375] calling  seqiv_module_init+0x0/0x38 @ 1
    [    0.443836] initcall seqiv_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.444471] calling  dh_init+0x0/0x70 @ 1
    [    0.444852] initcall dh_init+0x0/0x70 returned 0 after 0 usecs
    [    0.445400] calling  rsa_init+0x0/0xc0 @ 1
    [    0.445789] initcall rsa_init+0x0/0xc0 returned 0 after 0 usecs
    [    0.446345] calling  hmac_module_init+0x0/0x38 @ 1
    [    0.446798] initcall hmac_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.447419] calling  crypto_null_mod_init+0x0/0xa8 @ 1
    [    0.447905] initcall crypto_null_mod_init+0x0/0xa8 returned 0 after 0 usecs
    [    0.448562] calling  md5_mod_init+0x0/0x38 @ 1
    [    0.448982] initcall md5_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.449572] calling  sha1_generic_mod_init+0x0/0x38 @ 1
    [    0.450065] initcall sha1_generic_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.450728] calling  sha256_generic_mod_init+0x0/0x38 @ 1
    [    0.451238] initcall sha256_generic_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.451917] calling  sha512_generic_mod_init+0x0/0x38 @ 1
    [    0.452428] initcall sha512_generic_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.453108] calling  sha3_generic_mod_init+0x0/0x40 @ 1
    [    0.453603] initcall sha3_generic_mod_init+0x0/0x40 returned 0 after 0 usecs
    [    0.454265] calling  crypto_ecb_module_init+0x0/0x38 @ 1
    [    0.454766] initcall crypto_ecb_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.455436] calling  crypto_cbc_module_init+0x0/0x38 @ 1
    [    0.455936] initcall crypto_cbc_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.456606] calling  crypto_cts_module_init+0x0/0x38 @ 1
    [    0.457106] initcall crypto_cts_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.457779] calling  xts_module_init+0x0/0x38 @ 1
    [    0.458224] initcall xts_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.458837] calling  crypto_ctr_module_init+0x0/0x38 @ 1
    [    0.459339] initcall crypto_ctr_module_init+0x0/0x38 returned 0 after 0 usecs
    [    0.460009] calling  crypto_gcm_module_init+0x0/0xa0 @ 1
    [    0.460511] initcall crypto_gcm_module_init+0x0/0xa0 returned 0 after 0 usecs
    [    0.461182] calling  aes_init+0x0/0x38 @ 1
    [    0.461570] initcall aes_init+0x0/0x38 returned 0 after 0 usecs
    [    0.462126] calling  deflate_mod_init+0x0/0x38 @ 1
    [    0.462580] initcall deflate_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.463202] calling  crc32c_mod_init+0x0/0x48 @ 1
    [    0.463649] initcall crc32c_mod_init+0x0/0x48 returned 0 after 0 usecs
    [    0.464262] calling  lzo_mod_init+0x0/0x38 @ 1
    [    0.464682] initcall lzo_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.465273] calling  lzorle_mod_init+0x0/0x38 @ 1
    [    0.465719] initcall lzorle_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.466331] calling  lz4_mod_init+0x0/0x30 @ 1
    [    0.466750] initcall lz4_mod_init+0x0/0x30 returned 0 after 0 usecs
    [    0.467339] calling  drbg_init+0x0/0x148 @ 1
    [    0.467785] initcall drbg_init+0x0/0x148 returned 0 after 0 usecs
    [    0.468358] calling  ghash_mod_init+0x0/0x38 @ 1
    [    0.468797] initcall ghash_mod_init+0x0/0x38 returned 0 after 0 usecs
    [    0.469406] calling  ecdh_init+0x0/0xd0 @ 1
    [    0.469809] initcall ecdh_init+0x0/0xd0 returned 0 after 0 usecs
    [    0.470373] calling  init_bio+0x0/0xe8 @ 1
    [    0.471032] initcall init_bio+0x0/0xe8 returned 0 after 0 usecs
    [    0.471590] calling  blk_ioc_init+0x0/0x80 @ 1
    [    0.472013] initcall blk_ioc_init+0x0/0x80 returned 0 after 0 usecs
    [    0.472603] calling  blk_mq_init+0x0/0x1d0 @ 1
    [    0.473024] initcall blk_mq_init+0x0/0x1d0 returned 0 after 0 usecs
    [    0.473618] calling  genhd_device_init+0x0/0x80 @ 1
    [    0.474401] initcall genhd_device_init+0x0/0x80 returned 0 after 0 usecs
    [    0.475034] calling  blkcg_punt_bio_init+0x0/0x50 @ 1
    [    0.475729] initcall blkcg_punt_bio_init+0x0/0x50 returned 0 after 0 usecs
    [    0.476379] calling  blk_integrity_auto_init+0x0/0xe0 @ 1
    [    0.477178] initcall blk_integrity_auto_init+0x0/0xe0 returned 0 after 0 usecs
    [    0.477864] calling  bio_crypt_ctx_init+0x0/0x1a8 @ 1
    [    0.478373] initcall bio_crypt_ctx_init+0x0/0x1a8 returned 0 after 0 usecs
    [    0.479021] calling  blk_crypto_sysfs_init+0x0/0xe0 @ 1
    [    0.479513] initcall blk_crypto_sysfs_init+0x0/0xe0 returned 0 after 0 usecs
    [    0.480176] calling  io_wq_init+0x0/0x60 @ 1
    [    0.480581] initcall io_wq_init+0x0/0x60 returned 0 after 0 usecs
    [    0.481156] calling  raid6_select_algo+0x0/0x460 @ 1
    [    0.548370] raid6: neonx8   gen()  3775 MB/s
    [    0.616459] raid6: neonx4   gen()  3708 MB/s
    [    0.684544] raid6: neonx2   gen()  3545 MB/s
    [    0.752637] raid6: neonx1   gen()  2869 MB/s
    [    0.820726] raid6: int64x8  gen()  1718 MB/s
    [    0.888824] raid6: int64x4  gen()  1975 MB/s
    [    0.956924] raid6: int64x2  gen()  1684 MB/s
    [    1.025007] raid6: int64x1  gen()  1382 MB/s
    [    1.025408] raid6: using algorithm neonx8 gen() 3775 MB/s
    [    1.093096] raid6: .... xor() 2972 MB/s, rmw enabled
    [    1.093561] raid6: using neon recovery algorithm
    [    1.093996] initcall raid6_select_algo+0x0/0x460 returned 0 after 612000 usecs
    [    1.094680] calling  sg_pool_init+0x0/0x120 @ 1
    [    1.095235] initcall sg_pool_init+0x0/0x120 returned 0 after 0 usecs
    [    1.095846] calling  irq_poll_setup+0x0/0xf0 @ 1
    [    1.096294] initcall irq_poll_setup+0x0/0xf0 returned 0 after 0 usecs
    [    1.096900] calling  sx150x_init+0x0/0x38 @ 1
    [    1.097374] initcall sx150x_init+0x0/0x38 returned 0 after 0 usecs
    [    1.097960] calling  gpiolib_debugfs_init+0x0/0x58 @ 1
    [    1.098498] initcall gpiolib_debugfs_init+0x0/0x58 returned 0 after 0 usecs
    [    1.099154] calling  swnode_gpio_init+0x0/0x70 @ 1
    [    1.099631] initcall swnode_gpio_init+0x0/0x70 returned 0 after 0 usecs
    [    1.100255] calling  palmas_gpio_init+0x0/0x38 @ 1
    [    1.100897] initcall palmas_gpio_init+0x0/0x38 returned 0 after 0 usecs
    [    1.101522] calling  rc5t583_gpio_init+0x0/0x38 @ 1
    [    1.102012] initcall rc5t583_gpio_init+0x0/0x38 returned 0 after 0 usecs
    [    1.102645] calling  tps6586x_gpio_init+0x0/0x38 @ 1
    [    1.103142] initcall tps6586x_gpio_init+0x0/0x38 returned 0 after 0 usecs
    [    1.103782] calling  tps65910_gpio_init+0x0/0x38 @ 1
    [    1.104278] initcall tps65910_gpio_init+0x0/0x38 returned 0 after 0 usecs
    [    1.104924] calling  pwm_init+0x0/0x98 @ 1
    [    1.105332] initcall pwm_init+0x0/0x98 returned 0 after 0 usecs
    [    1.105893] calling  leds_init+0x0/0x68 @ 1
    [    1.106315] initcall leds_init+0x0/0x68 returned 0 after 0 usecs
    [    1.106883] calling  pci_slot_init+0x0/0x70 @ 1
    [    1.107317] initcall pci_slot_init+0x0/0x70 returned 0 after 0 usecs
    [    1.107915] calling  fbmem_init+0x0/0xb8 @ 1
    [    1.108394] initcall fbmem_init+0x0/0xb8 returned 0 after 0 usecs
    [    1.108977] calling  misc_init+0x0/0xe0 @ 1
    [    1.109380] initcall misc_init+0x0/0xe0 returned 0 after 0 usecs
    [    1.109947] calling  tpm_init+0x0/0x120 @ 1
    [    1.110501] initcall tpm_init+0x0/0x120 returned 0 after 0 usecs
    [    1.111068] calling  iommu_subsys_init+0x0/0x1e0 @ 1
    [    1.111537] iommu: Default domain type: Translated
    [    1.111987] iommu: DMA domain TLB invalidation policy: lazy mode
    [    1.112551] initcall iommu_subsys_init+0x0/0x1e0 returned 0 after 0 usecs
    [    1.113195] calling  cn_init+0x0/0x120 @ 1
    [    1.113625] initcall cn_init+0x0/0x120 returned 0 after 0 usecs
    [    1.114181] calling  register_cpu_capacity_sysctl+0x0/0x58 @ 1
    [    1.115167] initcall register_cpu_capacity_sysctl+0x0/0x58 returned 0 after 0 usecs
    [    1.115890] calling  pm860x_i2c_init+0x0/0x78 @ 1
    [    1.116350] initcall pm860x_i2c_init+0x0/0x78 returned 0 after 0 usecs
    [    1.116966] calling  wm8400_driver_init+0x0/0x70 @ 1
    [    1.117452] initcall wm8400_driver_init+0x0/0x70 returned 0 after 0 usecs
    [    1.118093] calling  wm831x_i2c_init+0x0/0x70 @ 1
    [    1.118544] initcall wm831x_i2c_init+0x0/0x70 returned 0 after 0 usecs
    [    1.119159] calling  wm831x_spi_init+0x0/0x60 @ 1
    [    1.119613] initcall wm831x_spi_init+0x0/0x60 returned 0 after 0 usecs
    [    1.120229] calling  wm8350_i2c_init+0x0/0x38 @ 1
    [    1.120688] initcall wm8350_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.121305] calling  tps65910_i2c_init+0x0/0x38 @ 1
    [    1.121780] initcall tps65910_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.122410] calling  ezx_pcap_init+0x0/0x40 @ 1
    [    1.122846] initcall ezx_pcap_init+0x0/0x40 returned 0 after 0 usecs
    [    1.123446] calling  da903x_init+0x0/0x38 @ 1
    [    1.123868] initcall da903x_init+0x0/0x38 returned 0 after 0 usecs
    [    1.124451] calling  da9052_spi_init+0x0/0x70 @ 1
    [    1.124903] initcall da9052_spi_init+0x0/0x70 returned 0 after 0 usecs
    [    1.125518] calling  da9052_i2c_init+0x0/0x70 @ 1
    [    1.125975] initcall da9052_i2c_init+0x0/0x70 returned 0 after 0 usecs
    [    1.126590] calling  lp8788_init+0x0/0x38 @ 1
    [    1.127011] initcall lp8788_init+0x0/0x38 returned 0 after 0 usecs
    [    1.127593] calling  da9055_i2c_init+0x0/0x70 @ 1
    [    1.128047] initcall da9055_i2c_init+0x0/0x70 returned 0 after 0 usecs
    [    1.128663] calling  max77843_i2c_init+0x0/0x38 @ 1
    [    1.129137] initcall max77843_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.129769] calling  max8925_i2c_init+0x0/0x70 @ 1
    [    1.130236] initcall max8925_i2c_init+0x0/0x70 returned 0 after 0 usecs
    [    1.130860] calling  max8997_i2c_init+0x0/0x38 @ 1
    [    1.131321] initcall max8997_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.131945] calling  max8998_i2c_init+0x0/0x38 @ 1
    [    1.132412] initcall max8998_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.133036] calling  tps6586x_init+0x0/0x38 @ 1
    [    1.133473] initcall tps6586x_init+0x0/0x38 returned 0 after 0 usecs
    [    1.134072] calling  tps65090_init+0x0/0x38 @ 1
    [    1.134512] initcall tps65090_init+0x0/0x38 returned 0 after 0 usecs
    [    1.135112] calling  aat2870_init+0x0/0x38 @ 1
    [    1.135539] initcall aat2870_init+0x0/0x38 returned 0 after 0 usecs
    [    1.136131] calling  palmas_i2c_init+0x0/0x38 @ 1
    [    1.136584] initcall palmas_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.137199] calling  rc5t583_i2c_init+0x0/0x38 @ 1
    [    1.137661] initcall rc5t583_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.138286] calling  as3711_i2c_init+0x0/0x38 @ 1
    [    1.138742] initcall as3711_i2c_init+0x0/0x38 returned 0 after 0 usecs
    [    1.139359] calling  libnvdimm_init+0x0/0x90 @ 1
    [    1.139864] initcall libnvdimm_init+0x0/0x90 returned 0 after 0 usecs
    [    1.140473] calling  dax_core_init+0x0/0x150 @ 1
    [    1.141182] initcall dax_core_init+0x0/0x150 returned 0 after 4000 usecs
    [    1.141818] calling  dma_buf_init+0x0/0xd0 @ 1
    [    1.142272] initcall dma_buf_init+0x0/0xd0 returned 0 after 0 usecs
    [    1.142871] calling  dma_heap_init+0x0/0xb8 @ 1
    [    1.143309] initcall dma_heap_init+0x0/0xb8 returned 0 after 0 usecs
    [    1.143909] calling  init_scsi+0x0/0xb8 @ 1
    [    1.144422] SCSI subsystem initialized
    [    1.144774] initcall init_scsi+0x0/0xb8 returned 0 after 0 usecs
    [    1.145343] calling  ata_init+0x0/0x3e8 @ 1
    [    1.145903] libata version 3.00 loaded.
    [    1.146263] initcall ata_init+0x0/0x3e8 returned 0 after 0 usecs
    [    1.146832] calling  phy_init+0x0/0x390 @ 1
    [    1.147276] initcall phy_init+0x0/0x390 returned 0 after 0 usecs
    [    1.147845] calling  usb_common_init+0x0/0x48 @ 1
    [    1.148298] initcall usb_common_init+0x0/0x48 returned 0 after 0 usecs
    [    1.148915] calling  usb_init+0x0/0x1e0 @ 1
    [    1.149360] usbcore: registered new interface driver usbfs
    [    1.149889] usbcore: registered new interface driver hub
    [    1.150401] usbcore: registered new device driver usb
    [    1.150875] initcall usb_init+0x0/0x1e0 returned 0 after 0 usecs
    [    1.151448] calling  usb_roles_init+0x0/0x38 @ 1
    [    1.151892] initcall usb_roles_init+0x0/0x38 returned 0 after 0 usecs
    [    1.152502] calling  serio_init+0x0/0x70 @ 1
    [    1.152925] initcall serio_init+0x0/0x70 returned 0 after 0 usecs
    [    1.153501] calling  input_init+0x0/0x178 @ 1
    [    1.153923] initcall input_init+0x0/0x178 returned 0 after 0 usecs
    [    1.154508] calling  rtc_init+0x0/0x50 @ 1
    [    1.154903] initcall rtc_init+0x0/0x50 returned 0 after 0 usecs
    [    1.155467] calling  dw_i2c_init_driver+0x0/0x38 @ 1
    [    1.156079] initcall dw_i2c_init_driver+0x0/0x38 returned 0 after 0 usecs
    [    1.156716] calling  media_devnode_init+0x0/0xc0 @ 1
    [    1.157183] mc: Linux media interface: v0.10
    [    1.157595] initcall media_devnode_init+0x0/0xc0 returned 0 after 4000 usecs
    [    1.158257] calling  v4l2_async_init+0x0/0x68 @ 1
    [    1.158705] initcall v4l2_async_init+0x0/0x68 returned 0 after 0 usecs
    [    1.159317] calling  videodev_init+0x0/0xb8 @ 1
    [    1.159748] videodev: Linux video capture interface: v2.00
    [    1.160268] initcall videodev_init+0x0/0xb8 returned 0 after 0 usecs
    [    1.160864] calling  init_dvbdev+0x0/0x120 @ 1
    [    1.161296] initcall init_dvbdev+0x0/0x120 returned 0 after 0 usecs
    [    1.161886] calling  rc_core_init+0x0/0x120 @ 1
    [    1.162331] initcall rc_core_init+0x0/0x120 returned 0 after 0 usecs
    [    1.162927] calling  pps_init+0x0/0x100 @ 1
    [    1.163325] pps_core: LinuxPPS API ver. 1 registered
    [    1.163795] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
    [    1.164650] initcall pps_init+0x0/0x100 returned 0 after 0 usecs
    [    1.165214] calling  ptp_init+0x0/0xc8 @ 1
    [    1.165604] PTP clock support registered
    [    1.165971] initcall ptp_init+0x0/0xc8 returned 0 after 0 usecs
    [    1.166528] calling  power_supply_class_init+0x0/0x38 @ 1
    [    1.167048] initcall power_supply_class_init+0x0/0x38 returned 0 after 0 usecs
    [    1.167727] calling  hwmon_init+0x0/0x68 @ 1
    [    1.168137] initcall hwmon_init+0x0/0x68 returned 0 after 0 usecs
    [    1.168709] calling  md_init+0x0/0x1c0 @ 1
    [    1.169417] initcall md_init+0x0/0x1c0 returned 0 after 4000 usecs
    [    1.170001] calling  edac_init+0x0/0xb8 @ 1
    [    1.170396] EDAC MC: Ver: 3.0.0
    [    1.170888] initcall edac_init+0x0/0xb8 returned 0 after 0 usecs
    [    1.171455] calling  mmc_init+0x0/0x68 @ 1
    [    1.171876] initcall mmc_init+0x0/0x68 returned 0 after 0 usecs
    [    1.172441] calling  psci_hibernate_init+0x0/0x90 @ 1
    [    1.172918] initcall psci_hibernate_init+0x0/0x90 returned 0 after 0 usecs
    [    1.173564] calling  vme_init+0x0/0x38 @ 1
    [    1.173965] initcall vme_init+0x0/0x38 returned 0 after 0 usecs
    [    1.174523] calling  remoteproc_init+0x0/0xa0 @ 1
    [    1.174988] initcall remoteproc_init+0x0/0xa0 returned 0 after 0 usecs
    [    1.175603] calling  devfreq_init+0x0/0x120 @ 1
    [    1.176232] initcall devfreq_init+0x0/0x120 returned 0 after 0 usecs
    [    1.176838] calling  devfreq_event_init+0x0/0x90 @ 1
    [    1.177313] initcall devfreq_event_init+0x0/0x90 returned 0 after 0 usecs
    [    1.177952] calling  devfreq_simple_ondemand_init+0x0/0x38 @ 1
    [    1.178503] initcall devfreq_simple_ondemand_init+0x0/0x38 returned 0 after 0 usecs
    [    1.179224] calling  devfreq_performance_init+0x0/0x38 @ 1
    [    1.179742] initcall devfreq_performance_init+0x0/0x38 returned 0 after 0 usecs
    [    1.180430] calling  devfreq_powersave_init+0x0/0x38 @ 1
    [    1.180939] initcall devfreq_powersave_init+0x0/0x38 returned 0 after 0 usecs
    [    1.181611] calling  devfreq_userspace_init+0x0/0x38 @ 1
    [    1.182113] initcall devfreq_userspace_init+0x0/0x38 returned 0 after 0 usecs
    [    1.182785] calling  devfreq_passive_init+0x0/0x38 @ 1
    [    1.183270] initcall devfreq_passive_init+0x0/0x38 returned 0 after 0 usecs
    [    1.183926] calling  arm_pmu_hp_init+0x0/0x88 @ 1
    [    1.184372] initcall arm_pmu_hp_init+0x0/0x88 returned 0 after 0 usecs
    [    1.184990] calling  ras_init+0x0/0x30 @ 1
    [    1.185384] initcall ras_init+0x0/0x30 returned 0 after 0 usecs
    [    1.185944] calling  nvmem_init+0x0/0x78 @ 1
    [    1.186378] initcall nvmem_init+0x0/0x78 returned 0 after 0 usecs
    [    1.186954] calling  dpll_init+0x0/0x38 @ 1
    [    1.187388] initcall dpll_init+0x0/0x38 returned 0 after 0 usecs
    [    1.187957] calling  proto_init+0x0/0x38 @ 1
    [    1.188365] initcall proto_init+0x0/0x38 returned 0 after 0 usecs
    [    1.188941] calling  net_dev_init+0x0/0x410 @ 1
    [    1.189635] initcall net_dev_init+0x0/0x410 returned 0 after 0 usecs
    [    1.190238] calling  neigh_init+0x0/0x40 @ 1
    [    1.190646] initcall neigh_init+0x0/0x40 returned 0 after 0 usecs
    [    1.191221] calling  fib_notifier_init+0x0/0x38 @ 1
    [    1.191685] initcall fib_notifier_init+0x0/0x38 returned 0 after 0 usecs
    [    1.192316] calling  netdev_genl_init+0x0/0x70 @ 1
    [    1.192787] initcall netdev_genl_init+0x0/0x70 returned 0 after 0 usecs
    [    1.193417] calling  page_pool_user_init+0x0/0x38 @ 1
    [    1.193896] initcall page_pool_user_init+0x0/0x38 returned 0 after 0 usecs
    [    1.194544] calling  fib_rules_init+0x0/0xb0 @ 1
    [    1.194984] initcall fib_rules_init+0x0/0xb0 returned 0 after 0 usecs
    [    1.195591] calling  init_cgroup_netprio+0x0/0x38 @ 1
    [    1.196071] initcall init_cgroup_netprio+0x0/0x38 returned 0 after 0 usecs
    [    1.196720] calling  bpf_lwt_init+0x0/0x38 @ 1
    [    1.197141] initcall bpf_lwt_init+0x0/0x38 returned 0 after 0 usecs
    [    1.197737] calling  pktsched_init+0x0/0xc8 @ 1
    [    1.198174] initcall pktsched_init+0x0/0xc8 returned 0 after 0 usecs
    [    1.198774] calling  tc_filter_init+0x0/0xb0 @ 1
    [    1.199223] initcall tc_filter_init+0x0/0xb0 returned 0 after 0 usecs
    [    1.199832] calling  tc_action_init+0x0/0x40 @ 1
    [    1.200270] initcall tc_action_init+0x0/0x40 returned 0 after 0 usecs
    [    1.200878] calling  ethnl_init+0x0/0xa0 @ 1
    [    1.201379] initcall ethnl_init+0x0/0xa0 returned 0 after 4000 usecs
    [    1.201984] calling  nexthop_init+0x0/0x60 @ 1
    [    1.202411] initcall nexthop_init+0x0/0x60 returned 0 after 0 usecs
    [    1.203004] calling  cipso_v4_init+0x0/0x80 @ 1
    [    1.203435] initcall cipso_v4_init+0x0/0x80 returned 0 after 0 usecs
    [    1.204037] calling  devlink_init+0x0/0xb0 @ 1
    [    1.204556] initcall devlink_init+0x0/0xb0 returned 0 after 0 usecs
    [    1.205146] calling  wireless_nlevent_init+0x0/0x78 @ 1
    [    1.205640] initcall wireless_nlevent_init+0x0/0x78 returned 0 after 0 usecs
    [    1.206306] calling  netlbl_init+0x0/0x98 @ 1
    [    1.206717] NetLabel: Initializing
    [    1.207035] NetLabel:  domain hash size = 128
    [    1.207443] NetLabel:  protocols = UNLABELED CIPSOv4 CALIPSO
    [    1.208008] NetLabel:  unlabeled traffic allowed by default
    [    1.208530] initcall netlbl_init+0x0/0x98 returned 0 after 0 usecs
    [    1.209111] calling  rfkill_init+0x0/0x190 @ 1
    [    1.209673] initcall rfkill_init+0x0/0x190 returned 0 after 0 usecs
    [    1.210265] calling  ncsi_init_netlink+0x0/0x38 @ 1
    [    1.210741] initcall ncsi_init_netlink+0x0/0x38 returned 0 after 0 usecs
    [    1.211371] calling  shaper_init+0x0/0x30 @ 1
    [    1.211790] initcall shaper_init+0x0/0x30 returned 0 after 0 usecs
    [    1.212371] calling  vsprintf_init_hashval+0x0/0x30 @ 1
    [    1.212865] initcall vsprintf_init_hashval+0x0/0x30 returned 0 after 0 usecs
    [    1.213527] calling  init_32bit_el0_mask+0x0/0xb8 @ 1
    [    1.214005] initcall init_32bit_el0_mask+0x0/0xb8 returned 0 after 0 usecs
    [    1.214650] calling  vga_arb_device_init+0x0/0xe0 @ 1
    [    1.215246] vgaarb: loaded
    [    1.215503] initcall vga_arb_device_init+0x0/0xe0 returned 0 after 0 usecs
    [    1.216153] calling  watchdog_init+0x0/0xf0 @ 1
    [    1.216736] initcall watchdog_init+0x0/0xf0 returned 0 after 0 usecs
    [    1.217456] calling  create_debug_debugfs_entry+0x0/0x48 @ 1
    [    1.217998] initcall create_debug_debugfs_entry+0x0/0x48 returned 0 after 0 usecs
    [    1.218701] calling  iomem_init_inode+0x0/0xd8 @ 1
    [    1.219189] initcall iomem_init_inode+0x0/0xd8 returned 0 after 0 usecs
    [    1.219815] calling  em_debug_init+0x0/0x48 @ 1
    [    1.220244] initcall em_debug_init+0x0/0x48 returned 0 after 0 usecs
    [    1.220841] calling  clocksource_done_booting+0x0/0x78 @ 1
    [    1.221403] clocksource: Switched to clocksource arch_sys_counter
    [    1.221974] initcall clocksource_done_booting+0x0/0x78 returned 0 after 583 usecs
    [    1.222678] calling  tracer_init_tracefs+0x0/0x130 @ 1
    [    1.223187] initcall tracer_init_tracefs+0x0/0x130 returned 0 after 10 usecs
    [    1.223853] calling  init_trace_printk_function_export+0x0/0x48 @ 1
    [    1.224465] initcall init_trace_printk_function_export+0x0/0x48 returned 0 after 20 usecs
    [    1.225237] calling  init_graph_tracefs+0x0/0x48 @ 1
    [    1.225718] initcall init_graph_tracefs+0x0/0x48 returned 0 after 4 usecs
    [    1.226356] calling  trace_events_synth_init+0x0/0x68 @ 1
    [    1.226875] initcall trace_events_synth_init+0x0/0x68 returned 0 after 10 usecs
    [    1.227561] calling  bpf_event_init+0x0/0x30 @ 1
    [    1.227998] initcall bpf_event_init+0x0/0x30 returned 0 after 1 usecs
    [    1.228602] calling  init_kprobe_trace+0x0/0x220 @ 1
    [    1.229075] initcall init_kprobe_trace+0x0/0x220 returned 0 after 5 usecs
    [    1.229717] calling  init_dynamic_event+0x0/0x48 @ 1
    [    1.230188] initcall init_dynamic_event+0x0/0x48 returned 0 after 2 usecs
    [    1.230825] calling  init_uprobe_trace+0x0/0x98 @ 1
    [    1.231289] initcall init_uprobe_trace+0x0/0x98 returned 0 after 4 usecs
    [    1.231919] calling  bpf_init+0x0/0x98 @ 1
    [    1.232313] initcall bpf_init+0x0/0x98 returned 0 after 7 usecs
    [    1.232869] calling  secretmem_init+0x0/0xb0 @ 1
    [    1.233332] initcall secretmem_init+0x0/0xb0 returned 0 after 26 usecs
    [    1.233954] calling  init_fs_stat_sysctls+0x0/0x58 @ 1
    [    1.234447] initcall init_fs_stat_sysctls+0x0/0x58 returned 0 after 9 usecs
    [    1.235101] calling  init_fs_exec_sysctls+0x0/0x50 @ 1
    [    1.235588] initcall init_fs_exec_sysctls+0x0/0x50 returned 0 after 2 usecs
    [    1.236242] calling  init_pipe_fs+0x0/0x98 @ 1
    [    1.236677] initcall init_pipe_fs+0x0/0x98 returned 0 after 16 usecs
    [    1.237275] calling  init_fs_namei_sysctls+0x0/0x50 @ 1
    [    1.237789] initcall init_fs_namei_sysctls+0x0/0x50 returned 0 after 12 usecs
    [    1.238460] calling  init_fs_dcache_sysctls+0x0/0x78 @ 1
    [    1.238966] initcall init_fs_dcache_sysctls+0x0/0x78 returned 0 after 4 usecs
    [    1.239636] calling  init_fs_namespace_sysctls+0x0/0x50 @ 1
    [    1.240163] initcall init_fs_namespace_sysctls+0x0/0x50 returned 0 after 1 usecs
    [    1.240858] calling  cgroup_writeback_init+0x0/0x50 @ 1
    [    1.241356] initcall cgroup_writeback_init+0x0/0x50 returned 0 after 6 usecs
    [    1.242024] calling  inotify_user_setup+0x0/0x138 @ 1
    [    1.242512] initcall inotify_user_setup+0x0/0x138 returned 0 after 10 usecs
    [    1.243167] calling  eventpoll_init+0x0/0x150 @ 1
    [    1.244793] initcall eventpoll_init+0x0/0x150 returned 0 after 1183 usecs
    [    1.245438] calling  anon_inode_init+0x0/0x98 @ 1
    [    1.245906] initcall anon_inode_init+0x0/0x98 returned 0 after 23 usecs
    [    1.246530] calling  init_dax_wait_table+0x0/0x78 @ 1
    [    1.247053] initcall init_dax_wait_table+0x0/0x78 returned 0 after 46 usecs
    [    1.247708] calling  proc_locks_init+0x0/0x58 @ 1
    [    1.248156] initcall proc_locks_init+0x0/0x58 returned 0 after 2 usecs
    [    1.248771] calling  backing_aio_init+0x0/0x90 @ 1
    [    1.249229] initcall backing_aio_init+0x0/0x90 returned 0 after 5 usecs
    [    1.249858] calling  init_fs_coredump_sysctls+0x0/0x50 @ 1
    [    1.250383] initcall init_fs_coredump_sysctls+0x0/0x50 returned 0 after 6 usecs
    [    1.251071] calling  init_vm_drop_caches_sysctls+0x0/0x50 @ 1
    [    1.251616] initcall init_vm_drop_caches_sysctls+0x0/0x50 returned 0 after 2 usecs
    [    1.252329] calling  iomap_dio_init+0x0/0x48 @ 1
    [    1.252775] initcall iomap_dio_init+0x0/0x48 returned 0 after 9 usecs
    [    1.253382] calling  iomap_ioend_init+0x0/0x40 @ 1
    [    1.254017] initcall iomap_ioend_init+0x0/0x40 returned 0 after 178 usecs
    [    1.254657] calling  dquot_init+0x0/0x190 @ 1
    [    1.255069] VFS: Disk quotas dquot_6.6.0
    [    1.255583] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
    [    1.256229] initcall dquot_init+0x0/0x190 returned 0 after 1159 usecs
    [    1.256836] calling  quota_init+0x0/0x58 @ 1
    [    1.257255] initcall quota_init+0x0/0x58 returned 0 after 14 usecs
    [    1.257846] calling  proc_cmdline_init+0x0/0x70 @ 1
    [    1.258309] initcall proc_cmdline_init+0x0/0x70 returned 0 after 2 usecs
    [    1.258940] calling  proc_consoles_init+0x0/0x50 @ 1
    [    1.259411] initcall proc_consoles_init+0x0/0x50 returned 0 after 1 usecs
    [    1.260051] calling  proc_cpuinfo_init+0x0/0x48 @ 1
    [    1.260513] initcall proc_cpuinfo_init+0x0/0x48 returned 0 after 1 usecs
    [    1.261145] calling  proc_devices_init+0x0/0x60 @ 1
    [    1.261619] initcall proc_devices_init+0x0/0x60 returned 0 after 9 usecs
    [    1.262250] calling  proc_interrupts_init+0x0/0x50 @ 1
    [    1.262735] initcall proc_interrupts_init+0x0/0x50 returned 0 after 1 usecs
    [    1.263390] calling  proc_loadavg_init+0x0/0x60 @ 1
    [    1.263851] initcall proc_loadavg_init+0x0/0x60 returned 0 after 0 usecs
    [    1.264482] calling  proc_meminfo_init+0x0/0x60 @ 1
    [    1.264943] initcall proc_meminfo_init+0x0/0x60 returned 0 after 0 usecs
    [    1.265579] calling  proc_stat_init+0x0/0x48 @ 1
    [    1.266017] initcall proc_stat_init+0x0/0x48 returned 0 after 1 usecs
    [    1.266623] calling  proc_uptime_init+0x0/0x60 @ 1
    [    1.267078] initcall proc_uptime_init+0x0/0x60 returned 0 after 1 usecs
    [    1.267701] calling  proc_version_init+0x0/0x60 @ 1
    [    1.268164] initcall proc_version_init+0x0/0x60 returned 0 after 1 usecs
    [    1.268796] calling  proc_softirqs_init+0x0/0x60 @ 1
    [    1.269265] initcall proc_softirqs_init+0x0/0x60 returned 0 after 1 usecs
    [    1.269909] calling  proc_kcore_init+0x0/0x198 @ 1
    [    1.270432] initcall proc_kcore_init+0x0/0x198 returned 0 after 69 usecs
    [    1.271066] calling  vmcore_init+0x0/0x600 @ 1
    [    1.271488] initcall vmcore_init+0x0/0x600 returned 0 after 0 usecs
    [    1.272079] calling  proc_kmsg_init+0x0/0x48 @ 1
    [    1.272518] initcall proc_kmsg_init+0x0/0x48 returned 0 after 1 usecs
    [    1.273125] calling  proc_page_init+0x0/0x88 @ 1
    [    1.273577] initcall proc_page_init+0x0/0x88 returned 0 after 2 usecs
    [    1.274184] calling  proc_boot_config_init+0x0/0xb8 @ 1
    [    1.274681] initcall proc_boot_config_init+0x0/0xb8 returned 0 after 2 usecs
    [    1.275344] calling  init_ramfs_fs+0x0/0x38 @ 1
    [    1.275776] initcall init_ramfs_fs+0x0/0x38 returned 0 after 2 usecs
    [    1.276375] calling  init_hugetlbfs_fs+0x0/0x278 @ 1
    [    1.277018] initcall init_hugetlbfs_fs+0x0/0x278 returned 0 after 172 usecs
    [    1.277684] calling  tomoyo_interface_init+0x0/0x1a8 @ 1
    [    1.278189] initcall tomoyo_interface_init+0x0/0x1a8 returned 0 after 0 usecs
    [    1.278863] calling  aa_create_aafs+0x0/0x3b0 @ 1
    [    1.279572] AppArmor: AppArmor Filesystem Enabled
    [    1.280015] initcall aa_create_aafs+0x0/0x3b0 returned 0 after 704 usecs
    [    1.280650] calling  safesetid_init_securityfs+0x0/0xd8 @ 1
    [    1.281175] initcall safesetid_init_securityfs+0x0/0xd8 returned 0 after 0 usecs
    [    1.281881] calling  dynamic_debug_init_control+0x0/0xb8 @ 1
    [    1.282425] initcall dynamic_debug_init_control+0x0/0xb8 returned 0 after 9 usecs
    [    1.283129] calling  chr_dev_init+0x0/0x120 @ 1
    [    1.291812] initcall chr_dev_init+0x0/0x120 returned 0 after 8255 usecs
    [    1.292440] calling  hwrng_modinit+0x0/0xc8 @ 1
    [    1.292979] initcall hwrng_modinit+0x0/0xc8 returned 0 after 110 usecs
    [    1.293606] calling  firmware_class_init+0x0/0x128 @ 1
    [    1.294109] initcall firmware_class_init+0x0/0x128 returned 0 after 16 usecs
    [    1.294773] calling  powercap_init+0x0/0x3e0 @ 1
    [    1.295271] initcall powercap_init+0x0/0x3e0 returned 0 after 61 usecs
    [    1.295886] calling  sysctl_core_init+0x0/0x60 @ 1
    [    1.296380] initcall sysctl_core_init+0x0/0x60 returned 0 after 40 usecs
    [    1.297013] calling  eth_offload_init+0x0/0x38 @ 1
    [    1.297473] initcall eth_offload_init+0x0/0x38 returned 0 after 0 usecs
    [    1.298098] calling  ipv4_offload_init+0x0/0xe8 @ 1
    [    1.298562] initcall ipv4_offload_init+0x0/0xe8 returned 0 after 1 usecs
    [    1.299195] calling  inet_init+0x0/0x340 @ 1
    [    1.300172] NET: Registered PF_INET protocol family
    [    1.300935] IP idents hash table entries: 262144 (order: 9, 2097152 bytes, linear)
    [    1.311109] tcp_listen_portaddr_hash hash table entries: 16384 (order: 6, 262144 bytes, linear)
    [    1.312196] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
    [    1.313185] TCP established hash table entries: 262144 (order: 9, 2097152 bytes, linear)
    [    1.316108] TCP bind hash table entries: 65536 (order: 9, 2097152 bytes, linear)
    [    1.318689] TCP: Hash tables configured (established 262144 bind 65536)
    [    1.319716] MPTCP token hash table entries: 32768 (order: 7, 786432 bytes, linear)
    [    1.320834] UDP hash table entries: 16384 (order: 8, 1048576 bytes, linear)
    [    1.322792] UDP-Lite hash table entries: 16384 (order: 8, 1048576 bytes, linear)
    [    1.324823] initcall inet_init+0x0/0x340 returned 0 after 25222 usecs
    [    1.325445] calling  af_unix_init+0x0/0x1e0 @ 1
    [    1.325881] NET: Registered PF_UNIX/PF_LOCAL protocol family
    [    1.326427] initcall af_unix_init+0x0/0x1e0 returned 0 after 554 usecs
    [    1.327041] calling  ipv6_offload_init+0x0/0xe0 @ 1
    [    1.327503] initcall ipv6_offload_init+0x0/0xe0 returned 0 after 2 usecs
    [    1.328131] calling  vlan_offload_init+0x0/0x50 @ 1
    [    1.328592] initcall vlan_offload_init+0x0/0x50 returned 0 after 0 usecs
    [    1.329222] calling  xsk_init+0x0/0xc8 @ 1
    [    1.329615] NET: Registered PF_XDP protocol family
    [    1.330067] initcall xsk_init+0x0/0xc8 returned 0 after 452 usecs
    [    1.330640] calling  pci_apply_final_quirks+0x0/0x188 @ 1
    [    1.331155] PCI: CLS 0 bytes, default 64
    [    1.331524] initcall pci_apply_final_quirks+0x0/0x188 returned 0 after 371 usecs
    [    1.332222] calling  populate_rootfs+0x0/0xa8 @ 1
    [    1.332676] initcall populate_rootfs+0x0/0xa8 returned 0 after 6 usecs
    [    1.332822] Trying to unpack rootfs image as initramfs...
    [    1.333425] calling  register_arm64_panic_block+0x0/0x40 @ 1
    [    1.334326] initcall register_arm64_panic_block+0x0/0x40 returned 0 after 1 usecs
    [    1.335029] calling  cpuinfo_regs_init+0x0/0x128 @ 1
    [    1.336068] initcall cpuinfo_regs_init+0x0/0x128 returned 0 after 571 usecs
    [    1.336724] calling  aarch32_el0_sysfs_init+0x0/0xa8 @ 1
    [    1.337225] initcall aarch32_el0_sysfs_init+0x0/0xa8 returned 0 after 0 usecs
    [    1.337902] calling  arch_init_uprobes+0x0/0x48 @ 1
    [    1.338366] initcall arch_init_uprobes+0x0/0x48 returned 0 after 1 usecs
    [    1.338998] calling  ptdump_init+0x0/0x310 @ 1
    [    1.339421] initcall ptdump_init+0x0/0x310 returned 0 after 1 usecs
    [    1.340013] calling  chacha_simd_mod_init+0x0/0x60 @ 1
    [    1.340528] initcall chacha_simd_mod_init+0x0/0x60 returned 0 after 28 usecs
    [    1.341193] calling  neon_poly1305_mod_init+0x0/0x60 @ 1
    [    1.341715] initcall neon_poly1305_mod_init+0x0/0x60 returned 0 after 15 usecs
    [    1.342396] calling  proc_execdomains_init+0x0/0x50 @ 1
    [    1.342895] initcall proc_execdomains_init+0x0/0x50 returned 0 after 4 usecs
    [    1.343560] calling  register_warn_debugfs+0x0/0x50 @ 1
    [    1.344062] initcall register_warn_debugfs+0x0/0x50 returned 0 after 8 usecs
    [    1.344728] calling  cpuhp_sysfs_init+0x0/0x138 @ 1
    [    1.345255] initcall cpuhp_sysfs_init+0x0/0x138 returned 0 after 63 usecs
    [    1.345901] calling  ioresources_init+0x0/0x88 @ 1
    [    1.346360] initcall ioresources_init+0x0/0x88 returned 0 after 4 usecs
    [    1.346984] calling  psi_proc_init+0x0/0xd0 @ 1
    [    1.347424] initcall psi_proc_init+0x0/0xd0 returned 0 after 13 usecs
    [    1.348029] calling  snapshot_device_init+0x0/0x38 @ 1
    [    1.348639] initcall snapshot_device_init+0x0/0x38 returned 0 after 125 usecs
    [    1.349312] calling  irq_gc_init_ops+0x0/0x40 @ 1
    [    1.349766] initcall irq_gc_init_ops+0x0/0x40 returned 0 after 1 usecs
    [    1.350381] calling  irq_pm_init_ops+0x0/0x38 @ 1
    [    1.350825] initcall irq_pm_init_ops+0x0/0x38 returned 0 after 0 usecs
    [    1.351439] calling  proc_modules_init+0x0/0x48 @ 1
    [    1.351901] initcall proc_modules_init+0x0/0x48 returned 0 after 2 usecs
    [    1.352532] calling  timer_sysctl_init+0x0/0x48 @ 1
    [    1.352997] initcall timer_sysctl_init+0x0/0x48 returned 0 after 4 usecs
    [    1.353632] calling  timekeeping_init_ops+0x0/0x40 @ 1
    [    1.354118] initcall timekeeping_init_ops+0x0/0x40 returned 0 after 0 usecs
    [    1.354773] calling  init_clocksource_sysfs+0x0/0x58 @ 1
    [    1.355359] initcall init_clocksource_sysfs+0x0/0x58 returned 0 after 83 usecs
    [    1.356041] calling  init_timer_list_procfs+0x0/0x58 @ 1
    [    1.356544] initcall init_timer_list_procfs+0x0/0x58 returned 0 after 2 usecs
    [    1.357215] calling  alarmtimer_init+0x0/0xe0 @ 1
    [    1.357755] initcall alarmtimer_init+0x0/0xe0 returned 0 after 90 usecs
    [    1.358379] calling  init_posix_timers+0x0/0x88 @ 1
    [    1.358844] initcall init_posix_timers+0x0/0x88 returned 0 after 4 usecs
    [    1.359474] calling  clockevents_init_sysfs+0x0/0x170 @ 1
    [    1.360256] initcall clockevents_init_sysfs+0x0/0x170 returned 0 after 270 usecs
    [    1.360953] calling  sched_clock_syscore_init+0x0/0x40 @ 1
    [    1.361476] initcall sched_clock_syscore_init+0x0/0x40 returned 0 after 0 usecs
    [    1.362164] calling  kallsyms_init+0x0/0x48 @ 1
    [    1.362595] initcall kallsyms_init+0x0/0x48 returned 0 after 2 usecs
    [    1.363194] calling  pid_namespaces_init+0x0/0xc8 @ 1
    [    1.363808] initcall pid_namespaces_init+0x0/0xc8 returned 0 after 135 usecs
    [    1.364474] calling  ikheaders_init+0x0/0x58 @ 1
    [    1.364915] initcall ikheaders_init+0x0/0x58 returned 0 after 4 usecs
    [    1.365527] calling  audit_watch_init+0x0/0x70 @ 1
    [    1.365983] initcall audit_watch_init+0x0/0x70 returned 0 after 0 usecs
    [    1.366607] calling  audit_fsnotify_init+0x0/0x70 @ 1
    [    1.367085] initcall audit_fsnotify_init+0x0/0x70 returned 0 after 0 usecs
    [    1.367733] calling  audit_tree_init+0x0/0x110 @ 1
    [    1.368189] initcall audit_tree_init+0x0/0x110 returned 0 after 3 usecs
    [    1.368813] calling  seccomp_sysctl_init+0x0/0x50 @ 1
    [    1.369297] initcall seccomp_sysctl_init+0x0/0x50 returned 0 after 4 usecs
    [    1.369949] calling  utsname_sysctl_init+0x0/0x48 @ 1
    [    1.370437] initcall utsname_sysctl_init+0x0/0x48 returned 0 after 9 usecs
    [    1.371085] calling  init_tracepoints+0x0/0x68 @ 1
    [    1.371542] initcall init_tracepoints+0x0/0x68 returned 0 after 2 usecs
    [    1.372166] calling  stack_trace_init+0x0/0x100 @ 1
    [    1.372640] initcall stack_trace_init+0x0/0x100 returned 0 after 15 usecs
    [    1.373279] calling  init_blk_tracer+0x0/0x98 @ 1
    [    1.373742] initcall init_blk_tracer+0x0/0x98 returned 0 after 16 usecs
    [    1.374363] calling  perf_event_sysfs_init+0x0/0xd8 @ 1
    [    1.375029] initcall perf_event_sysfs_init+0x0/0xd8 returned 0 after 171 usecs
    [    1.375710] calling  system_trusted_keyring_init+0x0/0x120 @ 1
    [    1.376260] Initialise system trusted keyrings
    [    1.376695] initcall system_trusted_keyring_init+0x0/0x120 returned 0 after 435 usecs
    [    1.377437] calling  blacklist_init+0x0/0x108 @ 1
    [    1.377883] Key type blacklist registered
    [    1.378274] initcall blacklist_init+0x0/0x108 returned 0 after 392 usecs
    [    1.378906] calling  kswapd_init+0x0/0xb8 @ 1
    [    1.379502] initcall kswapd_init+0x0/0xb8 returned 0 after 185 usecs
    [    1.380102] calling  extfrag_debug_init+0x0/0x90 @ 1
    [    1.380582] initcall extfrag_debug_init+0x0/0x90 returned 0 after 10 usecs
    [    1.381229] calling  mm_compute_batch_init+0x0/0x48 @ 1
    [    1.381733] initcall mm_compute_batch_init+0x0/0x48 returned 0 after 1 usecs
    [    1.382398] calling  slab_proc_init+0x0/0x50 @ 1
    [    1.382838] initcall slab_proc_init+0x0/0x50 returned 0 after 2 usecs
    [    1.383445] calling  workingset_init+0x0/0x110 @ 1
    [    1.383900] workingset: timestamp_bits=36 max_order=23 bucket_order=0
    [    1.384507] initcall workingset_init+0x0/0x110 returned 0 after 607 usecs
    [    1.385146] calling  proc_vmalloc_init+0x0/0x50 @ 1
    [    1.385614] initcall proc_vmalloc_init+0x0/0x50 returned 0 after 1 usecs
    [    1.386246] calling  memblock_init_debugfs+0x0/0xa0 @ 1
    [    1.386756] initcall memblock_init_debugfs+0x0/0xa0 returned 0 after 16 usecs
    [    1.387431] calling  slab_debugfs_init+0x0/0x98 @ 1
    [    1.387912] initcall slab_debugfs_init+0x0/0x98 returned 0 after 19 usecs
    [    1.388554] calling  procswaps_init+0x0/0x50 @ 1
    [    1.388994] initcall procswaps_init+0x0/0x50 returned 0 after 2 usecs
    [    1.389606] calling  zs_init+0x0/0x40 @ 1
    [    1.389985] initcall zs_init+0x0/0x40 returned 0 after 1 usecs
    [    1.390533] calling  ptdump_debugfs_init+0x0/0x50 @ 1
    [    1.391017] initcall ptdump_debugfs_init+0x0/0x50 returned 0 after 3 usecs
    [    1.391667] calling  fcntl_init+0x0/0x80 @ 1
    [    1.392075] initcall fcntl_init+0x0/0x80 returned 0 after 4 usecs
    [    1.392648] calling  proc_filesystems_init+0x0/0x50 @ 1
    [    1.393142] initcall proc_filesystems_init+0x0/0x50 returned 0 after 1 usecs
    [    1.393808] calling  start_dirtytime_writeback+0x0/0x78 @ 1
    [    1.394339] initcall start_dirtytime_writeback+0x0/0x78 returned 0 after 5 usecs
    [    1.395035] calling  dio_init+0x0/0x88 @ 1
    [    1.395424] initcall dio_init+0x0/0x88 returned 0 after 1 usecs
    [    1.395979] calling  dnotify_init+0x0/0x108 @ 1
    [    1.396344] Freeing initrd memory: 1792K
    [    1.396934] initcall dnotify_init+0x0/0x108 returned 0 after 530 usecs
    [    1.397553] calling  fanotify_user_setup+0x0/0x1f0 @ 1
    [    1.398212] initcall fanotify_user_setup+0x0/0x1f0 returned 0 after 174 usecs
    [    1.398885] calling  userfaultfd_init+0x0/0xc8 @ 1
    [    1.399567] initcall userfaultfd_init+0x0/0xc8 returned 0 after 228 usecs
    [    1.400208] calling  aio_setup+0x0/0x110 @ 1
    [    1.400762] initcall aio_setup+0x0/0x110 returned 0 after 150 usecs
    [    1.401354] calling  mbcache_init+0x0/0x90 @ 1
    [    1.402089] initcall mbcache_init+0x0/0x90 returned 0 after 303 usecs
    [    1.402697] calling  init_devpts_fs+0x0/0x78 @ 1
    [    1.403147] initcall init_devpts_fs+0x0/0x78 returned 0 after 11 usecs
    [    1.403761] calling  ext4_init_fs+0x0/0x1e0 @ 1
    [    1.406879] initcall ext4_init_fs+0x0/0x1e0 returned 0 after 2688 usecs
    [    1.407506] calling  journal_init+0x0/0x190 @ 1
    [    1.409211] initcall journal_init+0x0/0x190 returned 0 after 1276 usecs
    [    1.409845] calling  init_squashfs_fs+0x0/0xd8 @ 1
    [    1.410398] squashfs: version 4.0 (2009/01/31) Phillip Lougher
    [    1.410944] initcall init_squashfs_fs+0x0/0xd8 returned 0 after 644 usecs
    [    1.411584] calling  ecryptfs_init+0x0/0x2e0 @ 1
    [    1.413546] initcall ecryptfs_init+0x0/0x2e0 returned 0 after 1526 usecs
    [    1.414182] calling  init_nls_cp437+0x0/0x40 @ 1
    [    1.414620] initcall init_nls_cp437+0x0/0x40 returned 0 after 0 usecs
    [    1.415228] calling  fuse_init+0x0/0x258 @ 1
    [    1.415634] fuse: init (API version 7.43)
    [    1.416396] initcall fuse_init+0x0/0x258 returned 0 after 761 usecs
    [    1.416990] calling  ovl_init+0x0/0xc0 @ 1
    [    1.417490] initcall ovl_init+0x0/0xc0 returned 0 after 110 usecs
    [    1.418066] calling  bcachefs_init+0x0/0x98 @ 1
    [    1.418868] initcall bcachefs_init+0x0/0x98 returned 0 after 371 usecs
    [    1.419487] calling  ipc_init+0x0/0x48 @ 1
    [    1.419898] initcall ipc_init+0x0/0x48 returned 0 after 22 usecs
    [    1.420466] calling  ipc_sysctl_init+0x0/0x58 @ 1
    [    1.420934] initcall ipc_sysctl_init+0x0/0x58 returned 0 after 21 usecs
    [    1.421567] calling  init_mqueue_fs+0x0/0x120 @ 1
    [    1.422197] initcall init_mqueue_fs+0x0/0x120 returned 0 after 183 usecs
    [    1.422832] calling  key_proc_init+0x0/0xa0 @ 1
    [    1.423266] initcall key_proc_init+0x0/0xa0 returned 0 after 3 usecs
    [    1.423866] calling  selinux_nf_ip_init+0x0/0x88 @ 1
    [    1.424337] initcall selinux_nf_ip_init+0x0/0x88 returned 0 after 0 usecs
    [    1.424978] calling  init_sel_fs+0x0/0x158 @ 1
    [    1.425405] initcall init_sel_fs+0x0/0x158 returned 0 after 0 usecs
    [    1.425997] calling  selnl_init+0x0/0x98 @ 1
    [    1.426413] initcall selnl_init+0x0/0x98 returned 0 after 10 usecs
    [    1.426998] calling  sel_netif_init+0x0/0xa8 @ 1
    [    1.427436] initcall sel_netif_init+0x0/0xa8 returned 0 after 0 usecs
    [    1.428045] calling  sel_netnode_init+0x0/0xc8 @ 1
    [    1.428501] initcall sel_netnode_init+0x0/0xc8 returned 0 after 0 usecs
    [    1.429125] calling  sel_netport_init+0x0/0xc8 @ 1
    [    1.429584] initcall sel_netport_init+0x0/0xc8 returned 0 after 0 usecs
    [    1.430209] calling  aurule_init+0x0/0x50 @ 1
    [    1.430624] initcall aurule_init+0x0/0x50 returned 0 after 0 usecs
    [    1.431208] calling  init_smk_fs+0x0/0x210 @ 1
    [    1.431631] initcall init_smk_fs+0x0/0x210 returned 0 after 0 usecs
    [    1.432225] calling  smack_nf_ip_init+0x0/0x50 @ 1
    [    1.432680] initcall smack_nf_ip_init+0x0/0x50 returned 0 after 0 usecs
    [    1.433305] calling  apparmor_nf_ip_init+0x0/0x68 @ 1
    [    1.433825] initcall apparmor_nf_ip_init+0x0/0x68 returned 0 after 35 usecs
    [    1.434484] calling  platform_keyring_init+0x0/0x50 @ 1
    [    1.434984] integrity: Platform Keyring initialized
    [    1.435441] initcall platform_keyring_init+0x0/0x50 returned 0 after 465 usecs
    [    1.436121] calling  bpf_crypto_skcipher_init+0x0/0x38 @ 1
    [    1.436640] initcall bpf_crypto_skcipher_init+0x0/0x38 returned 0 after 1 usecs
    [    1.437327] calling  crypto_hkdf_module_init+0x0/0x18 @ 1
    [    1.437839] initcall crypto_hkdf_module_init+0x0/0x18 returned 0 after 0 usecs
    [    1.438518] calling  jent_mod_init+0x0/0x118 @ 1
    [    1.478276] initcall jent_mod_init+0x0/0x118 returned 0 after 39321 usecs
    [    1.478916] calling  calibrate_xor_blocks+0x0/0x110 @ 1
    [    1.479414] xor: measuring software checksum speed
    [    1.480471]    8regs           :  5400 MB/sec
    [    1.481510]    32regs          :  5215 MB/sec
    [    1.482349]    arm64_neon      :  7626 MB/sec
    [    1.482758] xor: using function: arm64_neon (7626 MB/sec)
    [    1.483266] initcall calibrate_xor_blocks+0x0/0x110 returned 0 after 3856 usecs
    [    1.483954] calling  asymmetric_key_init+0x0/0x38 @ 1
    [    1.484432] Key type asymmetric registered
    [    1.484816] initcall asymmetric_key_init+0x0/0x38 returned 0 after 385 usecs
    [    1.485483] calling  x509_key_init+0x0/0x38 @ 1
    [    1.485912] Asymmetric key parser 'x509' registered
    [    1.486368] initcall x509_key_init+0x0/0x38 returned 0 after 456 usecs
    [    1.486982] calling  crypto_kdf108_init+0x0/0x18 @ 1
    [    1.487450] initcall crypto_kdf108_init+0x0/0x18 returned 0 after 0 usecs
    [    1.488089] calling  blkdev_init+0x0/0x40 @ 1
    [    1.488628] initcall blkdev_init+0x0/0x40 returned 0 after 126 usecs
    [    1.489227] calling  proc_genhd_init+0x0/0x80 @ 1
    [    1.489681] initcall proc_genhd_init+0x0/0x80 returned 0 after 3 usecs
    [    1.490296] calling  bsg_init+0x0/0xc8 @ 1
    [    1.490693] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 240)
    [    1.491385] initcall bsg_init+0x0/0xc8 returned 0 after 701 usecs
    [    1.491959] calling  throtl_init+0x0/0x68 @ 1
    [    1.492547] initcall throtl_init+0x0/0x68 returned 0 after 175 usecs
    [    1.493147] calling  ioprio_init+0x0/0x38 @ 1
    [    1.493574] initcall ioprio_init+0x0/0x38 returned 0 after 7 usecs
    [    1.494156] calling  ioc_init+0x0/0x38 @ 1
    [    1.494551] initcall ioc_init+0x0/0x38 returned 0 after 7 usecs
    [    1.495109] calling  deadline_init+0x0/0x38 @ 1
    [    1.495538] io scheduler mq-deadline registered
    [    1.495961] initcall deadline_init+0x0/0x38 returned 0 after 423 usecs
    [    1.496576] calling  io_uring_init+0x0/0xe0 @ 1
    [    1.497167] initcall io_uring_init+0x0/0xe0 returned 0 after 162 usecs
    [    1.497789] calling  xor_neon_init+0x0/0x68 @ 1
    [    1.498219] initcall xor_neon_init+0x0/0x68 returned 0 after 0 usecs
    [    1.498817] calling  blake2s_mod_init+0x0/0x10 @ 1
    [    1.499270] initcall blake2s_mod_init+0x0/0x10 returned 0 after 0 usecs
    [    1.499893] calling  btree_module_init+0x0/0x78 @ 1
    [    1.500360] initcall btree_module_init+0x0/0x78 returned 0 after 6 usecs
    [    1.500991] calling  percpu_counter_startup+0x0/0x88 @ 1
    [    1.501702] initcall percpu_counter_startup+0x0/0x88 returned 0 after 205 usecs
    [    1.502392] calling  audit_classes_init+0x0/0x68 @ 1
    [    1.502863] initcall audit_classes_init+0x0/0x68 returned 0 after 2 usecs
    [    1.503502] calling  digsig_init+0x0/0x70 @ 1
    [    1.503919] initcall digsig_init+0x0/0x70 returned 0 after 4 usecs
    [    1.504502] calling  simple_pm_bus_driver_init+0x0/0x38 @ 1
    [    1.505097] probe of fd58a000.syscon returned 19 after 30 usecs
    [    1.505699] probe of fd5d0000.syscon returned 19 after 15 usecs
    [    1.506273] probe of fd5d8000.syscon returned 19 after 13 usecs
    [    1.506843] probe of fd5dc000.syscon returned 19 after 11 usecs
    [    1.507431] probe of fd8d8000.power-management returned 19 after 12 usecs
    [    1.508216] probe of fd5d4000.syscon returned 19 after 13 usecs
    [    1.508818] initcall simple_pm_bus_driver_init+0x0/0x38 returned 0 after 3789 usecs
    [    1.509549] calling  phy_core_init+0x0/0x80 @ 1
    [    1.510004] initcall phy_core_init+0x0/0x80 returned 0 after 24 usecs
    [    1.510613] calling  ledtrig_disk_init+0x0/0x70 @ 1
    [    1.511083] initcall ledtrig_disk_init+0x0/0x70 returned 0 after 6 usecs
    [    1.511715] calling  ledtrig_mtd_init+0x0/0x60 @ 1
    [    1.512170] initcall ledtrig_mtd_init+0x0/0x60 returned 0 after 1 usecs
    [    1.512794] calling  ledtrig_cpu_init+0x0/0x178 @ 1
    [    1.513444] ledtrig-cpu: registered to indicate activity on CPUs
    [    1.514008] initcall ledtrig_cpu_init+0x0/0x178 returned 0 after 753 usecs
    [    1.514658] calling  ledtrig_panic_init+0x0/0x80 @ 1
    [    1.515130] initcall ledtrig_panic_init+0x0/0x80 returned 0 after 2 usecs
    [    1.515770] calling  pcie_portdrv_init+0x0/0x90 @ 1
    [    1.516303] initcall pcie_portdrv_init+0x0/0x90 returned 0 after 72 usecs
    [    1.516946] calling  pci_proc_init+0x0/0xa8 @ 1
    [    1.517387] initcall pci_proc_init+0x0/0xa8 returned 0 after 11 usecs
    [    1.518009] calling  pci_hotplug_init+0x0/0x98 @ 1
    [    1.518464] initcall pci_hotplug_init+0x0/0x98 returned 0 after 0 usecs
    [    1.519088] calling  shpcd_init+0x0/0x40 @ 1
    [    1.519519] initcall shpcd_init+0x0/0x40 returned 0 after 25 usecs
    [    1.520105] calling  pci_ep_cfs_init+0x0/0x140 @ 1
    [    1.520611] initcall pci_ep_cfs_init+0x0/0x140 returned 0 after 51 usecs
    [    1.521245] calling  pci_epc_init+0x0/0x38 @ 1
    [    1.521685] initcall pci_epc_init+0x0/0x38 returned 0 after 6 usecs
    [    1.522277] calling  pci_epf_init+0x0/0x70 @ 1
    [    1.522713] initcall pci_epf_init+0x0/0x70 returned 0 after 14 usecs
    [    1.523314] calling  dw_plat_pcie_driver_init+0x0/0x38 @ 1
    [    1.523932] initcall dw_plat_pcie_driver_init+0x0/0x38 returned 0 after 99 usecs
    [    1.524632] calling  imsttfb_init+0x0/0x1b0 @ 1
    [    1.525084] initcall imsttfb_init+0x0/0x1b0 returned 0 after 21 usecs
    [    1.525703] calling  asiliantfb_init+0x0/0x78 @ 1
    [    1.526177] initcall asiliantfb_init+0x0/0x78 returned 0 after 27 usecs
    [    1.526803] calling  of_fixed_factor_clk_driver_init+0x0/0x38 @ 1
    [    1.527446] initcall of_fixed_factor_clk_driver_init+0x0/0x38 returned 0 after 66 usecs
    [    1.528202] calling  of_fixed_clk_driver_init+0x0/0x38 @ 1
    [    1.528790] initcall of_fixed_clk_driver_init+0x0/0x38 returned 0 after 68 usecs
    [    1.529500] calling  gpio_clk_driver_init+0x0/0x38 @ 1
    [    1.530069] initcall gpio_clk_driver_init+0x0/0x38 returned 0 after 81 usecs
    [    1.530735] calling  gated_fixed_clk_driver_init+0x0/0x40 @ 1
    [    1.531340] initcall gated_fixed_clk_driver_init+0x0/0x40 returned 0 after 61 usecs
    [    1.532064] calling  clk_rk3399_driver_init+0x0/0x40 @ 1
    [    1.532711] initcall clk_rk3399_driver_init+0x0/0x40 returned -19 after 148 usecs
    [    1.533421] calling  clk_rk3528_driver_init+0x0/0x40 @ 1
    [    1.534016] initcall clk_rk3528_driver_init+0x0/0x40 returned -19 after 95 usecs
    [    1.534712] calling  clk_rk3562_driver_init+0x0/0x40 @ 1
    [    1.535304] initcall clk_rk3562_driver_init+0x0/0x40 returned -19 after 92 usecs
    [    1.535998] calling  clk_rk3568_driver_init+0x0/0x40 @ 1
    [    1.536621] initcall clk_rk3568_driver_init+0x0/0x40 returned -19 after 123 usecs
    [    1.537324] calling  clk_rk3576_driver_init+0x0/0x40 @ 1
    [    1.537929] initcall clk_rk3576_driver_init+0x0/0x40 returned -19 after 95 usecs
    [    1.538625] calling  virtio_mmio_init+0x0/0x40 @ 1
    [    1.539146] initcall virtio_mmio_init+0x0/0x40 returned 0 after 69 usecs
    [    1.539777] calling  virtio_pci_driver_init+0x0/0x40 @ 1
    [    1.540296] initcall virtio_pci_driver_init+0x0/0x40 returned 0 after 18 usecs
    [    1.540974] calling  virtio_balloon_driver_init+0x0/0x38 @ 1
    [    1.541523] initcall virtio_balloon_driver_init+0x0/0x38 returned 0 after 9 usecs
    [    1.542226] calling  rk808_regulator_driver_init+0x0/0x38 @ 1
    [    1.542795] initcall rk808_regulator_driver_init+0x0/0x38 returned 0 after 28 usecs
    [    1.543514] calling  n_null_init+0x0/0x40 @ 1
    [    1.543926] initcall n_null_init+0x0/0x40 returned 0 after 0 usecs
    [    1.544507] calling  pty_init+0x0/0x368 @ 1
    [    1.545027] initcall pty_init+0x0/0x368 returned 0 after 124 usecs
    [    1.545625] calling  sysrq_init+0x0/0x248 @ 1
    [    1.546094] initcall sysrq_init+0x0/0x248 returned 0 after 58 usecs
    [    1.546683] calling  serial8250_init+0x0/0x130 @ 1
    [    1.547135] Serial: 8250/16550 driver, 32 ports, IRQ sharing enabled
    [    1.547852] probe of serial8250:0 returned 0 after 10 usecs
    [    1.548411] probe of serial8250:0.0 returned 0 after 8 usecs
    [    1.549209] probe of serial8250:0.1 returned 0 after 7 usecs
    [    1.549972] probe of serial8250:0.2 returned 0 after 14 usecs
    [    1.550719] probe of serial8250:0.3 returned 0 after 7 usecs
    [    1.551456] probe of serial8250:0.4 returned 0 after 7 usecs
    [    1.552222] probe of serial8250:0.5 returned 0 after 7 usecs
    [    1.552959] probe of serial8250:0.6 returned 0 after 6 usecs
    [    1.553735] probe of serial8250:0.7 returned 0 after 7 usecs
    [    1.554473] probe of serial8250:0.8 returned 0 after 6 usecs
    [    1.555210] probe of serial8250:0.9 returned 0 after 6 usecs
    [    1.555945] probe of serial8250:0.10 returned 0 after 7 usecs
    [    1.556710] probe of serial8250:0.11 returned 0 after 6 usecs
    [    1.557531] probe of serial8250:0.12 returned 0 after 7 usecs
    [    1.558281] probe of serial8250:0.13 returned 0 after 6 usecs
    [    1.559025] probe of serial8250:0.14 returned 0 after 6 usecs
    [    1.559777] probe of serial8250:0.15 returned 0 after 14 usecs
    [    1.560537] probe of serial8250:0.16 returned 0 after 6 usecs
    [    1.561279] probe of serial8250:0.17 returned 0 after 6 usecs
    [    1.562044] probe of serial8250:0.18 returned 0 after 6 usecs
    [    1.562806] probe of serial8250:0.19 returned 0 after 7 usecs
    [    1.563575] probe of serial8250:0.20 returned 0 after 6 usecs
    [    1.564320] probe of serial8250:0.21 returned 0 after 6 usecs
    [    1.565063] probe of serial8250:0.22 returned 0 after 6 usecs
    [    1.565833] probe of serial8250:0.23 returned 0 after 7 usecs
    [    1.566583] probe of serial8250:0.24 returned 0 after 7 usecs
    [    1.567334] probe of serial8250:0.25 returned 0 after 14 usecs
    [    1.568113] probe of serial8250:0.26 returned 0 after 6 usecs
    [    1.568858] probe of serial8250:0.27 returned 0 after 6 usecs
    [    1.569632] probe of serial8250:0.28 returned 0 after 7 usecs
    [    1.570376] probe of serial8250:0.29 returned 0 after 6 usecs
    [    1.571129] probe of serial8250:0.30 returned 0 after 7 usecs
    [    1.571872] probe of serial8250:0.31 returned 0 after 6 usecs
    [    1.572644] probe of serial8250 returned 0 after 14 usecs
    [    1.573159] initcall serial8250_init+0x0/0x130 returned 0 after 26023 usecs
    [    1.573827] calling  serial_pci_driver_init+0x0/0x48 @ 1
    [    1.574348] initcall serial_pci_driver_init+0x0/0x48 returned 0 after 21 usecs
    [    1.575027] calling  pericom8250_pci_driver_init+0x0/0x40 @ 1
    [    1.575594] initcall pericom8250_pci_driver_init+0x0/0x40 returned 0 after 25 usecs
    [    1.576314] calling  max310x_uart_init+0x0/0xa0 @ 1
    [    1.576818] initcall max310x_uart_init+0x0/0xa0 returned 0 after 43 usecs
    [    1.577470] calling  sccnxp_uart_driver_init+0x0/0x38 @ 1
    [    1.578028] initcall sccnxp_uart_driver_init+0x0/0x38 returned 0 after 48 usecs
    [    1.578716] calling  init_kgdboc+0x0/0xc8 @ 1
    [    1.579208] probe of kgdboc returned 0 after 11 usecs
    [    1.579683] initcall init_kgdboc+0x0/0xc8 returned 0 after 555 usecs
    [    1.580282] calling  random_sysctls_init+0x0/0x50 @ 1
    [    1.580767] initcall random_sysctls_init+0x0/0x50 returned 0 after 8 usecs
    [    1.581437] calling  ttyprintk_init+0x0/0x140 @ 1
    [    1.582043] initcall ttyprintk_init+0x0/0x140 returned 0 after 160 usecs
    [    1.582676] calling  virtio_console_init+0x0/0x138 @ 1
    [    1.583207] initcall virtio_console_init+0x0/0x138 returned 0 after 46 usecs
    [    1.583872] calling  smccc_trng_driver_init+0x0/0x38 @ 1
    [    1.584407] initcall smccc_trng_driver_init+0x0/0x38 returned 0 after 34 usecs
    [    1.585087] calling  rk_rng_driver_init+0x0/0x38 @ 1
    [    1.585665] probe of fe378000.rng returned -517 after 10 usecs
    [    1.586255] initcall rk_rng_driver_init+0x0/0x38 returned 0 after 685 usecs
    [    1.586912] calling  init_tis+0x0/0x60 @ 1
    [    1.587381] initcall init_tis+0x0/0x60 returned 0 after 81 usecs
    [    1.587947] calling  virtio_iommu_drv_init+0x0/0x38 @ 1
    [    1.588449] initcall virtio_iommu_drv_init+0x0/0x38 returned 0 after 8 usecs
    [    1.589113] calling  cn_proc_init+0x0/0x78 @ 1
    [    1.589540] initcall cn_proc_init+0x0/0x78 returned 0 after 1 usecs
    [    1.590131] calling  topology_sysfs_init+0x0/0x50 @ 1
    [    1.590751] initcall topology_sysfs_init+0x0/0x50 returned 0 after 143 usecs
    [    1.591416] calling  cacheinfo_sysfs_init+0x0/0x50 @ 1
    [    1.593477] initcall cacheinfo_sysfs_init+0x0/0x50 returned 0 after 1575 usecs
    [    1.594161] calling  devcoredump_init+0x0/0x38 @ 1
    [    1.594624] initcall devcoredump_init+0x0/0x38 returned 0 after 9 usecs
    [    1.595248] calling  loop_init+0x0/0x148 @ 1
    [    1.599981] loop: module loaded
    [    1.600280] initcall loop_init+0x0/0x148 returned 0 after 4627 usecs
    [    1.600884] calling  tps65912_i2c_driver_init+0x0/0x38 @ 1
    [    1.601445] initcall tps65912_i2c_driver_init+0x0/0x38 returned 0 after 27 usecs
    [    1.602144] calling  tps65912_spi_driver_init+0x0/0x38 @ 1
    [    1.602674] initcall tps65912_spi_driver_init+0x0/0x38 returned 0 after 11 usecs
    [    1.603371] calling  twl_driver_init+0x0/0x38 @ 1
    [    1.603825] initcall twl_driver_init+0x0/0x38 returned 0 after 8 usecs
    [    1.604440] calling  twl4030_audio_driver_init+0x0/0x40 @ 1
    [    1.605062] initcall twl4030_audio_driver_init+0x0/0x40 returned 0 after 94 usecs
    [    1.605774] calling  twl6040_driver_init+0x0/0x38 @ 1
    [    1.606262] initcall twl6040_driver_init+0x0/0x38 returned 0 after 10 usecs
    [    1.606919] calling  da9063_i2c_driver_init+0x0/0x38 @ 1
    [    1.607430] initcall da9063_i2c_driver_init+0x0/0x38 returned 0 after 9 usecs
    [    1.608104] calling  max14577_i2c_init+0x0/0x38 @ 1
    [    1.608575] initcall max14577_i2c_init+0x0/0x38 returned 0 after 8 usecs
    [    1.609206] calling  max77693_i2c_driver_init+0x0/0x38 @ 1
    [    1.609752] initcall max77693_i2c_driver_init+0x0/0x38 returned 0 after 17 usecs
    [    1.610450] calling  adp5520_driver_init+0x0/0x38 @ 1
    [    1.610943] initcall adp5520_driver_init+0x0/0x38 returned 0 after 13 usecs
    [    1.611601] calling  rk8xx_i2c_driver_init+0x0/0x38 @ 1
    [    1.612104] initcall rk8xx_i2c_driver_init+0x0/0x38 returned 0 after 9 usecs
    [    1.612769] calling  rk8xx_spi_driver_init+0x0/0x38 @ 1
    [    1.613272] initcall rk8xx_spi_driver_init+0x0/0x38 returned 0 after 8 usecs
    [    1.613959] calling  of_pmem_region_driver_init+0x0/0x38 @ 1
    [    1.614582] initcall of_pmem_region_driver_init+0x0/0x38 returned 0 after 87 usecs
    [    1.615296] calling  system_heap_create+0x0/0x80 @ 1
    [    1.615922] initcall system_heap_create+0x0/0x80 returned 0 after 155 usecs
    [    1.616582] calling  udmabuf_dev_init+0x0/0xf0 @ 1
    [    1.617131] initcall udmabuf_dev_init+0x0/0xf0 returned 0 after 94 usecs
    [    1.617774] calling  init_sd+0x0/0x170 @ 1
    [    1.618189] initcall init_sd+0x0/0x170 returned 0 after 26 usecs
    [    1.618757] calling  init_sr+0x0/0x90 @ 1
    [    1.619146] initcall init_sr+0x0/0x90 returned 0 after 8 usecs
    [    1.619698] calling  init_sg+0x0/0x220 @ 1
    [    1.620105] initcall init_sg+0x0/0x220 returned 0 after 18 usecs
    [    1.620673] calling  piix_init+0x0/0x58 @ 1
    [    1.621092] initcall piix_init+0x0/0x58 returned 0 after 21 usecs
    [    1.621676] calling  sis_pci_driver_init+0x0/0x48 @ 1
    [    1.622182] initcall sis_pci_driver_init+0x0/0x48 returned 0 after 26 usecs
    [    1.622837] calling  ata_generic_pci_driver_init+0x0/0x40 @ 1
    [    1.623398] initcall ata_generic_pci_driver_init+0x0/0x40 returned 0 after 17 usecs
    [    1.624120] calling  blackhole_netdev_init+0x0/0x98 @ 1
    [    1.624629] initcall blackhole_netdev_init+0x0/0x98 returned 0 after 14 usecs
    [    1.625304] calling  phy_module_init+0x0/0x40 @ 1
    [    1.625767] initcall phy_module_init+0x0/0x40 returned 0 after 12 usecs
    [    1.626392] calling  fixed_mdio_bus_init+0x0/0x100 @ 1
    [    1.626925] probe of Fixed MDIO bus returned 0 after 21 usecs
    [    1.627676] initcall fixed_mdio_bus_init+0x0/0x100 returned 0 after 797 usecs
    [    1.628351] calling  tun_init+0x0/0x100 @ 1
    [    1.628749] tun: Universal TUN/TAP device driver, 1.6
    [    1.629378] initcall tun_init+0x0/0x100 returned 0 after 628 usecs
    [    1.629973] calling  ppp_init+0x0/0x158 @ 1
    [    1.630372] PPP generic driver version 2.4.2
    [    1.630899] initcall ppp_init+0x0/0x158 returned 0 after 527 usecs
    [    1.631487] calling  vfio_init+0x0/0xb8 @ 1
    [    1.632210] VFIO - User Level meta-driver version: 0.3
    [    1.632693] initcall vfio_init+0x0/0xb8 returned 0 after 808 usecs
    [    1.633278] calling  vfio_iommu_type1_init+0x0/0x38 @ 1
    [    1.633782] initcall vfio_iommu_type1_init+0x0/0x38 returned 0 after 0 usecs
    [    1.634448] calling  vfio_pci_core_init+0x0/0x30 @ 1
    [    1.634931] initcall vfio_pci_core_init+0x0/0x30 returned 0 after 11 usecs
    [    1.635581] calling  vfio_pci_init+0x0/0x230 @ 1
    [    1.636049] initcall vfio_pci_init+0x0/0x230 returned 0 after 28 usecs
    [    1.636667] calling  cdrom_init+0x0/0x30 @ 1
    [    1.637082] initcall cdrom_init+0x0/0x30 returned 0 after 8 usecs
    [    1.637663] calling  dwc2_platform_driver_init+0x0/0x38 @ 1
    [    1.638810] initcall dwc2_platform_driver_init+0x0/0x38 returned 0 after 618 usecs
    [    1.639526] calling  ehci_hcd_init+0x0/0x170 @ 1
    [    1.639970] initcall ehci_hcd_init+0x0/0x170 returned 0 after 7 usecs
    [    1.640580] calling  ehci_pci_init+0x0/0x88 @ 1
    [    1.641030] initcall ehci_pci_init+0x0/0x88 returned 0 after 19 usecs
    [    1.641644] calling  ehci_platform_init+0x0/0x60 @ 1
    [    1.642163] probe of fc800000.usb returned -517 after 15 usecs
    [    1.642248] initcall ehci_platform_init+0x0/0x60 returned 0 after 132 usecs
    [    1.642392] probe of fc880000.usb returned -517 after 18 usecs
    [    1.643906] calling  ohci_hcd_mod_init+0x0/0xd0 @ 1
    [    1.644373] initcall ohci_hcd_mod_init+0x0/0xd0 returned 0 after 3 usecs
    [    1.645006] calling  ohci_pci_init+0x0/0x88 @ 1
    [    1.645470] initcall ohci_pci_init+0x0/0x88 returned 0 after 28 usecs
    [    1.646080] calling  ohci_platform_init+0x0/0x60 @ 1
    [    1.646588] probe of fc840000.usb returned -517 after 10 usecs
    [    1.646626] probe of fc8c0000.usb returned -517 after 23 usecs
    [    1.646670] initcall ohci_platform_init+0x0/0x60 returned 0 after 118 usecs
    [    1.646680] calling  uhci_hcd_init+0x0/0x1a0 @ 1
    [    1.646721] initcall uhci_hcd_init+0x0/0x1a0 returned 0 after 32 usecs
    [    1.646730] calling  xhci_hcd_init+0x0/0x50 @ 1
    [    1.646744] initcall xhci_hcd_init+0x0/0x50 returned 0 after 5 usecs
    [    1.646752] calling  xhci_pci_init+0x0/0x98 @ 1
    [    1.646786] initcall xhci_pci_init+0x0/0x98 returned 0 after 25 usecs
    [    1.646796] calling  mousedev_init+0x0/0x128 @ 1
    [    1.647102] mousedev: PS/2 mouse device common for all mice
    [    1.647105] initcall mousedev_init+0x0/0x128 returned 0 after 300 usecs
    [    1.647115] calling  evdev_init+0x0/0x38 @ 1
    [    1.647124] initcall evdev_init+0x0/0x38 returned 0 after 0 usecs
    [    1.647132] calling  atkbd_init+0x0/0x48 @ 1
    [    1.654379] initcall atkbd_init+0x0/0x48 returned 0 after 28 usecs
    [    1.654965] calling  elants_i2c_driver_init+0x0/0x38 @ 1
    [    1.655490] initcall elants_i2c_driver_init+0x0/0x38 returned 0 after 20 usecs
    [    1.656172] calling  uinput_misc_init+0x0/0x38 @ 1
    [    1.656778] initcall uinput_misc_init+0x0/0x38 returned 0 after 150 usecs
    [    1.657429] calling  i2c_dev_init+0x0/0xd8 @ 1
    [    1.657848] i2c_dev: i2c /dev entries driver
    [    1.658257] initcall i2c_dev_init+0x0/0xd8 returned 0 after 409 usecs
    [    1.658862] calling  ptp_kvm_init+0x0/0x108 @ 1
    [    1.659290] initcall ptp_kvm_init+0x0/0x108 returned -95 after 0 usecs
    [    1.659904] calling  mt6323_pwrc_driver_init+0x0/0x38 @ 1
    [    1.660489] initcall mt6323_pwrc_driver_init+0x0/0x38 returned 0 after 78 usecs
    [    1.661175] calling  restart_poweroff_driver_init+0x0/0x38 @ 1
    [    1.661795] initcall restart_poweroff_driver_init+0x0/0x38 returned 0 after 66 usecs
    [    1.662523] calling  tps65086_restart_driver_init+0x0/0x38 @ 1
    [    1.663101] initcall tps65086_restart_driver_init+0x0/0x38 returned 0 after 28 usecs
    [    1.663826] calling  watchdog_gov_noop_register+0x0/0x38 @ 1
    [    1.664360] initcall watchdog_gov_noop_register+0x0/0x38 returned 0 after 1 usecs
    [    1.665062] calling  dm_init+0x0/0x118 @ 1
    [    1.665453] device-mapper: core: CONFIG_IMA_DISABLE_HTABLE is disabled. Duplicate IMA measurements will not be recorded in the IMA log.
    [    1.666653] device-mapper: uevent: version 1.0.3
    [    1.667306] device-mapper: ioctl: 4.49.0-ioctl (2025-01-17) initialised: dm-devel@lists.linux.dev
    [    1.668138] initcall dm_init+0x0/0x118 returned 0 after 2685 usecs
    [    1.668722] calling  mmc_pwrseq_simple_driver_init+0x0/0x38 @ 1
    [    1.669352] initcall mmc_pwrseq_simple_driver_init+0x0/0x38 returned 0 after 72 usecs
    [    1.670097] calling  mmc_pwrseq_emmc_driver_init+0x0/0x38 @ 1
    [    1.670703] initcall mmc_pwrseq_emmc_driver_init+0x0/0x38 returned 0 after 64 usecs
    [    1.671423] calling  smccc_devices_init+0x0/0xd8 @ 1
    [    1.671892] initcall smccc_devices_init+0x0/0xd8 returned 0 after 0 usecs
    [    1.672530] calling  smccc_soc_init+0x0/0x1c8 @ 1
    [    1.672975] SMCCC: SOC_ID: ARCH_SOC_ID not implemented, skipping ....
    [    1.673582] initcall smccc_soc_init+0x0/0x1c8 returned 0 after 607 usecs
    [    1.674213] calling  rproc_virtio_driver_init+0x0/0x38 @ 1
    [    1.674761] initcall rproc_virtio_driver_init+0x0/0x38 returned 0 after 29 usecs
    [    1.675457] calling  vmgenid_plaform_driver_init+0x0/0x38 @ 1
    [    1.676062] initcall vmgenid_plaform_driver_init+0x0/0x38 returned 0 after 61 usecs
    [    1.676784] calling  extcon_class_init+0x0/0x88 @ 1
    [    1.677251] initcall extcon_class_init+0x0/0x88 returned 0 after 5 usecs
    [    1.677887] calling  armv8_pmu_driver_init+0x0/0x58 @ 1
    [    1.678868] hw perfevents: enabled with armv8_cortex_a55 PMU driver, 7 (0,8000003f) counters available
    [    1.679767] probe of pmu-a55 returned 0 after 1358 usecs
    [    1.680664] hw perfevents: enabled with armv8_cortex_a76 PMU driver, 7 (0,8000003f) counters available
    [    1.681565] probe of pmu-a76 returned 0 after 1291 usecs
    [    1.682728] initcall armv8_pmu_driver_init+0x0/0x58 returned 0 after 4347 usecs
    [    1.683419] calling  icc_init+0x0/0xb8 @ 1
    [    1.684132] initcall icc_init+0x0/0xb8 returned 0 after 323 usecs
    [    1.684709] calling  sock_diag_init+0x0/0x60 @ 1
    [    1.685176] initcall sock_diag_init+0x0/0x60 returned 0 after 28 usecs
    [    1.685803] calling  init_net_drop_monitor+0x0/0x1b0 @ 1
    [    1.686307] drop_monitor: Initializing network drop monitor service
    [    1.686921] initcall init_net_drop_monitor+0x0/0x1b0 returned 0 after 614 usecs
    [    1.687611] calling  blackhole_init+0x0/0x38 @ 1
    [    1.688050] initcall blackhole_init+0x0/0x38 returned 0 after 2 usecs
    [    1.688658] calling  gre_offload_init+0x0/0x88 @ 1
    [    1.689114] initcall gre_offload_init+0x0/0x88 returned 0 after 1 usecs
    [    1.689750] calling  sysctl_ipv4_init+0x0/0x90 @ 1
    [    1.690313] initcall sysctl_ipv4_init+0x0/0x90 returned 0 after 107 usecs
    [    1.690956] calling  cubictcp_register+0x0/0xa8 @ 1
    [    1.691422] initcall cubictcp_register+0x0/0xa8 returned 0 after 2 usecs
    [    1.692055] calling  inet6_init+0x0/0x430 @ 1
    [    1.693094] NET: Registered PF_INET6 protocol family
    [    1.696098] Segment Routing with IPv6
    [    1.696470] In-situ OAM (IOAM) with IPv6
    [    1.696874] initcall inet6_init+0x0/0x430 returned 0 after 4409 usecs
    [    1.697497] calling  packet_init+0x0/0xb8 @ 1
    [    1.697915] NET: Registered PF_PACKET protocol family
    [    1.698388] initcall packet_init+0x0/0xb8 returned 0 after 477 usecs
    [    1.698986] calling  strp_dev_init+0x0/0x60 @ 1
    [    1.699562] initcall strp_dev_init+0x0/0x60 returned 0 after 149 usecs
    [    1.700177] calling  dcbnl_init+0x0/0x58 @ 1
    [    1.700583] initcall dcbnl_init+0x0/0x58 returned 0 after 2 usecs
    [    1.701156] calling  init_dns_resolver+0x0/0x170 @ 1
    [    1.701664] Key type dns_resolver registered
    [    1.702066] initcall init_dns_resolver+0x0/0x170 returned 0 after 431 usecs
    [    1.702722] calling  handshake_init+0x0/0xe8 @ 1
    [    1.703181] initcall handshake_init+0x0/0xe8 returned 0 after 22 usecs
    [    1.703796] calling  check_mmu_enabled_at_boot+0x0/0x40 @ 1
    [    1.704323] initcall check_mmu_enabled_at_boot+0x0/0x40 returned 0 after 0 usecs
    [    1.705144] calling  kernel_do_mounts_initrd_sysctls_init+0x0/0x50 @ 1
    [    1.705773] initcall kernel_do_mounts_initrd_sysctls_init+0x0/0x50 returned 0 after 3 usecs
    [    1.706561] calling  kernel_panic_sysctls_init+0x0/0x50 @ 1
    [    1.707094] initcall kernel_panic_sysctls_init+0x0/0x50 returned 0 after 6 usecs
    [    1.707792] calling  kernel_panic_sysfs_init+0x0/0x48 @ 1
    [    1.708307] initcall kernel_panic_sysfs_init+0x0/0x48 returned 0 after 5 usecs
    [    1.708988] calling  kernel_exit_sysctls_init+0x0/0x50 @ 1
    [    1.709514] initcall kernel_exit_sysctls_init+0x0/0x50 returned 0 after 2 usecs
    [    1.710204] calling  kernel_exit_sysfs_init+0x0/0x48 @ 1
    [    1.710711] initcall kernel_exit_sysfs_init+0x0/0x48 returned 0 after 3 usecs
    [    1.711383] calling  param_sysfs_builtin_init+0x0/0x280 @ 1
    [    1.716671] initcall param_sysfs_builtin_init+0x0/0x280 returned 0 after 4760 usecs
    [    1.717408] calling  reboot_ksysfs_init+0x0/0xb8 @ 1
    [    1.717893] initcall reboot_ksysfs_init+0x0/0xb8 returned 0 after 13 usecs
    [    1.718542] calling  sched_core_sysctl_init+0x0/0x50 @ 1
    [    1.719052] initcall sched_core_sysctl_init+0x0/0x50 returned 0 after 7 usecs
    [    1.719727] calling  sched_fair_sysctl_init+0x0/0x50 @ 1
    [    1.720228] initcall sched_fair_sysctl_init+0x0/0x50 returned 0 after 2 usecs
    [    1.720897] calling  sched_rt_sysctl_init+0x0/0x50 @ 1
    [    1.721383] initcall sched_rt_sysctl_init+0x0/0x50 returned 0 after 3 usecs
    [    1.722042] calling  sched_dl_sysctl_init+0x0/0x50 @ 1
    [    1.722526] initcall sched_dl_sysctl_init+0x0/0x50 returned 0 after 2 usecs
    [    1.723180] calling  sched_init_debug+0x0/0x370 @ 1
    [    1.723769] initcall sched_init_debug+0x0/0x370 returned 0 after 130 usecs
    [    1.724417] calling  sched_energy_aware_sysctl_init+0x0/0x50 @ 1
    [    1.724984] initcall sched_energy_aware_sysctl_init+0x0/0x50 returned 0 after 2 usecs
    [    1.725727] calling  cpu_latency_qos_init+0x0/0x80 @ 1
    [    1.726334] initcall cpu_latency_qos_init+0x0/0x80 returned 0 after 122 usecs
    [    1.727007] calling  pm_debugfs_init+0x0/0x50 @ 1
    [    1.727454] initcall pm_debugfs_init+0x0/0x50 returned 0 after 3 usecs
    [    1.728068] calling  printk_late_init+0x0/0x198 @ 1
    [    1.728540] initcall printk_late_init+0x0/0x198 returned 0 after 11 usecs
    [    1.729178] calling  init_srcu_module_notifier+0x0/0x70 @ 1
    [    1.729716] initcall init_srcu_module_notifier+0x0/0x70 returned 0 after 2 usecs
    [    1.730411] calling  swiotlb_create_default_debugfs+0x0/0xb8 @ 1
    [    1.730987] initcall swiotlb_create_default_debugfs+0x0/0xb8 returned 0 after 9 usecs
    [    1.731722] calling  tk_debug_sleep_time_init+0x0/0x50 @ 1
    [    1.732243] initcall tk_debug_sleep_time_init+0x0/0x50 returned 0 after 2 usecs
    [    1.732931] calling  bpf_ksym_iter_register+0x0/0x38 @ 1
    [    1.733536] initcall bpf_ksym_iter_register+0x0/0x38 returned 0 after 74 usecs
    [    1.734219] calling  kernel_acct_sysctls_init+0x0/0x50 @ 1
    [    1.734740] initcall kernel_acct_sysctls_init+0x0/0x50 returned 0 after 2 usecs
    [    1.735429] calling  kexec_core_sysctl_init+0x0/0x50 @ 1
    [    1.735934] initcall kexec_core_sysctl_init+0x0/0x50 returned 0 after 4 usecs
    [    1.736606] calling  bpf_rstat_kfunc_init+0x0/0x38 @ 1
    [    1.737092] initcall bpf_rstat_kfunc_init+0x0/0x38 returned 0 after 1 usecs
    [    1.737756] calling  debugfs_kprobe_init+0x0/0xc8 @ 1
    [    1.738246] initcall debugfs_kprobe_init+0x0/0xc8 returned 0 after 11 usecs
    [    1.738903] calling  kernel_delayacct_sysctls_init+0x0/0x50 @ 1
    [    1.739465] initcall kernel_delayacct_sysctls_init+0x0/0x50 returned 0 after 1 usecs
    [    1.740195] calling  taskstats_init+0x0/0x60 @ 1
    [    1.740644] registered taskstats version 1
    [    1.741028] initcall taskstats_init+0x0/0x60 returned 0 after 395 usecs
    [    1.741677] calling  ftrace_sysctl_init+0x0/0x40 @ 1
    [    1.742151] initcall ftrace_sysctl_init+0x0/0x40 returned 0 after 2 usecs
    [    1.742793] calling  init_hwlat_tracer+0x0/0x140 @ 1
    [    1.743643] initcall init_hwlat_tracer+0x0/0x140 returned 0 after 378 usecs
    [    1.744304] calling  init_osnoise_tracer+0x0/0x380 @ 1
    [    1.745096] initcall init_osnoise_tracer+0x0/0x380 returned 0 after 304 usecs
    [    1.745782] calling  bpf_key_sig_kfuncs_init+0x0/0x28 @ 1
    [    1.746290] initcall bpf_key_sig_kfuncs_init+0x0/0x28 returned 0 after 0 usecs
    [    1.746968] calling  bpf_kprobe_multi_kfuncs_init+0x0/0x30 @ 1
    [    1.747517] initcall bpf_kprobe_multi_kfuncs_init+0x0/0x30 returned 0 after 0 usecs
    [    1.748237] calling  kdb_ftrace_register+0x0/0x28 @ 1
    [    1.748718] initcall kdb_ftrace_register+0x0/0x28 returned 0 after 5 usecs
    [    1.749363] calling  bpf_global_ma_init+0x0/0x58 @ 1
    [    1.749942] initcall bpf_global_ma_init+0x0/0x58 returned 0 after 106 usecs
    [    1.750599] calling  bpf_syscall_sysctl_init+0x0/0x50 @ 1
    [    1.751111] initcall bpf_syscall_sysctl_init+0x0/0x50 returned 0 after 3 usecs
    [    1.751789] calling  unbound_reg_init+0x0/0x78 @ 1
    [    1.752241] initcall unbound_reg_init+0x0/0x78 returned 0 after 0 usecs
    [    1.752863] calling  kfunc_init+0x0/0x110 @ 1
    [    1.753276] initcall kfunc_init+0x0/0x110 returned 0 after 1 usecs
    [    1.753863] calling  bpf_map_iter_init+0x0/0x50 @ 1
    [    1.754323] initcall bpf_map_iter_init+0x0/0x50 returned 0 after 0 usecs
    [    1.754953] calling  init_subsystem+0x0/0x40 @ 1
    [    1.755390] initcall init_subsystem+0x0/0x40 returned 0 after 0 usecs
    [    1.755995] calling  task_iter_init+0x0/0x140 @ 1
    [    1.756440] initcall task_iter_init+0x0/0x140 returned 0 after 1 usecs
    [    1.757053] calling  bpf_prog_iter_init+0x0/0x38 @ 1
    [    1.757525] initcall bpf_prog_iter_init+0x0/0x38 returned 0 after 0 usecs
    [    1.758164] calling  bpf_link_iter_init+0x0/0x38 @ 1
    [    1.758632] initcall bpf_link_iter_init+0x0/0x38 returned 0 after 0 usecs
    [    1.759270] calling  init_trampolines+0x0/0x78 @ 1
    [    1.759726] initcall init_trampolines+0x0/0x78 returned 0 after 2 usecs
    [    1.760347] calling  rqspinlock_register_kfuncs+0x0/0x38 @ 1
    [    1.760880] initcall rqspinlock_register_kfuncs+0x0/0x38 returned 0 after 0 usecs
    [    1.761587] calling  kfunc_init+0x0/0x40 @ 1
    [    1.761990] initcall kfunc_init+0x0/0x40 returned 0 after 0 usecs
    [    1.762563] calling  bpf_cgroup_iter_init+0x0/0x40 @ 1
    [    1.763048] initcall bpf_cgroup_iter_init+0x0/0x40 returned 0 after 0 usecs
    [    1.763703] calling  cpumask_kfunc_init+0x0/0xd0 @ 1
    [    1.764187] initcall cpumask_kfunc_init+0x0/0xd0 returned 0 after 15 usecs
    [    1.764835] calling  crypto_kfunc_init+0x0/0xc0 @ 1
    [    1.765296] initcall crypto_kfunc_init+0x0/0xc0 returned 0 after 0 usecs
    [    1.765931] calling  bpf_kmem_cache_iter_init+0x0/0x40 @ 1
    [    1.766448] initcall bpf_kmem_cache_iter_init+0x0/0x40 returned 0 after 0 usecs
    [    1.767135] calling  load_system_certificate_list+0x0/0x50 @ 1
    [    1.767684] Loading compiled-in X.509 certificates
    [    1.770381] Loaded X.509 cert 'Build time autogenerated kernel key: 25db107803b7668676e8f8aca5e242434540b333'
    [    1.773318] Loaded X.509 cert 'Canonical Ltd. Live Patch Signing: 14df34d1a87cf37625abec039ef2bf521249b969'
    [    1.776220] Loaded X.509 cert 'Canonical Ltd. Kernel Module Signing: 88f752e560a1e0737e31163a466ad7b70a850c19'
    [    1.777156] initcall load_system_certificate_list+0x0/0x50 returned 0 after 9472 usecs
    [    1.777906] calling  load_revocation_certificate_list+0x0/0x68 @ 1
    [    1.778489] blacklist: Loading compiled-in revocation X.509 certificates
    [    1.779160] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing: 61482aa2830d0ab2ad5af10b7250da9033ddcef0'
    [    1.780138] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (2017): 242ade75ac4a15e50d50c84b0d45ff3eae707a03'
    [    1.781150] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (ESM 2018): 365188c1d374d6b07c3c8f240f8ef722433d6a8b'
    [    1.782207] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (2019): c0746fd6c5da3ae827864651ad66ae47fe24b3e8'
    [    1.783227] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (2021 v1): a8d54bbb3825cfb94fa13c9f8a594a195c107b8d'
    [    1.784263] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (2021 v2): 4cf046892d6fd3c9a5b03f98d845f90851dc6a8c'
    [    1.785297] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (2021 v3): 100437bb6de6e469b581e61cd66bce3ef4ed53af'
    [    1.786357] Loaded X.509 cert 'Canonical Ltd. Secure Boot Signing (Ubuntu Core 2019): c1d57b8f6b743f23ee41f4f7ee292f06eecadfb9'
    [    1.787429] initcall load_revocation_certificate_list+0x0/0x68 returned 0 after 8941 usecs
    [    1.788208] calling  vmstat_late_init+0x0/0x40 @ 1
    [    1.788663] initcall vmstat_late_init+0x0/0x40 returned 0 after 2 usecs
    [    1.789286] calling  fault_around_debugfs+0x0/0x50 @ 1
    [    1.789783] initcall fault_around_debugfs+0x0/0x50 returned 0 after 5 usecs
    [    1.790440] calling  slab_sysfs_init+0x0/0x160 @ 1
    [    1.798083] initcall slab_sysfs_init+0x0/0x160 returned 0 after 7188 usecs
    [    1.798738] calling  max_swapfiles_check+0x0/0x18 @ 1
    [    1.799218] initcall max_swapfiles_check+0x0/0x18 returned 0 after 0 usecs
    [    1.799866] calling  zswap_init+0x0/0x68 @ 1
    [    1.800272] initcall zswap_init+0x0/0x68 returned 0 after 0 usecs
    [    1.800848] calling  mempolicy_sysfs_init+0x0/0x2a0 @ 1
    [    1.801351] initcall mempolicy_sysfs_init+0x0/0x2a0 returned 0 after 8 usecs
    [    1.802022] calling  kfence_debugfs_init+0x0/0xc0 @ 1
    [    1.802499] initcall kfence_debugfs_init+0x0/0xc0 returned 0 after 0 usecs
    [    1.803145] calling  memory_tier_late_init+0x0/0x108 @ 1
    [    1.803750] Demotion targets for Node 0: null
    [    1.804160] initcall memory_tier_late_init+0x0/0x108 returned 0 after 511 usecs
    [    1.804852] calling  split_huge_pages_debugfs+0x0/0x58 @ 1
    [    1.805377] initcall split_huge_pages_debugfs+0x0/0x58 returned 0 after 5 usecs
    [    1.806075] calling  check_early_ioremap_leak+0x0/0xc0 @ 1
    [    1.806592] initcall check_early_ioremap_leak+0x0/0xc0 returned 0 after 0 usecs
    [    1.807277] calling  set_hardened_usercopy+0x0/0x80 @ 1
    [    1.807772] initcall set_hardened_usercopy+0x0/0x80 returned 1 after 1 usecs
    [    1.808434] calling  mg_debugfs_init+0x0/0x58 @ 1
    [    1.808880] initcall mg_debugfs_init+0x0/0x58 returned 0 after 2 usecs
    [    1.809502] calling  fscrypt_init+0x0/0xf8 @ 1
    [    1.810139] Key type .fscrypt registered
    [    1.810507] Key type fscrypt-provisioning registered
    [    1.810972] initcall fscrypt_init+0x0/0xf8 returned 0 after 1050 usecs
    [    1.811588] calling  fsverity_init+0x0/0x60 @ 1
    [    1.812202] initcall fsverity_init+0x0/0x60 returned 0 after 185 usecs
    [    1.812819] calling  pstore_init+0x0/0x78 @ 1
    [    1.813241] initcall pstore_init+0x0/0x78 returned 0 after 9 usecs
    [    1.813831] calling  bpf_fs_kfuncs_init+0x0/0x38 @ 1
    [    1.814301] initcall bpf_fs_kfuncs_init+0x0/0x38 returned 0 after 0 usecs
    [    1.814941] calling  init_root_keyring+0x0/0x38 @ 1
    [    1.815441] initcall init_root_keyring+0x0/0x38 returned 0 after 36 usecs
    [    1.816083] calling  init_trusted+0x0/0x198 @ 1
    [    1.816514] initcall init_trusted+0x0/0x198 returned 0 after 1 usecs
    [    1.817115] calling  init_encrypted+0x0/0x128 @ 1
    [    1.819932] Key type encrypted registered
    [    1.820309] initcall init_encrypted+0x0/0x128 returned 0 after 2743 usecs
    [    1.820950] calling  init_profile_hash+0x0/0xd0 @ 1
    [    1.821421] AppArmor: AppArmor sha256 policy hashing enabled
    [    1.821952] initcall init_profile_hash+0x0/0xd0 returned 0 after 533 usecs
    [    1.822599] calling  integrity_fs_init+0x0/0x98 @ 1
    [    1.823065] initcall integrity_fs_init+0x0/0x98 returned 0 after 7 usecs
    [    1.823693] calling  init_ima+0x0/0x150 @ 1
    [    1.824090] ima: No TPM chip found, activating TPM-bypass!
    [    1.824609] Loading compiled-in module X.509 certificates
    [    1.827124] Loaded X.509 cert 'Build time autogenerated kernel key: 25db107803b7668676e8f8aca5e242434540b333'
    [    1.828053] ima: Allocated hash algorithm: sha1
    [    1.828492] ima: No architecture policies found
    [    1.828954] initcall init_ima+0x0/0x150 returned 0 after 4866 usecs
    [    1.829552] calling  init_evm+0x0/0x1f8 @ 1
    [    1.829947] evm: Initialising EVM extended attributes:
    [    1.830428] evm: security.selinux
    [    1.830740] evm: security.SMACK64
    [    1.831051] evm: security.SMACK64EXEC
    [    1.831395] evm: security.SMACK64TRANSMUTE
    [    1.831779] evm: security.SMACK64MMAP
    [    1.832122] evm: security.apparmor
    [    1.832441] evm: security.ima
    [    1.832719] evm: security.capability
    [    1.833055] evm: HMAC attrs: 0x1
    [    1.833406] initcall init_evm+0x0/0x1f8 returned 0 after 3458 usecs
    [    1.833996] calling  crypto_algapi_init+0x0/0x30 @ 1
    [    1.834470] initcall crypto_algapi_init+0x0/0x30 returned 0 after 4 usecs
    [    1.835109] calling  blk_timeout_init+0x0/0x28 @ 1
    [    1.835563] initcall blk_timeout_init+0x0/0x28 returned 0 after 0 usecs
    [    1.836185] calling  sed_opal_init+0x0/0x108 @ 1
    [    1.836636] initcall sed_opal_init+0x0/0x108 returned 0 after 14 usecs
    [    1.837252] calling  init_error_injection+0x0/0xb0 @ 1
    [    1.837958] initcall init_error_injection+0x0/0xb0 returned 0 after 214 usecs
    [    1.838631] calling  depot_debugfs_init+0x0/0x88 @ 1
    [    1.839108] initcall depot_debugfs_init+0x0/0x88 returned 0 after 4 usecs
    [    1.839748] calling  pci_resource_alignment_sysfs_init+0x0/0x40 @ 1
    [    1.840346] initcall pci_resource_alignment_sysfs_init+0x0/0x40 returned 0 after 5 usecs
    [    1.841108] calling  pci_sysfs_init+0x0/0xc0 @ 1
    [    1.841554] initcall pci_sysfs_init+0x0/0xc0 returned 0 after 2 usecs
    [    1.842162] calling  clk_debug_init+0x0/0x148 @ 1
    [    1.867783] initcall clk_debug_init+0x0/0x148 returned 0 after 25173 usecs
    [    1.868442] calling  genpd_debug_init+0x0/0xa8 @ 1
    [    1.868901] initcall genpd_debug_init+0x0/0xa8 returned 0 after 7 usecs
    [    1.869531] calling  sync_state_resume_initcall+0x0/0x30 @ 1
    [    1.870068] initcall sync_state_resume_initcall+0x0/0x30 returned 0 after 1 usecs
    [    1.870771] calling  deferred_probe_initcall+0x0/0xe0 @ 1
    [    1.871411] probe of fe378000.rng returned -517 after 20 usecs
    [    1.872184] probe of fc880000.usb returned -517 after 20 usecs
    [    1.872406] probe of fc800000.usb returned -517 after 14 usecs
    [    1.872633] probe of fc840000.usb returned -517 after 16 usecs
    [    1.872719] probe of fc8c0000.usb returned -517 after 12 usecs
    [    1.872780] probe of fe378000.rng returned -517 after 12 usecs
    [    1.875190] probe of fc840000.usb returned -517 after 20 usecs
    [    1.875357] probe of fc8c0000.usb returned -517 after 45 usecs
    [    1.875433] probe of fc880000.usb returned -517 after 22 usecs
    [    1.875449] probe of fe378000.rng returned -517 after 13 usecs
    [    1.875484] initcall deferred_probe_initcall+0x0/0xe0 returned 0 after 4204 usecs
    [    1.875495] calling  sync_debugfs_init+0x0/0x90 @ 1
    [    1.875544] probe of fc800000.usb returned -517 after 35 usecs
    [    1.875561] initcall sync_debugfs_init+0x0/0x90 returned 0 after 56 usecs
    [    1.875571] calling  charger_manager_init+0x0/0xb8 @ 1
    [    1.875988] initcall charger_manager_init+0x0/0xb8 returned 0 after 410 usecs
    [    1.880861] calling  dm_init_init+0x0/0x940 @ 1
    [    1.881289] initcall dm_init_init+0x0/0x940 returned 0 after 1 usecs
    [    1.881893] calling  firmware_memmap_init+0x0/0x68 @ 1
    [    1.882377] initcall firmware_memmap_init+0x0/0x68 returned 0 after 0 usecs
    [    1.883030] calling  psci_debugfs_init+0x0/0x80 @ 1
    [    1.883495] initcall psci_debugfs_init+0x0/0x80 returned 0 after 5 usecs
    [    1.884125] calling  of_fdt_raw_init+0x0/0xb8 @ 1
    [    1.884603] initcall of_fdt_raw_init+0x0/0xb8 returned 0 after 32 usecs
    [    1.885226] calling  bpf_kfunc_init+0x0/0x138 @ 1
    [    1.885678] initcall bpf_kfunc_init+0x0/0x138 returned 0 after 2 usecs
    [    1.886292] calling  init_subsystem+0x0/0x40 @ 1
    [    1.886730] initcall init_subsystem+0x0/0x40 returned 0 after 0 usecs
    [    1.887337] calling  xdp_metadata_init+0x0/0x38 @ 1
    [    1.887799] initcall xdp_metadata_init+0x0/0x38 returned 0 after 0 usecs
    [    1.888430] calling  bpf_sockmap_iter_init+0x0/0x48 @ 1
    [    1.888925] initcall bpf_sockmap_iter_init+0x0/0x48 returned 0 after 1 usecs
    [    1.889594] calling  bpf_sk_storage_map_iter_init+0x0/0x48 @ 1
    [    1.890145] initcall bpf_sk_storage_map_iter_init+0x0/0x48 returned 0 after 0 usecs
    [    1.890867] calling  bpf_prog_test_run_init+0x0/0xc0 @ 1
    [    1.891371] initcall bpf_prog_test_run_init+0x0/0xc0 returned 0 after 1 usecs
    [    1.892043] calling  bpf_dummy_struct_ops_init+0x0/0x38 @ 1
    [    1.892570] initcall bpf_dummy_struct_ops_init+0x0/0x38 returned 0 after 0 usecs
    [    1.893267] calling  tcp_congestion_default+0x0/0x40 @ 1
    [    1.893776] initcall tcp_congestion_default+0x0/0x40 returned 0 after 1 usecs
    [    1.894448] calling  inet_blackhole_dev_init+0x0/0x58 @ 1
    [    1.894968] initcall inet_blackhole_dev_init+0x0/0x58 returned 0 after 8 usecs
    [    1.895649] calling  tcp_bpf_v4_build_proto+0x0/0xe0 @ 1
    [    1.896154] initcall tcp_bpf_v4_build_proto+0x0/0xe0 returned 0 after 0 usecs
    [    1.896828] calling  udp_bpf_v4_build_proto+0x0/0x78 @ 1
    [    1.897331] initcall udp_bpf_v4_build_proto+0x0/0x78 returned 0 after 0 usecs
    [    1.898007] calling  bpf_tcp_ca_kfunc_init+0x0/0x58 @ 1
    [    1.898503] initcall bpf_tcp_ca_kfunc_init+0x0/0x58 returned 0 after 0 usecs
    [    1.899169] calling  bpf_mptcp_kfunc_init+0x0/0x38 @ 1
    [    1.899653] initcall bpf_mptcp_kfunc_init+0x0/0x38 returned 0 after 0 usecs
    [    1.900308] calling  software_resume_initcall+0x0/0x1a8 @ 1
    [    1.900834] initcall software_resume_initcall+0x0/0x1a8 returned -2 after 2 usecs
    [    1.901541] calling  lockup_detector_check+0x0/0xa0 @ 1
    [    1.902077] initcall lockup_detector_check+0x0/0xa0 returned 0 after 40 usecs
    [    1.902749] calling  latency_fsnotify_init+0x0/0x58 @ 1
    [    1.903259] initcall latency_fsnotify_init+0x0/0x58 returned 0 after 14 usecs
    [    1.903934] calling  trace_eval_sync+0x0/0x38 @ 1
    [    1.904395] initcall trace_eval_sync+0x0/0x38 returned 0 after 14 usecs
    [    1.905019] calling  late_trace_init+0x0/0xf0 @ 1
    [    1.905472] initcall late_trace_init+0x0/0xf0 returned 0 after 0 usecs
    [    1.906089] calling  fb_logo_late_init+0x0/0x28 @ 1
    [    1.906552] initcall fb_logo_late_init+0x0/0x28 returned 0 after 0 usecs
    [    1.907185] calling  amba_stub_drv_init+0x0/0x50 @ 1
    [    1.907691] initcall amba_stub_drv_init+0x0/0x50 returned 0 after 34 usecs
    [    1.908342] calling  clk_disable_unused+0x0/0x1a8 @ 1
    [    1.908821] clk: Not disabling unused clocks
    [    1.909221] initcall clk_disable_unused+0x0/0x1a8 returned 0 after 401 usecs
    [    1.909896] calling  genpd_power_off_unused+0x0/0xe8 @ 1
    [    1.910396] PM: genpd: Not disabling unused power domains
    [    1.910901] initcall genpd_power_off_unused+0x0/0xe8 returned 0 after 504 usecs
    [    1.911586] calling  regulator_init_complete+0x0/0x78 @ 1
    [    1.912095] initcall regulator_init_complete+0x0/0x78 returned 0 after 1 usecs
    [    1.912772] calling  of_platform_sync_state_init+0x0/0x30 @ 1
    [    1.913314] initcall of_platform_sync_state_init+0x0/0x30 returned 0 after 0 usecs
    [    1.914056] Warning: unable to open an initial console.
    [    1.919016] Freeing unused kernel memory: 8256K
    [    2.144860] Checked W+X mappings: passed, no W+X pages found
    [    2.145435] Run /init as init process
    [    2.145784]   with arguments:
    [    2.146065]     /init
    [    2.146281]   with environment:
    [    2.146576]     HOME=/
    [    2.146798]     TERM=linux
    [    2.147053]     splash=verbose
    [    2.171818] Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100
    [    2.172543] CPU: 7 UID: 0 PID: 1 Comm: init Not tainted 6.15.7 #8 PREEMPT(voluntary)
    [    2.173280] Hardware name: Xunlong Orange Pi 5 Plus (DT)
    [    2.173779] Call trace:
    [    2.174010]  show_stack+0x20/0x38 (C)
    [    2.174362]  dump_stack_lvl+0x38/0x90
    [    2.174714]  dump_stack+0x18/0x28
    [    2.175031]  panic+0x3c8/0x458
    [    2.175325]  do_exit+0x860/0x9b8
    [    2.175632]  do_group_exit+0x3c/0xa0
    [    2.175971]  __arm64_sys_exit_group+0x20/0x28
    [    2.176385]  invoke_syscall.constprop.0+0x78/0xd8
    [    2.176833]  do_el0_svc+0x50/0xe8
    [    2.177149]  el0_svc+0x3c/0x140
    [    2.177451]  el0t_64_sync_handler+0x144/0x168
    [    2.177865]  el0t_64_sync+0x198/0x1a0
    [    2.178213] SMP: stopping secondary CPUs
    [    2.178591] Kernel Offset: 0x5475afa00000 from 0xffff800080000000
    [    2.179163] PHYS_OFFSET: 0xfff0c99b40000000
    [    2.179556] CPU features: 0x0c00,000002e0,01202650,8200720b
    [    2.180081] Memory Limit: none
    [    2.180369] ---[ end Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100 ]---
</details>

# Official OrangePi 5 Build

For first steps, you can try to build the original OrangePi5 Kernel based on http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_5_Plus#Compile_the_linux_kernel

### Create an image based on Opi5 kernel deb packages

* Create chroot environment where the deb-packages of the built kernel can be unpacked:

```
# sets up the chroot dir with all defined binaries that are required to unpack the debs in the chroot-env, like dash, ls, dpkg, tar. Default dir is ./image
bash ./create_image.sh
# copy all required debs into the image dir (./output is the output of OrangePi5 build.sh):
cp -vr output/ ./image/
# create the chroot env with default dir:
sudo chroot ./image /bin/dash
# within chroot, unpack the debs:
dpkg -x output/debs/linux-image-current-rockchip-rk3588_1.2.0_arm64.deb /
# repeat for each *.deb
```
* now copy the content of ./image/ to a sdcard
* for a custom rootfs, continue with the [create rootfs] section

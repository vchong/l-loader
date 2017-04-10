#!/bin/sh
#DTB=pxa910-dkb.dtb
#DTB=pxa168-aspenite.dtb
#DTB=mmp2-brownstone.dtb
#DTB=hi3620-hi4511.dtb
#DTB=hix5hd2-dkb.dtb
#DTB=hip04-d01.dtb
#DTB=vexpress-v2p-ca9.dtb
#DTB=exynos5250-arndale.dtb
#DTB=pxa27x.dtb
#DTB=omap4-panda-es.dtb
#DTB=rtsm_ve-aemv8a.dtb
#DTB=pxa3xx.dtb
#DTB=hi6220_cs_udp_ddr3_config.dtb
#DTB=hi6220-hikey.dtb
DTB=hi3660-hikey960.dtb

ARCH=arm
BOOT=arch/arm/boot
#ANDROID_TOOLCHAIN=1

case "$DTB" in
"hi6220_cs_udp_ddr3_config.dtb")
	unset ARCH
	#DIR=/tmp
	DIR=/media/hzhuang1/windowsshare
	OUT=out_v8r2
	BOOT=arch/arm64/boot
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
	if [ ! -d $OUT ]; then
		echo "can't find out_v8r2, so create it"
		mkdir -p $OUT
		make hisi_hi6210sft_defconfig O=$OUT
	fi
	;;
"rtsm_ve-aemv8a.dtb")
	DIR=/home/hzhuang1
	OUT=out_v8
	BOOT=arch/arm64/boot
	export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
	if [ ! -d $OUT ]; then
		echo "can't find out_v8, so create it"
		mkdir -p $OUT
		make defconfig O=$OUT
	fi
	;;
"hi6220-hikey.dtb")
	DIR=/home/hzhuang1
	BOOT=arch/arm64/boot
	export ARCH=arm64
	if [ $ANDROID_TOOLCHAIN ]; then
		export CROSS_COMPILE=aarch64-linux-android-
		OUT=out_android_v8
	else
		export CROSS_COMPILE=aarch64-linux-gnu-
		OUT=out_v8
	fi
	if [ ! -d $OUT ]; then
		echo "can't find out_v8, so create it"
		mkdir -p $OUT
		make defconfig O=$OUT 
	fi
	;;
"hi3660-hikey960.dtb")
	DIR=/opt/workspace/boot/uefi/hikey960/l-loader
	BOOT=arch/arm64/boot
	export ARCH=arm64
	if [ $ANDROID_TOOLCHAIN ]; then
		export CROSS_COMPILE=aarch64-linux-android-
		OUT=out_android_v8
	else
		export CROSS_COMPILE=aarch64-linux-gnu-
		OUT=out_v8
	fi
	if [ ! -d $OUT ]; then
		echo "can't find out_v8, so create it"
		mkdir -p $OUT
		make hikey960_defconfig O=$OUT
		#make defconfig O=$OUT 
	fi
	;;
"hip04-d01.dtb" )
	echo "found D01"
	# use ftp protocol
	DIR=/home/hzhuang1
	OUT=out_p04
	if [ ! -d $OUT ]; then
		echo "can't find out_p04, so create it"
		mkdir -p $OUT
		make hisi_defconfig O=$OUT
	fi
	;;
"hi3620-hi4511.dtb" )
	echo "found hi3xxx"
	# use tftp protocol
	DIR=/var/lib/tftpboot
	OUT=out_hi3xxx
	if [ ! -d $OUT ]; then
		echo "can't find out_hi3xxx, so create it"
		mkdir -p $OUT
		#make hi3xxx_defconfig O=$OUT
		make hisi_defconfig O=$OUT
	fi
	;;
"hix5hd2-dkb.dtb" )
	echo "found hix5hd2"
	DIR=/var/lib/tftpboot
	OUT=out_hi3xxx
	if [ ! -d $OUT ]; then
		echo "can't find out_hi3xxx, so create it"
		mkdir -p $OUT
		make hi3xxx_defconfig O=$OUT
	fi
	;;
"pxa27x.dtb" )
	echo "found pxa27x"
	DIR=/var/lib/tftpboot
	OUT=out_pxa27x
	if [ ! -d $OUT ]; then
		echo "can't find out_pxa27x, so create it"
		mkdir -p $OUT
		make corgi_defconfig O=$OUT
	fi
	;;
"pxa3xx.dtb" )
	echo "found pxa3xx"
	DIR=/var/lib/tftpboot
	OUT=out_pxa3xx
	if [ ! -d $OUT ]; then
		echo "can't find out_pxa3xx, so create it"
		mkdir -p $OUT
		make pxa3xx_defconfig O=$OUT
	fi
	;;
"pxa910-dkb.dtb" )
	echo "found pxa910"
	DIR=/var/lib/tftpboot
	OUT=out_pxa910
	if [ ! -d $OUT ]; then
		echo "can't find out_pxa910, so create it"
		mkdir -p $OUT
		make pxa910_defconfig O=$OUT
	fi
	;;
"exynos5250-arndale.dtb")
	echo "found exynos arndale"
	# use tftp protocol
	DIR=/var/lib/tftpboot/
	OUT=out_exynos
	UIMAGE=uImage
	if [ ! -d $OUT ]; then
		echo "can't find out_exynos, so create it"
		mkdir -p $OUT
		make exynos_defconfig O=$OUT
	fi
	;;
"vexpress-v2p-ca9.dtb" )
	echo "found vexpress"
	# use qemu
	DIR=/opt/workspace/qemu_vexpress/
	OUT=out_vexpress
	if [ ! -d $OUT ]; then
		echo "can't find out_vexpress, so create it"
		mkdir -p $OUT
		make vexpress_defconfig O=$OUT
	fi
	;;
"omap4-panda-es.dtb" )
	echo "found omap4 panda"
	DIR=/var/lib/tftpboot
	OUT=out_omap4
	if [ ! -d $OUT ]; then
		echo "can't find out_omap4, so create it"
		mkdir -p $OUT
		make omap2plus_defconfig O=$OUT
	fi
	;;
* )
	echo "can't find any board"
	exit
	;;
esac

if [ $DISTCC ]; then
	CC="distcc ${CROSS_COMPILE}gcc"
fi

make oldconfig O=$OUT/ V=1

if [ $DISTCC ]; then
	make ${UIMAGE} -j10 CC="distcc ${CROSS_COMPILE}gcc" O=$OUT
	make ${DTB} -j10 CC="distcc ${CROSS_COMPILE}gcc" O=$OUT
else
	make ${UIMAGE} -j8 O=$OUT
	#make modules -j8 O=$OUT
	#make ${DTB} -j8 O=$OUT
fi

case "$DTB" in
"hi6220_cs_udp_ddr3_config.dtb")
	if [ -f $OUT/$BOOT/Image ]; then
		UTILS=./utils
		#ramdisk shell
		RAMDISK=$UTILS/ramdisk_64.img
		#android ramdisk
		#RAMDISK=$UTILS/ramdisk.img
		abootimg  --kernel $OUT/$BOOT/Image --ramdisk $RAMDISK --cmdline "k3v2mem hisi_dma_print=0 vmalloc=484M maxcpus=8 no_irq_affinity earlyprintk=pl011,0xf8015000" --base 0x07400000 --tags-addr 0x09e00000 --kernel_offset 0x00080000 --ramdisk_offset 0x07c00000  --output boot.img
		#cp boot.img $DIR/boot.img
	fi
	;;
"hi3660-hikey960.dtb")
	if [ -f $OUT/$BOOT/Image ]; then
		UTILS=./utils
		TOOLS=/media/hzhuang1/5a02a996-5c6e-46f2-9509-ba495026e0e8/workspace/hikey960/tools-images-hikey960
		#ramdisk shell
		#RAMDISK=$UTILS/ramdisk_64.img
		#android ramdisk
		#RAMDISK=$UTILS/ramdisk.img
		RAMDISK=/opt/workspace/96/960/aosp_49/hikey960-linaro-2017.02.28/flatten_image/initrd.img
		cat $OUT/$BOOT/Image $OUT/$BOOT/dts/hisilicon/$DTB > $OUT/$BOOT/Image-dtb
		abootimg --create $OUT/$BOOT/boot.img -k $OUT/$BOOT/Image-dtb -r $RAMDISK -f bootimg-960.cfg
		cp $OUT/$BOOT/boot.img $DIR/boot.img
		if [ -f $TOOLS/dtbTool ]; then
			rm $OUT/$BOOT/dts/hisilicon/hi6220-hikey.dtb
			rm $OUT/$BOOT/dts/hisilicon/hip05-d02.dtb
			$TOOLS/dtbTool -o dt.img -s 2048 -p $OUT/scripts/dtc/ -v $OUT/$BOOT/dts/hisilicon/
			cp dt.img $DIR/dt.img
		fi
	fi
	;;
"hip04-d01.dtb" )
	if [ -f $OUT/$BOOT/zImage-dtb.hip04-d01 ]; then
		cp $OUT/$BOOT/zImage-dtb.hip04-d01 $DIR/.kernel
	else
		cat $OUT/$BOOT/zImage $OUT/$BOOT/dts/${DTB} > $DIR/.kernel
	fi
	;;
"exynos5250-arndale.dtb" )
	if [ -f $OUT/$BOOT/uImage ]; then
		cp $OUT/$BOOT/uImage /tmp/uImage
		cp $OUT/$BOOT/dts/exynos5250-arndale.dtb /tmp/board.dtb
	fi
	;;
"vexpress-v2p-ca9.dtb" )
	cp $OUT/$BOOT/zImage $DIR/zImage
	cp $OUT/$BOOT/dts/vexpress-v2p-ca9.dtb $DIR/vexpress-v2p-ca9.dtb
	;;
"rtsm_ve-aemv8a.dtb")
	cp $OUT/$BOOT/zImage $OUT/$BOOT/dts/${DTB} > $DIR/zImage_dtb
	;;
"hi6220-hikey.dtb")
	if [ -f $OUT/$BOOT/Image ]; then
		UTILS=./utils
		TOOLS=/media/hzhuang1/5a02a996-5c6e-46f2-9509-ba495026e0e8/workspace/hikey_aosp/aosp/out/host/linux-x86/bin
		#ramdisk shell
		RAMDISK=$UTILS/ramdisk_64.img
		#android ramdisk
		#RAMDISK=$UTILS/ramdisk.img
		$TOOLS/mkbootimg  --kernel $OUT/$BOOT/Image.gz --ramdisk $RAMDISK --cmdline "loglevel=15 console=ttyAMA3,115200,8n1 androidboot.hardware=hikey androidboot.selinux=permissive firmware_class.path=/system/etc/firmware" --base 0 --tags_offset 0x07a00000 --kernel_offset 0x00080000 --ramdisk_offset 0x07c00000  --output boot.img
		cp boot.img $DIR/boot.img
	fi
	;;
* )
	cp $OUT/$BOOT/zImage $DIR/
	cat $OUT/$BOOT/zImage $OUT/$BOOT/dts/${DTB} > $DIR/zImage_dtb
	;;
esac

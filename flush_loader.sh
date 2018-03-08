#!/bin/sh
#USB=/dev/ttyUSB0
USB=/dev/ttyUSB1
BL2_EL3=1

case "$1" in
"hikey")
	echo "Download recovery images into HiKey platform"
	if [ $BL2_EL3 ]; then
		echo "Flush recovery.bin into eMMC"
		sudo python hisi-idt.py -d $USB --img1 recovery.bin
		sudo fastboot flash loader l-loader.bin
	else
		echo "Flush l-loader.bin into eMMC"
		sudo python hisi-idt.py -d $USB --img1 l-loader.bin
	fi
	sudo fastboot flash fastboot fip.bin
	;;
"hikey960")
	echo "Download recovery images into HiKey960 platform"
	if [ $BL2_EL3 ]; then
		echo "Flush recovery.bin into UFS"
		sed -i '3s/l-loader.bin/recovery.bin/g' config
	else
		echo "Flush l-loader.bin into UFS"
		sed -i '3s/recovery.bin/l-loader.bin/g' config
	fi
	sudo ./hikey_idt -c config -p $USB
	sudo fastboot flash fastboot l-loader.bin
	sudo fastboot flash fip fip.bin
	;;
esac

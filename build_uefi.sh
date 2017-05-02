#!/bin/sh
BUILD_OPTION=DEBUG
#BUILD_OPTION=RELEASE
GENERATE_PTABLE=1

case "$1" in
"hikey")
	PLATFORM=hikey
	;;
"hikey960")
	PLATFORM=hikey960
	;;
"")
	# If $1 is empty, set ${PLATFORM} as hikey960 by default.
	PLATFORM=hikey960
	;;
*)
	echo "Not supported platform:$1"
	exit
	;;
esac

if [ -d "${PWD}/edk2" ] && [ -d "${PWD}/uefi-tools" ] && [ -d "${PWD}/arm-trusted-firmware" ] && [ -d "${PWD}/l-loader" ]; then
	# Check whether source code are available in ${PWD}
	BUILD_PATH=${PWD}
	echo "Find source code in ${PWD}"
elif [ -d "${PWD}/../edk2" ] && [ -d "${PWD}/../uefi-tools" ] && [ -d "${PWD}/../arm-trusted-firmware" ] && [ -d "${PWD}/../l-loader" ]; then
	# Check whether source code are available in parent of ${PWD}
	BUILD_PATH=$(dirname ${PWD})
	echo "Find source code in parent directory of ${PWD}"
else
	echo "Warning: Can't find source code to build."
	exit
fi

# Setup environment variables that are used in uefi-tools
#export AARCH64_TOOLCHAIN=GCC49
export AARCH64_TOOLCHAIN=GCC48
export UEFI_TOOLS_DIR=${BUILD_PATH}/uefi-tools

EDK2_DIR=${BUILD_PATH}/edk2
echo "edk2 dir:${EDK2_DIR}"
export EDK2_DIR

case "$PLATFORM" in
"hikey")
	EDK2_OUTPUT_DIR=${EDK2_DIR}/Build/HiKey/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}
	# Since HiKey and HiKey960 isn't using the same ATF
	cd ${BUILD_PATH}
	rm -f arm-trusted-firmware
	ln -sf /opt/workspace/boot/uefi/upstream/test-atf arm-trusted-firmware
	;;
"hikey960")
	EDK2_OUTPUT_DIR=${EDK2_DIR}/Build/HiKey960/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}
	# Since HiKey and HiKey960 isn't using the same ATF
	cd ${BUILD_PATH}
	rm -f arm-trusted-firmware
	ln -sf atf960 arm-trusted-firmware
	;;
esac

# Fip.bin is produced in ${EDK2_OUTPUT_DIR}. And ${EDK2_OUTPUT_DIR} is local environment variable.
echo $EDK2_OUTPUT_DIR

# Always clean build EDK2
rm -f ${BUILD_PATH}/l-loader/l-loader.bin
rm -fr ${BUILD_PATH}/arm-trusted-firmware/build
rm -fr ${EDK2_DIR}/Build/
rm -f ${EDK2_OUTPUT_DIR}/FV/bl1.bin
rm -f ${EDK2_OUTPUT_DIR}/FV/fip.bin
rm -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd
sync

echo "Start to build ${PLATFORM} Bootloader..."

case "${BUILD_OPTION}" in
"DEBUG")
	echo "Debug build"
	;;
"RELEASE")
	echo "Release build"
	;;
* )
	echo "Invalid build mode"
	exit
	;;
esac

# Build UEFI & ARM Trusted Firmware
cd ${EDK2_DIR}
${UEFI_TOOLS_DIR}/uefi-build.sh -b $BUILD_OPTION -a ../arm-trusted-firmware $PLATFORM
if [ $? != 0 ]; then
	echo "Fail to build UEFI & ARM Trusted Firmware ($?)"
	exit
fi

# Locate output files of UEFI & Arm Trust Firmware
cd ${BUILD_PATH}/l-loader
ln -sf ${EDK2_OUTPUT_DIR}/FV/bl1.bin
ln -sf ${EDK2_OUTPUT_DIR}/FV/fip.bin
if [ -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd ]; then
	ln -sf ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd
fi

case "${PLATFORM}" in
"hikey")
	# Patch ARM64 mode by l-loader
	arm-linux-gnueabihf-gcc -c -o start.o start.S
	arm-linux-gnueabihf-ld -Bstatic -Tl-loader.lds -Ttext 0xf9800800 start.o -o loader
	arm-linux-gnueabihf-objcopy -O binary loader temp
	python gen_loader_hikey.py -o l-loader.bin --img_loader=temp --img_bl1=bl1.bin

	# Generate partition table
	if [ $GENERATE_PTABLE ]; then
		PTABLE=aosp-8g SECTOR_SIZE=512 bash -x generate_ptable.sh
		python gen_loader_hikey.py -o ptable.img --img_prm_ptable=prm_ptable.img
	fi

	;;
"hikey960")
	# Pack bl1.bin and BL33 together
	if [ -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd ]; then
		python gen_loader_hikey960.py -o l-loader.bin --img_bl1=bl1.bin --img_ns_bl1u=BL33_AP_UEFI.fd
	else
		python gen_loader_hikey960.py -o l-loader.bin --img_bl1=bl1.bin
	fi
	# Generate partition table
	if [ $GENERATE_PTABLE ]; then
		PTABLE=aosp-32g SECTOR_SIZE=4096 bash -x generate_ptable.sh
	fi
	;;
esac

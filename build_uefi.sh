#!/bin/sh
BUILD_OPTION=DEBUG
#BUILD_OPTION=RELEASE
#GENERATE_PTABLE=1
#BUILD_PATH=/opt/workspace/boot/uefi/upstream
BUILD_PATH=/opt/workspace/boot/uefi/hikey960
#ESTUARY=1
UPSTREAM=1
PREBUILT_FASTBOOT=1

# Check whether source code are available in ${PWD}
if [ -d "${PWD}/edk2" ] && [ -d "${PWD}/uefi-tools" ] && [ -d "${PWD}/arm-trusted-firmware" ] && [ -d "${PWD}/l-loader" ]; then
	BUILD_PATH=${PWD}
else
	echo "Warning: Can't find source code to build in ${PWD}. Use ${BUILD_PATH} instead."
fi

# Check whether source code are available in ${BUILD_PATH}
if [ ! -d "${BUILD_PATH}/edk2" ] || [ ! -d "${BUILD_PATH}/uefi-tools" ] || [ ! -d "${BUILD_PATH}/arm-trusted-firmware" ] || [ ! -d "${BUILD_PATH}/l-loader" ]; then
	echo "Error: Can't find source code to build in ${BUILD_PATH}."
	exit
fi

# Setup environment variables that are used in uefi-tools
#export AARCH64_TOOLCHAIN=GCC49
export AARCH64_TOOLCHAIN=GCC48
export UEFI_TOOLS_DIR=${BUILD_PATH}/uefi-tools

EDK2_DIR=${BUILD_PATH}/edk2
echo "edk2 dir:${EDK2_DIR}"
export EDK2_DIR

# Fip.bin is produced in ${EDK2_OUTPUT_DIR}. And ${EDK2_OUTPUT_DIR} is local environment variable.
EDK2_OUTPUT_DIR=${EDK2_DIR}/Build/HiKey960/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}
echo $EDK2_OUTPUT_DIR

# Always clean build EDK2
rm -f ${BUILD_PATH}/l-loader/l-loader.bin
#rm -fr ${EDK2_DIR}/Build/HiKey

echo "Start to build HiKey960 Bootloader..."

case "$BUILD_OPTION" in
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

# Build Android Fastboot
cd ${EDK2_DIR}
#if [ ${PREBUILT_FASTBOOT} ]; then
	# Build Android Fastboot
	#${UEFI_TOOLS_DIR}/uefi-build.sh -b $BUILD_OPTION aarch64-fastboot
	#cp Build/AndroidFastboot/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}/AARCH64/AndroidFastbootApp.efi AndroidFastbootBinPkg/AArch64/
#fi
# Build UEFI & ARM Trust Firmware
${UEFI_TOOLS_DIR}/uefi-build.sh -b $BUILD_OPTION -a ../arm-trusted-firmware hikey960

# Locate output files of UEFI & Arm Trust Firmware
cd ${BUILD_PATH}/l-loader
ln -sf ${EDK2_OUTPUT_DIR}/FV/bl1.bin
ln -sf ${EDK2_OUTPUT_DIR}/FV/fip.bin
if [ -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd ]; then
	ln -sf ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd
fi

# Pack bl1.bin and BL33 together
if [ -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd ]; then
	python gen_loader.py -o l-loader.bin --img_bl1=bl1.bin --img_ns_bl1u=BL33_AP_UEFI.fd
else
	python gen_loader.py -o l-loader.bin --img_bl1=bl1.bin
fi

# Generate partition table
#if [ $GENERATE_PTABLE ]; then
	# XXX sgdisk usage requires sudo
	#sudo PTABLE=linux-4g bash -x generate_ptable.sh
#fi

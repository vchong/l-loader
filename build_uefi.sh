#!/usr/bin/env bash

#
# Usage: bash build_uefi.sh {platform}
#

# Execute bash shell if use other shell
if [ -z "$BASH_VERSION" ]
then
	exec bash "$0" "$@"
fi

: ${BUILD_OPTION:=DEBUG}
#BUILD_OPTION=RELEASE
AARCH64_GCC=LINARO_GCC_7_2    # Prefer to use Linaro GCC >= 7.1.1. Otherwise, user may meet some toolchain issues.
#AARCH64_GCC=ANDROID_GCC_4_9
#CLANG=CLANG_5_0               # Prefer to use CLANG >= 3.9. Since LLVMgold.so is missing in CLANG 3.8.
GENERATE_PTABLE=1
#EDK2_PLATFORM=1
: ${OPTEE:=1}
#TBB=1                         # Trusted Board Boot
: ${CLEAN:=1}

# l-loader on hikey and optee need AARCH32_GCC
#AARCH32_GCC=/opt/toolchain/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf/bin/
AARCH32_GCC=/home/victor.chong/work/swg/build/toolchains83/aarch32/bin/
PATH=${AARCH32_GCC}:${PATH} && export PATH

# Setup environment variables that are used in uefi-tools
case "${AARCH64_GCC}" in
"ANDROID_GCC_4_9")
	AARCH64_GCC_4_9=/opt/toolchain/aarch64-linux-android-4.9.git/bin/
	#AARCH64_GCC_4_9=/home/victor.chong/work/swg/aosp/master/prebuilts/clang/host/linux-x86/clang-r370808/bin/
	PATH=${AARCH64_GCC_4_9}:${PATH} && export PATH
	echo "which clang = $(which clang)"
	export AARCH64_TOOLCHAIN=GCC49
	CROSS_COMPILE=aarch64-linux-android-
	;;
"LINARO_GCC_7_1")
	AARCH64_GCC_7_1=/opt/toolchain/gcc-linaro-7.1.1-2017.08-x86_64_aarch64-linux-gnu/bin/
	PATH=${AARCH64_GCC_7_1}:${PATH} && export PATH
	export AARCH64_TOOLCHAIN=GCC5
	CROSS_COMPILE=aarch64-linux-gnu-
	;;
"LINARO_GCC_7_2")
	AARCH64_GCC_7_2=/opt/toolchain/gcc-linaro-7.2.1-2017.11-x86_64_aarch64-linux-gnu/bin/
	#AARCH64_GCC_7_2=/home/victor.chong/work/swg/build/toolchains83/aarch64/bin/
	PATH=${AARCH64_GCC_7_2}:${PATH} && export PATH
	export AARCH64_TOOLCHAIN=GCC5
	CROSS_COMPILE=aarch64-linux-gnu-
	;;
*)
	echo "Not supported toolchain:${AARCH64_GCC}"
	exit
	;;
esac

case "${CLANG}" in
"CLANG_3_9")
	export AARCH64_TOOLCHAIN=CLANG38
	TC_FLAGS="CC=clang"
	;;
"CLANG_5_0")
	export AARCH64_TOOLCHAIN=CLANG38
	TC_FLAGS="CC=clang"
	;;
"")
	# CLANG is not used.
	export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
	TC_FLAGS=""
	;;
*)
	echo "Not supported CLANG:${CLANG}"
	exit
	;;
esac

if [ $CLANG ]; then
	case "${CLANG_PATH}" in
	"")
		echo "Please export CLANG_PATH=/path/to/clang/"
		echo "Please NOTE the trailing forward slash!"
		exit
		;;
	*)
		PATH=${CLANG_PATH}:${PATH} && export PATH
		type clang || { echo >&2 "Cannot find clang in ${CLANG_PATH}"; exit ; }
		clang --version
		;;
	esac
fi

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

if [ -d "${PWD}/edk2" ] && [ -d "${PWD}/trusted-firmware-a" ] && [ -d "${PWD}/l-loader" ]; then
	# Check whether source code are available in ${PWD}
	if [ ${TBB} ]; then
		if [ ! -d "${PWD}/mbedtls" ]; then
			echo "Warning: Can't find mbedtls source code to build."
			exit
		fi
	fi
	BUILD_PATH=${PWD}
	echo "Find source code in ${PWD}"
elif [ -d "${PWD}/../edk2" ] && [ -d "${PWD}/../trusted-firmware-a" ] && [ -d "${PWD}/../l-loader" ]; then
	# Check whether source code are available in parent of ${PWD}
	if [ ${TBB} ]; then
		if [ ! -d "${PWD}/../mbedtls" ]; then
			echo "Warning: Can't find mbedtls source code to build."
			exit
		fi
	fi
	BUILD_PATH=$(dirname ${PWD})
	echo "Find source code in parent directory of ${PWD}"
else
	echo "Warning: Can't find source code to build."
	exit
fi

EDK2_DIR=${BUILD_PATH}/edk2
echo "edk2 dir:${EDK2_DIR}"
export EDK2_DIR

case "$PLATFORM" in
"hikey")
	# Check whether fastboot source code is available in ${BUILD_PATH}
	if [ ! -d "${BUILD_PATH}/atf-fastboot" ]; then
		echo "Warning: Can't find fastboot source code to build"
		exit
	fi
	EDK2_OUTPUT_DIR=${BUILD_PATH}/Build/HiKey/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}
	;;
"hikey960")
	EDK2_OUTPUT_DIR=${BUILD_PATH}/Build/HiKey960/${BUILD_OPTION}_${AARCH64_TOOLCHAIN}
	;;
esac

# Clean build EDK2
if [ "$CLEAN" -ge "1" ]; then
	unlink ${BUILD_PATH}/l-loader/fip.bin
	rm -f ${BUILD_PATH}/l-loader/l-loader.bin
	rm -fr ${BUILD_PATH}/trusted-firmware-a/build
	rm -fr ${BUILD_PATH}/atf-fastboot/build
	cd ${EDK2_DIR}/BaseTools
	make clean
	rm -fr ${BUILD_PATH}/Build/
	rm -fr ${EDK2_DIR}/Build/
	rm -f ${EDK2_DIR}/Conf/.cache
	rm -f ${EDK2_DIR}/Conf/build_rule.txt
	rm -f ${EDK2_DIR}/Conf/target.txt
	rm -f ${EDK2_DIR}/Conf/tools_def.txt
	rm -f ${EDK2_OUTPUT_DIR}/FV/bl1.bin
	rm -f ${EDK2_OUTPUT_DIR}/FV/fip.bin
	rm -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd
	if [ X"$OPTEE" = X"1" ]; then
		rm -fr ${BUILD_PATH}/optee_os/out
	fi
	if [ "$CLEAN" -gt "1" ]; then
		exit
	fi
else
	echo "Skip cleaning builds"
fi
sync

echo "Start to build ${PLATFORM} Bootloader..."

case "${BUILD_OPTION}" in
"DEBUG")
	echo "Debug build"
	BUILD_DEBUG=1
	;;
"RELEASE")
	echo "Release build"
	BUILD_DEBUG=0
	;;
* )
	echo "Invalid build mode"
	exit
	;;
esac

# Build fastboot for HiKey
case "${PLATFORM}" in
"hikey")
	cd ${BUILD_PATH}/atf-fastboot
	CROSS_COMPILE=aarch64-linux-gnu- make ${TC_FLAGS} PLAT=${PLATFORM} DEBUG=${BUILD_DEBUG}
	if [ $? != 0 ]; then
		echo "Fail to build fastboot ($?)"
		exit
	fi
	# Convert "DEBUG"/"RELEASE" to "debug"/"release"
	if [ -f ${BUILD_PATH}/atf-fastboot/build/${PLATFORM}/$(echo ${BUILD_OPTION,,})/bl1.bin ]; then
		cd ${BUILD_PATH}/l-loader
		ln -sf ${BUILD_PATH}/atf-fastboot/build/${PLATFORM}/$(echo ${BUILD_OPTION,,})/bl1.bin fastboot.bin
	else
		echo "ERROR: Can't find fastboot binary"
		exit
	fi
	;;
esac

function do_symlink()
{
	# Locate output files of UEFI & Arm Trust Firmware
	cd ${BUILD_PATH}/l-loader
	ln -sf ../trusted-firmware-a/build/${PLATFORM}/$(echo ${BUILD_OPTION,,})/bl1.bin
	ln -sf ../trusted-firmware-a/build/${PLATFORM}/$(echo ${BUILD_OPTION,,})/bl2.bin
	ln -sf ../trusted-firmware-a/build/${PLATFORM}/$(echo ${BUILD_OPTION,,})/fip.bin
	if [ -f ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd ]; then
		ln -sf ${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd
	fi
}

function do_build()
{
	# unset ARCH environment variable to avoid confusion for UEFI building
	unset ARCH

	# Build edk2
	cd ${BUILD_PATH}
	export WORKSPACE=${BUILD_PATH}
	if [ $EDK2_PLATFORM ]; then
		export PACKAGES_PATH=${WORKSPACE}/edk2:${WORKSPACE}/edk2-platforms:${WORKSPACE}/edk2-non-osi
		case "${PLATFORM}" in
		"hikey")
			DSC=Platform/Hisilicon/HiKey/HiKey.dsc
			SCP_BL2=${BUILD_PATH}/edk2-non-osi/Platform/Hisilicon/HiKey/mcuimage.bin
			;;
		"hikey960")
			DSC=Platform/Hisilicon/HiKey960/HiKey960.dsc
			SCP_BL2=${BUILD_PATH}/edk2-non-osi/Platform/Hisilicon/HiKey960/lpm3.img
			;;
		esac
	else
		if [ -f "${EDK2_DIR}/OpenPlatformPkg" ]; then
			unlink ${EDK2_DIR}/OpenPlatformPkg
		fi
		ln -sf ${BUILD_PATH}/OpenPlatformPkg ${EDK2_DIR}/
		export PACKAGES_PATH=${WORKSPACE}/edk2
		case "${PLATFORM}" in
		"hikey")
			DSC=OpenPlatformPkg/Platforms/Hisilicon/HiKey/HiKey.dsc
			SCP_BL2=${BUILD_PATH}/edk2/OpenPlatformPkg/Platforms/Hisilicon/HiKey/Binary/mcuimage.bin
			;;
		"hikey960")
			DSC=OpenPlatformPkg/Platforms/Hisilicon/HiKey960/HiKey960.dsc
			SCP_BL2=${BUILD_PATH}/edk2/OpenPlatformPkg/Platforms/Hisilicon/HiKey960/Binary/lpm3.img
			;;
		esac
	fi
	source edk2/edksetup.sh
	make -C edk2/BaseTools
	if [ $? != 0 ]; then
		echo "Fail to build EDKII BaseTools ($?)"
		exit
	fi
	build -a AARCH64 -t ${AARCH64_TOOLCHAIN} -p ${DSC} -b ${BUILD_OPTION}
	if [ $? != 0 ]; then
		echo "Fail to build EDKII ($?)"
		exit
	fi
	# Build OPTEE
	if [ X"$OPTEE" = X"1" ]; then
		cd ${BUILD_PATH}/optee_os
		if [ $CLANG ]; then
			OPTEE_OS_COMPILERS="CROSS_COMPILE64=aarch64-linux-android- CROSS_COMPILE32=arm-linux-androideabi- COMPILER=clang"
		else
			OPTEE_OS_COMPILERS="CROSS_COMPILE32=arm-linux-gnueabihf- CROSS_COMPILE64=aarch64-linux-gnu-"
		fi
		if [ X"${BUILD_DEBUG}" = X"1" ]; then
			OPTEE_OS_LOGLVL="CFG_TEE_CORE_LOG_LEVEL=3 CFG_TEE_TA_LOG_LEVEL=3"
		fi
		PATH=${AARCH64_GCC}:${PATH} make ${OPTEE_OS_COMPILERS} PLATFORM=hikey-${PLATFORM} CFG_ARM64_core=y DEBUG=${BUILD_DEBUG} ${OPTEE_OS_LOGLVL}
		if [ $? != 0 ]; then
			echo "Fail to build OPTEE ($?)"
			exit
		fi
	fi
	# Build ARM Trusted Firmware
	cd ${BUILD_PATH}/trusted-firmware-a
	BL33=${EDK2_OUTPUT_DIR}/FV/BL33_AP_UEFI.fd
	if [ X"$OPTEE" = X"1" ]; then
		BL32=../optee_os/out/arm-plat-hikey/core/tee-header_v2.bin
		BL32_EXTRA1=../optee_os/out/arm-plat-hikey/core/tee-pager_v2.bin
		BL32_EXTRA2=../optee_os/out/arm-plat-hikey/core/tee-pageable_v2.bin
		TEE_ARGS="SPD=opteed BL32=${BL32} BL32_EXTRA1=${BL32_EXTRA1} BL32_EXTRA2=${BL32_EXTRA2}"
	else
		TEE_ARGS=""
	fi
	if [ $TBB ]; then
		TBB_ARGS="TRUSTED_BOARD_BOOT=1 MBEDTLS_DIR=${BUILD_PATH}/mbedtls GENERATE_COT=1"
	else
		TBB_ARGS=""
	fi
	CROSS_COMPILE=aarch64-linux-gnu- make ${TC_FLAGS} PLAT=${PLATFORM} SCP_BL2=${SCP_BL2} ${TEE_ARGS} ${TBB_ARGS} BL33=${BL33} DEBUG=${BUILD_DEBUG} all fip
	if [ $? != 0 ]; then
		echo "Fail to build ARM Trusted Firmware ($?)"
		exit
	fi
}

# Build UEFI & ARM Trusted Firmware
do_build

do_symlink

case "${PLATFORM}" in
"hikey")
	# Patch aarch64 mode on bl1.bin. Then bind it with fastboot.
	make ${TC_FLAGS} -f ${PLATFORM}.mk recovery.bin
	# Patch aarch64 mode on bl2.bin
	make ${TC_FLAGS} -f ${PLATFORM}.mk l-loader.bin

	# Generate partition table
	if [ $GENERATE_PTABLE ]; then
		PTABLE=aosp-4g SECTOR_SIZE=512 bash -x generate_ptable.sh
		PTABLE=aosp-8g SECTOR_SIZE=512 bash -x generate_ptable.sh
	fi

	;;
"hikey960")
	# Bind bl1.bin with BL33
	make -f ${PLATFORM}.mk recovery.bin
	# Use bl2.bin as l-loader
	make -f ${PLATFORM}.mk l-loader.bin

	# Generate partition table with a patched sgdisk to force
	# default alignment (2048) and sector size (4096)
	if [ $GENERATE_PTABLE ]; then
		PTABLE=aosp-32g SECTOR_SIZE=4096 SGDISK=./sgdisk bash -x generate_ptable.sh
	fi
	;;
esac

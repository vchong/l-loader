#!/bin/sh
# Generate partition table for HiKey eMMC
#
# tiny: for testing purpose.
# aosp: 10 entries (same as linux with userdata).
# linux: 9 entries (same as aosp without userdata).

PTABLE=${PTABLE:-aosp}
SECTOR_SIZE=4096
TEMP_FILE=$(mktemp /tmp/${PTABLE}.XXXXXX)
# 128 entries at most
ENTRIES_IN_SECTOR=$(expr ${SECTOR_SIZE} / 128)
ENTRY_SECTORS=$(expr 128 / ${ENTRIES_IN_SECTOR})
PRIMARY_SECTORS=$(expr ${ENTRY_SECTORS} + 2)
SECONDARY_SECTORS=$(expr ${ENTRY_SECTORS} + 1)

case ${SECTOR_SIZE} in
  512)
    SGDISK=sgdisk
    ;;
  4096)
    TOOL_PATH=/opt/workspace/source_package/gdisk-1.0.1
    #SGDISK=${TOOL_PATH}/sgdisk
    SGDISK=./sgdisk
    ;;
esac

case ${PTABLE} in
  tiny)
    SECTOR_NUMBER=81920
    ;;
  aosp-4g|linux-4g)
    SECTOR_NUMBER=1048576
    ;;
  aosp-8g|linux-8g)
    SECTOR_NUMBER=2097152
    ;;
  aosp-16g|linux-16g)
    SECTOR_NUMBER=4194304
    ;;
  aosp-32g|linux-32g)
    SECTOR_NUMBER=7805952
    ;;
  aosp-64g|linux-64g)
    SECTOR_NUMBER=15616000
    ;;
esac

# get the partition table
case ${PTABLE} in
  tiny)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    fakeroot ${SGDISK} -U -R -v ${TEMP_FILE}
    fakeroot ${SGDISK} -n 1:2048:4095 -t 1:0700 -u 1:F9F21F01-A8D4-5F0E-9746-594869AEC3E4 -c 1:"vrl" -p ${TEMP_FILE}
    fakeroot ${SGDISK} -n 2:4096:6143 -t 2:0700 -u 2:F9F21F02-A8D4-5F04-9746-594869AEC3E4 -c 2:"vrl_backup" -p ${TEMP_FILE}
    ;;
  aosp-32g|aosp-64g)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    fakeroot sgdisk -U 2CB85345-6A91-4043-8203-723F0D28FBE8 -v ${TEMP_FILE}
    # Hisilicon creates 2 xloader partitions which are 512KB size. All partitions should be aligned at least 1MB with sgdisk.
    # So dicard one xloader partition in this tool.
    #[1: xloader: 1M-2M]
    fakeroot ${SGDISK} -n 1:0:+1M -t 1:0700 -u 1:697c41e0-7a59-4dfa-a9a6-aa43ac5be684 -c 1:"xloader" ${TEMP_FILE}
    #[2: fastboot: 2M-14M]
    fakeroot ${SGDISK} -n 2:0:+12M -t 2:0700 -u 2:3f5f8c48-4402-4ace-9058-30bfea4fa53f -c 2:"fastboot" ${TEMP_FILE}
    #[3: fip: 14M-26M]
    fakeroot ${SGDISK} -n 3:0:+12M -t 3:0700 -u 3:dc1a888e-f17c-4964-92d6-f8fcc402ed8b -c 3:"fip" ${TEMP_FILE}
    #[4: nvme: 26M-32M]
    fakeroot ${SGDISK} -n 4:0:+6M -t 4:0700 -u 4:4c7a5919-d512-4d2e-bdd5-1ceb799a1c7e -c 4:"nvme" ${TEMP_FILE}
    #[5: dts: 32M-64M]
    fakeroot ${SGDISK} -n 5:0:+32M -t 5:0700 -u 5:6e53b0bb-fa7e-4206-b607-5ae699e9f066 -c 5:"dts" ${TEMP_FILE}
    #[6: boot: 64M-128M]
    fakeroot ${SGDISK} -n 6:0:+64M -t 6:EF00 -u 6:d3340696-9b95-4c64-8df6-e6d4548fba41 -c 6:"boot" ${TEMP_FILE}
    #[7: reserved: 128M-512M]
    fakeroot ${SGDISK} -n 7:0:+384M -t 7:0700 -u 7:611eac6b-bc42-4d72-90ac-418569c8e9b8 -c 7:"reserved" ${TEMP_FILE}
    #[8: cache: 512M-768M]
    fakeroot ${SGDISK} -n 8:0:+256M -t 8:0700 -u 8:10cc3268-05f0-4db2-aa00-707361427fc8 -c 8:"cache" ${TEMP_FILE}
    #[9: mcuimage: 768M-776M]
    fakeroot ${SGDISK} -n 9:0:+8M -t 9:0700 -u 9:5d8481d4-c170-4aa8-9438-8743c73ea8f5 -c 9:"mcuimage" ${TEMP_FILE}
    #[10: system: 776M-5464M]
    fakeroot ${SGDISK} -n 10:0:+4688M -t 10:8300 -u 10:c3e50923-fb85-4153-b925-759614d4dfcd -c 10:"system" ${TEMP_FILE}
    #[11: vendor: 5464M-6248M]
    fakeroot ${SGDISK} -n 11:0:+784M -t 11:0700 -u 11:919d7080-d71a-4ae1-9227-e4585210c837 -c 11:"vendor" ${TEMP_FILE}
    #[12: userdata: 6248M-End]
    fakeroot ${SGDISK} -n -E -t 12:8300 -u 12:049b9a32-a36a-483e-ab6f-9ef6644e6d47 -c 12:"userdata" ${TEMP_FILE}
    ;;
  linux*)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    fakeroot ${SGDISK} -U 2CB85345-6A91-4043-8203-723F0D28FBE8 -v ${TEMP_FILE}
    #[1: fastboot: 8M-12M]
    fakeroot ${SGDISK} -n 1:0:+4M -t 1:0700 -u 1:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 1:"fastboot" ${TEMP_FILE}
    #[2: fip: 12M-20M]
    fakeroot ${SGDISK} -n 2:0:+8M -t 2:EF02 -u 2:b28add62-da27-4dd2-8dea-e3628a513929 -c 2:"fip" ${TEMP_FILE}
    #[3: dtb: 20M-36M]
    fakeroot ${SGDISK} -n 3:0:+16M -t 3:0700 -u 3:61A36FC1-8EFB-4899-84D8-B61642EFA723 -c 3:"dtb" ${TEMP_FILE}
    #[4: nvme: 36M-38M]
    fakeroot ${SGDISK} -n 4:0:+2M -t 4:0700 -u 4:00354BCD-BBCB-4CB3-B5AE-CDEFCB5DAC43 -c 4:"nvme" ${TEMP_FILE}
    #[5: optee: 38M-102M]
    fakeroot ${SGDISK} -n 5:0:+64M -t 5:0700 -u 5:61b94129-c1f2-4601-99ea-a1f518e1b082 -c 5:"optee" ${TEMP_FILE}
    #[6: cache: 102M-358M]
    fakeroot ${SGDISK} -n 6:0:+256M -t 6:8301 -u 6:A092C620-D178-4CA7-B540-C4E26BD6D2E2 -c 6:"cache" ${TEMP_FILE}
    #[7: boot: 358M-422M]
    fakeroot ${SGDISK} -n 7:0:+64M -t 7:EF00 -u 7:5C0F213C-17E1-4149-88C8-8B50FB4EC70E -c 7:"boot" ${TEMP_FILE}
    #[8: reserved: 422M-678M]
    fakeroot ${SGDISK} -n 8:0:+256M -t 8:0700 -u 8:BED8EBDC-298E-4A7A-B1F1-2500D98453B7 -c 8:"reserved" ${TEMP_FILE}
    #[9: system: 678M-End]
    fakeroot ${SGDISK} -n -E -t 9:8300 -u 9:FC56E345-2E8E-49AE-B2F8-5B9D263FE377 -c 9:"system" ${TEMP_FILE}
    ;;
esac

# get the primary partition table
dd if=${TEMP_FILE} of=prm_ptable.img bs=${SECTOR_SIZE} count=${PRIMARY_SECTORS}

BK_PTABLE_LBA=$(expr ${SECTOR_NUMBER} - ${SECONDARY_SECTORS})
dd if=${TEMP_FILE} of=sec_ptable.img skip=${BK_PTABLE_LBA} bs=${SECTOR_SIZE} count=${SECONDARY_SECTORS}

rm -f ${TEMP_FILE}

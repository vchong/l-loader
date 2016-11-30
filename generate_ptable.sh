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
  aosp-64g|linux-64g)
    SECTOR_NUMBER=15616000
    ;;
esac

# get the partition table
case ${PTABLE} in
  tiny)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    fakeroot sgdisk -U -R -v ${TEMP_FILE}
    fakeroot sgdisk -n 1:2048:4095 -t 1:0700 -u 1:F9F21F01-A8D4-5F0E-9746-594869AEC3E4 -c 1:"vrl" -p ${TEMP_FILE}
    fakeroot sgdisk -n 2:4096:6143 -t 2:0700 -u 2:F9F21F02-A8D4-5F04-9746-594869AEC3E4 -c 2:"vrl_backup" -p ${TEMP_FILE}
    ;;
  aosp*)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    fakeroot sgdisk -U 2CB85345-6A91-4043-8203-723F0D28FBE8 -v ${TEMP_FILE}
    #[1: fastboot: 8M-12M]
    fakeroot sgdisk -n 1:0:+4M -t 1:0700 -u 1:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 1:"fastboot" ${TEMP_FILE}
    #[2: fip: 12M-20M]
    fakeroot sgdisk -n 2:0:+8M -t 2:EF02 -u 2:b28add62-da27-4dd2-8dea-e3628a513929 -c 2:"fip" ${TEMP_FILE}
    #[3: dtb: 20M-36M]
    fakeroot sgdisk -n 3:0:+16M -t 3:0700 -u 3:61A36FC1-8EFB-4899-84D8-B61642EFA723 -c 3:"dtb" ${TEMP_FILE}
    #[4: nvme: 36M-38M]
    fakeroot sgdisk -n 4:0:+2M -t 4:0700 -u 4:00354BCD-BBCB-4CB3-B5AE-CDEFCB5DAC43 -c 4:"nvme" ${TEMP_FILE}
    #[5: optee: 38M-102M]
    fakeroot sgdisk -n 5:0:+64M -t 5:0700 -u 5:61b94129-c1f2-4601-99ea-a1f518e1b082 -c 5:"optee" ${TEMP_FILE}
    #[6: cache: 102M-358M]
    fakeroot sgdisk -n 6:0:+256M -t 6:8301 -u 6:A092C620-D178-4CA7-B540-C4E26BD6D2E2 -c 6:"cache" ${TEMP_FILE}
    #[7: boot: 358M-422M]
    fakeroot sgdisk -n 7:0:+64M -t 7:EF00 -u 7:5C0F213C-17E1-4149-88C8-8B50FB4EC70E -c 7:"boot" ${TEMP_FILE}
    #[8: reserved: 422M-678M]
    fakeroot sgdisk -n 8:0:+256M -t 8:0700 -u 8:BED8EBDC-298E-4A7A-B1F1-2500D98453B7 -c 8:"reserved" ${TEMP_FILE}
    #[9: system: 678M-2726M]
    fakeroot sgdisk -n 9:0:+2048M -t 9:8300 -u 9:FC56E345-2E8E-49AE-B2F8-5B9D263FE377 -c 9:"system" ${TEMP_FILE}
    #[10: userdata: 2726M-End]
    fakeroot sgdisk -n -E -t 10:8300 -u 10:064111F6-463B-4CE1-876B-13F3684CE164 -c 10:"userdata" -p ${TEMP_FILE}
    ;;
  linux*)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    fakeroot sgdisk -U 2CB85345-6A91-4043-8203-723F0D28FBE8 -v ${TEMP_FILE}
    #[1: fastboot: 8M-12M]
    fakeroot sgdisk -n 1:0:+4M -t 1:0700 -u 1:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 1:"fastboot" ${TEMP_FILE}
    #[2: fip: 12M-20M]
    fakeroot sgdisk -n 2:0:+8M -t 2:EF02 -u 2:b28add62-da27-4dd2-8dea-e3628a513929 -c 2:"fip" ${TEMP_FILE}
    #[3: dtb: 20M-36M]
    fakeroot sgdisk -n 3:0:+16M -t 3:0700 -u 3:61A36FC1-8EFB-4899-84D8-B61642EFA723 -c 3:"dtb" ${TEMP_FILE}
    #[4: nvme: 36M-38M]
    fakeroot sgdisk -n 4:0:+2M -t 4:0700 -u 4:00354BCD-BBCB-4CB3-B5AE-CDEFCB5DAC43 -c 4:"nvme" ${TEMP_FILE}
    #[5: optee: 38M-102M]
    fakeroot sgdisk -n 5:0:+64M -t 5:0700 -u 5:61b94129-c1f2-4601-99ea-a1f518e1b082 -c 5:"optee" ${TEMP_FILE}
    #[6: cache: 102M-358M]
    fakeroot sgdisk -n 6:0:+256M -t 6:8301 -u 6:A092C620-D178-4CA7-B540-C4E26BD6D2E2 -c 6:"cache" ${TEMP_FILE}
    #[7: boot: 358M-422M]
    fakeroot sgdisk -n 7:0:+64M -t 7:EF00 -u 7:5C0F213C-17E1-4149-88C8-8B50FB4EC70E -c 7:"boot" ${TEMP_FILE}
    #[8: reserved: 422M-678M]
    fakeroot sgdisk -n 8:0:+256M -t 8:0700 -u 8:BED8EBDC-298E-4A7A-B1F1-2500D98453B7 -c 8:"reserved" ${TEMP_FILE}
    #[9: system: 678M-End]
    fakeroot sgdisk -n -E -t 9:8300 -u 9:FC56E345-2E8E-49AE-B2F8-5B9D263FE377 -c 9:"system" ${TEMP_FILE}
    ;;
esac

# get the primary partition table
dd if=${TEMP_FILE} of=prm_ptable.img bs=512 count=34

rm -f ${TEMP_FILE}

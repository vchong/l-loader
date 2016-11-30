#!/bin/sh
# Generate partition table for HiKey eMMC
#
# tiny: for testing purpose.
# aosp: 11 entries (same as linux with userdata).
# linux: 10 entries (same as aosp without userdata).

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

#BK_PTABLE_LBA=$(expr ${SECTOR_NUMBER} - 33)
#echo ${BK_PTABLE_LBA}

# get the partition table
case ${PTABLE} in
  tiny)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    sgdisk -U -R -v ${TEMP_FILE}
    sgdisk -n 1:2048:4095 -t 1:0700 -u 1:F9F21F01-A8D4-5F0E-9746-594869AEC3E4 -c 1:"vrl" -p ${TEMP_FILE}
    sgdisk -n 2:4096:6143 -t 2:0700 -u 2:F9F21F02-A8D4-5F04-9746-594869AEC3E4 -c 2:"vrl_backup" -p ${TEMP_FILE}
    ;;
  aosp*)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    sgdisk -U 2CB85345-6A91-4043-8203-723F0D28FBE8 -v ${TEMP_FILE}
    #[1: vrl: 8M-9M]
    sgdisk -n 1:0:+1M -t 1:0700 -u 1:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 1:"vrl" ${TEMP_FILE}
    #[2: vrl_backup: 9M-10M]
    sgdisk -n 2:0:+1M -t 2:0700 -u 2:61A36FC1-8EFB-4899-84D8-B61642EFA723 -c 2:"vrl_backup" ${TEMP_FILE}
    #[3: fastboot: 10M-24M]
    sgdisk -n 3:0:+12M -t 3:0700 -u 3:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 3:"fastboot" ${TEMP_FILE}
    #[4: fip: 24M-36M]
    sgdisk -n 4:0:+12M -t 4:EF02 -u 4:b28add62-da27-4dd2-8dea-e3628a513929 -c 4:"fip" ${TEMP_FILE}
    #[5: nvme: 36M-38M]
    sgdisk -n 5:0:+2M -t 5:0700 -u 5:00354BCD-BBCB-4CB3-B5AE-CDEFCB5DAC43 -c 5:"nvme" ${TEMP_FILE}
    #[6: optee: 38M-102M]
    sgdisk -n 6:0:+64M -t 6:0700 -u 6:61b94129-c1f2-4601-99ea-a1f518e1b082 -c 6:"optee" ${TEMP_FILE}
    #[7: cache: 102M-358M]
    sgdisk -n 7:0:+256M -t 7:8301 -u 7:A092C620-D178-4CA7-B540-C4E26BD6D2E2 -c 7:"cache" ${TEMP_FILE}
    #[8: boot: 358M-422M]
    sgdisk -n 8:0:+64M -t 8:EF00 -u 8:5C0F213C-17E1-4149-88C8-8B50FB4EC70E -c 8:"boot" ${TEMP_FILE}
    #[9: reserved: 422M-678M]
    sgdisk -n 9:0:+256M -t 9:0700 -u 9:BED8EBDC-298E-4A7A-B1F1-2500D98453B7 -c 9:"reserved" ${TEMP_FILE}
    #[10: system: 678M-2726M]
    sgdisk -n 10:0:+2048M -t 10:8300 -u 10:FC56E345-2E8E-49AE-B2F8-5B9D263FE377 -c 10:"system" ${TEMP_FILE}
    #[11: userdata: 2726M-End]
    sgdisk -n -E -t 11:8300 -u 11:064111F6-463B-4CE1-876B-13F3684CE164 -c 11:"userdata" -p ${TEMP_FILE}
    ;;
  linux*)
    dd if=/dev/zero of=${TEMP_FILE} bs=${SECTOR_SIZE} count=${SECTOR_NUMBER} conv=sparse
    sgdisk -U 2CB85345-6A91-4043-8203-723F0D28FBE8 -v ${TEMP_FILE}
    #[1: vrl: 8M-9M]
    sgdisk -n 1:0:+1M -t 1:0700 -u 1:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 1:"vrl" ${TEMP_FILE}
    #[2: vrl_backup: 9M-10M]
    sgdisk -n 2:0:+1M -t 2:0700 -u 2:61A36FC1-8EFB-4899-84D8-B61642EFA723 -c 2:"vrl_backup" ${TEMP_FILE}
    #[3: fastboot: 10M-24M]
    sgdisk -n 3:0:+12M -t 3:0700 -u 3:496847AB-56A1-4CD5-A1AD-47F4ACF055C9 -c 3:"fastboot" ${TEMP_FILE}
    #[4: fip: 24M-36M]
    sgdisk -n 4:0:+12M -t 4:EF02 -u 4:b28add62-da27-4dd2-8dea-e3628a513929 -c 4:"fip" ${TEMP_FILE}
    #[5: nvme: 36M-38M]
    sgdisk -n 5:0:+2M -t 5:0700 -u 5:00354BCD-BBCB-4CB3-B5AE-CDEFCB5DAC43 -c 5:"nvme" ${TEMP_FILE}
    #[6: optee: 38M-102M]
    sgdisk -n 6:0:+64M -t 6:0700 -u 6:61b94129-c1f2-4601-99ea-a1f518e1b082 -c 6:"optee" ${TEMP_FILE}
    #[7: cache: 102M-358M]
    sgdisk -n 7:0:+256M -t 7:8301 -u 7:A092C620-D178-4CA7-B540-C4E26BD6D2E2 -c 7:"cache" ${TEMP_FILE}
    #[8: boot: 358M-422M]
    sgdisk -n 8:0:+64M -t 8:EF00 -u 8:5C0F213C-17E1-4149-88C8-8B50FB4EC70E -c 8:"boot" ${TEMP_FILE}
    #[9: reserved: 422M-678M]
    sgdisk -n 9:0:+256M -t 9:0700 -u 9:BED8EBDC-298E-4A7A-B1F1-2500D98453B7 -c 9:"reserved" ${TEMP_FILE}
    #[10: system: 678M-End]
    sgdisk -n -E -t 10:8300 -u 10:FC56E345-2E8E-49AE-B2F8-5B9D263FE377 -c 10:"system" ${TEMP_FILE}
    ;;
esac

# get the main and the backup parts of the partition table
dd if=${TEMP_FILE} of=prm_ptable.img bs=512 count=34
#dd if=${TEMP_FILE} of=sec_ptable.img skip=${BK_PTABLE_LBA} bs=512 count=33

rm -f ${TEMP_FILE}

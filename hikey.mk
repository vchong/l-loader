ifeq ($(notdir $(CC)), clang)
	CC=clang
	LD=ld.lld
	OBJCOPY=llvm-objcopy
	CFLAGS=-target arm-linux-gnueabihf
	OBJCOPY=llvm-objcopy
else
	CROSS_COMPILE=arm-linux-gnueabihf-
	CC=$(CROSS_COMPILE)gcc
	LD=$(CROSS_COMPILE)ld
	OBJCOPY=$(CROSS_COMPILE)objcopy
	CFLAGS=-mcpu=cortex-a53
	OBJCOPY=$(CROSS_COMPILE)objcopy
endif

BL1=bl1.bin
BL2=bl2.bin
NS_BL1U=fastboot.bin
PTABLE_LST?=linux-4g linux-8g aosp-4g aosp-8g

.PHONY: all
all: l-loader.bin prm_ptable.img recovery.bin

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

loader: start.o l-loader.lds
	$(LD) -Bstatic -Tl-loader.lds -Ttext 0xf9800800 start.o -o $@

temp: loader
	$(OBJCOPY) -O binary $< $@

l-loader.bin: temp $(BL2)
	python gen_loader_hikey.py -o $@ --img_loader=temp --img_bl1=$(BL2)

.PHONY: check_sgdisk
check_sgdisk:
	@which sgdisk || (echo "sgdisk NOT found. Please install it!"; exit 1)

prm_ptable.img: check_sgdisk
	for ptable in $(PTABLE_LST); do \
		PTABLE=$${ptable} SECTOR_SIZE=512 bash -x generate_ptable.sh;\
		cp prm_ptable.img ptable-$${ptable}.img;\
	done

recovery.bin: temp $(BL1) $(NS_BL1U)
	python gen_loader_hikey.py -o $@ --img_loader=temp --img_bl1=$(BL1) --img_ns_bl1u=$(NS_BL1U)

.PHONY: clean
clean:
	rm -f *.o l-loader.bin prm_ptable.img recovery.bin loader temp

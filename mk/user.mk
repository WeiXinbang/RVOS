# Standalone user program build rules.

USER_BUILD_DIR := $(BUILD_DIR)/user
USER_PROGRAMS  := hello once
USER_OBJS      := $(addprefix $(USER_BUILD_DIR)/,$(addsuffix .o,$(USER_PROGRAMS)))
USER_ELFS      := $(addprefix $(USER_BUILD_DIR)/,$(addsuffix .elf,$(USER_PROGRAMS)))
USER_INITRAMFS := $(USER_BUILD_DIR)/initramfs.img
USER_BLOB_S    := $(USER_BUILD_DIR)/initramfs_blob.S
USER_BLOB_O    := $(USER_BUILD_DIR)/initramfs_blob.o
USER_INITRAMFS_FILES := $(foreach prog,$(USER_PROGRAMS),--file /bin/$(prog)=$(USER_BUILD_DIR)/$(prog).elf)

USER_CFLAGS = \
	$(CC_TARGET_FLAGS) \
	-nostdlib \
	-ffreestanding \
	-fno-builtin \
	-fno-stack-protector \
	-march=$(RISCV_MARCH) \
	-mabi=$(RISCV_ABI) \
	-mcmodel=medany \
	-I include \
	-g

USER_LDFLAGS = \
	$(LD_TARGET_FLAGS) \
	-nostdlib \
	-march=$(RISCV_MARCH) \
	-mabi=$(RISCV_ABI) \
	-mcmodel=medany \
	-Wl,-T,user/user.lds \
	-Wl,--no-relax \
	-g

$(USER_BUILD_DIR)/%.o: user/%.S include/syscall_numbers.h
	@mkdir -p $(dir $@)
	$(CC) $(USER_CFLAGS) -c $< -o $@

$(USER_BUILD_DIR)/%.elf: $(USER_BUILD_DIR)/%.o user/user.lds
	@mkdir -p $(dir $@)
	$(CC) $(USER_LDFLAGS) $< -o $@

$(USER_INITRAMFS): $(USER_ELFS) scripts/build-initramfs.py
	@mkdir -p $(dir $@)
	python3 scripts/build-initramfs.py \
		--output $@ \
		$(USER_INITRAMFS_FILES)

$(USER_BLOB_S): $(USER_INITRAMFS) mk/user.mk
	@mkdir -p $(dir $@)
	@{ \
		printf '.section .initramfs, "a"\n'; \
		printf '.globl __initramfs_start\n'; \
		printf '.globl __initramfs_end\n'; \
		printf '.balign 8\n'; \
		printf '__initramfs_start:\n'; \
		printf '.incbin "$(USER_INITRAMFS)"\n'; \
		printf '__initramfs_end:\n'; \
	} > $@.tmp
	mv $@.tmp $@

$(USER_BLOB_O): $(USER_BLOB_S)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_BASE) $(INCLUDES) -MMD -MP -c $< -o $@

user-elf: $(USER_ELFS) $(USER_INITRAMFS)
	@echo "User ELFs generated: $(USER_ELFS)"
	@echo "Initramfs generated: $(USER_INITRAMFS)"

.PHONY: user-elf
.SECONDARY: $(USER_OBJS)

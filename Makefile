arch ?= x86_64
kernel := out/kernel-$(arch).bin
iso := out/os-$(arch).iso

linker_script := linker.ld
grub_cfg := src/resources/grub.cfg

assembly_source_files := $(wildcard src/asm/*.asm)
assembly_object_files := $(patsubst src/asm/%.asm, out/asm/%.o, $(assembly_source_files))

c_source_files := $(wildcard src/c/*.c)
c_object_files := $(patsubst src/c/%.c, out/c/%.o, $(c_source_files))

object_files := $(c_object_files) $(assembly_object_files)

.PHONY: all clean run iso

all: $(kernel)

clean:
	@rm -r out 

run: $(iso)
	@qemu-system-x86_64 -m 512 -serial file:serial.log -cdrom $(iso)

iso: $(iso)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p out/isofiles/boot/grub
	@cp $(kernel) out/isofiles/boot/kernel.bin
	@cp $(grub_cfg) out/isofiles/boot/grub
	@grub-mkrescue -o $(iso) out/isofiles 2> /dev/null
	@rm -r out/isofiles

$(kernel): $(object_files) $(linker_script)
	@ld -n -T $(linker_script) -o $(kernel) $(object_files)

# compile assembly files
out/asm/%.o: src/asm/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -f elf64 $< -o $@

out/c/%.o: src/c/%.c
	@mkdir -p $(shell dirname $@)
	@gcc -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -c $< -o $@
LDEMULATION := elf_x86_64
MAIN:
	mkdir -p isofiles/boot
	nasm -f elf64 boot.asm
	nasm -f elf64 multiboot_header.asm
	ld -n -o isofiles/boot/kernel.bin -T linker.ld multiboot_header.o boot.o
	grub-mkrescue -o os.iso isofiles

clean:
	rm isofiles/boot/kernel.bin
	rm *.o

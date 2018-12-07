PREFIX		= mipsel-unknown-elf-

AS			= $(PREFIX)as
LD			= $(PREFIX)ld

all: ../liteload.bin romstrap.o
	$(LD) --nmagic --oformat binary -T rom.ld romstrap.o -o rom.bin
	
romstrap.o: romstrap.s
	$(AS) $< -o $@
	
../liteload.bin: ../liteload.exe
	./exe2bin ../liteload.exe

clean:
	rm -f romstrap.o rom.bin
ASM			= armips

all: ../liteload.bin
	$(ASM) -sym liteload.sym romstrap.asm
	
../liteload.bin: ../liteload.exe
	./util/exe2bin ../liteload.exe

clean:
	rm -f romstrap.o rom.bin
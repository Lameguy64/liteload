The files contained within this directory are for creating a ROM bootable
version of LITELOAD which can be flashed to a cheat cartridge. The ROMstrap
code can be used to create ROM bootable versions of other programs.

Compiling the GNU assembler version of the source requires the GNU toolchain
targetting mipsel-unknown-elf which you can find pre compiled win32 binaries
of at www.psxdev.net. An SDevTC assembler compatible version is also included
albeit it is older than the GNU assembler version and doesn't boot as fast as
the GNU version.


To compile the GNU assembler version, simply run the makefile. Make sure a
path to the GNU toolchain is defined in your PATH environment variable.

To compile the SDevTC assembler version, simply run the following command
while inside the SDevTC directory:

asmpsx /p romstrap.asm,rom.bin

Both assume that you have LITELOAD already compiled and converted into a PS-EXE.


File listing:

makefile			Makefile to generate the ROM using GNU assembler.
roomstrap.s			GNU assembler of the PS-EXE ROMstrap code.
cop0.h				GNU assembler header of cop0 register definitions.
rom.ld				LD script to create the ROM file.

util/exe2bin.c		PS-EXE to binary file with reduced header converter.

sdevtc/romstrap.asm	SDevTC assembler version of the ROMstrap code (older).
sdevtc/cop0.inc		SDevTC assembler header of cop0 register definitions.
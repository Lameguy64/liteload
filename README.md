# LITELOAD
A very lightweight serial loader tool for the original Sony PlayStation. LITELOAD also improves upon most loaders by supporting uploading of binary files and CRC32 integrity verification to ensure that any bugs or crashes you experience in your project is not caused by corruption during upload.

Use [mcomms](https://github.com/Lameguy64/mcomms) to upload programs to the console.

## Features
* Supports executable size up to 1816KB (assuming EXE is loaded at 0x80010000).
* Supports uploading binary files to console memory (careful not to overwrite the loader).
* CRC32 verification to ensure data integrity.
* Open source!

## Compiling
This tool can only be compiled using the PlayStation PsyQ or Programmer's Tool SDK on Windows. Sorry PSXSDK users...

You will also need the following:
* msys or cygwin with make if you prefer the latter.
* mkpsxiso (get it [here](https://github.com/Lameguy64/mkpsxiso)).

1. Open up the command prompt.
2. Make sure that the SDK, msys and mkpsxiso binaries are in your PATH variable.
3. Run "make" to compile (don't use PSYMAKE).
4. Run "make iso" to build an ISO image.

## Upload protocol
In case you wanted to write your own loader tool, the following describes LITELOAD's communication protocol. It is designed to be as simple and efficient as possible for easy integration and provides the fastest upload rate possible on the already slow serial interface.

LITELOAD always communicates at 115200 baud, 8 data bits, 1 stop bit, no parity and no handshaking.

Legend:
	[S] - Send.
	[R] - Receive.
	[D] - Delay.

Uploading an executable:

	[S] char[4] - Send command: MEXE
	[R] char[1] - Acknowledge: K
	[S] int[16] - Executable parameters & checksum.
					First 15 ints are EXEC parameters (same format as EXEC in SDK).
					The 16th int is the CRC32 checksum.
	[S] int[1]	- Executable flags.
					bit 0: Set BPC on executable entrypoint.
					bit 1-31: reserved.
	[D] 20ms
	[S] *       - Executable data.
	
Uploading a binary file.

	[S] char[4] - Send command: MBIN
	[R] char[1] - Acknowledge: K
	[S] int[3]  - Parameters.
				  int[0] - Data size.
				  int[1] - Load address.
				  int[2] - CRC32 checksum.
	[D] 20ms
	[S] *       - Binary data.
	
Uploading a patch binary (similar to uploading a binary file).

	Patch binaries are basically just raw MIPS processor instructions and is always loaded at $80010000. It is called by the loader as a C function with no arguments as soon as it has finished uploading and CRC32 verification has completed. The main purpose of this mechanism is for patching debugging stubs to the system kernel and was implemented during the development of PSn00b Debugger.
	
	LITELOAD with patch $C000-$C008 with 0s (which count as nop instructions) just before the execution is transferred to the loaded program. This is to allow debug patches that use the serial port to remain inactive by having the first two instructions jump immediately back to the default kernel hook ($C80) so the loader can continue to use the serial port for loading programs and binary files until it is time to run the loaded program.

	[S] char[4] - Send command: MPAT
	[R] char[1] - Acknowledge: K
	[S] int[3]  - Parameters.
				  int[0] - Data size.
				  int[1] - Must be zero.
				  int[2] - CRC32 checksum.
	[D] 20ms
	[S] *       - Binary data.

	
## Patcher binaries
During the development of PSn00b Debugger a so called patch binary mechanism was implemented to allow for debug patches to be installed before uploading a program. Patch binaries are simply little binary executables that are always loaded to 0x80010000 and executed by the loader as a C function in which it can install patches and apply modifications to the kernel space.

A patch binary can be made easily using SDevTC Assembler for MIPS (ASMPSX) and no$psx's built-in assembler:
```
org $A0010000

start:

	< do whatever here >
	
	; Returns to loader
	jr	ra
	nop
```
In ASMPSX, assemble as plain binary with /p parameter.

For GNU assembler targeting mipsel-unknown-elf:
```
--- In your .ld script ---

MEMORY {
  ROM(RWX)   : ORIGIN = 0x80010000, LENGTH = 256K
}

SECTIONS {
  ROM : {
    *(.text);
  }
}

--- In your .s file ---

.set noreorder		# To make GAS behave a bit more closely to ASMPSX

.section .text

start:

	< do whatever here >
	
	# Returns to loader
	jr	$ra
	nop
	
--- Build with the following commands ---

mipsel-unknown-elf-as patch.s -o patch.o
mipsel-unknown-elf-ld --nmagic --oformat binary -T patch.ld patch.o -o patch.bin

```
Registers v0-v1, a0-a3 and t0-t9 can be used freely without having to preserve it through the stack.


## Changelog

**Version 1.1**
* Changed protocol when uploading EXEs to allow break on entrypoint for debuggers. This also means you're going to need to use a new version of mcomms that uses the updated protocol. Trying to use an older version of mcomms will likely result in incomplete download or CRC32 error.
* Added special patch binary support for installing debug patches to the PS1 kernel.
* Fixed progress bar overflowing when downloading large executables.

**Version 1.0 (6/22/2018)**
* Initial release.

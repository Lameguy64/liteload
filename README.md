# LITELOAD
A simple but very lightweight serial loader tool for the PS1. LITELOAD also
improves upon most loaders by supporting a number of new features such as
uploading binary files to set memory locations (a feature that was present
in Caetla and official development tools) and CRC32 data integrity
verification.

As of version 1.2, LITELOAD has been ported to the 100% free and open source
PS1 SDK called PSn00bSDK, making this homebrew loader completely free and is
also the very first PS1 homebrew to be ported from the official SDK to
PSn00bSDK without any features lost in the porting process. The move to
PSn00bSDK also reduced the size of the program by over 50%, as PSn00bSDK's
libraries are more efficiently written than the official libraries.

Use [mcomms](https://github.com/Lameguy64/mcomms) to upload binary files
and PS-EXE executables to LITELOAD.


## Features
* Supports PS-EXE size up to 1964KB (assuming PS-EXE loads at 0x80010000).
* Supports uploading binary files at set memory locations, be careful not
  to overwrite the loader.
* CRC32 checksums to verify data integrity, eliminating the possibility of
  program bugs caused by data corruption during upload.
* 100% free and open source as of version 1.2.


## Compiling (PS-EXE)
This tool can only be compiled using PSn00bSDK on Windows or Linux.

You will also need the following:
* MSys2 & PSn00bSDK.
* mkpsxiso (get it [here](https://github.com/Lameguy64/mkpsxiso)).

This assumes you already have PSn00bSDK setup with MSys2.

1. Open up the MSys2 terminal or Command Prompt.
2. Run "make" to compile.
3. Run "make iso" to build the ISO image using mkpsxiso.

The ISO image will be generated without license data, as the original Sony
license data is most likely still copyrighted. You can however patch the
license data yourself with an old licensing utility.

* All NTSC US systems will accept discs without license data.
* PAL systems accepts discs without license data up until the SCPH-5552.
* All NTSC JP systems will not accept discs without the correct license
  data until SCPH-9000 and onwards.

If you downloaded a pre-built package of LITELOAD, the ISO image would lack
license data normally. Be sure to patch the image before burning to a disc
if you want to include license data.


## Compiling (cartridge ROM version)
Creating a ROM version of LITELOAD requires the loader to be compiled first.

You will also need the following:
* GCC compiler targetting your host (for the exe2bin utility)
* ARMIPS Assembler (get it [here](https://github.com/kingcom/armips)).

1. Compile exe2bin in the rom/util directory as a PC side program.
2. Run `make` in the rom directory and it should produce a liteload.rom file.

The liteload.rom file can then be flashed to a cheat cartridge with X-FLASH
or with an external EEPROM programmer. The loader boots instantly through
this method and is recommended if you use LITELOAD regularly.


## Upload protocol
If you wish to write your own uploader tool, the following describes LITELOAD's
communication protocol. The protocol is designed to be as simple and efficient
as possible for simplified integration and provides the fastest upload rate
possible on the already slow serial interface.

LITELOAD always communicates at 115200 baud, 8 data bits, 1 stop bit, no parity
and no handshaking, as serial cables for connecting to the PS1 typically provide
only TX, RX and ground.

Legend:

	[S]  - Send.
	[R]  - Receive.
	[D]  - Delay.
	int  - 32-bit word.
	char - 8-bit byte.

Uploading an executable:

	[S] char[4] - Send command: MEXE
	[R] char[1] - Acknowledge: K
	[S] int[16] - Executable parameters & checksum.
					First 15 elements are EXEC parameters (same format as
					EXEC struct in SDK). The 16th element in the array is
					the CRC32 checksum.
	[S] int[1]	- Executable flags.
					bit 0   : Set BPC on executable entrypoint (for debug
					          monitors installed through a patch binary).
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

Patch binaries are basically just raw binary programs and is always
loaded at 0x80010000. It is called by the loader as a C function
as soon as it has finished downloading and checksum verification.
The binary is executed outside of critical section mode so you'll
have to call the relevant BIOS functions yourself.

The main purpose of this mechanism is for patching debug monitors into
the system kernel for use with homebrew debuggers. This feature was
implemented into this loader during the development of PSn00bDebugger.

LITELOAD with patch nops to $C000-$C008 just before the loaded program
is executed. This is so that debug monitors that use the serial interface
can remain 'inactive' by having the first 2 instructions jump back to the
kernel exception handler. The reason for this is so that the loader can
still use the serial interface as otherwise the debug monitor would take
all incoming bytes as commands before LITELOAD, rendering it unable to
receive a PS-EXE.

	[S] char[4] - Send command: MPAT
	[R] char[1] - Acknowledge: K
	[S] int[3]  - Parameters.
				  int[0] - Data size.
				  int[1] - Must be zero.
				  int[2] - CRC32 checksum.
	[D] 20ms
	[S] *       - Binary data.

	
## Patcher binaries
During the development of PSn00bDebugger a patch binary mechanism was 
implemented to allow for debug monitors to be patched to the kernel before
uploading a program, to allow for debugging capabilities.

Patch binaries are simply little binary programs that are always loaded
to 0x80010000 and executed by the loader as a C function, from there the
patch can do modifications to the kernel.

A patch binary is simply raw executable binary code and can be created
easily using ARMIPS:
```
.psx

.create "patch.bin", 0x80010000

start:

	< do whatever you need to do here >
	
	; Returns to loader (be sure ra is saved and restored before this point)
	jr	ra
	nop
	
.close
```


## Changelog
**Version 1.2 (07/19/2019)**
* Ported to PSn00bSDK, reducing the loader size from 38KB down to 18KB.
* Patch binary and ROM building guides updated for ARMIPS.
* Loader address changed to 0x801faff0 (upper 20KB).
* Updated exec logic to set stack on loaded programs to 0x801ffff0 
  (top of main RAM which is standard).
* Improved readme file.

**Version 1.1 (12/07/2018)**
* Changed protocol when uploading EXEs to allow break on entrypoint for
  debuggers. This also means you're going to need to use a new version of
  mcomms that uses the updated protocol. Trying to use an older version of
  mcomms will likely result in incomplete download or CRC32 error.
* Added special patch binary support for installing debug patches to the
  PS1 kernel.
* Fixed progress bar overflowing when uploading large executables.
* Included tools and ROMstrap code for creating a cheat cartridge bootable
  version of LITELOAD.

**Version 1.0 (6/22/2018)**
* Initial release.

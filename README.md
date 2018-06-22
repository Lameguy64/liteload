# LITELOAD
A very lightweight serial loader tool for the original Sony PlayStation. LITELOAD also improves upon most loaders by supporting uploading of binary files and CRC32 integrity verification to ensure that any bugs or crashes you experience in your project is not caused by corruption during upload.

## Features
* Supports executable size up to 1816KB (if EXE is loaded at 0x80010000).
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
				  First 15 ints are EXEC parameters (same struct format in SDK).
				  The 16th int is the CRC32 checksum.
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
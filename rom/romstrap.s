# ROMstrap by Lameguy64 of Meido-Tek Productions
# Boot PS-EXEs straight from a ROM cartridge!
#
# This code is to be assembled using the GNU assembler targeting
# mipsel-unknown-elf
#

# Uncomment either PAR or XPLORER depending on the cartridge you'll use

#.set PAR, 0
.set XPLORER, 1


.set noreorder

.include "cop0.h"

.set BREAK_ADDR,	0xa0000040	# cop0 breakpoint vector

.set EXE_pc0,		0			# PS-EXE header offsets
.set EXE_gp0,		4
.set EXE_taddr,		8
.set EXE_tsize,		12
.set EXE_daddr,		16
.set EXE_dsize,		20
.set EXE_baddr,		24
.set EXE_bsize,		28
.set EXE_spaddr,	32
.set EXE_sp_size,	36
.set EXE_sp,		40
.set EXE_fp,		44
.set EXE_gp,		48
.set EXE_ret,		52
.set EXE_base,		56
.set EXE_datapos,	60


.section .text

header:
	.word	0					# Postboot vector (not used)
	.ascii	"Licensed by Sony Computer Entertainment Inc."
	.ascii 	"NOT officially licensed or endorsed by Sony Computer Entertainment"
	.fill	14
	.word	preboot				# Preboot vector
	.ascii	"Licensed by Sony Computer Entertainment Inc."
	.asciiz	"ROMstrap loader for LITELOAD by Lameguy64 https://github.com/Lameguy64/liteload"
	
preboot:
	# Preboot function
	#
	# All it does is it sets a jump in the breakpoint vector at 0x40
	# and sets a cop0 breakpoint at 0x80030000 to perform a midboot
	# exploit as preboot doesn't have the kernel area initialized yet.
	
.ifdef XPLORER
	lui		$a0, 0x1f06			# Check of Xplorer switch is off
	lbu		$v0, 0($a0)
.endif

.ifdef PAR
	lui		$a0, 0x1f02			# Check of PAR switch is off
	lbu		$v0, 0x18($a0)
.endif

	nop
	andi	$v0, 0x1
	beqz	$v0, .no_rom		# If switch is off don't install hook
	nop

	li		$v0, BREAK_ADDR		# Apply a jump at cop0 breakpoint vector
	li		$a0, 0x3c1a1f00		# lui $k0, $1f00
	sw		$a0, 0($v0)
	la		$a1, midboot		# ori $k0, < address to midboot >
	andi	$a1, 0xffff
	lui		$a0, 0x375a
	or		$a0, $a1
	sw		$a0, 4($v0)
	li		$a0, 0x03400008		# jr  $k0
	sw		$a0, 8($v0)
	sw		$0 , 12($v0)		# nop
	
	lui		$v0, 0xffff			# Set BPCM and BDAM masks
	ori		$v0, 0xffff
	mtc0	$v0, BDAM
	mtc0	$v0, BPCM
	
	li		$v0, 0x80030000		# Set break on PC and data-write address
	mtc0	$v0, BDA			# BPC is mainly for compatibility with no$psx
	mtc0	$v0, BPC			# as it does not appear emulate BDA properly
	
	lui		$v0, 0xeb80			# Enable break on data-write and PC
	mtc0	$v0, DCIC
	
.no_rom:

	jr		$ra
	nop

midboot:
	# Midboot function
	#
	# Just returns from exception and jumps to main code
	
	mtc0	$0 , DCIC
	la		$k0, main
	jr		$k0
	rfe
	
main:
	
	la		$a0, exe_data		# Get PS-EXE addresses
	lw		$a1, EXE_taddr($a0)
	lw		$a2, EXE_tsize($a0)
	
	addiu	$a0, EXE_datapos

.copy_loop:						# Copy PS-EXE data

	lw		$v0, 0($a0)
	addiu	$a0, 4
	sw		$v0, 0($a1)
	addiu	$a2, -4

	bgtz	$a2, .copy_loop
	addiu	$a1, 4
	
	# Prepare for calling Exec
	
	addiu	$sp, -EXE_datapos	# Copy PS-EXE header to stack
	la		$a0, exe_data
	move	$a1, $sp
	li		$a2, EXE_datapos

.head_copy_loop:				# Copy header to stack

	lw		$v0, 0($a0)
	addiu	$a0, 4
	sw		$v0, 0($a1)
	addiu	$a2, -4
	
	bgtz	$a2, .head_copy_loop
	addiu	$a1, 4
	
	li		$a0, 0x1			# Enter critical section
	syscall	0x1
	
	move	$a0, $sp			# Set arguments for Exec()
	move	$a1, $0
	move	$a2, $0
	
	addiu	$t2, $0, 0xA0		# Call Exec() BIOS function
	jr		$t2
	addiu	$t1, $0, 0x43

exe_data:
	.incbin "../liteload.bin"	# Include PS-EXE data with reduced headers using exe2bin
	
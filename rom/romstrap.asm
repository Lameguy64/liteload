; ROMstrap by Lameguy64 of Meido-Tek Productions
; Boot PS-EXEs straight from a ROM cartridge!
;
; This code is to be assembled using ARMIPS
; https://github.com/kingcom/armips
;

; Uncomment either PAR or XPLORER depending on the cartridge you'll use

.psx

; Uncomment for PAR switch detection
;.definelabel	PAR, 1

; Uncomment for Xplorer switch detection
.definelabel	XPLORER, 1


.include "cop0.inc"


BREAK_ADDR	equ		0xa0000040	; cop0 breakpoint vector
STACK_ADDR	equ		0x801ffff0

EXE_pc0		equ		0			; PS-EXE header offsets
EXE_gp0		equ		4
EXE_taddr	equ		8
EXE_tsize	equ		12
EXE_daddr	equ		16
EXE_dsize	equ		20
EXE_baddr	equ		24
EXE_bsize	equ		28
EXE_spaddr	equ		32
EXE_sp_size	equ		36
EXE_sp		equ		40
EXE_fp		equ		44
EXE_gp		equ		48
EXE_ret		equ		52
EXE_base	equ		56
EXE_datapos	equ		60


; Workaround for those using an older version of ARMIPS
.macro rfe
	.word 0x42000010
.endmacro


.create "liteload.rom", 0x1f000000


header:
	.word	0			; Postboot vector & tty message (not used)
	.ascii	"Developed using 100% free development tools."
	.asciiz	"ROMstrap loader for LITELOAD by Lameguy64 https://github.com/lameguy64/liteload"
	.align	0x80
	
	.word	preboot		; Preboot vector
	.ascii	"Licensed by Sony Computer Entertainment Inc."
	.ascii 	"Not officially licensed or endorsed by Sony Computer Entertainment"
	.align	0x80
	
	
preboot:
	; Preboot function
	;
	; It sets a jump in the breakpoint vector at 0x40 and sets a cop0
	; breakpoint at 0x80030000 to perform a midboot hook trick as
	; preboot doesn't have the kernel area initialized yet.
	
	move	$v0, $0
	
.ifdef XPLORER
	lui		a0, 0x1f06			; Check if Xplorer switch is off
	lbu		v0, 0(a0)
.endif

.ifdef PAR
	lui		a0, 0x1f02			; Check if PAR switch is off
	lbu		v0, 0x18(a0)
.endif

	nop
	andi	v0, 0x1
	beqz	v0, .no_rom			; If switch is off don't install hook
	nop

	li		v0, BREAK_ADDR		; Apply a jump at cop0 breakpoint vector
	li		a0, 0x3c1a1f00		; lui k0, 0x1f00
	sw		a0, 0(v0)
	la		a1, midboot			; ori k0, < address to midboot >
	andi	a1, 0xffff
	lui		a0, 0x375a
	or		a0, a1
	sw		a0, 4(v0)
	li		a0, 0x03400008		; jr  k0
	sw		a0, 8(v0)
	sw		r0, 12(v0)			; nop
	
	lui		v0, 0xffff			; Set BPCM and BDAM masks
	ori		v0, 0xffff
	mtc0	v0, BDAM
	mtc0	v0, BPCM
	
	li		v0, 0x80030000		; Set break on PC and data-write address
	mtc0	v0, BDA				; BPC is mainly for compatibility with no$psx
	mtc0	v0, BPC				; as it does not appear emulate BDA properly
	
	lui		v0, 0xeb80			; Enable break on data-write and PC
	mtc0	v0, DCIC
	
.no_rom:

	jr		ra
	nop


midboot:
	; Midboot function
	;
	; Just returns from exception and jumps to main code
	
	mtc0	r0, DCIC
	la		k0, main
	jr		k0
	rfe


main:
	
	la		sp, STACK_ADDR
	
	la		a0, exe_data		; Get PS-EXE addresses
	lw		a1, EXE_taddr(a0)
	lw		a2, EXE_tsize(a0)
	
	addiu	a0, EXE_datapos

.copy_loop:						; Copy PS-EXE data

	lw		v0, 0(a0)
	addiu	a0, 4
	sw		v0, 0(a1)
	addiu	a2, -4

	bgtz	a2, .copy_loop
	addiu	a1, 4
	
	; Prepare for calling Exec
	
	addiu	sp, -EXE_datapos	; Copy PS-EXE header to stack
	la		a0, exe_data
	move	a1, sp
	li		a2, EXE_datapos

.head_copy_loop:				; Copy header to stack
	lw		v0, 0(a0)
	addiu	a0, 4
	sw		v0, 0(a1)
	addiu	a2, -4
	bgtz	a2, .head_copy_loop
	addiu	a1, 4
	
	la		$a0, STACK_ADDR		; Set stack address
	sw		$a0, EXE_sp($sp)
	sw		$a0, EXE_spaddr($sp)
	
	li		a0, 0x1				; Enter critical section
	syscall	0x1
	
	move	$a0, $sp			; Set arguments for Exec()
	move	$a1, $0
	move	$a2, $0
	
	
	addiu	$sp, -12
	addiu	$t2, $0, 0xA0		; Call Exec() BIOS function
	jr		$t2
	addiu	$t1, $0, 0x43

	
exe_data:
	.incbin "../liteload.bin"	; Include PS-EXE data with reduced headers using exe2bin
	
.close
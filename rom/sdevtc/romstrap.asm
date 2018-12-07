	opt	m+,l.,c+
	
	org	0x1f000000

	include 'cop0.inc'
	
BREAK_ADDR	equ	$a0000040
	
	rsreset
EXE_pc0		rw 1
EXE_gp0		rw 1
EXE_t_addr	rw 1
EXE_t_size	rw 1
EXE_d_addr	rw 1
EXE_d_size	rw 1
EXE_b_addr	rw 1
EXE_b_size	rw 1
EXE_sp_addr	rw 1
EXE_sp_size	rw 1
EXE_sp		rw 1
EXE_fp		rw 1
EXE_gp		rw 1
EXE_ret		rw 1
EXE_base	rw 1
EXE_datapos	rw 0

Header:
	dw	Postboot
	db	'Licensed by Sony Computer Entertainment Inc.'
	dsb	$50
	dw	Preboot
	db	'Licensed by Sony Computer Entertainment Inc.'
	dsb	$50
	
Postboot:
	jr		ra
	nop
	
Preboot:
	li		a1, BREAK_ADDR		; Set a cop0 break vector
	la		a0, $3c1a1f00
	sw		a0, 0(a1)
	la		a0, $375a0200
	sw		a0, 4(a1)
	la		a0, $03400008
	sw		a0, 8(a1)
	sw		r0, 12(a1)
	
	lui		a0, $ffff			; Set BPC masks
	ori		a0, $ffff
	mtc0	a0, BPCM
	
	li		a0, $80030000		; Set BPC address
	mtc0	a0, BPC
	
	lui		a0, $e180			; Enable cop0 break by BPC
	mtc0	a0, DCIC
	nop
	nop
	
	jr		ra
	nop
	
	org	0x1f000200
	
Insertion:
	mtc0	r0, DCIC			; Turn off cop0 break
	la		k0, Main
	jr		k0
	rfe
	
Main:
	
	; Check if Xplorer switch is off
	
	lui		a0, $1f06
	lbu		v0, 0(a0)
	nop
	andi	v0, $1
	beqz	v0, .no_rom			; If off, return back to BIOS menu
	nop
	
	; Copy the copier code
	la		a0, ExeCopyExec
	li		a1, $8000c000
	la		a2, ExeCopyEnd
	la		v0, ExeCopyExec
	subu	a2, v0

.copy_loop
	lw		v0, 0(a0)
	addiu	a0, 4
	sw		v0, 0(a1)
	addiu	a2, -4
	bgtz	a2, .copy_loop
	addiu	a1, 4
	
	li		a0, $8000c000
	jr		a0
	nop
	
.no_rom

	lui		t2, $8003
	jr		t2
	nop
	
ExeCopyExec:

	; Copies the executable
	
	la		a0, Payload
	lw		a1, EXE_t_addr(a0)
	lw		a2, EXE_t_size(a0)
	
	addiu	a0, EXE_datapos
.copy_loop
	lw		v0, 0(a0)
	addiu	a0, 4
	sw		v0, 0(a1)
	addiu	a2, -4
	bgtz	a2, .copy_loop
	addiu	a1, 4
	
	; Prepare for calling Exec
	
	subiu	sp, EXE_datapos		; Copy EXE header to stack
	la		a0, Payload
	move	a1, sp
	li		a2, 60
.head_copy_loop
	lw		v0, 0(a0)
	addiu	a0, 4
	sw		v0, 0(a1)
	addiu	a2, -4
	bgtz	a2, .head_copy_loop
	addiu	a1, 4
	
	li		a0, $1			; Enter critical section
	syscall	$1
	
	move	a0, sp			; Set arguments for Exec()
	move	a1, r0
	move	a2, r0
	
	addiu	t2,zero,0xA0	; Call Exec()
	jr		t2
	addiu	t1,zero,0x43

ExeCopyEnd:

Payload:
	incbin '..\..\liteload.bin'
%include "/usr/local/share/csc314/asm_io.inc"

; %define NONE	256		; 100000000
; %define NONE	128		; 010000000
%define lettuce	64		; 001000000
%define tomato	32		; 000100000
%define onion	16		; 000010000
%define pickle	8		; 000001000
%define mustard	4		; 000000100
%define ketchup	2		; 000000010
; %define NONE	1		; 000000001


segment .data

	order_code		db		"What is the Krabby Patty code?: ",0
	order_inc		db		"This order has:",10,0
	let 			db		" - Lettuce",10,0
	tom 			db		" - Tomato",10,0
	oni 			db		" - Onion",10,0
	pic 			db		" - Pickle",10,0
	mus 			db		" - Mustard",10,0
	ket 			db		" - Ketchup",10,0 
	bun				db		" - Dont forget the bun. This is not Paleo!",10,0

segment .bss


segment .text
	global  asm_main

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********

	mov		eax, order_code
	call	print_string
	call	read_int

	; 
	ror		eax, 2
	xor		eax, 'yay'
	not		eax
	xor		eax, 'rab'
	xor		eax, 'ty C'
	not		eax
	xor		eax, 'Krus'
	shl		eax, 1
	;call	print_int



	mov		ebx, eax			; putting the code in EBX for reference
	call	print_nl
	mov		eax, order_inc
	call	print_string

	; Lettuce compare 
	mov		eax, ebx
	and		eax, lettuce
	cmp		eax, 0
		je		tom_comp
	mov		eax, let
	call	print_string

	; Tomato compare 
	tom_comp:
	mov		eax, ebx
	and		eax, tomato
	cmp		eax, 0
		je		oni_comp
	mov		eax, tom
	call	print_string	

	; Onion Compare
	oni_comp:
	mov		eax, ebx
	and		eax, onion
	cmp		eax, 0
		je		pic_comp
	mov		eax, oni
	call	print_string

	; Pickle Compare
	pic_comp:
	mov		eax, ebx
	and		eax, pickle
	cmp		eax, 0
		je		mus_comp
	mov		eax, pic
	call	print_string

	; Mustard Compare
	mus_comp:
	mov		eax, ebx
	and		eax, mustard
	cmp		eax, 0
		je		ket_comp
	mov		eax, mus
	call	print_string

	; Ketchup Compare
	ket_comp:
	mov		eax, ebx
	and		eax, ketchup
	cmp		eax, 0
		je		end
	mov		eax, ket
	call	print_string
	
	end: 

	mov		eax, bun
	call	print_string

	

	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

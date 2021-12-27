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

	welcome		db		"Welcome to the Krusty Crab!",10,0
	ans			db		"Please answer using Y/y or N/n for questions.",10,0
	ING 		db		"What ingredients would you like?",10,0
	let 		db		"Lettuce?: ",0
	tom 		db		"Tomato?: ",0
	oni 		db		"Onion?: ",0
	pic 		db		"Pickle?: ",0
	mus 		db		"Mustard?: ",0
	ket 		db		"Ketchup?: ",0 
	order_code	db		"Your order code is: ",0

	order_inc		db		"This order has:",10,0
	let1 			db		" - Lettuce",10,0
	tom1 			db		" - Tomato",10,0
	oni1 			db		" - Onion",10,0
	pic1 			db		" - Pickle",10,0
	mus1 			db		" - Mustard",10,0
	ket1			db		" - Ketchup",10,0 

segment .bss


segment .text
	global  asm_main

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********

	mov		ebx, 0 			; Will be the final order

	; Start Order 
	mov		eax, welcome
	call	print_string
	call	print_nl
	mov		eax, ans
	call	print_string
	call	print_nl
	mov		eax, ING
	call	print_string
	call	print_nl

	; Lettuce
	mov		eax, let
	call	print_string

	call	read_char

	cmp		al, 'y'
	je		lettuce_add
	cmp		al, 'Y'
	je		lettuce_add

	jmp 	tomato_req


	lettuce_add:
	or 	ebx, lettuce

	; Tomato
	tomato_req:
	mov		eax, tom
	call	print_string

	call	read_char
	call	read_char
	cmp		al, 'y'
	je		tomato_add
	cmp		al, 'Y'
	je		tomato_add
	jmp 	onion_req

	tomato_add:
	or 	ebx, tomato

	; Onion
	onion_req:
	mov		eax, oni
	call	print_string
	
	call	read_char
	call	read_char
	cmp		al, 'y'
	je		onion_add
	cmp		al, 'Y'
	je		onion_add
	jmp 	pickle_req

	onion_add:
	or 	ebx, onion

	
	; Pickle
	pickle_req:
	mov		eax, pic
	call	print_string
	
	call	read_char
	call	read_char
	cmp		al, 'y'
	je		pickle_add
	cmp		al, 'Y'
	je		pickle_add
	jmp 	mustard_req

	pickle_add:
	or 	ebx, pickle
	
	; Mustard
	mustard_req:
	mov		eax, mus
	call	print_string
	
	call	read_char
	call	read_char
	cmp		al, 'y'
	je		mustard_add
	cmp		al, 'Y'
	je		mustard_add
	jmp 	ketchup_req

	mustard_add:
	or 	ebx, mustard	

	; Ketchup
	ketchup_req:
	mov		eax, ket
	call	print_string
	
	call	read_char
	call	read_char
	cmp		al, 'y'
	je		ketchup_add
	cmp		al, 'Y'
	je		ketchup_add
	jmp 	order_conf

	ketchup_add:
	or 	ebx, ketchup
	

	; Final Order confirmation				max value is 126 - in EBX

	order_conf:
	call	print_nl
	mov		eax, order_inc
	call	print_string
	; Lettuce compare 
	mov		eax, ebx
	and		eax, lettuce
	cmp		eax, 0
		je		tom_comp
	mov		eax, let1
	call	print_string

	; Tomato compare 
	tom_comp:
	mov		eax, ebx
	and		eax, tomato
	cmp		eax, 0
		je		oni_comp
	mov		eax, tom1
	call	print_string	

	; Onion Compare
	oni_comp:
	mov		eax, ebx
	and		eax, onion
	cmp		eax, 0
		je		pic_comp
	mov		eax, oni1
	call	print_string

	; Pickle Compare
	pic_comp:
	mov		eax, ebx
	and		eax, pickle
	cmp		eax, 0
		je		mus_comp
	mov		eax, pic1
	call	print_string

	; Mustard Compare
	mus_comp:
	mov		eax, ebx
	and		eax, mustard
	cmp		eax, 0
		je		ket_comp
	mov		eax, mus1
	call	print_string

	; Ketchup Compare
	ket_comp:
	mov		eax, ebx
	and		eax, ketchup
	cmp		eax, 0
		je		sec_sauce
	mov		eax, ket1
	call	print_string


	; Do the secrets sauce 

	sec_sauce:

	call	print_nl
	shr 	ebx, 1
	mov		eax, ebx
	xor		ebx, 'Krus'
	not		ebx
	xor		ebx, 'ty C'
	xor		ebx, 'rab'
	not		ebx
	xor		ebx, 'yay'
	rol		ebx, 2


	; Print the info 
	mov		eax, order_code
	call	print_string
	mov		eax, ebx
	call	print_int
	call	print_nl



	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

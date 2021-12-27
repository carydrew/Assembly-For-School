%include "/usr/local/share/csc314/asm_io.inc"


segment .data



segment .bss


segment .text
	global  asm_main

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********
	;																Can use EAX, EBX, ECX, EDX		ESI, EDI
	; Instructions 
	; 1.Read an integer from the user.
	; 2.Read a character from the user, representing the function. (+, -, *, /, %, ^)
	; 3.Read another integer from the user.
	; 4.Print an equals sign (=).
	; 5.Print the result.    ===== 				A (symbol) B = ans 

	call	read_int 
	mov 	esi, eax		; A = esi
	call	read_char		; dumping the trash char
	call	read_char
	mov		cl, al 			; Symbol = cl 
	call	read_int
	mov		edi, eax		; B = edi 

	cmp		cl, '+'		; + = 0x2b
	je		add_loop

	cmp		cl, '-'		; - = 0x2d
	je		sub_loop	
	
	cmp		cl, "*"		; * = 0x2a
	je		mul_loop
	
	cmp		cl, "/"		; / = 0x2f
	je		div_loop

	cmp		cl, "%"		; % = 0x25
	je		mod_loop

	cmp		cl, "^"		; ^ = 0x5e
	je		exp_loop

	add_loop:

		add		esi, edi
		mov 	eax, esi		; mov answer to get printed
		jmp		ans_loop		; jump to answer loop to print answer 

	end_add_loop:
	
	sub_loop:

		sub		esi, edi
		mov 	eax, esi		; mov answer to get printed
		jmp		ans_loop		; jump to answer loop to print answer 

	end_sub_loop:

	mul_loop:

		imul	esi, edi
		mov 	eax, esi		; mov answer to get printed
		jmp		ans_loop		; jump to answer loop to print answer 

	end_mul_loop:

	div_loop:

		; A   /  B 
		; ESI / EDI is needed 

		cdq						; edx = 0 
		mov		eax, esi		; eax = A 
		idiv	edi				; EAX = edx:eax / edi 
		jmp		ans_loop		; jump to answer loop to print answer 

	end_div_loop:

	mod_loop:

		; A   %  B 
		; ESI % EDI is needed 

		cdq						; edx = 0 
		mov		eax, esi		; eax = A 
		idiv	edi				; EAX = edx:eax / edi 
		mov		eax, edx		; moving remander to be printed
		jmp		ans_loop		; jump to answer loop to print answer 

	end_mod_loop:

	exp_loop:

		; A   ^  B 
		; ESI ^ EDI is needed
		mov		ebx, 0			; making a value for loop to compare to B - starting at 0, since if it's 10 the value is 1.

		cmp		ebx, edi		; checking to see if B is 0. If so going to different loop to return value of 1.
		je		one_loop
		inc		ebx				; making ebx 1 if it wasn't 0
		mov		eax, esi		; making a copy of A, so 1 can be multiplied repeated

		top_of_exp_loop:
				cmp		ebx, edi    		; compare counter to B 
				jge		end_of_exp_loop
				imul	eax, esi 			; multiplying A by itself 
				add		ebx, 1				; add 1 to the counter
				jmp		top_of_exp_loop		; restart the loop

		end_of_exp_loop:		; mul loop is done
		jmp		ans_loop		; jump to answer loop to print answer 
	end_exp_loop:

	one_loop:					; called if exponent 0.
		mov 	eax, 1
		jmp 	ans_loop
	end_one_loop:

	ans_loop:					; The answer loop to clean up lines. 
		mov		ebx, eax		; move answer from eax to print the = 
		mov		al, "="		; move = to eax 
		call	print_char		; print = 
		call	print_nl
		mov		eax, ebx 		; move answer back to eax 
		call	print_int		; print answer 
		call	print_nl
	end_ans_loop:

	

	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

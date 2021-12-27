%include "/usr/local/share/csc314/asm_io.inc"

%define sys_write 4
%define std_out 1 

segment .data

	str1	db	"Hello world",10,0	
	str2	db	"str3 is '%s' isn't that cool?",10,0
	str3	db	"woot woot",0
	str4 	db	"%c is a char but so is %% %s again!",10,0
	str5	db	"%d is a number!",10,0

segment .bss


segment .text
	global  asm_main

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********

	push	str1
	call	printf
	add		esp, 4
	push	str3
	push	str2
	call	printf
	add		esp, 8
	push 	str3
	push	"A"
	push 	str4
	call	printf
	add		esp, 12

	; %d challenge

	;push	2
	;push	str5
	;call	printf
	;add		esp, 8

	;push	99
	;push	str5
	;call	printf
	;add		esp,8

	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret


printf:  ;; 1 char at a time version. 
	push	ebp
	mov		ebp, esp
	sub		esp, 12 
  
	mov		edi, DWORD[ebp + 8]
	mov		esi, 0

	print_go_brrrrr:
		cmp		BYTE [edi], 0 		; check for null
		je		actual_end
		cmp		BYTE [edi], 37 		; check for %
		je		var_check
			; Print the char
			mov 	eax, sys_write
			mov		ebx, std_out
			lea		ecx, BYTE[edi]		; Point to the data
			mov		edx, 1 				; Put the length into edx
			int		0x80
		print_return:
		inc		edi
		jmp		print_go_brrrrr

		var_check:
			inc		edi
			mov		ecx, edi
			cmp		BYTE [edi], '%' 	; check for % again
			je		percent				; if % print the line
			cmp		BYTE[ecx], 's'		; If s go to string print
			je		var_print	
			;cmp		BYTE[ecx], 'd'		; If d go to int print
			;je		print_money

			; Print the %c
				add		esi, 4
				mov 	eax, sys_write
				mov		ebx, std_out
				lea		ecx, BYTE[ebp + 8 + esi]		; Point to the data
				mov		edx, 1 							; Put the length into edx
				int		0x80
				jmp		print_return

			; Print the %
			percent:
				mov 	eax, sys_write
				mov		ebx, std_out
				lea		ecx, BYTE[edi]		; Point to the data
				mov		edx, 1 				; Put the length into edx
				int		0x80
				jmp		print_return

		var_print:
			add		esi, 4
			mov		DWORD[ebp - 12], edi		; save the edi for later 
			mov		edi, [ebp + 8 + esi]

			var_go_brrrrrr:
				cmp		BYTE[edi], 0 			; check for null
				je		brrr_end
				cmp		BYTE[edi], 10 		; check for newline
				je		brrr_end			
				jmp		print
				print:
				; Print the char
					mov 	eax, sys_write
					mov		ebx, std_out
					lea		ecx, [edi]				; Point to the data
					mov		edx, 1 					; Put the length into edx
					int		0x80
				inc		edi						
				jmp		var_go_brrrrrr
			brrr_end:
			mov		edi, DWORD[ebp - 12]			; move edi back
			mov		esi, 8
			jmp		print_return

	actual_end:							; function end 
	mov		BYTE[ebp - 4], 10 			; new line for end of print
	mov 	eax, sys_write
	mov		ebx, std_out
	mov		ecx, DWORD[ebp - 4]			; Point to the newline
	mov		edx, 1
	int		0x80

	mov		esp, ebp
	pop		ebp
	ret									; return eax 


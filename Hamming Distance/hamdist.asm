%include "/usr/local/share/csc314/asm_io.inc"


segment .data

	format	db	"Hamming distance = %d",10,0

	; the hamming distance between these is 1
	str1	db	"text",0
	str2	db	"test",0
	wel		db 	"This function will check the Hamming Distance between two words.",10,0
	w1		db	"What is your first word to check?",10,0
	w2		db	"what is your second word to check?",10,0

segment .bss

	mystr	resb	1024 
	word1	resb	1024
	word2	resb	1024

segment .text
	global  asm_main
	extern	printf

asm_main:
	push	ebp
	mov		ebp, esp
	;***************CODE STARTS HERE***************************

	mov		eax, wel
	call	print_string
	mov		eax, w1
	call	print_string

	call	read_word1		; get the first word 
	mov		edx, eax 		; Word 1 is in ebx 


	mov		eax, w2
	call	print_string

	call	read_word2		; get the second word

	push	eax			; push word2 
	push	edx			; push word1
	

	; call your ham dist function here
	; pass str1 and str2 as arguments
	; result gets returned in EAX


	call	hamdist
	add		esp, 8


	push	eax		; the returned integer from hamdist()
	push	format	; "Hamming distance = %d\n"
	call	printf
	add		esp, 8

	;***************CODE ENDS HERE*****************************
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

hamdist:

	push 	ebp
	mov		ebp, esp
	sub		esp, 8				; The two integer vars

	; stack looks like
	;	EBP - 8	 = Local 2 
	;	EBP - 4	 = Local 1 
	;	EBP		 = EBP
	;	EBP + 4  = RET 
	;	EBP + 8  = word 1 
	;	EBP + 12 = word 2

	mov		DWORD [ebp - 4], 0 		; counter for i // local 1 // i = 0 
	mov		DWORD [ebp - 8], 0		; counter for unmatched  // local 2 // unmatched = 0 


	hamloop: 
		mov 	ebx, DWORD [ebp + 8]	; word 1
		mov		ecx, DWORD [ebp +12]	; word 2 
		mov		esi, DWORD [ebp - 4]	; i 

		mov		al, BYTE[ebx+esi]
		mov		dl, BYTE[ecx+esi]

		cmp		al, dl
		je		endhamloop
		inc		DWORD [ebp - 8]		; unmatched 
	endhamloop:
	inc		DWORD [ebp - 4]			; i 

	mov		eax, DWORD [ebp - 4]
	cmp 	BYTE [ebx + eax], 0	; compare to null byte
	jne		hamloop

	mov		eax, DWORD [ebp - 8]	; return unmatched 

	mov		esp, ebp
	pop		ebp
	ret

read_word1:

	push 	ebp
	mov		ebp, esp

	mov		esi, 0			; counter 

	readloop1:
		call	read_char
		mov		BYTE [word1 + esi], al
	
	inc		esi
	cmp 	al, 10	; looking for newline 
	jne		readloop1
	mov		BYTE[word1 + esi - 1], 0

	mov		eax, word1
	mov		esp, ebp
	pop		ebp
	ret 


read_word2:

	push 	ebp
	mov		ebp, esp

	mov		esi, 0		; counter 

	readloop2:
		call	read_char
		mov		BYTE [word2 + esi], al
	
	inc		esi
	cmp 	al, 10	; looking for newline 
	jne		readloop2
	mov		BYTE[word2 + esi -1 ], 0

	mov		eax, word2
	mov		esp, ebp
	pop		ebp
	ret 
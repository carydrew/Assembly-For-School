%include "/usr/local/share/csc314/asm_io.inc"


segment .data

	str1	db		"Input numbers",10,0
	str2	db		"These are the sorted numbers",10,0
	str3	db		"Done taking input",10,0
	str4	db		"Have a good day!",10,0


segment .bss

	nums	resb	10

segment .text
	global  asm_main

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********

	;; Read ints 

	mov		ecx, 0
	
	mov		eax, str1
	call 	print_string

	inputloop:
	cmp		ecx, 10
	jge		endinputloop
		
			call read_int
			mov DWORD [nums + ecx * 4], eax
			
		
	add		ecx, 1
	jmp		inputloop
	endinputloop:
	
	mov		eax, str3
	call 	print_string
	call	print_nl


	;; Sorting the array 

	mov ecx, 0

	sortloop:

	cmp		ecx, 10
	jge		endsortloop

	mov 	edx, 0    		; internal loop counter
			iloop:
				cmp		edx, 9
				jge		endiloop

				mov		eax, DWORD [nums + edx * 4]		;; Move EDX first byte into EAX 
				;call	print_int						;; troubleshooting I guess 
				;call	print_nl
				mov		ebx, DWORD [nums + 4 + edx * 4]	;; Move EDX second byte into EBX 
				add		edx, 1
				cmp 	eax, ebx						;; Compare the two bytes
				jle		iloop							;; if EAX is less than EBX, go back to top 
				sub		edx, 1							;; Else 
				mov		DWORD [nums + edx * 4], ebx 	;;  move what is from ebx into the first spot
				mov		DWORD [nums + 4 + edx * 4], eax ;;  move what is in eax into second spot 

				add		edx, 1
				jmp		iloop							;; jump to the top 
				

			endiloop:

	;mov		eax, DWORD [nums + ecx * 4]
	;mov		ebx, DWORD [nums + ecx * 8]
	;cmp 	eax, ebx
	add		ecx, 1
	jmp		sortloop
	
	endsortloop:

	;; print elements from array 

	mov		ecx, 0
	
	mov		eax, str2
	call 	print_string

	printloop:
	cmp		ecx, 10
	jge		endprintloop
		
			; print_int( nums[i+4]);
			mov		eax, DWORD [nums + ecx * 4]
			call	print_int
			call	print_nl
		
	add		ecx, 1
	jmp		printloop
	endprintloop:

	mov		eax, str4
	call 	print_string
	
	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

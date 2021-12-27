%include "/usr/local/share/csc314/asm_io.inc"


; how frequently we check for input
; 1,000,000 = 1 second
%define TICK 100000	; 1/10th of a second


segment .data

	; used to change the terminal mode
	mode_r				db "r",0
	raw_mode_on_cmd		db "stty raw -echo",0
	raw_mode_off_cmd	db "stty -raw echo",0

segment .bss


segment .text
	global  asm_main
	global  raw_mode_on
	global  raw_mode_off
	extern	system

	extern	usleep		; used to slow down the read loop
	extern	fcntl		; used to change the blocking mode
	extern	getchar		; used to get a single character
	extern	putchar		; used to print a single character

asm_main:
	push	ebp
	mov		ebp, esp
	;***************CODE STARTS HERE***************************

	call	raw_mode_on

	demo_loop:

	; try to get a character from the user
	; if they typed something, this will return the character
	; otherwise it will return -1 (0xff)
	call	nonblocking_getchar

	; check what was returned
	cmp		al, -1
	jne		got_char

		; we didn't get a character.  sleep and loop again
		; Note: if we don't sleep here it scrolls too fast
		; and ends up looking weird

		; usleep(TICK)
		push	TICK
		call	usleep
		add		esp, 4

		; also print a '.' to indicate no character seen
		push	'.'
		call	putchar
		add		esp, 4

		jmp		demo_loop

	got_char:

		; we got a character!  Do something with it and
		; then loop again

		cmp		al, 'q'
		je		done

		push	eax
		call	putchar
		add		esp, 4

		jmp		demo_loop

	done:

	call	raw_mode_off

	;***************CODE ENDS HERE*****************************
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret



; === FUNCTION ===
nonblocking_getchar:

; returns -1 on no-data
; returns char on succes

; magic values
%define F_GETFL 3
%define F_SETFL 4
%define O_NONBLOCK 2048
%define STDIN 0

	push	ebp
	mov		ebp, esp

	; single int used to hold flags
	; single character (aligned to 4 bytes) return
	sub		esp, 8

	; get current stdin flags
	; flags = fcntl(stdin, F_GETFL, 0)
	push	0
	push	F_GETFL
	push	STDIN
	call	fcntl
	add		esp, 12
	mov		DWORD [ebp-4], eax

	; set non-blocking mode on stdin
	; fcntl(stdin, F_SETFL, flags | O_NONBLOCK)
	or		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	call	getchar
	mov		DWORD [ebp-8], eax

	; restore blocking mode
	; fcntl(stdin, F_SETFL, flags ^ O_NONBLOCK
	xor		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	mov		eax, DWORD [ebp-8]

	mov		esp, ebp
	pop		ebp
	ret


; === FUNCTION ===
raw_mode_on:

	push	ebp
	mov		ebp, esp

	push	raw_mode_on_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
raw_mode_off:

	push	ebp
	mov		ebp, esp

	push	raw_mode_off_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

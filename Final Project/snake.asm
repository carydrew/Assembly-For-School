%include "/usr/local/share/csc314/asm_io.inc"

; the file that stores the initial state
%define BOARD_FILE 'board.txt'
%define LOGO_FILE	'snake.txt'
%define GAME_OVER_FILE 'game_over.txt'

; how to represent everything
%define WALL_CHAR '#'
%define SNAKE_HEAD '@'
%define SNAKE_BODY 'O'
%define SNAKE_FOOD '*'
%define EMPTY_CHAR ' '

; the size of the game screen in characters
%define HEIGHT 20
%define WIDTH 40

; The size of the start screen
%define S_HEIGHT 27
%define S_WIDTH 56

; The size of the end screen.
%define	E_HEIGHT 11 
%define E_WIDTH 83

; these keys do things
%define	PLAYCHAR 'y'
%define EXITCHAR 'x'
%define UPCHAR 'w'
%define LEFTCHAR 'a'
%define DOWNCHAR 's'
%define RIGHTCHAR 'd'

; how frequently we check for input ; 1,000,000 = 1 second
%define TICK 100000	; 1/10th of a second 

; magic values
%define F_GETFL 3
%define F_SETFL 4
%define O_NONBLOCK 2048
%define STDIN 0

segment .data

	; used to fopen() the board file defined above
	board_file			db BOARD_FILE,0

	; used to fopen() the logo file defined above
	logo_file			db LOGO_FILE,0

	; used to fopen() the end_game file defined above
	game_over_file		db GAME_OVER_FILE,0

	; used to change the terminal mode
	mode_r				db "r",0
	raw_mode_on_cmd		db "stty raw -echo",0
	raw_mode_off_cmd	db "stty -raw echo",0

	; ANSI escape sequence to clear/refresh the screen
	clear_screen_code	db	27,"[2J",27,"[H",0

	; things the program will print
	help_str			db 13,10,"Controls: ", \
							UPCHAR,"=UP / ", \
							LEFTCHAR,"=LEFT / ", \
							DOWNCHAR,"=DOWN / ", \
							RIGHTCHAR,"=RIGHT / ", \
							EXITCHAR,"=EXIT", \
							13,10,10,0

	score				dd 		0							; Score and the length of the body
	score_str			db 		"[Score: %d ]",10,13,0
	color_normal		db		27,"[0m",0
	color_red			db		27,"[31m",0
	color_yellow		db		27,"[93m",0
	color_green			db		27,"[92m",0
	color_black			db		27,"[40m",0

segment .bss

	; this array stores the current rendered gameboard (HxW)
	board	resb	(HEIGHT * WIDTH)

	; this array stores the current rendered logo (HxW)
	logo	resd	(S_HEIGHT * S_WIDTH)

	; this array stores the current rendered endgame screen(HxW)
	endgame	resd	(E_HEIGHT * E_WIDTH)

	; these variables store the current player position
	xpos	resd	1
	ypos	resd	1

	; these variables store the players last position
	last_xpos	resd	10
	last_ypos	resd	10

	; Variable for the food position
	fxpos	resd	1
	fypos	resd	1

	; Last move

	last_move	resd	1

segment .text

	global	asm_main			; main function
	global  raw_mode_on			; turn on raw mode function
	global  raw_mode_off		; turn off raw mode function
	global  init_board			; function to load in the board 
	global	init_logo			; function to load in the start logo
	global	logo_render			; function to render the logo
	global  render				; function to render the game board and play
	global  init_endgame		; function to load in the game over screen
	global  render_endgame		; function to render the game over screen
	global	player_move			; function to get a play move
	global  grow_func			; function to increase the length of the snake

	extern	system
	extern	putchar
	extern	getchar
	extern	printf
	extern	fopen
	extern	fread
	extern	fgetc
	extern	fclose

	extern	usleep		; used to slow down the read loop
	extern	fcntl		; used to change the blocking mode

	extern	time		; time/rand/srand are used for the random placement of food/snake
	extern	rand
	extern	srand

asm_main:
	push	ebp
	mov		ebp, esp

	; srand(time(0));
	push 	0
	call 	time
	add		esp, 4
	push	eax
	call	srand
	add		esp, 4

	call	raw_mode_on		; put the terminal in raw mode so the game works nicely
	call	init_logo		; load in the start logo
	call	logo_render		; show the start logo

	logo_start:
	call	getchar
	cmp		eax, EXITCHAR	; Test to start the game or quit
	je		game_loop_end	; Exit game if asked
	cmp		eax, PLAYCHAR	; Start game if asked
	jne		logo_start		; If not a proper char, do nothing.

	new_game: 						
	mov		DWORD [score], 0		; Set score back to 0
	mov		DWORD [last_move], 0	; Set last move back to 0 otherwise snake will move instantly. 
	call	init_board				; read the game board file into the global variable
	call	player_start_position	; set the player start 
	call	food_postion			; set the food start postion

	game_loop:

		call	render				; draw the game board
		call	player_move			; Get player move
			cmp		eax, EXITCHAR	; exit game if asked to
			je		game_loop_end		

		; compare the current position to the wall character
		mov		eax, WIDTH
		mul		DWORD [ypos]
		add		eax, DWORD [xpos]
		lea		eax, [board + eax]
		cmp		BYTE [eax], WALL_CHAR
			je		game_loop_end 				; opps, you hit the wall and just lost	
		cmp		BYTE [eax], SNAKE_BODY			; compare the current postion to the snake's body
			je		game_loop_end				; oops, you ate yourself and just lost
		jmp		game_loop						; Repeat the game loop. 
	
	game_loop_end:
	; Clear the screen
	push	clear_screen_code
	call	printf
	add		esp, 4

	call	init_endgame			; load in the gameover logo
	call	render_endgame			; render the gameover logo
	push	DWORD [score]			; Push the value for the score
	push	score_str				; Print the score
	call	printf
	add		esp, 8

	endgame_start:					; Test to start the game or quit
	call	getchar
	cmp		eax, EXITCHAR
	je		confirmed_end
	cmp		eax, PLAYCHAR
	je		new_game
	jmp		endgame_start			; loop again to get an actual letter required.

	confirmed_end:
	call 	raw_mode_off			; Restore old terminal functionality

	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret

raw_mode_on:

	push	ebp
	mov		ebp, esp

	push	raw_mode_on_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

raw_mode_off:

	push	ebp
	mov		ebp, esp

	push	raw_mode_off_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

init_board:

	push	ebp
	mov		ebp, esp

	; FILE* and loop counter
	; ebp-4, ebp-8
	sub		esp, 8

	; open the file
	push	mode_r
	push	board_file
	call	fopen
	add		esp, 8
	mov		DWORD [ebp - 4], eax

	; read the file data into the global buffer
	; line-by-line so we can ignore the newline characters
	mov		DWORD [ebp - 8], 0
	read_loop:
	cmp		DWORD [ebp - 8], HEIGHT
	je		read_loop_end

		; find the offset (WIDTH * counter)
		mov		eax, WIDTH
		mul		DWORD [ebp - 8]
		lea		ebx, [board + eax]

		; read the bytes into the buffer
		push	DWORD [ebp - 4]
		push	WIDTH
		push	1
		push	ebx
		call	fread
		add		esp, 16

		; slurp up the newline
		push	DWORD [ebp - 4]
		call	fgetc
		add		esp, 4

	inc		DWORD [ebp - 8]
	jmp		read_loop
	read_loop_end:

	; close the open file handle
	push	DWORD [ebp - 4]
	call	fclose
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

render:

	push	ebp
	mov		ebp, esp

	; two ints, for two loop counters
	; ebp-4, ebp-8
	sub		esp, 8

	; clear the screen
	push	clear_screen_code
	call	printf
	add		esp, 4

	; print the help information
	push	help_str
	call	printf
	add		esp, 4

	; print the score
	push	DWORD [score]
	push	score_str
	call	printf
	add		esp, 8


	; outside loop by height
	; i.e. for(c=0; c<height; c++)
	mov		DWORD [ebp - 4], 0
	y_loop_start:
	cmp		DWORD [ebp - 4], HEIGHT
	je		y_loop_end

		; inside loop by width
		; i.e. for(c=0; c<width; c++)
		mov		DWORD [ebp - 8], 0
		x_loop_start:

		; compare the snake position to the food. 
		mov		eax, DWORD [xpos]
		mov		ebx, DWORD [fxpos]
		cmp		eax, ebx
		jne		snake_didnt_eat
		mov		eax, DWORD [ypos]
		mov		ebx, DWORD [fypos]
		cmp		eax, ebx
		jne		snake_didnt_eat

		; Snake ate the food. 
		inc		DWORD[score]
		mov		DWORD[last_xpos], 
		mov				
		call	food_postion

		snake_didnt_eat:
		cmp		DWORD [ebp - 8], WIDTH
		je 		x_loop_end

			; check if (xpos,ypos)=(x,y)
			mov		eax, DWORD [xpos]
			cmp		eax, DWORD [ebp - 8]
			jne		body_print
			mov		eax, DWORD [ypos]
			cmp		eax, DWORD [ebp - 4]
			jne		body_print
				; if both were equal, print the player
				push	color_green
				call	printf
				add		esp, 4
				push	SNAKE_HEAD
				call	putchar
				add		esp, 4
				push	color_normal
				call	printf
				add		esp, 4
				jmp		print_end
			body_print:
			cmp		DWORD[score], 0 					; is the snake longer than the head?
			je		food_print							; if not skip this.
			; check if (last_xpos,last_ypos)=(x,y)
			mov		eax, DWORD [last_xpos]
			cmp		eax, DWORD [ebp - 8]
			jne		food_print
			mov		eax, DWORD [last_ypos]
			cmp		eax, DWORD [ebp - 4]
			jne		food_print
				; if both were equal, print the body of the snake
				push	color_green
				call	printf
				add		esp, 4
				push	SNAKE_BODY
				call	putchar
				add		esp, 4
				push	color_normal
				call	printf
				add		esp, 4
				jmp		print_end
			food_print:
			; check if (fxpos,fypos)=(x,y)
			mov		eax, DWORD [fxpos]
			cmp		eax, DWORD [ebp - 8]
			jne		print_board
			mov		eax, DWORD [fypos]
			cmp		eax, DWORD [ebp - 4]
			jne		print_board
				; if both were equal, print the food 
				push	color_yellow
				call	printf
				add		esp, 4
				push	SNAKE_FOOD
				call	putchar
				add		esp, 4
				push	color_normal
				call	printf
				add		esp, 4
				jmp		print_end

			print_board:
				; otherwise print whatever's in the buffer
				push	color_red
				call	printf
				add		esp, 4
				mov		eax, DWORD [ebp - 4]
				mov		ebx, WIDTH
				mul		ebx
				add		eax, DWORD [ebp - 8]
				mov		ebx, 0
				mov		bl, BYTE [board + eax]

				cmp		bl, EMPTY_CHAR
					push	color_black
					call	printf
					add		esp, 4
				not_food_print:

				push	ebx
				call	putchar
				add		esp, 4

				push	color_normal
				call	printf
				add		esp, 4
			print_end:

		inc		DWORD [ebp - 8]
		jmp		x_loop_start
		x_loop_end:

		; write a carriage return (necessary when in raw mode)
		push	0x0d
		call 	putchar
		add		esp, 4

		; write a newline
		push	0x0a
		call	putchar
		add		esp, 4

	inc		DWORD [ebp - 4]
	jmp		y_loop_start
	y_loop_end:

	mov		esp, ebp
	pop		ebp
	ret


nonblocking_getchar:

	; returns -1 on no-data
	; returns char on succes
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

print_empty:

	push	ebp
	mov		ebp, esp

	push	color_black
	call	printf
	add		esp, 4
	push	EMPTY_CHAR
	call	putchar
	add		esp, 4
	push	color_normal
	call	printf
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

food_postion:

	push	ebp
	mov		ebp, esp

	food_start:
		; fxpos = (rand() % (height - 2)) + 1;
		call	rand
		cdq		
		mov		ebx, WIDTH
		sub		ebx, 2
		idiv	ebx
		add		edx, 1
		mov		DWORD [fxpos], edx
		mov		ebx, DWORD [xpos]
		cmp		ebx, edx
		je		food_start

		; fypos = (rand() % (height - 2)) + 1;
		call	rand
		cdq		
		mov		ebx, HEIGHT
		sub		ebx, 2
		idiv	ebx
		add		edx, 1
		mov		DWORD [fypos], edx
		mov		ebx, DWORD [ypos]
		cmp		ebx, edx
		je		food_start

	mov		esp, ebp
	pop		ebp
	ret

init_logo:

	push	ebp
	mov		ebp, esp

	; FILE* and loop counter
	; ebp-4, ebp-8
	sub		esp, 8

	; open the file
	push	mode_r
	push	logo_file
	call	fopen
	add		esp, 8
	mov		DWORD [ebp - 4], eax

	; read the file data into the global buffer
	; line-by-line so we can ignore the newline characters
	mov		DWORD [ebp - 8], 0
	logo_read_loop:
	cmp		DWORD [ebp - 8], S_HEIGHT
	je		logo_read_loop_end

		; find the offset (WIDTH * counter)
		mov		eax, S_WIDTH
		mul		DWORD [ebp - 8]
		lea		ebx, [logo + eax]

		; read the bytes into the buffer
		push	DWORD [ebp - 4]
		push	S_WIDTH
		push	1
		push	ebx
		call	fread
		add		esp, 16

		; slurp up the newline
		push	DWORD [ebp - 4]
		call	fgetc
		add		esp, 4

	inc		DWORD [ebp - 8]
	jmp		logo_read_loop
	logo_read_loop_end:

	; close the open file handle
	push	DWORD [ebp - 4]
	call	fclose
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

logo_render:

	push	ebp
	mov		ebp, esp

	; two ints, for two loop counters
	; ebp-4, ebp-8
	sub		esp, 8

	; clear the screen
	push	clear_screen_code
	call	printf
	add		esp, 4

	; outside loop by S_HEIGHT
	; i.e. for(c=0; c<S_HEIGHT; c++)
	mov		DWORD [ebp - 4], 0
	logo_y_loop_start:
	cmp		DWORD [ebp - 4], S_HEIGHT
	je		logo_y_loop_end

		; inside loop by S_WIDTH
		; i.e. for(c=0; c<S_WIDTH; c++)
		mov		DWORD [ebp - 8], 0
		logo_x_loop_start:
		cmp		DWORD [ebp - 8], S_WIDTH
		je 		logo_x_loop_end

			; otherwise print whatever's in the buffer
			mov		eax, DWORD [ebp - 4]
			mov		ebx, S_WIDTH
			mul		ebx
			add		eax, DWORD [ebp - 8]
			mov		ebx, 0
			mov		bl, BYTE [logo + eax]
			push	ebx
			call	putchar
			add		esp, 4

		inc		DWORD [ebp - 8]
		jmp		logo_x_loop_start
		logo_x_loop_end:

		; write a carriage return (necessary when in raw mode)
		push	0x0d
		call 	putchar
		add		esp, 4

		; write a newline
		push	0x0a
		call	putchar
		add		esp, 4

	inc		DWORD [ebp - 4]
	jmp		logo_y_loop_start
	logo_y_loop_end:

	mov		esp, ebp
	pop		ebp
	ret



init_endgame:

	push	ebp
	mov		ebp, esp

	; FILE* and loop counter
	; ebp-4, ebp-8
	sub		esp, 8

	; open the file
	push	mode_r
	push	game_over_file
	call	fopen
	add		esp, 8
	mov		DWORD [ebp - 4], eax

	; read the file data into the global buffer
	; line-by-line so we can ignore the newline characters
	mov		DWORD [ebp - 8], 0
	endgame_read_loop:
	cmp		DWORD [ebp - 8], E_HEIGHT
	je		endgame_read_loop_end

		; find the offset (WIDTH * counter)
		mov		eax, E_WIDTH
		mul		DWORD [ebp - 8]
		lea		ebx, [endgame + eax]

		; read the bytes into the buffer
		push	DWORD [ebp - 4]
		push	E_WIDTH
		push	1
		push	ebx
		call	fread
		add		esp, 16

		; slurp up the newline
		push	DWORD [ebp - 4]
		call	fgetc
		add		esp, 4

	inc		DWORD [ebp - 8]
	jmp		endgame_read_loop
	endgame_read_loop_end:

	; close the open file handle
	push	DWORD [ebp - 4]
	call	fclose
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

render_endgame:

	push	ebp
	mov		ebp, esp

	; two ints, for two loop counters
	; ebp-4, ebp-8
	sub		esp, 8

	; clear the screen
	push	clear_screen_code
	call	printf
	add		esp, 4

	; outside loop by S_HEIGHT
	; i.e. for(c=0; c<S_HEIGHT; c++)
	mov		DWORD [ebp - 4], 0
	endgame_y_loop_start:
	cmp		DWORD [ebp - 4], E_HEIGHT
	je		endgame_y_loop_end

		; inside loop by S_WIDTH
		; i.e. for(c=0; c<S_WIDTH; c++)
		mov		DWORD [ebp - 8], 0
		endgame_x_loop_start:
		cmp		DWORD [ebp - 8], E_WIDTH
		je 		endgame_x_loop_end

			; otherwise print whatever's in the buffer
			mov		eax, DWORD [ebp - 4]
			mov		ebx, E_WIDTH
			mul		ebx
			add		eax, DWORD [ebp - 8]
			mov		ebx, 0
			mov		bl, BYTE [endgame + eax]
			push	ebx
			call	putchar
			add		esp, 4

		inc		DWORD [ebp - 8]
		jmp		endgame_x_loop_start
		endgame_x_loop_end:

		; write a carriage return (necessary when in raw mode)
		push	0x0d
		call 	putchar
		add		esp, 4

		; write a newline
		push	0x0a
		call	putchar
		add		esp, 4


	inc		DWORD [ebp - 4]
	jmp		endgame_y_loop_start
	endgame_y_loop_end:

	mov		esp, ebp
	pop		ebp
	ret

player_move:

	push	ebp
	mov		ebp, esp

		mov		edi, 0	; counter to use last char

		; get an action from the user
		; try to get a character from the user
		; if they typed something, this will return the character
		; otherwise it will return -1 (0xff)
		call	nonblocking_getchar

		; check what was returned
		cmp		al, -1
		jne		got_char

		no_char:
			; we didn't get a character.  sleep and loop again
			; Note: if we don't sleep here it scrolls too fast and ends up looking weird
			push	TICK						; usleep(TICK)
			call	usleep
			add		esp, 4

			inc		edi
			cmp		edi, 2						; check to see if no char press for 2/10 second.
			jge		repeat_char
			call	nonblocking_getchar			; get another key
			cmp		al, -1						; was a key returned? -1 = no
			jne		got_char					; if returned jump to go_char 
			jmp		no_char

		repeat_char:
		mov		eax, DWORD[last_move]
		jmp		do_the_move

		got_char:
		cmp		eax, DWORD[last_move]			; was key same as last?
		je		no_char							; if yes, don't do it as it looks wierd. Return to no_char loop to try again.
		mov		DWORD[last_move] , eax			; not the same then go do the move.
		
		do_the_move:  							; (W * y) + x = pos 
		; store the last position
		mov		DWORD [last_xpos], xpos
		mov		DWORD [last_ypos], ypos
		
		; store the current position  
		mov		esi, DWORD [xpos]
		mov		edi, DWORD [ypos]

		; choose what to do
		cmp		eax, EXITCHAR
		je		player_move_end
		cmp		eax, UPCHAR
		je 		move_up
		cmp		eax, LEFTCHAR
		je		move_left
		cmp		eax, DOWNCHAR
		je		move_down
		cmp		eax, RIGHTCHAR
		je		move_right
		jmp		input_end			; or just do nothing

		; move the player according to the input character
		move_up:
			dec		DWORD [ypos]
			jmp		input_end
		move_left:
			dec		DWORD [xpos]
			jmp		input_end
		move_down:
			inc		DWORD [ypos]
			jmp		input_end
		move_right:
			inc		DWORD [xpos]
		input_end:	

	player_move_end:
	mov		esp, ebp
	pop		ebp
	ret

player_start_position:

	push	ebp
	mov		ebp, esp

	; set the player at the proper start position ; xpos = (rand() % (width - 2)) + 1;
	call	rand
	cdq		
	mov		ebx, WIDTH
	sub		ebx, 2
	idiv	ebx
	add		edx, 1
	mov		DWORD [xpos], edx
	mov		DWORD [last_xpos], edx				; set the last postion as same initially

	; ypos = (rand() % (height - 2)) + 1;
	call	rand
	cdq		
	mov		ebx, HEIGHT
	sub		ebx, 2
	idiv	ebx
	add		edx, 1
	mov		DWORD [ypos], edx
	mov		DWORD [last_ypos], edx				; set the last postion as same initially

	mov		esp, ebp
	pop		ebp
	ret

grow_func:

	push	ebp
	mov		ebp, esp

	mov		DWORD [ebp - 4], last_xpos	; x pos
	mov		DWORD [ebp - 8], last_ypos	; y pos

	push	color_green
	call	printf
	add		esp, 4
	push	SNAKE_BODY
	call	putchar
	add		esp, 4
	push	color_normal
	call	printf
	add		esp, 4
	jmp		print_end

	mov		esp, ebp
	pop		ebp
	ret
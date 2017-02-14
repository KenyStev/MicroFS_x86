; ------------------------------------------------------------------
; os_string_length -- Return length of a string
; IN: AX = string location
; OUT AX = length (other regs preserved)

os_string_length:
	pusha

	mov bx, ax			; Move location of string to BX

	mov cx, 0			; Counter

.more:
	cmp byte [bx], 0		; Zero (end of string) yet?
	je .done
	inc bx				; If not, keep adding
	inc cx
	jmp .more


.done:
	mov word [.tmp_counter], cx	; Store count before restoring other registers
	popa

	mov ax, [.tmp_counter]		; Put count back into AX before returning
	ret


	.tmp_counter	dw 0


; ------------------------------------------------------------------
; os_string_copy -- Copy one string into another
; IN/OUT: SI = source, DI = destination (programmer ensure sufficient room)

os_string_copy:
	pusha

.more:
	mov al, [si]			; Transfer contents (at least one byte terminator)
	cmp byte al, 0			; If source string is empty, quit out
	je .done
	mov [di], al
	inc si
	inc di
	jmp .more

.done:
	popa
	ret


; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)

os_clear_screen:
  pusha

  mov dx, 0     ; Position cursor at top-left
  call os_move_cursor

  mov ah, 6     ; Scroll full-screen
  mov al, 0     ; Normal white on black
  mov bh, 7     ;
  mov cx, 0     ; Top-left
  mov dh, 24      ; Bottom-right
  mov dl, 79
  int 10h

  popa
  ret


; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to 255 characters, zero-terminated)


os_input_string:
  pusha

  mov di, ax      ; DI is where we'll store input (buffer)
  mov cx, 0     ; Character received counter for backspace


.more:          ; Now onto string getting
  call os_wait_for_key

  cmp al, 13      ; If Enter key pressed, finish
  je .done

  cmp al, 8     ; Backspace pressed?
  je .backspace     ; If not, skip following checks

  cmp al, ' '     ; In ASCII range (32 - 126)?
  jb .more      ; Ignore most non-printing characters

  cmp al, '~'
  ja .more

  jmp .nobackspace


.backspace:
  cmp cx, 0     ; Backspace at start of string?
  je .more      ; Ignore it if so

  call os_get_cursor_pos    ; Backspace at start of screen line?
  cmp dl, 0
  je .backspace_linestart

  pusha
  mov ah, 0Eh     ; If not, write space and move cursor back
  mov al, 8
  int 10h       ; Backspace twice, to clear space
  mov al, 32
  int 10h
  mov al, 8
  int 10h
  popa

  dec di        ; Character position will be overwritten by new
          ; character or terminator at end

  dec cx        ; Step back counter

  jmp .more


.backspace_linestart:
  dec dh        ; Jump back to end of previous line
  mov dl, 79
  call os_move_cursor

  mov al, ' '     ; Print space there
  mov ah, 0Eh
  int 10h

  mov dl, 79      ; And jump back before the space
  call os_move_cursor

  dec di        ; Step back position in string
  dec cx        ; Step back counter

  jmp .more


.nobackspace:
  pusha
  mov ah, 0Eh     ; Output entered, printable character
  int 10h
  popa

  mov byte[di], al
  inc di       ; Store character in designated buffer
  inc cx        ; Characters processed += 1
  cmp cx, 254     ; Make sure we don't exhaust buffer
  jae near .done

  jmp near .more      ; Still room for more


.done:
  mov ax, 0
  mov byte[di], al
  inc di
  popa
  ret

os_print_horiz_line:
  pusha

  mov cx, ax      ; Store line type param
  mov al, 196     ; Default is single-line code

  cmp cx, 1     ; Was double-line specified in AX?
  jne .ready
  mov al, 205     ; If so, here's the code

.ready:
  mov cx, 0     ; Counter
  mov ah, 0Eh     ; BIOS output char routine

.restart:
  int 10h
  inc cx
  cmp cx, 80      ; Drawn 80 chars yet?
  je .done
  jmp .restart

.done:
  popa
  ret

; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
  pusha

  mov bh, 0
  mov ah, 2
  int 10h       ; BIOS interrupt to move cursor

  popa
  ret


; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

os_get_cursor_pos:
  pusha

  mov bh, 0
  mov ah, 3
  int 10h       ; BIOS interrupt to get cursor position

  mov [.tmp], dx
  popa
  mov dx, [.tmp]
  ret


  .tmp dw 0

; ------------------------------------------------------------------
; os_int_to_string -- Convert unsigned integer to string
; IN: AX = signed int
; OUT: AX = string location

os_int_to_string:
  pusha
  mov cx, 0
  mov bx, 10      ; Set BX 10, for division and mod
  mov di, .t      ; Get our pointer ready

.push:
  mov dx, 0
  div bx        ; Remainder in DX, quotient in AX
  inc cx        ; Increase pop loop counter
  push dx       ; Push remainder, so as to reverse order when popping
  test ax, ax     ; Is quotient zero?
  jnz .push     ; If not, loop again
.pop:
  pop dx        ; Pop off values in reverse order, and add 48 to make them digits
  add dl, '0'     ; And save them in the string, increasing the pointer each time
  mov [di], dl
  inc di
  dec cx
  jnz .pop

  mov byte [di], 0    ; Zero-terminate string

  popa
  mov ax, .t      ; Return location of string
  ret

  .t times 5 db 0

  ; ------------------------------------------------------------------
; os_string_to_int -- Convert decimal string to integer value
; IN: SI = string location (max 5 chars, up to '65536')
; OUT: AX = number

os_string_to_int:
  pusha

  mov ax, si      ; First, get length of string
  call os_string_length

  add si, ax      ; Work from rightmost char in string
  dec si

  mov cx, ax      ; Use string length as counter

  mov bx, 0     ; BX will be the final number
  mov ax, 0


  ; As we move left in the string, each char is a bigger multiple. The
  ; right-most character is a multiple of 1, then next (a char to the
  ; left) a multiple of 10, then 100, then 1,000, and the final (and
  ; leftmost char) in a five-char number would be a multiple of 10,000

  mov word [.multiplier], 1 ; Start with multiples of 1

.loop:
  mov ax, 0
  mov byte al, [si]   ; Get character
  sub al, 48      ; Convert from ASCII to real number

  mul word [.multiplier]    ; Multiply by our multiplier

  add bx, ax      ; Add it to BX

  push ax       ; Multiply our multiplier by 10 for next char
  mov word ax, [.multiplier]
  mov dx, 10
  mul dx
  mov word [.multiplier], ax
  pop ax

  dec cx        ; Any more chars?
  cmp cx, 0
  je .finish
  dec si        ; Move back a char in the string
  jmp .loop

.finish:
  mov word [.tmp], bx
  popa
  mov word ax, [.tmp]

  ret


  .multiplier dw 0
  .tmp    dw 0


; ------------------------------------------------------------------
; os_string_parse -- Take string (eg "run foo bar baz") and return
; pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
; IN: SI = string; OUT: AX, BX, CX, DX = individual strings

os_string_parse:
	push si

	mov ax, si			; AX = start of first string

	mov bx, 0			; By default, other strings start empty
	mov cx, 0
	mov dx, 0

	push ax				; Save to retrieve at end

.loop1:
	lodsb				; Get a byte
	cmp al, 0			; End of string?
	je .finish
	cmp al, ' '			; A space?
	jne .loop1
	dec si
	mov byte [si], 0		; If so, zero-terminate this bit of the string

	inc si				; Store start of next string in BX
	mov bx, si

.loop2:					; Repeat the above for CX and DX...
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop2
	dec si
	mov byte [si], 0

	inc si
	mov cx, si

.loop3:
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop3
	dec si
	mov byte [si], 0

	inc si
	mov dx, si

.finish:
	pop ax

	pop si
	ret

; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

os_string_compare:
  pusha

.more:
  mov al, [si]      ; Retrieve string contents
  mov bl, [di]

  ; pusha
  ;   call print_char
  ;   mov al, bl
  ;   call print_char
  ; popa

  cmp al, bl      ; Compare characters at current location
  jne .not_same

  cmp al, 0     ; End of first string? Must also be end of second
  je .terminated

  inc si
  inc di
  jmp .more


.not_same:        ; If unequal lengths with same beginning, the byte
  popa        ; comparison fails at shortest string terminator
  clc       ; Clear carry flag
  ret


.terminated:        ; Both strings terminated at the same position
  popa
  stc       ; Set carry flag
  ret

; ------------------------------------------------------------------
; os_string_chomp -- Strip leading and trailing spaces from a string
; IN: AX = string location

os_string_chomp:
  pusha

  mov dx, ax      ; Save string location

  mov di, ax      ; Put location into DI
  mov cx, 0     ; Space counter

.keepcounting:        ; Get number of leading spaces into BX
  cmp byte [di], ' '
  jne .counted
  inc cx
  inc di
  jmp .keepcounting

.counted:
  cmp cx, 0     ; No leading spaces?
  je .finished_copy

  mov si, di      ; Address of first non-space character
  mov di, dx      ; DI = original string start

.keep_copying:
  mov al, [si]      ; Copy SI into DI
  mov [di], al      ; Including terminator
  cmp al, 0
  je .finished_copy
  inc si
  inc di
  jmp .keep_copying

.finished_copy:
  mov ax, dx      ; AX = original string start

  call os_string_length
  cmp ax, 0     ; If empty or all blank, done, return 'null'
  je .done

  mov si, dx
  add si, ax      ; Move to end of string

.more:
  dec si
  cmp byte [si], ' '
  jne .done
  mov byte [si], 0    ; Fill end spaces with 0s
  jmp .more     ; (First 0 will be the string terminator)

.done:
  popa
  ret

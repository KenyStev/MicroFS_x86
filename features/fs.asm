
; fs_get_drive_info:
;   mov ah, 8     ; Get drive parameters
;   int 13h
;   and cx, 3Fh     ; Maximum sector number
;   mov ax, cx  ; Sector numbers start at 1
;   call os_int_to_string
;   mov si, ax
;   call println
;   ret

; void save_info(unsigned int tail_block_ptr,
;   unsigned int head_block_ptr, unsigned int free_space,
;   unsigned int free_blocks)
save_info:
  push bp
  mov bp, sp

  ;reset whiteSpaces
  mov si, whiteSpace
  mov ax, info
  add ax, FREE_BLOCKS_OFFSET
  mov di, ax
  call os_string_copy

  mov si, whiteSpace
  mov ax, info
  add ax, FREE_SPACE_OFFSET
  mov di, ax
  call os_string_copy

  mov si, whiteSpace
  mov ax, info
  add ax, HEAD_BLOCK_OFFSET
  mov di, ax
  call os_string_copy

  mov si, whiteSpace
  mov ax, info
  add ax, TAIL_BLOCK_OFFSET
  mov di, ax
  call os_string_copy


  ; Copying Disk space into string
  mov ax, WORD [ARG(3)]
  call os_int_to_string
  mov si, ax
  mov di, info
  add di, FREE_BLOCKS_OFFSET
  call os_string_copy
; Copying Free blocks into string
  mov ax, WORD [ARG(2)]
  call os_int_to_string
  mov si, ax
  mov di, info
  add di, FREE_SPACE_OFFSET
  call os_string_copy
  ; Copying Head block into string
  mov ax, WORD [ARG(1)]
  call os_int_to_string
  mov si, ax
  mov di, info
  add di, HEAD_BLOCK_OFFSET
  call os_string_copy
  ; Copying Tail block into string
  mov ax, WORD [ARG(0)]
  call os_int_to_string
  mov si, ax
  mov di, info
  add di, TAIL_BLOCK_OFFSET
  call os_string_copy

  mov si, info
  xor di, di
  .writeBufferInMemory:
    lodsb
    stosb
    or al, al
    jnz .writeBufferInMemory
  .writeBufferInDrive:
    xor bx, bx
    mov ax, 20
    call disk_convert_l2hts
    push cx ; head
    push 1 ; count
    push ax ; sector
    push dx ; track
    call floppy.write
    add sp, 8
  .clearBuffer:
    xor di, di
    xor al, al
    mov cx, 0x72
    rep stosb

  pop bp
  ret

print_Info:
  .readFloppy:
    pusha
    xor bx, bx
    mov ax, 20
    call disk_convert_l2hts
    push cx ; head
    push 1 ; count
    push ax ; sector
    push dx ; track
    call floppy.read
    add sp, 8
  ; Buffer now contains dummy text, let's print it
    push ds
    mov ax, es
    mov ds, ax
    mov ax, bx
    mov si, ax
    call println

    pop ds
    popa

    ret

format:
  mov word[HEAD_BLOCK], 21
  mov word[TAIL_BLOCK], 21
  mov word[FREE_BLOCKS], 2859
  mov word[FREE_SPACE], 1430
  call os_print_newline
  mov si, msg1
  call println

  pusha
  mov word[block_index], 22
  mov ax, 0 ; iterator
  .loop:
    pusha

    mov ax, word[block_index]
    call os_int_to_string

    ;call os_wait_for_key

    mov si, ax
    xor di, di
    .writeBufferInMemory:
      lodsb
      stosb
      or al, al
      jnz .writeBufferInMemory
    .writeBufferInDrive:
      xor bx, bx
      mov ax, word[block_index]
      sub ax, 1
      call disk_convert_l2hts
      push cx ; head
      push 1 ; count
      push ax ; sector
      push dx ; track
      call floppy.write
      add sp, 8
    .clearBuffer:
      xor di, di
      xor al, al
      mov cx, 0x72
      rep stosb

      popa

      inc word[block_index]
      inc ax
      inc WORD[TAIL_BLOCK]
      cmp ax, 2858
      jne .loop
      writingLastBlock:
      ;writing null in the last block
      pusha

      mov si, null
      xor di, di
      .writeBufferInMemory:
        lodsb
        stosb
        or al, al
        jnz .writeBufferInMemory
      .writeBufferInDrive:
        xor bx, bx
        mov ax, word[TAIL_BLOCK]
        call disk_convert_l2hts
        push cx ; head
        push 1 ; count
        push ax ; sector
        push dx ; track
        call floppy.write
        add sp, 8
      .clearBuffer:
        xor di, di
        xor al, al
        mov cx, 0x72
        rep stosb
      popa

      mov ax, WORD[HEAD_BLOCK]
      mov bx, WORD[TAIL_BLOCK]
      sub bx, ax
      mov WORD [FREE_BLOCKS], bx
      push WORD[FREE_BLOCKS] ; free blocks
      push 1430 ; Free space
      push WORD[HEAD_BLOCK] ; Head block ptr
      push WORD[TAIL_BLOCK] ; Tail block ptr
      call save_info
      add sp, 8
  popa

  mov si, msg2
  call println
  ret

print_first_sector:
  .readFloppy:
    ;pusha
    xor bx, bx
    mov ax, WORD[HEAD_BLOCK]
    call disk_convert_l2hts
    push cx ; head
    push 1 ; count
    push ax ; sector
    push dx ; track
    call floppy.read
    add sp, 8
  ; Buffer now contains dummy text, let's print it
    push ds
    mov ax, es
    mov ds, ax
    mov ax, bx
    mov si, ax
    ;call println
    push si
    push di
    mov di, 0
    .loop:
      lodsb
      mov BYTE[.tmpTB+di], al
      inc di
      or al, al
      jz .done
      jmp .loop

    .done:
      pop di
      pop si
      mov si, .tmpTB
      call os_string_to_int
    pop ds
    ;popa
    call os_int_to_string
    mov si, ax
    ;call println
    ;call os_clear_screen
    ;call println
    call os_string_to_int
    ret
.tmpTB dw 0
.tmpTB2 times 5 db ' '

print_last_sector:
  .readFloppy:
    pusha
    xor bx, bx
    mov ax, WORD[TAIL_BLOCK]
    call disk_convert_l2hts
    push cx ; head
    push 1 ; count
    push ax ; sector
    push dx ; track
    call floppy.read
    add sp, 8
  ; Buffer now contains dummy text, let's print it
    push ds
    mov ax, es
    mov ds, ax
    mov ax, bx
    mov si, ax
    ;call println
    pop ds
    popa
    ret


  allocate_block:
    mov ax, word[HEAD_BLOCK]
    call os_int_to_string
    mov si, ax
    call println
    call print_first_sector
    mov WORD[HEAD_BLOCK], ax
    ;updating free blocks
    dec WORD[FREE_BLOCKS]
    mov ax, WORD[FREE_BLOCKS]
    ;ax = free_blocks
    mov bx, 512
    mul bx
    mov bx, 1024
    div bx
    mov WORD[FREE_SPACE], ax

    ; mov WORD[FREE_BLOCKS], ax
    ;updating free space
    ; mov ax,WORD[FREE_SPACE]
    ; sub ax, 1
    ;mov WORD[FREE_SPACE], ax
    ;SAVING INFO
    push WORD[FREE_BLOCKS] ; free blocks
    push WORD[FREE_SPACE] ; Free space
    push WORD[HEAD_BLOCK] ; Head block ptr
    push WORD[TAIL_BLOCK] ; Tail block ptr
    call save_info
    add sp, 8
    ret

deallocate_block:
  push bp
  mov bp, sp

  mov ax, WORD[ARG(0)]
  pusha
  ;UpdatingTailBlock(int block)
  updatingTail:
    call os_int_to_string
    mov si, ax
    xor di, di
    .writeBufferInMemory:
      lodsb
      stosb
      or al, al
      jnz .writeBufferInMemory
    .writeBufferInDrive:
      xor bx, bx
      mov ax, word[TAIL_BLOCK]
      call disk_convert_l2hts
      push cx ; head
      push 1 ; count
      push ax ; sector
      push dx ; track
      call floppy.write
      add sp, 8
    .clearBuffer:
      xor di, di
      xor al, al
      mov cx, 0x02
      rep stosb

    updatingNewTail:
      mov si, null
      xor di, di
      .writeBufferInMemory:
        lodsb
        stosb
        or al, al
        jnz .writeBufferInMemory
      .writeBufferInDrive:
        xor bx, bx
        mov ax, WORD[ARG(0)]
        call disk_convert_l2hts
        push cx ; head
        push 1 ; count
        push ax ; sector
        push dx ; track
        call floppy.write
        add sp, 8
      .clearBuffer:
        xor di, di
        xor al, al
        mov cx, 0x02
        rep stosb
  popa
  mov ax,WORD[FREE_BLOCKS]
  add ax, 1
  mov WORD[FREE_BLOCKS], ax
  ;updating free space
  mov ax,WORD[FREE_SPACE]
  sub ax, 1
  mov WORD[FREE_SPACE], ax
  ;updating TAIL_BLOCK variable
  mov ax, WORD[ARG(0)]
  mov word[TAIL_BLOCK], ax
  ;SAVING INFO
  push WORD[FREE_BLOCKS] ; free blocks
  push WORD[FREE_SPACE] ; Free space
  push WORD[HEAD_BLOCK] ; Head block ptr
  push WORD[TAIL_BLOCK] ; Tail block ptr
  call save_info
  add sp, 8
  call print_last_sector
  pop bp
  ret



info:
       DB 0x0D, 0x0A,'Disk space 1440 Kb'
       DB 0x0D, 0x0A,'Block size 512 B'
       DB 0x0D, 0x0A,'Free blocks '
       times 5 db ' '
       DB 0x0D, 0x0A,'Free space '
       times 5 db ' '
       DB 'kb',0x0D, 0x0A,'Head block '
       times 5 db ' '
       DB 0x0D, 0x0A,'Tail block '
       times 5 db ' '
       DB 0x00

msg1 db 0x0A,"writing linked blocks", 0
msg2 db 0x0A,"writing linked blocks finished", 0
null db '#',0x00
whiteSpace times 4 db ' ' 
db 0x00

FREE_BLOCKS_OFFSET equ 53
FREE_SPACE_OFFSET equ 71
HEAD_BLOCK_OFFSET equ 91
TAIL_BLOCK_OFFSET equ 109
block_index dw 22
HEAD_BLOCK dw 21
TAIL_BLOCK dw 21
FREE_BLOCKS dw 0
FREE_SPACE dw 1430

; *************************************** ;
;                 MACROS
; *************************************** ;

%define ARG(n) (bp + 2*(n + 2))

DRIVE equ 0
HEAD equ 0
RESET equ 00h
READ equ 02h
WRITE equ 03h
IO equ 13h
PRG_ADDR equ 0x1000
FREE_SECTORS equ 0x3800

; *************************************** ;
;               CONSTANTS
; *************************************** ;

CRLF: DB 0x0D, 0x0A, 0x00

; *************************************** ;
;               FUNCTIONS
; *************************************** ;

; Prints char located at register al
print_char:
  mov ah, 0x0E
  int 0x10
  ret

; Prints string located at ds:[si]
print:
  push si
  .loop:
    lodsb
    or al, al
    jz .done
    call print_char
    jmp .loop

  .done:
    pop si
    ret


; Prints string located at ds:[si] and adds new line
println:
  call print

  push si
  mov si, CRLF ;carriage return, line feed
  call print
  pop si

  ret


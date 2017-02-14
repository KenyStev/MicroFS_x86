; *************************************** ;
;                  boot.asm
; *************************************** ;

[ORG 0x7C00]
[BITS 16]

; *************************************** ;
;              BOOT ENTRY POINT
; *************************************** ;

start:
  cli
  xor ax, ax
  mov ds, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax

  mov sp, 0x7C00
  mov bp, sp

  mov ax, PRG_ADDR
  mov es, ax
  sti

main:
  xor bx, bx
  push 20 ; count
  push 2 ; sector
  push 0 ; track
  call floppy.read
  add sp, 6
  jmp 0x1000:0x00

; *************************************** ;
;               DATA SECTION
; *************************************** ;

msgLoading: DB 'Preparing to load AtomicFS', 0x00

; *************************************** ;
;               LIBRARIES
; *************************************** ;

%include "util.asm"
%include "floppy.asm"

; *************************************** ;
;              BOOT SIGNATURE
; *************************************** ;

TIMES 510-($-$$) DB 0
DW 0xAA55

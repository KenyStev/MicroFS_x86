; *************************************** ;
;              atomicfs.asm
; *************************************** ;

[ORG 0x10000]
[BITS 16]

; *************************************** ;
;            PROGRAM ENTRY POINT
; *************************************** ;

start:
  cli
  push cs
  pop ds

  mov ax, FREE_SECTORS
  mov es, ax

  sti

main:
  call os_clear_screen
  call os_print_horiz_line


  ;call print_Info

  call format

  call print_first_sector

  call os_print_newline

  call print_last_sector

  call os_print_newline

  call show_cli

  cli
  hlt


; *************************************** ;
;               DATA SECTION
; *************************************** ;

dummy:
       DB 'Lo logramos...con ayuda de Andres; '
       DB 'quiero variar el size del string, '
       DB 'hasta que ya no pueda caber!', 0x00

; *************************************** ;
;               LIBRARIES
; *************************************** ;

%include "features/util.asm"
%include "features/strings.asm"
%include "features/floppy.asm"
%include "features/keyboard.asm"
%include "features/cli.asm"
%include "features/fs.asm"

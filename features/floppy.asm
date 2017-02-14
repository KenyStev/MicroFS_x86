; void reset()
floppy:
  .reset:
    mov ah, RESET
    mov dl, DRIVE
    int IO
    jc .reset
    ret

  ; void read(unsigned int track, unsigned int sector, unsigned int count, unsigned int head)
  .read:
    push bp
    mov bp, sp

    call floppy.reset

    .sectorRead:
      mov ah, READ
      mov ch, BYTE [ARG(0)]
      mov cl, BYTE [ARG(1)]
      mov al, BYTE [ARG(2)]
      mov dh, BYTE [ARG(3)]
      mov dl, DRIVE
      int IO
      jc .sectorRead

    pop bp
    ret

  ; void write(unsigned int track, unsigned int sector, unsigned int count)
  .write:
    push bp
    mov bp, sp

    call floppy.reset

    .sectorWrite:
      mov ah, WRITE
      mov ch, BYTE [ARG(0)]
      mov cl, BYTE [ARG(1)]
      mov al, BYTE [ARG(2)]
      mov dh, BYTE [ARG(3)]
      mov dl, DRIVE
      int IO
      jc .sectorWrite

    pop bp
    ret

; --------------------------------------------------------------------------
; disk_convert_l2hts -- Calculate head, track and sector for int 13h
; IN: logical sector in AX; 
; OUT: BX=sector, CX=head, DX=track
 
disk_convert_l2hts:
  push bx
  mov bx, ax      ; Save logical sector
 
  mov dx, 0     ; First the sector
  div word [SecsPerTrack]   ; Sectors per track
  add dl, 01h     ; Physical sectors start at 1
  mov cl, dl      ; Sectors belong in CL for int 13h
  mov ax, bx
 
  mov dx, 0     ; Now calculate the head
  div word [SecsPerTrack]   ; Sectors per track
  mov dx, 0
  div word [Sides]    ; Floppy sides
  mov dh, dl      ; Head/side
  mov ch, al      ; Track

  mov word[.tmp], dx

  movzx dx, ch ; dx contains track
  movzx ax, cl ; bx contains sector
  mov cx, word[.tmp] ; cx contains head
 
 
; ******************************************************************
  ;mov dl, [bootdev]   ; Set correct device
; ******************************************************************
  pop bx
  ret

  .tmp dw 0
 
  Sides dw 2
  SecsPerTrack dw 18
  bootdev db 0
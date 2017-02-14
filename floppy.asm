; void reset()
floppy:
  .reset:
    mov ah, RESET
    mov dl, DRIVE
    int IO
    jc .reset
    ret

  ; void read(unsigned int track, unsigned int sector, unsigned int count)
  .read:
    push bp
    mov bp, sp

    call floppy.reset

    .sectorRead:
      mov ah, READ
      mov ch, BYTE [ARG(0)]
      mov cl, BYTE [ARG(1)]
      mov al, BYTE [ARG(2)]
      mov dh, 0
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
      mov dh, 0
      mov dl, DRIVE
      int IO
      jc .sectorWrite

    pop bp
    ret

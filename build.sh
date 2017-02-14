#!/bin/bash
nasm -f bin boot.asm -o boot.bin && \
nasm -f bin main.asm -o main.bin && \
dd if=/dev/zero of=floppy.img bs=512 count=2880 && \
dd if=boot.bin of=floppy.img bs=512 count=1 seek=0 conv=notrunc && \
dd if=main.bin of=floppy.img bs=512 count=20 seek=1 conv=notrunc && \
qemu-system-x86_64 -drive format=raw,file=floppy.img,index=0,if=floppy

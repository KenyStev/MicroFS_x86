show_cli:
	mov ax, buffer_input	;get user input
	call os_input_string

	mov si, CRLF
	call print

	mov si, buffer_input
	call os_string_parse

	mov si, cmd_allocate
	mov di, ax				;command name to compare
	call os_string_compare
	jc allocate

	mov si, cmd_format
	call os_string_compare
	jc format_disk

	mov si, cmd_free
	call os_string_compare
	jc free_block

	mov si, cmd_stats
	call os_string_compare
	jc show_stats

	jmp show_cli

allocate:
	call allocate_block
	jmp show_cli

format_disk:
	call format
	jmp show_cli

free_block:
	mov si, cmd_free
	mov si, bx				;block index
	call os_string_to_int	;convert to integer and stored in ax
	push ax
	call deallocate_block
	add sp, 2
	jmp show_cli

show_stats:
	call print_Info
	mov si, CRLF
	call print
	jmp show_cli

buffer_input: times 13 db 0
cmd_allocate: db "allocate", 0
cmd_format: db "format", 0
cmd_free: db "free", 0
cmd_stats: db "stats", 0

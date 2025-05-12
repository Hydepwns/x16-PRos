[BITS 16]

; Include required files
%include "src/lib/constants.inc"
%include "src/lib/ui.inc"

; Input buffer
section .bss
input_buffer: resb 128

; Error messages
section .data

error_messages:
    dw err_none_msg
    dw err_disk_read_msg
    dw err_disk_write_msg
    dw err_invalid_sect_msg
    dw err_invalid_clust_msg
    dw err_no_space_msg
    dw err_dir_full_msg
    dw err_file_exists_msg
    dw err_file_not_found_msg
    dw err_invalid_name_msg
    dw err_access_denied_msg
    dw err_bad_chain_msg
    dw err_invalid_size_msg
    dw err_buffer_overflow_msg
    dw err_invalid_attr_msg
    dw err_system_msg

; Error message strings
err_none_msg:           db "No error", 0
err_disk_read_msg:      db "Disk read error", 0
err_disk_write_msg:     db "Disk write error", 0
err_invalid_sect_msg:   db "Invalid sector number", 0
err_invalid_clust_msg:  db "Invalid cluster number", 0
err_no_space_msg:       db "No free space", 0
err_dir_full_msg:       db "Directory full", 0
err_file_exists_msg:    db "File already exists", 0
err_file_not_found_msg: db "File not found", 0
err_invalid_name_msg:   db "Invalid filename", 0
err_access_denied_msg:  db "Access denied", 0
err_bad_chain_msg:      db "Bad cluster chain", 0
err_invalid_size_msg:   db "Invalid file size", 0
err_buffer_overflow_msg: db "Buffer overflow", 0
err_invalid_attr_msg:   db "Invalid attributes", 0
err_system_msg:         db "System error", 0

; =============================================
; Input Routines
; =============================================

section .text

; Read a single character with echo
; Output:
;   - al: character read
read_char:
    mov ah, 00h
    int BIOS_KEYBOARD_INT
    ret

; Read a single character without echo
; Output:
;   - al: character read
read_char_silent:
    mov ah, 00h
    int BIOS_KEYBOARD_INT
    ret

; Read a string with backspace support
; Input:
;   - di: destination buffer
;   - cx: maximum length
; Output:
;   - di: points to end of string
;   - cx: remaining buffer space
read_string:
    push ax
    push bx
    push dx
    
    mov bx, 000Fh    ; White on black
    xor dx, dx       ; Start at (0,0)
    cld             ; Forward direction
    
.read_loop:
    call read_char
    
    cmp al, CHAR_ESCAPE
    je .exit
    
    cmp al, CHAR_BACKSPACE
    je .handle_backspace
    
    cmp al, CHAR_CARRIAGE_RETURN
    je .done
    
    ; Store character
    stosb
    
    ; Display character
    mov ah, 09h
    int BIOS_VIDEO_INT
    
    ; Move cursor
    call increment_cursor
    
    ; Check buffer space
    dec cx
    jnz .read_loop
    
.done:
    ; Null terminate
    xor al, al
    stosb
    
.exit:
    pop dx
    pop bx
    pop ax
    ret
    
.handle_backspace:
    ; Check if we're at start of buffer
    cmp di, input_buffer
    je .read_loop
    
    ; Remove character from buffer
    dec di
    
    ; Move cursor back
    call decrement_cursor
    
    ; Clear character
    mov al, CHAR_SPACE
    mov ah, 09h
    int BIOS_VIDEO_INT
    
    ; Move cursor back again
    call decrement_cursor
    
    ; Restore buffer space
    inc cx
    jmp .read_loop

; =============================================
; Output Routines
; =============================================

; Print a character
; Input:
;   - al: character to print
;   - bl: color
print_char:
    push ax
    push bx
    push cx
    
    mov ah, 09h
    mov cx, 1
    int BIOS_VIDEO_INT
    
    call increment_cursor
    
    pop cx
    pop bx
    pop ax
    ret

; Print a string
; Input:
;   - si: pointer to null-terminated string
;   - bl: color
print_string:
    push ax
    push bx
    push cx
    push si
    
.print_loop:
    lodsb
    test al, al
    jz .done
    
    mov ah, 09h
    mov cx, 1
    int BIOS_VIDEO_INT
    
    call increment_cursor
    jmp .print_loop
    
.done:
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Print a number
; Input:
;   - ax: number to print
;   - bl: color
print_number:
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0       ; Digit counter
    
.convert_loop:
    mov dx, 0
    mov bx, 10
    div bx          ; Divide by 10
    push dx         ; Save remainder (digit)
    inc cx
    test ax, ax
    jnz .convert_loop
    
.print_loop:
    pop ax
    add al, '0'     ; Convert to ASCII
    call print_char
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print a hex number
; Input:
;   - ax: number to print
;   - bl: color
print_hex:
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 4       ; 4 hex digits
    
.print_loop:
    rol ax, 4       ; Rotate left 4 bits
    mov dx, ax
    and dx, 0x000F  ; Get lowest 4 bits
    add dl, '0'     ; Convert to ASCII
    cmp dl, '9'
    jbe .print_digit
    add dl, 'A'-'0'-10  ; Adjust for A-F
    
.print_digit:
    mov al, dl
    call print_char
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print a newline character
; Input:
;   - bl: color
print_newline:
    push ax
    mov al, CHAR_CARRIAGE_RETURN
    call print_char
    mov al, CHAR_LINEFEED
    call print_char
    pop ax
    ret

; Print a space character
; Input:
;   - bl: color
print_space:
    push ax
    mov al, CHAR_SPACE
    call print_char
    pop ax
    ret

; =============================================
; Error Handling
; =============================================

; Display error message
; Input:
;   - al: error code
display_error:
    push ax
    push bx
    push cx
    push dx
    
    ; Convert error code to message index
    movzx bx, al
    shl bx, 1       ; Multiply by 2 (word size)
    
    ; Get error message
    mov si, [error_messages + bx]
    
    ; Display at error position
    mov dl, 0
    mov dh, UI_OUTPUT_START_Y
    call set_cursor_pos
    
    mov bl, COLOR_LIGHT_RED
    call print_string
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret 

global print_string
global print_char
global print_hex
global print_newline
global print_space

[BITS 16]

%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/utils.inc"

section .text

; Load program from disk
load_program:
    mov si, load_prompt
    call print_string
    call read_number  ; Read sector number
    call print_newline
    call start_program
    ret

; Read number from keyboard
read_number:
    mov di, number_buffer
    xor cx, cx
.read_loop:
    mov ah, 0x00
    int BIOS_KEYBOARD_INT
    cmp al, 0x0D      ; Check for Enter
    je .done_read
    cmp al, 0x08      ; Check for Backspace
    je .handle_backspace
    cmp cx, 5         ; Maximum number length (5 digits)
    jge .read_loop    ; If max length reached, ignore input
    cmp al, '0'       ; Check if character is a digit
    jb .read_loop
    cmp al, '9'
    ja .read_loop
    stosb             ; Store character in buffer
    mov ah, 0x0E      ; Print character
    mov bl, 0x1F
    int BIOS_VIDEO_INT
    inc cx            ; Increment character counter
    jmp .read_loop

.handle_backspace:
    cmp cx, 0         ; If buffer is empty, ignore backspace
    je .read_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int BIOS_VIDEO_INT
    mov al, ' '       ; Print space to erase character
    int BIOS_VIDEO_INT
    mov al, 0x08      ; Move cursor back again
    int BIOS_VIDEO_INT
    jmp .read_loop

.done_read:
    mov byte [di], 0  ; Null-terminate string
    ret

; Start program from specified sector
start_program:
    pusha
    mov ah, 0x02      ; Read sector function
    mov al, 1         ; Number of sectors to read
    mov ch, 0         ; Track number (cylinder)
    mov dh, 0         ; Head number
    mov cl, [sector_number]  ; Sector number
    mov bx, 800h      ; Load address
    int 0x13
    jc .disk_error    ; If error, handle it
    jmp 800h          ; Jump to loaded program
    popa
    ret

.disk_error:
    mov si, disk_error_msg
    call print_string_red
    popa
    ret

section .data
    load_prompt db 'Enter sector number: ', 0
    disk_error_msg db 'Disk read error!', 0
    number_buffer db 6 dup(0)
    sector_number dw 0 

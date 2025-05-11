[BITS 16]

%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/utils.inc"

section .data
    prompt db "x16-PRos> ", 0
    command_buffer times COMMAND_BUFFER_SIZE db 0

    ; Command strings
    help_str db "help", 0
    info_str db "info", 0
    cls_str db "cls", 0
    CPU_str db "CPU", 0
    date_str db "date", 0
    time_str db "time", 0
    shut_str db "shut", 0
    reboot_str db "reboot", 0
    writer_str db "writer", 0
    brainf_str db "brainf", 0

section .text

; Initialize shell
shell_init:
    mov si, prompt
    call print_string_white
    ret

; Main shell loop
shell_run:
    call read_command
    call print_command_buffer
    call print_newline
    call execute_command
    jmp shell_run

; Read command from keyboard
read_command:
    mov di, command_buffer
    xor cx, cx          ; Clear character counter
.read_loop:
    mov ah, 0x00
    int BIOS_KEYBOARD_INT            ; Wait for keypress, result in AL
    mov ah, al          ; Save character in AH for later use
    
    ; Echo character in default color
    mov ah, 0x0E
    mov bl, COLOR_WHITE        ; White color
    int BIOS_VIDEO_INT
    
    ; Debug: print key in cyan
    mov ah, 0x0E
    mov bl, COLOR_LIGHT_CYAN        ; Cyan color
    int BIOS_VIDEO_INT
    
    mov al, ah          ; Restore character from AH
    
    cmp al, CHAR_CARRIAGE_RETURN        ; Enter?
    je .done_read
    cmp al, CHAR_BACKSPACE        ; Backspace?
    je .handle_backspace
    
    ; Check for printable characters
    cmp al, CHAR_SPACE         ; Space is lowest printable ASCII
    jb .read_loop
    cmp al, '~'         ; Tilde is highest printable ASCII
    ja .read_loop
    
    ; Check buffer limit
    cmp cx, COMMAND_BUFFER_SIZE-1         ; Buffer limit
    jae .read_loop
    
    ; Store character and increment counter
    stosb
    inc cx
    jmp .read_loop

.handle_backspace:
    cmp cx, 0           ; If buffer is empty, ignore backspace
    je .read_loop
    
    ; Move cursor back
    mov ah, 0x0E
    mov bl, COLOR_WHITE        ; White color
    mov al, CHAR_BACKSPACE        ; Backspace
    int BIOS_VIDEO_INT
    mov al, CHAR_SPACE         ; Space
    int BIOS_VIDEO_INT
    mov al, CHAR_BACKSPACE        ; Backspace again
    int BIOS_VIDEO_INT
    
    ; Update buffer position and counter
    dec di
    dec cx
    jmp .read_loop

.done_read:
    mov byte [di], 0    ; Null-terminate
    
    ; Trim trailing spaces
    mov di, command_buffer
    add di, cx
.trim_trailing:
    dec di
    cmp di, command_buffer
    jb .set_zero
    mov al, [di]
    cmp al, CHAR_SPACE
    je .trim_trailing
.set_zero:
    mov byte [di+1], 0
    ret

; Execute command from buffer
execute_command:
    mov si, command_buffer
    ; Check command "help"
    mov di, help_str
    call compare_strings
    je do_help
    
    mov si, command_buffer
    ; Check command "info"
    mov di, info_str
    call compare_strings
    je print_OS_info

    mov si, command_buffer
    ; Check command "cls"
    mov di, cls_str
    call compare_strings
    je do_cls
    
    mov si, command_buffer
    ; Check command "CPU"
    mov di, CPU_str
    call compare_strings
    je do_CPUinfo
    
    mov si, command_buffer
    ; Check command "date"
    mov di, date_str
    call compare_strings
    je print_date
    
    mov si, command_buffer
    ; Check command "time"
    mov di, time_str
    call compare_strings
    je print_time

    mov si, command_buffer
    ; Check command "shut"
    mov di, shut_str
    call compare_strings
    je do_shutdown
    
    mov si, command_buffer
    ; Check command "reboot"
    mov di, reboot_str
    call compare_strings
    je do_reboot
   
    mov si, command_buffer
    ; Check command "writer"
    mov di, writer_str
    call compare_strings
    je start_writer
    
    mov si, command_buffer
    ; Check command "brainf"
    mov di, brainf_str
    call compare_strings
    je start_brainf
    
    ; Unknown command
    mov si, unknown_cmd
    call print_string_red
    ret

; Command handlers
do_help:
    call print_help
    ret

print_OS_info:
    call print_interface
    ret

do_cls:
    call clear_screen
    ret

do_CPUinfo:
    call print_CPU_info
    ret

print_date:
    call get_date
    ret

print_time:
    call get_time
    ret

do_shutdown:
    call shutdown
    ret

do_reboot:
    call reboot
    ret

start_writer:
    call launch_writer
    ret

start_brainf:
    call launch_brainf
    ret 

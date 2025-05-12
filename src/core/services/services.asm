[BITS 16]

%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/utils.inc"

section .text

global print_interface
global print_help
global print_CPU_info
global get_date
global get_time
global shutdown
global reboot
global launch_writer
global launch_brainf
global clear_screen

; Print system interface
print_interface:
    mov si, header
    print_string_white
    mov si, info
    print_string_green
    mov si, menu
    print_string_green
    ret

; Print help menu
print_help:
    mov si, menu
    print_string_green
    call print_newline
    ret

; Print CPU information
print_CPU_info:
    mov si, cpu_info
    print_string_cyan
    ret

; Get and print current date
get_date:
    mov ah, BIOS_GET_DATE
    int BIOS_INT
    mov si, date_format
    print_string_white
    ret

; Get and print current time
get_time:
    mov ah, BIOS_GET_TIME
    int BIOS_INT
    mov si, time_format
    print_string_white
    ret

; Shutdown system
shutdown:
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    ret

; Reboot system
reboot:
    int 0x19
    ret

; Launch text editor
launch_writer:
    mov ax, WRITER_ORG
    jmp ax
    ret

; Launch Brainfuck interpreter
launch_brainf:
    mov ax, BRAINF_ORG
    jmp ax
    ret

; Clear screen
clear_screen:
    mov ax, 0x03      ; BIOS: Set 80x25 text mode (clears screen)
    int 0x10
    ret

section .data
    header db "x16-PRos Operating System", 0
    info db "Type 'help' for available commands", 0
    menu db "help - Show this menu", 13, 10, \
            "info - Show system info", 13, 10, \
            "cls  - Clear screen", 13, 10, \
            "CPU  - Show CPU info", 13, 10, \
            "date - Show current date", 13, 10, \
            "time - Show current time", 13, 10, \
            "shut - Shutdown system", 13, 10, \
            "reboot - Reboot system", 13, 10, \
            "writer - Launch text editor", 13, 10, \
            "brainf - Launch Brainfuck interpreter", 0
    
    cpu_info db "CPU: 8086/8088", 13, 10, \
              "Mode: Real Mode", 13, 10, \
              "Architecture: x86", 0
    
    date_format db "DD/MM/YY", 0
    time_format db "HH:MM:SS", 0 

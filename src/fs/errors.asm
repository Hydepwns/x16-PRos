[BITS 16]

; Include guard
%ifndef ERRORS_INCLUDED
%define ERRORS_INCLUDED

%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/error_codes.inc"

; Error codes
ERR_NONE equ 0x00
ERR_DISK_READ equ 0x01
ERR_DISK_WRITE equ 0x02
ERR_INVALID_PARAM equ 0x03
ERR_NOT_FOUND equ 0x04
ERR_ALREADY_EXISTS equ 0x05
ERR_INVALID_ATTR equ 0x06
ERR_INVALID_SIZE equ 0x07
ERR_INVALID_CLUSTER equ 0x08
ERR_INVALID_FILENAME equ 0x09
ERR_DIR_FULL equ 0x0A
ERR_FAT_FULL equ 0x0B
ERR_NO_SPACE equ 0x0C

; Error messages
section .data
error_messages:
    dw msg_none
    dw msg_disk_read
    dw msg_disk_write
    dw msg_invalid_param
    dw msg_not_found
    dw msg_already_exists
    dw msg_invalid_attr
    dw msg_invalid_size
    dw msg_invalid_cluster
    dw msg_invalid_filename
    dw msg_dir_full
    dw msg_fat_full
    dw msg_no_space

msg_none: db "No error", 0
msg_disk_read: db "Disk read error", 0
msg_disk_write: db "Disk write error", 0
msg_invalid_param: db "Invalid parameter", 0
msg_not_found: db "File not found", 0
msg_already_exists: db "File already exists", 0
msg_invalid_attr: db "Invalid attributes", 0
msg_invalid_size: db "Invalid file size", 0
msg_invalid_cluster: db "Invalid cluster", 0
msg_invalid_filename: db "Invalid filename", 0
msg_dir_full: db "Directory full", 0
msg_fat_full: db "FAT full", 0
msg_no_space: db "No space left", 0

; Error handling functions
section .text
global set_error
global get_error
global print_error
extern print_string

; Set error code
; Input:
;   - al: error code
set_error:
    mov [error_code], al
    ret

; Get error code
; Output:
;   - al: error code
get_error:
    mov al, [error_code]
    ret

; Print error message
; Input:
;   - al: error code
print_error:
    push ax
    push bx
    push si

    ; Get error message pointer
    xor ah, ah
    shl ax, 1       ; Multiply by 2 (word size)
    mov si, error_messages
    add si, ax
    mov si, [si]    ; Get message pointer

    ; Print message
    call print_string

    pop si
    pop bx
    pop ax
    ret

; Data section
section .data
error_code: db 0

%endif ; ERRORS_INCLUDED 
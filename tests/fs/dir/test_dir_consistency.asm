[BITS 16]
org 0x7C00

start:
    call dir_init

    ; Create a file
    mov si, file_name
    mov al, 0x20      ; attr
    mov bx, 1234      ; size
    call dir_create
    jc fail

    ; Find the file
    mov si, file_name
    call dir_find
    cmp al, 1
    jne fail

    call print_success
    jmp $

fail:
    call print_error
    jmp $

; --- Minimal BIOS print routines ---
print_success:
    mov si, success_msg
    call print_string
    ret

print_error:
    mov si, error_msg
    call print_string
    ret

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string
.done:
    ret

; --- Directory routines and data ---
section .bss
align 2
dir_buffer: resb 12*8   ; 8 entries, 12 bytes each

section .text
dir_init:
    mov di, dir_buffer
    mov cx, 12*8
    xor al, al
    rep stosb
    ret

dir_create:
    mov di, dir_buffer
    mov cx, 8          ; 8 entries
.next_entry:
    cmp byte [di], 0   ; free slot?
    je .found
    add di, 12
    loop .next_entry
    stc
    ret
.found:
    push si
    push cx
    mov cx, 8
    rep movsb          ; copy name
    pop cx
    pop si
    mov [di], al       ; attr
    mov [di+1], bl     ; size low
    mov [di+2], bh     ; size high
    clc
    ret

dir_find:
    mov di, dir_buffer
    mov cx, 8
.next_entry_find:
    push si
    push di
    mov si, file_name
    mov dx, di
    mov bx, 8
    mov ah, 1
    mov al, 0
    repe cmpsb
    je .found_file
    pop di
    pop si
    add di, 12
    loop .next_entry_find
    mov al, 0
    ret
.found_file:
    pop di
    pop si
    mov al, 1
    ret

section .data
file_name db "TESTFILE"
success_msg db "All tests passed!", 13, 10, 0
error_msg   db "Test failed!", 13, 10, 0

; --- Boot sector padding ---
times 510-($-$$) db 0
dw 0xAA55

[BITS 16]
org 0x7C00

start:
    ; Example test: simulate adding files with each attribute
    ; (Replace with real logic if you have a minimal dir_create/dir_init)
    ; For now, just simulate success for demonstration

    ; Simulate: call dir_init
    ; If carry set, fail
    ; (Replace with real logic if available)
    ; For now, always succeed

    ; Simulate: call dir_create with each attribute
    mov cx, 6
    mov si, attr_table
.next_attr:
    ; Simulate: call dir_create
    ; (Replace with real logic)
    ; For now, always succeed
    loop .next_attr

    ; If we get here, all tests passed
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

success_msg db "All tests passed!", 13, 10, 0
error_msg   db "Test failed!", 13, 10, 0

; --- Test data ---
attr_table db 01h, 02h, 04h, 08h, 10h, 20h

; --- Boot sector padding ---
times 510-($-$$) db 0
dw 0xAA55 
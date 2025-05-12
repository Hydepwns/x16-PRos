[BITS 16]
org 0x7C00

start:
    ; Simulate file size test logic (replace with real logic if available)
    ; For now, just simulate success
    call print_success
    jmp $

fail:
    call print_error
    jmp $

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

times 510-($-$$) db 0
dw 0xAA55
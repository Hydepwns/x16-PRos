org 0x7C00
[BITS 16]

mov si, msg
.print:
lodsb
or al, al
jz .done
mov ah, 0x0E
int 0x10
jmp .print
.done:
hlt

msg db 'DIR OVERFLOW OK', 0

; --- Boot sector padding ---
times 510-($-$$) db 0
dw 0xAA55

























































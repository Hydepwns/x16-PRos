%ifndef UTILS
%define UTILS

; Compare two Strings (case-insensitive)
; si - 1st string
; di - 2nd string
; Returns: ZF=1 if equal, ZF=0 if not equal
; Preserves: ax, cx, dx
compare_strings:
    push ax
    push cx
    push dx
    xor cx, cx
.next_char:
    lodsb
    mov ah, [di]
    ; Convert both to lowercase if uppercase
    cmp al, 'A'
    jb .no_upper1
    cmp al, 'Z'
    ja .no_upper1
    or al, 0x20
.no_upper1:
    cmp ah, 'A'
    jb .no_upper2
    cmp ah, 'Z'
    ja .no_upper2
    or ah, 0x20
.no_upper2:
    cmp al, ah
    jne .not_equal
    test al, al
    jz .equal
    inc di
    jmp .next_char
.not_equal:
    xor ax, ax    ; Clear ZF
    jmp .done
.equal:
    xor ax, ax    ; Set ZF
    inc ax
.done:
    pop dx
    pop cx
    pop ax
    ret

; Convert String to Number
; si - input string
; Returns: ax = number
; Preserves: cx, dx, si, di
string_to_number:
    push cx
    push dx
    push si
    push di
    xor ax, ax
    xor cx, cx
.convert_loop:
    lodsb
    test al, al
    jz .done_convert
    sub al, '0'
    imul cx, 10
    add cx, ax
    jmp .convert_loop
.done_convert:
    mov ax, cx
    pop di
    pop si
    pop dx
    pop cx
    ret

; Convert ASCII string to number
; si - pointer to string
; Returns: ax = number
; Preserves: bx, cx, dx, si
utils_convert_to_number:
    push bx
    push cx
    push dx
    push si
    xor ax, ax
    xor bx, bx
    mov cl, 10
.loop:
    mov bl, [si]
    test bl, bl
    jz .done
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    sub bl, '0'
    mul cl
    add ax, bx
    inc si
    jmp .loop
.done:
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Convert number to ASCII string
; ax - number to convert
; di - pointer to buffer
; Returns: di = pointer to end of string
; Preserves: ax, bx, cx, dx
number_to_string:
    push ax
    push bx
    push cx
    push dx
    mov bx, 10
    mov cx, 0
.loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .loop
.loop2:
    pop ax
    add al, '0'
    stosb
    loop .loop2
    mov byte [di], 0
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Set cursor position
; dh - row
; dl - column
; Preserves: ax, cx, dx, si, di
%ifndef UI_INCLUDED
extern set_cursor_pos
%endif

%endif

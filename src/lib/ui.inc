; =============================================
; x16-PRos UI Library
; =============================================

%ifndef UI_INCLUDED
%define UI_INCLUDED

%include "src/lib/constants.inc"

; =============================================
; Common UI Routines
; =============================================

; Display a message at a specific position
; Input: 
;   - bp: pointer to message
;   - cx: message length
;   - dl: x position
;   - dh: y position
;   - bl: color
display_message:
    mov ax, 1301h
    int BIOS_VIDEO_INT
    ret

; Display helper message at top of screen
; Input:
;   - bp: pointer to message
;   - cx: message length
display_helper:
    mov dl, 0
    mov dh, 0
    mov bl, COLOR_WHITE
    call display_message
    ret

; Display footer message at bottom of screen
; Input:
;   - bp: pointer to message
;   - cx: message length
display_footer:
    mov dl, 0
    mov dh, SCREEN_HEIGHT-1
    mov bl, COLOR_WHITE
    call display_message
    ret

; Display separator line
; Input:
;   - dh: y position
display_separator:
    push ax
    push bx
    push cx
    push dx
    
    mov dl, 0
    mov ah, 02h
    int BIOS_VIDEO_INT
    
    mov cx, SCREEN_WIDTH
    mov al, '-'
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, COLOR_WHITE
.separator_loop:
    int BIOS_VIDEO_INT
    loop .separator_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Clear screen with specific color
; Input:
;   - bl: color
clear_screen_color:
    push ax
    push bx
    push cx
    push dx
    
    mov ax, 0600h
    xor cx, cx
    mov dx, 184Fh
    int BIOS_VIDEO_INT
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Set cursor position
; Input:
;   - dl: x position
;   - dh: y position
set_cursor_pos:
    mov ah, 02h
    int BIOS_VIDEO_INT
    ret

; Increment cursor position
; Input:
;   - dl: current x position
;   - dh: current y position
; Output:
;   - dl: new x position
;   - dh: new y position
increment_cursor:
    inc dl
    cmp dl, SCREEN_WIDTH
    jne .no_newline
    xor dl, dl
    inc dh
.no_newline:
    mov ah, 02h
    int BIOS_VIDEO_INT
    ret

; Decrement cursor position
; Input:
;   - dl: current x position
;   - dh: current y position
; Output:
;   - dl: new x position
;   - dh: new y position
decrement_cursor:
    test dl, 0FFh
    jnz .no_newline
    dec dh
    mov dl, SCREEN_WIDTH
.no_newline:
    dec dl
    mov ah, 02h
    int BIOS_VIDEO_INT
    ret

%endif ; UI_INCLUDED 
%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/ui.inc"
%include "src/lib/memory.inc"
%include "src/lib/app.inc"

[BITS 16]
[ORG SNAKE_ORG]

; =============================================
; Snake Game
; A simple snake game implementation
; =============================================

start:
setup:
    xor eax, eax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x800
    
init:
    mov di, clockticks
    stosd
    stosd
    mov ax, (SCREEN_WIDTH*SCREEN_HEIGHT)/2
    stosw
    add al, 4
    stosw
    add al, 4
    stosw
    mov al, 0xFF
    out 0x60, al
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    
screen:
    mov ax, VIDEO_MEMORY_SEG
    mov es, ax
    mov ax, VIDEO_MODE_TEXT
    int BIOS_VIDEO_INT
    inc ah
    mov cx, 0x2000
    int BIOS_VIDEO_INT
    xor di, di
    mov cx, (SCREEN_WIDTH*SCREEN_HEIGHT)/2
    mov ax, (COLOR_YELLOW << 8) | CHAR_SPACE
    pusha
    rep stosw
    
.messages:
    mov di, GAME_MSG_NAME_POS
    mov si, msg_name
    call print
    mov si, msg_score
    mov di, GAME_MSG_SCORE_POS
    call print
    mov si, msg_controls
    mov di, GAME_MSG_CONTROLS_POS
    call print
    
.rect:
    mov ax, GAME_BORDER_CHAR
    mov cx, GAME_BORDER_WIDTH
    mov di, GAME_BORDER_START
    rep stosw
    mov cx, GAME_BORDER_HEIGHT
.rect_loop:
    stosw
    pusha
    mov cx, 41
    xor ah, ah
    rep stosw
    mov ah, 2
    stosw
    popa
    add di, SCREEN_WIDTH-2
    loop .rect_loop
    mov cx, GAME_BORDER_WIDTH
    mov di, GAME_BORDER_END
    rep stosw

game:
.setup:
    popa
    mov di, cx
    mov si, init_snake
    call print
    mov bp, 6
    call place_food
    
.delay:
    xor eax, eax
    int BIOS_TIME_INT
    mov ax, cx
    shl eax, 16
    mov ax, dx
    mov ebx, eax
    sub eax, [clockticks]
    cmp eax, GAME_FRAME_DELAY
    jl .delay
    mov [clockticks], ebx
    in al, 0x60
    
.direction:
    cmp al, GAME_KEY_NEW
    je start
    cmp al, CHAR_ESCAPE
    je esc_exit
    and al, 0x7F
    cmp al, GAME_KEY_UP
    je .up
    cmp al, GAME_KEY_LEFT
    je .left
    cmp al, GAME_KEY_DOWN
    je .down
    cmp al, GAME_KEY_RIGHT
    jne .delay

.right:
    mov al, GAME_DIR_RIGHT
    add di, 4
    jmp .move
    
.up:
    mov al, GAME_DIR_UP
    sub di, SCREEN_WIDTH
    jmp .move

.down:
    mov al, GAME_DIR_DOWN
    add di, SCREEN_WIDTH
    jmp .move
    
.left:
    mov al, GAME_DIR_LEFT
    sub di, 4
    
.move:    
    cmp byte [es:di], GAME_FOOD_CHAR
    sete ah
    je .nofail
    cmp byte [es:di], CHAR_SPACE
    jne .fail
    
.nofail:
    stosb
    dec di
    pusha
    push es
    push ds
    pop es
    mov cx, bp
    inc cx
    mov si, snake
    add si, bp
    mov di, si
    inc di
    inc di
    std
    rep movsb
    cld
    pop es
    popa
    push di
    mov [snake], di
    mov di, [snake+2]
    mov al, GAME_SNAKE_CHAR
    stosb
    cmp ah, 1
    je .food
    mov di, [snake+bp]
    mov al, CHAR_SPACE
    stosb
    jmp .done
    
.food:
    inc bp
    inc bp
    mov di, GAME_SCORE_DISPLAY
    add word [score], GAME_SCORE_INCREMENT
    mov ax, [score]
    mov bl, 10
.printscore_loop:
    div bl
    xchg al, ah
    add al, '0'
    stosb
    dec di
    dec di
    dec di
    mov al, ah
    xor ah, ah
    or al, al
    jnz .printscore_loop
    call place_food
.done:
    pop di
    jmp .delay

.fail:
    mov di, GAME_MSG_FAIL_POS
    mov si, msg_fail
    call print
.fail_wait:
    in al, 0x60
    cmp al, GAME_KEY_NEW
    jne .check_esc_fail
    jmp start
.check_esc_fail:
    cmp al, CHAR_ESCAPE
    jne .fail_wait
    jmp esc_exit

place_food:
    pusha
.seed:
    xor eax, eax
    xor bl, bl
    int BIOS_TIME_INT
.random:
    cmp bl, GAME_FOOD_RETRIES
    jg .seed
    mov ax, dx
    mov cx, GAME_FOOD_MULTIPLIER
    mul cx
    movzx edx, dx
    mov ecx, GAME_FOOD_DIVISOR
    div ecx
    mov ax, dx
    shr edx, 16
    mov ecx, (SCREEN_WIDTH*SCREEN_HEIGHT)
    div cx
    and dl, 0xFC
    inc bl
    cmp dx, GAME_MIN_FOOD_Y
    jl .random
    mov di, dx
    cmp byte [es:di], CHAR_SPACE
    jne .random
    mov al, GAME_FOOD_CHAR
    stosb
    popa
    ret
    
print:
    pusha
.loop:
    lodsb
    or al, al
    jz .done
    stosb
    inc di
    jmp .loop
.done:
    popa
    ret

esc_exit:
    mov ax, VIDEO_MODE_VGA
    int BIOS_VIDEO_INT
    int 0x19

; =============================================
; Data Section
; =============================================
section .data
    clockticks dd 0, 0
    score dw 0
    snake times GAME_SNAKE_BUFFER_SIZE dw 0
    msg_name db 'Snake Game', 0
    msg_score db 'Score:', 0
    msg_controls db 'WASD to move, N for new game, ESC to exit', 0
    msg_fail db 'Game Over! Press N for new game or ESC to exit', 0
    init_snake db '>', 0

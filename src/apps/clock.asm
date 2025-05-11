%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/ui.inc"
%include "src/lib/memory.inc"
%include "src/lib/app.inc"

[bits 16]
[org CLOCK_ORG]

jmp start

; =============================================
; Data Section
; =============================================
section .data
    ; Clock state
    current_hour db 0
    current_minute db 0
    current_second db 0
    current_date db 0
    current_month db 0
    current_year db 0
    is_12h_format db 0
    is_pm db 0

    ; Display settings
    foreground_color db COLOR_WHITE
    background_color db COLOR_BLACK

    ; Messages
    msg_12h db "12h", 0
    msg_24h db "24h", 0
    msg_pm db "PM", 0
    msg_am db "AM", 0

    ; Digit segment patterns (7-segment display)
    digit_patterns:
        dw 0x3F  ; 0
        dw 0x06  ; 1
        dw 0x5B  ; 2
        dw 0x4F  ; 3
        dw 0x66  ; 4
        dw 0x6D  ; 5
        dw 0x7D  ; 6
        dw 0x07  ; 7
        dw 0x7F  ; 8
        dw 0x6F  ; 9

    date_str db "DD/MM/YY", 0

; =============================================
; Code Section
; =============================================
section .text
start:
    ; Initialize segments
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, CLOCK_STACK_SEG

    ; Clear screen and hide cursor
    call clear_screen
    mov dx, CLOCK_CURSOR_HIDE
    call set_cursor_position

    ; Main loop
main_loop:
    ; Check for key press
    mov ah, BIOS_KB_CHECK
    int BIOS_INT
    jz update_display

    ; Handle key press
    mov ah, BIOS_KB_READ
    int BIOS_INT

    ; Process key
    cmp al, CLOCK_KEY_FG
    je cycle_foreground
    cmp al, CLOCK_KEY_BG
    je cycle_background
    cmp al, CLOCK_KEY_12H
    je toggle_12h_format
    jmp update_display

cycle_foreground:
    inc byte [foreground_color]
    and byte [foreground_color], 0x0F
    jmp update_display

cycle_background:
    inc byte [background_color]
    and byte [background_color], 0x0F
    jmp update_display

toggle_12h_format:
    not byte [is_12h_format]
    jmp update_display

update_display:
    ; Get current time
    mov ah, BIOS_GET_TIME
    int BIOS_INT

    ; Store time
    mov [current_hour], ch
    mov [current_minute], cl
    mov [current_second], dh

    ; Get current date
    mov ah, BIOS_GET_DATE
    int BIOS_INT

    ; Store date
    mov [current_date], dl
    mov [current_month], dh
    mov [current_year], cx

    ; Update display
    call draw_clock
    call draw_date

    ; Wait for next update
    mov cx, CLOCK_UPDATE_DELAY
    mov dx, CLOCK_UPDATE_DELAY_L
    mov ah, BIOS_WAIT
    int BIOS_INT

    jmp main_loop

; =============================================
; Display Functions
; =============================================
draw_clock:
    ; Draw hour tens
    mov al, [current_hour]
    shr al, 4
    and al, CLOCK_BCD_MASK
    mov bx, CLOCK_HOUR_TENS_POS
    call draw_digit

    ; Draw hour ones
    mov al, [current_hour]
    and al, CLOCK_BCD_MASK
    mov bx, CLOCK_HOUR_ONES_POS
    call draw_digit

    ; Draw minute tens
    mov al, [current_minute]
    shr al, 4
    and al, CLOCK_BCD_MASK
    mov bx, CLOCK_MIN_TENS_POS
    call draw_digit

    ; Draw minute ones
    mov al, [current_minute]
    and al, CLOCK_BCD_MASK
    mov bx, CLOCK_MIN_ONES_POS
    call draw_digit

    ; Draw dots
    call draw_dots

    ; Draw 12/24h indicator
    cmp byte [is_12h_format], 0
    je .draw_24h
    mov si, msg_12h
    jmp .draw_indicator
.draw_24h:
    mov si, msg_24h
.draw_indicator:
    mov dx, CLOCK_DATE_POS
    call print_string

    ; Draw AM/PM if in 12h mode
    cmp byte [is_12h_format], 0
    je .done
    mov si, msg_am
    cmp byte [is_pm], 0
    je .draw_ampm
    mov si, msg_pm
.draw_ampm:
    mov dx, CLOCK_DATE_POS
    add dx, 4
    call print_string
.done:
    ret

draw_dots:
    ; Draw first dot pair
    mov bx, CLOCK_DOT1_POS
    call draw_dot_pair

    ; Draw second dot pair
    mov bx, CLOCK_DOT2_POS
    call draw_dot_pair

    ; Draw third dot pair
    mov bx, CLOCK_DOT3_POS
    call draw_dot_pair

    ; Draw fourth dot pair
    mov bx, CLOCK_DOT4_POS
    call draw_dot_pair
    ret

draw_dot_pair:
    push bx
    mov cx, CLOCK_DOT_WIDTH
    mov al, [foreground_color]
    call draw_horizontal_line
    pop bx
    add bx, CLOCK_LINE_SPACING
    push bx
    mov cx, CLOCK_DOT_WIDTH
    mov al, [foreground_color]
    call draw_horizontal_line
    pop bx
    ret

draw_digit:
    ; Draw digit segments based on value in al
    ; Uses lookup table for segment patterns
    push bx
    mov si, digit_patterns
    movzx ax, al
    shl ax, 1
    add si, ax
    mov ax, [si]
    pop bx

    ; Draw each segment
    test ax, 1
    jz .skip_segment1
    push bx
    mov cx, CLOCK_DIGIT_WIDTH
    mov al, [foreground_color]
    call draw_horizontal_line
    pop bx
.skip_segment1:
    add bx, CLOCK_DIGIT_SPACING

    test ax, 2
    jz .skip_segment2
    push bx
    mov cx, CLOCK_DIGIT_WIDTH
    mov al, [foreground_color]
    call draw_horizontal_line
    pop bx
.skip_segment2:
    add bx, CLOCK_DIGIT_SPACING

    test ax, 4
    jz .skip_segment3
    push bx
    mov cx, CLOCK_DIGIT_HEIGHT
    mov al, [foreground_color]
    call draw_vertical_line
    pop bx
.skip_segment3:
    add bx, CLOCK_DIGIT_WIDTH

    test ax, 8
    jz .skip_segment4
    push bx
    mov cx, CLOCK_DIGIT_HEIGHT
    mov al, [foreground_color]
    call draw_vertical_line
    pop bx
.skip_segment4:
    add bx, CLOCK_DIGIT_SPACING

    test ax, 16
    jz .skip_segment5
    push bx
    mov cx, CLOCK_DIGIT_WIDTH
    mov al, [foreground_color]
    call draw_horizontal_line
    pop bx
.skip_segment5:
    add bx, CLOCK_DIGIT_SPACING

    test ax, 32
    jz .skip_segment6
    push bx
    mov cx, CLOCK_DIGIT_HEIGHT
    mov al, [foreground_color]
    call draw_vertical_line
    pop bx
.skip_segment6:
    add bx, CLOCK_DIGIT_WIDTH

    test ax, 64
    jz .skip_segment7
    push bx
    mov cx, CLOCK_DIGIT_HEIGHT
    mov al, [foreground_color]
    call draw_vertical_line
    pop bx
.skip_segment7:
    ret

draw_date:
    ; Convert date components to ASCII
    mov al, [current_date]
    call bcd_to_ascii
    mov [date_str], al
    mov [date_str+1], ah

    mov al, [current_month]
    call bcd_to_ascii
    mov [date_str+3], al
    mov [date_str+4], ah

    mov ax, [current_year]
    call bcd_to_ascii
    mov [date_str+6], al
    mov [date_str+7], ah

    ; Print date string
    mov si, date_str
    mov dx, CLOCK_DATE_POS
    add dx, 8
    call print_string
    ret

; =============================================
; Helper Functions
; =============================================
bcd_to_ascii:
    ; Convert BCD number in al to ASCII
    mov ah, al
    and al, CLOCK_BCD_MASK
    add al, '0'
    shr ah, 4
    and ah, CLOCK_BCD_MASK
    add ah, '0'
    ret

times 510-($-$$) db 0
dw 0xAA55

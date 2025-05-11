%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/ui.inc"
%include "src/lib/memory.inc"
%include "src/lib/app.inc"
%include "src/lib/utils.inc"

[BITS 16]
[ORG CALC_ORG]
jmp start

; =============================================
; Calculator
; A simple calculator implementation
; =============================================

start:
    pusha
    mov ax, VIDEO_MODE_TEXT
    int BIOS_VIDEO_INT
    popa
    
    mov dl, 0 
    mov dh, 0
    call set_cursor_pos

    mov bp, wmsg
    mov cx, SCREEN_WIDTH
    call print_message
    
    call print_newline
    call calc_cycle
    ret
    
calc_cycle:
    mov ax, [step]
    cmp ax, CALC_STEP_INPUT1
    je .step0            ; Input first number
    cmp ax, CALC_STEP_INPUT2
    je .step1            ; Input second number
    cmp ax, CALC_STEP_OPERATION
    je .step2            ; Select operation
    cmp ax, CALC_STEP_RESULT
    je .step3            ; Print result
    
    mov si, quit_msg
    call print_string_green
    call print_newline
    ; Check exit
    mov ah, 10h
    int BIOS_KEYBOARD_INT
    
    cmp al, CHAR_ESCAPE
    jz .end_cycle
    
    mov al, CALC_STEP_INPUT1
    mov [step], al
    
    jmp calc_cycle
    
.end_cycle:
    int 0x19 
    ret
    
; STEP0 - First Number
.step0:
    mov si, inpn1
    call print_string

    mov si, input_buffer
    mov bx, CALC_MAX_NUMBERS
    call scan_string
    call print_newline
    
    mov di, input_buffer
    mov bx, num1
    call convert_to_number
    
    mov al, [step]
    inc al
    mov [step], al
    
    jmp calc_cycle

; STEP1 - Second Number
.step1:
    mov si, inpn2
    call print_string

    mov si, input_buffer
    mov bx, CALC_MAX_NUMBERS
    call scan_string
    call print_newline
    
    mov di, input_buffer
    mov bx, num2
    call convert_to_number
    
    mov al, [step]
    inc al
    mov [step], al
    
    jmp calc_cycle

; STEP2 - Operation Select
.step2:
    mov si, select_mode
    call print_string_green

    mov si, input_buffer
    mov bx, CALC_MAX_NUMBERS
    call scan_string
    call print_newline
    
    mov di, input_buffer
    mov bx, mode
    call convert_to_number
    
    mov al, [step]
    inc al
    mov [step], al
    
    jmp calc_cycle

; STEP3 - Result
.step3:
    mov si, result_prompt
    call print_string
    
    mov ax, [mode]
    cmp ax, CALC_OP_ADD
    je .mode_1
    cmp ax, CALC_OP_SUB
    je .mode_2
    cmp ax, CALC_OP_MUL
    je .mode_3
    cmp ax, CALC_OP_DIV
    je .mode_4
    
    jmp .mode_err

.mode_1:
    mov ax, [num1]
    mov bx, [num2]
    add ax, bx
    mov di, result_str
    call convert_to_string
    
    mov si, result_str
    call print_string
    call print_newline
    mov si, idk
    call print_string_green
    call print_newline
    jmp .step3_end
    
.mode_2:
    mov ax, [num1]
    mov bx, [num2]
    sub ax, bx
    mov di, result_str
    call convert_to_string
    
    mov si, result_str
    call print_string
    call print_newline
    mov si, idk
    call print_string_green
    call print_newline
    jmp .step3_end
    
.mode_3:
    mov ax, [num1]
    mov bx, [num2]
    mul bx
    mov di, result_str
    call convert_to_string
    
    mov si, result_str
    call print_string
    call print_newline
    mov si, idk
    call print_string_green
    call print_newline
    jmp .step3_end
    
.mode_4:
    xor dx, dx
    mov ax, [num1]
    mov bx, [num2]
    div bx
    mov di, result_str
    call convert_to_string
    
    mov si, result_str
    call print_string_cyan
    call print_newline
    mov si, idk
    call print_string_green
    call print_newline
    jmp .step3_end

.mode_err:
    mov si, error_mode_msg
    call print_string_red
    
    jmp .step3_end

.step3_end:
    mov al, [step]
    inc al
    mov [step], al

    jmp calc_cycle

; =============================================
; Data Section
; =============================================
section .data
    wmsg db 'PRos calculator v0.1', CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 0
    inpn1 db "Enter a first num: ", 0
    inpn2 db "Enter a second num: ", 0
    result_prompt db "Result: ", 0
    idk db "==========================", 0
    quit_msg db "Press: ", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
             db "ESC - exit", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
             db "Any key - continue", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
             db 0
    select_mode db "Select operation:", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
                db "1 - add", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
                db "2 - sub", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
                db "3 - mul", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
                db "4 - div", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN
                db 0
    error_mode_msg db "Unknown operation", CHAR_LINEFEED, CHAR_CARRIAGE_RETURN, 0

    mode resw 1
    step resw 1
    input_buffer db CALC_INPUT_SIZE dup(0)
    num1 resw 1
    num2 resw 1
    result_str db CALC_RESULT_SIZE dup(0)


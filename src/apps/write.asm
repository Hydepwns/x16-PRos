%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/ui.inc"
%include "src/lib/memory.inc"
%include "src/lib/app.inc"
%include "src/lib/utils.inc"

[BITS 16]
[ORG WRITE_ORG]

; =============================================
; Text Editor
; A simple text editor implementation
; =============================================

start:
    ; Очистка экрана
    mov ax, 0600h
    mov bh, COLOR_WHITE
    xor cx, cx
    mov dx, 184Fh
    int BIOS_VIDEO_INT
    
    mov ax, VIDEO_MODE_TEXT
    int BIOS_VIDEO_INT
    
    mov dl, 0
    mov dh, 0
    call set_cursor_pos

    mov bp, helper
    mov cx, UI_MSG_HELPER_LEN
    call print_message_white
    
    mov dl, 0
    mov dh, SCREEN_HEIGHT-1
    call set_cursor_pos

    mov bp, msg
    mov cx, UI_MSG_FOOTER_LEN
    call print_message_white
    
    mov dl, 0
    mov dh, 17
    call set_cursor_pos
    
    mov si, hr
    call print_string
    
    ; Start input
    jmp getInput

getInput:
    ; Setup for input
    mov bx, 000Fh
    mov cx, 1
    xor dx, dx
    cld
    mov di, sectorEnd
    mov ah, 02h
    mov dh, UI_INPUT_START_Y
    int BIOS_VIDEO_INT

.read_char:
    mov ah, 00h
    int BIOS_KEYBOARD_INT
    
    cmp al, CHAR_ESCAPE
    jz esc_exit

    cmp al, CHAR_BACKSPACE
    je .handle_backspace

    stosb

    cmp al, CHAR_CARRIAGE_RETURN
    je allocateWorkspace

    mov ah, 09h
    int BIOS_VIDEO_INT

    call incrementCursor
    jmp .read_char

.handle_backspace:
    dec di
    call decrementCursor
    mov al, CHAR_SPACE
    mov ah, 09h
    int BIOS_VIDEO_INT
    jmp .read_char

allocateWorkspace:
    mov word [programCounter], sectorEnd
    mov [dataPointer], di
    mov cx, BF_WORKSPACE_SIZE
    mov al, 0
.loop:
    stosb
    dec cx
    jnz .loop

runCode:
    mov bx, 000Fh
    mov cx, 1
    mov dl, 0
    mov ah, 02h
    mov dh, UI_OUTPUT_START_Y
    int BIOS_VIDEO_INT
    dec word [programCounter]

.next_instruction:
    inc word [programCounter]
    movzx eax, word [programCounter]
    cmp byte [eax], BF_INSTR_INC_PTR
    je .inc_data_ptr
    cmp byte [eax], BF_INSTR_DEC_PTR
    je .dec_data_ptr
    cmp byte [eax], BF_INSTR_INC_VAL
    je .inc_cell
    cmp byte [eax], BF_INSTR_DEC_VAL
    je .dec_cell
    cmp byte [eax], BF_INSTR_OUTPUT
    je .out_cell
    cmp byte [eax], BF_INSTR_INPUT
    je .in_cell
    cmp byte [eax], BF_INSTR_LOOP_START
    je .jump_forward
    cmp byte [eax], BF_INSTR_LOOP_END
    je .jump_backward

.error:
    mov ah, 00h
    int BIOS_KEYBOARD_INT
    jmp getInput

.inc_data_ptr:
    inc word [dataPointer]
    jmp .next_instruction

.dec_data_ptr:
    dec word [dataPointer]
    jmp .next_instruction

.inc_cell:
    movzx eax, word [dataPointer]
    inc byte [eax]
    jmp .next_instruction

.dec_cell:
    movzx eax, word [dataPointer]
    dec byte [eax]
    jmp .next_instruction

.out_cell:
    movzx eax, word [dataPointer]
    mov al, [eax]
    mov ah, 09h
    int BIOS_VIDEO_INT
    call incrementCursor
    jmp .next_instruction

.in_cell:
    mov ah, 00h
    int BIOS_KEYBOARD_INT
    mov ah, 09h
    int BIOS_VIDEO_INT
    mov cl, al
    call incrementCursor
    movzx eax, word [dataPointer]
    mov [eax], cl
    mov cx, 1
    jmp .next_instruction

.jump_forward:
    movzx eax, word [dataPointer]
    mov al, [eax]
    test al, 0FFh
    jnz .next_instruction
    mov cx, 1
.jump_forward_loop:
    inc word [programCounter]
    movzx eax, word [programCounter]
    cmp byte [eax], BF_INSTR_LOOP_START
    jne .jump_forward_loop_no_open
    inc cx
.jump_forward_loop_no_open:
    cmp byte [eax], BF_INSTR_LOOP_END
    jne .jump_forward_loop_no_close
    dec cx
.jump_forward_loop_no_close:
    test cx, 0FFh
    jnz .jump_forward_loop
    mov cx, 1
    jmp .next_instruction

.jump_backward:
    movzx eax, word [dataPointer]
    mov al, [eax]
    test al, 0FFh
    jz .next_instruction
    mov cx, 1
.jump_backward_loop:
    dec word [programCounter]
    movzx eax, word [programCounter]
    cmp byte [eax], BF_INSTR_LOOP_END
    jne .jump_backward_loop_no_close
    inc cx
.jump_backward_loop_no_close:
    cmp byte [eax], BF_INSTR_LOOP_START
    jne .jump_backward_loop_no_open
    dec cx
.jump_backward_loop_no_open:
    test cx, 0FFh
    jnz .jump_backward_loop
    mov cx, 1
    jmp .next_instruction

incrementCursor:
    inc dl
    cmp dl, SCREEN_WIDTH
    jne .no_newline
    xor dl, dl
    inc dh
.no_newline:
    mov ah, 02h
    int BIOS_VIDEO_INT
    ret

decrementCursor:
    test dl, 0FFh
    jnz .no_newline
    dec dh
    mov dl, SCREEN_WIDTH
.no_newline:
    dec dl
    mov ah, 02h
    int BIOS_VIDEO_INT
    ret

; =============================================
; Data Section
; =============================================
section .data
    programCounter dw 0
    dataPointer dw 0
    helper db 'Type your brainfuck code and press Enter to run it. Press ESC to exit.', 13, 10, 0
    msg db 'PRos brainf v0.1', 13, 10, 0
    hr db '--------------------------------------------------------------------------------', 0

sectorEnd:

get_user_input:
    mov di, input_buffer
    mov cx, INPUT_BUFFER_SIZE
    call read_input_with_newline
    ret

clear_screen:
    call clear_screen_color
    ret

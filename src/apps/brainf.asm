; ==================================
; "Hello, world!" program example:
; ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
; ==================================

%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/ui.inc"
%include "src/lib/memory.inc"
%include "src/lib/app.inc"
%include "src/lib/utils.inc"

[BITS 16]
[ORG BRAINF_ORG]

section .data
    app_title    db "PRos Brainfuck Interpreter", 0
    app_version  db "v0.1", 0
    app_helper   db "Type your brainf code and press Enter to run it. Press ESC to exit.", 0
    app_footer   db "PRos brainf v0.1                                                               ", 0

section .bss
    app_context: resb APP_CTX_size

section .text
start:
    ; Initialize application
    mov ax, cs
    mov es, ax
    mov di, app_context
    mov si, app_title
    mov ax, app_version
    call init_app
    
    ; Display application header
    call display_app_header
    
    ; Run application
    call run_app
    
    ; Exit application
    call exit_app

; Process application input
process_app_input:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Get input buffer
    push di
    add di, APP_CTX.input_buffer
    mov si, di
    
    ; Process input
    mov word [programCounter], si
    call allocateWorkspace
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Update application display
update_app_display:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Run brainfuck code
    call runCode
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

allocateWorkspace:
    ; Allocate workspace
    mov cx, BF_WORKSPACE_SIZE
    call allocate_memory
    test ax, ax
    jz .allocation_failed
    mov [dataPointer], ax
    
    ; Clear workspace
    mov es, ax
    xor di, di
    mov cx, BF_WORKSPACE_SIZE
    xor al, al
    call clear_buffer
    
    ret
    
.allocation_failed:
    mov al, ERR_SYSTEM
    call display_error
    ret

runCode:
    mov dl, 0
    mov dh, UI_OUTPUT_START_Y
    call set_cursor_pos
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
    mov al, ERR_SYSTEM
    call display_error
    call read_char
    ret

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
    mov bl, COLOR_WHITE
    call print_char
    jmp .next_instruction

.in_cell:
    call read_char
    mov bl, COLOR_WHITE
    call print_char
    movzx eax, word [dataPointer]
    mov [eax], al
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
    jmp .next_instruction

dataPointer:
    dw 0
programCounter:
    dw 0

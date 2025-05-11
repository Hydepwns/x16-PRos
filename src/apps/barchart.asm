%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/ui.inc"
%include "src/lib/memory.inc"
%include "src/lib/app.inc"

[BITS 16]
[ORG BAR_CHART_ORG]

start:
    call clear_screen
    call draw_interface
    call get_user_input
    call parse_input
    call draw_diagram
    call wait_for_key
    jmp exit

draw_interface:
    mov si, welcome_msg
    call print_string
    mov si, input_prompt
    call print_string
    ret

get_user_input:
    mov di, input_buffer
    mov cx, INPUT_BUFFER_SIZE
    call read_input_with_newline
    ret

parse_input:
    mov si, input_buffer
    mov di, data_buffer
    mov cx, 0
    
.parse_loop:
    call skip_spaces
    cmp byte [si], 0
    je .done
    call parse_number
    jc .done
    cmp al, 200
    ja .parse_loop
    stosb
    inc cx
    cmp cx, 20
    je .done
    jmp .parse_loop

.done:
    mov [data_count], cx
    ret

skip_spaces:
    mov al, [si]
    cmp al, CHAR_SPACE
    jne .done
    inc si
    jmp skip_spaces
.done:
    ret

parse_number:
    mov si, input_buffer
    call convert_to_number
    ret

draw_diagram:
    mov ah, 0x0C
    mov al, COLOR_WHITE
    mov cx, 10
    mov dx, 450
    
.draw_x_axis:
    int BIOS_VIDEO_INT
    inc cx
    cmp cx, 600
    jle .draw_x_axis
    
    mov cx, 10
    mov dx, 40
.draw_y_axis:
    int BIOS_VIDEO_INT
    inc dx
    cmp dx, 450
    jle .draw_y_axis

    mov cx, [data_count]
    cmp cx, 0
    je .done
    
    mov si, data_buffer
    mov bx, 50
    
.draw_bar:
    lodsb
    mov ah, 0
    mov di, ax
    shl di, 1
    
    mov ah, 0x0C
    mov al, COLOR_YELLOW
    push cx
    push bx
    
    mov cx, bx
    add bx, 25
    
.width_loop:
    mov dx, 450
    sub dx, di
    cmp dx, 40
    jge .height_loop
    mov dx, 40
    
.height_loop:
    int BIOS_VIDEO_INT
    inc dx
    cmp dx, 450
    jl .height_loop
    
    inc cx
    cmp cx, bx
    jl .width_loop
    
    pop bx
    pop cx
    add bx, 35
    loop .draw_bar
    
.done:
    ret

wait_for_key:
    mov ah, 0x00
    int BIOS_KEYBOARD_INT
    ret

exit:
    int 0x19

welcome_msg    db '-PRos Bar Chart Program v0.1-', CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 0
input_prompt   db 'Enter numbers (0-200, use space between, Enter to finish): ', 0
input_buffer   db 51 dup(0)
data_buffer    db 20 dup(0)
data_count     dw 0

times 510-($-$$) db 0
dw 0xAA55

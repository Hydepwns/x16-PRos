; =============================================
; x16-PRos Application Framework Library
; =============================================

%ifndef APP_INCLUDED
%define APP_INCLUDED

%include "src/lib/constants.inc"
%include "src/lib/ui.inc"
%include "src/lib/io.inc"
%include "src/lib/memory.inc"

; =============================================
; Application States
; =============================================
APP_STATE_INIT      equ 0    ; Initialization
APP_STATE_RUNNING   equ 1    ; Main application loop
APP_STATE_PAUSED    equ 2    ; Application paused
APP_STATE_EXIT      equ 3    ; Application exit

; =============================================
; Application Structure
; =============================================
struc APP_CTX
    .state          resw 1   ; Current application state
    .title          resb 32  ; Application title
    .version        resb 8   ; Application version
    .helper_msg     resb 82  ; Helper message
    .footer_msg     resb 80  ; Footer message
    .input_buffer   resb 128 ; Input buffer
    .output_buffer  resb 128 ; Output buffer
    .error_code     resb 1   ; Last error code
    .flags          resb 1   ; Application flags
endstruc

; =============================================
; Application Initialization
; =============================================

; Initialize application context
; Input:
;   - es:di: pointer to APP_CTX structure
;   - ds:si: pointer to title string
;   - ax: version number
; Output:
;   - es:di: initialized context
init_app:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Clear context
    mov cx, APP_CTX_size
    xor al, al
    cld
    rep stosb
    
    ; Reset pointer to start of context
    sub di, APP_CTX_size
    
    ; Set initial state
    mov word [es:di + APP_CTX.state], APP_STATE_INIT
    
    ; Copy title
    push di
    add di, APP_CTX.title
    mov cx, 31
    cld
.copy_title:
    lodsb
    test al, al
    jz .title_done
    stosb
    loop .copy_title
.title_done:
    pop di
    
    ; Set version
    mov [es:di + APP_CTX.version], ax
    
    ; Initialize memory system
    mov ax, di
    add ax, APP_CTX_size
    mov bx, 0xFFFF
    call init_memory
    
    ; Clear screen and set video mode
    mov bl, COLOR_WHITE
    call clear_screen_color
    mov ax, VIDEO_MODE_TEXT
    int BIOS_VIDEO_INT
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; Application Display
; =============================================

; Display application header
; Input:
;   - es:di: pointer to APP_CTX structure
display_app_header:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Display title
    mov dl, 0
    mov dh, 0
    call set_cursor_pos
    
    push di
    add di, APP_CTX.title
    mov si, di
    mov bl, COLOR_WHITE
    call print_string
    pop di
    
    ; Display version
    mov dl, 40
    mov dh, 0
    call set_cursor_pos
    
    push di
    add di, APP_CTX.version
    mov si, di
    mov bl, COLOR_LIGHT_GRAY
    call print_string
    pop di
    
    ; Display helper message
    mov dl, 0
    mov dh, 1
    call set_cursor_pos
    
    push di
    add di, APP_CTX.helper_msg
    mov si, di
    mov bl, COLOR_WHITE
    call print_string
    pop di
    
    ; Display footer
    mov dl, 0
    mov dh, SCREEN_HEIGHT-1
    call set_cursor_pos
    
    push di
    add di, APP_CTX.footer_msg
    mov si, di
    mov bl, COLOR_WHITE
    call print_string
    pop di
    
    ; Display separator
    mov dh, UI_MSG_SEPARATOR_POS / SCREEN_WIDTH
    call display_separator
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; Application Input/Output
; =============================================

; Get application input
; Input:
;   - es:di: pointer to APP_CTX structure
; Output:
;   - al: last character read
;   - ZF: set if ESC pressed
get_app_input:
    push bx
    push cx
    push dx
    
    ; Set input position
    mov dl, 0
    mov dh, UI_INPUT_START_Y
    call set_cursor_pos
    
    ; Read input
    push di
    add di, APP_CTX.input_buffer
    mov cx, INPUT_BUFFER_SIZE
    call read_string
    pop di
    
    ; Check for ESC
    cmp al, CHAR_ESCAPE
    je .esc_pressed
    
    ; Store in context
    mov [es:di + APP_CTX.error_code], al
    
.esc_pressed:
    pop dx
    pop cx
    pop bx
    ret

; Display application output
; Input:
;   - es:di: pointer to APP_CTX structure
;   - ds:si: output string
display_app_output:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Set output position
    mov dl, 0
    mov dh, UI_OUTPUT_START_Y
    call set_cursor_pos
    
    ; Display output
    mov bl, COLOR_WHITE
    call print_string
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; Application Control
; =============================================

; Run application main loop
; Input:
;   - es:di: pointer to APP_CTX structure
run_app:
    push ax
    push bx
    push cx
    push dx
    
    ; Set initial state
    mov word [es:di + APP_CTX.state], APP_STATE_RUNNING
    
.main_loop:
    ; Check state
    cmp word [es:di + APP_CTX.state], APP_STATE_EXIT
    je .exit
    
    ; Get input
    call get_app_input
    jz .exit
    
    ; Process input
    call process_app_input
    
    ; Update display
    call update_app_display
    
    jmp .main_loop
    
.exit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Process application input (to be implemented by application)
; Input:
;   - es:di: pointer to APP_CTX structure
process_app_input:
    ret

; Update application display (to be implemented by application)
; Input:
;   - es:di: pointer to APP_CTX structure
update_app_display:
    ret

; =============================================
; Application Exit
; =============================================

; Exit application
; Input:
;   - es:di: pointer to APP_CTX structure
exit_app:
    push ax
    push bx
    push cx
    push dx
    
    ; Set exit state
    mov word [es:di + APP_CTX.state], APP_STATE_EXIT
    
    ; Restore video mode
    mov ax, VIDEO_MODE_VGA
    int BIOS_VIDEO_INT
    
    ; Reboot system
    int 0x19
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

%endif ; APP_INCLUDED 
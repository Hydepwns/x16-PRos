[BITS 16]

; Include error handling and constants
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"
%include "src/lib/io.inc"

; External symbols
extern print_hex
extern print_newline
extern print_string
extern set_error
extern get_error
extern print_error

; Interrupt Handling Functions
section .text

; Initialize interrupt handling
; Input: None
; Output: None
interrupts_init:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Clear interrupt vector table
    xor ax, ax
    mov es, ax
    xor di, di
    mov cx, 256 * 4    ; 256 interrupts * 4 bytes each
    xor al, al
    rep stosb

    ; Set up default interrupt handlers
    mov ax, 0
    mov es, ax

    ; Set up exception handlers (0-31)
    mov di, 0 * 4
    mov ax, exception_handler
    mov [es:di], ax
    mov ax, cs
    mov [es:di + 2], ax

    ; Set up IRQ handlers (32-47)
    mov di, 32 * 4
    mov ax, irq_handler
    mov [es:di], ax
    mov ax, cs
    mov [es:di + 2], ax

    ; Set up software interrupt handlers (48-255)
    mov di, 48 * 4
    mov ax, software_interrupt_handler
    mov [es:di], ax
    mov ax, cs
    mov [es:di + 2], ax

    ; Initialize PIC
    call init_pic

    mov al, ERR_NONE
    call set_error

    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Initialize Programmable Interrupt Controller (PIC)
; Input: None
; Output: None
init_pic:
    push ax

    ; ICW1: Initialize PIC
    mov al, 0x11        ; ICW1: Edge triggered, cascade mode, ICW4 needed
    out 0x20, al        ; Master PIC
    out 0xA0, al        ; Slave PIC

    ; ICW2: Set interrupt vector offsets
    mov al, 0x20        ; Master PIC interrupts start at 0x20
    out 0x21, al
    mov al, 0x28        ; Slave PIC interrupts start at 0x28
    out 0xA1, al

    ; ICW3: Set up cascade
    mov al, 0x04        ; Slave PIC at IRQ2
    out 0x21, al
    mov al, 0x02        ; Slave PIC cascade identity
    out 0xA1, al

    ; ICW4: Set 8086 mode
    mov al, 0x01        ; 8086 mode
    out 0x21, al
    out 0xA1, al

    ; Mask all interrupts except cascade
    mov al, 0xFB        ; Enable IRQ2 (cascade) only
    out 0x21, al
    mov al, 0xFF        ; Disable all slave interrupts
    out 0xA1, al

    pop ax
    ret

; Register interrupt handler
; Input: AL = interrupt number
;       BX = handler address
; Output: None
register_handler:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Check if interrupt number is valid
    cmp al, 255
    ja .error

    ; Calculate vector table offset
    xor ah, ah
    mov cl, 2
    shl ax, cl          ; Multiply by 4
    mov di, ax

    ; Set handler address
    xor ax, ax
    mov es, ax
    mov [es:di], bx     ; Offset
    mov ax, cs
    mov [es:di + 2], ax ; Segment

    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_INTERRUPT_INVALID
    call set_error

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Enable interrupt
; Input: AL = interrupt number
; Output: None
enable_interrupt:
    push ax
    push bx
    push cx
    push dx

    ; Check if interrupt number is valid
    cmp al, 15
    ja .error

    ; Calculate bit mask
    mov cl, al
    mov al, 1
    shl al, cl
    not al

    ; Update PIC mask
    cmp cl, 8
    jae .slave_pic
    in al, 0x21         ; Read master PIC mask
    and al, bl          ; Clear bit
    out 0x21, al        ; Write back
    jmp .done

.slave_pic:
    sub cl, 8
    mov al, 1
    shl al, cl
    not al
    in al, 0xA1         ; Read slave PIC mask
    and al, bl          ; Clear bit
    out 0xA1, al        ; Write back

.done:
    mov al, ERR_NONE
    call set_error
    jmp .exit

.error:
    mov al, ERR_INTERRUPT_INVALID
    call set_error

.exit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Disable interrupt
; Input: AL = interrupt number
; Output: None
disable_interrupt:
    push ax
    push bx
    push cx
    push dx

    ; Check if interrupt number is valid
    cmp al, 15
    ja .error

    ; Calculate bit mask
    mov cl, al
    mov al, 1
    shl al, cl

    ; Update PIC mask
    cmp cl, 8
    jae .slave_pic
    in al, 0x21         ; Read master PIC mask
    or al, bl           ; Set bit
    out 0x21, al        ; Write back
    jmp .done

.slave_pic:
    sub cl, 8
    mov al, 1
    shl al, cl
    in al, 0xA1         ; Read slave PIC mask
    or al, bl           ; Set bit
    out 0xA1, al        ; Write back

.done:
    mov al, ERR_NONE
    call set_error
    jmp .exit

.error:
    mov al, ERR_INTERRUPT_INVALID
    call set_error

.exit:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Exception handler
; Input: None
; Output: None
exception_handler:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    ; Print exception message
    mov si, exception_msg
    call print_string
    mov al, [esp + 16]  ; Get exception number
    call print_hex
    call print_newline

    ; Print register state
    call print_registers

    ; Halt system
    cli
    hlt

; IRQ handler
; Input: None
; Output: None
irq_handler:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    ; Get IRQ number
    mov al, [esp + 16]
    sub al, 32          ; Adjust for IRQ offset

    ; Call appropriate handler
    mov bx, irq_handlers
    mov cl, 2
    mul cl
    add bx, ax
    call [bx]

    ; Send EOI to PIC
    cmp al, 8
    jae .slave_pic
    mov al, 0x20
    out 0x20, al        ; Master PIC EOI
    jmp .done

.slave_pic:
    mov al, 0x20
    out 0xA0, al        ; Slave PIC EOI
    out 0x20, al        ; Master PIC EOI

.done:
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret

; Software interrupt handler
; Input: None
; Output: None
software_interrupt_handler:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    ; Get interrupt number
    mov al, [esp + 16]

    ; Call appropriate handler
    mov bx, sw_handlers
    mov cl, 2
    mul cl
    add bx, ax
    call [bx]

    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret

; Print register state
; Input: None
; Output: None
print_registers:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Print AX
    mov si, reg_ax_msg
    call print_string
    mov ax, [esp + 8]
    call print_hex
    call print_newline

    ; Print BX
    mov si, reg_bx_msg
    call print_string
    mov ax, [esp + 6]
    call print_hex
    call print_newline

    ; Print CX
    mov si, reg_cx_msg
    call print_string
    mov ax, [esp + 4]
    call print_hex
    call print_newline

    ; Print DX
    mov si, reg_dx_msg
    call print_string
    mov ax, [esp + 2]
    call print_hex
    call print_newline

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data section
section .data
exception_msg: db "Exception: ", 0
reg_ax_msg:    db "AX: ", 0
reg_bx_msg:    db "BX: ", 0
reg_cx_msg:    db "CX: ", 0
reg_dx_msg:    db "DX: ", 0

; IRQ handler table
irq_handlers:
    dw timer_handler        ; IRQ 0: Timer
    dw keyboard_handler     ; IRQ 1: Keyboard
    dw cascade_handler      ; IRQ 2: Cascade
    dw serial_handler       ; IRQ 3: Serial
    dw serial_handler       ; IRQ 4: Serial
    dw disk_handler         ; IRQ 5: Disk
    dw floppy_handler       ; IRQ 6: Floppy
    dw printer_handler      ; IRQ 7: Printer
    dw rtc_handler          ; IRQ 8: RTC
    dw acpi_handler         ; IRQ 9: ACPI
    dw network_handler      ; IRQ 10: Network
    dw network_handler      ; IRQ 11: Network
    dw mouse_handler        ; IRQ 12: Mouse
    dw coprocessor_handler  ; IRQ 13: Coprocessor
    dw ide_handler          ; IRQ 14: IDE
    dw ide_handler          ; IRQ 15: IDE

; Software interrupt handler table
sw_handlers:
    times 208 dw default_handler  ; 208 software interrupts

; Default handlers
default_handler:
    ret

timer_handler:
    ret

keyboard_handler:
    ret

cascade_handler:
    ret

serial_handler:
    ret

disk_handler:
    ret

floppy_handler:
    ret

printer_handler:
    ret

rtc_handler:
    ret

acpi_handler:
    ret

network_handler:
    ret

mouse_handler:
    ret

coprocessor_handler:
    ret

ide_handler:
    ret 

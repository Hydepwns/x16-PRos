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
extern memory_alloc
extern memory_free

; Process Management Functions
section .text

; Initialize process management
; Input: None
; Output: None
global process_init
process_init:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Initialize process table
    mov ax, PROCESS_TABLE_SEG
    mov es, ax
    xor di, di
    mov cx, MAX_PROCESSES * PROCESS_ENTRY_SIZE
    xor al, al
    rep stosb

    ; Initialize process queue
    mov word [process_queue_head], 0
    mov word [process_queue_tail], 0
    mov word [current_process], 0
    mov word [next_process], 0

    ; Create idle process
    mov ax, IDLE_PROCESS_STACK_SIZE
    call memory_alloc
    test ax, ax
    jz .error

    ; Set up idle process
    mov bx, PROCESS_TABLE_SEG
    mov es, bx
    xor di, di
    mov word [es:di + PROCESS_ENTRY_STATE], PROCESS_STATE_READY
    mov word [es:di + PROCESS_ENTRY_STACK], ax
    mov word [es:di + PROCESS_ENTRY_PRIORITY], 0
    mov word [es:di + PROCESS_ENTRY_ID], 0

    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_PROCESS_INIT
    call set_error

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Create new process
; Input: AX = entry point
;       BX = stack size
;       CL = priority
; Output: AX = process ID (0 if failed)
global process_create
process_create:
    push bx
    push cx
    push dx
    push es
    push di

    ; Allocate stack
    xchg ax, bx         ; Save entry point, get stack size
    call memory_alloc
    test ax, ax
    jz .error
    xchg ax, bx         ; Restore entry point, save stack pointer

    ; Find free process slot
    mov ax, PROCESS_TABLE_SEG
    mov es, ax
    xor di, di
    mov cx, MAX_PROCESSES
.find_slot:
    cmp word [es:di + PROCESS_ENTRY_STATE], PROCESS_STATE_FREE
    je .found_slot
    add di, PROCESS_ENTRY_SIZE
    loop .find_slot
    jmp .error

.found_slot:
    ; Initialize process entry
    mov word [es:di + PROCESS_ENTRY_STATE], PROCESS_STATE_READY
    mov word [es:di + PROCESS_ENTRY_STACK], bx
    mov byte [es:di + PROCESS_ENTRY_PRIORITY], cl
    mov ax, [next_process_id]
    mov word [es:di + PROCESS_ENTRY_ID], ax
    inc word [next_process_id]

    ; Set up initial stack frame
    mov es, bx
    mov di, STACK_SIZE - 2
    mov word [es:di], ax         ; Entry point
    sub di, 2
    mov word [es:di], 0          ; Flags
    sub di, 2
    mov word [es:di], 0          ; CS
    sub di, 2
    mov word [es:di], 0          ; IP

    ; Add to process queue
    call add_to_queue

    mov ax, [es:di + PROCESS_ENTRY_ID]
    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_PROCESS_CREATE
    call set_error
    xor ax, ax

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Terminate process
; Input: AX = process ID
; Output: None
global process_terminate
process_terminate:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Find process
    call find_process
    jc .error

    ; Free process stack
    mov ax, [es:di + PROCESS_ENTRY_STACK]
    call memory_free

    ; Mark process as free
    mov word [es:di + PROCESS_ENTRY_STATE], PROCESS_STATE_FREE

    ; Remove from queue
    call remove_from_queue

    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_PROCESS_TERMINATE
    call set_error

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Schedule next process
; Input: None
; Output: None
global process_schedule
process_schedule:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Get next process from queue
    mov ax, [process_queue_head]
    cmp ax, [process_queue_tail]
    je .no_process

    ; Update current process
    mov [current_process], ax
    mov [next_process], ax

    ; Switch context
    call switch_context

    mov al, ERR_NONE
    call set_error
    jmp .done

.no_process:
    mov al, ERR_PROCESS_SCHEDULE
    call set_error

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Switch process context
; Input: None
; Output: None
switch_context:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Save current process state
    mov ax, [current_process]
    call find_process
    jc .error

    ; Save registers
    mov [es:di + PROCESS_ENTRY_AX], ax
    mov [es:di + PROCESS_ENTRY_BX], bx
    mov [es:di + PROCESS_ENTRY_CX], cx
    mov [es:di + PROCESS_ENTRY_DX], dx
    mov [es:di + PROCESS_ENTRY_SI], si
    mov [es:di + PROCESS_ENTRY_DI], di
    mov [es:di + PROCESS_ENTRY_BP], bp
    mov [es:di + PROCESS_ENTRY_SP], sp
    mov [es:di + PROCESS_ENTRY_DS], ds
    mov [es:di + PROCESS_ENTRY_ES], es
    mov [es:di + PROCESS_ENTRY_SS], ss
    mov [es:di + PROCESS_ENTRY_CS], cs
    ; Save FLAGS using pushf/popf
    pushf
    pop ax
    mov [es:di + PROCESS_ENTRY_FLAGS], ax
    ; Note: Saving IP (instruction pointer) directly is not possible in 16-bit x86.
    ; A real context switch would save the return address from the stack or use a far call/iret.

    ; Load next process state
    mov ax, [next_process]
    call find_process
    jc .error

    ; Restore registers
    mov ax, [es:di + PROCESS_ENTRY_AX]
    mov bx, [es:di + PROCESS_ENTRY_BX]
    mov cx, [es:di + PROCESS_ENTRY_CX]
    mov dx, [es:di + PROCESS_ENTRY_DX]
    mov si, [es:di + PROCESS_ENTRY_SI]
    mov di, [es:di + PROCESS_ENTRY_DI]
    mov bp, [es:di + PROCESS_ENTRY_BP]
    mov sp, [es:di + PROCESS_ENTRY_SP]
    mov ds, [es:di + PROCESS_ENTRY_DS]
    mov es, [es:di + PROCESS_ENTRY_ES]
    mov ss, [es:di + PROCESS_ENTRY_SS]
    mov cs, [es:di + PROCESS_ENTRY_CS]
    ; Restore FLAGS using push/popf
    push word [es:di + PROCESS_ENTRY_FLAGS]
    popf
    ; Note: Restoring IP (instruction pointer) directly is not possible in 16-bit x86.
    ; A real context switch would set up the stack and use iret or retf to switch IP/CS/FLAGS.

    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_PROCESS_SWITCH
    call set_error

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Find process by ID
; Input: AX = process ID
; Output: ES:DI = process entry, CF = 1 if not found
find_process:
    push ax
    push bx
    push cx

    mov bx, PROCESS_TABLE_SEG
    mov es, bx
    xor di, di
    mov cx, MAX_PROCESSES
.search_loop:
    cmp word [es:di + PROCESS_ENTRY_ID], ax
    je .found
    add di, PROCESS_ENTRY_SIZE
    loop .search_loop
    stc
    jmp .done

.found:
    clc

.done:
    pop cx
    pop bx
    pop ax
    ret

; Add process to queue
; Input: ES:DI = process entry
; Output: None
add_to_queue:
    push ax
    push bx

    mov ax, [process_queue_tail]
    mov bx, PROCESS_QUEUE_SEG
    mov es, bx
    mov si, ax
    mov [es:si], di
    add ax, 2
    cmp ax, PROCESS_QUEUE_SIZE
    jb .no_wrap
    xor ax, ax
.no_wrap:
    mov [process_queue_tail], ax

    pop bx
    pop ax
    ret

; Remove process from queue
; Input: ES:DI = process entry
; Output: None
remove_from_queue:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    mov ax, [process_queue_head]
    mov bx, PROCESS_QUEUE_SEG
    mov es, bx
    mov cx, [process_queue_tail]
.search_loop:
    cmp ax, cx
    je .not_found
    mov si, ax
    mov dx, [es:si]
    cmp dx, di
    je .found
    add ax, 2
    cmp ax, PROCESS_QUEUE_SIZE
    jb .search_loop
    xor ax, ax
    jmp .search_loop

.found:
    ; Remove entry by shifting remaining entries
    mov bx, ax
.shift_loop:
    add bx, 2
    cmp bx, [process_queue_tail]
    je .done_shift
    mov dx, [es:bx]
    mov si, bx
    sub si, 2
    mov [es:si], dx
    jmp .shift_loop

.done_shift:
    sub word [process_queue_tail], 2
    jmp .done

.not_found:
    stc

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data section
section .data
process_queue_head:    dw 0
process_queue_tail:    dw 0
current_process:       dw 0
next_process:         dw 0
next_process_id:      dw 1

; Constants
PROCESS_TABLE_SEG     equ 0x3000
PROCESS_QUEUE_SEG     equ 0x4000
MAX_PROCESSES         equ 32
PROCESS_ENTRY_SIZE    equ 32
PROCESS_QUEUE_SIZE    equ 64
STACK_SIZE           equ 4096
IDLE_PROCESS_STACK_SIZE equ 1024

; Process states
PROCESS_STATE_FREE    equ 0
PROCESS_STATE_READY   equ 1
PROCESS_STATE_RUNNING equ 2
PROCESS_STATE_BLOCKED equ 3
PROCESS_STATE_ZOMBIE  equ 4

; Process entry structure
PROCESS_ENTRY_STATE    equ 0
PROCESS_ENTRY_STACK    equ 2
PROCESS_ENTRY_PRIORITY equ 4
PROCESS_ENTRY_ID      equ 6
PROCESS_ENTRY_AX      equ 8
PROCESS_ENTRY_BX      equ 10
PROCESS_ENTRY_CX      equ 12
PROCESS_ENTRY_DX      equ 14
PROCESS_ENTRY_SI      equ 16
PROCESS_ENTRY_DI      equ 18
PROCESS_ENTRY_BP      equ 20
PROCESS_ENTRY_SP      equ 22
PROCESS_ENTRY_DS      equ 24
PROCESS_ENTRY_ES      equ 26
PROCESS_ENTRY_SS      equ 28
PROCESS_ENTRY_CS      equ 30
PROCESS_ENTRY_IP      equ 32
PROCESS_ENTRY_FLAGS   equ 34 

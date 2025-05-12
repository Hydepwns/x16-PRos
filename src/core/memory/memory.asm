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

; Memory Management Functions
section .text

; Initialize memory management
; Input: None
; Output: None
global memory_init
memory_init:
    push ax
    push bx
    push cx
    push dx

    ; Initialize memory bitmap
    mov ax, MEMORY_BITMAP_SEG
    mov es, ax
    xor di, di
    mov cx, MEMORY_BITMAP_SIZE
    xor al, al
    rep stosb

    ; Mark system memory as allocated (0-640KB)
    mov ax, MEMORY_BITMAP_SEG
    mov es, ax
    xor di, di
    mov cx, 80      ; 640KB / 8KB = 80 bits
    mov al, 0xFF    ; Mark as allocated
    rep stosb

    ; Initialize heap
    mov word [heap_start], HEAP_START
    mov word [heap_end], HEAP_END
    mov word [current_heap], HEAP_START

    mov al, ERR_NONE
    call set_error

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Allocate memory block
; Input: AX = size in bytes
; Output: AX = pointer to allocated memory (0 if failed)
global memory_alloc
memory_alloc:
    push bx
    push cx
    push dx
    push es
    push di

    ; Check if size is valid
    test ax, ax
    jz .error
    cmp ax, MAX_ALLOC_SIZE
    ja .error

    ; Calculate number of 8KB blocks needed
    mov bx, 8 * 1024    ; 8KB block size
    xor dx, dx
    div bx
    test dx, dx
    jz .no_remainder
    inc ax              ; Round up to next block
.no_remainder:
    mov cx, ax          ; Save number of blocks needed

    ; Search for free blocks
    mov ax, MEMORY_BITMAP_SEG
    mov es, ax
    xor di, di
    mov dx, MEMORY_BITMAP_SIZE
.search_loop:
    mov al, [es:di]
    test al, al
    jnz .next_byte
    ; Found a free byte, check if we need more
    dec cx
    jz .found_space
.next_byte:
    inc di
    dec dx
    jnz .search_loop
    jmp .error

.found_space:
    ; Calculate memory address
    mov ax, di
    shl ax, 3           ; Multiply by 8 (bits per byte)
    shl ax, 10          ; Multiply by 1024 (bytes per block)
    add ax, 0x1000      ; Add base address

    ; Mark blocks as allocated
    mov di, ax
    shr di, 13          ; Divide by 8KB to get block number
    mov cl, [es:di]
    mov ah, 1
    mov cl, bl   ; bit offset (0-7)
    shl ah, cl
    not ah
    and cl, ah
    mov [es:di], cl

    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_MEMORY_ALLOC
    call set_error
    xor ax, ax          ; Return 0 for failure

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Free memory block
; Input: AX = pointer to memory block
; Output: None
global memory_free
memory_free:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    ; Check if pointer is valid
    test ax, ax
    jz .error
    cmp ax, 0x1000
    jb .error

    ; Calculate block number
    mov bx, ax
    shr bx, 13          ; Divide by 8KB
    mov ax, MEMORY_BITMAP_SEG
    mov es, ax
    mov di, bx
    shr di, 3           ; Divide by 8 to get byte offset
    and bx, 7           ; Get bit offset
    mov cl, [es:di]
    mov ah, 1
    mov cl, bl   ; bit offset (0-7)
    shl ah, cl
    not ah
    and cl, ah
    mov [es:di], cl

    mov al, ERR_NONE
    call set_error
    jmp .done

.error:
    mov al, ERR_MEMORY_FREE
    call set_error

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Get memory status
; Input: None
; Output: AX = total free memory in bytes
memory_status:
    push bx
    push cx
    push dx
    push es
    push di

    mov ax, MEMORY_BITMAP_SEG
    mov es, ax
    xor di, di
    mov cx, MEMORY_BITMAP_SIZE
    xor ax, ax          ; Free block counter
.count_loop:
    mov bl, [es:di]
    mov bh, 8           ; Bits per byte
.bit_loop:
    test bl, 1
    jnz .next_bit
    inc ax              ; Count free blocks
.next_bit:
    shr bl, 1
    dec bh
    jnz .bit_loop
    inc di
    loop .count_loop

    ; Convert blocks to bytes
    shl ax, 13          ; Multiply by 8KB

    mov al, ERR_NONE
    call set_error

    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Data section
section .data
heap_start:     dw 0
heap_end:       dw 0
current_heap:   dw 0

; Constants
MEMORY_BITMAP_SEG   equ 0x2000
MEMORY_BITMAP_SIZE  equ 1024    ; 8MB / 8KB = 1024 bits
HEAP_START         equ 0x1000
HEAP_END           equ 0x7FFF
MAX_ALLOC_SIZE     equ 0x1000   ; 4KB maximum allocation 

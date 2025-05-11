; =============================================
; x16-PRos Memory Management Library
; =============================================

%ifndef MEMORY_INCLUDED
%define MEMORY_INCLUDED

%include "src/lib/constants.inc"

; =============================================
; Buffer Management
; =============================================

; Clear a buffer with a specific value
; Input:
;   - es:di: destination buffer
;   - cx: buffer size in bytes
;   - al: value to fill with
; Output:
;   - es:di: points to end of buffer
clear_buffer:
    push ax
    push cx
    push di
    
    cld             ; Forward direction
    rep stosb       ; Store byte and increment di
    
    pop di
    pop cx
    pop ax
    ret

; Copy memory block
; Input:
;   - ds:si: source buffer
;   - es:di: destination buffer
;   - cx: number of bytes to copy
; Output:
;   - ds:si: points to end of source
;   - es:di: points to end of destination
copy_memory:
    push ax
    push cx
    push si
    push di
    
    cld             ; Forward direction
    rep movsb       ; Copy byte and increment si,di
    
    pop di
    pop si
    pop cx
    pop ax
    ret

; Compare memory blocks
; Input:
;   - ds:si: first buffer
;   - es:di: second buffer
;   - cx: number of bytes to compare
; Output:
;   - ZF: set if equal, cleared if different
;   - si: points to first difference
;   - di: points to first difference
compare_memory:
    push ax
    push cx
    push si
    push di
    
    cld             ; Forward direction
    repe cmpsb      ; Compare bytes until different or count exhausted
    
    pop di
    pop si
    pop cx
    pop ax
    ret

; =============================================
; Memory Allocation
; =============================================

; Initialize memory allocation system
; Input:
;   - ax: start address of free memory
;   - bx: size of free memory in bytes
init_memory:
    push ax
    push bx
    
    mov [free_memory_start], ax
    mov [free_memory_size], bx
    
    pop bx
    pop ax
    ret

; Allocate memory block
; Input:
;   - cx: size in bytes
; Output:
;   - ax: address of allocated block (0 if failed)
;   - bx: actual size allocated
allocate_memory:
    push cx
    push dx
    push si
    push di
    
    ; Check if enough memory available
    mov ax, [free_memory_size]
    cmp ax, cx
    jb .failed
    
    ; Get current free memory start
    mov ax, [free_memory_start]
    mov bx, cx      ; Return actual size
    
    ; Update free memory pointer and size
    add ax, cx
    mov [free_memory_start], ax
    sub [free_memory_size], cx
    
    jmp .done
    
.failed:
    xor ax, ax      ; Return 0 for failure
    xor bx, bx
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    ret

; Free memory block
; Input:
;   - ax: address of block to free
;   - bx: size of block
; Output:
;   - ax: 0 if successful, 1 if failed
free_memory:
    push bx
    push cx
    push dx
    
    ; Check if block is valid
    mov cx, [free_memory_start]
    sub cx, [free_memory_size]
    cmp ax, cx
    jb .failed
    
    ; Check if block is at end of free memory
    add bx, ax
    cmp bx, [free_memory_start]
    jne .failed
    
    ; Update free memory pointer and size
    mov [free_memory_start], ax
    add [free_memory_size], bx
    
    xor ax, ax      ; Return 0 for success
    jmp .done
    
.failed:
    mov ax, 1       ; Return 1 for failure
    
.done:
    pop dx
    pop cx
    pop bx
    ret

; =============================================
; Memory Utilities
; =============================================

; Convert segment:offset to linear address
; Input:
;   - ax: segment
;   - bx: offset
; Output:
;   - eax: linear address
segment_to_linear:
    push bx
    push cx
    push dx
    
    mov cx, 16
    mul cx          ; Multiply segment by 16
    add ax, bx      ; Add offset
    
    pop dx
    pop cx
    pop bx
    ret

; Convert linear address to segment:offset
; Input:
;   - eax: linear address
; Output:
;   - ax: segment
;   - bx: offset
linear_to_segment:
    push cx
    push dx
    
    mov bx, ax
    and bx, 0x000F  ; Get offset (low 4 bits)
    shr ax, 4       ; Get segment (high bits)
    
    pop dx
    pop cx
    ret

; =============================================
; Memory Variables
; =============================================

free_memory_start:  dw 0
free_memory_size:   dw 0

%endif ; MEMORY_INCLUDED 
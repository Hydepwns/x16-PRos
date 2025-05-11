[BITS 16]

%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/utils.inc"

section .text

; Print CPU information
print_CPU_info:
    pusha
    mov si, cpu_name
    call print_string
    ; Print CPU information
    mov eax, 80000002h
    call print_full_name_part
    mov eax, 80000003h
    call print_full_name_part
    mov eax, 80000004h
    call print_full_name_part
    mov si, mt
    call print_string
    call print_cores
    mov si, mt
    call print_string
    call print_cache_line
    mov si, mt
    call print_string
    call print_stepping
    mov si, mt
    call print_string
    popa
    ret

; Print EDX register value
print_edx:
    mov ah, 0eh
    mov bx, 4
.loop4r:
    mov al, dl
    int 10h
    ror edx, 8
    dec bx
    cmp bx, 0
    jne .loop4r
    ret

; Print full CPU name part
print_full_name_part:
    cpuid
    push edx
    push ecx
    push ebx
    push eax
    mov cx, 4
.loop4n:
    pop edx
    call print_edx
    dec cx
    cmp cx, 0
    jne .loop4n
    ret

; Print number of CPU cores
print_cores:
    mov si, cores
    call print_string
    mov eax, 1
    cpuid
    ror ebx, 16
    mov al, bl
    call print_al
    ret

; Print cache line size
print_cache_line:
    mov si, cache_line
    call print_string
    mov eax, 1
    cpuid
    ror ebx, 8
    mov al, bl
    mov bl, 8
    mul bl
    call print_al
    ret

; Print CPU stepping
print_stepping:
    mov si, stepping
    call print_string
    mov eax, 1
    cpuid
    and al, 15
    call print_al
    ret

; Print AL register as decimal
print_al:
    mov ah, 0
    mov dl, 10
    div dl
    add ax, '00'
    mov dx, ax
    mov ah, 0eh
    mov al, dl
    cmp dl, '0'
    jz .skip_fn
    mov bl, 0x0F
    int 10h
.skip_fn:
    mov al, dh
    mov bl, 0x0F
    int 10h
    ret

section .data
    cpu_name db '  CPU name: ', 0
    cores db '  CPU cores: ', 0
    stepping db '  Stepping ID: ', 0
    cache_line db '  Cache line: ', 0
    mt db '', 10, 13, 0 

%ifndef FAT_INCLUDED
%define FAT_INCLUDED

[BITS 16]

; Include error handling
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"
%include "src/fs/fat/check.asm"

; External error handling functions
extern set_error
extern get_error
extern print_error
extern print_string

; Sector size configuration
%ifndef SECTOR_SIZE
    %define SECTOR_SIZE 512
%endif

; Validate sector size
%if SECTOR_SIZE < 256 || SECTOR_SIZE > 4096
    %error "Invalid sector size. Must be between 256 and 4096 bytes."
%endif

; FAT Constants
FAT_START_SECTOR equ 2        ; FAT starts at sector 2 (after boot sector)
FAT_SECTORS      equ 4        ; FAT is 4 sectors long
FAT_BUFFER      equ 0x7800    ; FAT buffer in memory (moved to avoid conflicts)
MAX_CLUSTERS    equ (FAT_SECTORS * SECTOR_SIZE * 2 / 3)  ; Maximum clusters based on sector size

; FAT Entry Values
FAT_FREE        equ 0x000     ; Free cluster
FAT_RESERVED    equ 0xFF0     ; Reserved cluster
FAT_BAD         equ 0xFF7     ; Bad cluster
FAT_EOF         equ 0xFF8     ; End of file marker

; FAT Operations
section .text
global fat_next
global fat_alloc
global fat_free
global fat_get_next
global fat_set_next
global fat_is_valid

; Initialize FAT
; Input: None
; Output: CF=0 if successful, CF=1 if error
fat_init:
    push ax
    push bx
    push cx
    push dx
    push es

    ; Load FAT into memory
    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x02    ; BIOS read sector
    mov al, FAT_SECTORS
    mov ch, 0x00    ; Cylinder 0
    mov cl, FAT_START_SECTOR
    mov dh, 0x00    ; Head 0
    mov dl, DISK_FIRST_HD    ; First hard disk
    int BIOS_DISK_INT
    jc .disk_error

    ; Clear FAT (set all entries to 0x000)
    mov ax, FAT_BUFFER
    mov es, ax
    xor di, di
    mov cx, FAT_SECTORS * SECTOR_SIZE  ; Size in bytes
    xor ax, ax
    rep stosb

    ; Mark first entry as reserved (0xFFF)
    mov word [es:0], 0x0FFF

    ; Write FAT back to disk
    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    jc .disk_error

    mov al, ERR_NONE
    call set_error
    clc             ; Clear carry flag (success)
    jmp .done

.disk_error:
    mov al, ERR_DISK_READ
    call set_error
    stc             ; Set carry flag (error)

.done:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Allocate a new cluster
; Input: None
; Output: AX = cluster number (0x000 if no free clusters)
;         CF = 1 if error
fat_alloc:
    push bx
    push cx
    push dx
    push es

    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx      ; Start at first cluster
    mov cx, MAX_CLUSTERS

.search_loop:
    ; Get 12-bit FAT entry
    mov ax, [es:bx]
    test bx, 1      ; Check if odd or even byte
    jz .even_entry
    shr ax, 4       ; Odd byte: shift right 4 bits
.even_entry:
    and ax, 0x0FFF  ; Get 12-bit value
    cmp ax, FAT_FREE
    je .found_free

    add bx, 1       ; Move to next byte
    loop .search_loop
    mov al, ERR_NO_SPACE
    call set_error
    xor ax, ax      ; No free clusters found
    stc
    jmp .done

.found_free:
    ; Calculate cluster number
    mov ax, bx
    mov cl, 2
    div cl          ; Divide by 2 to get cluster number
    mov bx, ax      ; Save cluster number

    ; Mark cluster as end of file
    mov ax, FAT_BUFFER
    mov es, ax
    mov ax, bx
    mov cl, 2
    mul cl          ; Multiply by 2 to get byte offset
    mov bx, ax
    test bx, 1      ; Check if odd or even byte
    jz .mark_even
    mov ax, [es:bx]
    and ax, 0x000F  ; Clear high 12 bits
    or ax, FAT_EOF << 4  ; Set high 12 bits to EOF
    jmp .mark_done
.mark_even:
    mov ax, [es:bx]
    and ax, 0xF000  ; Clear low 12 bits
    or ax, FAT_EOF  ; Set low 12 bits to EOF
.mark_done:
    mov [es:bx], ax

    ; Write FAT back to disk
    push bx         ; Save cluster number
    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    pop bx          ; Restore cluster number
    jc .disk_error

    mov ax, bx      ; Return cluster number
    mov al, ERR_NONE
    call set_error
    clc             ; Clear carry flag (success)
    jmp .done

.disk_error:
    mov al, ERR_DISK_WRITE
    call set_error
    xor ax, ax      ; Return 0 on error
    stc

.done:
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Deallocate a cluster
; Input: AX = cluster number to deallocate
; Output: CF = 0 if successful, CF = 1 if error
fat_free:
    push ax
    push bx
    push es

    ; Validate cluster number
    cmp ax, MAX_CLUSTERS
    jae .invalid_cluster

    ; Calculate FAT offset
    mov bx, ax
    mov cl, 2
    mul cl          ; Multiply by 2 to get byte offset
    mov bx, ax

    ; Mark cluster as free
    mov ax, FAT_BUFFER
    mov es, ax
    test bx, 1      ; Check if odd or even byte
    jz .free_even
    mov ax, [es:bx]
    and ax, 0x000F  ; Clear high 12 bits
    jmp .free_done
.free_even:
    mov ax, [es:bx]
    and ax, 0xF000  ; Clear low 12 bits
.free_done:
    mov [es:bx], ax

    ; Write FAT back to disk
    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    jc .disk_error

    mov al, ERR_NONE
    call set_error
    clc             ; Clear carry flag (success)
    jmp .done

.invalid_cluster:
    mov al, ERR_INVALID_CLUST
    call set_error
    stc
    jmp .done

.disk_error:
    mov al, ERR_DISK_WRITE
    call set_error
    stc             ; Set carry flag (error)

.done:
    pop es
    pop bx
    pop ax
    ret

; Get next cluster in chain
; Input: AX = current cluster number
; Output: AX = next cluster number (0xFFF if end of chain)
;         CF = 1 if error
fat_next:
    push bx
    push es

    ; Validate cluster number
    cmp ax, MAX_CLUSTERS
    jae .invalid_cluster

    ; Calculate FAT offset
    mov bx, ax
    mov cl, 2
    mul cl          ; Multiply by 2 to get byte offset
    mov bx, ax

    ; Get next cluster
    mov ax, FAT_BUFFER
    mov es, ax
    mov ax, [es:bx]
    test bx, 1      ; Check if odd or even byte
    jz .even_entry
    shr ax, 4       ; Odd byte: shift right 4 bits
.even_entry:
    and ax, 0x0FFF  ; Get 12-bit value

    mov al, ERR_NONE
    call set_error
    clc             ; Clear carry flag (success)
    jmp .done

.invalid_cluster:
    mov al, ERR_INVALID_CLUST
    call set_error
    stc

.done:
    pop es
    pop bx
    ret

; Mark cluster as bad
; Input: AX = cluster number to mark as bad
; Output: CF = 0 if successful, CF = 1 if error
fat_mark_bad:
    push ax
    push bx
    push es

    ; Validate cluster number
    cmp ax, MAX_CLUSTERS
    jae .invalid_cluster

    ; Calculate FAT offset
    mov bx, ax
    mov cl, 2
    mul cl          ; Multiply by 2 to get byte offset
    mov bx, ax

    ; Mark cluster as bad
    mov ax, FAT_BUFFER
    mov es, ax
    test bx, 1      ; Check if odd or even byte
    jz .mark_even
    mov ax, [es:bx]
    and ax, 0x000F  ; Clear high 12 bits
    or ax, FAT_BAD << 4  ; Set high 12 bits to BAD
    jmp .mark_done
.mark_even:
    mov ax, [es:bx]
    and ax, 0xF000  ; Clear low 12 bits
    or ax, FAT_BAD  ; Set low 12 bits to BAD
.mark_done:
    mov [es:bx], ax

    ; Write FAT back to disk
    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    jc .disk_error

    mov al, ERR_NONE
    call set_error
    clc             ; Clear carry flag (success)
    jmp .done

.invalid_cluster:
    mov al, ERR_INVALID_CLUST
    call set_error
    stc
    jmp .done

.disk_error:
    mov al, ERR_DISK_WRITE
    call set_error
    stc             ; Set carry flag (error)

.done:
    pop es
    pop bx
    pop ax
    ret 

; Get next cluster in chain (alias for fat_next)
; Input: AX = current cluster number
; Output: AX = next cluster number (0xFFF if end of chain), CF=1 if error
fat_get_next:
    jmp fat_next

; Set next cluster in chain
; Input: AX = current cluster number, DX = next cluster number (12 bits)
; Output: CF = 0 if successful, CF = 1 if error
fat_set_next:
    push ax
    push bx
    push dx
    push es

    cmp ax, MAX_CLUSTERS
    jae .invalid_cluster
    cmp dx, 0x0FFF
    ja .invalid_value

    ; Calculate FAT offset
    mov bx, ax
    mov cl, 2
    mul cl          ; Multiply by 2 to get byte offset
    mov bx, ax

    mov ax, FAT_BUFFER
    mov es, ax
    mov ax, [es:bx]
    test bx, 1
    jz .even_entry
    ; Odd entry: upper 12 bits
    and ax, 0x000F
    mov cx, dx
    shl cx, 4
    or ax, cx
    mov [es:bx], ax
    jmp .write_disk
.even_entry:
    ; Even entry: lower 12 bits
    and ax, 0xF000
    or ax, dx
    mov [es:bx], ax
.write_disk:
    ; Write FAT back to disk
    mov ax, FAT_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    jc .disk_error
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.invalid_cluster:
    mov al, ERR_INVALID_CLUST
    call set_error
    stc
    jmp .done
.invalid_value:
    mov al, ERR_INVALID_CLUST
    call set_error
    stc
    jmp .done
.disk_error:
    mov al, ERR_DISK_WRITE
    call set_error
    stc
.done:
    pop es
    pop dx
    pop bx
    pop ax
    ret

; Check if a cluster number is valid (not reserved/bad)
; Input: AX = cluster number
; Output: ZF=1 if valid, ZF=0 if not valid, CF=1 if error
fat_is_valid:
    push ax
    cmp ax, 2
    jb .invalid
    cmp ax, MAX_CLUSTERS
    jae .invalid
    ; Check for reserved/bad
    cmp ax, FAT_RESERVED
    je .invalid
    cmp ax, FAT_BAD
    je .invalid
    ; Valid
    pop ax
    clc
    xor ax, ax ; ZF=1
    ret
.invalid:
    pop ax
    stc
    mov ax, 1 ; ZF=0
    ret

%endif ; FAT_INCLUDED 

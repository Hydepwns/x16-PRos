[BITS 16]

; Include guard
%ifndef DIR_CORE_INCLUDED
%define DIR_CORE_INCLUDED

; Include error handling and constants
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"
%include "src/fs/fat.inc"
; %include "src/fs/fat.asm"   ; Removed to prevent multiple definitions

; External symbols
extern print_hex
extern print_string
extern print_char
extern print_newline
extern print_space
extern fat_validate_chain
extern fat_next

; External error handling functions
extern set_error
extern get_error
extern print_error
extern error_messages

; Directory Operations
section .text

; Initialize directory
; Input: None
; Output: CF=0 if successful, CF=1 if error
dir_init:
    push ax
    push bx
    push cx
    push dx
    push es

    ; Load directory into memory
    mov ax, DIR_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x02    ; BIOS read sector
    mov al, DIR_SECTORS
    mov ch, 0x00    ; Cylinder 0
    mov cl, DIR_START_SECTOR
    mov dh, 0x00    ; Head 0
    mov dl, DISK_FIRST_HD    ; First hard disk
    int BIOS_DISK_INT
    jc .disk_error

    ; Clear directory (set all entries to 0)
    mov ax, DIR_BUFFER
    mov es, ax
    xor di, di
    mov cx, DIR_SECTORS * SECTOR_SIZE  ; Total directory size
    xor ax, ax
    rep stosb

    ; Initialize first entry as root directory
    mov ax, DIR_BUFFER
    mov es, ax
    xor di, di
    mov byte [es:di], '.'              ; First char of name
    mov byte [es:di + 1], ' '          ; Rest of name
    mov byte [es:di + DIR_ATTR_OFFSET], DIR_ATTR_DIRECTORY  ; Directory attribute
    mov word [es:di + DIR_SIZE_OFFSET], 0     ; Clear file size
    mov byte [es:di + DIR_SIZE_OFFSET + 2], 0 ; Clear high byte of file size
    mov word [es:di + DIR_CLUSTER_OFFSET], 0  ; Root directory cluster
    mov word [es:di + DIR_DATE_OFFSET], 0     ; Clear date
    mov word [es:di + DIR_TIME_OFFSET], 0     ; Clear time

    ; Write directory back to disk
    mov ax, DIR_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, DIR_SECTORS
    mov ch, 0x00
    mov cl, DIR_START_SECTOR
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

; Find directory entry
; Input: DS:SI = pointer to filename (8.3 format)
; Output: AX = entry offset (0xFFFF if not found)
;         CF = 1 if error
dir_find:
    push bx
    push cx
    push dx
    push es
    push di

    ; Validate filename length
    mov cx, DIR_FILENAME_SIZE
    mov di, si
.check_name:
    mov al, [di]
    test al, al
    jz .invalid_name
    cmp al, ' '     ; Allow spaces in filename
    je .next_name
    cmp al, '.'     ; Allow dot in filename
    je .next_name
    cmp al, 'A'     ; Check if uppercase letter
    jb .invalid_name
    cmp al, 'Z'
    ja .invalid_name
.next_name:
    inc di
    loop .check_name

    ; Skip dot
    cmp byte [di], '.'
    jne .invalid_name
    inc di

    ; Validate extension
    mov cx, DIR_EXTENSION_SIZE
.check_ext:
    mov al, [di]
    test al, al
    jz .invalid_name
    cmp al, ' '     ; Allow spaces in extension
    je .next_ext
    cmp al, 'A'     ; Check if uppercase letter
    jb .invalid_name
    cmp al, 'Z'
    ja .invalid_name
.next_ext:
    inc di
    loop .check_ext

    mov ax, DIR_BUFFER
    mov es, ax
    xor di, di      ; Start at first entry
    mov cx, MAX_ENTRIES

.search_loop:
    ; Check if entry is free or deleted
    mov al, [es:di]
    test al, al
    jz .not_found
    cmp al, DIR_ENTRY_DELETED
    je .next_entry

    ; Compare filename
    push cx
    push si
    push di
    mov cx, DIR_FILENAME_SIZE
    mov bx, di      ; Save di in bx
.loop1:
    mov al, [es:bx]
    cmp al, [ds:si]
    jne .next_entry
    inc bx
    inc si
    loop .loop1
    pop di
    pop si
    pop cx

    ; Compare extension
    push cx
    push si
    push di
    mov bx, di
    add bx, DIR_EXTENSION_OFFSET
    mov cx, DIR_EXTENSION_SIZE
.loop2:
    mov al, [es:bx]
    cmp al, [ds:si]
    jne .next_entry
    inc bx
    inc si
    loop .loop2
    pop di
    pop si
    pop cx

    ; Found matching entry
    mov ax, di
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.next_entry:
    add di, DIR_ENTRY_SIZE
    loop .search_loop

.not_found:
    mov ax, 0xFFFF
    mov al, ERR_FILE_NOT_FOUND
    call set_error
    stc
    jmp .done

.invalid_name:
    mov ax, 0xFFFF
    mov al, ERR_INVALID_NAME
    call set_error
    stc

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Create directory entry
; Input: DS:SI = pointer to filename (8.3 format)
;       BX = starting cluster
;       CX = file size
;       DL = attributes
; Output: AX = entry offset (0xFFFF if error)
;         CF = 1 if error
dir_create:
    push bx
    push cx
    push dx
    push es
    push di

    ; Validate filename length
    mov cx, DIR_FILENAME_SIZE
    mov di, si
.check_name:
    mov al, [di]
    test al, al
    jz .invalid_name
    cmp al, ' '     ; Allow spaces in filename
    je .next_name
    cmp al, '.'     ; Allow dot in filename
    je .next_name
    cmp al, 'A'     ; Check if uppercase letter
    jb .invalid_name
    cmp al, 'Z'
    ja .invalid_name
.next_name:
    inc di
    loop .check_name

    ; Skip dot
    cmp byte [di], '.'
    jne .invalid_name
    inc di

    ; Validate extension
    mov cx, DIR_EXTENSION_SIZE
.check_ext:
    mov al, [di]
    test al, al
    jz .invalid_name
    cmp al, ' '     ; Allow spaces in extension
    je .next_ext
    cmp al, 'A'     ; Check if uppercase letter
    jb .invalid_name
    cmp al, 'Z'
    ja .invalid_name
.next_ext:
    inc di
    loop .check_ext

    ; Validate attributes
    test dl, DIR_ATTR_INVALID
    jnz .invalid_attr

    ; Validate file size (3 bytes)
    cmp cx, MAX_FILE_SIZE
    ja .invalid_size

    ; Validate cluster number
    cmp bx, MAX_CLUSTERS
    jae .invalid_cluster

    ; Check if file already exists
    call dir_find
    jnc .file_exists

    ; Find free entry
    mov ax, DIR_BUFFER
    mov es, ax
    xor di, di
    mov cx, MAX_ENTRIES

.search_loop:
    mov al, [es:di]
    test al, al
    jz .found_free
    cmp al, DIR_ENTRY_DELETED
    je .found_free
    add di, DIR_ENTRY_SIZE
    loop .search_loop

    ; No free entries
    mov ax, 0xFFFF
    mov al, ERR_DIR_FULL
    call set_error
    stc
    jmp .done

.found_free:
    ; Copy filename
    push cx
    push si
    push di
    mov cx, DIR_FILENAME_SIZE
.loop1:
    mov al, [ds:si]
    mov [es:di], al
    inc si
    inc di
    loop .loop1
    pop di
    pop si
    pop cx

    ; Skip dot
    cmp byte [si], '.'
    jne .invalid_name
    inc si

    ; Copy extension
    push cx
    push si
    push di
    add di, DIR_EXTENSION_OFFSET
    mov cx, DIR_EXTENSION_SIZE
.loop2:
    mov al, [ds:si]
    mov [es:di], al
    inc si
    inc di
    loop .loop2
    pop di
    pop si
    pop cx

    ; Set attributes
    mov [es:di + DIR_ATTR_OFFSET], dl

    ; Set file size (3 bytes)
    mov [es:di + DIR_SIZE_OFFSET], cx    ; Store first two bytes
    mov byte [es:di + DIR_SIZE_OFFSET + 2], 0  ; Clear third byte

    ; Set starting cluster (2 bytes)
    mov [es:di + DIR_CLUSTER_OFFSET], bx

    ; Set date and time (2 bytes each)
    mov word [es:di + DIR_DATE_OFFSET], 0x0000
    mov word [es:di + DIR_TIME_OFFSET], 0x0000

    ; Write directory back to disk
    mov ax, DIR_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, DIR_SECTORS
    mov ch, 0x00
    mov cl, DIR_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    jc .disk_error

    mov ax, di      ; Return entry offset
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.invalid_name:
    mov ax, 0xFFFF
    mov al, ERR_INVALID_NAME
    call set_error
    stc
    jmp .done

.invalid_attr:
    mov ax, 0xFFFF
    mov al, ERR_INVALID_ATTR
    call set_error
    stc
    jmp .done

.invalid_size:
    mov ax, 0xFFFF
    mov al, ERR_INVALID_SIZE
    call set_error
    stc
    jmp .done

.invalid_cluster:
    mov ax, 0xFFFF
    mov al, ERR_INVALID_CLUST
    call set_error
    stc
    jmp .done

.file_exists:
    mov ax, 0xFFFF
    mov al, ERR_FILE_EXISTS
    call set_error
    stc
    jmp .done

.disk_error:
    mov ax, 0xFFFF
    mov al, ERR_DISK_WRITE
    call set_error
    stc

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Delete directory entry
; Input: AX = entry offset
; Output: CF = 0 if successful, CF = 1 if error
dir_delete:
    push ax
    push bx
    push es

    ; Validate entry offset
    cmp ax, MAX_ENTRIES * DIR_ENTRY_SIZE
    jae .invalid_entry

    ; Mark entry as deleted and clear fields
    mov bx, DIR_BUFFER
    mov es, bx
    mov bx, ax
    mov byte [es:bx], DIR_ENTRY_DELETED
    mov word [es:bx + DIR_SIZE_OFFSET], 0     ; Clear file size
    mov byte [es:bx + DIR_SIZE_OFFSET + 2], 0 ; Clear high byte of file size
    mov word [es:bx + DIR_CLUSTER_OFFSET], 0  ; Clear cluster number
    mov word [es:bx + DIR_DATE_OFFSET], 0     ; Clear date
    mov word [es:bx + DIR_TIME_OFFSET], 0     ; Clear time

    ; Write directory back to disk
    mov ax, DIR_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, DIR_SECTORS
    mov ch, 0x00
    mov cl, DIR_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    int BIOS_DISK_INT
    jc .disk_error

    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.invalid_entry:
    mov al, ERR_INVALID_NAME
    call set_error
    stc
    jmp .done

.disk_error:
    mov al, ERR_DISK_WRITE
    call set_error
    stc

.done:
    pop es
    pop bx
    pop ax
    ret 

%endif ; DIR_CORE_INCLUDED 

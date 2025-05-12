[BITS 16]

; Include error handling and recovery
%include "src/fs/recovery.asm"
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"
%include "src/fs/fat.inc"

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

; File Constants
CLUSTER_SIZE   equ SECTOR_SIZE ; Size of a cluster in bytes (1 sector per cluster)
MAX_FILE_SIZE  equ 0xFFFFFF   ; Maximum file size (3 bytes in directory entry)

; File Operations
section .text

; Create a new file
; Input: DS:SI = pointer to filename (8.3 format)
;       DL = attributes
; Output: AX = entry offset (0xFFFF if error)
;         CF = 1 if error
file_create:
    push bx
    push cx
    push dx
    push si

    ; Validate filename length
    mov cx, DIR_FILENAME_SIZE + DIR_EXTENSION_SIZE
    mov di, si
.check_length:
    mov al, [di]
    test al, al
    jz .invalid_name
    inc di
    loop .check_length

    ; Validate attributes
    test dl, DIR_ATTR_INVALID
    jnz .invalid_attr

    ; Allocate first cluster
    call fat_alloc
    jc .no_space
    mov bx, ax      ; Save cluster number

    ; Create directory entry
    xor cx, cx      ; Initial file size = 0
    xor dx, dx      ; High byte of file size = 0
    call dir_create
    jc .dir_error

    ; Success
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.invalid_name:
    mov al, ERR_INVALID_NAME
    call set_error
    mov ax, 0xFFFF
    stc
    jmp .done

.invalid_attr:
    mov al, ERR_INVALID_ATTR
    call set_error
    mov ax, 0xFFFF
    stc
    jmp .done

.no_space:
    mov al, ERR_NO_SPACE
    call set_error
    mov ax, 0xFFFF
    stc
    jmp .done

.dir_error:
    ; Free allocated cluster on error
    mov ax, bx
    call fat_free
    mov ax, 0xFFFF
    stc

.done:
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Delete a file
; Input: DS:SI = pointer to filename (8.3 format)
; Output: CF = 0 if successful, CF = 1 if error
file_delete:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Find file entry
    call dir_find
    jc .not_found
    push ax         ; Save entry offset

    ; Get starting cluster
    mov bx, DIR_BUFFER
    mov es, bx
    mov bx, ax      ; Save entry offset
    add bx, DIR_CLUSTER_OFFSET  ; Add offset to get cluster
    mov bx, [es:bx]  ; Get cluster number

    ; Free all clusters in chain
.free_loop:
    test bx, bx
    jz .free_done
    mov ax, bx
    call fat_next    ; Get next cluster
    push ax         ; Save next cluster
    mov ax, bx
    call fat_free    ; Free current cluster
    pop bx          ; Restore next cluster
    jmp .free_loop

.free_done:
    ; Delete directory entry
    pop ax          ; Restore entry offset
    call dir_delete
    jc .delete_error

    ; Success
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.not_found:
    mov al, ERR_FILE_NOT_FOUND
    call set_error
    stc
    jmp .done

.delete_error:
    mov al, ERR_SYSTEM
    call set_error
    stc

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Read file data
; Input: DS:SI = pointer to filename (8.3 format)
;       ES:BX = destination buffer
;       CX = number of bytes to read
; Output: AX = number of bytes read
;         CF = 1 if error
file_read:
    push bx
    push cx
    push dx
    push si
    push di
    push es

    ; Find file entry
    call dir_find
    jc .not_found
    push ax         ; Save entry offset

    ; Get file size and starting cluster
    mov di, DIR_BUFFER
    mov es, di
    mov di, ax
    mov ax, [es:di + DIR_SIZE_OFFSET]    ; Get first two bytes
    mov bl, [es:di + DIR_SIZE_OFFSET + 2] ; Get third byte
    mov bh, 0
    mov dx, bx                           ; Combine into 24-bit value
    mov bx, [es:di + DIR_CLUSTER_OFFSET] ; Get cluster number
    pop di          ; Restore entry offset
    push ax         ; Save file size (low word)
    push dx         ; Save file size (high word)

    ; Check if read size is valid
    pop dx          ; Get high word of file size
    pop ax          ; Get low word of file size
    cmp cx, ax
    jbe .size_ok
    mov cx, ax      ; Limit read to file size
.size_ok:
    push cx         ; Save bytes to read

    ; Try to read data
    mov ax, dx      ; Starting cluster
    pop cx          ; Bytes to read
    pop es          ; Destination buffer
    pop di          ; Buffer offset
    xor dx, dx      ; Bytes read counter

.read_loop:
    test cx, cx
    jz .read_done

    ; Calculate sector number from cluster
    push ax
    add ax, FILE_DATA_START
    mov bx, ax
    mov ax, FILE_BUFFER
    mov es, ax
    xor bx, bx

    ; Read sector with retry
    mov ah, 0x02    ; BIOS read sector
    mov al, FILE_READ_SECTORS
    mov ch, 0x00
    mov cl, bl      ; Sector number
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .disk_error

    ; Copy data to destination
    push cx
    push di
    push es
    mov ax, FILE_BUFFER
    mov es, ax
    xor di, di
    mov cx, SECTOR_SIZE
    mov bx, cx      ; Save SECTOR_SIZE in bx
    pop es          ; Restore original es
    pop di          ; Restore original di
    pop cx          ; Restore original cx
    cmp bx, cx      ; Compare SECTOR_SIZE with remaining bytes
    jbe .copy_ok
    mov bx, cx      ; Use remaining bytes
.copy_ok:
    mov cx, bx      ; Move count to cx for copy_loop
    mov bx, si      ; Use source offset in bx
.copy_loop:
    mov al, [es:bx]
    mov [es:di], al
    inc bx
    inc di
    loop .copy_loop
    pop es
    pop di
    pop cx

    ; Update counters
    sub cx, SECTOR_SIZE
    add dx, SECTOR_SIZE
    add di, SECTOR_SIZE

    ; Get next cluster
    pop ax
    call fat_next
    cmp ax, 0xFF8   ; Check for end of file
    jae .read_done
    jmp .read_loop

.read_done:
    mov ax, dx      ; Return bytes read
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.not_found:
    mov al, ERR_FILE_NOT_FOUND
    call set_error
    xor ax, ax      ; Return 0 on error
    stc
    jmp .done

.disk_error:
    ; Try to recover data
    pop ax          ; Restore cluster number
    pop es          ; Restore destination buffer
    pop di          ; Restore buffer offset
    pop cx          ; Restore bytes to read
    call recover_file_data
    jc .recovery_failed
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.recovery_failed:
    mov al, ERR_DISK_READ
    call set_error
    xor ax, ax      ; Return 0 on error
    stc

.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Write file data
; Input: DS:SI = pointer to filename (8.3 format)
;       ES:BX = source buffer
;       CX = number of bytes to write
; Output: AX = number of bytes written
;         CF = 1 if error
file_write:
    push bx
    push cx
    push dx
    push si
    push di
    push es

    ; Validate file size
    cmp cx, MAX_FILE_SIZE
    ja .invalid_size

    ; Find file entry
    call dir_find
    jc .not_found
    push ax         ; Save entry offset

    ; Get starting cluster and current file size
    mov bx, DIR_BUFFER
    mov es, bx
    mov bx, ax      ; Save entry offset
    mov ax, [es:bx + DIR_SIZE_OFFSET]    ; Get first two bytes
    mov dl, [es:bx + DIR_SIZE_OFFSET + 2] ; Get third byte
    mov dh, 0
    push dx         ; Save high byte of current size
    push ax         ; Save low word of current size
    add bx, DIR_CLUSTER_OFFSET  ; Add offset to get cluster
    mov bx, [es:bx]  ; Get cluster number

    ; Write data cluster by cluster
    mov ax, bx      ; Starting cluster
    pop di          ; Entry offset
    pop es          ; Source buffer
    pop si          ; Buffer offset
    pop cx          ; Bytes to write
    xor dx, dx      ; Bytes written counter

.write_loop:
    test cx, cx
    jz .write_done

    ; Check if we need a new cluster
    test ax, ax
    jnz .use_cluster
    call fat_alloc  ; Allocate new cluster
    jc .no_space
    test dx, dx
    jz .first_cluster
    push ax
    mov ax, dx
    call fat_next
    pop bx
    mov [es:bx], ax ; Update FAT chain
    mov ax, bx
.first_cluster:
    mov dx, ax      ; Save first cluster
    push ax
    mov ax, di
    mov bx, ax
    add bx, DIR_CLUSTER_OFFSET
    mov [es:bx], dx
    pop ax

.use_cluster:
    ; Calculate sector number from cluster
    push ax
    add ax, FILE_DATA_START
    mov bx, ax
    mov ax, FILE_BUFFER
    mov es, ax
    xor bx, bx

    ; Copy data to sector buffer
    push cx
    push si
    push es
    mov ax, FILE_BUFFER
    mov es, ax
    xor di, di
    mov cx, SECTOR_SIZE
    mov bx, cx      ; Save SECTOR_SIZE in bx
    pop es          ; Restore original es
    pop si          ; Restore original si
    pop cx          ; Restore original cx
    cmp bx, cx      ; Compare SECTOR_SIZE with remaining bytes
    jbe .copy_ok
    mov bx, cx      ; Use remaining bytes
.copy_ok:
    mov cx, bx      ; Move count to cx for copy_loop
    mov bx, si      ; Use source offset in bx
.copy_loop:
    mov al, [es:bx]
    mov [es:di], al
    inc bx
    inc di
    loop .copy_loop
    pop es
    pop si
    pop cx

    ; Write sector with retry
    mov ah, 0x03    ; BIOS write sector
    mov al, FILE_WRITE_SECTORS
    mov ch, 0x00
    mov cl, bl      ; Sector number
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .disk_error

    ; Update counters
    sub cx, SECTOR_SIZE
    add dx, SECTOR_SIZE
    add si, SECTOR_SIZE

    ; Get next cluster
    pop ax
    call fat_next
    cmp ax, 0xFF8   ; Check for end of file
    jae .write_done
    jmp .write_loop

.write_done:
    ; Update file size
    pop di          ; Restore entry offset
    mov ax, DIR_BUFFER
    mov es, ax
    mov bx, di
    add bx, DIR_SIZE_OFFSET
    mov [es:bx], dx      ; Store first two bytes
    mov byte [es:bx+2], 0 ; Clear third byte since we don't support files > 64KB

    ; Write directory back to disk with retry
    mov ax, DIR_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, DIR_SECTORS
    mov ch, 0x00
    mov cl, DIR_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .disk_error

    mov ax, dx      ; Return bytes written
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.not_found:
    mov al, ERR_FILE_NOT_FOUND
    call set_error
    xor ax, ax      ; Return 0 on error
    stc
    jmp .done

.invalid_size:
    mov al, ERR_INVALID_SIZE
    call set_error
    xor ax, ax      ; Return 0 on error
    stc
    jmp .done

.no_space:
    mov al, ERR_NO_SPACE
    call set_error
    xor ax, ax      ; Return 0 on error
    stc
    jmp .done

.disk_error:
    ; Try to recover FAT chain
    pop ax          ; Restore cluster number
    call recover_fat_chain
    jc .recovery_failed
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.recovery_failed:
    mov al, ERR_DISK_WRITE
    call set_error
    xor ax, ax      ; Return 0 on error
    stc

.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret 

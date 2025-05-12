[BITS 16]

%ifndef RECOVERY_INCLUDED
%define RECOVERY_INCLUDED

; Include constants
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"

; External error handling functions
extern set_error
extern get_error
extern print_error
extern print_string
; extern fat_validate_chain  ; Commented out to avoid redefinition error in flat binary mode
extern fat_next

; Include directory operations
%include "src/fs/dir.asm"

; Include FAT operations
%include "src/fs/fat.inc"

; Recovery Constants
MAX_RETRIES     equ 3         ; Maximum number of retries for operations
RECOVERY_BUFFER equ 0x9500    ; Buffer for recovery operations
RECOVERY_SIZE   equ SECTOR_SIZE  ; Size of recovery buffer

; Recovery Operations
section .text

; Retry disk operation with error recovery
; Input: AH = BIOS operation (0x02 for read, 0x03 for write)
;       AL = number of sectors
;       CH = cylinder
;       CL = sector
;       DH = head
;       DL = drive
;       ES:BX = buffer
; Output: CF = 0 if successful, CF = 1 if error
;         AX = error code if error
retry_disk_op:
    push bx
    push cx
    push dx
    push es
    push di

    mov di, MAX_RETRIES
.retry_loop:
    ; Save original buffer
    push es
    push bx
    push ax

    ; Try operation
    int BIOS_DISK_INT
    jnc .success

    ; Operation failed, try recovery
    pop ax          ; Restore operation
    pop bx          ; Restore buffer
    pop es          ; Restore segment

    ; Check if we should retry
    dec di
    jz .max_retries

    ; Reset disk system
    push ax
    xor ax, ax
    int BIOS_DISK_INT
    pop ax

    ; Wait a bit before retry
    push ax
    push cx
    mov cx, 0xFFFF
.delay:
    loop .delay
    pop cx
    pop ax

    jmp .retry_loop

.success:
    pop ax          ; Clean up stack
    pop bx
    pop es
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.max_retries:
    mov al, ERR_DISK_READ
    cmp ah, 0x02
    je .set_error
    mov al, ERR_DISK_WRITE
.set_error:
    call set_error
    stc

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Recover FAT chain
; Input: AX = starting cluster
; Output: CF = 0 if successful, CF = 1 if error
;         AX = error code if error
recover_fat_chain:
    push bx
    push cx
    push dx
    push es
    push si
    push di

    ; Save starting cluster
    mov dx, ax

    ; Load FAT into recovery buffer
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x02    ; BIOS read sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .error

    ; Scan for orphaned clusters
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor di, di
    mov cx, MAX_CLUSTERS

.scan_loop:
    mov ax, [es:di]
    and ax, 0x0FFF  ; Get 12-bit value
    cmp ax, FAT_FREE
    je .next_cluster
    cmp ax, FAT_RESERVED
    je .next_cluster
    cmp ax, FAT_BAD
    je .next_cluster
    cmp ax, FAT_EOF
    je .next_cluster

    ; Found orphaned cluster, try to link it
    push di
    mov ax, dx      ; Get starting cluster
    call fat_next
    cmp ax, FAT_EOF
    je .link_cluster
    pop di
    jmp .next_cluster

.link_cluster:
    pop di
    mov word [es:di], FAT_EOF
    mov dx, di      ; Update current cluster

.next_cluster:
    add di, 3       ; Move to next cluster (1.5 bytes per entry)
    shr di, 1       ; Adjust for 12-bit entries
    and di, 0xFFFE  ; Ensure even alignment
    shl di, 1       ; Restore original value
    loop .scan_loop

    ; Write recovered FAT back to disk
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, FAT_SECTORS
    mov ch, 0x00
    mov cl, FAT_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .error

    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.error:
    mov al, ERR_BAD_CHAIN
    call set_error
    stc

.done:
    pop di
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Recover directory entry
; Input: AX = entry offset
; Output: CF = 0 if successful, CF = 1 if error
;         AX = error code if error
recover_dir_entry:
    push bx
    push cx
    push dx
    push es
    push si
    push di

    ; Load directory into recovery buffer
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x02    ; BIOS read sector
    mov al, DIR_SECTORS
    mov ch, 0x00
    mov cl, DIR_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .error

    ; Validate entry
    mov di, ax      ; Entry offset
    mov al, [es:di]
    test al, al
    jz .invalid_entry
    cmp al, 0xE5    ; Deleted entry
    je .invalid_entry

    ; Check if entry has valid cluster
    mov ax, [es:di + DIR_CLUSTER_OFFSET]
    test ax, ax
    jz .invalid_entry
    cmp ax, MAX_CLUSTERS
    jae .invalid_entry

    ; Check if file size is valid (3 bytes)
    mov ax, [es:di + DIR_SIZE_OFFSET]
    mov bl, [es:di + DIR_SIZE_OFFSET + 2]
    mov bh, 0
    mov dx, bx
    cmp dx, MAX_FILE_SIZE
    ja .invalid_entry

    ; Check if cluster chain is valid
    push di
    call fat_next
    pop di
    jc .invalid_entry

    ; Entry is valid
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.invalid_entry:
    ; Mark entry as deleted
    mov byte [es:di], 0xE5

    ; Write directory back to disk
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x03    ; BIOS write sector
    mov al, DIR_SECTORS
    mov ch, 0x00
    mov cl, DIR_START_SECTOR
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .error

    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.error:
    mov al, ERR_SYSTEM
    call set_error
    stc

.done:
    pop di
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    ret

; Recover file data
; Input: AX = starting cluster
;       ES:BX = destination buffer
;       CX = number of bytes to recover
; Output: AX = number of bytes recovered
;         CF = 1 if error
recover_file_data:
    push bx
    push cx
    push dx
    push es
    push si
    push di

    ; Save parameters
    mov dx, ax      ; Starting cluster
    mov si, bx      ; Buffer offset
    push cx         ; Bytes to recover

    ; Read data cluster by cluster
    xor di, di      ; Bytes recovered counter

.recover_loop:
    test cx, cx
    jz .recover_done

    ; Calculate sector number from cluster
    push ax
    mov ax, dx
    add ax, 8       ; Data area starts at sector 8
    mov bx, ax
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor bx, bx

    ; Read sector with retry
    mov ah, 0x02    ; BIOS read sector
    mov al, 1       ; Read 1 sector
    mov ch, 0x00
    mov cl, bl      ; Sector number
    mov dh, 0x00
    mov dl, DISK_FIRST_HD
    call retry_disk_op
    jc .disk_error

    ; Copy data to destination
    push cx
    push si
    push es
    mov ax, RECOVERY_BUFFER
    mov es, ax
    xor di, di
    mov cx, SECTOR_SIZE
    cmp cx, [esp + 4]  ; Compare with remaining bytes
    jbe .copy_ok
    mov cx, [esp + 4]  ; Use remaining bytes
.copy_ok:
    mov bx, di      ; Save di in bx
.copy_loop:
    mov al, [es:bx]
    mov [es:di], al
    inc bx
    inc di
    loop .copy_loop
    pop es
    pop si
    pop cx

    ; Update counters
    sub cx, SECTOR_SIZE
    add di, SECTOR_SIZE
    add si, SECTOR_SIZE

    ; Get next cluster
    pop ax
    mov ax, dx
    call fat_next
    cmp ax, 0xFF8   ; Check for end of file
    jae .recover_done
    mov dx, ax      ; Update current cluster
    jmp .recover_loop

.recover_done:
    mov ax, di      ; Return bytes recovered
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done

.disk_error:
    mov al, ERR_DISK_READ
    call set_error
    xor ax, ax      ; Return 0 on error
    stc

.done:
    pop di
    pop si
    pop es
    pop dx
    pop cx
    pop bx
    ret 

%endif ; RECOVERY_INCLUDED 

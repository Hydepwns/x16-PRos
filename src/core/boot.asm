%include "src/lib/constants.inc"

[BITS 16]
[ORG BOOT_SECTOR_OFF]

; Sector size configuration
%ifndef SECTOR_SIZE
    %define SECTOR_SIZE 512
%endif

; Validate sector size
%if SECTOR_SIZE < 256 || SECTOR_SIZE > 4096
    %error "Invalid sector size. Must be between 256 and 4096 bytes."
%endif

; Calculate sector size dependent values
%define SECTORS_PER_CLUSTER 1
%define FAT_SECTORS 4
%define DIR_SECTORS 4
%define RESERVED_SECTORS 1

; Memory layout
%define BOOT_SECTOR_SEG 0x0000
%define BOOT_SECTOR_OFF 0x7C00
%define FAT_BUFFER_SEG  0x0800
%define FAT_BUFFER_OFF  0x0000
%define DIR_BUFFER_SEG  0x0880
%define DIR_BUFFER_OFF  0x0000
%define KERNEL_SEG      0x0050
%define KERNEL_OFF      0x0000

%include "src/lib/constants.inc"

; Boot sector structure
boot_start:
    ; Jump to boot code
    jmp near boot_code
    nop

    ; File system information
    db "FS"              ; File system signature
    db 0x01             ; Version number
    db SECTORS_PER_CLUSTER  ; Sectors per cluster
    db 0x01             ; Number of FATs
    db 0x40             ; Root directory entries (64)
    dw 0x0B40           ; Total sectors (2880)
    db FAT_SECTORS      ; Sectors per FAT
    db RESERVED_SECTORS ; Reserved sectors
    db "x16-PRos"       ; Volume label (8 bytes)
    db "x16FS"          ; File system type (6 bytes)
    times 230-($-boot_start) db 0  ; Boot code space

boot_code:
    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BOOT_SECTOR_OFF

    ; Set video mode
    call set_video_mode

    ; Display banner
    mov si, banner
    call print_string
    
    mov si, check_msg
    call print_string
    
    ; System checks
    call check_disk
    jc disk_error

    ; All checks passed
    mov si, ready_message
    call print_string
    
    ; Load FAT
    mov ax, FAT_BUFFER_SEG
    mov es, ax
    xor bx, bx
    mov ah, 0x02        ; BIOS read sectors
    mov al, FAT_SECTORS ; Number of sectors to read
    mov ch, 0x00        ; Cylinder 0
    mov cl, FAT_START_SECTOR        ; Start from sector 2
    mov dh, 0x00        ; Head 0
    mov dl, DISK_FIRST_HD        ; First hard disk
    int BIOS_DISK_INT
    jc disk_error

    ; Load root directory
    mov ax, DIR_BUFFER_SEG
    mov es, ax
    xor bx, bx
    mov ah, 0x02        ; BIOS read sectors
    mov al, DIR_SECTORS ; Number of sectors to read
    mov ch, 0x00        ; Cylinder 0
    mov cl, DIR_START_SECTOR        ; Start from sector 6
    mov dh, 0x00        ; Head 0
    mov dl, DISK_FIRST_HD        ; First hard disk
    int BIOS_DISK_INT
    jc disk_error

    mov si, wait_msg
    call print_string
    
    ; Wait for key press
    call wait_for_key

    ; Jump to kernel
    jmp KERNEL_SEG:KERNEL_OFF

; Error handlers
disk_error:
    mov si, disk_error_message
    call print_string
    jmp $

; Utility functions
set_video_mode:
    mov ax, VIDEO_MODE_VGA
    int BIOS_VIDEO_INT
    ret

print_string:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, COLOR_WHITE
.print_char:
    lodsb
    test al, al
    jz .done
    int BIOS_VIDEO_INT
    jmp .print_char
.done:
    ret

wait_for_key:
    mov ah, 0x00
    int BIOS_KEYBOARD_INT
    ret

check_disk:
    mov ah, 0x02
    mov al, 6        
    mov ch, 0         
    mov dh, 0        
    mov cl, FAT_START_SECTOR       
    mov bx, KERNEL_SEG     
    int BIOS_DISK_INT         
    ret

; Data section
banner db "x16-PRos Booting...", CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 0
disk_error_message db "Disk [ERROR]", CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 0
ready_message db "Disk [OK]", CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 
              db "RAM  [OK]", CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 
              db "CPU  [OK]", CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 0
wait_msg db "Press any key to boot...", 0
check_msg db "Checking components:", CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, CHAR_CARRIAGE_RETURN, CHAR_LINEFEED, 0

; Boot signature
times SECTOR_SIZE-2-($-$$) db 0
dw 0xAA55

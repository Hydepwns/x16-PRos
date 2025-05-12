; loader.asm - Minimal bootloader for test harness
; Loads SECTOR_COUNT sectors from sector 1 into 0x8000, then jumps to 0x8000
; Usage: nasm -DSECTOR_COUNT=4 -f bin loader.asm -o loader.bin

org 0x7C00

%ifndef SECTOR_COUNT
SECTOR_COUNT equ 4
%endif

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, msg_loading
    call print_string

    mov bx, 0x8000        ; ES:BX = load address
    mov dh, 0             ; head = 0
    mov dl, 0             ; drive 0 (floppy)
    mov ch, 0             ; cylinder = 0
    mov cl, 2             ; sector = 2 (sector 1 is sector 2 in BIOS)
    mov al, SECTOR_COUNT  ; number of sectors to read
    mov ah, 0x02          ; INT 13h: read sectors
    int 0x13
    jc disk_error

    jmp 0x0000:0x8000     ; jump to loaded test

hang:
    cli
    hlt
    jmp hang

disk_error:
    mov si, msg_error
    call print_string
    jmp hang

print_string:
    mov ah, 0x0E
.next:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .next
.done:
    ret

msg_loading db 'Loading test...', 0
msg_error   db 'Disk error!', 0

; Pad to 510 bytes
 times 510-($-$$) db 0
 dw 0xAA55

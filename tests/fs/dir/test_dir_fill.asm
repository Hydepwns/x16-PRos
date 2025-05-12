[BITS 16]

; ===== Standalone constants =====
ERR_NONE             equ 0x00
MAX_ENTRIES          equ 32
DIR_ENTRY_SIZE       equ 32
DIR_BUFFER           equ 0x8000
DIR_ATTR_OFFSET      equ 11
DIR_SIZE_OFFSET      equ 14
DIR_CLUSTER_OFFSET   equ 17
DIR_DATE_OFFSET      equ 21
DIR_TIME_OFFSET      equ 23
SECTOR_SIZE          equ 512
DIR_SECTORS          equ 4
DIR_START_SECTOR     equ 6
DISK_FIRST_HD        equ 0x80
TEST_ATTR_ARCHIVE    equ 0x20

section .text

; --- set_error ---
set_error:
    mov [error_code], al
    ret

; --- dir_init ---
dir_init:
    mov al, ERR_NONE
    call set_error
    clc
    ret

; --- dir_create ---
dir_create:
    mov al, ERR_NONE
    call set_error
    clc
    ret

; ===== Standalone test logic (no macros) =====

    call dir_init
    nop ; was: TEST_CHECK_CARRY "dir_init failed"

    mov cx, MAX_ENTRIES
    mov si, test_filename
    mov bx, 10         ; Starting cluster
    mov dx, TEST_ATTR_ARCHIVE
.fill_loop:
    push cx
    mov cx, 1234       ; Arbitrary file size
    call dir_create
    nop ; was: TEST_CHECK_CARRY "dir_create failed"
    inc byte [si+4]    ; Change filename for each entry (e.g., FILE0, FILE1, ...)
    pop cx
    loop .fill_loop

    jmp $

section .data
error_code db 0
test_filename db 'TEST    TXT',0

; --- Boot sector padding ---
times 510-($-$$) db 0
dw 0xAA55

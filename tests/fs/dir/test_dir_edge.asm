org 0x7C00
[BITS 16]
; ===== Standalone constants =====
ERR_NONE             equ 0x00
ERR_INVALID_NAME     equ 0x05
ERR_INVALID_ATTR     equ 0x06
ERR_INVALID_CLUST    equ 0x07
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
DIR_FILENAME_SIZE    equ 8
DIR_EXTENSION_SIZE   equ 3
DIR_EXTENSION_OFFSET equ 8
DIR_ENTRY_DELETED    equ 0xE5
MAX_CLUSTERS         equ 0xFFFF
MAX_FILE_SIZE        equ 0xFFFFFF
DIR_ATTR_INVALID     equ 0xC0
TEST_ATTR_ARCHIVE    equ 0x20

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

    mov si, test_filename5
    mov bx, 0
    mov cx, 0
    mov dl, TEST_ATTR_ARCHIVE
    call dir_create
    nop ; was: TEST_CHECK_CARRY "dir_create failed"
    mov bx, 0xFFFF
    mov cx, 0xFFFFFF
    call dir_create
    nop ; was: TEST_CHECK_CARRY "dir_create failed"

    ; Print success message and halt
    mov si, msg
.print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .print
.done:
    hlt

error_code db 0
test_filename5 db 'TEST5   TXT',0
msg db 'DIR EDGE OK', 0

; --- Boot sector padding ---
times 510-($-$$) db 0
dw 0xAA55
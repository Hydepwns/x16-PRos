[BITS 16]

; Include test framework
%include "tests/test_framework.inc"

; Include FAT and directory functions
%include "src/fs/fat.inc"
%include "src/fs/dir/dir.inc"
%include "src/lib/constants.inc"

TEST_START
    ; Test 1: Validate sector size
    TEST_MESSAGE test_fs_init_sector_msg, "Test 1: Validating sector size..."
    
    ; Validate sector size (power of 2 and alignment)
    mov ax, SECTOR_SIZE
    mov bx, ax
    dec bx
    test ax, bx
    TEST_CHECK_CARRY "Invalid sector size (not power of 2)"
    nop
    mov ax, SECTOR_SIZE
    mov bx, 256
    xor dx, dx
    div bx
    test dx, dx
    TEST_CHECK_CARRY "Invalid sector size (not aligned to 256)"
    nop

    ; Test 2: Initialize FAT
    TEST_MESSAGE test_fs_init_fat_msg, "Test 2: Initializing FAT..."
    
    ; Initialize FAT
    call fat_init
    TEST_CHECK_CARRY "fat_init failed"
    nop

    ; Test 3: Initialize directory
    TEST_MESSAGE test_fs_init_dir_msg, "Test 3: Initializing directory..."
    
    ; Initialize directory
    call dir_init
    TEST_CHECK_CARRY "dir_init failed"
    nop

TEST_ERROR
TEST_END
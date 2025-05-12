[BITS 16]

; Include test framework and data
%include "tests/test_framework.inc"
%include "tests/test_data.inc"

; Include file functions
%include "src/fs/file.asm"
%include "src/fs/recovery.asm"
%include "src/lib/constants.inc"
%include "src/fs/fat.inc"

TEST_START
    ; Initialize FAT
    call fat_init
    TEST_CHECK_CARRY "fat_init failed"
    nop

    ; Test 1: Basic file size operations
    TEST_MESSAGE test_file_size_valid_msg, "Test 1: Basic file size operations..."

    ; Create test file
    mov si, test_filename
    mov dl, TEST_ATTR_ARCHIVE
    call file_create
    TEST_CHECK_CARRY "file_create failed"
    nop

    ; Write test data
    mov si, test_filename
    mov ax, TEST_BUFFER_SEG1
    mov es, ax
    xor bx, bx
    mov si, test_data
    mov cx, test_data_len
    call file_write
    TEST_CHECK_CARRY "file_write failed"
    nop

    ; Get file size
    mov si, test_filename
    call file_size
    TEST_CHECK_CARRY "file_size failed"
    nop
    cmp ax, test_data_len
    TEST_CHECK_NO_CARRY "file_size failed"
    nop

    ; Test 2: File size recovery
    TEST_MESSAGE test_file_size_recovery_msg, "Test 2: File size recovery..."

    ; Create another file
    mov si, test_filename2
    mov dl, TEST_ATTR_ARCHIVE
    call file_create
    TEST_CHECK_CARRY "file_create failed"
    nop

    ; Write test data
    mov si, test_filename2
    mov ax, TEST_BUFFER_SEG2
    mov es, ax
    xor bx, bx
    mov si, test_data
    mov cx, test_data_len
    call file_write
    TEST_CHECK_CARRY "file_write failed"
    nop

    ; Corrupt file size in directory entry
    mov ax, DIR_BUFFER
    mov es, ax
    mov di, ax      ; Entry offset
    mov dword [es:di + DIR_SIZE_OFFSET], 0xFFFFFFFF  ; Invalid size

    ; Try to recover file size
    mov ax, di
    call recover_file_size
    TEST_CHECK_CARRY "recover_file_size failed"
    nop

    ; Verify file size was fixed
    mov si, test_filename2
    call file_size
    TEST_CHECK_CARRY "file_size failed"
    nop
    cmp ax, test_data_len
    TEST_CHECK_NO_CARRY "file_size failed"
    nop

    ; Test 3: Create file with initial size
    TEST_MESSAGE test_file_size_create_msg, "Test 3: Create file with initial size..."

    ; Create file
    mov ax, test_filename
    mov bx, 10      ; Starting cluster
    mov cx, 100     ; Initial size
    call file_create
    TEST_CHECK_CARRY "file_create failed"
    nop

    ; Get file size
    mov ax, test_filename
    call file_get_size
    TEST_CHECK_CARRY "file_get_size failed"
    nop
    cmp ax, 100
    TEST_CHECK_NO_CARRY "file_get_size failed"
    nop

    ; Test 4: Grow file
    TEST_MESSAGE test_file_size_grow_msg, "Test 4: Grow file..."

    ; Write data
    mov ax, test_filename
    mov bx, test_data
    mov cx, test_data_size
    call file_write
    TEST_CHECK_CARRY "file_write failed"
    nop

    ; Get new size
    mov ax, test_filename
    call file_get_size
    TEST_CHECK_CARRY "file_get_size failed"
    nop
    cmp ax, test_data_size
    TEST_CHECK_NO_CARRY "file_get_size failed"
    nop

    ; Test 5: Shrink file
    TEST_MESSAGE test_file_size_shrink_msg, "Test 5: Shrink file..."

    ; Write smaller data
    mov ax, test_filename
    mov bx, test_data2
    mov cx, test_data2_size
    call file_write
    TEST_CHECK_CARRY "file_write failed"
    nop

    ; Get new size
    mov ax, test_filename
    call file_get_size
    TEST_CHECK_CARRY "file_get_size failed"
    nop
    cmp ax, test_data2_size
    TEST_CHECK_NO_CARRY "file_get_size failed"
    nop

    ; Test 6: Delete file
    TEST_MESSAGE test_file_size_delete_msg, "Test 6: Delete file..."

    ; Delete file
    mov ax, test_filename
    call file_delete
    TEST_CHECK_CARRY "file_delete failed"
    nop

    ; Verify file is deleted
    mov ax, test_filename
    call file_exists
    TEST_CHECK_CARRY "file_exists failed"
    nop
    cmp ax, 0
    TEST_CHECK_NO_CARRY "file_exists failed"
    nop

TEST_ERROR
TEST_END
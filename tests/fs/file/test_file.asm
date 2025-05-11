[BITS 16]

; Include test framework and data
%include "tests/test_framework.inc"
%include "tests/test_data.inc"

; Include file functions
%include "src/fs/file.asm"
%include "src/lib/constants.inc"

TEST_START
    ; Initialize file system
    call file_init
    TEST_CHECK_CARRY

    ; Test 1: Create and write file
    TEST_MESSAGE test_file_create_msg, "Test 1: Create and write file..."

    ; Create file
    mov ax, test_filename
    mov bx, 10      ; Starting cluster
    mov cx, 100     ; File size
    call file_create
    TEST_CHECK_CARRY

    ; Write data
    mov ax, test_filename
    mov bx, test_data
    mov cx, test_data_size
    call file_write
    TEST_CHECK_CARRY

    ; Test 2: Read file
    TEST_MESSAGE test_file_read_msg, "Test 2: Read file..."

    ; Read data
    mov ax, test_filename
    mov bx, test_buffer
    mov cx, test_data_size
    call file_read
    TEST_CHECK_CARRY

    ; Verify data
    mov si, test_data
    mov di, test_buffer
    mov cx, test_data_size
    repe cmpsb
    TEST_CHECK_NO_CARRY

    ; Test 3: Update file
    TEST_MESSAGE test_file_update_msg, "Test 3: Update file..."

    ; Update data
    mov ax, test_filename
    mov bx, test_data2
    mov cx, test_data2_size
    call file_write
    TEST_CHECK_CARRY

    ; Read updated data
    mov ax, test_filename
    mov bx, test_buffer
    mov cx, test_data2_size
    call file_read
    TEST_CHECK_CARRY

    ; Verify updated data
    mov si, test_data2
    mov di, test_buffer
    mov cx, test_data2_size
    repe cmpsb
    TEST_CHECK_NO_CARRY

    ; Test 4: Delete file
    TEST_MESSAGE test_file_delete_msg, "Test 4: Delete file..."

    ; Delete file
    mov ax, test_filename
    call file_delete
    TEST_CHECK_CARRY

    ; Verify file is deleted
    mov ax, test_filename
    call file_exists
    TEST_CHECK_CARRY
    cmp ax, 0
    TEST_CHECK_NO_CARRY

TEST_ERROR
TEST_END 
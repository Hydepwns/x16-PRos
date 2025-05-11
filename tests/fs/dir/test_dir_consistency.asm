[BITS 16]

; Include test framework and data
%include "tests/test_framework.inc"
%include "tests/test_data.inc"

; Include directory functions
%include "src/fs/dir/core.asm"
%include "src/fs/dir/list.asm"
%include "src/fs/dir/helpers.asm"
%include "src/lib/constants.inc"

TEST_START
    ; Initialize directory
    call dir_init
    TEST_CHECK_CARRY

    ; Test 1: Create and verify file
    TEST_MESSAGE test_dir_consistency_create_msg, "Test 1: Create and verify file..."

    ; Create a file
    mov si, test_filename
    mov bx, 10         ; Starting cluster
    mov cx, 1234       ; File size
    mov dl, TEST_ATTR_ARCHIVE
    call dir_create
    TEST_CHECK_CARRY

    ; Verify file exists
    mov si, test_filename
    call dir_find
    TEST_CHECK_CARRY

    ; Test 2: Update file attributes
    TEST_MESSAGE test_dir_consistency_attr_msg, "Test 2: Update file attributes..."

    ; Update attributes
    mov dl, TEST_ATTR_READONLY
    call dir_set_attributes
    TEST_CHECK_CARRY

    ; Verify attributes
    call dir_get_attributes
    TEST_CHECK_CARRY
    cmp al, TEST_ATTR_READONLY
    TEST_CHECK_NO_CARRY

    ; Test 3: Update file size
    TEST_MESSAGE test_dir_consistency_size_msg, "Test 3: Update file size..."

    ; Update size
    mov cx, 5678
    call dir_set_size
    TEST_CHECK_CARRY

    ; Verify size
    call dir_get_size
    TEST_CHECK_CARRY
    cmp cx, 5678
    TEST_CHECK_NO_CARRY

    ; Test 4: Update starting cluster
    TEST_MESSAGE test_dir_consistency_cluster_msg, "Test 4: Update starting cluster..."

    ; Update cluster
    mov bx, 20
    call dir_set_cluster
    TEST_CHECK_CARRY

    ; Verify cluster
    call dir_get_cluster
    TEST_CHECK_CARRY
    cmp bx, 20
    TEST_CHECK_NO_CARRY

    ; Test 5: Delete and verify
    TEST_MESSAGE test_dir_consistency_delete_msg, "Test 5: Delete and verify..."

    ; Delete file
    call dir_delete
    TEST_CHECK_CARRY

    ; Verify deletion
    mov si, test_filename
    call dir_find
    TEST_CHECK_NO_CARRY

TEST_ERROR
TEST_END 
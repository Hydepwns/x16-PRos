[BITS 16]

; Include test framework and data
%include "tests/test_framework.inc"
%include "tests/test_data.inc"

; Include FAT functions
%include "src/fs/fat.asm"
%include "src/lib/constants.inc"

TEST_START
    ; Initialize FAT
    call fat_init
    TEST_CHECK_CARRY

    ; Test 1: Create and validate chain
    TEST_MESSAGE test_fat_chain_create_msg, "Test 1: Create and validate chain..."

    ; Allocate first cluster
    call fat_alloc
    TEST_CHECK_CARRY
    mov bx, ax      ; Save first cluster

    ; Allocate second cluster
    call fat_alloc
    TEST_CHECK_CARRY
    mov cx, ax      ; Save second cluster

    ; Link clusters
    mov ax, bx
    call fat_set_next
    TEST_CHECK_CARRY

    ; Validate chain
    mov ax, bx
    call fat_validate_chain
    TEST_CHECK_CARRY

    ; Test 2: Test chain traversal
    TEST_MESSAGE test_fat_chain_traverse_msg, "Test 2: Test chain traversal..."

    ; Get next cluster
    mov ax, bx
    call fat_get_next
    TEST_CHECK_CARRY
    cmp ax, cx
    TEST_CHECK_NO_CARRY

    ; Test 3: Test chain modification
    TEST_MESSAGE test_fat_chain_modify_msg, "Test 3: Test chain modification..."

    ; Allocate new cluster
    call fat_alloc
    TEST_CHECK_CARRY
    mov dx, ax      ; Save new cluster

    ; Update chain
    mov ax, bx
    mov bx, dx
    call fat_set_next
    TEST_CHECK_CARRY

    ; Verify chain
    mov ax, bx
    call fat_get_next
    TEST_CHECK_CARRY
    cmp ax, dx
    TEST_CHECK_NO_CARRY

    ; Test 4: Test chain deletion
    TEST_MESSAGE test_fat_chain_delete_msg, "Test 4: Test chain deletion..."

    ; Free chain
    mov ax, bx
    call fat_free_chain
    TEST_CHECK_CARRY

    ; Verify chain is freed
    mov ax, bx
    call fat_get_next
    TEST_CHECK_CARRY
    cmp ax, FAT_FREE
    TEST_CHECK_NO_CARRY

TEST_ERROR
TEST_END 
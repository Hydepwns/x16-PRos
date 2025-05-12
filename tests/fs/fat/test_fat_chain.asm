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
    TEST_CHECK_CARRY "fat_init failed"
    nop

    ; Test 1: Create and validate chain
    TEST_MESSAGE test_fat_chain_create_msg, "Test 1: Create and validate chain..."

    ; Allocate first cluster
    call fat_alloc
    TEST_CHECK_CARRY "fat_alloc failed"
    nop
    mov bx, ax      ; Save first cluster

    ; Allocate second cluster
    call fat_alloc
    TEST_CHECK_CARRY "fat_alloc failed"
    nop
    mov cx, ax      ; Save second cluster

    ; Link clusters
    mov ax, bx
    call fat_set_next
    TEST_CHECK_CARRY "fat_set_next failed"
    nop

    ; Validate chain
    mov ax, bx
    call fat_validate_chain
    TEST_CHECK_CARRY "fat_validate_chain failed"
    nop

    ; Test 2: Test chain traversal
    TEST_MESSAGE test_fat_chain_traverse_msg, "Test 2: Test chain traversal..."

    ; Get next cluster
    mov ax, bx
    call fat_get_next
    TEST_CHECK_CARRY "fat_get_next failed"
    nop
    cmp ax, cx
    TEST_CHECK_NO_CARRY "FAT get_next (1) unexpected result"
    nop

    ; Test 3: Test chain modification
    TEST_MESSAGE test_fat_chain_modify_msg, "Test 3: Test chain modification..."

    ; Allocate new cluster
    call fat_alloc
    TEST_CHECK_CARRY "fat_alloc failed"
    nop
    mov dx, ax      ; Save new cluster

    ; Update chain
    mov ax, bx
    mov bx, dx
    call fat_set_next
    TEST_CHECK_CARRY "fat_set_next failed"
    nop

    ; Verify chain
    mov ax, bx
    call fat_get_next
    TEST_CHECK_CARRY "fat_get_next failed"
    nop
    cmp ax, dx
    TEST_CHECK_NO_CARRY "FAT get_next (2) unexpected result"
    nop

    ; Test 4: Test chain deletion
    TEST_MESSAGE test_fat_chain_delete_msg, "Test 4: Test chain deletion..."

    ; Free chain
    mov ax, bx
    call fat_free_chain
    TEST_CHECK_CARRY "fat_free_chain failed"
    nop

    ; Verify chain is freed
    mov ax, bx
    call fat_get_next
    cmp ax, FAT_FREE
    TEST_CHECK_NO_CARRY "FAT get_next (3) unexpected result (not free)"
    nop

TEST_ERROR "Reached end of test without success"
TEST_END 
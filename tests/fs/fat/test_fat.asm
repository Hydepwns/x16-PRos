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

    ; Test 1: Allocate and free clusters
    TEST_MESSAGE test_fat_alloc_msg, "Test 1: Allocate and free clusters..."

    ; Allocate a cluster
    call fat_alloc
    TEST_CHECK_CARRY
    mov bx, ax      ; Save cluster number

    ; Free the cluster
    mov ax, bx
    call fat_free
    TEST_CHECK_CARRY

    ; Test 2: Test cluster chain operations
    TEST_MESSAGE test_fat_chain_msg, "Test 2: Test cluster chain operations..."

    ; Allocate two clusters
    call fat_alloc
    TEST_CHECK_CARRY
    mov bx, ax      ; First cluster
    call fat_alloc
    TEST_CHECK_CARRY
    mov cx, ax      ; Second cluster

    ; Link clusters
    mov ax, bx
    call fat_set_next
    TEST_CHECK_CARRY

    ; Get next cluster
    mov ax, bx
    call fat_get_next
    TEST_CHECK_CARRY
    cmp ax, cx
    TEST_CHECK_NO_CARRY

    ; Test 3: Test cluster validation
    TEST_MESSAGE test_fat_validate_msg, "Test 3: Test cluster validation..."

    ; Check valid cluster
    mov ax, bx
    call fat_is_valid
    TEST_CHECK_CARRY

    ; Check invalid cluster
    mov ax, 0xFFFF
    call fat_is_valid
    TEST_CHECK_NO_CARRY

    ; Test 4: Test cluster chain validation
    TEST_MESSAGE test_fat_chain_validate_msg, "Test 4: Test cluster chain validation..."

    ; Create a valid chain
    mov ax, bx
    call fat_validate_chain
    TEST_CHECK_CARRY

    ; Create an invalid chain
    mov ax, 0xFFFF
    call fat_validate_chain
    TEST_CHECK_NO_CARRY

TEST_ERROR
TEST_END 
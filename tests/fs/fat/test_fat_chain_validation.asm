; Test: FAT Chain Validation (Expanded)
; -----------------------------------
; This test sets up several small FATs and calls fat_validate_chain.

%include "tests/test_framework.inc"
%include "src/lib/constants.inc"
%include "src/fs/fat/check.asm"
%include "src/fs/fat.inc"

section .text
    global test_fat_chain_validation

test_fat_chain_validation:
    TEST_START

    ; --- Case 1: Valid chain (2 -> 3 -> 4 -> EOF) ---
    mov ax, FAT_BUFFER
    mov es, ax
    ; Set up FAT: cluster 2 -> 3, 3 -> 4, 4 -> EOF
    mov word [es:4], 0x003   ; cluster 2 (offset 4) = 3
    mov word [es:6], 0x004   ; cluster 3 (offset 6) = 4
    mov word [es:8], 0xFF8   ; cluster 4 (offset 8) = EOF

    mov si, 2                ; Start at cluster 2
    mov di, 0xB800           ; Bitmap buffer
    call fat_validate_chain
    cmp ax, 0
    jne fail_valid
    TEST_MESSAGE msg_valid_chain, "FAT chain validation: valid chain passed"

    ; --- Case 2: Cycle (2 -> 3 -> 2) ---
    mov word [es:4], 0x003   ; cluster 2 = 3
    mov word [es:6], 0x002   ; cluster 3 = 2 (cycle)

    mov si, 2
    mov di, 0xB800
    call fat_validate_chain
    cmp ax, 1
    jne fail_cycle
    TEST_MESSAGE msg_cycle, "FAT chain validation: cycle detected correctly"

    ; --- Case 3: Invalid cluster (2 -> 9999) ---
    mov word [es:4], 9999    ; cluster 2 = 9999 (invalid)

    mov si, 2
    mov di, 0xB800
    call fat_validate_chain
    cmp ax, 2
    jne fail_invalid
    TEST_MESSAGE msg_invalid, "FAT chain validation: invalid cluster detected correctly"

    ; --- Case 4: Premature end (2 -> 0) ---
    mov word [es:4], 0x000   ; cluster 2 = 0 (invalid/premature end)

    mov si, 2
    mov di, 0xB800
    call fat_validate_chain
    cmp ax, 2
    jne fail_premature
    TEST_MESSAGE msg_premature, "FAT chain validation: premature end detected correctly"

    ; --- Case 5: Double-allocation (2 -> 3, 3 -> EOF, 4 -> 3) ---
    ; This is not detected by a single chain walk, but can be checked by walking both 2 and 4
    ; First, walk from 2 (should be valid)
    mov word [es:4], 0x003   ; cluster 2 = 3
    mov word [es:6], 0xFF8   ; cluster 3 = EOF
    mov word [es:8], 0x003   ; cluster 4 = 3 (double-allocated)

    mov si, 2
    mov di, 0xB800
    call fat_validate_chain
    cmp ax, 0
    jne fail_double1
    TEST_MESSAGE msg_double1, "FAT chain validation: double-allocation (first walk) passed"
    ; Now, walk from 4 (should detect cycle, since 3 is already visited in previous walk if bitmap is reused)
    mov si, 4
    mov di, 0xB800
    call fat_validate_chain
    cmp ax, 1
    jne fail_double2
    TEST_MESSAGE msg_double2, "FAT chain validation: double-allocation (second walk) detected as cycle"

    ; --- Case 6: Orphaned cluster (cluster 5 marked as used, not referenced) ---
    mov word [es:10], 0xFF8  ; cluster 5 = EOF (orphaned, not in any chain)
    ; Walk from 2 (should be valid, orphan not detected by this routine)
    mov si, 2
    mov di, 0xB800
    call fat_validate_chain
    cmp ax, 0
    jne fail_orphan
    TEST_MESSAGE msg_orphan, "FAT chain validation: orphaned cluster (not detected by single chain walk, as expected)"

    TEST_END

fail_valid:
    TEST_ERROR "FAT chain validation: valid chain failed"
fail_cycle:
    TEST_ERROR "FAT chain validation: cycle not detected"
fail_invalid:
    TEST_ERROR "FAT chain validation: invalid cluster not detected"
fail_premature:
    TEST_ERROR "FAT chain validation: premature end not detected"
fail_double1:
    TEST_ERROR "FAT chain validation: double-allocation (first walk) failed"
fail_double2:
    TEST_ERROR "FAT chain validation: double-allocation (second walk) not detected as cycle"
fail_orphan:
    TEST_ERROR "FAT chain validation: orphaned cluster test failed"
    TEST_END
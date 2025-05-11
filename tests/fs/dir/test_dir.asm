[BITS 16]

; Include test framework and data
%include "tests/test_framework.inc"
%include "tests/test_data.inc"

; Include directory functions
%include "src/lib/constants.inc"

extern set_error
extern get_error
extern print_error
extern error_messages
extern print_string
extern print_char
extern print_newline
extern print_hex
extern print_space
extern dir_init
extern dir_create
extern dir_find
extern dir_delete

TEST_START
    ; Initialize directory
    call dir_init
    TEST_CHECK_CARRY

    ; Test 1: Fill directory to capacity
    TEST_MESSAGE test_dir_fill_msg, "Test 1: Fill directory to capacity..."

    ; Fill the directory to capacity
    mov cx, MAX_ENTRIES
    mov si, test_filename
    mov bx, 10         ; Starting cluster
    mov dx, TEST_ATTR_ARCHIVE
.fill_loop:
    push cx
    mov cx, 1234       ; Arbitrary file size
    call dir_create
    TEST_CHECK_CARRY
    inc byte [si+4]    ; Change filename for each entry (e.g., FILE0, FILE1, ...)
    pop cx
    loop .fill_loop

    ; Test 2: Test directory overflow
    TEST_MESSAGE test_dir_overflow_msg, "Test 2: Test directory overflow..."

    ; Try to add one more file (should fail)
    mov si, test_filename2
    mov bx, 99
    mov cx, 4321
    mov dl, TEST_ATTR_ARCHIVE
    call dir_create
    TEST_CHECK_NO_CARRY  ; Should set carry flag (error)

    ; Test 3: Test file deletion
    TEST_MESSAGE test_dir_delete_msg, "Test 3: Test file deletion..."

    ; Delete the 3rd file (simulate deletion)
    mov si, test_filename3
    call dir_find
    TEST_CHECK_CARRY
    call dir_delete
    TEST_CHECK_CARRY

    ; Test 4: Test file attributes
    TEST_MESSAGE test_dir_attr_msg, "Test 4: Test file attributes..."

    ; Add a file with each attribute
    mov si, test_filename4
    mov bx, 55
    mov cx, 555
    mov dl, 0x01       ; Read-only
    call dir_create
    TEST_CHECK_CARRY
    mov dl, 0x02       ; Hidden
    call dir_create
    TEST_CHECK_CARRY
    mov dl, 0x04       ; System
    call dir_create
    TEST_CHECK_CARRY
    mov dl, 0x08       ; Volume
    call dir_create
    TEST_CHECK_CARRY
    mov dl, 0x10       ; Directory
    call dir_create
    TEST_CHECK_CARRY
    mov dl, 0x20       ; Archive
    call dir_create
    TEST_CHECK_CARRY

    ; Test 5: Test edge cases
    TEST_MESSAGE test_dir_edge_msg, "Test 5: Test edge cases..."

    ; Add files with edge-case sizes and clusters
    mov si, test_filename5
    mov bx, 0
    mov cx, 0
    mov dl, TEST_ATTR_ARCHIVE
    call dir_create
    TEST_CHECK_CARRY
    mov bx, 0xFFFF
    mov cx, 0xFFFFFF
    call dir_create
    TEST_CHECK_CARRY

TEST_ERROR
TEST_END

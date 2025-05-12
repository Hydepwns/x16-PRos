%ifndef TEST_FRAMEWORK_INCLUDED
%define TEST_FRAMEWORK_INCLUDED

[BITS 16]

; Include required files
%include "src/lib/constants.inc"
%include "src/lib/io.inc"

; Extern declarations for symbols defined in errors.asm
extern set_error
extern get_error
extern print_error
extern error_messages
extern msg_none
extern msg_disk_read
extern msg_disk_write
extern msg_invalid_param
extern msg_not_found
extern msg_already_exists
extern msg_invalid_attr
extern msg_invalid_size
extern msg_invalid_cluster
extern msg_invalid_filename
extern msg_dir_full
extern msg_fat_full
extern msg_no_space
extern error_code

; Test Framework Macros and Constants
%macro TEST_START 0
    section .text
        global _start
    _start:
%endmacro

%macro TEST_END 0
%%.success_msg: db "All tests passed!", 13, 10, 0
    section .text
    mov si, %%.success_msg
    call print_string
    cli
    hlt
%endmacro

%macro TEST_ERROR 1
%%.errmsg: db %1, 13, 10, 0
    section .text
    mov si, %%.errmsg
    call print_string
    cli
    hlt
%endmacro

%macro TEST_MESSAGE 2
    section .text
    %1: db %2, 13, 10, 0
    mov si, %1
    call print_string
%endmacro

; Test error handling macros
DEFAULT_CARRY_MSG: db "Error: Carry flag not set as expected.", 13, 10, 0

%macro TEST_CHECK_CARRY 1
    jnc %%no_error
    TEST_ERROR %1
%%no_error:
%endmacro

%macro TEST_CHECK_NO_CARRY 1
    jc %%no_error
    TEST_ERROR %1
%%no_error:
%endmacro

; Include test_data.inc in your test files for test data and filenames

; Common test attributes
TEST_ATTR_READONLY equ 0x01
TEST_ATTR_HIDDEN   equ 0x02
TEST_ATTR_SYSTEM   equ 0x04
TEST_ATTR_VOLUME   equ 0x08
TEST_ATTR_DIR      equ 0x10
TEST_ATTR_ARCHIVE  equ 0x20

; Common test buffer segments
TEST_BUFFER_SEG1 equ 0x1000
TEST_BUFFER_SEG2 equ 0x2000
TEST_BUFFER_SEG3 equ 0x3000
TEST_BUFFER_SEG4 equ 0x4000

%endif ; TEST_FRAMEWORK_INCLUDED

%ifndef TEST_FRAMEWORK_INCLUDED
%define TEST_FRAMEWORK_INCLUDED

[BITS 16]

; Include required files
%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/fs/errors.asm"

; Test Framework Macros and Constants
%macro TEST_START 0
    section .text
        global _start
    _start:
%endmacro

%macro TEST_END 0
    test_done:
        mov si, test_success_msg
        call print_string
        cli
        hlt
    test_success_msg: db "All tests passed!", 13, 10, 0
%endmacro

%macro TEST_ERROR 0
    test_error_label:
        mov si, test_error_msg
        call print_string
        jmp test_done
    test_error_msg: db "Test failed!", 13, 10, 0
%endmacro

%macro TEST_MESSAGE 2
    %ifndef TEST_MESSAGE_DATA_SECTION
        %define TEST_MESSAGE_DATA_SECTION
        section .data
    %endif
    %1: db %2, 13, 10, 0
    section .text
    mov si, %1
    call print_string
%endmacro

; Test error handling macros
%macro TEST_CHECK_CARRY 0
    jc test_error_label
%endmacro

%macro TEST_CHECK_NO_CARRY 0
    jnc test_error_label
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
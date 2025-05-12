; =============================================
; x16-PRos Test IO Library (Stub for tests)
; =============================================

%ifndef IO_INCLUDED
%define IO_INCLUDED

%include "src/lib/constants.inc"

; Extern declarations for test linkage
extern print_string
extern print_char
extern print_hex
extern print_newline
extern print_space

; Color-specific print macros (for test output)
%macro print_string_white 0
    mov bl, COLOR_WHITE
    call print_string
%endmacro

%macro print_string_red 0
    mov bl, COLOR_LIGHT_RED
    call print_string
%endmacro

%macro print_string_green 0
    mov bl, COLOR_LIGHT_GREEN
    call print_string
%endmacro

%macro print_string_blue 0
    mov bl, COLOR_LIGHT_BLUE
    call print_string
%endmacro

%macro print_string_cyan 0
    mov bl, COLOR_LIGHT_CYAN
    call print_string
%endmacro

%macro print_string_yellow 0
    mov bl, COLOR_YELLOW
    call print_string
%endmacro

%macro print_string_magenta 0
    mov bl, COLOR_LIGHT_MAGENTA
    call print_string
%endmacro

%endif ; IO_INCLUDED

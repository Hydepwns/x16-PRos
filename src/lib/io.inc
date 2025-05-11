; =============================================
; x16-PRos IO Library
; =============================================

%ifndef IO_INCLUDED
%define IO_INCLUDED

%include "src/lib/constants.inc"
%include "src/lib/ui.inc"

; External symbols from io.asm
extern input_buffer
extern error_messages
extern err_none_msg
extern err_disk_read_msg
extern err_disk_write_msg
extern err_invalid_sect_msg
extern err_invalid_clust_msg
extern err_no_space_msg
extern err_dir_full_msg
extern err_file_exists_msg
extern err_file_not_found_msg
extern err_invalid_name_msg
extern err_access_denied_msg
extern err_bad_chain_msg
extern err_invalid_size_msg
extern err_buffer_overflow_msg
extern err_invalid_attr_msg
extern err_system_msg

; External functions from io.asm
extern read_char
extern read_char_silent
extern read_string
extern print_char
extern print_string
extern print_number
extern print_hex
extern print_newline
extern print_space
extern display_error

; Color-specific print macros
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
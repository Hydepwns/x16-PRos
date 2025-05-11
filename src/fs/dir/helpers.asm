[BITS 16]

; Include constants
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"

; External error handling functions
extern set_error
extern get_error
extern print_error
extern error_messages

; External symbols
extern print_hex
extern print_string
extern print_newline
extern print_char
extern print_space

; Directory Helper Functions
section .text

; Include guard
%ifndef DIR_HELPERS_INCLUDED
%define DIR_HELPERS_INCLUDED

; Validate filename
; Input:
;   - si: pointer to filename
; Output:
;   - carry flag: set if invalid
validate_filename:
    push ax
    push bx
    push cx
    push si

    ; Check name length
    mov cx, 8       ; Maximum name length
.check_name:
    lodsb
    test al, al
    jz .check_ext   ; End of name
    cmp al, ' '     ; Space is not allowed
    je .invalid
    cmp al, '.'     ; Dot is not allowed
    je .invalid
    loop .check_name
    jmp .check_ext

.next_char:
    lodsb
    test al, al
    jz .valid       ; End of string
    cmp al, ' '     ; Space is not allowed
    je .invalid
    cmp al, '.'     ; Dot is not allowed
    je .invalid
    jmp .next_char

.check_ext:
    mov si, [esp]   ; Restore filename pointer
    add si, 8       ; Skip to extension
    mov cx, 3       ; Maximum extension length
.check_ext_loop:
    lodsb
    test al, al
    jz .valid       ; No extension is valid
    cmp al, ' '     ; Space is not allowed
    je .invalid
    cmp al, '.'     ; Dot is not allowed
    je .invalid
    loop .check_ext_loop
    jmp .valid

.next_ext:
    lodsb
    test al, al
    jz .valid       ; End of string
    cmp al, ' '     ; Space is not allowed
    je .invalid
    cmp al, '.'     ; Dot is not allowed
    je .invalid
    jmp .next_ext

.valid:
    clc             ; Clear carry flag (valid)
    jmp .done

.invalid:
    stc             ; Set carry flag (invalid)

.done:
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Convert filename to directory entry format
; Input:
;   - si: pointer to source filename
;   - di: pointer to destination buffer
convert_filename:
    push ax
    push bx
    push cx
    push si
    push di

    ; Copy name
    mov cx, 8       ; Maximum name length
.copy_name:
    lodsb
    test al, al
    jz .pad_name    ; End of name
    cmp al, '.'
    je .find_ext    ; Found extension
    stosb           ; Copy character
    loop .copy_name
    jmp .pad_name

.pad_name:
    mov al, ' '     ; Pad with spaces
    rep stosb

.find_ext:
    mov si, [esp]   ; Restore filename pointer
    add si, 8       ; Skip to extension
    mov cx, 3       ; Maximum extension length
.copy_ext:
    lodsb
    test al, al
    jz .pad_ext     ; End of extension
    cmp al, '.'
    je .copy_ext_loop
    stosb           ; Copy character
    loop .copy_ext
    jmp .pad_ext

.copy_ext_loop:
    lodsb
    test al, al
    jz .pad_ext     ; End of extension
    stosb           ; Copy character
    loop .copy_ext_loop

.pad_ext:
    mov al, ' '     ; Pad with spaces
    rep stosb

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Get file size from directory entry
; Input:
;   - si: pointer to directory entry
; Output:
;   - eax: file size
get_file_size:
    push si
    mov eax, [si + DIR_SIZE_OFFSET]
    pop si
    ret

; Get starting cluster from directory entry
; Input:
;   - si: pointer to directory entry
; Output:
;   - ax: starting cluster
get_start_cluster:
    push si
    mov ax, [si + DIR_CLUSTER_OFFSET]
    pop si
    ret

; Get file attributes from directory entry
; Input:
;   - si: pointer to directory entry
; Output:
;   - al: attributes
get_attributes:
    push si
    mov al, [si + DIR_ATTR_OFFSET]
    pop si
    ret

; Set file attributes in directory entry
; Input:
;   - si: pointer to directory entry
;   - al: attributes
set_attributes:
    push si
    mov [si + DIR_ATTR_OFFSET], al
    pop si
    ret

; Get file date from directory entry
; Input:
;   - si: pointer to directory entry
; Output:
;   - ax: date
get_file_date:
    push si
    mov ax, [si + DIR_DATE_OFFSET]
    pop si
    ret

; Get file time from directory entry
; Input:
;   - si: pointer to directory entry
; Output:
;   - ax: time
get_file_time:
    push si
    mov ax, [si + DIR_TIME_OFFSET]
    pop si
    ret

%endif ; DIR_HELPERS_INCLUDED 

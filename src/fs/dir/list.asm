[BITS 16]

; Include error handling and constants
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"
%include "src/lib/io.inc"

; External symbols
extern print_hex
extern print_newline
extern print_space
extern print_char
extern print_string

; External error handling functions
extern set_error
extern get_error
extern print_error
extern error_messages

; Directory Listing Functions
section .text

; List directory contents
; Input: None
; Output: None
dir_list:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    push si

    ; Load directory into memory
    mov ax, DIR_BUFFER
    mov es, ax
    xor bx, bx
    mov ah, 0x02    ; BIOS read sector
    mov al, DIR_SECTORS
    mov ch, 0x00    ; Cylinder 0
    mov cl, DIR_START_SECTOR
    mov dh, 0x00    ; Head 0
    mov dl, DISK_FIRST_HD    ; First hard disk
    int BIOS_DISK_INT
    jc .disk_error

    ; Print header
    mov si, dir_header
    call print_string
    call print_newline
    mov si, dir_separator
    call print_string
    call print_newline

    ; List entries
    xor di, di      ; Start at first entry
    mov cx, MAX_ENTRIES

.list_loop:
    ; Check if entry is free or deleted
    mov al, [es:di]
    test al, al
    jz .next_entry
    cmp al, DIR_ENTRY_DELETED
    je .next_entry

    ; Print filename
    push cx
    push di
    mov cx, DIR_FILENAME_SIZE
.print_filename:
    mov al, [es:di]
    call print_char
    inc di
    loop .print_filename
    pop di
    pop cx

    ; Print extension
    push cx
    push di
    add di, DIR_EXTENSION_OFFSET
    mov cx, DIR_EXTENSION_SIZE
.print_extension:
    mov al, [es:di]
    call print_char
    inc di
    loop .print_extension
    pop di
    pop cx

    ; Print attributes
    push cx
    push di
    add di, DIR_ATTR_OFFSET
    mov al, [es:di]
    call print_attributes
    pop di
    pop cx

    ; Print file size (3 bytes)
    push cx
    push di
    add di, DIR_SIZE_OFFSET
    mov ax, [es:di]        ; Get first two bytes
    call print_hex
    mov al, [es:di+2]      ; Get third byte
    call print_hex
    pop di
    pop cx

    ; Print starting cluster
    push cx
    push di
    add di, DIR_CLUSTER_OFFSET
    mov ax, [es:di]
    call print_hex
    pop di
    pop cx

    ; Print date
    push cx
    push di
    add di, DIR_DATE_OFFSET
    mov ax, [es:di]
    call print_date
    pop di
    pop cx

    ; Print time
    push cx
    push di
    add di, DIR_TIME_OFFSET
    mov ax, [es:di]
    call print_time
    pop di
    pop cx

    call print_newline

.next_entry:
    add di, DIR_ENTRY_SIZE
    loop .list_loop

    mov al, ERR_NONE
    call set_error
    jmp .done

.disk_error:
    mov al, ERR_DISK_READ
    call set_error

.done:
    pop si
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print file attributes
; Input: AL = attributes byte
; Output: None
print_attributes:
    push ax
    push bx
    push cx

    mov cx, 8       ; 8 bits to check
    mov bl, al      ; Save attributes in bl

.attr_loop:
    mov al, '0'     ; Default to '0'
    test bl, 1      ; Test lowest bit
    jz .print_bit
    mov al, '1'     ; Set to '1' if bit is set
.print_bit:
    call print_char
    shr bl, 1       ; Shift right to check next bit
    loop .attr_loop

    call print_space

    pop cx
    pop bx
    pop ax
    ret

; Print date in MM/DD/YY format
; Input: AX = date (2 bytes)
; Output: None
print_date:
    push ax
    push bx
    push cx

    ; Extract month (bits 15-9)
    mov bx, ax
    shr bx, 9
    and bx, 0x1F    ; 5 bits for month
    mov al, bl
    call print_decimal
    mov al, '/'
    call print_char

    ; Extract day (bits 8-4)
    mov bx, ax
    shr bx, 4
    and bx, 0x1F    ; 5 bits for day
    mov al, bl
    call print_decimal
    mov al, '/'
    call print_char

    ; Extract year (bits 3-0)
    mov bx, ax
    and bx, 0x0F    ; 4 bits for year
    add bx, 80      ; Base year is 1980
    mov al, bl
    call print_decimal

    call print_space

    pop cx
    pop bx
    pop ax
    ret

; Print time in HH:MM:SS format
; Input: AX = time (2 bytes)
; Output: None
print_time:
    push ax
    push bx
    push cx

    ; Extract hour (bits 15-11)
    mov bx, ax
    shr bx, 11
    and bx, 0x1F    ; 5 bits for hour
    mov al, bl
    call print_decimal
    mov al, ':'
    call print_char

    ; Extract minute (bits 10-5)
    mov bx, ax
    shr bx, 5
    and bx, 0x3F    ; 6 bits for minute
    mov al, bl
    call print_decimal
    mov al, ':'
    call print_char

    ; Extract second (bits 4-0)
    mov bx, ax
    and bx, 0x1F    ; 5 bits for second
    shl bx, 1       ; Multiply by 2 (seconds are stored in 2-second units)
    mov al, bl
    call print_decimal

    call print_space

    pop cx
    pop bx
    pop ax
    ret

; Print decimal number
; Input: AL = number to print
; Output: None
print_decimal:
    push ax
    push bx
    push cx
    push dx

    mov bl, 10      ; Divisor
    xor cx, cx      ; Digit counter

.div_loop:
    xor ah, ah      ; Clear high byte
    div bl          ; Divide by 10
    push ax         ; Save remainder
    inc cx          ; Count digits
    test al, al     ; Check if more digits
    jnz .div_loop

.print_loop:
    pop ax          ; Get digit
    mov al, ah      ; Move remainder to al
    add al, '0'     ; Convert to ASCII
    call print_char
    loop .print_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Data section
section .data
dir_header: db "Filename    Ext  Attr    Size    Cluster  Date       Time", 0
dir_separator: db "--------------------------------------------------------", 0 

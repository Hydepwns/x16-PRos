%include "src/lib/constants.inc"
%include "src/lib/io.inc"
%include "src/lib/utils.inc"

[BITS 16]

; External symbols from shell module
extern shell_init
extern shell_run

; External symbols from services module
extern print_interface
extern print_help
extern print_CPU_info
extern get_date
extern get_time
extern shutdown
extern reboot
extern launch_writer
extern launch_brainf

; External symbols from CPU module
extern print_edx
extern print_full_name_part
extern print_cores
extern print_cache_line
extern print_stepping
extern print_al

; External symbols from loader module
extern load_program
extern read_number
extern start_program

; External symbols from memory module
extern memory_init
extern memory_alloc
extern memory_free

; External symbols from interrupt module
extern interrupts_init
extern register_handler
extern enable_interrupt
extern disable_interrupt

; External symbols from process module
extern process_init
extern process_create
extern process_terminate
extern process_schedule

section .text

; Constants
KERNEL_ORG equ 0x0500

kernel_start:
    ; Initialize segments
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Initialize video mode
    mov ax, 0x0003  ; 80x25 text mode
    int BIOS_VIDEO_INT

    ; Initialize core modules
    call initialize_core_modules
    jc .init_error

    ; Initialize shell
    call shell_init
    call shell_run

    ; If we get here, something went wrong
    jmp $

.init_error:
    ; Handle initialization error (halt or loop)
    cli
    hlt

; Initialize core modules
; Output: CF = 1 if initialization failed
initialize_core_modules:
    push ax
    push bx
    push cx
    push dx

    mov si, msg_starting
    call print_string

    call memory_init
    call check_error
    jc .error_mem
    mov si, msg_mem_ok
    call print_string

    call interrupts_init
    call check_error
    jc .error_int
    mov si, msg_int_ok
    call print_string

    call process_init
    call check_error
    jc .error_proc
    mov si, msg_proc_ok
    call print_string

    mov al, 0x20
    mov bx, timer_handler
    call register_handler
    call check_error
    jc .error_timer
    mov si, msg_timer_ok
    call print_string

    mov al, 0x20
    call enable_interrupt
    call check_error
    jc .error_enable
    mov si, msg_enable_ok
    call print_string

    call create_system_processes
    call check_error
    jc .error_sysproc
    mov si, msg_sysproc_ok
    call print_string

    clc
    jmp .done

.error_mem:
    mov si, msg_init_error
    call print_string
    mov al, [error_code]
    call print_hex
    stc
    jmp .done

.error_int:
    mov si, msg_init_error
    call print_string
    mov al, [error_code]
    call print_hex
    stc
    jmp .done

.error_proc:
    mov si, msg_init_error
    call print_string
    mov al, [error_code]
    call print_hex
    stc
    jmp .done

.error_timer:
    mov si, msg_init_error
    call print_string
    mov al, [error_code]
    call print_hex
    stc
    jmp .done

.error_enable:
    mov si, msg_init_error
    call print_string
    mov al, [error_code]
    call print_hex
    stc
    jmp .done

.error_sysproc:
    mov si, msg_init_error
    call print_string
    mov al, [error_code]
    call print_hex
    stc
    jmp .done

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Create system processes
; Output: CF = 1 if process creation failed
create_system_processes:
    push ax
    push bx
    push cx

    ; Create shell process
    mov ax, shell_run   ; Entry point
    mov bx, 4096        ; Stack size
    mov cl, 1           ; Priority
    call process_create
    call check_error
    jc .error

    ; Create idle process
    mov ax, idle_loop   ; Entry point
    mov bx, 1024        ; Stack size
    mov cl, 0           ; Priority
    call process_create
    call check_error
    jc .error

    clc                 ; Clear carry flag to indicate success
    jmp .done

.error:
    stc                 ; Set carry flag to indicate error

.done:
    pop cx
    pop bx
    pop ax
    ret

; Timer interrupt handler
timer_handler:
    push ax
    push bx
    push cx
    push dx

    ; Schedule next process
    call process_schedule

    ; Send EOI to PIC
    mov al, 0x20
    out 0x20, al

    pop dx
    pop cx
    pop bx
    pop ax
    iret

; Idle process loop
idle_loop:
    hlt                 ; Halt CPU until next interrupt
    jmp idle_loop

; Check for error after module call
; Input: None
; Output: CF = 1 if error occurred
check_error:
    push ax
    mov al, [error_code]
    test al, al
    jz .no_error
    stc                 ; Set carry flag to indicate error
    jmp .done
.no_error:
    clc                 ; Clear carry flag to indicate success
.done:
    pop ax
    ret

; Data section
section .data
error_code db 0
msg_starting db "Starting kernel...", 13, 10, 0
msg_mem_ok db "Memory OK", 13, 10, 0
msg_int_ok db "Interrupts OK", 13, 10, 0
msg_proc_ok db "Process OK", 13, 10, 0
msg_timer_ok db "Timer handler OK", 13, 10, 0
msg_enable_ok db "Timer enabled", 13, 10, 0
msg_sysproc_ok db "System processes OK", 13, 10, 0
msg_init_error db "INIT ERROR! Code: ", 0

section .text

; Removed duplicate kernel_start definition and its code

; Set video mode
set_video_mode:
    pusha
    mov ax, VIDEO_MODE_VGA
    int BIOS_VIDEO_INT
    popa
    ret

; Move cursor to top of screen
move_cursor_to_top:
    xor dx, dx
    call set_cursor_pos
    ret

; Set background color
set_background_color:
    mov ah, 0x06
    mov al, 0x00
    mov bh, COLOR_BLACK
    mov cx, 0x0000
    mov dx, 0x184F
    int BIOS_VIDEO_INT
    ret

shell:
    mov si, prompt
    mov bl, 0x0F
    call print_string
    call read_command
    call print_command_buffer
    call print_newline
    call execute_command
    jmp shell

; ===================== Shell =====================

read_command:
    mov di, command_buffer
    xor cx, cx          ; Clear character counter
.read_loop:
    mov ah, 0x00
    int BIOS_KEYBOARD_INT            ; Wait for keypress, result in AL
    mov ah, al          ; Save character in AH for later use
    
    ; Echo character in default color
    mov ah, 0x0E
    mov bl, 0x0F        ; White color
    int BIOS_VIDEO_INT
    
    ; Debug: print key in cyan
    mov ah, 0x0E
    mov bl, 0x0B        ; Cyan color
    int BIOS_VIDEO_INT
    
    mov al, ah          ; Restore character from AH
    
    cmp al, CHAR_CARRIAGE_RETURN        ; Enter?
    je .done_read
    cmp al, CHAR_BACKSPACE        ; Backspace?
    je .handle_backspace
    
    ; Check for printable characters
    cmp al, CHAR_SPACE         ; Space is lowest printable ASCII
    jb .read_loop
    cmp al, '~'         ; Tilde is highest printable ASCII
    ja .read_loop
    
    ; Check buffer limit
    cmp cx, COMMAND_BUFFER_SIZE-1         ; Buffer limit
    jae .read_loop
    
    ; Store character and increment counter
    stosb
    inc cx
    jmp .read_loop

.handle_backspace:
    cmp cx, 0           ; If buffer is empty, ignore backspace
    je .read_loop
    
    ; Move cursor back
    mov ah, 0x0E
    mov bl, 0x0F        ; White color
    mov al, CHAR_BACKSPACE        ; Backspace
    int BIOS_VIDEO_INT
    mov al, CHAR_SPACE         ; Space
    int BIOS_VIDEO_INT
    mov al, CHAR_BACKSPACE        ; Backspace again
    int BIOS_VIDEO_INT
    
    ; Update buffer position and counter
    dec di
    dec cx
    jmp .read_loop

.done_read:
    mov byte [di], 0    ; Null-terminate
    
    ; Trim trailing spaces
    mov di, command_buffer
    add di, cx
.trim_trailing:
    dec di
    cmp di, command_buffer
    jb .set_zero
    mov al, [di]
    cmp al, CHAR_SPACE
    je .trim_trailing
.set_zero:
    mov byte [di+1], 0
    ret

execute_command:
    mov si, command_buffer
    ; Проверка команды "help"
    mov di, help_str
    call compare_strings
    je do_help
    
    mov si, command_buffer
    ; Проверка команды "info"
    mov di, info_str
    call compare_strings
    je print_OS_info

    mov si, command_buffer
    ; Проверка команды "cls"
    mov di, cls_str
    call compare_strings
    je do_cls
    
    mov si, command_buffer
    ; Проверка команды "CPU"
    mov di, CPU_str
    call compare_strings
    je do_CPUinfo
    
    mov si, command_buffer
    ; Проверка команды "date"
    mov di, date_str
    call compare_strings
    je print_date
    
    mov si, command_buffer
    ; Проверка команды "time"
    mov di, time_str
    call compare_strings
    je print_time

    mov si, command_buffer
    ; Проверка команды "shut"
    mov di, shut_str
    call compare_strings
    je do_shutdown
    
    mov si, command_buffer
    ; Проверка команды "reboot"
    mov di, reboot_str
    call compare_strings
    je do_reboot
   
    mov si, command_buffer
    ; Проверка команды "writer"
    mov di, writer_str
    call compare_strings
    je start_writer
    
    mov si, command_buffer
    ; Проверка команды "brainf"
    mov di, brainf_str
    call compare_strings
    je start_brainf
    
    mov si, command_buffer
    ; Проверка команды "barchart"
    mov di, barchart_str
    call compare_strings
    je start_barchart
    
    mov si, command_buffer
    ; Проверка команды "snake"
    mov di, snake_str
    call compare_strings
    je start_snake
    
    mov si, command_buffer
    ; Проверка команды "calc"
    mov di, calc_str
    call compare_strings
    je start_calc
    
    mov si, command_buffer
    ; Проверка команды "load"
    mov di, load_str
    call compare_strings
    je load_program

    call unknown_command
    ret

help_str db 'help', 0
info_str db 'info', 0
cls_str db 'cls', 0
shut_str db 'shut', 0
reboot_str db 'reboot', 0
CPU_str db 'CPU', 0
date_str db 'date', 0
time_str db 'time', 0
load_str db 'load', 0
writer_str db 'writer', 0
brainf_str db 'brainf', 0
barchart_str db 'barchart', 0
snake_str db 'snake', 0
calc_str db 'calc', 0

; ===================== Other =====================
do_banner:
    call print_interface
    call print_newline
    ret

do_help:
    call print_newline
    call print_help
    call print_newline
    ret

do_cls:
    pusha
    mov ax, 0x12
    int 0x10
    popa
    ret

unknown_command:
    mov si, unknown_msg
    mov bl, 0x0C
    call print_string
    call print_newline
    ret

do_shutdown:
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    ret
    
do_reboot:
    int 0x19
    ret
    
print_OS_info:
    mov si, info
    mov bl, 0x0A
    call print_string
    call print_newline
    ret
       
;===================== Start programs =====================

start_writer:
    pusha
    mov ah, 0x02
    mov al, 2
    mov ch, 0
    mov dh, 0
    mov cl, 9
    mov bx, 800h
    int 0x13
    jc .disk_error
    jmp 800h
.disk_error:
    mov si, disk_error_msg
    mov bl, 0x0C
    call print_string
    call print_newline
    popa
    ret
    
start_brainf:
    pusha
    mov ah, 0x02
    mov al, 2
    mov ch, 0
    mov dh, 0
    mov cl, 12
    mov bx, 800h
    int 0x13
    jc .disk_error
    jmp 800h
.disk_error:
    mov si, disk_error_msg
    mov bl, 0x0C
    call print_string
    call print_newline
    popa
    ret
   
start_barchart:
    pusha
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov dh, 0
    mov cl, 15
    mov bx, 800h
    int 0x13
    jc .disk_error
    jmp 800h
.disk_error:
    mov si, disk_error_msg
    mov bl, 0x0C
    call print_string
    call print_newline
    popa
    ret
    
start_snake:
    pusha
    mov ah, 0x02
    mov al, 2
    mov ch, 0
    mov dh, 0
    mov cl, 16
    mov bx, 800h
    int 0x13
    jc .disk_error
    jmp 800h
.disk_error:
    mov si, disk_error_msg
    mov bl, 0x0C
    call print_string
    call print_newline
    popa
    ret
    
start_calc:
    pusha
    mov ah, 0x02
    mov al, 2
    mov ch, 0
    mov dh, 0
    mov cl, 18
    mov bx, 800h
    int 0x13
    jc .disk_error
    jmp 800h
.disk_error:
    mov si, disk_error_msg
    mov bl, 0x0C
    call print_string
    call print_newline
    popa
    ret

; ===================== CPU info functions ===================== 
print_edx:
    mov ah, 0eh

    mov bx, 4
    loop4r:
        mov al, dl
        int 10h
        ror edx, 8

        dec bx
        cmp bx, 0
        jne loop4r
    ret
    
print_full_name_part:
    cpuid
    push edx
    push ecx
    push ebx
    push eax

    mov cx, 4
loop4n:
    pop edx
    call print_edx

    dec cx
    cmp cx, 0
    jne loop4n

    ret

print_cores:
    mov si, cores
    mov bl, 0x0F
    call print_string
    mov eax, 1
    cpuid
    ror ebx, 16
    mov al, bl
    call print_al
    ret

print_cache_line:
    mov si, cache_line
    mov bl, 0x0F
    call print_string
    mov eax, 1
    cpuid
    ror ebx, 8
    mov al, bl
    mov bl, 8
    mul bl
    call print_al
    ret

print_stepping:
    mov si, stepping
    mov bl, 0x0F
    call print_string
    mov eax, 1
    cpuid
    and al, 15
    call print_al
    ret
 
print_al:
    mov ah, 0
    mov dl, 10
    div dl
    add ax, '00'
    mov dx, ax

    mov ah, 0eh
    mov al, dl
    cmp dl, '0'
    jz skip_fn
    mov bl, 0x0F
    int 10h
skip_fn:
    mov al, dh
    mov bl, 0x0F
    int 10h
    ret
    
do_CPUinfo:
    pusha
    mov si, cpu_name
    mov bl, 0x0F
    call print_string
    ; Выводим информацию о ЦПУ
    mov eax, 80000002h
    call print_full_name_part
    mov eax, 80000003h
    call print_full_name_part
    mov eax, 80000004h
    call print_full_name_part
    mov si, mt
    mov bl, 0x0F
    call print_string
    call print_cores
    mov si, mt
    call print_string
    call print_cache_line
    mov si, mt
    call print_string
    call print_stepping
    mov si, mt
    call print_string
    popa
    ret
    
cpu_name db '  CPU name: ', 0
cores db '  CPU cores: ', 0
stepping db '  Stepping ID: ', 0
cache_line db '  Cache line: ', 0

; ===================== About OS =====================

info db 10, 13
     db '+----------------------------------------------+', 10, 13
     db '|  x16 PRos is the simple 16 bit operating     |', 10, 13
     db '|  system written in NASM for x86 PC`s         |', 10, 13
     db '|----------------------------------------------|', 10, 13
     db '|  Autor: PRoX (https://github.com/PRoX2011)   |', 10, 13
     db '|  Amount of disk sectors: 25                  |', 10, 13
     db '|  OS version: 0.2.6                           |', 10, 13
     db '+==============================================+', 10, 13, 0

; ===================== Date and time functions =====================

; Функция для вывода даты
; Выводит дату в формате DD.MM.YY
print_date:
    mov si, date_msg
    mov bl, 0x0F
    call print_string
    
    pusha
    ; Получить дату
    mov ah, 0x04
    int 0x1a  ; Получаем дату: ch - век, cl - год, dh - месяц, dl - день

    mov ah, 0x0e  ; Установить функцию для вывода символа

    ; Вывести день (dl)
    mov al, dl
    shr al, 4
    add al, '0'  ; Преобразовать в ASCII
    mov bl, 0x0F
    int 0x10     ; Выводим
    mov al, dl
    and al, 0x0F
    add al, '0'  ; Преобразовать в ASCII
    int 0x10     ; Выводим

    ; Вывести точку
    mov al, '.'
    mov bl, 0x0F
    int 0x10

    ; Вывести месяц (dh)
    mov al, dh
    shr al, 4
    add al, '0'
    mov bl, 0x0F
    int 0x10
    mov al, dh
    and al, 0x0F
    add al, '0'
    mov bl, 0x0F
    int 0x10

    ; Вывести точку
    mov al, '.'
    mov bl, 0x0F
    int 0x10

    ; Вывести год (cl)
    mov al, cl
    shr al, 4
    add al, '0'
    mov bl, 0x0F
    int 0x10
    mov al, cl
    and al, 0x0F
    add al, '0'
    mov bl, 0x0F
    int 0x10
    
    mov si, mt
    mov bl, 0x0F
    call print_string
    
    popa
    ret
    
date_msg db 'Current date: ', 0

; Функция для вывода времяни
; Выводит дату в формате HH.MM.SS
print_time:
    mov si, time_msg
    mov bl, 0x0F
    call print_string
    
    pusha
    ; Получить время
    mov ah, 0x02
    int 0x1a  ; Получаем время: ch - часы, cl - минуты, dh - секунды

    mov ah, 0x0e  ; Установить функцию для вывода символа

    ; Вывести часы
    mov al, ch
    shr al, 4
    add al, '0'  ; Преобразовать в ASCII
    mov bl, 0x0F
    int 0x10     ; Выводим
    mov al, ch
    and al, 0x0F
    add al, '0'  ; Преобразовать в ASCII
    mov bl, 0x0F
    int 0x10     ; Выводим

    ; Вывести разделитель
    mov al, ':'
    mov bl, 0x0F
    int 0x10

    ; Вывести минуты
    mov al, cl
    shr al, 4
    add al, '0'
    mov bl, 0x0F
    int 0x10
    mov al, cl
    and al, 0x0F
    add al, '0'
    mov bl, 0x0F
    int 0x10

    ; Вывести разделитель
    mov al, ':'
    mov bl, 0x0F
    int 0x10

    ; Вывести секунды
    mov al, dh
    shr al, 4
    add al, '0'
    mov bl, 0x0F
    int 0x10
    mov al, dh
    and al, 0x0F
    add al, '0'
    mov bl, 0x0F
    int 0x10
    
    mov si, mt
    mov bl, 0x0F
    call print_string
    
    popa
    ret
    
time_msg db 'Current time: ', 0

; ===================== Load Command =====================

load_program:
    mov si, load_prompt
    mov bl, 0x0F
    call print_string
    call read_number  ; Читаем номер сектора
    call print_newline

    ; Загружаем программу с указанного сектора
    call start_program
    ret

read_number:
    mov di, number_buffer
    xor cx, cx
.read_loop:
    mov ah, 0x00
    int BIOS_KEYBOARD_INT
    cmp al, 0x0D      ; Проверка на Enter
    je .done_read
    cmp al, 0x08      ; Проверка на Backspace
    je .handle_backspace
    cmp cx, 5         ; Максимальная длина числа (5 цифр)
    jge .read_loop    ; Если достигнут максимум, игнорируем ввод
    cmp al, '0'       ; Проверка, что символ является цифрой
    jb .read_loop
    cmp al, '9'
    ja .read_loop
    stosb             ; Сохраняем символ в буфер
    mov ah, 0x0E      ; Выводим символ на экран
    mov bl, 0x1F
    int BIOS_VIDEO_INT
    inc cx            ; Увеличиваем счётчик введённых символов
    jmp .read_loop

.handle_backspace:
    cmp cx, 0         ; If buffer is empty, ignore backspace
    je .read_loop
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int BIOS_VIDEO_INT
    mov al, ' '       ; Print space to erase character
    int BIOS_VIDEO_INT
    mov al, 0x08      ; Move cursor back again
    int BIOS_VIDEO_INT
    jmp .read_loop

.done_read:
    mov byte [di], 0  ; Завершаем строку нулевым символом
    call utils_convert_to_number  ; Преобразуем строку в число
    ret

kernel_convert_to_number:
    mov si, number_buffer
    xor ax, ax
    xor cx, cx
.convert_loop:
    lodsb
    cmp al, 0         ; Проверка на конец строки
    je .done_convert
    sub al, '0'       ; Преобразуем символ в цифру
    imul cx, 10       ; Умножаем текущее значение на 10
    add cx, ax        ; Добавляем новую цифру
    jmp .convert_loop
.done_convert:
    mov [sector_number], cx  ; Сохраняем число в переменную
    ret

start_program:
    pusha
    mov ah, 0x02      ; Функция чтения сектора
    mov al, 1         ; Количество секторов для чтения
    mov ch, 0         ; Номер дорожки (цилиндра)
    mov dh, 0         ; Номер головки
    mov cl, [sector_number]  ; Номер сектора
    mov bx, 800h      ; Адрес, куда загружать данные
    int 0x13
    jc .disk_error    ; Если ошибка, переходим к обработке ошибки
    jmp 800h          ; Переход к загруженной программе
    popa
    ret

.disk_error:
    mov si, disk_error_msg
    mov bl, 0x0C
    call print_string
    popa
    ret

load_prompt db 'Enter sector number: ', 0
disk_error_msg db 'Disk read error!', 0
number_buffer db 6 dup(0)
sector_number dw 0

; ===================== Data section =====================

header db '============================= x16 PRos v0.2 ====================================', 0
menu db '+-----------------------------------------------+', 10, 13
     db '|Commands:                                      |', 10, 13
     db '|  help - get list of the commands              |', 10, 13
     db '|  info - print information about OS            |', 10, 13
     db '|  cls - clear terminal                         |', 10, 13
     db '|  shut - shutdown PC                           |', 10, 13
     db '|  reboot - go to bootloader (restart system)   |', 10, 13
     db '|  date - print current date (DD.MM.YY)         |', 10, 13
     db '|  time - print current time (HH.MM.SS)         |', 10, 13
     db '|  CPU - print CPU info                         |', 10, 13
     db '|  load - load program from disk sector         |', 10, 13
     db '|  writer - text editor                         |', 10, 13
     db '|  brainf - brainf IDE                          |', 10, 13
     db '|  barchart - charting soft (by Loxsete)        |', 10, 13
     db '|  snake - snake game                           |', 10, 13
     db '|  calc - calculator program (by Saeta)         |', 10, 13
     db '+===============================================+', 0
unknown_msg db 'Unknown command.', 0
prompt db '[PRos] > ', 0
mt db '', 10, 13, 0
buffer db 512 dup(0)
command_buffer db 128 dup(0)

; ===================== Debug print for command buffer =====================
global print_command_buffer
print_command_buffer:
    mov si, command_buffer
    mov bl, 0x0B
    call print_string
    ret

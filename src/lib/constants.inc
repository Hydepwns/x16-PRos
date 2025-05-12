; =============================================
; x16-PRos Constants Library
; =============================================

%ifndef CONSTANTS_INCLUDED
%define CONSTANTS_INCLUDED

; =============================================
; BIOS Interrupts
; =============================================
BIOS_VIDEO_INT        equ 0x10
BIOS_KEYBOARD_INT     equ 0x16
BIOS_DISK_INT         equ 0x13
BIOS_TIME_INT         equ 0x1A
BIOS_WAIT_INT         equ 0x15
BIOS_INT              equ 0x1A   ; Standard BIOS time/date interrupt
BIOS_GET_DATE         equ 0x04   ; Function: Get Date (INT 1Ah, AH=04h)
BIOS_GET_TIME         equ 0x02   ; Function: Get Time (INT 1Ah, AH=02h)

; =============================================
; Video Mode Constants
; =============================================
VIDEO_MODE_VGA        equ 0x12    ; VGA 640x480
VIDEO_MODE_TEXT       equ 0x03    ; Text mode 80x25
SCREEN_WIDTH          equ 80      ; Width of the screen in characters
SCREEN_HEIGHT         equ 25      ; Text mode height
SCREEN_SIZE           equ 2000    ; 80 * 25

; =============================================
; Color Constants
; =============================================
COLOR_BLACK           equ 0x00
COLOR_BLUE            equ 0x01
COLOR_GREEN           equ 0x02
COLOR_CYAN            equ 0x03
COLOR_RED             equ 0x04
COLOR_MAGENTA         equ 0x05
COLOR_BROWN           equ 0x06
COLOR_LIGHT_GRAY      equ 0x07
COLOR_DARK_GRAY       equ 0x08
COLOR_LIGHT_BLUE      equ 0x09
COLOR_LIGHT_GREEN     equ 0x0A
COLOR_LIGHT_CYAN      equ 0x0B
COLOR_LIGHT_RED       equ 0x0C
COLOR_LIGHT_MAGENTA   equ 0x0D
COLOR_YELLOW          equ 0x0E
COLOR_WHITE           equ 0x0F

; =============================================
; Special Characters
; =============================================
CHAR_BACKSPACE        equ 0x08
CHAR_TAB             equ 0x09
CHAR_LINEFEED        equ 0x0A
CHAR_CARRIAGE_RETURN equ 0x0D
CHAR_ESCAPE          equ 0x1B
CHAR_SPACE           equ 0x20

; =============================================
; Buffer Sizes
; =============================================
INPUT_BUFFER_SIZE     equ 128
COMMAND_BUFFER_SIZE   equ 128
%define SECTOR_SIZE 512

; =============================================
; Memory Addresses
; =============================================
VIDEO_MEMORY_SEG     equ 0xB800
KERNEL_SEGMENT       equ 0x0050
KERNEL_OFFSET        equ 0x0000
BOOT_SECTOR_SEG      equ 0x0000
BOOT_SECTOR_OFF      equ 0x7C00
KERNEL_START_SECTOR  equ 10      ; Kernel starts at sector 10 (data area)

; =============================================
; Disk Constants
; =============================================
DISK_FIRST_HD        equ 0x80
FAT_START_SECTOR     equ 2
FAT_SECTORS          equ 4
DIR_START_SECTOR     equ 6
DIR_SECTORS          equ 4

; =============================================
; FAT Constants
; =============================================
FAT_FREE            equ 0x000
FAT_RESERVED        equ 0xFF0
FAT_BAD             equ 0xFF7
FAT_EOF             equ 0xFF8
MAX_FILE_SIZE       equ 0xFFFFFF ; Maximum file size (3 bytes)

; =============================================
; Directory Constants
; =============================================
DIR_BUFFER           equ 0x8000     ; Directory buffer in memory (moved to avoid conflicts)
DIR_ENTRY_SIZE       equ 32         ; Size of each directory entry in bytes
DIR_FILENAME_SIZE    equ 8          ; Size of filename in directory entry
DIR_EXTENSION_SIZE   equ 3          ; Size of extension in directory entry
DIR_ATTR_SIZE        equ 1          ; Size of attributes in directory entry
DIR_RESERVED1_SIZE   equ 2          ; Size of first reserved field
DIR_SIZE_SIZE        equ 3          ; Size of file size field
DIR_CLUSTER_SIZE     equ 2          ; Size of starting cluster field
DIR_RESERVED2_SIZE   equ 2          ; Size of second reserved field
DIR_DATE_SIZE        equ 2          ; Size of date field
DIR_TIME_SIZE        equ 2          ; Size of time field
MAX_ENTRIES          equ 32         ; Maximum number of directory entries

; Directory Entry Offsets
DIR_FILENAME_OFFSET  equ 0          ; Filename offset in entry
DIR_EXTENSION_OFFSET equ 8          ; Extension offset in entry
DIR_ATTR_OFFSET      equ 11         ; Attributes offset in entry
DIR_RESERVED1_OFFSET equ 12         ; First reserved field offset
DIR_SIZE_OFFSET      equ 14         ; File size offset in entry
DIR_CLUSTER_OFFSET   equ 17         ; Starting cluster offset in entry
DIR_RESERVED2_OFFSET equ 19         ; Second reserved field offset
DIR_DATE_OFFSET      equ 21         ; Date offset in entry
DIR_TIME_OFFSET      equ 23         ; Time offset in entry

; Directory Entry Attributes
DIR_ATTR_READONLY    equ 0x01       ; Read-only attribute
DIR_ATTR_HIDDEN      equ 0x02       ; Hidden attribute
DIR_ATTR_SYSTEM      equ 0x04       ; System attribute
DIR_ATTR_VOLUME      equ 0x08       ; Volume label attribute
DIR_ATTR_DIRECTORY   equ 0x10       ; Directory attribute
DIR_ATTR_ARCHIVE     equ 0x20       ; Archive attribute
DIR_ATTR_INVALID     equ 0xC0       ; Invalid attribute bits mask

; Directory Entry Status
DIR_ENTRY_FREE       equ 0x00       ; Free entry
DIR_ENTRY_DELETED    equ 0xE5       ; Deleted entry

; =============================================
; Error Codes
; =============================================
ERR_NONE            equ 0x00
ERR_DISK_READ       equ 0x01
ERR_DISK_WRITE      equ 0x02
ERR_FILE_NOT_FOUND  equ 0x03
ERR_FILE_EXISTS     equ 0x04
ERR_INVALID_NAME    equ 0x05
ERR_INVALID_ATTR    equ 0x06
ERR_INVALID_CLUST   equ 0x07
ERR_BAD_CHAIN       equ 0x08
ERR_SYSTEM          equ 0x09
ERR_DIR_FULL        equ 0x0A

; =============================================
; Game Constants
; =============================================
GAME_FRAME_DELAY     equ 3       ; Frame delay in clock ticks
GAME_BORDER_CHAR     equ 0x02FE  ; Border character
GAME_SNAKE_CHAR      equ '*'     ; Snake body character
GAME_FOOD_CHAR       equ 'o'     ; Food character
GAME_DIR_UP          equ '^'     ; Up direction character
GAME_DIR_DOWN        equ 'v'     ; Down direction character
GAME_DIR_LEFT        equ '<'     ; Left direction character
GAME_DIR_RIGHT       equ '>'     ; Right direction character
GAME_KEY_UP          equ 17      ; W key
GAME_KEY_LEFT        equ 30      ; A key
GAME_KEY_DOWN        equ 31      ; S key
GAME_KEY_RIGHT       equ 32      ; D key
GAME_KEY_NEW         equ 177     ; N key (new game)
GAME_BORDER_WIDTH    equ 38      ; Game border width
GAME_BORDER_HEIGHT   equ 16      ; Game border height
GAME_SCORE_INCREMENT equ 4       ; Points per food eaten

; Snake Game Specific Constants
GAME_SNAKE_BUFFER_SIZE equ 256   ; Size of snake buffer in words
GAME_MSG_NAME_POS     equ (SCREEN_WIDTH*3)+42  ; Position of game name
GAME_MSG_SCORE_POS    equ (SCREEN_WIDTH*3)+94  ; Position of score display
GAME_MSG_CONTROLS_POS equ (SCREEN_WIDTH*21)+40 ; Position of controls message
GAME_MSG_FAIL_POS     equ (SCREEN_WIDTH*19)+92 ; Position of fail message
GAME_BORDER_START     equ (SCREEN_WIDTH*4)+40  ; Start position of game border
GAME_BORDER_END       equ (SCREEN_WIDTH*20)+42 ; End position of game border
GAME_SCORE_DISPLAY    equ (SCREEN_WIDTH*3)+114 ; Position of score value
GAME_MIN_FOOD_Y       equ (SCREEN_WIDTH*5)     ; Minimum Y position for food
GAME_FOOD_RETRIES     equ 5                    ; Maximum retries for food placement
GAME_FOOD_MULTIPLIER  equ 75                   ; Random number multiplier
GAME_FOOD_DIVISOR     equ 65537                ; Random number divisor

; =============================================
; File Constants
; =============================================
FILE_BUFFER           equ 0x8800     ; File buffer in memory (moved to avoid conflicts)
FILE_MAX_SIZE         equ 0xFFFFFF   ; Maximum file size (3 bytes in directory entry)
FILE_DATA_START       equ 10         ; Data area starts at sector 10 (after FAT and directory)
FILE_READ_RETRIES     equ 3          ; Number of retries for file operations
FILE_WRITE_RETRIES    equ 3          ; Number of retries for file operations
FILE_READ_SECTORS     equ 1          ; Number of sectors to read at once
FILE_WRITE_SECTORS    equ 1          ; Number of sectors to write at once

; =============================================
; Common UI Constants
; =============================================
UI_MSG_HELPER_POS    equ (SCREEN_WIDTH*0)+0   ; Position of helper message
UI_MSG_FOOTER_POS    equ (SCREEN_WIDTH*24)+0  ; Position of footer message
UI_MSG_SEPARATOR_POS equ (SCREEN_WIDTH*17)+0  ; Position of separator line
UI_MSG_HELPER_LEN    equ 82                   ; Length of helper message
UI_MSG_FOOTER_LEN    equ 80                   ; Length of footer message
UI_INPUT_START_Y     equ 2                    ; Y position for input start
UI_OUTPUT_START_Y    equ 20                   ; Y position for output start

; =============================================
; Brainfuck Constants
; =============================================
BF_WORKSPACE_SIZE    equ 30000               ; Size of brainfuck workspace
BF_INSTR_INC_PTR     equ '>'                 ; Increment pointer instruction
BF_INSTR_DEC_PTR     equ '<'                 ; Decrement pointer instruction
BF_INSTR_INC_VAL     equ '+'                 ; Increment value instruction
BF_INSTR_DEC_VAL     equ '-'                 ; Decrement value instruction
BF_INSTR_OUTPUT      equ '.'                 ; Output value instruction
BF_INSTR_INPUT       equ ','                 ; Input value instruction
BF_INSTR_LOOP_START  equ '['                 ; Start loop instruction
BF_INSTR_LOOP_END    equ ']'                 ; End loop instruction

; =============================================
; Calculator Constants
; =============================================
CALC_STEP_INPUT1      equ 0    ; Step: Input first number
CALC_STEP_INPUT2      equ 1    ; Step: Input second number
CALC_STEP_OPERATION   equ 2    ; Step: Select operation
CALC_STEP_RESULT      equ 3    ; Step: Show result
CALC_STEP_EXIT        equ 4    ; Step: Exit prompt

CALC_OP_ADD           equ 1    ; Operation: Addition
CALC_OP_SUB           equ 2    ; Operation: Subtraction
CALC_OP_MUL           equ 3    ; Operation: Multiplication
CALC_OP_DIV           equ 4    ; Operation: Division

CALC_INPUT_SIZE       equ 6    ; Size of input buffer
CALC_RESULT_SIZE      equ 7    ; Size of result buffer
CALC_MAX_NUMBERS      equ 4    ; Maximum number of input digits

; =============================================
; Clock Constants
; =============================================
CLOCK_ORG            equ 0x700   ; Clock program origin
CLOCK_STACK_SEG      equ 0x8000  ; Clock stack segment
CLOCK_UPDATE_DELAY   equ 0x0007  ; Update delay high word
CLOCK_UPDATE_DELAY_L equ 0xa120  ; Update delay low word

; Clock Display Positions
CLOCK_HOUR_TENS_POS  equ 0       ; Position of hour tens digit
CLOCK_HOUR_ONES_POS  equ 34      ; Position of hour ones digit
CLOCK_MIN_TENS_POS   equ 92      ; Position of minute tens digit
CLOCK_MIN_ONES_POS   equ 126     ; Position of minute ones digit
CLOCK_DOT1_POS       equ 876     ; Position of first dot pair
CLOCK_DOT2_POS       equ 1036    ; Position of second dot pair
CLOCK_DOT3_POS       equ 1996    ; Position of third dot pair
CLOCK_DOT4_POS       equ 2156    ; Position of fourth dot pair
CLOCK_DATE_POS       equ 0x1524  ; Position of date display
CLOCK_CURSOR_HIDE    equ 0x1900  ; Position to hide cursor

; Clock Display Parameters
CLOCK_DOT_WIDTH      equ 3       ; Width of clock dots
CLOCK_DIGIT_WIDTH    equ 16      ; Width of digit segments
CLOCK_DIGIT_HEIGHT   equ 8       ; Height of digit segments
CLOCK_DIGIT_SPACING  equ 24      ; Spacing between digit segments
CLOCK_LINE_SPACING   equ 128     ; Spacing between lines

; Clock Control Keys
CLOCK_KEY_FG         equ 'f'     ; Key to cycle foreground color
CLOCK_KEY_BG         equ 'b'     ; Key to cycle background color
CLOCK_KEY_12H        equ 'h'     ; Key to toggle 12/24 hour format

; Clock Format Constants
CLOCK_12H_THRESHOLD  equ 00010010b  ; BCD 12 for 12-hour format
CLOCK_BCD_MASK       equ 1111b      ; BCD digit mask

; =============================================
; Program Origins
; =============================================
KERNEL_ORG           equ 0x500   ; Kernel origin
APP_ORG             equ 0x800   ; Default application origin
BAR_CHART_ORG       equ 0x800   ; Bar chart program origin
BRAINF_ORG          equ 0x800   ; Brainfuck program origin
WRITE_ORG           equ 0x800   ; Write program origin
SNAKE_ORG           equ 0x800   ; Snake program origin
CALC_ORG            equ 0x800   ; Calculator program origin
WRITER_ORG          equ 0x800   ; Alias for text editor origin

%endif ; CONSTANTS_INCLUDED
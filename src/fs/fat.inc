; FAT Header (src/fs/fat.inc)
; Contains constants, macros, and externs for FAT routines

%ifndef FAT_INC_INCLUDED
%define FAT_INC_INCLUDED

[BITS 16]

; Include error handling and constants
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"

; Sector size configuration
%ifndef SECTOR_SIZE
    %define SECTOR_SIZE 512
%endif

; Validate sector size
%if SECTOR_SIZE < 256 || SECTOR_SIZE > 4096
    %error "Invalid sector size. Must be between 256 and 4096 bytes."
%endif

; FAT Constants
FAT_START_SECTOR equ 2        ; FAT starts at sector 2 (after boot sector)
FAT_SECTORS      equ 4        ; FAT is 4 sectors long
FAT_BUFFER      equ 0x7800    ; FAT buffer in memory (moved to avoid conflicts)
MAX_CLUSTERS    equ (FAT_SECTORS * SECTOR_SIZE * 2 / 3)  ; Maximum clusters based on sector size

; FAT Entry Values
FAT_FREE        equ 0x000     ; Free cluster
FAT_RESERVED    equ 0xFF0     ; Reserved cluster
FAT_BAD         equ 0xFF7     ; Bad cluster
FAT_EOF         equ 0xFF8     ; End of file marker

; Extern declarations for FAT routines
extern fat_init
extern fat_alloc
extern fat_free
extern fat_next
extern fat_mark_bad
extern fat_validate_chain
extern fat_set_next
extern fat_get_next
extern fat_is_valid
extern fat_free_chain

%endif ; FAT_INC_INCLUDED 
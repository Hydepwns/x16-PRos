[BITS 16]

; Directory Entry Field Operations (by filename)
; Each routine finds the entry by filename (DS:SI) and gets/sets the field.
; Uses helpers from helpers.asm

%include "src/fs/dir/helpers.asm"
%include "src/lib/constants.inc"
%include "src/lib/error_codes.inc"

section .text

extern dir_find
extern dir_init
extern dir_create
extern dir_delete

global dir_set_attributes
global dir_get_attributes
global dir_set_size
global dir_get_size
global dir_set_cluster
global dir_get_cluster

; Set file attributes by filename
; Input: DS:SI = filename, AL = new attributes
; Output: CF=0 if success, CF=1 if error
;         AX = entry offset (if found)
dir_set_attributes:
    push bx
    push di
    call dir_find
    jc .fail
    mov bx, ax                ; entry offset
    mov di, DIR_BUFFER
    add di, bx                ; DI = entry pointer
    call set_attributes       ; AL = new attributes
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.fail:
    stc
.done:
    pop di
    pop bx
    ret

; Get file attributes by filename
; Input: DS:SI = filename
; Output: AL = attributes, CF=0 if success, CF=1 if error
;         AX = entry offset (if found)
dir_get_attributes:
    push bx
    push di
    call dir_find
    jc .fail
    mov bx, ax
    mov di, DIR_BUFFER
    add di, bx
    call get_attributes      ; returns AL
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.fail:
    mov al, 0
    stc
.done:
    pop di
    pop bx
    ret

; Set file size by filename
; Input: DS:SI = filename, CX = new size
; Output: CF=0 if success, CF=1 if error
;         AX = entry offset (if found)
dir_set_size:
    push bx
    push di
    call dir_find
    jc .fail
    mov bx, ax
    mov di, DIR_BUFFER
    add di, bx
    mov [di + DIR_SIZE_OFFSET], cx
    mov byte [di + DIR_SIZE_OFFSET + 2], 0 ; clear high byte
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.fail:
    stc
.done:
    pop di
    pop bx
    ret

; Get file size by filename
; Input: DS:SI = filename
; Output: CX = size, CF=0 if success, CF=1 if error
;         AX = entry offset (if found)
dir_get_size:
    push bx
    push di
    call dir_find
    jc .fail
    mov bx, ax
    mov di, DIR_BUFFER
    add di, bx
    mov cx, [di + DIR_SIZE_OFFSET]
    ; ignore high byte for now
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.fail:
    mov cx, 0
    stc
.done:
    pop di
    pop bx
    ret

; Set starting cluster by filename
; Input: DS:SI = filename, BX = new cluster
; Output: CF=0 if success, CF=1 if error
;         AX = entry offset (if found)
dir_set_cluster:
    push dx
    push di
    call dir_find
    jc .fail
    mov dx, ax
    mov di, DIR_BUFFER
    add di, dx
    mov [di + DIR_CLUSTER_OFFSET], bx
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.fail:
    stc
.done:
    pop di
    pop dx
    ret

; Get starting cluster by filename
; Input: DS:SI = filename
; Output: BX = cluster, CF=0 if success, CF=1 if error
;         AX = entry offset (if found)
dir_get_cluster:
    push dx
    push di
    call dir_find
    jc .fail
    mov dx, ax
    mov di, DIR_BUFFER
    add di, dx
    mov bx, [di + DIR_CLUSTER_OFFSET]
    mov al, ERR_NONE
    call set_error
    clc
    jmp .done
.fail:
    mov bx, 0
    stc
.done:
    pop di
    pop dx
    ret 
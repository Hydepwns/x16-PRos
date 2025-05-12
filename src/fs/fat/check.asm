; FAT Chain Validation Routines
; -----------------------------------
; fat_validate_chain: Validates a FAT chain for cycles, premature ends, and invalid clusters.
; Input: SI = starting cluster, DI = pointer to bitmap buffer
; Output: AX = status code (0 = OK, nonzero = error)

%include "src/lib/constants.inc"

section .text
    global fat_validate_chain

; Error codes
FAT_CHAIN_OK      equ 0
FAT_CHAIN_CYCLE   equ 1
FAT_CHAIN_INVALID equ 2
FAT_CHAIN_EOF     equ 0xFF8

; Assumes FAT buffer is at FAT_BUFFER (see constants.inc)
; Assumes cluster numbers start at 2 (FAT12 convention)
; Assumes bitmap buffer is large enough for all clusters (1 bit per cluster)

fat_validate_chain:
    push bx
    push cx
    push dx
    push es
    push di
    push si

    mov ax, FAT_BUFFER
    mov es, ax

    ; Clear bitmap (assume MAX_CLUSTERS <= 4096, so 512 bytes max)
    mov bx, di
    mov cx, (MAX_CLUSTERS + 7) / 8
.clear_bitmap:
    mov byte [bx], 0
    inc bx
    loop .clear_bitmap

    mov bx, si              ; bx = current cluster
    mov cx, 0               ; cx = step counter (optional, for safety)

.next_cluster:
    ; Check cluster bounds
    cmp bx, 2
    jb .invalid             ; cluster < 2 is invalid
    cmp bx, MAX_CLUSTERS
    jae .invalid            ; cluster >= MAX_CLUSTERS is invalid

    ; Check bitmap: is this cluster already visited?
    mov dx, bx
    shr dx, 3               ; byte offset
    mov si, di
    add si, dx
    mov al, [si]            ; al = bitmap byte
    mov dl, bl
    and dl, 7               ; bit within byte
    mov cl, dl
    mov ah, 1
    shl ah, cl
    test al, ah
    jnz .cycle              ; already visited

    ; Mark as visited
    or al, ah
    mov [si], al

    ; Get next cluster from FAT. Original BX = current cluster number (N)
    push bx                 ; Save current cluster N (in bx)
    mov ax, bx              ; ax = N
    mov cx, 3
    mul cx                  ; dx:ax = N * 3
    mov cx, 2
    div cx                  ; ax = (N * 3) / 2 (byte offset), dx = (N*3) % 2
                            ; ax now holds the byte offset into the FAT

    mov si, ax              ; Use SI for addressing [es:si]
    ;mov ax, [es:si]         ; ax = the 16-bit word from FAT table
    nop
    pop bx                  ; Restore original N into BX (current cluster number)

    test bl, 1              ; Test if original N (in bl) is odd or even
    jz .fetch_even_entry    ; If N is even
    ; N is odd: the entry is in the upper 12 bits
    mov cl, 4               ; New diagnostic
    ;shr ax, cl              ; New diagnostic
    nop
    jmp .fetched_fat_entry
.fetch_even_entry:
    ; N is even: the entry is in the lower 12 bits
    and ax, 0x0FFF
.fetched_fat_entry:
    ; AX now holds the next cluster number (0x000-0xFF7 or EOF marker)

    ; Check for end of chain
    cmp ax, FAT_CHAIN_EOF
    jae .ok                 ; >= 0xFF8 is end of chain

    ; Next cluster
    mov bx, ax
    inc cx
    cmp cx, MAX_CLUSTERS    ; safety: prevent infinite loop
    jae .cycle
    jmp .next_cluster

.ok:
    xor ax, ax              ; AX = 0 (OK)
    jmp .done
.cycle:
    mov ax, FAT_CHAIN_CYCLE
    jmp .done
.invalid:
    mov ax, FAT_CHAIN_INVALID
    jmp .done
.done:
    pop si
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    ret 
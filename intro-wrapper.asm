
;-------------------------------------------------
; 
; -- TTE INTRO WRAPPER
;
; FOR 64KB INTROS WHICH NEED THE RAM
;
; FUCK THE SYSTEM!
;
;-------------------------------------------------

Main:
    lea       $dff000,a6
    move.w    #$7fff,$dff096
    move.w    #$7fff,$dff09a

    lea       Chip,a0
    lea       Fast,a1
    move.l    a0,a2
    bsr       Reloc
    move.l    a1,a2
    bsr       Reloc

    move.l    a0,a2
    bsr       ClearBss

    move.l    a1,a2
    bsr       ClearBss

    addq.l    #8,a1

    move.l    #"DEAD",d0
    ; topaz in d1
    jmp       (a1)

;--------------------------------------
;
; Clear BSS
;
; a2 = hunk data
;
;--------------------------------------

ClearBss:
    move.l    4(a2),d7
    beq       .nobss
    add.l     (a2)+,a2          ; reloc datasame time
    addq.l    #4,a2             ; now at reloc table
    lsr.l     #2,d7             ; long words
.clearloop
    clr.l     (a2)+
    subq.l    #1,d7
    bne       .clearloop
.nobss
    rts

;--------------------------------------
;
; Relocate our merged hunks to their ne location
;
; a0 = chip data
; a1 = fast data
; a2 = hunk to process
;
;--------------------------------------

Reloc:
    move.l    a2,a3                    
    addq.l    #8,a3             ; this hunk start address

    add.l     (a2)+,a2          ; reloc data
    addq.l    #4,a2             ; now at reloc table
.next
    move.l    (a2)+,d7          ; reloc count
    beq       .done

    move.l    a0,d1             ; address value to add
    move.l    (a2)+,d0          ; target hunk
    beq       .chip
    move.l    a1,d1     
.chip   
    addq.l    #8,d1             ; skip two values
.loop
    move.l    a3,a4             ; copy base address
    add.l     (a2)+,a4
    add.l     d1,(a4)
    subq.l    #1,d7
    bne       .loop

    bra       .next
.done
    rts


Chip:
    incbin    "uae/dh0/chip"
    dcb.b     $70000
Fast:
    incbin    "uae/dh0/fast"
    dcb.b     $70000


;----------------------------------------------------------------------------
;
; map the sample bank
;
;----------------------------------------------------------------------------

LSPBankMapper:
    PUSHALL
    lea        Variables,a5
    lea        LSPIndex,a2
.sampleloop 
    move.w     (a2)+,d1                         ; sample id
    bmi        .done                            ; negative end of list

    move.w     d1,d2
    lsl.w      #2,d2                            ; sample bank id
    lea        sample_pointers,a6
    move.l     (a6,d2.w),a6

    move.l     LSP_State+m_lspInstruments,a3
    lea        12(a3),a3
    lea        LSPInstruments,a0                ; songs instrument list
.insloadloop
    move.w     LSPIns_Type(a0),d2               ; type
    bmi        .loaddone
    cmp.w      #0,d2                            ; loop type?
    bne        .next                            ; not loop sample

    cmp.w      LSPIns_BankId(a0),d1
    bne        .next                            ; not this sample

    move.l     LSPIns_Offset(a0),d5
    add.l      a6,d5                            ; new pointer
    move.l     d5,(a3)                          ; sample start
    
    cmp.w      #2,d1
    beq        .hack
    cmp.w      #4,d1
    bne        .nohack
.hack
    addq.l     #1,(a3)
.nohack
    move.l     LSPIns_LoopOffset(a0),d5                          
    add.l      a6,d5                            ; new pointer
    move.l     d5,6(a3)                         ; loop start

.next
    lea        LSPIns_Sizeof(a0),a0             ; next our list
    lea        12(a3),a3                        ; next lsp list
    bra        .insloadloop
.loaddone

    bra        .sampleloop 
.done
    POPALL
    rts

.fuck
    rts

; in d3 = sample id
;    d6 = sample pointer
LSPDrumMapper:
    PUSHALL
    addq.l     #1,d6
    move.l     LSP_State+m_lspInstruments,a3
    lea        12(a3),a3
    lea        LSPInstruments,a0                ; songs instrument list
.insloadloop
    move.w     LSPIns_Type(a0),d2               ; type
    bmi        .loaddone
    cmp.w      #0,d2                            ; loop type?
    beq        .next                            ; not loop sample

    cmp.w      LSPIns_BankId(a0),d3
    bne        .next                            ; not this sample

    move.l     LSPIns_Offset(a0),d0
    add.l      d6,d0                            ; new pointer
    move.l     d0,(a3)                          ; sample start
    
    move.l     LSPIns_LoopOffset(a0),d0                          
    add.l      d6,d0                            ; new pointer
    move.l     d0,6(a3)                         ; loop start

.next
    lea        LSPIns_Sizeof(a0),a0             ; next our list
    lea        12(a3),a3                        ; next lsp list
    bra        .insloadloop
.loaddone
    POPALL
    rts

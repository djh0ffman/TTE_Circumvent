    section    main,code

    INCDIR     "include"
    INCLUDE    "hw.i"
    INCLUDE    "funcdef.i"
    INCLUDE    "exec/exec_lib.i"
    INCLUDE    "graphics/graphics_lib.i"
    INCLUDE    "hardware/cia.i"
    include    "graphics/text.i"


DMA             = %1000001110100000

    include    "macros.asm"

Main:
    lea        CUSTOM,a6
    move.w     #$7fff,DMACON(a6)
    move.w     #$7fff,INTENA(a6)

    jsr        NurdleFont
    lea        Variables,a5
    lea        CUSTOM,a6
    jsr        ActionReplayInit

    move.l     #InterruptTick,$6c
    move.w     #$c030,INTENA(a6)
.forever
    bra        .forever



; ------------------------------------------
;
; font nurdler
;
; ------------------------------------------


FONT_CHAR_COUNT = 224

NurdleFont:
    move.l     $4,a6
    lea        Variables,a5
    lea        graphics_name(pc),a1
    moveq      #0,d0
    jsr        -552(a6)                        ; OpenLibrary()
    move.l     d0,sys_gfxbase(a5)
    bne.b      .gfxok
    moveq      #-1,d0                          ; return failure
    rts

.gfxok    
    move.l     d0,a6
                   
    lea        FontDef(PC),a0
    lea        FontName(PC),a1
    move.l     a1,(a0)                         ;PC-relative, ya know!
    jsr        -72(a6)                         ;openFont(topaz.font)
    move.l     d0,a1
    move.l     tf_CharData(a1),TopazPtr(a5)    ;fontaddr
    move.w     tf_Modulo(a1),TopazMod(a5)      ; font mod


    move.l     TopazPtr(a5),a0
    lea        FontTopaz,a1
    moveq      #0,d0
    move.w     TopazMod(a5),d0

    move.w     #FONT_CHAR_COUNT-1,d7
.charloop
    move.l     a0,a2
    moveq      #8-1,d6
.pixloop
    move.b     (a2),(a1)+
    add.l      d0,a2
    dbra       d6,.pixloop

    addq.l     #1,a0
    dbra       d7,.charloop
    rts



FontDef:
    dc.l       0
    dc.w       8,0

FontName:
    dc.b       "topaz.font",0
    even
GfxLib:	
    dc.b       "graphics.library",0            ;MUST BE ODD!
    even

graphics_name:  
    dc.b       'graphics.library',0
    even


InterruptTick:
    PUSHALL
    lea        CUSTOM,a6
    move.w     INTREQR(a6),d0
    move.w     d0,d1
    and.w      #$3fff,d1
    move.w     d1,INTREQ(a6)
    move.w     d1,INTREQ(a6)

    and.w      #$0010,d0
    beq        .vblank

    ; copper interrupt
    bra        .exit

.vblank
    ; vblank
    addq.w     #1,TickCounter(a5)
    jsr        ActionReplayTick

.exit
    POPALL
    rte

Variables:
    dcb.b      Variables_Sizeof

    include    "const.asm"

    include    "actionreplay.asm"
    
    section    main_bss_fast,bss
FontTopaz:
    ds.b       FONT_CHAR_COUNT*8

    section    main_bss_chip,bss_c
ScreenMem:
    ds.b       AR_Sizeof
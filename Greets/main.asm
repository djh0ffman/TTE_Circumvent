    section    main,code

    INCDIR     "include"
    INCLUDE    "hw.i"
    INCLUDE    "funcdef.i"
    INCLUDE    "exec/exec_lib.i"
    INCLUDE    "graphics/graphics_lib.i"
    INCLUDE    "hardware/cia.i"
    


DMA          = %1000001110100000

    include    "macros.asm"

Main:
    bsr        make_sine

    lea        CUSTOM,a6
    move.w     #$7fff,DMACON(a6)
    move.w     #$7fff,INTENA(a6)

    lea        Variables,a5
    jsr        GreetsDiscreteInit

    jsr        GreetsInit

    move.l     #VBlankTick,$6c
    move.w     #$c030,INTENA(a6)
    move.w     #1,DemoEnabled(a5)

    move.l     #GreetsTick,VBlankPtr(a5)

    jsr        GreetsBackgroundThread
.forever

    bra        .forever

; ------------------------------------------
;
; vblank / copper intterupt handler
;
; ------------------------------------------

VBlankTick:
    PUSHALL
    lea        CUSTOM,a6                   
    lea        Variables,a5

    move.w     INTREQR(a6),d0
    move.w     d0,d1
    and.w      #$3fff,d1
    move.w     d1,INTREQ(a6)
    move.w     d1,INTREQ(a6)

    and.w      #$0010,d0
    beq        .vblank

    ; copper interrupt
    move.l     CopperIntPtr(a5),d0
    beq        .exit
    move.l     d0,a0
    jsr        (a0)
    bra        .exit

.vblank    
    tst.w      DemoEnabled(a5)
    beq        .nodemo

    ;bsr        MusicPlay
    ;bsr        Scripting
    addq.w     #1,TickCounter(a5)
.nodemo
    move.l     VBlankPtr(a5),d0
    beq        .exit
    move.l     d0,a0
    jsr        (a0)
.exit

    ;move.w        #$000,$dff180
    POPALL
    rte



make_sine:
    lea        sinus,a0
    addq.l     #2,a0
    lea.l      sine_degrees/2*2-2(a0),a1

    moveq.l    #1,d7
.loop:
    move.w     d7,d1
    mulu.w     d7,d1
    lsr.l      #8,d1

    move.w     #2373,d0
    mulu.w     d1,d0
    swap.w     d0
    neg.w      d0
    add.w      #21073,d0
    mulu.w     d1,d0
    swap.w     d0
    neg.w      d0
    add.w      #51469,d0
    mulu.w     d7,d0
    lsr.l      #8,d0
    lsr.l      #5,d0

    move.w     d0,(a0)+
    move.w     d0,-(a1)
    neg.w      d0
    move.w     d0,sine_degrees/2*2(a1)
    move.w     d0,sine_degrees/2*2-2(a0)

    addq.w     #1,d7
    cmp.w      #sine_degrees/4,d7
    blt.b      .loop

    neg.w      d0
    move.w     d0,-(a1)
    neg.w      d0
    move.w     d0,sine_degrees/2*2(a1)
    rts

sine_degrees = 16384
sinus:
    dcb.w      sine_degrees

Variables:
    dcb.b      Variables_Sizeof

    include    "const.asm"

    include    "greets.asm"
    



    section    main_bss_chip,bss_c
ScreenMem:
    ds.b       Greets_ChipSize
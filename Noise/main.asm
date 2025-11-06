    section    main,code

    INCDIR     "include"
    INCLUDE    "hw.i"
    INCLUDE    "funcdef.i"
    INCLUDE    "exec/exec_lib.i"
    INCLUDE    "graphics/graphics_lib.i"
    INCLUDE    "hardware/cia.i"
    


DMA = %1000001110100000

    include    "macros.asm"

Main:
    lea        CUSTOM,a6
    move.w     #$7fff,DMACON(a6)
    move.w     #$7fff,INTENA(a6)

    jsr        NoiseInit

    move.l     #InterruptTick,$6c
    move.w     #$c030,INTENA(a6)
.forever
    bra        .forever


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
    jsr        NoiseTick

.exit
    POPALL
    rte

Variables:
    dcb.b      Variables_Sizeof

    include    "const.asm"

    include    "noise.asm"
    



    section    main_bss_chip,bss_c
ScreenMem:
    ds.b       NoiseChip_Sizeof
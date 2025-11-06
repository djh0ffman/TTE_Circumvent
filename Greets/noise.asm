; noise

    section       noise_code,code


NOISE_SCREEN_WIDTH          = 320
NOISE_SCREEN_WIDTH_BYTE     = NOISE_SCREEN_WIDTH/8
NOISE_SCREEN_HEIGHT         = 256
NOISE_SCREEN_DEPTH          = 2

NOISE_SIZE_BYTES            = 1024

NOISE_EDGE                  = 512
NOISE_RAND_PLANE_WIDTH      = NOISE_SCREEN_WIDTH+NOISE_EDGE
NOISE_RAND_PLANE_WIDTH_BYTE = NOISE_RAND_PLANE_WIDTH/8
NOISE_RAND_PLANE_WIDTH_WORD = NOISE_RAND_PLANE_WIDTH/16

NOISE_DMA                   = %1000001110100000


    include       "noise_struct.asm"


NoiseInit:
    lea           Variables,a5
    move.l        #$BABEFEED,RandomSeed(a5)

    lea           ScreenMem,a4
    lea           NoiseChip_RandPlane(a4),a0
    move.w        #(NOISE_SIZE_BYTES/2)-1,d7
.gennoise
    RANDOMWORD
    move.w        d0,(a0)+
    dbra          d7,.gennoise

    bsr           NoiseCopperPopulate
    bsr           NoiseTick

    lea           ScreenMem,a4
    lea           NoiseChip_Copper(a4),a0
    move.l        a0,d0
    lea           NoiseCopJump,a0                           ; fill copper jump
    move.w        d0,6(a0)
    swap          d0
    move.w        d0,2(a0)

    move.l        #NoiseCopper,COP1LC(a6)
    move.w        #0,COPJMP1(a6)
    move.w        #NOISE_DMA,DMACON(a6)


    rts


NoiseCopperPopulate:
    lea           ScreenMem,a4
    lea           NoiseChip_Copper(a4),a4   
    move.w        #NOISE_SCREEN_HEIGHT-1,d7
    move.w        #$2c,d4                                   ; line number
.loop
    move.l        #$2c01ff00,NoiseCopper_Wait(a4)           ; wait line
    move.l        #$1fc0000,NoiseCopper_WaitEnd(a4)         ; NOP IT!

    lea           NoiseCopper_Planes(a4),a1
    move.w        #BPL1PTH,d1
    move.w        #(NOISE_SCREEN_DEPTH*2)-1,d6
.planeloop
    move.w        d1,(a1)+
    clr.w         (a1)+
    addq.w        #2,d1
    dbra          d6,.planeloop


    move.b        d4,NoiseCopper_Wait(a4) 

    addq.b        #$1,d4
    bne           .skipntsc
    move.l        #$80df80fe,NoiseCopper_WaitEnd(a4)        ; wait for end of line
.skipntsc

    lea           NoiseCopper_Sizeof(a4),a4
    dbra          d7,.loop

    move.l        #-2,(a4)+
    move.l        #-2,(a4)+

    rts


NoiseTick:
    ;move.w        #$0c0,$dff180
    lea           Variables,a5
    lea           ScreenMem,a4
    lea           NoiseChip_Copper(a4),a4
    move.w        #NOISE_SCREEN_HEIGHT-1,d7

    lea           ScreenMem,a0
    lea           NoiseChip_RandPlane(a0),a0
    move.l        a0,d2
.loop
    RANDOMWORD
    move.l        d0,d1
    and.w         #(NOISE_SIZE_BYTES/2)-1,d0
    lsr.w         #8,d1
    and.w         #(NOISE_SIZE_BYTES/2)-1,d1
    add.l         d2,d0
    add.l         d2,d1

    lea           NoiseCopper_Planes(a4),a1
    move.w        d0,6(a1)
    swap          d0
    move.w        d0,2(a1)
    move.w        d1,8+6(a1)
    swap          d1
    move.w        d1,8+2(a1)

    lea           NoiseCopper_Sizeof(a4),a4
    dbra          d7,.loop
    ;move.w        #$000,$dff180

    rts



    section       noise_data_chip,data_c

NoiseCopper:
    dc.w          DIWSTRT,$2c81                             ; window start stop
    dc.w          DIWSTOP,$2cc1                             ; 192 + 8

    dc.w          DDFSTRT,$38                               ; datafetch start stop 
    dc.w          DDFSTOP,$d0

    dc.w          BPLCON0,$0200+(NOISE_SCREEN_DEPTH<<12)    ; set as 1 bp display
    dc.w          BPLCON1,$0000                             ; set scroll 0
    dc.w          BPLCON2,$0000    
    dc.w          BPL1MOD,0
    dc.w          BPL2MOD,0


    dc.w          SPR0PTH,0
    dc.w          SPR0PTL,0
    dc.w          SPR1PTH,0
    dc.w          SPR1PTL,0
    dc.w          SPR2PTH,0
    dc.w          SPR2PTL,0
    dc.w          SPR3PTH,0
    dc.w          SPR3PTL,0
    dc.w          SPR4PTH,0
    dc.w          SPR4PTL,0
    dc.w          SPR5PTH,0
    dc.w          SPR5PTL,0
    dc.w          SPR6PTH,0
    dc.w          SPR6PTL,0
    dc.w          SPR7PTH,0
    dc.w          SPR7PTL,0

    dc.w          COLOR00,$000
    dc.w          COLOR01,$444
    dc.w          COLOR02,$888
    dc.w          COLOR03,$aaa

NoiseCopJump:
    dc.w          COP2LCH,0
    dc.w          COP2LCL,0
    dc.w          COPJMP2,0




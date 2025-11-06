    section   Disks_code,code


DISK_SCREEN_WIDTH      = 320
DISK_SCREEN_WIDTH_BYTE = DISK_SCREEN_WIDTH/8
DISK_SCREEN_WIDTH_WORD = DISK_SCREEN_WIDTH_BYTE/2
DISK_SCREEN_HEIGHT     = 256
DISK_SCREEN_DEPTH      = 1
DISK_SCREEN_VIEW_DEPTH = 2
DISK_SCREEN_SIZE       = DISK_SCREEN_WIDTH_BYTE*DISK_SCREEN_HEIGHT*DISK_SCREEN_DEPTH
DISK_SCREEN_MOD        = DISK_SCREEN_WIDTH_BYTE*(DISK_SCREEN_DEPTH-1)


DISK_WAVE_SIZE         = 128
DISK_WAVE_PLANE_SIZE   = DISK_SCREEN_WIDTH_BYTE*DISK_WAVE_SIZE
DISK_WAVE_PLANE_LOC    = ScreenMem+DisksChip_WavePlane
DISK_WAVE_VOLSCALES    = 8


DISK_SPRITE_HEIGHT     = 32
DISK_SPRITE_LENGTH     = 256+32
DISK_SPRITE_SIZE       = (DISK_SPRITE_LENGTH*4)+4+4

DISK_COPPER_TOTAL      = DISK_COPPER_SIZE+(4*4)
DISK_COPPER_SIZE       = DiskCopper_Sizeof*DISK_SCREEN_HEIGHT
DISK_COPPER_MID        = DISK_COPPER_SIZE/2

DISKS_DMA              = %1000001111100000
DISKS_ENABLE_BLITTER   = %1000001001000000

SPRITE_START_V         = $2c
;SPRITE_STOP_V          = SPRITE_START_V+SCREEN_HEIGHT

SPRITE_MAX_LINES       = 256+48
SPRITE_MAX_SIZE        = (SPRITE_MAX_LINES*4)+8
SPRITE_COUNT           = 6

SPRITE_CTRL            = ($2c<<8)+(1<<1)

    include   "disksstruct.asm"


DisksDiscreteInit:
    bsr       DisksGenerateLookups
    bsr       PopulateLogoLUT
    rts

DisksInit:
    PUSHALL
    lea       ScreenMem+DisksChip_WavePlane,a0
    move.l    a0,d1

    ; do this with the blitter?    
    move.w    #(DISK_WAVE_PLANE_SIZE/2)-1,d7
.clearplane
    clr.w     (a0)+
    dbra      d7,.clearplane

    move.w    #DISKS_DMA,DMACON(a6)

    bsr       DisksGenerateWave
    bsr       DisksPrepSpriteBanks
    bsr       DisksLoadSpriteCopper
    bsr       DisksPopulateCopper
 
    ;bsr        FillTestPlanes
    move.l    #cpDisksCopper,COP1LC(a6)

    POPALL

    rts






DisksGenerateLookups:
    ; plane lookup
    move.w    #DISK_WAVE_SIZE-1,d7
    lea       DisksWaveLookUp,a0

    move.l    #ScreenMem+DisksChip_WavePlane,d0
    move.l    #DISK_SCREEN_WIDTH_BYTE,d1
.planes
    move.l    d0,(a0)+
    add.l     d1,d0
    dbra      d7,.planes

    ; volume lookup
    lea       DisksVolLookup,a0
    moveq     #DISK_WAVE_VOLSCALES-1,d7
    moveq     #0,d5                                                  ; volume
.vtable
    moveq     #0,d0
    move.w    #256-1,d6
.byte
    move.b    d0,d1
    bpl       .pos
    neg.b     d1
.pos
    lsr.w     #1,d1
    mulu      d5,d1
    divu      #DISK_WAVE_VOLSCALES,d1
    move.b    d1,(a0)+
    addq.w    #1,d0
    dbra      d6,.byte

    ; add volume
    addq.w    #1,d5
    dbra      d7,.vtable
    rts




;----------------------------------------------------------------------------------
;
; DisksGenerateWave
;
;----------------------------------------------------------------------------------
DISK_WAVE_BLTCON1      = %0000000000010010
DISK_WAVE_BLIT_SIZE    = (DISK_WAVE_SIZE<<6)+DISK_SCREEN_WIDTH_WORD

DisksGenerateWave:
    lea       DISK_WAVE_PLANE_LOC,a0
    move.w    #DISK_WAVE_SIZE-1,d7
    move.w    #DISK_SCREEN_WIDTH/2,d0                                ; right pixel
    move.w    d0,d1                                                  ; left pixel
    subq.w    #1,d1
.plotloop
    move.w    d0,d2
    move.w    d2,d3
    not.b     d3
    lsr.w     #3,d2
    bset      d3,(a0,d2)

    move.w    d1,d2
    move.w    d2,d3
    not.w     d3
    lsr.w     #3,d2
    bset      d3,(a0,d2)

    subq.w    #1,d1
    addq.w    #1,d0

    lea       DISK_SCREEN_WIDTH_BYTE(a0),a0
    dbra      d7,.plotloop

    subq.l    #2,a0

    WAITBLIT
    move.w    #$09f0,BLTCON0(a6)
    move.w    #DISK_WAVE_BLTCON1,BLTCON1(a6)
    ;move.w       #0,BLTCON1(a6)
    ;move.w       #-1,BLTADAT(a6)
    move.l    a0,BLTAPT(a6)
    move.l    a0,BLTDPT(a6)
    move.w    #0,BLTAMOD(a6)
    move.w    #0,BLTDMOD(a6)
    move.w    #DISK_WAVE_BLIT_SIZE,BLTSIZE(a6)

    rts

.plot
    rts


DISK_WAVE_PERIOD       = 35469/(180/2)
DISK_WAVE_DELTA        = (DISK_WAVE_PERIOD<<16)/128
DISK_COPY_SIZE_BYTES   = DiskCopper_CopyEnd-DiskCopper_CopyStart
DISK_COPY_BLITSIZE     = (128<<6)+(DISK_COPY_SIZE_BYTES/2)
DISK_COPY_MOD_DEST     = -(DiskCopper_Sizeof+DISK_COPY_SIZE_BYTES)
DISK_COPY_MOD_SOURCE   = DiskCopper_Sizeof-DISK_COPY_SIZE_BYTES


DisksWaveSet:
    lea       DisksVolLookup,a1
    moveq     #0,d0
    move.w    SampleVolume(a5),d0
    beq       .zerovol
    subq.w    #1,d0
    lsr.w     #3,d0
    lsl.w     #8,d0
.zerovol
    add.l     d0,a1                                                  ; volume lookup

    lea       DisksWaveLookUp,a2
    lea       DisksWaveColors,a6
    moveq     #0,d4
    move.l    SamplePointer(a5),a0
    add.l     #DISK_WAVE_PERIOD,SamplePointer(a5)
    move.w    #(DISK_SCREEN_HEIGHT/2)-1,d7
    move.l    #DISK_WAVE_PLANE_LOC,d5
    move.l    DiskCopperPtrs(pc),a4
    lea       DISK_COPPER_MID(a4),a4
    move.l    #DiskCopper_Sizeof,d2

.loop
    moveq     #0,d0
    move.b    (a0)+,d0
    move.b    (a1,d0.w),d0

    move.w    d0,d1

    move.w    d0,d1
    lsr.w     #1,d1

    move.w    d1,d3
    lsr.w     #2,d3
    add.w     d3,d3
    add.w     d3,d3
    move.w    (a6,d3.w),DiskCopper_WaveColor+2(a4)
    move.w    2(a6,d3.w),DiskCopper_WaveColor+6(a4)

    add.w     d0,d0
    add.w     d0,d0
    move.w    (a2,d0.w),DiskCopper_Planes+2(a4)
    move.w    2(a2,d0.w),DiskCopper_Planes+6(a4)

    add.w     d1,d1
    add.w     d1,d1
    move.w    (a2,d1.w),DiskCopper_Planes+8+2(a4)
    move.w    2(a2,d1.w),DiskCopper_Planes+8+6(a4)

    add.l     d2,a4
    dbra      d7,.loop

    lea       CUSTOM,a6
    
    move.l    DiskCopperPtrs(pc),a4
    lea       DISK_COPPER_MID+DiskCopper_CopyStart(a4),a4
    lea       -DiskCopper_Sizeof(a4),a3

    WAITBLIT
    move.w    #$09f0,BLTCON0(a6)    
    move.w    #0,BLTCON1(a6)
    move.l    #-1,BLTAFWM(a6)
    move.w    #DISK_COPY_MOD_SOURCE,BLTAMOD(a6)
    move.w    #DISK_COPY_MOD_DEST,BLTDMOD(a6)
    move.l    a4,BLTAPT(a6)
    move.l    a3,BLTDPT(a6)
    move.w    #DISK_COPY_BLITSIZE,BLTSIZE(a6)
    
    ; now mirror copy the copper list with the blitter

    rts

DiskLoadLogoRun:
    move.w    DiskParamStatus,d0
    JMPINDEX  d0
.i
    dc.w      DisksLoadLogo-.i
    dc.w      DisksLoadLogo-.i
    dc.w      DiskLogoOppo-.i
    dc.w      DisksLoadLogo2-.i
    dc.w      DiskLogoOppo-.i
    dc.w      DisksLoadLogo2-.i
    dc.w      DiskLogoOppo-.i
    dc.w      DisksLoadLogo2-.i
    dc.w      DiskLogoOppo-.i
    dc.w      DisksLoadLogo2-.i



DiskLogoOppo:
    bsr       DisksLoadLogoHalf
    neg.w     DiskLogoY
    addq.w    #1,DiskLogoY
    bsr       DisksLoadLogoHalf
    rts

DiskLogoOppoSinePos:
    dc.w      0

; --------------------- logo high

DisksLoadLogoHalf:
    moveq     #0,d2                                                  ; clear top crop
    move.w    #LOGO_HEIGHT,d3

    move.w    DiskLogoY,d0
    add.w     #DISK_SCREEN_HEIGHT/2,d0  
    sub.w     #LOGO_HEIGHT/2,d0
    bpl       .nocrop1

    neg       d0
    cmp.w     d3,d0
    bcc       .nologo

    move.w    d0,d2
    moveq     #0,d0
    sub.w     d2,d3                                                  ; reduce height

.nocrop1
    move.w    d0,d4                                                  ; check bottom grop
    add.w     d3,d4
    sub.w     #DISK_SCREEN_HEIGHT,d4
    bmi       .nocrop2
    sub.w     d4,d3                                                  ; reduce height
    bmi       .nologo
    beq       .nologo
.nocrop2


    move.w    d3,d7
    subq.w    #1,d7
    bmi       .nologo

    move.l    DiskCopperPtrs(pc),a4
    mulu      #DiskCopper_Sizeof,d0
    add.l     d0,a4

    lea       DiskLogoLookUp,a0
    lea       DiskLogoOffset,a1


    ;move.w      #LOGO_HEIGHT-1,d7
    move.w    d2,d0
    lsr.w     #1,d7
.loop    
;    and.w       #127,d0
    move.w    d0,d1
    add.w     d1,d1
    move.l    a0,a2
    add.w     (a1,d1.w),a2
    move.w    (a2)+,DiskCopper_LogoPlanes+2(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+6(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+8+2(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+8+6(a4)

    movem.w   (a2)+,d3/d4/d5

    move.w    d3,DiskCopper_LogoColors+2+(4*0)(a4)
    move.w    d4,DiskCopper_LogoColors+2+(4*1)(a4)
    move.w    d5,DiskCopper_LogoColors+2+(4*2)(a4)

    move.w    d3,DiskCopper_LogoColors+2+(4*3)(a4)
    move.w    d4,DiskCopper_LogoColors+2+(4*4)(a4)
    move.w    #$d49,DiskCopper_LogoColors+2+(4*5)(a4)                ; outer
    ;$d49

    move.w    d3,DiskCopper_LogoColors+2+(4*6)(a4)                  
    move.w    d4,DiskCopper_LogoColors+2+(4*7)(a4)
    move.w    #$fa6,DiskCopper_LogoColors+2+(4*8)(a4)                ; inner
    ;$ffaa66

    lea       DiskCopper_Sizeof*2(a4),a4

    addq.w    #2,d0
    dbra      d7,.loop
.nologo
    rts




; --------------------- logo high

DisksLoadLogo2:
    moveq     #0,d2                                                  ; clear top crop
    move.w    #LOGO_HEIGHT,d3

    move.w    DiskLogoY,d0
    add.w     #DISK_SCREEN_HEIGHT/2,d0  
    sub.w     #LOGO_HEIGHT/2,d0
    bpl       .nocrop1

    neg       d0
    cmp.w     d3,d0
    bcc       .nologo

    move.w    d0,d2
    moveq     #0,d0
    sub.w     d2,d3                                                  ; reduce height

.nocrop1
    move.w    d0,d4                                                  ; check bottom grop
    add.w     d3,d4
    sub.w     #DISK_SCREEN_HEIGHT,d4
    bmi       .nocrop2
    sub.w     d4,d3                                                  ; reduce height
    bmi       .nologo
    beq       .nologo
.nocrop2


    move.w    d3,d7
    subq.w    #1,d7
    bmi       .nologo

    move.l    DiskCopperPtrs(pc),a4
    mulu      #DiskCopper_Sizeof,d0
    add.l     d0,a4

    lea       DiskLogoLookUp,a0
    lea       DiskLogoOffset,a1


    ;move.w      #LOGO_HEIGHT-1,d7
    move.w    d2,d0
.loop    
;    and.w       #127,d0
    move.w    d0,d1
    add.w     d1,d1
    move.l    a0,a2
    add.w     (a1,d1.w),a2
    move.w    (a2)+,DiskCopper_LogoPlanes+2(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+6(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+8+2(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+8+6(a4)

    movem.w   (a2)+,d3/d4/d5

    move.w    d3,DiskCopper_LogoColors+2+(4*0)(a4)
    move.w    d4,DiskCopper_LogoColors+2+(4*1)(a4)
    move.w    d5,DiskCopper_LogoColors+2+(4*2)(a4)

    move.w    d3,DiskCopper_LogoColors+2+(4*3)(a4)
    move.w    d4,DiskCopper_LogoColors+2+(4*4)(a4)
    move.w    #$d49,DiskCopper_LogoColors+2+(4*5)(a4)                ; outer
    ;$d49

    move.w    d3,DiskCopper_LogoColors+2+(4*6)(a4)                  
    move.w    d4,DiskCopper_LogoColors+2+(4*7)(a4)
    move.w    #$fa6,DiskCopper_LogoColors+2+(4*8)(a4)                ; inner
    ;$ffaa66

    lea       DiskCopper_Sizeof(a4),a4

    addq.w    #1,d0
    dbra      d7,.loop
.nologo
    rts




; ----- logo solid

DisksLoadLogo:
    moveq     #0,d2                                                  ; clear top crop
    move.w    #LOGO_HEIGHT,d3

    move.w    DiskLogoY,d0
    add.w     #DISK_SCREEN_HEIGHT/2,d0  
    sub.w     #LOGO_HEIGHT/2,d0
    bpl       .nocrop1

    neg       d0
    cmp.w     d3,d0
    bcc       .nologo

    move.w    d0,d2
    moveq     #0,d0
    sub.w     d2,d3                                                  ; reduce height

.nocrop1
    move.w    d0,d4                                                  ; check bottom grop
    add.w     d3,d4
    sub.w     #DISK_SCREEN_HEIGHT,d4
    bmi       .nocrop2
    sub.w     d4,d3                                                  ; reduce height
    bmi       .nologo
    beq       .nologo
.nocrop2


    move.w    d3,d7
    subq.w    #1,d7
    bmi       .nologo

    move.l    DiskCopperPtrs(pc),a4
    mulu      #DiskCopper_Sizeof,d0
    add.l     d0,a4

    lea       DiskLogoLookUp,a0
    lea       DiskLogoOffset,a1


    ;move.w      #LOGO_HEIGHT-1,d7
    move.w    d2,d0
.loop    
;    and.w       #127,d0
    move.w    d0,d1
    add.w     d1,d1
    move.l    a0,a2
    add.w     (a1,d1.w),a2
    move.w    (a2)+,DiskCopper_LogoPlanes+2(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+6(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+8+2(a4)
    move.w    (a2)+,DiskCopper_LogoPlanes+8+6(a4)

    movem.w   (a2)+,d3/d4/d5

    move.w    d3,DiskCopper_LogoColors+2+(4*0)(a4)
    move.w    d4,DiskCopper_LogoColors+2+(4*1)(a4)
    move.w    d5,DiskCopper_LogoColors+2+(4*2)(a4)

    move.w    d3,DiskCopper_LogoColors+2+(4*3)(a4)
    move.w    d4,DiskCopper_LogoColors+2+(4*4)(a4)
    move.w    d5,DiskCopper_LogoColors+2+(4*5)(a4)                   ; outer

    move.w    d3,DiskCopper_LogoColors+2+(4*6)(a4)                  
    move.w    d4,DiskCopper_LogoColors+2+(4*7)(a4)
    move.w    d5,DiskCopper_LogoColors+2+(4*8)(a4)                   ; inner

    lea       DiskCopper_Sizeof(a4),a4

    addq.w    #1,d0
    dbra      d7,.loop
.nologo
    rts


DiskLogoY:
    dc.w      0                                                      ;-400


DisksVBlankTick:
    bsr       DisksLoadCopper
    bsr       DisksSwitchCopper

    bsr       DisksRestoreCopper
    ;move.w      #$f00,$dff180
    bsr       DisksWaveSet
    bsr       DiskLogoParamRun
    bsr       DiskLoadLogoRun
    rts


DISKLOGO_WAVE_DELTA    = sine_degrees/4/(7*4)                        ;130

DiskParamStatus:
    dc.w      0

DiskLogoParamRun:
    move.w    DiskParamStatus,d0
    JMPINDEX  d0
.i 
    dc.w      DiskLogoBounceIn-.i
    dc.w      DiskLogoWobble-.i
    dc.w      DiskLogoOppoParamWob-.i
    dc.w      DiskLogoSomething-.i
    dc.w      DiskLogoOppoParamWobSlow-.i
    dc.w      DiskLogoSomething-.i
    dc.w      DiskLogoOppoParamDrop-.i
    dc.w      DiskLogoSomething-.i
    dc.w      DiskLogoOppoParamExit-.i
    dc.w      DiskLogoNull-.i
    dc.w      DiskLogoSomething-.i

DiskLogoNull:
    rts

DiskLogoOppoParamExit:
    lea       sinus,a0
    moveq     #0,d0
    move.w    DiskLogoSinPosExit,d0
    move.w    d0,d1
.noloop
    and.w     #(sine_degrees/2)-1,d0
    add.w     d0,d0
    move.w    (a0,d0.w),d0
    ext.l     d0
    divs      #80,d0
    move.w    d0,DiskLogoY
    add.w     #DISKLOGO_WAVE_DELTA,DiskLogoSinPosExit
.noreset
    rts

DiskLogoSinPosExit:
    dc.w      0

DiskLogoSomething:
    clr.w     DiskLogoY
    rts

DISK_WOBBLE_DELTA      = sine_degrees/(7*2)

DiskLogoWobble:
    lea       sinus,a0
    moveq     #0,d0
    move.w    DiskLogoSinPos,d0
    and.w     #sine_degrees-1,d0
    add.w     d0,d0
    move.w    (a0,d0.w),d0
    ext.l     d0
    divs      #800,d0
    move.w    d0,DiskLogoY
    add.w     #DISK_WOBBLE_DELTA,DiskLogoSinPos
    rts

DISK_SWITCH            = (16+8)*7
DISK_WOBOFF            = (16+12)*7

DiskLogoOppoParamDrop:
    lea       sinus+(sine_degrees/2),a0
    moveq     #0,d0
    move.w    DiskLogoSinPos,d0
    move.w    d0,d1
.noloop
    and.w     #(sine_degrees/4)-1,d0
    add.w     d0,d0
    move.w    (a0,d0.w),d0
    ext.l     d0
    divs      #200,d0
    move.w    d0,DiskLogoY
    add.w     #DISKLOGO_WAVE_DELTA,DiskLogoSinPos
.noreset
    rts


DiskLogoOppoParamWob:
    lea       sinus,a0
    moveq     #0,d0
    move.w    DiskLogoSinPos,d0
    move.w    d0,d1
.noloop
    and.w     #(sine_degrees/2)-1,d0
    add.w     d0,d0
    move.w    (a0,d0.w),d0
    ext.l     d0
    divs      #400,d0
    move.w    d0,DiskLogoY
    add.w     #DISKLOGO_WAVE_DELTA*2,DiskLogoSinPos
.noreset
    rts

DiskLogoOppoParamWobSlow:
    lea       sinus,a0
    moveq     #0,d0
    move.w    DiskLogoSinPos,d0
    move.w    d0,d1
.noloop
    and.w     #(sine_degrees/2)-1,d0
    add.w     d0,d0
    move.w    (a0,d0.w),d0
    ext.l     d0
    divs      #200,d0
    move.w    d0,DiskLogoY
    add.w     #DISKLOGO_WAVE_DELTA,DiskLogoSinPos
.noreset
    rts

DiskLogoOppoPos:
    dc.w      sine_degrees/4

DiskLogoBounceIn:
    tst.w     DiskLogoBounceCount
    beq       .noreset

    lea       sinus+(sine_degrees),a0
    moveq     #0,d0
    move.w    DiskLogoSinPos,d0
    move.w    d0,d1
.noloop
    and.w     #(sine_degrees/2)-1,d0
    add.w     d0,d0
    move.w    (a0,d0.w),d0
    ext.l     d0
    divs      DiskLogoBounceAmp,d0
    move.w    d0,DiskLogoY
    add.w     #DISKLOGO_WAVE_DELTA,DiskLogoSinPos
    cmp.w     #(sine_degrees/2),DiskLogoSinPos
    bcc       .noreset
    sub.w     #(sine_degrees/2),DiskLogoSinPos
    move.w    DiskLogoBounceAmp,d0
    lsl.w     #1,d0
    move.w    d0,DiskLogoBounceAmp

    subq.w    #1,DiskLogoBounceCount
    bne       .noreset
    clr.w     DiskLogoY
    clr.w     DiskLogoSinPos
.noreset
    rts

DiskLogoBounceAmp:
    dc.w      40

DiskLogoSinPos:
    dc.w      sine_degrees/4

DiskLogoBounceCount:
    dc.w      4

DisksCopperTick:
    bsr       DisksMove
    bsr       DisksLoadSpriteCopper
    rts

DISK_RES_BLITSIZE      = (256<<6)+8
DISK_RES_MOD           = DiskCopper_Sizeof-16

DisksRestoreCopper:
    WAITBLIT
    move.l    DiskCopperPtrs+8(pc),a0
    move.l    DiskCopperPtrs(pc),a1
    lea       DiskCopper_LogoPlanes(a0),a0
    lea       DiskCopper_LogoPlanes(a1),a1
    move.w    #$09f0,BLTCON0(a6)    
    move.w    #0,BLTCON1(a6)
    move.l    #-1,BLTAFWM(a6)
    move.w    #DISK_RES_MOD,BLTAMOD(a6)
    move.w    #DISK_RES_MOD,BLTDMOD(a6)
    move.l    a0,BLTAPT(a6)
    move.l    a1,BLTDPT(a6)
    move.w    #DISK_RES_BLITSIZE,BLTSIZE(a6)
    rts

;----------------------------------------------------------------------------------
;
; Disk pre-calc table
;
;----------------------------------------------------------------------------------

LOGO_HEIGHT            = 86

PopulateLogoLUT:
    lea       DiskLogoOffset,a0
    moveq     #0,d0
    move.w    #LOGO_HEIGHT-1,d7
.offset
    move.w    d0,(a0)+
    add.w     #Logo_Sizeof,d0
    dbra      d7,.offset


    lea       DiskLogoLookUp,a0
    move.l    #MainLogo,d0
    move.l    #MainLogo+DISK_SCREEN_WIDTH_BYTE,d1
    lea       LogoGrads,a1
    move.w    #LOGO_HEIGHT-1,d7
    move.l    #DISK_SCREEN_WIDTH_BYTE*2,d2
.load
    move.l    d0,Logo_Plane1(a0)
    move.l    d1,Logo_Plane2(a0)
    add.l     d2,d0
    add.l     d2,d1
    move.w    (a1)+,Logo_Color1(a0)
    move.w    (a1)+,Logo_Color2(a0)
    move.w    (a1)+,Logo_Color3(a0)
    lea       Logo_Sizeof(a0),a0
    dbra      d7,.load
    rts

;----------------------------------------------------------------------------------
;
; DisksLoadSpriteCopper
;
;----------------------------------------------------------------------------------


DisksLoadSpriteCopper:
    lea       DiskSprites,a3
    moveq     #SPRITE_COUNT-1,d7
    lea       cpDisksSpritePtr,a2
.loop
    move.l    DiskSprite_CurrentPointer(a3),d1
    move.w    d1,6(a2)
    swap      d1
    move.w    d1,2(a2)
    swap      d1
    addq.l    #8,a2
    lea       DiskSprite_Sizeof(a3),a3
    dbra      d7,.loop
    rts



;----------------------------------------------------------------------------------
;
; DisksPopulateCopper
;
;----------------------------------------------------------------------------------

WAVE_COLOR1            = COLOR01
WAVE_COLOR2            = COLOR03

DisksPopulateCopper:
    move.l    DiskCopperPtrs(pc),a4
    move.w    #DISK_SCREEN_HEIGHT-1,d7

    move.w    #$2c,d4                                                ; line number

    move.l    #DisksBlankLine,d3
    move.w    d3,d2
    swap      d3

.loop
    lea       DiskSprites,a1

    ; test color
    ;move.l      #(COLOR00<<16)|$0f0,DiskCopper_TestColor(a4)
    ;move.l      #(COLOR00<<16)|$000,DiskCopper_TestColor+4(a4)

    ;move.l      #$2c01ff00,DiskCopper_WaitStart(a4)                    ; wait line
    move.l    #$2cdffffe,DiskCopper_WaitEdge(a4)                     ; wait line

    move.l    #$2c59fffe,DiskCopper_WaitCenter(a4)
    ;move.l      #$80df80fe,DiskCopper_WaitEnd(a4)                       ; wait for end of line

    move.w    #WAVE_COLOR1,DiskCopper_WaveColor(a4)
    move.w    #WAVE_COLOR2,DiskCopper_WaveColor+4(a4)

    move.w    #$000,DiskCopper_WaveColor+2(a4)
    move.w    #$000,DiskCopper_WaveColor+6(a4)

    move.w    #BPL1PTH,DiskCopper_Planes+(4*0)(a4)
    move.w    #BPL1PTL,DiskCopper_Planes+(4*1)(a4)
    move.w    #BPL2PTH,DiskCopper_Planes+(4*2)(a4)
    move.w    #BPL2PTL,DiskCopper_Planes+(4*3)(a4)

    move.w    d3,DiskCopper_Planes+2+(4*0)(a4)
    move.w    d2,DiskCopper_Planes+2+(4*1)(a4)
    move.w    d3,DiskCopper_Planes+2+(4*2)(a4)
    move.w    d2,DiskCopper_Planes+2+(4*3)(a4)

    move.w    #BPL3PTH,DiskCopper_LogoPlanes+(4*0)(a4)
    move.w    #BPL3PTL,DiskCopper_LogoPlanes+(4*1)(a4)
    move.w    #BPL4PTH,DiskCopper_LogoPlanes+(4*2)(a4)
    move.w    #BPL4PTL,DiskCopper_LogoPlanes+(4*3)(a4)

    ; logo shit
    move.w    d3,DiskCopper_LogoPlanes+2+(4*0)(a4)
    move.w    d2,DiskCopper_LogoPlanes+2+(4*1)(a4)
    move.w    d3,DiskCopper_LogoPlanes+2+(4*2)(a4)
    move.w    d2,DiskCopper_LogoPlanes+2+(4*3)(a4)

    move.l    #(COLOR04<<16)|$000,DiskCopper_LogoColors+(4*0)(a4)
    move.l    #(COLOR08<<16)|$000,DiskCopper_LogoColors+(4*1)(a4)
    move.l    #(COLOR12<<16)|$000,DiskCopper_LogoColors+(4*2)(a4)

    move.l    #(COLOR05<<16)|$000,DiskCopper_LogoColors+(4*3)(a4)
    move.l    #(COLOR09<<16)|$000,DiskCopper_LogoColors+(4*4)(a4)
    move.l    #(COLOR13<<16)|$000,DiskCopper_LogoColors+(4*5)(a4)

    move.l    #(COLOR07<<16)|$000,DiskCopper_LogoColors+(4*6)(a4)
    move.l    #(COLOR11<<16)|$000,DiskCopper_LogoColors+(4*7)(a4)
    move.l    #(COLOR15<<16)|$000,DiskCopper_LogoColors+(4*8)(a4)

    ;move.b      d4,DiskCopper_WaitStart(a4) 
    move.b    d4,DiskCopper_WaitCenter(a4)
    subq.b    #1,d4
    move.b    d4,DiskCopper_WaitEdge(a4) 
    addq.w    #1,d4


    addq.b    #$1,d4
;    cmp.b       #$00,d4
;    beq         .skipntsc
;    move.l      #$1fc0000,DiskCopper_WaitEnd(a4)                        ; NOP IT!
;.skipntsc

    lea       DiskCopper_PosLeft(a4),a2
    lea       DiskCopper_PosRight(a4),a3
    move.w    #SPR1POS,d5

    moveq     #SPRITE_COUNT-1,d6
.spriteLoop
    move.w    d5,(a2)+
    move.w    DiskSprite_PosLeft(a1),(a2)+
    move.w    d5,(a3)+
    move.w    DiskSprite_PosRight(a1),(a3)+
    lea       DiskSprite_Sizeof(a1),a1
    add.w     #SPR1POS-SPR0POS,d5
    dbra      d6,.spriteLoop

    lea       DiskCopper_Sizeof(a4),a4
    dbra      d7,.loop

    ; setup copper tail

    move.l    #$2c01fffe,(a4)+                                       ; wait line
    move.l    #(INTREQ<<16)+$8010,(a4)+                              ; interrupt line
    move.l    #-2,(a4)+                                              ; eoc
    move.l    #-2,(a4)+

    ; duplicate copper list into 2nd buffer

    move.l    DiskCopperPtrs(pc),a0
    move.l    DiskCopperPtrs+4(pc),a1
    move.l    DiskCopperPtrs+8(pc),a2                                ; restore copy
    move.w    #(DISK_COPPER_TOTAL/4)-1,d7
.copycopper
    move.l    (a0),(a1)+
    move.l    (a0)+,(a2)+
    dbra      d7,.copycopper

    lea       cpDisksJump,a0
    move.l    DiskCopperPtrs(pc),d0
    move.w    d0,6(a0)                                               ; 10 / 28
    swap      d0
    move.w    d0,2(a0)

    rts


DisksLoadCopper:
    lea       cpDisksJump,a0
    move.l    DiskCopperPtrs(pc),d0
    move.w    d0,6(a0)                                               ; 10 / 28
    swap      d0
    move.w    d0,2(a0)
    rts

DisksSwitchCopper:
    lea       DiskCopperPtrs(pc),a0
    move.l    (a0),d0
    move.l    4(a0),(a0)
    move.l    d0,4(a0)
    rts


DiskCopperPtrs:
    dc.l      ScreenMem+DisksChip_CopperBuffer1
    dc.l      ScreenMem+DisksChip_CopperBuffer2
    dc.l      ScreenMem+DisksChip_CopperBufferRes

;----------------------------------------------------------------------------------
;
; DisksPrepSpriteBanks
;
;----------------------------------------------------------------------------------

DisksPrepSpriteBanks:
    lea       SpriteInfo,a0
    lea       DiskSprites,a3
    lea       ScreenMem,a4
    lea       DisksChip_SpriteBanks(a4),a4
    moveq     #SPRITE_COUNT-1,d7

.bankloop
    moveq     #0,d4
    move.l    a4,DiskSprite_BasePointer(a3)
    move.l    a4,DiskSprite_CurrentPointer(a3)
    clr.l     DiskSprite_BackupLine(a3)    


    move.w    #SPRITE_MAX_LINES-1,d6
    move.w    (a0)+,d1                                               ; sprite height

    moveq     #0,d2
    move.w    d1,d2
    lsr.w     #1,d2
    add.w     #DISK_SCREEN_HEIGHT,d2
    divu      d1,d2
    clr.w     d2
    move.l    d2,DiskSprite_Pos(a3)

    clr.l     DiskSprite_Height(a3)
    move.w    d1,DiskSprite_Height(a3)

    move.w    #SPRITE_START_V<<8,d2
    add.w     (a0)+,d2
    move.w    d2,d3
    add.w     (a0)+,d3
    move.w    d2,DiskSprite_PosLeft(a3)
    move.w    d3,DiskSprite_PosRight(a3)

    move.l    (a0)+,DiskSprite_Delta(a3)

    move.l    (a0)+,a1                                               ; sprite gfx

    move.w    d2,(a4)+                                               ; setup sprite control words
    move.w    #SPRITE_CTRL,(a4)+

    move.l    a1,a2
    move.w    d1,d2
.lineloop
    addq.w    #1,d4
    move.l    (a2)+,(a4)+
    subq.w    #1,d2
    bne       .noreset
    move.l    a1,a2
    move.w    d1,d2
.noreset    
    dbra      d6,.lineloop
    clr.l     (a4)+

    lea       DiskSprite_Sizeof(a3),a3
    dbra      d7,.bankloop

    rts


;----------------------------------------------------------------------------------
;
; DisksMove
;
;----------------------------------------------------------------------------------

DisksMove:
    lea       DiskSprites,a3
    moveq     #SPRITE_COUNT-1,d7
.loop
    move.l    DiskSprite_Height(a3),d1
    move.l    d1,d2
    move.l    DiskSprite_Pos(a3),d0
    add.l     DiskSprite_Delta(a3),d0
    bpl       .positive

    neg.l     d2
    bra       .wrap

.positive
    cmp.l     d1,d0
    bcs       .nowrap
.wrap
    sub.l     d2,d0

.nowrap
    move.l    d0,DiskSprite_Pos(a3)

    swap      d0
    add.w     d0,d0
    add.w     d0,d0

    move.l    DiskSprite_CurrentPointer(a3),a0
    move.l    DiskSprite_BackupLine(a3),(a0)                         ; restore long
    move.l    DiskSprite_BasePointer(a3),a0
    lea       (a0,d0.w),a0
    move.l    (a0),DiskSprite_BackupLine(a3)                         ; save line

    move.w    DiskSprite_PosLeft(a3),(a0)
    move.w    #SPRITE_CTRL,2(a0)

    move.l    a0,DiskSprite_CurrentPointer(a3)

    lea       DiskSprite_Sizeof(a3),a3
    dbra      d7,.loop
    rts

DisksReverse:
    lea       DiskSprites,a3
    moveq     #SPRITE_COUNT-1,d7
.loop
    neg.l     DiskSprite_Delta(a3)    
    lea       DiskSprite_Sizeof(a3),a3
    dbra      d7,.loop
    rts


;----------------------------------------------------------------------------------
;
; FAST MEM
;
;----------------------------------------------------------------------------------


    section   SpriteTestMem_bss_Fast,bss

DiskSprites:
    ds.b      DiskSprite_Sizeof*SPRITE_COUNT


;----------------------------------------------------------------------------------
;
; CHIP DATA
;
;----------------------------------------------------------------------------------

    section   Disks_Data_Chip,data_c

MainLogo:
    incbin    "MAIN_LOGO_320.raw"

cpDisksCopper:
    dc.w      DIWSTRT,$2c81                                          ; window start stop
    dc.w      DIWSTOP,$2cc1                                          ; 192 + 8

    dc.w      DDFSTRT,$38                                            ; datafetch start stop 
    dc.w      DDFSTOP,$d0

    dc.w      BPLCON0,$4200                                          ; set as 4 bp display
    dc.w      BPLCON1,$0000                                          ; set scroll 0
    dc.w      BPLCON2,$0000    
    dc.w      BPL1MOD,DISK_SCREEN_MOD
    dc.w      BPL2MOD,DISK_SCREEN_MOD

    dc.w      SPR0PTH,0
    dc.w      SPR0PTL,0
cpDisksSpritePtr:
    dc.w      SPR1PTH,0
    dc.w      SPR1PTL,0
    dc.w      SPR2PTH,0
    dc.w      SPR2PTL,0
    dc.w      SPR3PTH,0
    dc.w      SPR3PTL,0
    dc.w      SPR4PTH,0
    dc.w      SPR4PTL,0
    dc.w      SPR5PTH,0
    dc.w      SPR5PTL,0
    dc.w      SPR6PTH,0
    dc.w      SPR6PTL,0
    dc.w      SPR7PTH,0
    dc.w      SPR7PTL,0

    dc.w      COLOR00,$000
    dc.w      COLOR01,$00f                                           ; wave color 1
    dc.w      COLOR02,$aaf
    dc.w      COLOR03,$aaf                                           ; wave color 2

    dc.w      COLOR04,$0469
    dc.w      COLOR05,$0469                                          ; wave color 1
    dc.w      COLOR06,$0469
    dc.w      COLOR07,$0469                                          ; wave color 2

    dc.w      COLOR08,$08AB
    dc.w      COLOR09,$08AB                                          ; wave color 1
    dc.w      COLOR10,$08AB
    dc.w      COLOR11,$08AB                                          ; wave color 2

    dc.w      COLOR12,$0FFF
    dc.w      COLOR13,$0FFF                                          ; wave color 1
    dc.w      COLOR14,$0FFF
    dc.w      COLOR15,$0FFF                                          ; wave color 2

;0000 0469 08AB 0FFF

    dc.w      COLOR16,$000
    dc.w      COLOR17,$036
    dc.w      COLOR18,$059
    dc.w      COLOR19,$778

    dc.w      COLOR20,$000
    dc.w      COLOR21,$036
    dc.w      COLOR22,$059
    dc.w      COLOR23,$778

    dc.w      COLOR24,$000
    dc.w      COLOR25,$035
    dc.w      COLOR26,$047
    dc.w      COLOR27,$667

    dc.w      COLOR28,$000
    dc.w      COLOR29,$013
    dc.w      COLOR30,$024
    dc.w      COLOR31,$445

    dc.w      $2801,$fffe
cpDisksJump:
    dc.w      COP2LCH,0
    dc.w      COP2LCL,0
    dc.w      COPJMP2,0


    section   Disks_Data_Fast,data

DISKA_LEFT             = $3d
DISKA_OFFSET           = $96-6
DISKB_LEFT             = $52                                         ; 4e
DISKB_OFFSET           = $76-8
DISKC_LEFT             = $61
DISKC_OFFSET           = $62-10

DISKA_DELTA            = (48<<16)/FRM_BEAT
DISKB_DELTA            = (29<<16)/FRM_BEAT
DISKC_DELTA            = (16<<16)/FRM_BEAT


DisksWaveColors:
    dc.w      $414,$222
    dc.w      $515,$444
    dc.w      $625,$555
    dc.w      $726,$777
    dc.w      $836,$999
    dc.w      $937,$bbb
    dc.w      $a37,$ddd
    dc.w      $b38,$fff

SpriteInfo:
    dc.w      48                                                     ; height
    dc.w      DISKA_LEFT,DISKA_OFFSET                                ; pos left / offset right
    dc.l      DISKA_DELTA                                            ; detla
    dc.l      Sprite48A

    dc.w      48                                                     ; height
    dc.w      DISKA_LEFT+8,DISKA_OFFSET                              ; pos left / offset right
    dc.l      DISKA_DELTA                                            ; detla
    dc.l      Sprite48B

    dc.w      48                                                     ; height
    dc.w      DISKA_LEFT+$10,DISKA_OFFSET                            ; pos left / offset right
    dc.l      DISKA_DELTA                                            ; detla
    dc.l      Sprite48C

    dc.w      29                                                     ; height
    dc.w      DISKB_LEFT,DISKB_OFFSET                                ; pos left / offset right
    dc.l      DISKB_DELTA                                            ; detla
    dc.l      Sprite32A

    dc.w      29                                                     ; height
    dc.w      DISKB_LEFT+8,DISKB_OFFSET                              ; pos left / offset right
    dc.l      DISKB_DELTA                                            ; detla
    dc.l      Sprite32B

    dc.w      16                                                     ; height
    dc.w      DISKC_LEFT,DISKC_OFFSET                                ; pos left / offset right
    dc.l      DISKC_DELTA                                            ; detla
    dc.l      Sprite16

    include   grads/grads.asm

Sprite48A: 
    incbin    "disc_48_a.spr"
Sprite48B: 
    incbin    "disc_48_b.spr"
Sprite48C: 
    incbin    "disc_48_c.spr"

Sprite32A: 
    incbin    "disc_32_a.spr"
Sprite32B: 
    incbin    "disc_32_b.spr"
Sprite16: 
    incbin    "disc_16.spr"


;----------------------------------------------------------------------------------
;
; FAST RAM
;
;----------------------------------------------------------------------------------

    section   Disks_bss_Fast,bss

DiskLogoOffset:
    ds.w      LOGO_HEIGHT

DiskLogoLookUp:
    ds.b      Logo_Sizeof*LOGO_HEIGHT

DisksWaveLookUp:
    ds.l      DISK_WAVE_SIZE

DisksVolLookup:
    ds.b      DISK_WAVE_VOLSCALES*256

;----------------------------------------------------------------------------------
;
; CHIP RAM
;
;----------------------------------------------------------------------------------


    section   Disks_bss_Chip,bss_c

DisksBlankLine:
    ds.b      DISK_SCREEN_WIDTH_BYTE

DisksNullSprite:
    ds.l      2 


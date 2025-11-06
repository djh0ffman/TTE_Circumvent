

    include      "tunnel_struct.asm"
    section      tunnel_code,code

TUNNEL_DMA       = %1000001111000000

; ------------------------------------------
;
; tunnel init
;
; ------------------------------------------

TunnelDiscreteInit:
    ;bsr            TunnelCalcRot
    bsr          TunnelCalcRotXY
    bsr          TunnelFlipImage
    rts



TunnelFlipImage:
    ; make bitflip table
    move.w       #0,d0
    move.w       #256-1,d7
    lea          Tunnel_FlipBits,a0
.loop
    move.w       d0,d1
    moveq        #0,d2
    REPT         8
    clr.b        d2
    lsl.b        #1,d1
    scs          d2
    ror.w        #1,d2
    ENDR
    lsr.w        #8,d2
    move.b       d2,(a0)+
    addq.w       #1,d0
    dbra         d7,.loop

    moveq        #0,d0

    lea          Tunnel_FlipBits,a4
    lea          Tunnel_BKG,a0
    lea          Tunnel_BKGFix,a1
    lea          32(a1),a2
    
    move.w       #256-1,d7
.flip
    REPT         16
    move.b       (a0)+,d0
    move.b       d0,(a1)+
    move.b       (a4,d0),-(a2)
    ENDR
    
    lea          16(a1),a1
    lea          16*3(a2),a2
    dbra         d7,.flip
    rts


TunnelClearAll:
    lea          ScreenMem,a0
    move.l       #TunnelSizeof,d7
    add.l        d7,a0

    divu         #52,d7
    subq.w       #1,d7
    bmi          .remain
    PUSHM        a5/a6
    sub.l        a1,a1
    sub.l        a2,a2
    sub.l        a3,a3
    sub.l        a4,a4
    sub.l        a5,a5
    sub.l        a6,a6
    moveq        #0,d0
    moveq        #0,d1
    moveq        #0,d2
    moveq        #0,d3
    moveq        #0,d4
    moveq        #0,d5
    moveq        #0,d6
.loop1
    movem.l      a1-a6/d0-d6,-(a0)
    dbra         d7,.loop1
    POPM         a5/a6
.remain
    ; remainder
    clr.w        d7
    swap         d7
    subq.w       #1,d7
    bcs          .done
.loop2
    clr.b        -(a0)
    dbra         d7,.loop2
.done

    lea          ScreenMem,a1
    rts



TunnelInit:
    move.l       #$BABEFEED,RandomSeed(a5)

    bsr          TunnelClearAll

    bsr          TunnelPopulateCopper

    move.l       #Tunnel_BKGFix,d0
    lea          cpTunnelBack,a0
    move.w       d0,6(a0)
    swap         d0
    move.w       d0,2(a0)
    swap         d0
    add.l        #TUNNEL_WIDTH_BYTE,d0
    addq.l       #8,a0
    move.w       d0,6(a0)
    swap         d0
    move.w       d0,2(a0)
    swap         d0

    move.w       #128,Tunnel_MasterZ

    move.w       #(TUNNEL_ROT_COUNT/3)+1,Tunnel_PointDelta
    ;move.w         #(TUNNEL_ROT_COUNT/3)+1,Tunnel_PointDeltaNext(a5)

    lea          Tunnel_Z,a0
    move.w       #$7f,d0
    move.w       #7*8,d1
    bsr          ParamInit

    move.l       #TUNNEL_PLANES,d0
    lea          TunnelBufferPtrs,a1
    move.w       #TUNNEL_BUFFERS-1,d7
.loop1
    move.l       d0,(a1)+
    add.l        #TUNNEL_PLANE_SIZE,d0
    dbra         d7,.loop1

    move.l       #SOLID_PLANES,d0
    lea          SolidBufferPtrs,a1
    move.w       #SOLID_BUFFERS-1,d7
.loop2
    move.l       d0,(a1)+
    add.l        #TUNNEL_PLANE_SIZE,d0
    dbra         d7,.loop2

    bsr          TunnelLoadSwitch

    lea          cpTunnel,a0
    move.l       a0,COP1LC(a6)

    move.w       #TUNNEL_DMA,DMACON(a6)
    rts



; ------------------------------------------
;
; load copper and rotate buffers
;
; ------------------------------------------


TunnelLoadSwitch:
    lea          TunnelBufferPtrs(pc),a1
    move.l       (a1),d0

    lea          cpTunnelPlanes,a0
    move.w       d0,6(a0)
    swap         d0
    move.w       d0,2(a0)

    ROTATE_LONG  a1,TUNNEL_BUFFERS

    lea          SolidBufferPtrs(pc),a1
    move.l       (a1),d0

    lea          cpSolidPlanes,a0
    move.w       d0,6(a0)
    swap         d0
    move.w       d0,2(a0)

    ROTATE_LONG  a1,SOLID_BUFFERS


    lea          TunnelCopPtrs(pc),a1
    move.l       (a1),d0
    lea          cpTunnelCop2,a0
    move.w       d0,6(a0)
    swap         d0
    move.w       d0,2(a0)

    ROTATE_LONG  a1,2

    rts

TunnelBufferPtrs:
    dcb.l        TUNNEL_BUFFERS

SolidBufferPtrs:
    dcb.l        SOLID_BUFFERS



; ------------------------------------------
;
; tunnel tick
;
; ------------------------------------------

TunnelTick:
    bsr          TunnelTestRotXY
    bsr          TunnelDrawBoxes
    bsr          TunnelDrawEdges
    bsr          TunnelDrawRing

    bsr          TunnelParamTest
    bsr          ParamListRun
    bsr          TunnelEndParams
    bsr          TunnelMidRot

    bsr          SolidFill

    bsr          TunnelClearCPU
    bsr          SolidClear
    bsr          TunnelRandScroll
    bsr          TunnelLoadSwitch
    ;move.w         #$004,$dff180
    rts

;TunnelCop_Wait       rs.l       1                 
;TunnelCop_Scroll     rs.l       1
;TunnelCop_BplMod     rs.l       1
;TunnelCop_WaitEnd    rs.l       1    

TunnelPopulateCopper:
    move.w       #TUNNEL_HEIGHT-1,d7
    move.l       TunnelCopPtrs(pc),a4
    move.l       #BPLCON1<<16,d3
    move.l       #(BPL2MOD<<16)|TUNNEL_WIDTH_BYTE,d2
    move.w       #TUNNEL_HEIGHT-1,d7
    move.w       #$2c,d4                                                        ; line number
.loop
    move.l       #$2c01ff00,TunnelCop_Wait(a4)                                  ; wait line
    move.l       #$1fc0000,TunnelCop_WaitEnd(a4)                                ; NOP IT!
    move.l       d3,TunnelCop_Scroll(a4)
    move.l       d2,TunnelCop_BplMod(a4)
    move.b       d4,TunnelCop_Wait(a4) 

    addq.b       #$1,d4
    bne          .skipntsc
    move.l       #$80df80fe,TunnelCop_WaitEnd(a4)                               ; wait for end of line
.skipntsc
    cmp.b        #$ab,d4
    bne          .skipflip
    move.l       #(BPL2MOD<<16)|(-(TUNNEL_WIDTH_BYTE*3)&$ffff),d2
.skipflip

    lea          TunnelCop_Sizeof(a4),a4
    dbra         d7,.loop

    move.l       #-2,(a4)+
    move.l       #-2,(a4)+

    ; dupe it
    move.l       TunnelCopPtrs(pc),a0
    move.l       TunnelCopPtrs+4(pc),a1
    move.w       #(TUNNELCOP_SIZE/4)-1,d7
.copyloop
    move.l       (a0)+,(a1)+
    dbra         d7,.copyloop
    rts
    

TunnelCopPtrs:
    dc.l         ScreenMem+TunnelCopper1
    dc.l         ScreenMem+TunnelCopper2



TunnelRandScroll:
;    rts
    RANDOMWORD
    and.w        #512-1,d0
    lea          RandomList,a0
    lea          (a0,d0.w),a0

    move.l       TunnelCopPtrs(pc),a4
    lea          TunnelCop_Scroll+3(a4),a4

    move.b       #$f0,d2

    move.l       #TunnelCop_Sizeof*2,d5
    move.w       TickCounter(a5),d0
    and.w        #3,d0
    beq          .loop
    lea          TunnelCop_Sizeof(a4),a4
.loop   
    REPT         (TUNNEL_HEIGHT/2)
    move.b       (a0)+,d0
    and.b        d2,d0
    move.b       d0,(a4)
    add.l        d5,a4
    ENDR
    rts

; ------------------------------------------
;
; tunnel draw boxes
;
; ------------------------------------------

; in	d0.w	x0
;	d1.w	y0
;	d2.w	x1
;	d3.w	y1
;	d4.w	bytes per row in bitplane
;	a0	bitplane
;	a6	$dff000

TunnelDrawBoxes:
    move.w       #TUNNEL_DEPTH-1,d6

    lea          TunnelPoints,a1
    move.w       #TUNNEL_WIDTH_BYTE,d4
.layer
    move.w       Tunnel_Points(a5),d7
    subq.w       #2,d7

    move.w       (a1)+,d0
    move.w       (a1)+,d1
    move.w       d0,-(sp)
    move.w       d1,-(sp)
.loop
    move.w       (a1)+,d2
    move.w       (a1)+,d3

    jsr          BlitterLine
    move.w       d2,d0
    move.w       d3,d1
    dbra         d7,.loop

    move.w       d5,d0
    move.w       d6,d1
    move.w       (sp)+,d1
    move.w       (sp)+,d0
    jsr          BlitterLine

    dbra         d6,.layer

    rts


TunnelDrawEdges:
    move.w       #TUNNEL_WIDTH_BYTE,d4

    lea          TunnelPoints,a1
    move.w       Tunnel_Points(a5),d0
    move.w       d0,d7
    add.w        d0,d0
    add.w        d0,d0
    lea          (a1,d0.w),a2

    mulu         #TUNNEL_DEPTH-1,d7
    subq.w       #1,d7                                                          ; dbra
.loop
    move.w       (a1)+,d0
    move.w       (a1)+,d1
    move.w       (a2)+,d2
    move.w       (a2)+,d3
    jsr          BlitterLine
    dbra         d7,.loop

    rts



TunnelDrawRing:
    move.w       TunnelRingId(pc),d0
    bpl          .ok
    rts
.ok
    tst.w        TunnelRingFlip
    beq          .inward
    move.w       #2,d0
    sub.w        TunnelRingId(pc),d0
.inward
    move.l       SolidBufferPtrs(pc),a0
    move.w       #TUNNEL_WIDTH_BYTE,d4

    mulu         Tunnel_Points(a5),d0
    add.w        d0,d0
    add.w        d0,d0
    lea          TunnelPoints,a1    
    add.l        d0,a1
    bsr          .ring

.ring
    move.w       Tunnel_Points(a5),d7
    subq.w       #3,d7

    move.w       (a1)+,d0
    move.w       (a1)+,d1
    PUSHM        d0/d1
    move.w       (a1)+,d2
    move.w       (a1)+,d3
    jsr          BlitterLineFill
.loop    
    move.w       d2,d0
    move.w       d3,d1
    move.w       (a1)+,d2
    move.w       (a1)+,d3
    jsr          BlitterLineFill
    dbra         d7,.loop

    move.w       d2,d0
    move.w       d3,d1
    POPM         d2/d3
    jsr          BlitterLineFill
    

    rts


TunnelRingId: 
    dc.w         -1
TunnelRingFlip:
    dc.w         0

TunnelDrawWall:
    moveq        #0,d0
    move.w       Tunnel_Points(a5),d0
.again
    moveq        #TUNNEL_DEPTH-2,d7
    lea          TunnelPoints,a1
    move.l       d0,-(sp)
    bsr          .item
    move.l       (sp)+,d0
    subq.w       #2,d0
    bpl          .again
    rts


.item
    subq.w       #1,d0
    bpl          .positive
    add.w        Tunnel_Points(a5),d0
.positive
    move.l       d0,-(sp)
    bsr          .test
    move.l       (sp)+,d0

    move.w       Tunnel_Points(a5),d1
    add.w        d1,d1
    add.w        d1,d1
    lea          (a1,d1.w),a1
    dbra         d7,.item

    rts


.test
    move.l       SolidBufferPtrs(pc),a0

    move.w       #TUNNEL_WIDTH_BYTE,d4


;    moveq          #0,d0
;    move.w         Tunnel_WallId(a5),d0
    moveq        #0,d1
    move.w       Tunnel_Points(a5),d1

    move.w       d1,d5
    add.w        d5,d5
    add.w        d5,d5                                                          ; layer size

    divu         d1,d0
    swap         d0
    move.w       d0,d2                                                          ; left colum
    move.w       d2,d3                                                          ; right colum
    addq.w       #1,d3
    cmp.w        d1,d3
    bne          .notedge
    moveq        #0,d3
.notedge
    add.w        d2,d2
    add.w        d2,d2                                                          ; left column index
    add.w        d3,d3  
    add.w        d3,d3                                                          ; right column index

    lea          (a1,d3.w),a2
    lea          (a1,d2.w),a3


.loop
    move.w       0(a3),d0
    move.w       2(a3),d1
    move.w       0(a2),d2
    move.w       2(a2),d3
    jsr          BlitterLineFill

    move.w       d2,d0
    move.w       d3,d1
    move.w       0(a2,d5.w),d2
    move.w       2(a2,d5.w),d3
    jsr          BlitterLineFill

    move.w       d2,d0
    move.w       d3,d1
    move.w       0(a3,d5.w),d2
    move.w       2(a3,d5.w),d3
    jsr          BlitterLineFill

    move.w       d2,d0
    move.w       d3,d1
    move.w       0(a3),d2
    move.w       2(a3),d3
    jsr          BlitterLineFill

    rts

TUNNEL_ROT_DELTA = sine_degrees/TUNNEL_ROT_COUNT

TunnelCalcRotXY:
    lea          sinus,a0
    lea          TunnelRotXY,a1
    move.w       #TUNNEL_ROT_COUNT-1,d7
    moveq        #0,d0                                                          ; sin
    move.w       #sine_degrees/4,d1                                             ; cos
.loop
    move.w       d0,d2
    move.w       d1,d3
    add.w        d2,d2
    add.w        d3,d3
    move.w       (a0,d2.w),d2                                                   ; sin (X)
    move.w       (a0,d3.w),d3                                                   ; cos (Y)

    ; scale
    ext.l        d2
    ext.l        d3
    divs         #130,d2
    divs         #130,d3
    move.w       d2,(a1)+
    move.w       d3,(a1)+

    add.w        #TUNNEL_ROT_DELTA,d0
    add.w        #TUNNEL_ROT_DELTA,d1
    and.w        #sine_degrees-1,d1
    dbra         d7,.loop
    rts


TunnelTestRotXY:
    move.w       Tunnel_Z,d0
    move.w       d0,Tunnel_ZStep(a5)
    ; initial calc of points based on delta
    moveq        #0,d0
    moveq        #0,d1
    move.w       Tunnel_PointDelta,d0
    move.w       #TUNNEL_ROT_COUNT,d1
    divu         d0,d1

    moveq        #1,d0
    swap         d1
    tst.w        d1
    bne          .add
    moveq        #0,d0
.add
    swap         d1
    add.w        d0,d1
    move.w       d1,Tunnel_Points(a5)

    ; thats done, now calc all the points for drawing later

    move.w       #TUNNEL_DEPTH-1,d6

    ;move.w         #128,d0
    move.w       Tunnel_MasterZ,d0

    lea          TunnelRotXY,a1
    lea          TunnelPoints,a2
  

    move.w       Tunnel_Offset,d4
    add.w        Tunnel_Offset2,d4
.layer
    move.w       Tunnel_Points(a5),d7
    subq.w       #1,d7

    move.w       d4,d5
                                     ; step
    move.l       TunnelBufferPtrs,a0
.loop    
    move.w       d5,d3
    and.w        #TUNNEL_ROT_COUNT-1,d3
    add.w        d3,d3
    add.w        d3,d3

    move.w       (a1,d3.w),d2
    move.w       2(a1,d3.w),d3
    ext.l        d2
    ext.l        d3

    asl.w        #7,d2
    asl.w        #7,d3
    divs         d0,d2
    divs         d0,d3

    add.w        #TUNNEL_CENTER_X,d2
    add.w        #TUNNEL_CENTER_Y,d3

    move.w       d2,(a2)+
    move.w       d3,(a2)+

    add.w        Tunnel_PointDelta,d5
    dbra         d7,.loop

    move.w       Tunnel_ZStep(a5),d5
    add.w        d5,d0
    add.w        d5,Tunnel_ZStep(a5)
    add.w        Tunnel_Twist,d4

    dbra         d6,.layer
.nope
    rts


TunnelClear:
    WAITBLITN
    move.l       TunnelBufferPtrs+((TUNNEL_BUFFERS-1)*4),a0
    move.w       #$0100,BLTCON0(a6)
    move.w       #0,BLTCON1(a6)
    move.w       #0,BLTDMOD(a6)                                                 ; FORE_MODULO
    move.l       a0,BLTDPT(a6)
    move.w       #TUNNEL_CLEAR_BLIT_SIZE,BLTSIZE(a6)
    rts

TunnelClearCPU:
    move.l       TunnelBufferPtrs+((TUNNEL_BUFFERS-1)*4),a0
    add.l        #TUNNEL_PLANE_SIZE,a0
    PUSHM        a5/a6
    sub.l        a1,a1
    sub.l        a2,a2
    sub.l        a3,a3
    sub.l        a4,a4
    sub.l        a5,a5
    sub.l        a6,a6
    moveq        #0,d0
    moveq        #0,d1
    moveq        #0,d2
    moveq        #0,d3
    moveq        #0,d4
    moveq        #0,d5
    moveq        #0,d6
    moveq        #0,d7
    REPT         146
    movem.l      a1-a6/d0-d7,-(a0)
    ENDR
    movem.l      d0-d3,-(a0)
    POPM         a5/a6
    rts


SolidClear:
    WAITBLITN
    move.l       SolidBufferPtrs+((SOLID_BUFFERS-1)*4),a0
    move.w       #$0100,BLTCON0(a6)
    move.w       #0,BLTCON1(a6)
    move.w       #0,BLTDMOD(a6)                                                 ; FORE_MODULO
    move.l       a0,BLTDPT(a6)
    move.w       #TUNNEL_CLEAR_BLIT_SIZE,BLTSIZE(a6)
    rts

FILL_BLTCON1     = %0000000000010010

SolidFill:
    move.l       SolidBufferPtrs,a0
    add.l        #TUNNEL_PLANE_SIZE-2,a0
    WAITBLIT
    move.w       #$09f0,BLTCON0(a6)
    move.w       #FILL_BLTCON1,BLTCON1(a6)
    move.l       a0,BLTAPT(a6)
    move.l       a0,BLTDPT(a6)
    move.w       #0,BLTAMOD(a6)
    move.w       #0,BLTDMOD(a6)
    move.w       #TUNNEL_CLEAR_BLIT_SIZE,BLTSIZE(a6)
    rts


TunnelEndParams:
    cmp.w        #8,SnareCount
    bne          .exit
    cmp.w        #7*4,TunnelEndPos
    beq          .exit
    
    moveq        #0,d0
    move.w       TunnelEndPos,d0
    mulu         #TUNNEL_END_DELTA,d0
    add.w        d0,d0
    lea          sinus,a0
    move.w       (a0,d0.w),d0 
    divs         #10,d0
    add.w        #128,d0
    move.w       d0,Tunnel_MasterZ
    move.w       d0,Tunnel_Z
    addq.w       #1,TunnelEndPos
    ;cmp.w          #7*4,TunnelEndPos
    ;bne            .exit
    ;clr.w          TunnelEndPos
.exit
    rts

TUNNEL_END_DELTA = (sine_degrees/4)/(7*4)

TunnelEndPos:
    dc.w         0


TUNNEL_OFFROT    = TUNNEL_ROT_COUNT/FRM_BAR

TunnelMidRot:
    cmp.w        #4,SnareCount
    bcs          .exit
    subq.w       #2,Tunnel_Offset2
.exit
    rts


SOUND_CLICK      = $26

TunnelParamTest:
    cmp.w        #8,SnareCount
    bne          .ok
    rts
.ok
    moveq        #0,d0
    move.w       TickCounter(a5),d0
    divu         #FRM_BAR,d0
    swap         d0

    tst.w        d0
    beq          .bar

    moveq        #2,d1
    cmp.w        #CLICK1,d0
    beq          .click
    subq.w       #1,d1
    cmp.w        #CLICK2,d0
    beq          .click
    subq.w       #1,d1
    cmp.w        #CLICK3,d0
    beq          .click


    cmp.w        #SNARE,d0
    beq          .snare

    rts

.bar
    move.l       TunnelSizePointer,a1
    move.w       (a1)+,d0
    move.l       a1,TunnelSizePointer
    move.w       #7*4,d1
    lea          Tunnel_PointDelta,a0
    bsr          ParamInit

    move.l       TunnelOffsetPointer,a1
    move.w       (a1)+,d0
    move.l       a1,TunnelOffsetPointer
    move.w       #7*4,d1
    lea          Tunnel_Offset,a0
    bsr          ParamInit
    rts

.snare 
    addq.w       #1,SnareCount
    move.w       #-1,TunnelRingId
    eor.w        #1,TunnelRingFlip

    cmp.w        #8,SnareCount
    beq          .done

    lea          Tunnel_Z,a0
    move.w       Param_Value(a0),d0
    add.w        #$100,Param_Value(a0)
    move.w       #7*4,d1
    bsr          ParamInit


    lea          Tunnel_MasterZ,a0
    move.w       Param_Value(a0),d0
    add.w        #$20,Param_Value(a0)
    move.w       #7*2,d1
    bsr          ParamInit
.done
    rts


.click
    move.w       d1,TunnelRingId
    move.l       TunnelTwistPointer,a1
    move.w       (a1)+,d0
    move.l       a1,TunnelTwistPointer
    move.w       #7*2,d1
    lea          Tunnel_Twist,a0
    bsr          ParamInit

.noclick
    rts    

CLICK1           = 7*3
CLICK2           = CLICK1*2
CLICK3           = CLICK1*3
CLICK4           = CLICK1+(7*16)
CLICK5           = CLICK2+(7*16)
CLICK6           = CLICK3+(7*16)
SNARE            = 12*7

SnareCount:
    dc.w         0


TunnelParamList:
    dc.l         Tunnel_PointDelta
    dc.l         Tunnel_Z
    dc.l         Tunnel_Offset
    dc.l         Tunnel_Twist
    dc.l         Tunnel_MasterZ
    dc.l         0


TunnelSizePointer:
    dc.l         TunnelSizes    

TunnelOffsetPointer:
    dc.l         TunnelOffsets    

TunnelTwistPointer:
    dc.l         TunnelTwists

TunnelTwists:
    dc.w         -20
    dc.w         -40
    dc.w         -60
    dc.w         100
    dc.w         50
    dc.w         0

    dc.w         -40
    dc.w         -80
    dc.w         -120
    dc.w         150
    dc.w         75
    dc.w         0

    dc.w         -50
    dc.w         -100
    dc.w         -150
    dc.w         200
    dc.w         100
    dc.w         0

    dc.w         -60
    dc.w         -120
    dc.w         -180
    dc.w         180
    dc.w         90
    dc.w         0

    dc.w         -50
    dc.w         -100
    dc.w         -150
    dc.w         100
    dc.w         50
    dc.w         0

    dc.w         -40
    dc.w         -80
    dc.w         -120
    dc.w         80
    dc.w         40
    dc.w         0



TunnelOffsets:
    dc.w         (TUNNEL_ROT_COUNT/8)
    dc.w         (TUNNEL_ROT_COUNT/10)
    dc.w         (TUNNEL_ROT_COUNT/12)
    dc.w         (TUNNEL_ROT_COUNT/14)
    dc.w         (TUNNEL_ROT_COUNT/12)
    dc.w         (TUNNEL_ROT_COUNT/10)
    dc.w         (TUNNEL_ROT_COUNT/8)
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/3)+1
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         (TUNNEL_ROT_COUNT/6)+1
    dc.w         (TUNNEL_ROT_COUNT/7)+1
    dc.w         (TUNNEL_ROT_COUNT/6)+1
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/3)+1


TunnelSizes:
; 3
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         (TUNNEL_ROT_COUNT/6)+1
    dc.w         (TUNNEL_ROT_COUNT/7)+1
    dc.w         (TUNNEL_ROT_COUNT/6)+1
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/3)+1
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         (TUNNEL_ROT_COUNT/6)+1
    dc.w         (TUNNEL_ROT_COUNT/7)+1
    dc.w         (TUNNEL_ROT_COUNT/6)+1
    dc.w         (TUNNEL_ROT_COUNT/5)+1
    dc.w         TUNNEL_ROT_COUNT/4
    dc.w         (TUNNEL_ROT_COUNT/3)+1


; d0 = next value
; d1 = number of steps
; a0 = param structure

PARAM_ANGLES     = 512
SINE_RANGE       = $4000
PARAM_SHIFT      = 4

ParamInit:
    clr.w        Param_Angle(a0)
    move.w       d0,Param_Next(a0)
    move.w       d1,Param_Count(a0)         
    move.w       Param_Value(a0),d2
    move.w       d2,Param_Current(a0)
    sub.w        d2,d0
    move.w       d0,Param_Diff(a0)
    moveq        #0,d2
    move.w       #PARAM_ANGLES<<PARAM_SHIFT,d2
    divu         d1,d2
    move.w       d2,Param_Step(a0)
    move.w       #1,Param_Active(a0)
    rts

; a0 = param structure

ParamListRun:
    cmp.w        #8,SnareCount
    bne          .ok
    rts
.ok
    lea          TunnelParamList,a4
.loop
    move.l       (a4)+,d0
    beq          .done
    move.l       d0,a0
    bsr          ParamRun
    bra          .loop
.done
    rts

ParamRun:
    tst.w        Param_Active(a0)
    beq          .exit

    tst.w        Param_Count(a0)
    bne          .runit
    move.w       Param_Next(a0),Param_Value(a0)
    rts

.runit
    lea          Quartic,a1
    move.w       Param_Angle(a0),d0
    lsr.w        #PARAM_SHIFT,d0
    add.w        d0,d0
    move.w       (a1,d0.w),d0                                                   ; quart value
    ext.l        d0
    move.w       Param_Diff(a0),d1
    muls         d1,d0
    divs         #SINE_RANGE,d0
    add.w        Param_Current(a0),d0
    move.w       d0,Param_Value(a0)
    subq.w       #1,Param_Count(a0)
    move.w       Param_Step(a0),d0
    add.w        d0,Param_Angle(a0)
.exit
    rts

    ;include        "..\greets\blitbits.i"
    include      "linedraw.asm"


    section      tunnel_data_fast,data

Quartic:
    incbin       "quartic.bin"
Tunnel_BKG:
    incbin       "back.raw"
    
; ------------------------------------------
;
; tunnel fast ram
;
; ------------------------------------------

    section      tunnel_fast_ram,bss
; word x / y
TunnelPoints:
    ds.l         100                                                            ; TODO: maybe sanitise this.. TUNNEL_DEPTH*4

TunnelRotXY:
    ds.l         TUNNEL_ROT_COUNT

; word x / y * 4
TunnelRotation:
    ds.l         TUNNEL_ROT_COUNT*4
TunnelRotationEnd:

; params

Tunnel_Offset2:
    ds.w         1

Tunnel_PointDelta:
    ds.b         Param_Sizeof
Tunnel_Z:
    ds.b         Param_Sizeof
Tunnel_Offset:
    ds.b         Param_Sizeof
Tunnel_Twist:
    ds.b         Param_Sizeof
Tunnel_MasterZ:
    ds.b         Param_Sizeof

Tunnel_FlipBits:
    ds.b         256

; ------------------------------------------
;
; tunnel chip data
;
; ------------------------------------------


    section      tunnel_data_chip,data_c
TUNNEL_DIW_W     = 256
TUNNEL_DIW_H     = 255
TUNNEL_DIW_XSTRT = ($242-TUNNEL_DIW_W)/2
TUNNEL_DIW_YSTRT = ($158-TUNNEL_DIW_H)/2
TUNNEL_DIW_XSTOP = TUNNEL_DIW_XSTRT+TUNNEL_DIW_W
TUNNEL_DIW_YSTOP = TUNNEL_DIW_YSTRT+TUNNEL_DIW_H

cpTunnel:
    ;dc.w           DIWSTRT,$2c81                                    ; window start stop
    ;dc.w           DIWSTOP,$2cc1                                    ; 192 + 8

    ;dc.w           DDFSTRT,$38                                      ; datafetch start stop 
    ;dc.w           DDFSTOP,$d0

    dc.w         DIWSTRT,TUNNEL_DIW_YSTRT<<8!TUNNEL_DIW_XSTRT
    dc.w         DIWSTOP,(TUNNEL_DIW_YSTOP-256)<<8!(TUNNEL_DIW_XSTOP-256)
    dc.w         DDFSTRT,(TUNNEL_DIW_XSTRT-17)>>1&$fc
    dc.w         DDFSTOP,(TUNNEL_DIW_XSTRT-17+(TUNNEL_DIW_W>>4-1)<<4)>>1&$fc

    dc.w         BPLCON0,$4200                                                  ; set as 1 bp display
    dc.w         BPLCON1,$0000                                                  ; set scroll 0
    dc.w         BPLCON2,$0000    
    dc.w         BPL1MOD,0
    dc.w         BPL2MOD,TUNNEL_WIDTH_BYTE

    dc.w         COLOR01,$05F                                                   ; lines color 1
    dc.w         COLOR03,$27D                                                   ; lines color 2
    dc.w         COLOR09,$49E                                                   ; lines color 3
    dc.w         COLOR11,$6CF                                                   ; lines color 4
    dc.w         COLOR05,$F5F                                                   ; x-lines color 1
    dc.w         COLOR07,$F7F                                                   ; x-lines color 2
    dc.w         COLOR13,$FBF                                                   ; x-lines color 3
    dc.w         COLOR15,$FEF                                                   ; x-lines color 4
    dc.w         COLOR04,$B09                                                   ; fill color 1
    dc.w         COLOR06,$D3A                                                   ; fill color 2
    dc.w         COLOR12,$E5D                                                   ; fill color 3
    dc.w         COLOR14,$F7D                                                   ; fill color 4
    dc.w         COLOR00,$112                                                   ; !!!
    dc.w         COLOR02,$000                                                   ; !!!
    dc.w         COLOR08,$000                                                   ; !!!
    dc.w         COLOR10,$000                                                   ; !!!

    ;dc.w         COLOR01,$A09                                                   ; lines color 1
    ;dc.w         COLOR03,$C0A                                                   ; lines color 2
    ;dc.w         COLOR09,$F0C                                                   ; lines color 3
    ;dc.w         COLOR11,$F4F                                                   ; lines color 4
    ;dc.w         COLOR05,$07F                                                   ; x-lines color 1
    ;dc.w         COLOR07,$0AF                                                   ; x-lines color 2
    ;dc.w         COLOR13,$1CF                                                   ; x-lines color 3
    ;dc.w         COLOR15,$1FF                                                   ; x-lines color 4
    ;dc.w         COLOR04,$01F                                                   ; fill color 1
    ;dc.w         COLOR06,$14E                                                   ; fill color 2
    ;dc.w         COLOR12,$06F                                                   ; fill color 3
    ;dc.w         COLOR14,$18F                                                   ; fill color 4
    ;dc.w         COLOR00,$112                                                   ; !!!
    ;dc.w         COLOR02,$000                                                   ; !!!
    ;dc.w         COLOR08,$000                                                   ; !!!
    ;dc.w         COLOR10,$000                                                   ; !!!

 
    dc.w         SPR0PTH,0
    dc.w         SPR0PTL,0
    dc.w         SPR1PTH,0
    dc.w         SPR1PTL,0
    dc.w         SPR2PTH,0
    dc.w         SPR2PTL,0
    dc.w         SPR3PTH,0
    dc.w         SPR3PTL,0
    dc.w         SPR4PTH,0
    dc.w         SPR4PTL,0
    dc.w         SPR5PTH,0
    dc.w         SPR5PTL,0
    dc.w         SPR6PTH,0
    dc.w         SPR6PTL,0
    dc.w         SPR7PTH,0
    dc.w         SPR7PTL,0
cpTunnelBack:
    dc.w         BPL2PTH,$0
    dc.w         BPL2PTL,$0    
    dc.w         BPL4PTH,$0
    dc.w         BPL4PTL,$0     

cpTunnelPlanes:
    dc.w         BPL1PTH,$0
    dc.w         BPL1PTL,$0    
cpSolidPlanes:
    dc.w         BPL3PTH,$0
    dc.w         BPL3PTL,$0    
cpTunnelCop2:
    dc.w         COP2LCH,0
    dc.w         COP2LCL,0
    dc.w         COPJMP2,0

;    dc.w           $ab01,$fffe
;    dc.w           BPL2MOD,-(TUNNEL_WIDTH_BYTE*3)

    dc.l         COPPER_HALT
    dc.l         COPPER_HALT


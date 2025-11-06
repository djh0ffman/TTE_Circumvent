

;-------------------------------------
;
; greets / particle engine
;
;-------------------------------------
GREETZ_MAX_CHARS  = 16
GREETS_DMA        = %1000001111100000
BLOCK_OBJECT_SIZE = BlockObjectEnd-BlockObject
POINT_BUFFER_MAX  = GREETZ_MAX_CHARS*BLOCK_OBJECT_SIZE

    section        greets_code,code

    include        "greets_struct.asm"



;-------------------------------------
;
; greets discrete init
;
;-------------------------------------

GreetsDiscreteInit:
    bsr            GreetsGridPreCalc

    move.l         #FLOOR_PLANE1,FloorBufferPtr1
    move.l         #FLOOR_PLANE1B,FloorBufferPtr1+4
    move.l         #FLOOR_PLANE2,FloorBufferPtr2
    move.l         #FLOOR_PLANE2B,FloorBufferPtr2+4

    lea            BlockObject,a0
    move.w         (a0)+,d7
    subq.w         #1,d7
    addq.l         #4,a0
.loop
    move.w         (a0),d0
    muls           #3,d0
    move.w         d0,(a0)+
    move.w         (a0),d0
    muls           #3,d0
    move.w         d0,(a0)+
    addq.l         #4,a0
    dbra           d7,.loop
    rts

;-------------------------------------
;
; greets runtime init
;
;-------------------------------------

GreetsInit:
    lea            Variables,a5
    lea            CUSTOM,a6

    bsr            GreetsClear

    move.l         #FORE_BUFFER_A,ForeBufferPtr(a5)
    move.l         #FORE_BUFFER_B,ForeBufferPtr+4(a5)
    move.l         #FORE_BUFFER_C,ForeBufferPtr+8(a5)

;    move.l         ForeBufferPtr(a5),a0
;    bsr            ScreenClearFull
;
;    move.l         ForeBufferPtr+4(a5),a0
;    bsr            ScreenClearFull
;
;    move.l         ForeBufferPtr+8(a5),a0
;    bsr            ScreenClearFull

    bsr            LoadGreetCopperGrad

    bsr            GreetsLoadCopper

    bsr            ParticleInit

    move.l         #GreetCharListA,GreetsCharPtrs(a5)
    move.l         #GreetCharListB,GreetsCharPtrs+4(a5)
    move.l         #PointsBufferA,GreetsPointPtrs(a5)
    move.l         #PointsBufferB,GreetsPointPtrs+4(a5)

    move.w         #1,GreetsActive(a5)

    move.l         #PointsBufferA,PointBufferPtr(a5)

    move.l         #FLOOR_PLANE1,d0
    lea            cpFloorPlanes,a1
    move.w         d0,6(a1)
    swap           d0
    move.w         d0,2(a1)
    swap           d0
    addq.l         #8,a1
    move.l         #FLOOR_PLANE2,d0
    move.w         d0,6(a1)
    swap           d0
    move.w         d0,2(a1)

    move.w         #%1000001001000000,DMACON(a6)
    bsr            DrawFloor

    move.w         #GREETS_DMA,DMACON(a6)
    move.l         #cpGreets,COP1LC(a6)

    ;move.w         #0,COPJMP1(a6)


    rts


; 13 * 4 = 52

GreetsClear:
    lea            ScreenMem,a0
    move.l         #Greets_ChipSize,d7
    add.l          d7,a0

    divu           #52,d7
    subq.w         #1,d7
    bmi            .remain
    PUSHM          a5/a6
    sub.l          a1,a1
    sub.l          a2,a2
    sub.l          a3,a3
    sub.l          a4,a4
    sub.l          a5,a5
    sub.l          a6,a6
    moveq          #0,d0
    moveq          #0,d1
    moveq          #0,d2
    moveq          #0,d3
    moveq          #0,d4
    moveq          #0,d5
    moveq          #0,d6
.loop1
    movem.l        a1-a6/d0-d6,-(a0)
    dbra           d7,.loop1
    POPM           a5/a6
.remain
    ; remainder
    clr.w          d7
    swap           d7
    subq.w         #1,d7
    bcs            .done
.loop2
    clr.b          -(a0)
    dbra           d7,.loop2
.done

    lea            ScreenMem,a1
    rts


;-------------------------------------
;
; draw floor / ceiling
;
;-------------------------------------


FLOOR_BLIT_SIZE   = (FLOOR_HEIGHT<<6)+FLOOR_WIDTH_WORD

DrawFloor:
    lea            FloorLines,a2
    move.w         (a2)+,d7
    subq.w         #1,d7
    lea            FLOOR_PLANE1,a0
    move.w         #FLOOR_WIDTH_BYTE,d4
.loop    
    movem.w        (a2)+,d0/d1/d2/d3
    bsr            BlitterLine
    dbra           d7,.loop

    ; copy floor plane to 2nd buffer with shift
    WAITBLITN
    move.w         #$19f0,BLTCON0(a6)
    move.w         #0,BLTCON1(a6)
    move.w         #0,BLTAMOD(a6)
    move.w         #0,BLTDMOD(a6)
    move.l         #-1,BLTAFWM(a6)
    move.l         #FLOOR_PLANE1,BLTAPT(a6)
    move.l         #FLOOR_PLANE2,BLTDPT(a6)
    move.w         #FLOOR_BLIT_SIZE,BLTSIZE(a6)

    ; other shift
    WAITBLITN
    move.w         #$1dfc,BLTCON0(a6)
    move.w         #$2,BLTCON1(a6)
    move.w         #0,BLTAMOD(a6)
    move.w         #0,BLTBMOD(a6)
    move.w         #0,BLTDMOD(a6)
    move.l         #-1,BLTAFWM(a6)
    move.l         #FLOOR_PLANE1+FLOOR_PLANE_SIZE-2,BLTAPT(a6)
    move.l         #FLOOR_PLANE2+FLOOR_PLANE_SIZE-2,BLTBPT(a6)
    move.l         #FLOOR_PLANE2+FLOOR_PLANE_SIZE-2,BLTDPT(a6)
    move.w         #FLOOR_BLIT_SIZE,BLTSIZE(a6)

    WAITBLITN 
    move.w         #$09f0,BLTCON0(a6)
    move.w         #0,BLTCON1(a6)
    move.w         #0,BLTAMOD(a6)
    move.w         #0,BLTDMOD(a6)
    move.l         #-1,BLTAFWM(a6)
    move.l         #FLOOR_PLANE1,BLTAPT(a6)
    move.l         #FLOOR_PLANE1B,BLTDPT(a6)
    move.w         #FLOOR_BLIT_SIZE,BLTSIZE(a6)

    WAITBLITN 
    move.w         #$09f0,BLTCON0(a6)
    move.w         #0,BLTCON1(a6)
    move.w         #0,BLTAMOD(a6)
    move.w         #0,BLTDMOD(a6)
    move.l         #-1,BLTAFWM(a6)
    move.l         #FLOOR_PLANE2,BLTAPT(a6)
    move.l         #FLOOR_PLANE2B,BLTDPT(a6)
    move.w         #FLOOR_BLIT_SIZE,BLTSIZE(a6)
    WAITBLITN 

    rts


;-------------------------------------
;
; greets background processor
;
;-------------------------------------


GREET_CENTERX     = (320/2)
GREET_CENTERY     = 256/2

GreetsBackgroundThread:
    lea            GreetText,a0

.loopmessage   
    tst.w          GreetsActive(a5)
    beq            .loopmessage

    move.l         GreetsCharPtrs(a5),a1
    move.l         GreetsPointPtrs(a5),PointBufferPtr(a5)

    ;move.l         GreetsPointer(a5),a0
    move.w         #7*4,d3                                        ; timer
    moveq          #0,d0
.next
    cmp.b          #-1,(a0)
    beq            .listdone

    ; find lenght of string
    move.l         a0,a2
    moveq          #-1,d4
.length
    addq.w         #1,d4
    tst.b          (a2)+
    bne            .length

    move.w         d4,d5
    subq.w         #1,d4
    muls           #18,d4
    lsr.w          #1,d4
    neg.w          d4                                             ; x position 

    lsr.w          #1,d5
    add.w          d5,d3
    moveq          #1,d6

.nextchar
    move.b         (a0)+,d0
    beq            .poscalcdone

    move.l         #GREET_CENTERY<<16,GreetChar_PosY(a1)

    move.l         #GREET_CENTERX<<16,d1
    move.l         d1,GreetChar_PosX(a1)
    move.w         d4,GreetChar_OffsetX(a1)
    clr.w          GreetChar_SinePos(a1)

    add.w          #18,d4

    move.w         d0,GreetChar_Char(a1)
    move.w         d3,GreetChar_Timer(a1)

    sub.w          d6,d3                                          ; add timer
    cmp.w          #7*4,d3
    bne            .noflip
    neg.w          d6
.noflip

    lea            GreetChar_Sizeof(a1),a1

    addq.w         #1,d5                                          ; next char count from center
    bra            .nextchar

    ; now loop point buffer stuff
    move.l         GreetsCharPtrs(a5),a1

.poscalcdone
    clr.w          GreetChar_Char(a1)

    move.l         GreetsCharPtrs(a5),a1
.pointloop
    move.l         PointBufferPtr(a5),GreetChar_PointPtr(a1)
    move.w         GreetChar_Char(a1),d0
    beq            .messagedone
    movem.l        a0/a1,-(sp)
    bsr            Convert16
    movem.l        (sp)+,a0/a1
    lea            GreetChar_Sizeof(a1),a1
    bra            .pointloop


.messagedone
    clr.w          GreetsActive(a5)

    ; swap buffers
    move.l         GreetsCharPtrs(a5),d0
    move.l         GreetsCharPtrs+4(a5),GreetsCharPtrs(a5)
    move.l         d0,GreetsCharPtrs+4(a5)

    move.l         GreetsPointPtrs(a5),d0
    move.l         GreetsPointPtrs+4(a5),GreetsPointPtrs(a5)
    move.l         d0,GreetsPointPtrs+4(a5)

    bra            .loopmessage

.listdone
    rts




;-------------------------------------
;
; greets copper grad
;
;-------------------------------------

LoadGreetCopperGrad:
    lea            GREET_COPPER_GRAD,a0

    move.l         a0,d0
    move.w         d0,cpGreetGradJump+6
    swap           d0
    move.w         d0,cpGreetGradJump+2

    lea            GreetCol1,a1
    lea            GreetCol2,a2
    lea            GreetCol3,a3

    move.l         #$2b01fffe,d0
    move.w         #COLOR09,d1
    move.w         #COLOR10,d2
    move.w         #COLOR11,d3
    move.w         #64-1,d7
.looptop
    move.l         d0,(a0)+
    move.w         d1,(a0)+
    move.w         (a1)+,(a0)+
    move.w         d2,(a0)+
    move.w         (a2)+,(a0)+
    move.w         d3,(a0)+
    move.w         (a3)+,(a0)+
    add.l          #$02000000,d0
    dbra           d7,.looptop

    ; mod
    move.w         #BPL2MOD,(a0)+
    move.w         #-(FLOOR_WIDTH_BYTE*2),(a0)+

    move.w         #64-1,d7
.loopbot
    move.l         d0,(a0)+
    move.w         d1,(a0)+
    move.w         -(a1),(a0)+
    move.w         d2,(a0)+
    move.w         -(a2),(a0)+
    move.w         d3,(a0)+
    move.w         -(a3),(a0)+
    add.l          #$02000000,d0
    dbra           d7,.loopbot

    move.l         #-2,(a0)+
    move.l         #-2,(a0)+

    rts



;-------------------------------------
;
; greets frame tick
;
;-------------------------------------

GreetsTick:
    RANDOMWORD
    move.w         d0,RandomFrame(a5)

    bsr            GreetsBeatSync

    bsr            GreetsGrid
    ;move.w         #$600,$dff180

    move.l         GreetsCharPtrs(a5),a0
    bsr            ProcessGreets
    move.l         GreetsCharPtrs+4(a5),a0
    bsr            ProcessGreets

.noadd
    bsr            ParticleProcessDraw
    bsr            ScreenClearCurrent
    bsr            GreetsLoadCopper
    ;move.w         #$040,$dff180
    rts

GreetsBeatSync:
    move.w         TickCounter(a5),d0
    divu           #7*8,d0
    swap           d0
    tst.w          d0
    bne            .notbeat
    move.w         #1,GreetsActive(a5)
.notbeat
    rts

;-------------------------------------
;
; greets grid
;
;-------------------------------------

GRID_COUNT        = 10
GRID_SPACING      = 130
GRID_STEPS        = 7*4
GRID_DELTA        = (GRID_SPACING<<16)/GRID_STEPS

GreetsGridPreCalc:
    lea            GridList,a0
    move.w         #GRID_STEPS-1,d6
    move.l         #301<<16,d4
.frame
    move.l         d4,d2
    swap           d2
    moveq          #GRID_COUNT-1,d7
.loop
    bsr            GridZCalc
    move.w         d0,(a0)+
    add.w          #GRID_SPACING,d2    
    dbra           d7,.loop

    add.l          #GRID_DELTA,d4
    dbra           d6,.frame
    rts

GreetsGrid:
    bsr            GreetsGridRestore
    move.w         GridListInc,d0
    add.w          d0,GridListPos
    cmp.w          #GRID_STEPS,GridListPos
    bcs            .noloop
    sub.w          #GRID_STEPS,GridListPos
    ;clr.w          GridListPos
.noloop
    bsr            GreetsGridDraw
    rts


GreetsGridRestore:
    moveq          #GRID_COUNT-1,d7
    moveq          #-1,d5
    lea            GridList,a0
    move.w         GridListPos,d0
    add.w          d0,d0
    mulu           #GRID_COUNT,d0
    lea            (a0,d0.w),a0
.drawloop
    moveq          #0,d0
    move.w         (a0)+,d0
    subq.w         #1,d0
    mulu           #FLOOR_WIDTH_BYTE,d0
    move.l         FloorBufferPtr1+4,a1
    move.l         FloorBufferPtr1,a2
    move.l         FloorBufferPtr2+4,a3
    move.l         FloorBufferPtr2,a4
    add.l          d0,a1
    add.l          d0,a2
    add.l          d0,a3
    add.l          d0,a4
    REPT           30
    move.l         (a1)+,(a2)+
    move.l         (a3)+,(a4)+
    ENDR
    dbra           d7,.drawloop
    rts

GreetsGridDraw:
    moveq          #GRID_COUNT-1,d7
    moveq          #-1,d5
    lea            GridList,a0
    move.w         GridListPos,d0
    add.w          d0,d0
    mulu           #GRID_COUNT,d0
    lea            (a0,d0.w),a0
.drawloop
    move.l         FloorBufferPtr1,a1
    move.l         FloorBufferPtr2,a2

    move.w         (a0)+,d0
    mulu           #FLOOR_WIDTH_BYTE,d0
    lea            (a1,d0.w),a3
    lea            (a2,d0.w),a4
    REPT           10
    move.l         d5,(a3)+
    clr.l          (a4)+
    ENDR

    lea            -FLOOR_WIDTH_BYTE*2(a3),a1
    lea            -FLOOR_WIDTH_BYTE*2(a4),a2

    REPT           10
    move.l         (a1)+,d4
    move.l         d5,(a2)
    eor.l          d4,(a2)+

    move.l         (a3)+,d4
    move.l         d5,(a4)
    eor.l          d4,(a4)+
    ENDR

    dbra           d7,.drawloop
    rts


FloorBufferPtr1:   
    dcb.l          2
FloorBufferPtr2:   
    dcb.l          2

GridListPos:
    dc.w           0
GridListInc:
    dc.w           1

; in d2 z
; out d0 y
GridZCalc:
    move.w         #127,d1
    move.w         d2,d3
    muls           #300,d1
    divs           d3,d1
    move.w         #127,d0
    sub.w          d1,d0
    rts


;-------------------------------------
;
; greets load copper
;
;-------------------------------------

GreetsLoadCopper:
    move.l         ForeBufferPtr(a5),d0                           ; current screen    
    lea            cpGreetsPlanes,a3

    REPT           DISPLAY_DEPTH    
    move.w         d0,6(a3)
    swap           d0
    move.w         d0,2(a3)
    swap           d0
    add.l          #FORE_WIDTH_BYTE,d0
    addq.l         #8,a3
    ENDR

    lea            ForeBufferPtr(a5),a0
    lea            ForeBufferPtr(a5),a0
    ROTATE_LONG    a0,3
    rts

FORE_CLEAR_START  = ((FORE_HEIGHT/4)-16)*FORE_STRIDE

ScreenClearCurrent:
    move.l         ForeBufferPtr+8(a5),a0

ScreenClear:
    WAITBLITN
    add.l          #FORE_CLEAR_START,a0
    move.w         #$0100,BLTCON0(a6)
    move.w         #0,BLTCON1(a6)
    move.w         #FORE_BLIT_MOD,BLTDMOD(a6)                     ; FORE_MODULO
    move.l         a0,BLTDPT(a6)
    move.w         #FORE_HALF_BLIT_SIZE,BLTSIZE(a6)
    rts


ScreenClearFull:
    WAITBLITN
    move.w         #$0100,BLTCON0(a6)
    move.w         #0,BLTCON1(a6)
    move.w         #FORE_BLIT_MOD,BLTDMOD(a6)                     ; FORE_MODULO
    move.l         a0,BLTDPT(a6)
    move.w         #FORE_BLIT_SIZE,BLTSIZE(a6)
    rts

;----------------------------------------------------------------------------
;
; ProcessGreets array
;
;----------------------------------------------------------------------------

ProcessGreets:
    ;lea            GreetCharList,a0
    lea            sinus,a4
    move.w         #GREETZ_MAX_CHARS-1,d7
.loop
    tst.w          GreetChar_Timer(a0)
    beq            .next

    move.w         GreetChar_Char(a0),d0
    cmp.b          #" ",d0
    beq            .next

    move.w         GreetChar_SinePos(a0),d1
    add.w          d1,d1
    move.w         (a4,d1.w),d1
    muls           GreetChar_OffsetX(a0),d1
    divs           #sine_degrees,d1
    add.w          GreetChar_PosX(a0),d1
    move.w         d1,GreetChar_PosXActual(a0)

    move.w         GreetChar_Char(a0),d0
    move.w         GreetChar_PosY(a0),d2
    sub.w          #8,d1
    sub.w          #8,d2
    bsr            Print16

    cmp.w          #sine_degrees/4,GreetChar_SinePos(a0)
    bcc            .noadd
    add.w          #sine_degrees/7*2/20,GreetChar_SinePos(a0)
.noadd
    subq.w         #1,GreetChar_Timer(a0)
    bne            .next

    move.w         GreetChar_PosXActual(a0),d0
    move.w         GreetChar_PosY(a0),d1 
    move.l         GreetChar_PointPtr(a0),a1

    bsr            ParticleAddObject
.next
    lea            GreetChar_Sizeof(a0),a0
    dbra           d7,.loop    

    rts

;----------------------------------------------------------------------------
;
; print 16
;
; d0 = letter (ascii)
; d1 = x 
; d2 = y
;
;----------------------------------------------------------------------------

FONT16_CHARS      = 64
FONT16_WIDTH_BYTE = FONT16_CHARS*2
FONT16_BLITSIZE   = (16<<6)+2
;FONT16_MODSOURCE  = FONT16_WIDTH_BYTE-4
FONT16_MODSOURCE  = -2

FONT16_MODDEST    = FORE_STRIDE-4



Print16:
    PUSHMOST
    lea            Font16,a0
    sub.b          #$20,d0
    ;lsl.w          #1,d0
    mulu           #$20,d0
    lea            (a0,d0.w),a0                                   ; font pointer

    move.w         d1,d3
    and.w          #$f,d3                                         ; 16 pixel offset
    add.w          d3,d3 
    add.w          d3,d3                                          ; bltcon lookup

    lsr.w          #3,d1                                          ; x in bytes
    add.w          d2,d2
    lea            ParticleYLookUp(a5),a2
    move.w         (a2,d2.w),d2                                   ; screen offest Y
    add.w          d1,d2

    move.l         ForeBufferPtr(a5),a1
    lea            (a1,d2.w),a1                                   ; screen position
    
    WAITBLITN
    move.l         .bltcon(pc,d3.w),BLTCON0(a6)                   ; use channels A & D
    move.l         #$ffff0000,BLTAFWM(a6)                         ; last word mask 
    
    move.w         #FONT16_MODSOURCE,BLTAMOD(a6)                  ; source mod
    move.w         #FONT16_MODSOURCE,BLTBMOD(a6)                  ; source mod
    move.w         #FONT16_MODDEST,BLTCMOD(a6)                    ; screen dest mod
    move.w         #FONT16_MODDEST,BLTDMOD(a6)                    ; scratch destination

    move.l         a0,BLTAPT(a6)                                  ; mask
    move.l         a0,BLTBPT(a6)                                  ; item
    move.l         a1,BLTCPT(a6)                                  ; screen
    move.l         a1,BLTDPT(a6)                                  ; screen
    move.w         #FONT16_BLITSIZE,BLTSIZE(a6)                   ; BLIT!

    POPMOST
    rts

.bltcon
    dc.l           $0fca0000
    dc.l           $1fca1000
    dc.l           $2fca2000
    dc.l           $3fca3000
    dc.l           $4fca4000
    dc.l           $5fca5000
    dc.l           $6fca6000
    dc.l           $7fca7000
    dc.l           $8fca8000
    dc.l           $9fca9000
    dc.l           $afcaa000
    dc.l           $bfcab000
    dc.l           $cfcac000
    dc.l           $dfcad000
    dc.l           $efcae000
    dc.l           $ffcaf000
;----------------------------------------------------------------------------
;
; convert 16 - converts a 16x16 font letter to particle points
;
; d0 = letter (ascii)
;
;----------------------------------------------------------------------------

Convert16:
    sub.b          #$20,d0
    ;add.w          d0,d0
    mulu           #$20,d0
    lea            Font16,a4
    lea            (a4,d0.w),a4                                   ; font pointer

    move.l         PointBufferPtr(a5),a0
    lea            2(a0),a1

    moveq          #0,d5                                          ; point count

    lea            BlockObject+2,a2
    moveq          #16-1,d7
.lineloop
    move.l         a2,a3
    move.w         (a4)+,d0
    beq            .nextline

    moveq          #16-1,d6
.pixelloop
    ; line has pixels
    lsl.w          #1,d0
    bcs            .haspixel
    beq            .nextline
    addq.l         #8,a3
    dbra           d6,.pixelloop
    bra            .nextline
    
.haspixel
    addq.w         #1,d5
    move.l         (a3)+,(a1)+
    move.l         (a3)+,(a1)+
    dbra           d6,.pixelloop

.nextpixel
    dbra           d6,.pixelloop

.nextline
    ;lea            FONT16_WIDTH_BYTE(a4),a4
    lea            128(a2),a2
    dbra           d7,.lineloop

    move.w         d5,(a0)                                        ; store count

    move.l         a1,PointBufferPtr(a5)
    rts


    include        "particles.asm"
    include        "linedraw.asm"




GreetCol1:
    dc.w           $fff,$eee,$fff,$eee,$fff,$eee,$fff,$eee
    dc.w           $fff,$ddd,$fff,$ddd,$fff,$ddd,$fff,$ddd
    dc.w           $eee,$ccc,$eee,$ccc,$eee,$ccc,$eee,$ccc
    dc.w           $ddd,$bbb,$ddd,$bbb,$ddd,$bbb,$ddd,$bbb
    dc.w           $ccc,$aaa,$ccc,$aaa,$ccc,$aaa,$ccc,$aaa
    dc.w           $bbb,$999,$bbb,$999,$bbb,$999,$bbb,$999
    dc.w           $aaa,$888,$aaa,$888,$aaa,$888,$aaa,$888
    dc.w           $999,$777,$999,$777,$999,$777,$999,$777
GreetCol2:
    dc.w           $33f,$33f,$33f,$33f,$33f,$33f,$33f,$22e
    dc.w           $33f,$22d,$33e,$22d,$33e,$22d,$22e,$22d
    dc.w           $22e,$22c,$22e,$22c,$22e,$22c,$22e,$22c
    dc.w           $22d,$22b,$22d,$22b,$22d,$22b,$22d,$22b
    dc.w           $22c,$22a,$22c,$22a,$22c,$22a,$22c,$22a
    dc.w           $22b,$22a,$22b,$22a,$22b,$22a,$22b,$229
    dc.w           $22a,$118,$119,$118,$119,$118,$119,$118
    dc.w           $119,$117,$119,$117,$119,$117,$119,$117
GreetCol3:
    dc.w           $77f,$77f,$77f,$77f,$77f,$77f,$77f,$77e
    dc.w           $77f,$66d,$66e,$66d,$66e,$66d,$66e,$66d
    dc.w           $66e,$66d,$66e,$66d,$66e,$66d,$66e,$55c
    dc.w           $66d,$55b,$66c,$55b,$66c,$55b,$55c,$55b
    dc.w           $55c,$55b,$55c,$55b,$55c,$55a,$55c,$55a
    dc.w           $55b,$55a,$55b,$449,$44a,$449,$44a,$449
    dc.w           $44a,$449,$44a,$449,$44a,$448,$449,$448
    dc.w           $449,$337,$449,$337,$448,$337,$448,$337

;-------------------------------------
;
; greets fast ram
;
;-------------------------------------

    section        greets_bss_fast,bss
GridList:
    ds.w           GRID_COUNT*GRID_STEPS
ParticleSpeeds:       
    ds.w           (PARTICLES_MAX_GUARD)*2                        ; x / y speeds of particles
ParticleLife:    
    ds.w           PARTICLES_MAX_GUARD                            ; life of each particle
ParticlesDead:
    ds.w           PARTICLES_MAX_GUARD                            ; dead list of particles
    
SparticleSpeeds:       
    ds.w           (PARTICLES_MAX_GUARD)*2                        ; x / y speeds of particles
SparticleLife:    
    ds.w           PARTICLES_MAX_GUARD                            ; life of each particle

CharPointList:
    ds.l           FONT16_CHARS

; TODO: work out how big this needs to be?!
PointsBufferA:
    ds.b           POINT_BUFFER_MAX
PointsBufferB:
    ds.b           POINT_BUFFER_MAX

GreetCharListA:
    ds.b           GREETZ_MAX_CHARS*GreetChar_Sizeof
GreetCharListB:
    ds.b           GREETZ_MAX_CHARS*GreetChar_Sizeof

;-------------------------------------
;
; greets chip data
;
;-------------------------------------

    section        greets_data_chip,data_c
blitter_temp_output_word:
    dc.w           0

cpGreets:
    dc.w           DIWSTRT,$2c81                                  ; window start stop
    dc.w           DIWSTOP,$2cc1                                  ; 192 + 8

    ;dc.w           DIWSTRT,$2c81                                ; window start stop
    ;dc.w           DIWSTOP,$f4c1                                ; 192 + 8

    dc.w           DDFSTRT,$38                                    ; datafetch start stop 
    dc.w           DDFSTOP,$d0

    dc.w           BPLCON0,$4600                                  ; set as 4 bp display dual pf
    dc.w           BPLCON1,0                                      ; set scroll 0
    dc.w           BPLCON2,0    
    dc.w           BPL1MOD,FORE_MODULO
    dc.w           BPL2MOD,FLOOR_MODULO

cpGreetsPlanes:
    dc.w           BPL1PTH,0
    dc.w           BPL1PTL,0
    dc.w           BPL3PTH,0
    dc.w           BPL3PTL,0
cpFloorPlanes:
    dc.w           BPL2PTH,0
    dc.w           BPL2PTL,0
    dc.w           BPL4PTH,0
    dc.w           BPL4PTL,0


    dc.w           SPR0PTH,0
    dc.w           SPR0PTL,0
    dc.w           SPR1PTH,0
    dc.w           SPR1PTL,0
    dc.w           SPR2PTH,0
    dc.w           SPR2PTL,0
    dc.w           SPR3PTH,0
    dc.w           SPR3PTL,0
    dc.w           SPR4PTH,0
    dc.w           SPR4PTL,0
    dc.w           SPR5PTH,0
    dc.w           SPR5PTL,0
    dc.w           SPR6PTH,0
    dc.w           SPR6PTL,0
    dc.w           SPR7PTH,0
    dc.w           SPR7PTL,0

    dc.w           COLOR00,$000
    dc.w           COLOR01,$fff
    dc.w           COLOR02,$00f
    dc.w           COLOR03,$f00

    dc.w           COLOR08,$000
    dc.w           COLOR09,$fff
    dc.w           COLOR10,$33f
    dc.w           COLOR11,$77f

cpGreetGradJump:
    dc.w           COP2LCH,0
    dc.w           COP2LCL,0
    dc.w           COPJMP2,0

;cpCopperGrad:
;    dcb.b          GreetCopper_Sizeof*64

;    dc.w           $ab01,$fffe
;    dc.w           BPL2MOD,-(FLOOR_WIDTH_BYTE*2) 

;    dc.l           -2
;    dc.l           -2

Font16:
    incbin         "ttefont.raw"

;-------------------------------------
;
; greets data fast
;
;-------------------------------------

    section        greets_data_fast,data
BlockObject:
    incbin         "CHAR_BLOCK.pnt"
BlockObjectEnd:

    include        "lines.asm"

GSHIFT_Y          = 30
CENTER_X          = 320/2
GTOP_Y            = 128-GSHIFT_Y
GBOT_Y            = 128+GSHIFT_Y

GreetText:
    dc.b           "GREETS TO..",0
    dc.b           "SPREADPOINT",0
    dc.b           "SCOOPEX",0
    dc.b           "LOGICOMA",0
    dc.b           "LOONIES",0
    dc.b           "DESIRE",0
    dc.b           "INSANE",0
    dc.b           "UP ROUGH",0
    dc.b           "RIFT",0
    dc.b           "THE BLACK LOTUS",0
    dc.b           "LEMON.",0
    dc.b           "FOCUS DESIGN",0
    dc.b           "DEFEKT",0
    dc.b           "FIELD FX",0
    dc.b           "BITSHIFTERS",0
    dc.b           -1
    even

;    dc.w           140,180,18,0
;    dc.b           "Group Name",0
;    even

    dc.l           -1
    even



;-------------------------------------
;
; greets chip ram
;
;-------------------------------------


    section        greets_bss_chip,bss_c

    ;rept       PARTICLES_OCS
    ;bset       d0,$1(a0)
    ;endr
;PARTICLE_SMC:
;    ds.l           PARTICLES_OCS
;PARTICLE_SMC_rts:
;    ds.w           1
;
;ParticlePositions:    
;    ds.w           (PARTICLES_MAX_GUARD)*2               ; x / y positions of particles
;SparticlePositions:    
;    ds.w           (PARTICLES_MAX_GUARD)*2               ; x / y positions of particles
;SparticleFlicker: 
;    ds.w           PARTICLES_MAX_GUARD+32


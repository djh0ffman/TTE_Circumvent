

    include       "actionreplay_struct.asm"
    section       actionreplay_code,code

AR_DMA = %1000001110100000

ActionReplayInit:
    move.l        #$BABEFEED,RandomSeed(a5)
    lea           ScreenMem,a0
    move.w        #(AR_SIZE/4)-1,d7
.clear
    clr.l         (a0)+
    dbra          d7,.clear    

    lea           cpARPlanes,a0
    move.l        #ScreenMem,d0
    move.w        d0,6(a0)
    swap          d0
    move.w        d0,2(a0)

    lea           cpARSrpite,a0
    move.l        #ARSprite,d0
    move.w        d0,6(a0)
    swap          d0
    move.w        d0,2(a0)


    move.l        #cpAR,COP1LC(a6)
    move.w        #0,COPJMP1(a6)
    move.w        #AR_DMA,DMACON(a6)

    lea           ARText,a0
    bsr           ActionReplayPrintAll

    clr.w         ARStatus
    move.w        #50,ARWait
    rts

ARStatus:
    dc.w          0
ARWait:
    dc.w          0

AR_X: 
    dc.w          0
AR_Y: 
    dc.w          0
ARTextPtr:
    dc.l          0
; a0 = text


;----------------------------------------------------------------------------
;
; sprite coord
;
; d1 = x
; d2 = y
; a0 = sprite strucutre
;
; d5 = $80 attach bit
;
;----------------------------------------------------------------------------


ActionReplaySpriteSet:
    ;move.w        AR_X,d0
    ;move.w        AR_Y,d1
    ;add.w         #100,d0
    ;add.w         #$2c,d1
    ;lsr.w         #1,d0
    ;move.w        d1,d2


;SpriteCoord:
    lea           ARSprite,a0
    move.w        AR_X,d1
    mulu          #4,d1
    move.w        AR_Y,d2
    mulu          #8,d2
    addq.w        #7,d2

    move.w        TickCounter(a5),d5
    divu          #50,d5
    swap          d5
    cmp.w         #25,d5
    bcs           .on
    move.w        #-20,d2
   
.on
    moveq         #0,d5

    add.w         #$80,d1
    moveq         #$2c,d4
    add.w         d4,d2

    move.l        d1,d4
    swap          d4
    lsr.l         #1,d4
    rol.w         #1,d4                                                                                   ; H START

    move.l        d2,d3
    lsl.l         #8,d3
    swap          d3
    lsl.w         #2,d3
    or.l          d3,d4                                                                                   ; V START ( lower bits )

    move.l        d2,d3
    ;add.w         #18,d3                                                     ; Height
    ;add.w         d5,d3                                                                                   ; height
    add.w         #1,d3
    rol.w         #8,d3
    lsl.b         #1,d3
    or.l          d3,d4                                                                                   ; V STOP ( lower bits )

    swap          d5
    or.b          d5,d4                                                                                   ; attach bit
    
    move.l        d4,(a0)

    rts

ActionReplayPrintAll:
    cmp.b         #-1,(a0)
    beq           .exit
    bsr           ActionReplayPrintLine
    bsr           ActionReplayNextLine
    bra           ActionReplayPrintAll
.exit
    rts

ActionReplayPrintLine:
    lea           FontTopaz,a1
    moveq         #0,d0
    move.w        AR_X,d0
    move.w        AR_Y,d1
    mulu          #AR_WIDTH_BYTE*8,d1
    add.w         d1,d0
    lea           ScreenMem,a3
    add.l         d0,a3                                                                                   ; screen pos
    ;addq.w     #1,AR_Y
.charloop
    moveq         #0,d0
    move.b        (a0)+,d0
    beq           .done
    sub.w         #$20,d0
    lsl.w         #3,d0
    lea           (a1,d0.w),a4
    move.b        (a4)+,AR_WIDTH_BYTE*0(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*1(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*2(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*3(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*4(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*5(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*6(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*7(a3)
    addq.l        #1,a3
    addq.w        #1,AR_X
    bra           .charloop
.done
    rts


ActionReplayNextLine:
    addq.w        #1,AR_Y    
    clr.w         AR_X
    rts

ActionReplayPrintOne:
    lea           FontTopaz,a1
    moveq         #0,d0
    move.w        AR_X,d0
    move.w        AR_Y,d1
    mulu          #AR_WIDTH_BYTE*8,d1
    add.w         d1,d0
    lea           ScreenMem,a3
    add.l         d0,a3                                                                                   ; screen pos
    ;addq.w     #1,AR_Y
.charloop
    moveq         #0,d0
    move.b        (a0)+,d0
    beq           .done
    sub.w         #$20,d0
    lsl.w         #3,d0
    lea           (a1,d0.w),a4
    move.b        (a4)+,AR_WIDTH_BYTE*0(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*1(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*2(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*3(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*4(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*5(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*6(a3)
    move.b        (a4)+,AR_WIDTH_BYTE*7(a3)
.done
    rts

ActionReplayTick:
    bsr           ActionReplaySpriteSet
    move.w        ARStatus,d0
    JMPINDEX      d0
.i
    dc.w          ActionReplayWait-.i
    dc.w          ActionReplayShow-.i
    dc.w          ActionReplayWait-.i
    dc.w          ActionReplaySetupType1-.i
    dc.w          ActionReplayTyper-.i
    dc.w          ActionReplayPrintReading-.i
    dc.w          ActionReplaySeekZero-.i
    dc.w          ActionReplayWait-.i
    dc.w          ActionReplaySetupType2-.i
    dc.w          ActionReplayTyper-.i
    dc.w          ActionReplaySetupLines-.i
    dc.w          ActionReplayLiner-.i
    dc.w          ActionReplayBigWait-.i
    dc.w          ActionReplayWait-.i
    dc.w          ActionReplaySetupType3-.i
    dc.w          ActionReplayTyper-.i
    dc.w          ActionReplayBigWait-.i
    dc.w          ActionReplayWait-.i
    dc.w          ActionReplayReset-.i
    dc.w          ActionReplayNull-.i
    rts

ActionReplayBigWait:
    move.w        #50*2,ARWait
    addq.w        #1,ARStatus
    rts

ActionReplayReset:
    move.l        4.w,a6
    cmp.w         #36,(20,a6)   ; lib_Version
	blo.b	      .classic
	jmp           (_LVOColdReboot,a6)
    cnop          2,4
.classic:
    jsr           (_LVOSuperState,a6)
	lea           $01000002,a0
	sub.l         (-22,a0),a0
	reset
	jmp            (a0)
;    jmp           $fc0000

ActionReplayShow:
    lea           cpARPal,a0
    move.w        #$05a,2(a0)
    move.w        #$fff,6(a0)
    move.w        #$fff,10(a0)
    move.w        #25,ARWait
    addq.w        #1,ARStatus
    rts


ActionReplayNull:
    rts

ActionReplayWait:
    subq.w        #1,ARWait
    bne           .exit
    RANDOMWORD 
    and.w         #15,d0
    move.w        d0,ARWait
    addq.w        #1,ARStatus
.exit
    rts

ActionReplaySetupType1:
    move.l        #ARRead,ARTextPtr
    addq.w        #1,ARStatus
    rts

ActionReplaySetupType2:
    move.l        #ARNRead,ARTextPtr
    addq.w        #1,ARStatus
    rts

ActionReplaySetupType3:
    move.l        #ARReset,ARTextPtr
    addq.w        #1,ARStatus
    rts

ActionReplaySetupLines:
    move.l        #ARBoot,ARTextPtr
    addq.w        #1,ARStatus
    bsr           ActionReplayNextLine
    rts

ActionReplayTyper:
    move.l        ARTextPtr,a0
    tst.b         (a0)
    beq           .done
    
    tst.w         ARWait
    beq           .go
    subq.w        #1,ARWait
    rts
.go
    bsr           ActionReplayPrintOne
    addq.l        #1,ARTextPtr
    addq.w        #1,AR_X
    RANDOMWORD 
    and.w         #15,d0
    move.w        d0,ARWait
    rts
.done
    addq.w        #1,ARStatus
    rts

ActionReplayLiner:
    move.l        ARTextPtr,a0
    cmp.b         #-1,(a0)
    beq           .done
    
    tst.w         ARWait
    beq           .go
    subq.w        #1,ARWait
    rts
.go
    bsr           ActionReplayPrintLine
    move.l        a0,ARTextPtr
    bsr           ActionReplayNextLine
    move.w        #2,d0
    move.w        d0,ARWait
    rts
.done
    addq.w        #1,ARStatus
    rts


ActionReplayPrintReading:
    clr.w         AR_X
    bsr           ActionReplayNextLine
    lea           ARReading,a0
    bsr           ActionReplayPrintLine
    addq.w        #1,ARStatus
    rts

ActionReplaySeekZero:
    ; TODO: seek disk drive
    bsr           TrackSeeker
    bsr           ActionReplayNextLine
    lea           ARDiskOK,a0
    bsr           ActionReplayPrintLine
    move.w        #50*2,ARWait
    addq.w        #1,ARStatus
    bsr           ActionReplayNextLine
    rts



    include       "trackseek.asm"

    section       actionreplay_data_fast,data
ARText:
    dc.b          0,0
    dc.b          "********************************************************************************",0
    dc.b          "                      ACTION REPLAY AMIGA MK III",0
    dc.b          "              (c) 1990/1991 by Olaf Boehm & J",214,"rg Zanger",0
    dc.b          "                    (p) by Datel Electronics Ltd",0
    dc.b          "********************************************************************************",0
    dc.b          "No known virus in memory!",0
    dc.b          "Ready.",0
    dc.b          -1
    even

ARRead:
    dc.b          "rt 0 1 30000",0

ARReading:
    dc.b          "Reading track !00 head 0",0

ARDiskOK:
    dc.b          "Disk ok",0

ARReset:
    dc.b          "reset",0
ARNRead:
    dc.b          "n 30000",0
    
ARBoot:
    dc.b          ".30000 DOS........pa...a..X,x..3|....#|.....(#|.....,#|.....$N..8 <LOAD",0
    dc.b          ".30040 a...,x.. <....r.N..:J.g.$.......p.`Xp.H@r.N..:J.g.$.......`@p.H@",0
    dc.b          ".30060 r.N..:J.g.$.p.H@r.N..:J.f.p.`.p.H@r.N..:J.g.............$.p..Br.",0
    dc.b          ".300C0 ,x.....2..g.r.&<BOOTN.....~.3.....Q...`.A.....~?..g.X.Q...`.p.r.",0
    dc.b          ".30100 0.2.........,x..3|....Hy....#_.(#@.,#A.$p.r.N..8Nu.*..g...X...B.",0
    dc.b          ".30140 S.f.Nu&JP...X...g... .g...P.(K....S.f.`.NuH...a J.g.2|.. @><....",0
    dc.b          ".30160 Q...p.N{..L...Nu/.p.,x.......)g.K...N...*_NuNz..NsH...3.@.....,x",0
    dc.b          ".301C0 ..K...N...3.......L...Nup.K..$C...E..,&Q(R..$..xNqN{..N{....$.Ns",0
    dc.b          ".30200 X...Ns  Cecconoid v1.0 - (C) Thalamus Digital 2024 .............",0
    dc.b          ".30240 ................................................................",0
    dc.b          ".30260 ................................................................",0
    dc.b          ".302C0 ................................................................",0
    dc.b          ".30300 ................................................................",0
    dc.b          ".30340 ................................................................",0
    dc.b          ".30360 ................................................................",0
    dc.b          ".303C0 ......................................cracked by TTE!...........",0
    dc.b          -1


    section       actionreplay_data_chip,data_c

ARSprite:
    dc.w          $0,$0
    dc.w          $f000,0000
    dc.w          $0,0

cpAR:
    dc.w          DIWSTRT,$2c81                                                                           ; window start stop
    dc.w          DIWSTOP,$2cc1                                                                           ; 192 + 8

    dc.w          DDFSTRT,$3c                                                                             ; datafetch start stop 
    dc.w          DDFSTOP,$d4

    dc.w          BPLCON0,$9200                                                                           ; set as 1 bp display
    dc.w          BPLCON1,$0040                                                                           ; set scroll 0
    dc.w          BPLCON2,$0000    
    dc.w          BPL1MOD,0
    dc.w          BPL2MOD,0
cpARPal
    dc.w          COLOR00,$05a
    dc.w          COLOR01,$05a
    dc.w          COLOR17,$05a
cpARSrpite:
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
cpARPlanes:
    dc.w          BPL1PTH,$0
    dc.w          BPL1PTL,$0    

    dc.l          COPPER_HALT
    dc.l          COPPER_HALT

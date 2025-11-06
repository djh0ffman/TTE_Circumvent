
    section    main,data_c


    IF         INCLUDE_SAMPLES=1
LSBank:
    incbin     "tunedata\tune.lsbank"
    even
    ENDIF


precalc_copper:
    dc.w       $100,$2200                ; set as 1 bp display
    dc.w       $102,$0000                ; set scroll 0
    dc.w       $108,-40
    dc.w       $10a,-40
    dc.w       $92,$38                   ; datafetch start stop
    dc.w       $94,$d0
    dc.w       $8e,$9081                 ; window start stop
    dc.w       $90,$a9c1
    dc.w       $180,$000
precalc_col: 
    dc.w       $182,$fff
    dc.w       $184,$666
precalc_col2: 
    dc.w       $186,$fff

    dc.w       $100,$9200                ; set as 1 bp display hi res
progress_message_copper:
    dc.w       $e0,$0
    dc.w       $e2,$0
    dc.w       $108,0
    dc.w       $10a,0

    dc.w       $9901,$fffe
    dc.w       $100,$2200                ; set as 2 bp display
    dc.w       $108,-40
    dc.w       $10a,-40

progress_copper:	
    dc.w       $e0,$0
    dc.w       $e2,$0
    dc.w       $e4,$0
    dc.w       $e6,$0

    dc.w       $ffff,$fffe
    dc.w       $ffff,$fffe

DeadCopper:
    dc.w       BPLCON0,0
    dc.w       COLOR00,0
    dc.l       -2
    dc.l       -2



CopperAudio:
    dc.w       $0701,$fffe
AudioDMA:
    dc.w       DMACON,$8000
    dc.w       COP1LCH,0
    dc.w       COP1LCL,0
    dc.w       COPJMP1,0


BKG_COLOR = $113

cpBanner:
    dc.w       DIWSTRT,$2c81             ; window start stop
    dc.w       DIWSTOP,$2cc1             ; 192 + 8

    dc.w       DDFSTRT,$3c               ; datafetch start stop 
    dc.w       DDFSTOP,$d4

    dc.w       BPLCON0,$a200             ; set as 1 bp display
    dc.w       BPLCON1,$0040             ; set scroll 0
    dc.w       BPLCON2,$0000    
    dc.w       BPL1MOD,0
    dc.w       BPL2MOD,0

    dc.w       COLOR00,$000
    dc.w       COLOR01,$ccc
    dc.w       COLOR02,$000
    dc.w       COLOR03,$ccc

    dc.w       SPR0PTH,0
    dc.w       SPR0PTL,0
    dc.w       SPR1PTH,0
    dc.w       SPR1PTL,0
    dc.w       SPR2PTH,0
    dc.w       SPR2PTL,0
    dc.w       SPR3PTH,0
    dc.w       SPR3PTL,0
    dc.w       SPR4PTH,0
    dc.w       SPR4PTL,0
    dc.w       SPR5PTH,0
    dc.w       SPR5PTL,0
    dc.w       SPR6PTH,0
    dc.w       SPR6PTL,0
    dc.w       SPR7PTH,0
    dc.w       SPR7PTL,0
cpBannerPlanes:
    dc.w       BPL1PTH,$0
    dc.w       BPL1PTL,$0    
    dc.w       BPL2PTH,$0
    dc.w       BPL2PTL,$0    

    ; top lines
    dc.w       $2807,$fffe
cpKickColor:
    dc.w       COLOR00,$a22
    dc.w       $2907,$fffe
    dc.w       COLOR00,$000
    dc.w       $2a07,$fffe
    dc.w       COLOR00,BKG_COLOR

cpSelect:
    ; select lines
    dc.w       $50ff,$fffe
    dc.w       COLOR00,BKG_COLOR
    dc.w       $58ff,$fffe
    dc.w       COLOR00,BKG_COLOR

    ; end lines
    dc.w       $ffdf,$fffe

    dc.w       $2d07,$fffe
    dc.w       COLOR00,$000
    dc.w       $2e07,$fffe
cpSnareColor:
    dc.w       COLOR00,$a22
    dc.w       $2f07,$fffe
    dc.w       COLOR00,$000

                ;dc.w       $90df,$fffe            ;  end of loading thingy
                ;dc.w       BPLCON0,$0000   
    dc.l       COPPER_HALT
    dc.l       COPPER_HALT

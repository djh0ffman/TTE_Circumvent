
; scripting

ScriptingInit:
    lea       Script,a0
    move.w    (a0)+,ScriptWait(a5)
    move.l    a0,ScriptPtr(a5)
    rts

Scripting:
    subq.w    #1,ScriptWait(a5)
    bne       .exit
    
    move.l    ScriptPtr(a5),a0
    move.l    (a0)+,d0
    beq       .exit

    move.w    (a0)+,ScriptWait(a5)
    move.l    a0,ScriptPtr(a5)
    move.l    d0,a1
    jmp       (a1)

.exit
    rts

; frames counts
FRM_NOTE = 7
FRM_BEAT = FRM_NOTE*4
FRM_BAR  = FRM_BEAT*4

Script:
    ; -- crack intro section
;    dc.w      FRM_BAR*2
;    dc.l      BannerNextPage
;    dc.w      FRM_BAR*2
;    dc.l      BannerNextPage
;    dc.w      FRM_BAR*2
;    dc.l      BannerNextPage
;    dc.w      FRM_BAR*2
;    dc.l      BannerNextPage


    dc.w      FRM_BAR*4
    dc.l      BannerNextPage
    dc.w      FRM_BAR*5
    dc.l      BannerShowMenu
    dc.w      (FRM_BAR*5)-FRM_BEAT
    dc.l      BringTheNoise

    ; -- big scroll
    dc.w      FRM_BEAT    
;    dc.l      KillScreen                                              
    dc.l      BigScrollScriptInit

    ; -- DISKS!!
    dc.w      FRM_BAR*8
    dc.l      DisksProgStart

    dc.w      FRM_BEAT*6
    dc.l      DiskProgAdvance                                         ; -- wob

    dc.w      FRM_BEAT*1
    dc.l      DiskProgAdvance                                         ; -- deerrrraaa

    dc.w      FRM_BEAT*1
    dc.l      DiskProgAdvance                                         ; -- clean

;    dc.w      FRM_BEAT*1
;    dc.l      DisksReverse

    dc.w      FRM_BEAT*6
    dc.l      DiskProgAdvance                                         ; -- long wobble

    dc.w      FRM_BEAT*2
    dc.l      DiskProgAdvance                                         ; -- clean

    dc.w      FRM_BEAT*7
    dc.l      DiskProgAdvance                                         ; -- big drop

    dc.w      FRM_BEAT*1
    dc.l      DiskProgAdvance                                         ; -- big drop

    dc.w      FRM_BEAT*6
    dc.l      DiskProgAdvance

    dc.w      FRM_BEAT*1
    dc.l      DiskProgAdvance

    ;dc.w      FRM_BEAT*1
    ;dc.l      DisksReverse


;    dc.w      FRM_BAR*4
;    dc.l      ScriptNull

    ; -- boing logo
;    dc.w      FRM_BAR*1
;    dc.l      RevbounceStart


    dc.w      FRM_BEAT*1
    dc.l      RevbounceStart

    dc.w      FRM_BAR*8
    dc.l      ScriptNull


    ; -- tunnel
    dc.w      FRM_BAR*4
    dc.l      TunnelScriptInit
    dc.w      FRM_BAR*4
    dc.l      ScriptNull

    ; -- greets
    dc.w      FRM_BAR*4
    dc.l      GreetScriptInit
    dc.w      FRM_BAR*4
    dc.l      GreetScriptStop

    dc.w      FRM_BAR*4
    dc.l      GreetScriptPlus

    dc.w      FRM_BEAT/2
    dc.l      GreetScriptPlus
    dc.w      FRM_BEAT/2
    dc.l      GreetScriptPlus
    dc.w      FRM_BEAT/2
    dc.l      GreetScriptPlus
    dc.w      FRM_BEAT/2
    dc.l      GreetScriptPlus

    ; -- edit pause before credits
    dc.w      FRM_BEAT*1
    dc.l      BringTheNoise
    ;dc.w      FRM_BEAT
    ;dc.l      BringTheNoise

    dc.w      FRM_BEAT
    dc.l      CreditsScriptInit

    dc.w      FRM_BAR*2
    dc.l      BannerNextPage
    dc.w      FRM_BAR*2
    dc.l      BannerNextPage
    dc.w      FRM_BAR*2
    dc.l      BannerNextPage
    dc.w      (FRM_BAR*2)-FRM_BEAT
    dc.l      BannerNextPage
    dc.w      FRM_BEAT
    dc.l      BannerNextPage
    dc.w      (FRM_BAR*3)+33
    dc.l      BannerNextPage

    dc.w      FRM_BEAT*2
    dc.l      KillDemo

    dc.w      FRM_BEAT*2
    dc.l      StartAR

    dc.w      1
    dc.l      0                                                       ; end of script


DiskProgAdvance:
    addq.w    #1,DiskParamStatus
    rts

BigScrollScriptInit:
    bsr       KillScreen
    move.l    #BigScrollScriptInit2,BackgroundThreadPtr(a5)
    rts

BigScrollScriptInit2
    jsr       Bigscroll_init
    clr.l     BackgroundThreadPtr(a5)
    move.l    #Bigscroll_frame,VBlankPtr(a5)
    rts


GreetScriptPlus:
    addq.w    #1,GridListInc
    rts

KillDemo:
    bsr       KillScreen
    clr.w     MusicEnabled(a5)
    clr.w     DMAAudio
    move.w    #$0004,DMACON(a6)
    move.w    #0,AUD0VOL(a6)
    move.w    #0,AUD1VOL(a6)
    move.w    #0,AUD2VOL(a6)
    move.w    #0,AUD3VOL(a6)
    rts

TunnelScriptInit:
    bsr       KillScreen
    move.l    #TunnelScriptInit2,BackgroundThreadPtr(a5)
    rts

TunnelScriptInit2:
    clr.l     BackgroundThreadPtr(a5)
    jsr       TunnelInit
    move.l    #TunnelTick,VBlankPtr(a5)
    rts


StartAR:
    jsr       ActionReplayInit
    move.l    #ActionReplayTick,VBlankPtr(a5)
    rts

ScriptNull:
    rts

BannerNextPage:
    move.w    #1,TitleNextPage(a5)
    rts

BannerShowMenu:
    move.w    #5,TitleStatus(a5)
    rts

BringTheNoise:
    bsr       KillScreen
    move.l    #BringTheNoise2,BackgroundThreadPtr(a5)
    rts

BringTheNoise2:
    clr.l     BackgroundThreadPtr(a5)
    jsr       NoiseInit
    move.l    #NoiseTick,VBlankPtr(a5)
    rts


KillScreen:
    WAITBLIT  
    clr.l     BackgroundThreadPtr(a5)
    clr.l     VBlankPtr(a5)
    clr.l     CopperIntPtr(a5)
    move.l    #DeadCopper,COP1LC(a6)
    move.w    #0,COPJMP1(a6)
    rts

DisksProgStart:
    bsr       KillScreen
    move.l    #DisksProgStart2,BackgroundThreadPtr(a5)
    rts

DisksProgStart2:
    jsr       DisksInit
    move.l    #DisksCopperTick,CopperIntPtr(a5)
    move.l    #DisksVBlankTick,VBlankPtr(a5)
    clr.l     BackgroundThreadPtr(a5)
    rts

RevbounceStart:
    bsr       KillScreen
    move.l    #RevbounceStart2,BackgroundThreadPtr(a5)
    rts

RevbounceStart2:
    jsr       revbounce_init
    move.l    #revbounce_vbtick,VBlankPtr(a5)
    move.l    #revbounce_background_thread,BackgroundThreadPtr(a5)
    rts

GreetScriptInit:
    bsr       KillScreen
    move.l    #GreetScriptInit2,BackgroundThreadPtr(a5)
    rts

GreetScriptInit2:
    jsr       GreetsInit
    move.l    #GreetsBackgroundThread,BackgroundThreadPtr(a5)
    move.l    #GreetsTick,VBlankPtr(a5)
    rts

GreetScriptStop:
    clr.l     BackgroundThreadPtr(a5)
    rts


CreditsScriptInit:
    bsr       KillScreen
    bsr       HoffBannerCleanInit
    move.l    #TextProgCredits,TextProgPtr(a5)
    move.l    #HoffBannerBkg2,BackgroundThreadPtr(a5)
    move.l    #HoffBannerVBlank,VBlankPtr(a5)
    rts
; -------------------------------------------------------
;
; TTE - tinytro
;
; Code  : h0ffman
; Music : h0ffman
; ASCII : ne7 & FuZion
; Synth : Blueberry
;
; READ THIS STUFF
;
; Builds with VASM by hand or use the built in VSCode build task
;
; The VSCode launch config has a %%PATH%% variable to point to 
; kickstart roms when using VSCode Amiga Assembly Plugin
;
; https://marketplace.visualstudio.com/items?itemName=prb28.amiga-assembly
;
; Display text needs to be AMIGA ASCII format. If in doubt open it 
; in Notepad++ and run EOL conversion to UNIX.  NO TABS!!
;
; version-ish
;
; 2024-01-10
; SYNC FX on bars
; new menu functions
; some better comments
;
; -------------------------------------------------------

    INCDIR      "include"
    INCLUDE     "hw.i"
    INCLUDE     "funcdef.i"
    INCLUDE     "exec/exec_lib.i"
    INCLUDE     "graphics/graphics_lib.i"
    INCLUDE     "hardware/cia.i"
    include     "graphics/text.i"
    include     "macros.asm"
    include     "variables.asm"
;---------- Const ----------

    section     tinytro,code
CIAA                       = $00bfe001

DMACONSET                  = %1000001111000000

SYSTEM_NICE                = 1                                                  ; 0 = fuck the OS for less code and force to $40000 : 1 = be nice to the OS and return gracefully

MENU_ON                    = 1                                                  ; include all code required for menu selection
    IF          MENU_ON=1
MENU_LINE                  = 8                                                  ; text line menu starts on
MENU_COUNT                 = 5                                                  ; count of menu items
MENU_SELECT                = 0                                                  ; 0 = options on / off : 1 = pack menu selection
    ENDIF

SYNC_FX                    = 1                                                  ; include code for top and bottom bar music sync

INCLUDE_SAMPLES            = 0
USE_PREBUILT_RINGRENDERERS = 0                                                  ; revision logo will include ringx.s files instead of generate code if 1

Main:
    IF          SYSTEM_NICE=1
    PUSHALL
    ENDIF

    lea         CUSTOM,a6
    lea         Variables,a5

    IF          SYSTEM_NICE=1
    bsr         system_disable
    ELSE
    move.w      #$7fff,d0
    move.w      d0,$9A(a6)                                                      ; Disable Interrupts
    move.w      d0,$96(a6)                                                      ; Clear all DMA channels
    move.w      d0,$9C(a6)                                                      ; Clear all INT requests
    ENDIF

    bsr         Init

    move.w      #1,DemoEnabled(a5)
    move.w      #1,MusicEnabled(a5)

.mainloop
    move.l      BackgroundThreadPtr(a5),d0
    beq         .notset

    move.l      d0,a0
    jsr         (a0)
.notset
    btst        #6,$bfe001
    bne         .mainloop


    ; graceful system exit with no bootloader
    IF          SYSTEM_NICE=1
    bsr         system_enable
    POPALL
    rts
    ELSE

    ; exit point for disabled system and bootloader
    ;move.w        OptionId(a5),d0                           ; this value is the selected item from the list
    ;move.l        Options(a5),d0                            ; bit flags from options menu
    RESET
    ENDIF



    IF          INCLUDE_SAMPLES=0
;------------------------------------------------
;
; pre-calc bar
;
;------------------------------------------------
PRECALC_DMA                = %1000001110000000

PROGRESS_PLANE             = ScreenMem
PROGRESS_MESSAGE_PLANE     = ScreenMem+(320/4)

setup_precalc_bar:
    bsr         PrecalcBarPrep

    move.l      #PROGRESS_PLANE,d0
    lea         progress_copper,a1
    move.w      d0,6(a1)
    swap        d0
    move.w      d0,2(a1)
    swap        d0

    addq.l      #8,a1
    add.l       #320/8,d0
    move.w      d0,6(a1)
    swap        d0
    move.w      d0,2(a1)
    swap        d0

    move.l      #PROGRESS_MESSAGE_PLANE,d0
    lea         progress_message_copper,a1
    move.w      d0,6(a1)
    swap        d0
    move.w      d0,2(a1)
    swap        d0

    move.b      #$80,PROGRESS_PLANE
    move.l      #precalc_copper,COP1LC(a6)
    move.w      #0,COPJMP1(a6)
    move.w      #PRECALC_DMA,DMACON(a6)                                         ; set DMA	+ BIT 09/15
    move.w      #$8200,DMACON(a6)
    move.l      #precalc_vblank,VBlankPtr(a5)
    rts

PrecalcBarClear:
    lea         PROGRESS_PLANE,a0
    move.w      #((320/8)/2)-1,d7
.clear
    clr.l       (a0)+
    dbra        d7,.clear
    rts

PrecalcBarPrep:
    bsr         PrecalcClearMsg

    lea         PROGRESS_PLANE,a0
    move.w      #((320/8)/2)-1,d7
.clear
    clr.w       (a0)+
    dbra        d7,.clear

    move.w      #((320/8)/2)-1,d7
.fill
    move.w      #-1,(a0)+
    dbra        d7,.fill
    rts


PrecalcClearMsg:
    lea         PROGRESS_MESSAGE_PLANE,a0
    move.w      #(80*8)-1,d7
.msgclear
    clr.b       (a0)+
    ;move.b        #$88,(a0)+
    dbra        d7,.msgclear    
    rts

; d0 = 0 - 320
PrecalcPrintMsg:
    move.w      PrecalcMessage,d1
    mulu        #320,d1
    divu        #PRECALC_MSG_COUNT,d1

    cmp.w       d0,d1
    ble         .printit
    rts
.printit
    addq.w      #1,PrecalcMessage
    bsr         PrecalcClearMsg

    move.l      PrecalcTextPtr,a0
    lea         FontTopaz,a1
    lea         PROGRESS_MESSAGE_PLANE+2,a3
.charloop
    moveq       #0,d0
    move.b      (a0)+,d0
    beq         .done
    sub.w       #$20,d0
    lsl.w       #3,d0
    lea         (a1,d0.w),a4
    move.b      (a4)+,AR_WIDTH_BYTE*0(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*1(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*2(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*3(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*4(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*5(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*6(a3)
    move.b      (a4)+,AR_WIDTH_BYTE*7(a3)
    addq.l      #1,a3
    bra         .charloop
.done
    move.l      a0,PrecalcTextPtr
    rts

PrecalcMessage:
    dc.w        0

PRECALC_MSG_COUNT          = 8

PrecalcTextPtr:
    dc.l        PrecalcText
PrecalcText:
    dc.b        "Pre-rendering audio data...",0
    dc.b        "Yeah we know..  it takes ages...",0
    dc.b        "We have a greedy musician with a lot of instruments",0
    dc.b        "And no.. it's not AmigaKlang ;)",0
    dc.b        "Still, this is probably quicker than most AGA 060 demos!",0
    dc.b        "Now..  shout AMIGAaaaaaaaaa!!!",0
    dc.b        "LAUTER!!!!",0
    dc.b        "Fasten your seatbelts.....",0
    dc.b        "LET'S ROCK!",0
    dc.b        -1
    even 

**********************************************************************
** pre-calc vblank (lets get a bar running shall we)
**********************************************************************     

precalc_vblank:  
    lea         prog_current(pc),a0
    move.l      progress_pointer,d0                                             ; current
    sub.l       #sample_ram,d0
    cmp.l       (a0),d0
    beq.b       .same

    move.l      d0,(a0)                                                         ; store new current
    move.l      #sample_ram_end-sample_ram,d1                                   ; total

    asr.l       #8,d0
    asr.l       #8,d1

    mulu        #320,d0
    divu.w      d1,d0

    cmp.w       #320,d0
    blo.b       .doit
    move.w      #320,d0
    move.l      #fadecalc_vblank,VBlankPtr(a5)

.doit
    PUSHMOST
    bsr         PrecalcPrintMsg
    POPMOST

    lea         ScreenMem,a0
    move.w      d0,d1
    divu.w      #8,d1                                                           ; 8 pixels
    move.w      d1,d2
    swap        d1                                                              ; remainder

    moveq       #-1,d3
    lsr.b       d1,d3
    not.b       d3
                  
    subq.w      #1,d2
    bcs.b       .equal
    moveq       #-1,d4
.byte  
    move.b      d4,(a0)+
    dbra        d2,.byte
.equal 
    move.b      d3,(a0)

.same 
    rts

prog_current:   
    dc.l        0


**********************************************************************
** pre-calc vblank fade (lets do something gentle before we start the show)
**********************************************************************     

fadecalc_vblank:  
    lea         fade_pause(pc),a0
    move.w      (a0),d0
    bmi.b       .pause
    addq.w      #1,d0
    cmp.w       #7,d0
    ble.b       .pause
                   
    moveq       #0,d0                                                           ; reset you idiot
    lea         precalc_col+2,a1
    lea         precalc_col2+2,a2
    move.w      (a1),d1
    beq.b       .done
    sub.w       #$111,d1
    move.w      d1,(a1)
    move.w      d1,(a2)
    bra.b       .pause
.done  
    moveq       #-1,d0
    move.w      d0,(a0)  
    bsr         PrecalcBarClear
    rts

.pause 
    move.w      d0,(a0)  
    rts


fade_pause:   
    dc.w        0
    ENDIF

;------------------------------------------------
;
; INIT!!
;
;------------------------------------------------

Init:
    move.l      sys_vectorbase(a5),a0
    lea         VBlankTick,a1
    move.l      a1,$6c(a0)
    move.w      #INTENASET!$C000,$9A(a6)                                        ; set Interrupts+ BIT 14/15

    bsr         NurdleFont

    IF          INCLUDE_SAMPLES=0
    bsr         setup_precalc_bar
    ELSE
    bsr         make_sine
    ENDIF

    lea         $BFD100,a3
    or.b        #$f8,(a3)
    nop
    and.b       #$87,(a3)
    nop
    or.b        #$78,(a3)                                                       ; deselect all

    bsr         MusicInit

    bsr         DiscreteInit

    IF          INCLUDE_SAMPLES=0
.notyet        
    tst.w       fade_pause
    bpl         .notyet
    ENDIF

    move.l      #$BABEFEED,RandomSeed(a5)
    bsr         ScriptingInit
    bsr         GenericRandomGen
    bsr         PrepRand

    move.l      #ScreenMem,d1
    lea         cpBannerPlanes,a2
    move.w      d1,6(a2)
    swap        d1
    move.w      d1,2(a2)
    swap        d1
    move.l      #ScreenOffset,d1
    move.w      d1,8+6(a2)
    swap        d1
    move.w      d1,8+2(a2)
    swap        d1

    bsr         HoffBannerCleanInit

    move.l      #HoffBannerBkg,BackgroundThreadPtr(a5)
    move.l      #HoffBannerVBlank,VBlankPtr(a5)
    move.l      #TextProg,TextProgPtr(a5)

    move.w      #DMACONSET,dmacon(a6)

    rts



GenericRandomGen:
    move.w      #1024-1,d7
    lea         RandomList,a0
.loop
    RANDOMWORD
    move.w      d0,(a0)+
    dbra        d7,.loop
    rts


    IF          INCLUDE_SAMPLES=1

make_sine:
    lea         sinus,a0
    addq.l      #2,a0
    lea.l       sine_degrees/2*2-2(a0),a1

    moveq.l     #1,d7
.loop:
    move.w      d7,d1
    mulu.w      d7,d1
    lsr.l       #8,d1

    move.w      #2373,d0
    mulu.w      d1,d0
    swap.w      d0
    neg.w       d0
    add.w       #21073,d0
    mulu.w      d1,d0
    swap.w      d0
    neg.w       d0
    add.w       #51469,d0
    mulu.w      d7,d0
    lsr.l       #8,d0
    lsr.l       #5,d0

    move.w      d0,(a0)+
    move.w      d0,-(a1)
    neg.w       d0
    move.w      d0,sine_degrees/2*2(a1)
    move.w      d0,sine_degrees/2*2-2(a0)

    addq.w      #1,d7
    cmp.w       #sine_degrees/4,d7
    blt.b       .loop

    neg.w       d0
    move.w      d0,-(a1)
    neg.w       d0
    move.w      d0,sine_degrees/2*2(a1)
    rts

sine_degrees               = 16384
sinus:
    dcb.w       sine_degrees
    ENDIF

; ------------------------------------------
;
; discrete init processing
;
; ------------------------------------------

DiscreteInit:
    lea         DiscreteInitList(pc),a0
.next
    move.l      (a0)+,d0
    beq         .discretedone
    PUSHALL
    move.l      d0,a0
    jsr         (a0)
    POPALL
    bra         .next
.discretedone
    rts

DiscreteInitList:
    dc.l        DisksDiscreteInit
    ;dc.l          NurdleFont  
    dc.l        GreetsDiscreteInit
    dc.l        TunnelDiscreteInit
    dc.l        revbounce_discrete_init ; this needs an intermediate cache clear
    dc.l        Bigscroll_discrete_init
    dc.l        ClearCaches
    dc.l        0

; ------------------------------------------
;
; font nurdler
;
; ------------------------------------------


FONT_CHAR_COUNT            = 224

NurdleFont:
    move.l      TopazPtr(a5),a0
    lea         FontTopaz,a1
    moveq       #0,d0
    move.w      TopazMod(a5),d0

    move.w      #FONT_CHAR_COUNT-1,d7
.charloop
    move.l      a0,a2
    moveq       #8-1,d6
.pixloop
    move.b      (a2),(a1)+
    add.l       d0,a2
    dbra        d6,.pixloop

    addq.l      #1,a0
    dbra        d7,.charloop
    rts


RAND_MAX                   = 80+32

PrepRand:
    lea         RandList(a5),a0
    move.w      #RAND_MAX-1,d7
.loop
    RANDOMWORD
    and.w       #31<<3,d0
    move.w      d0,(a0)+
    dbra        d7,.loop

    lea         RandList2(a5),a0
    move.w      #RAND_MAX-1,d7
.loop2
    RANDOMWORD
    and.w       #15<<3,d0
    move.w      d0,(a0)+
    dbra        d7,.loop2

    rts


MusicInit:
    PUSHALL
    IF          INCLUDE_SAMPLES=1
    lea         LSBank,a1
    ENDIF
    lea         LSTune,a0
    lea         DMAAudio+1,a2
    bsr         LSP_MusicInit
    POPALL
    rts

DMAAudio:
    dc.w        $8000



MusicPlay:
    move.b      VHPOSR(a6),d0
    add.b       #7,d0
    PUSH        d0

    lea         AUD0LC(a6),a6
    bsr         LSP_MusicPlayTick

    if          INCLUDE_SAMPLES=0
    lea         Variables,a5
    jsr         drum_loop_runtime  
    endif

    POP         d0                      
    lea         Variables,a5
    lea         CUSTOM,a6
.wait1    
    cmp.b       VHPOSR(a6),d0
    bcc         .wait1
    move.w      DMAAudio,d0
    move.w      d0,DMACON(a6)

    rts
     

; ------------------------------------------
;
; vblank / copper intterupt handler
;
; ------------------------------------------

VBlankTick:
    PUSHALL
    lea         CUSTOM,a6                   
    lea         Variables,a5

    move.w      INTREQR(a6),d0
    move.w      d0,d1
    and.w       #$3fff,d1
    move.w      d1,INTREQ(a6)
    move.w      d1,INTREQ(a6)

    and.w       #$0010,d0
    beq         .vblank

    ; copper interrupt
    move.l      CopperIntPtr(a5),d0
    beq         .exit
    move.l      d0,a0
    jsr         (a0)
    bra         .exit

.vblank    
    tst.w       DemoEnabled(a5)
    beq         .nodemo

    tst.w       MusicEnabled(a5)
    beq         .shhh
    bsr         MusicPlay
.shhh
    bsr         Scripting
    addq.w      #1,TickCounter(a5)
.nodemo
    move.l      VBlankPtr(a5),d0
    beq         .exit
    move.l      d0,a0
    jsr         (a0)
.exit

    ;move.w        #$000,$dff180
    POPALL
    rte


    include     "LightSpeedPlayer.asm"

    include     "scripting.asm"



    if          SYNC_FX=1
    include     "sync.asm"
    endif

    include     "banner.asm"

    IF          SYSTEM_NICE=1
    include     "os_kill.asm"
    ENDIF


FontDef:
    dc.l        0
    dc.w        8,0

TextProg:
    dc.l        LogoText
    dc.l        BANNER_SCREEN_WIDTH_BYTE*8
    dc.w        0                                                               ; no centring
    dc.w        6*FPS                                                           ; wait time

    dc.l        IntroText
    dc.l        BANNER_SCREEN_WIDTH_BYTE*10
    dc.w        1                                                               ; centring
    dc.w        6*FPS                                                           ; wait time
TextProgLast:
    dc.l        0                                                               ; repeat



TextProgCredits:
    dc.l        CredHoff
    dc.l        BANNER_SCREEN_WIDTH_BYTE*8
    dc.w        0                                                               ; no centring
    dc.w        6*FPS                                                           ; wait time

    dc.l        CredHoover
    dc.l        BANNER_SCREEN_WIDTH_BYTE*8
    dc.w        0                                                               ; no centring
    dc.w        6*FPS                                                           ; wait time

    dc.l        CredIridon
    dc.l        BANNER_SCREEN_WIDTH_BYTE*8
    dc.w        0                                                               ; no centring
    dc.w        6*FPS                                                           ; wait time

    dc.l        CredNE7
    dc.l        BANNER_SCREEN_WIDTH_BYTE*8
    dc.w        0                                                               ; no centring
    dc.w        6*FPS                                                           ; wait time
TextProgCreditsLast:
    dc.l        MembersText
    dc.l        BANNER_SCREEN_WIDTH_BYTE*10
    dc.w        1                                                               ; centring
    dc.w        6*FPS                                                           ; wait time

    dc.l        0

    IF          MENU_ON=1
MenuProg:
    dc.l        MenuText
    dc.l        BANNER_SCREEN_WIDTH_BYTE*10
    dc.w        1                                                               ; centring
    dc.w        15*FPS                                                          ; wait time
    dc.l        0
    ENDIF


    IF          SYSTEM_NICE=0
graphics_name:   
    dc.b        'graphics.library',0
    even
    ENDIF

; 224*8
FontName:
    dc.b        "topaz.font",0
GfxLib:	
    dc.b        "graphics.library",0                                            ;MUST BE ODD!
    even

LogoText:
    incbin      "text/ne7-tte.txt"
    dc.b        0
    even

IntroText:
    incbin      "text/intro-text.txt"
    dc.b        0
    even

MembersText:
    incbin      "text/tte-members.txt"
    dc.b        0
    even

CredHoff:
    incbin      "text/cred-hoff.txt"
    dc.b        0 
    even

CredIridon:
    incbin      "text/cred-iridon.txt"
    dc.b        0 
    even
CredHoover:
    incbin      "text/cred-hoover.txt"
    dc.b        0 
    even
CredNE7:
    incbin      "text/cred-ne7.txt"
    dc.b        0 
    even

BBSAdd:
    incbin      "text/r32_bbs_ad2.txt"
    dc.b        0
    even


    IF          MENU_ON=1
MenuText:
    incbin      "text/menu.txt"
    dc.b        0
    even
    ENDIF




    ; base data and ram sections
    include     "data_chip.asm"
    include     "data_fast.asm"
    include     "mem_chip.asm"
    include     "mem_fast.asm"


;--------------------------------
;
; PARTS
;
;--------------------------------

    incdir      "Noise"
    include     "noise.asm"

    incdir      "Bigscroll"
    include     "bigscroll.s"

    incdir      "Disks"
    include     "disks.asm"

    incdir      "Revbounce"
    include     "revbounce.s"

    incdir      "Greets"
    include     "greets.asm"

    incdir      "Tunnel"
    include     "tunnel.asm"

    incdir      "ActionReplay"
    include     "actionreplay.asm"

    section     tinytro,code

	include "exec/exec.i"

ClearCaches:
    movem.l     d2-d7/a2-a6,-(sp)
	move.l	    4.w,a6
	btst	    #AFB_68020,(AttnFlags+1,a6)
	beq		    .done
    lea         (.flush,pc),a5
    jsr         (_LVOSupervisor,a6)
.done:
    movem.l     (sp)+,d2-d7/a2-a6
    rts

.flush:
	dc.w	    $4E7A,$0002				; movec CACR,d0
	tst.w	    d0						; test bit 15
	bmi		    .cache040				; 040/060 instruction cache enabled
	or.w	    #CACRF_ClearI,d0		; 020/030 flush instruction cache
	dc.w	    $4E7B,$0002				; movec d0,CACR
	rte
.cache040:
	dc.w	    $F4F8					; cpusha bc	; 040/060 flush both caches
	rte

;--------------------------------
;
; GENERATOR
;
;--------------------------------
    IF          INCLUDE_SAMPLES=0
    include     "tunedata\project_config.i"

    incdir      "generator"
    include     "generator.asm"
    ENDIF
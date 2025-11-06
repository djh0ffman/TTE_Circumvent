
                   incdir     include
                   include    hw.i


SEEK_ZERO      = 1                                 ; 0 - assume track number has been set correctly / seek to zero then to track

;CIAA           = $bfe001
;CIAB           = $bfe101

CIAPRA       EQU $0000
CIAPRB       EQU $0100
CIADDRA      EQU $0200
CIADDRB      EQU $0300
CIATALO      EQU $0400
CIATAHI      EQU $0500
CIATBLO      EQU $0600
CIATBHI      EQU $0700
CIATODLOW    EQU $0800
CIATODMID    EQU $0900
CIATODHI     EQU $0A00
CIASDR       EQU $0C00
CIAICR       EQU $0D00
CIACRA       EQU $0E00
CIACRB       EQU $0F00

; from memory.asm


; Port A bits (input)
DSKCHANGE    equ 2
DSKPROT      equ 3
DSKTRACK0    equ 4
DSKRDY       equ 5

; Port B bits (output)
DSKSTEP      equ 0
DSKDIREC     equ 1
DSKSIDE      equ 2
DSKSEL0      equ 3
DSKMOTOR     equ 7

; constants
NUM_TRACKS   equ 160
SECT_PER_TRK equ 11
STEPDELAY    equ 64                                ; (* 64us) ca. 4ms  (minimum: 3ms)
SETTLEDELAY  equ 400                               ; (* 64us) ca. 25ms (minimum: 18ms)

MFM_BUFSIZE  equ $1a00*2
MFM_READLEN  equ $19f0                             ; in words
MFM_WRITELEN equ $1900                             ; in words
MFM_GAPSIZE  equ $f0                               ; gap in words at track-start and end

NUM_RETRIES  equ 4                                 ; retries on read error
DMA_TIMEOUT  equ 2000                              ; timeout after 2 seconds


                ;near       a4

                 ;section    trackdisk,code


; a0 = track data $1600 bytes
; a1 = mfm buffer

TrackSeeker:
                   movem.l    d1-d7/a0-a6,-(sp)
                   lea        TrackVars(pc),a4
;                 move.l     a0,DataPointer(a4)
;                 move.l     a1,MFMbuffer(a4)

                   lea        $dff000,a6
                   lea        $BFE001,a2
                   lea        $BFD100,a3
                   
;                 move.w     #$4000,DSKLEN(a6)
;                 move.w     #$8210,DMACON(a6)
;                 move.w     #$1002,INTENA(a6)

                  ; motor on
                   ;bsr        td_motoron
                   
                   moveq      #$7d,d1
                   move.b     d1,(a3)
                   bclr       #3,d1
                   move.b     d1,(a3)

                   moveq      #100-1,d2            ; timeout after ~500ms
.waitdrive:        moveq      #78,d0
                   bsr        td_delay             ; ~5ms
                   btst       #DSKRDY,(a2)
                   dbeq       d2,.waitdrive

                   bsr        td_seekzero

                   move.w     #10000,d0
                   bsr        td_delay             ; wait until TRACK0 signal is valid


                   or.b       #$f8,(a3)
                   nop
                   and.b      #$87,(a3)
                   nop
                   or.b       #$78,(a3)            ; deselect all

                   movem.l    (sp)+,d1-d7/a0-a6
                   moveq      #0,d0
                   rts








;---------------------------------------------------------------------------
td_seek:
; Step to the required cylinder and select the correct head.
; d0.w = track to seek
; a2 = CIAAPRA
; a3 = CIABPRB

                   cmp.w      #NUM_TRACKS,d0
                   bhs        .exit                ; illegal track

                   movem.l    d2-d3,-(sp)
                   move.w     CurrentTrk(a4),d3
                   move.w     d0,d2
                   btst       #0,d2
                   bne        .1

	; select lower head
                   bset       #DSKSIDE,(a3)
                   bclr       #0,d3
                   bra        .2

	; select upper head
.1:                bclr       #DSKSIDE,(a3)
                   bset       #0,d3

.2:                cmp.w      d3,d2
                   beq        .done
                   bhi        .3

	; step outwards
                   bset       #DSKDIREC,(a3)
                   subq.w     #2,d3
                   bra        .4

.3:	; step inwards
                   bclr       #DSKDIREC,(a3)
                   addq.w     #2,d3

.4:                bsr        td_step
                   bra        .2

.done:
                   move.w     d2,CurrentTrk(a4)

                   move.w     #SETTLEDELAY,d0
                   bsr        td_delay

                   movem.l    (sp)+,d2-d3
.exit:
                   rts

                   IF         SEEK_ZERO=1
td_seekzero:
; Turn motor on. Seek track 0, reset CurrentTrk to 0.
; a2 = CIAAPRA
; a3 = CIABPRB
; -> d0/Z = error code (0=ok, 1=unformatted, 2=missingSectors, 3=badHeader)

                   bset       #DSKSIDE,(a3)        ; select lower head: track 0
                   bset       #DSKDIREC,(a3)       ; step outwards

.1:                moveq      #STEPDELAY,d0
                   bsr        td_delay             ; wait until TRACK0 signal is valid

                   btst       #DSKTRACK0,(a2)
                   beq        .2

                   bsr        td_step
                   bra        .1

	; head is positioned over track 0 now; read it
.2:                clr.w      CurrentTrk(a4)
                   rts
                   ENDIF

;---------------------------------------------------------------------------
td_step:
; Step a track into selected direction.
; a2 = CIAAPRA
; a3 = CIABPRB

                   moveq      #STEPDELAY,d0
                   bsr        td_delay
                   bclr       #DSKSTEP,(a3)
                   nop
                   bset       #DSKSTEP,(a3)
                   rts


;---------------------------------------------------------------------------
td_delay:
; Wait for ca. count * 64us.
; d0.w = count
; a0 and a1 are preserved!

.1:                move.b     VHPOSR(a6),d1
.2:                cmp.b      VHPOSR(a6),d1
                   beq        .2
                   subq.w     #1,d0
                   bne        .1
                   rts

                   RSRESET
MFMbuffer:         rs.l       1                    ;ChipMFMBuffer                      ; buffer for raw MFM track data
DataPointer:       rs.l       1
CurrentTrk:        rs.w       1                    ; current track in MFM buffer (-1 = none)
TrackVars_Size:    rs.b       0



TrackVars:         dcb.b      TrackVars_Size,0
                   even
                   dc.b       "END!"



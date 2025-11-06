** VOICE SYNC
**
** Single output ocsillator with hard sync to secondary silent oscillator

; d0 = osc1 wave
; d1 = osc1 amp

; d5 = osc1 period  
; d6 = osc2 period

voice_sync:  nop
             lea            wave_pointers,a6
             lsl.w          #2,d0
             move.l         (a6,d0.w),a0
             lea            amp_1,a1
             move.w         d1,d0
             bsr            voice_amp

             move.w         d5,d1
             move.w         d6,d2

; d1 = osc1 period
; d2 = osc2 period

             move.l         render_pointer,a0 
             move.l         render_period,d5
             move.w         render_length,d7
             CALCDELTA32    d0,d1,d6
             CALCDELTA32    d0,d2,d6
             moveq          #0,d3                ; osc1 counter
             moveq          #0,d4                ; osc2 counter
             move.w         #255,d6              ; wave and'er  
             lea            amp_1(pc),a1 

             lea            clamp2u,a6

             moveq          #0,d5                ; sample loader
             subq.w         #1,d7                ; dbra out by one

.sample      
             swap           d3
             swap           d4

             cmp.w          d6,d3
             ble.b          .noreset
             clr.w          d4
     
.noreset     and.w          d6,d4
             and.w          d6,d3

             moveq          #0,d0                ; wave accumulator
             move.b         (a0),d0              ; get source
             move.b         (a1,d4.w),d5         ; osc 1
             add.w          d5,d0                ; mix

             move.b         (a6,d0.w),(a0)+      ; clamp output and store

             swap           d3                   ; flip ocs1 delta
             swap           d4                   ; flip osc2 delta
             add.l          d1,d3                ; add delta osc1
             add.l          d2,d4                ; add delta osc2

             dbra           d7,.sample

             rts

;		c   c#  d   d#  e   f   f#  g   g#  a   a#  b   
;period       dc.w           856,808,762,720,678,640,604,570,538,508,480,453
;             dc.w           428,404,381,360,339,320,302,285,269,254,240,226
;             dc.w           214,202,190,180,170,160,151,143,135,127,120,113


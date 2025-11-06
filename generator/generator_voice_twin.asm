
; d0 = osc1 wave
; d1 = osc1 amp
; d2 = osc2 wave
; d3 = osc2 amp
; d5 = osc1 note
; d6 = osc2 note

voice_twin: 
         moveq           #0,d0
         moveq           #0,d1
         moveq           #0,d2
         moveq           #0,d3
         moveq           #0,d4
         moveq           #0,d5
         moveq           #0,d6
    
         move.w          (a0)+,d0             ; osc1 wave
         move.w          (a0)+,d1             ; osc1 amp
         move.w          (a0)+,d2             ; osc2 wave
         move.w          (a0)+,d3             ; osc2 amp
         
         move.w          (a0)+,d5             ; osc1 note
         move.w          (a0)+,d6             ; osc2 note

         lea             wave_pointers,a6
         lsl.w           #2,d0
         move.l          (a6,d0.w),a0
         lea             amp_1,a1
         move.w          d1,d0
         bsr             voice_amp
            
         lea             wave_pointers,a6
         lsl.w           #2,d2
         move.l          (a6,d2.w),a0
         lea             amp_2,a1
         move.w          d3,d0
         bsr             voice_amp
            
         move.w          d5,d1
         move.w          d6,d2

; d1 = osc1 note
; d2 = osc2 note


         lea             period_table,a0
         NOTETOPERIOD    a0,d1,d4,d5,d6
         NOTETOPERIOD    a0,d2,d4,d5,d6

         moveq           #0,d0
         move.w          base_period,d0
         move.w          render_length,d7
         CALCDELTA32     d0,d1,d6
         CALCDELTA32     d0,d2,d6
         moveq           #0,d3                ; osc1 counter
         moveq           #0,d4                ; osc2 counter
         move.w          #255,d6              ; wave and'er  
         lea             amp_1,a1 
         lea             amp_2,a2

         move.l          render_pointer,a0 

         lea             clamp3u,a6

         moveq           #0,d5                ; sample loader
         subq.w          #1,d7                ; dbra out by one

.sample  moveq           #0,d0                ; wave accumulator
         swap            d3
         swap            d4
         and.w           d6,d3
         and.w           d6,d4

         move.b          (a0),d0              ; get source
         move.b          (a1,d3.w),d5         ; osc 1
         add.w           d5,d0                ; mix
         move.b          (a2,d4.w),d5         ; osc 2
         add.w           d5,d0                ; mix

         move.b          (a6,d0.w),(a0)+      ; clamp output and store

         swap            d3                   ; flip ocs1 delta
         swap            d4                   ; flip osc2 delta
         add.l           d1,d3                ; add delta osc1
         add.l           d2,d4                ; add delta osc2

         dbra            d7,.sample

         rts

;		c   c#  d   d#  e   f   f#  g   g#  a   a#  b   
;period       dc.w           856,808,762,720,678,640,604,570,538,508,480,453
;             dc.w           428,404,381,360,339,320,302,285,269,254,240,226
;             dc.w           214,202,190,180,170,160,151,143,135,127,120,113


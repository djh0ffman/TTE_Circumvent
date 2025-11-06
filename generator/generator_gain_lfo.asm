; gain LFO

; word - lfo waveform id

gain_lfo:
         move.w    (a0)+,d7

         lea       wave_pointers,a6
         lsl.w     #2,d7
         move.l    (a6,d7.w),a6         ; lfo wave


         moveq     #0,d6                ; lfo phase
         move.w    #$80,d4              ; signer

         moveq     #0,d1
         move.w    (a0)+,d1             ; lfo freq
         moveq     #0,d2
         move.w    (a0)+,d2             ; lfo inc
         ;swap      d1

         move.l    render_pointer,a0
         move.w    render_length,d7
         subq.w    #1,d7
         
         moveq     #50,d5

.sample  moveq     #0,d0                ; sample
         moveq     #0,d5                ; lfo value
         
         move.b    (a0),d0              ; get source
         move.b    (a6,d6.w),d5         ; lfo value

         add.b     d4,d0                ; sign sample
         ext.w     d0
         add.b     d4,d5                ; sign lfo

         muls      d5,d0                ; multiply
         divs      #255,d0              ; divide / now at x some

         add.b     d4,d0                ; unsign sample
         move.b    d0,(a0)+             ; push output

         swap      d6
         add.l     d1,d6
         move.w    d1,d2
         swap      d6
         and.w     #255,d6              ; cycle phase

         dbra      d7,.sample

         rts
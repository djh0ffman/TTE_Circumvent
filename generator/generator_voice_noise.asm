
; d0 = noise amp

; param list = a0
; word - amp

voice_noise:  
         move.w    (a0)+,d2
         lea       amp_1,a0
         move.w    #255,d6
         bsr       make_amp

         lea       noise,a2
         move.l    a2,a3
         lea       amp_1,a4
         lea       clamp2u,a6

         move.l    render_pointer,a0
         move.w    render_length,d7

         move.w    #noise_len,d1
         moveq     #0,d5                ; sample temp
              
.loop    move.w    d1,d6                ; counter
         sub.w     d6,d7                ; sub noise length from counter
         bcc.b     .over
         add.w     d6,d7                ; over flow, add it back
         move.w    d7,d6                ; move remainder in
         clr.w     d7                   ; clear sample counter to signify end

.over    subq.w    #1,d6
         bcs.b     .none

.sample  moveq     #0,d0                ; sample accumulator
              
         move.b    (a0),d0              ; get source
         move.b    (a3)+,d5             ; get noise
         move.b    (a4,d5.w),d5         ; amp noise
         add.w     d5,d0                ; mix noise

         move.b    (a6,d0.w),(a0)+      ; clamp output and store

         dbra      d6,.sample

.none    move.l    a2,a3

         tst.w     d7
         bne.b     .loop

         rts


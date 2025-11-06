; generator - gain

; word - gain percentage

gain:
         move.w    (a0)+,d2             ; gain
         lea       amp_1,a0
         move.w    #100,d6
         bsr       make_amp_uu

         lea       amp_1,a4

         move.l    render_pointer,a0
         move.w    render_length,d7
         subq.w    #1,d7
         moveq     #0,d0

.sample  move.b    (a0),d0              ; get source
         move.b    (a4,d0.w),(a0)+      ; push amped output

         dbra      d7,.sample

         rts
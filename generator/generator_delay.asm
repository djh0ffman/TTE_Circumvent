


delay_unrolllog2 = 4

; delay

; a0 = parameter chunk
; WORD delay level - byte (0-255)
; WROD feedback level - byte (0-255)
; WORD delay length

delay:             move.w    (a0)+,d0                                          ; delay level
                   move.w    (a0)+,d1                                          ; feedback level
                   move.w    (a0)+,delay_delaylen                              ; delay buffer length

                   lea       amp_1,a0
                   move.w    d0,d2
                   move.w    #255,d6
                   bsr       make_amp_uu

                   lea       amp_2,a0
                   move.w    d1,d2
                   move.w    #255,d6
                   bsr       make_amp_uu

                   lea       delay_delaybuf,a0
                   move.w    delay_delaylen,d7
                   btst      #0,d7
                   beq.b     .prep
                   addq.w    #1,d7
                
.prep              bsr       prep_buffer


; turbo delay run - single buffer replace version
; a0 = buffer
; d7 = length

                   move.l    render_pointer,a0
                   move.w    render_length,d7
                   lea       clamp2u,a6
                   lea       delay_delaybuf,a2
                   move.l    a2,a5                                             ; backup for later
                   lea       amp_1,a3
                   lea       amp_2,a4
                   move.w    delay_delaylen(pc),d5
                   moveq     #0,d0                                             ; clear for delay mix, not needed in inner loop
                   moveq     #0,d3                                             ; clear for output mix, not needed in inner loop
                   moveq     #-$80,d1                                          ; unsigner

.loop              move.w    d5,d4                                             ; set sample counter to delay length
                   sub.w     d5,d7                                             ; sub delay length from total length
                   bcc.b     .bufcont                                          ; no carry, so move into main loop
                   add.w     d5,d7                                             ; reset total length
                   move.w    d7,d4                                             ; set sample counter to remaining length
                   clr.w     d7                                                ; clear total as this is the last run

.bufcont           subq.w    #1,d4                                             ; dbra loop, out by one otherwise
                   move.w    d4,d2
                   lsr.w     #delay_unrolllog2,d4
                   not.w     d2
                   and.w     #(1<<delay_unrolllog2)-1,d2
                   mulu.w    #(.sampleend-.sample)/(1<<delay_unrolllog2),d2
                   jmp       .sample(pc,d2.w)

.sample     
                   REPT      (1<<delay_unrolllog2)
                   moveq     #0,d2
                   move.b    (a0),d2                                           ; source sample - unsigned
                   move.b    (a2),d3                                           ; get delay sample
                   moveq     #0,d6
                   move.b    (a3,d2.w),d6                                      ; delay input with volume (unsigned result)
                   move.b    (a4,d3.w),d0                                      ; delay feedback with volume (unsigned result)

                   add.w     d0,d6                                             ; mix input and feedback
                   move.b    (a6,d6.w),(a2)+                                   ; write delay buffer using clamp

                   add.w     d3,d2                                             ; mix delay and source
                   move.b    (a6,d2.w),(a0)+                                   ; write the output using clamp
                   ENDR
.sampleend
                   dbra      d4,.sample                                        ; loop next sample
                   move.l    a5,a2                                             ; restore to start of delay buffer

                   tst.w     d7                                                ; are we done yet
                   bne       .loop                                             ; nope
                   rts

delay_delaylen:    dc.w      0

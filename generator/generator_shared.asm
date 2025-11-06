; shared stuff

; builds the clamp table

noise_len    = $4000
sine_degrees = 16384

shared_init:  movem.l        d0-a6,-(sp) 
              bsr            make_clamp
              bsr            make_noise
              bsr            prep_wave_pointers
              bsr            make_sine
              bsr            make_freq_table
              bsr            drum_loop_precalc
              movem.l        (sp)+,d0-a6
              rts

make_sine:
              lea            sinus,a0
              addq.l         #2,a0
              lea.l          sine_degrees/2*2-2(a0),a1

              moveq.l        #1,d7
.loop:
              move.w         d7,d1
              mulu.w         d7,d1
              lsr.l          #8,d1

              move.w         #2373,d0
              mulu.w         d1,d0
              swap.w         d0
              neg.w          d0
              add.w          #21073,d0
              mulu.w         d1,d0
              swap.w         d0
              neg.w          d0
              add.w          #51469,d0
              mulu.w         d7,d0
              lsr.l          #8,d0
              lsr.l          #5,d0

              move.w         d0,(a0)+
              move.w         d0,-(a1)
              neg.w          d0
              move.w         d0,sine_degrees/2*2(a1)
              move.w         d0,sine_degrees/2*2-2(a0)

              addq.w         #1,d7
              cmp.w          #sine_degrees/4,d7
              blt.b          .loop

              neg.w          d0
              move.w         d0,-(a1)
              neg.w          d0
              move.w         d0,sine_degrees/2*2(a1)
              rts

prep_wave_pointers:
              lea            wave_pointers,a0
              lea            waves,a1
.next         moveq          #0,d0
              move.w         (a1)+,d0
              bmi.b          .done
              add.l          d0,d0
              add.l          d0,d0
              move.l         a1,(a0,d0.w)
              lea            (256,a1),a1
              bra.b          .next
.done         rts

              ; (200.0f + (20000.0f - 200.0f) * param * param);
make_freq_table:
              lea            freq_table,a0
              move.w         #freq_positions-1,d7         ; counter
              move.w         #200,d0                      ; fitler start position
              move.w         #20000-200,d1                ; fitler range
              moveq          #0,d2                        ; filter current position
              move.w         #freq_positions,d3           
.loop         move.w         d1,d4                        
              muls           d2,d4
              divs           d3,d4
              muls           d2,d4
              divs           d3,d4
              add.w          d0,d4
              move.w         d4,(a0)+
              addq.w         #1,d2                        ; next position
              dbra           d7,.loop
              rts

; preps the buffer with unsigned pcm samples $80
; a0 = buffer
; d7 = length
prep_buffer:  movem.l        d0-a6,-(sp)
              move.l         #$80808080,d0
              move.l         d0,d1
              move.l         d0,d2
              move.l         d0,d3
              move.l         d0,d4
              move.l         d0,d5
              move.l         d0,d6
              move.l         d0,a1
              move.l         d0,a2
              move.l         d0,a3
              move.l         d0,a4
              move.l         d0,a5
              move.l         d0,a6

              swap           d7
              clr.w          d7
              swap           d7
              add.l          d7,a0

              divu           #13*4,d7
              subq.w         #1,d7
              bcs.b          .bytes

.mloop        movem.l        d0-d6/a1-a6,-(a0)
              dbra           d7,.mloop

              swap           d7
.bytes        subq.w         #1,d7
              bcs.b          .exit
.bloop        move.b         d0,-(a0)
              dbra           d7,.bloop
            
.exit         movem.l        (sp)+,d0-a6
              rts

; a0 = buffer
; d7 = length
sign_buffer:  movem.l        d0-a6,-(sp)
              subq.w         #1,d7
              move.b         #$80,d6
.sloop        add.b          d6,(a0)+
              dbra           d7,.sloop
              movem.l        (sp)+,d0-a6
              rts


; a0 = source wave
; a1 = dest wave
; d0 = amp
voice_amp:    movem.l        d0-a6,-(sp) 
              move.w         #255,d7
.lp           move.b         (a0)+,d6
              ext.w          d6
              muls           d0,d6
              divs           #255,d6
              add.b          #$80,d6
              move.b         d6,(a1)+
              dbra           d7,.lp
              movem.l        (sp)+,d0-a6
              rts

                ; a0 = table address
                ; d2 = volume 
                ; d6 = divider / scale
make_amp:     movem.l        d0-a6,-(sp) 
              move.w         d6,d7                        ; counter
              moveq          #-$80,d5                     ; unsigner
              moveq          #0,d3                        ; sample
.amplp        move.w         d3,d4                        ; move sample
              ext.w          d4                           ; extend to word
              muls           d2,d4                        ; multiply sample by volume
              divs           d6,d4                        ; divide by factor
              add.b          d5,d4                        ; unsign
              move.b         d4,(a0)+                     ; store
              addq.b         #1,d3                        ; next sample
              dbra           d7,.amplp
              movem.l        (sp)+,d0-a6
              rts

                ; this was super werid to work out!!
                ; unsigned input -> unsigned output
                ; please someone tell me a more sensible way to do this!
                ; a0 = look up table address
                ; d2 = volume 
                ; d6 = divider / scale
make_amp_uu:  movem.l        d0-a6,-(sp)
              lea            ($80,a0),a0                  ; centre lookup
              move.l         a0,a1
              move.w         #127,d7                      ; counter
              moveq          #0,d3                        ; sample
              move.w         #$80,d0                      ; centre
              move.w         #$7f,d1
.amplp        move.w         d3,d4                        ; move sample
              ext.w          d4                           ; extend to word
              muls           d2,d4                        ; multiply sample by volume
              divs           d6,d4                        ; divide by factor
              cmp.b          d0,d4                        ; check over
              blo.b          .under
              move.w         d1,d4
.under        move.w         d0,d5                        ; centre
              add.w          d4,d5 
              move.b         d5,(a0)+                     ; store top
              move.w         d1,d5                        ; centre
              sub.w          d4,d5
              move.b         d5,-(a1)
              addq.b         #1,d3                        ; next sample
              dbra           d7,.amplp
              movem.l        (sp)+,d0-a6
              rts

make_clamp:   lea            clamp4,a0                    ; build clamp table
              lea            clamp4u,a1      
              moveq          #-$80,d0            
              moveq          #0,d1
              move.w         #$180-1,d6
              
              move.w         d6,d7
.cllow        move.b         d0,(a0)+
              move.b         d1,(a1)+
              dbra           d7,.cllow

              move.w         #$100-1,d7
.clmid        move.b         d0,(a0)+
              move.b         d1,(a1)+
              addq.b         #1,d0
              addq.b         #1,d1
              dbra           d7,.clmid
              subq.b         #1,d0
              subq.b         #1,d1

              move.w         d6,d7
.clhi         move.b         d0,(a0)+
              move.b         d1,(a1)+
              dbra           d7,.clhi
              rts

            ; pre-calcs an envelope ( range 0 - 255 )
            ; moves a0 (param chunk address) along 
            ; saves all other registers
            ; d0 = base position
            ; d1 = amount ( +255 / -255 )
make_env:     
              movem.l        d0-d7/a1-a6,-(sp)
              move.w         d0,d5                        ; store base position
              move.w         d1,d6                        ; backup env amout
              lea            envelope_table,a1

              ; ATTACK
              move.w         #255,d2 
              muls           d6,d2 
              divs           #255,d2                      ; attack top value              
              move.w         d0,d1
              add.w          d2,d1                        ; new attack to level
              move.w         (a0)+,d7                     ; num samples samples (attack)
              bsr            linear_env

              ; ATTACK HOLD
              move.w         (a0)+,(a1)+                  ; attack hold
              move.w         -4(a1),(a1)+                 ; last value hold

              ; DECAY
              move.w         d1,d0                        ; new current position
              move.w         (a0)+,d7                     ; decay samples
              move.w         (a0)+,d2                     ; sustain level
              muls           d6,d2 
              divs           #255,d2                      ; sustain value scaled
              move.w         d5,d1
              add.w          d2,d1                        ; sustatin + base position
              bsr            power_env

              ; SUSTAIN HOLD
              move.w         (a0)+,(a1)+                  ; attack hold
              move.w         -4(a1),(a1)+                 ; last value hold

              ; RELEASE
              move.w         d1,d0                        ; new current position
              move.w         (a0)+,d7                     ; release samples
              muls           d6,d2 
              divs           #255,d2                      ; sustain value scaled
              move.w         d5,d1                        ; back to base position
              bsr            power_env

              ; TAIL
              move.w         #-1,(a1)+                    ; attack hold
              move.w         -4(a1),(a1)+                 ; last value hold

              movem.l        (sp)+,d0-d7/a1-a6
              rts

            ; d0 = start value
            ; d1 = end value
            ; d7 = sample count
            
linear_env:   movem.l        d0-d7/a2-a6,-(sp)

              moveq          #0,d6                        ; up or down 
              move.w         d1,d2                        
              sub.w          d0,d2                        ; distance
              bpl.b          .upwards
              not.w          d2                           ; distance positive
              moveq          #-1,d6
.upwards      
              DIVIDE32       d2,d7,d3,d5,d6               ; d2 / d7 = d3 16:16
              swap           d0                           ; start value
              moveq          #0,d4                        ; sample couter 

              moveq          #-1,d1                       ; current clampped value
.loop         swap           d0                           ; switch counter
              move.w         d0,d5
              CLAMP_UBYTE    d5
              cmp.w          d5,d1
              beq.b          .same
              move.w         d5,d1                        ; new value

              move.w         d4,(a1)+                     ; store sample count
              move.w         d1,(a1)+                     ; store value
              moveq          #0,d4

.same         swap           d0                           ; swap to int value
              tst.b          d6                           ; check if up or down
              beq.b          .addme
              sub.l          d3,d0
              bra.b          .next                        ; maybe work out a better way with more code
.addme        add.l          d3,d0
.next         addq.w         #1,d4
              dbra           d7,.loop

              tst.w          d4
              beq.b          .noremain
              move.w         d4,(a1)+                     ; store remaining cample count
              move.w         -4(a1),(a1)+

.noremain     movem.l        (sp)+,d0-d7/a2-a6
              rts

            ; d0 = start value
            ; d1 = end value
            ; d6 - direction flag ( 0 upwards / -1 downards )
            ; d7 = sample count
            
power_env:    movem.l        d0-d7/a2-a6,-(sp)
              move.w         d1,a4                        ; destination
              move.l         d7,a3                        ; total samples

              moveq          #0,d6                        ; up or down 
              move.w         d1,d2                        
              sub.w          d0,d2                        ; distance
              bpl.b          .upwards
              not.w          d2                           ; distance positive
              moveq          #-1,d6
.upwards      
              move.w         d2,a2                        ; store distance
              DIVIDE32       d2,d7,d3,d5,d6               ; d2 / d7 = d3 16:16
              swap           d0                           ; start value
              moveq          #0,d4                        ; sample couter 

              moveq          #-1,d1                       ; current clampped value
.loop         swap           d0                           ; switch counter
              move.w         d0,d5
              CLAMP_UBYTE    d5
              cmp.w          d5,d1
              beq.b          .same
              move.w         d5,d1                        ; new value

              move.w         d4,(a1)+                     ; store sample count

              move.w         a2,d4                        ; distance
              move.w         a3,d2                        ; total samples
              mulu           d7,d4
              divu           d2,d4                        ; v * v
              mulu           d7,d4
              divu           d2,d4
              
              tst.b          d6
              beq.b          .inverted
              add.w          a4,d4
              move.w         d4,(a1)+                     ; store val
              bra.b          .next
.inverted     move.w         a4,a5
              sub.w          d4,a5
              move.w         a5,(a1)+                     ; store val

.next         moveq          #0,d4

.same         swap           d0                           ; swap to int value
              tst.b          d6                           ; check if up or down
              beq.b          .addme
              sub.l          d3,d0
              bra.b          .deltanext                   ; maybe work out a better way with more code
.addme        add.l          d3,d0
.deltanext    addq.w         #1,d4
              dbra           d7,.loop

              tst.w          d4
              beq.b          .noremain
              move.w         d4,(a1)+                     ; store remaining cample count
              move.w         -4(a1),(a1)+

.noremain     movem.l        (sp)+,d0-d7/a2-a6
              rts


	; noise generator (donated by Corial / Focus Design)
make_noise:
              lea            noise,a0
              move.w         #0102,d0                     ;just some initial values
              move.w         #0304,d1
              move.w         #0506,d2
              move.w         #0708,d3
              move.w         #0910,d4
              move.w         #1112,d5

              move.w         #noise_len-1,d7
.loop
              addx.w         d0,d1                        ;the code to generate pseudorandom numbers
              addx.w         d1,d2
              addx.w         d2,d3
              addx.w         d3,d4
              addx.w         d4,d5
              addx.w         d5,d0

              move.b         d0,(a0)+                     ;save value in buffer
              dbra           d7,.loop
              rts


; biquad filter
; special thanks to emoon for the help in getting this converted to integer maths

; this is incorrect due to our render rate
; but the calculation below doesn't play well with differen values
bq_sample_rate = 44100

; filter types
; 0 = low pass
; 1 = high pass
; 2 = band pass

; param list
; WORD - filter type
; WORD - frequency
; WORD - q / reso

biquad:        move.w           (a0)+,d7                       ; filter type
               moveq            #0,d0
               move.w           (a0)+,d0                       ; filter freq position (0 to freq positions)
               moveq            #0,d3
               move.w           (a0)+,d3                       ; q

               bsr              biquad_calc
               bra              biquad_main
               
               ; d7 filter type
               ; d0 filter freq position
               ; d3 q
biquad_calc:   lea              sinus,a6

               moveq            #0,d6
               move.w           #sine_degrees,d6               ; our const_1
                        
               moveq            #0,d2
               move.w           #bq_sample_rate,d2             ; sample rate

               lea              freq_table,a1
               add.w            d0,d0
               move.w           (a1,d0.w),d0

               move.l           d6,d1                          ; const_1
               mulu             d1,d0                          ; two_pi * freq
               divu             d2,d0                          ; div sample rate

               move.l           d0,d5              
               add.w            #sine_degrees/4,d5
               and.w            #sine_degrees-1,d5  

               add.w            d5,d5                          ; double for lookup
               move.w           (a6,d5.w),d5                   ; cos w0
               ext.l            d5   

               add.w            d3,d3                          ; shift q
               move.w           d0,d4
               ext.l            d4
               asl.l            #8,d4
               divs             d3,d4                          ; alpha_t
               ext.l            d4

               tst.b            d7                             ; select filter type
               beq              .lowpass
               cmp.b            #1,d7
               beq              .highpass

              ; biquad address foo (reference to C)
              ; a0 = dv = a0_i
              ; a1 = c1 = b0_i
              ; a2 = c2 = b1_i
              ; a3 = c3 = b2_i
              ; a4 = c4 = a1_i
              ; a5 = c5 = a2_i 
              ; d6 = sine_degress
              ; d5 = cos_w0
              ; d4 = alpha
 
              ; band pass
.bandpass      move.l           d6,d0
               add.l            d4,d0
               move.l           d0,a0                          ; a0_i

               moveq            #-2,d0
               move.l           d5,d1
               muls             d1,d0
               move.l           d0,a4                          ; a1_i

               move.l           d6,d0
               sub.l            d4,d0
               move.l           d0,a5                          ; a2_i

               move.l           d4,a1                          ; b0_i

               sub.l            a2,a2                          ; b1_i

               move.l           d4,d0
               not.l            d0
               move.l           d0,a3                          ; b2_i
               bra              .calccr

             ; hipass
.highpass      move.l           d6,d0
               add.l            d4,d0
               move.l           d0,a0                          ; a0_i

               moveq            #-2,d0
               move.l           d5,d1
               muls             d1,d0
               move.l           d0,a4                          ; a1_i

               move.l           d6,d0
               sub.l            d4,d0
               move.l           d0,a5                          ; a2_i
               
               move.l           d6,d0
               add.l            d5,d0
               lsr.l            #1,d0
               move.l           d0,a1                          ; b0_i

               move.l           d6,d0
               add.l            d5,d0
               not.l            d0
               move.l           d0,a2                          ; b1_i

               not.l            d0
               lsr.l            #1,d0
               move.l           d0,a3                          ; b2_i

               bra              .calccr

              ; address foo
              ; d6 = sine_degress
              ; d5 = cos_w0
              ; d4 = alpha
.lowpass       move.l           d6,d0
               add.l            d4,d0
               move.l           d0,a0                          ; a0_i

               moveq            #-2,d0
               move.l           d5,d1
               muls             d1,d0
               move.l           d0,a4                          ; a1_i

               move.l           d6,d0
               sub.l            d4,d0
               move.l           d0,a5                          ; a2_i

               move.l           d6,d0
               sub.l            d5,d0
               asr.l            #1,d0
               move.l           d0,a1                          ; b0_i

               move.l           d6,d0
               sub.l            d5,d0
               move.l           d0,a2                          ; b1_i

               asr.l            #1,d0
               move.l           d0,a3                          ; b2_i

.calccr        move.l           a0,d6                          ; a0_i

               move.l           a1,d0                          ; b0_i
               swap             d0
               asr.l            #3,d0
               divs             d6,d0
               ext.l            d0
               move.l           d0,a1                          ; c1

               move.l           a2,d0                          ; b1_i
               swap             d0
               asr.l            #3,d0
               divs             d6,d0
               ext.l            d0
               move.l           d0,a2                          ; c2

               move.l           a3,d0                          ; b2_i
               swap             d0
               asr.l            #3,d0
               divs             d6,d0
               ext.l            d0
               move.l           d0,a3                          ; c3

               move.l           a4,d0                          ; a1_i
               swap             d0
               asr.l            #3,d0
               divs             d6,d0
               ext.l            d0
               move.l           d0,a4                          ; c4

               move.l           a5,d0                          ; a2_i
               swap             d0
               asr.l            #3,d0
               divs             d6,d0
               ext.l            d0
               move.l           d0,a5                          ; c5

               rts


               ; main filter loop
               ; c1-c5 in registers a1-a5
BIQUAD_SAMPLE MACRO
               move.b           (a0),d0                        ; input
               add.b            #$80,d0                        ; resign
               ext.w            d0
               muls             #64,d0                         ; extend

               move.l           d0,d6                          ; backup input

               move.w           d0,d1
               move.l           a1,d2
               muls             d2,d1

               move.w           lastin(a6),d2
               move.l           a2,d3
               muls             d3,d2

               move.w           lastlastin(a6),d3
               move.l           a3,d4
               muls             d4,d3
 
               move.w           lastout(a6),d4
               move.l           a4,d5
               muls             d5,d4

               move.w           lastlastout(a6),d5
               move.l           a5,d0
               muls             d0,d5

               add.l            d2,d1
               add.l            d3,d1
               sub.l            d4,d1
               sub.l            d5,d1                          ; d1 = output

               move.w           lastout(a6),lastlastout(a6)
               move.w           lastin(a6),lastlastin(a6)

               move.w           d6,lastin(a6)
               asl.l            #3,d1                          ; shift output back down
               swap             d1
               move.w           d1,lastout(a6)

               asr.w            #6,d1                          ; shift actual output               
               ENDM

               ; c1-c5 in registers a1-a5
biquad_main:   lea              biquad_params(pc),a6

               clr.w            lastin(a6)
               clr.w            lastlastin(a6)
               clr.w            lastout(a6)
               clr.w            lastlastout(a6)

               move.l           render_pointer,a0
               move.w           render_length,d7
               subq.w           #1,d7

.sample        BIQUAD_SAMPLE
               CLAMP_SAMPLE     d1
               add.b            #$80,d1                        ; unsign
               move.b           d1,(a0)+
               dbra             d7,.sample
               rts

                ; enveloped biquad
; stange param order this one..
; WORD - fitler position
; WORD - envelope amount
; WORD - env block (attack/hold/decay/sustatin/hold/release)
; WORD - filter type
; WROD - filter Q
biquad_env:    move.w           (a0)+,d0                       ; filter position
               move.w           (a0)+,d1                       ; envelope amount
               bsr              make_env                       ; this takes all 6 env values

               move.w           (a0)+,d7                       ; filter type
               move.w           (a0)+,d3                       ; q
               bsr              biquad_precalc

               move.l           #biquad_coeff,d1
               lea              biquad_params(pc),a6
               clr.w            lastin(a6)
               clr.w            lastlastin(a6)
               clr.w            lastout(a6)
               clr.w            lastlastout(a6)

               move.l           render_pointer,a0
               move.w           render_length,d7
               subq.w           #1,d7

               move.l           a6,d6                          ; backup param pointer
               lea              envelope_table,a6

               move.w           (a6)+,d3                       ; d3 is out env sample coutner
               move.w           (a6)+,d0

.sample        move.w           d0,d2
               mulu             #5*4,d2
               move.l           d1,a1
               movem.l          (a1,d2.w),a1-a5

               movem.l          d0-d7/a6,-(sp)
               move.l           d6,a6                          ; move param pointer back in
               BIQUAD_SAMPLE
               CLAMP_SAMPLE     d1
               add.b            #$80,d1                        ; unsign
               move.b           d1,(a0)+
               movem.l          (sp)+,d0-d7/a6

               subq.w           #1,d3
               bcc.b            .contenv 
               move.w           (a6)+,d3
               move.w           (a6)+,d0
.contenv   
               dbra             d7,.sample
               rts



              ; d7 = filter type
              ; d3 = q
biquad_precalc:
               movem.l          d0-a6,-(sp)
               moveq            #0,d0                          ; freq coutner                       
               move.w           #freq_positions-1,d6
               lea              biquad_coeff,a0
.loop          movem.l          a0/d0-d7,-(sp)
               bsr              biquad_calc
               movem.l          (sp)+,a0/d0-d7
               movem.l          a1-a5,(a0)                     ; store co-effs
               lea              5*4(a0),a0
               addq.w           #1,d0
               dbra             d6,.loop
               movem.l          (sp)+,d0-a6
               rts



; biquad variables
               RSRESET
lastin         rs.w             1
lastlastin     rs.w             1
lastout        rs.w             1
lastlastout    rs.w             1
biquad_sizeof  rs.w             0

biquad_params  dcb.b            biquad_sizeof,0


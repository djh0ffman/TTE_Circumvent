; thanks blueberry ;)

; instrument parameters:

; short mpitch, mod, bpitch
; short attack, distortions, decay
; short mpitchdecay, moddecay, bpitchdecay

; Sample state:
; long mpitch, mod, bpitch
; short ampdelta,amp

; inbound from generator
; a0 = param chunk

; needed for cinter
; a2 = instrument data
; a4 = output buffer
; d5 = render length

cinter:
            move.l            a0,a2                  ; move param chunk pointer
            move.l            render_pointer,a4
            moveq             #0,d5
            move.w            render_length,d5

            lea               sinus,a0
            lea               cinter_state(pc),a6

            lea               clamp2u,a5

			; Init state
            move.l            a6,a1
            rept              3
            move.w            (a2)+,(a1)+
            clr.w             (a1)+
            endr
            move.w            (a2)+,(a1)+
            clr.w             (a1)+

            clr.w             (a4)+
            subq.l            #2,d5
            moveq.l           #0,d6                  ; Index
.sampleloop:

			; Distortion parameters
            move.l            a2,a3
            move.w            (a3)+,d4

			; Modulation wave
            move.l            a6,a1
            move.w            d6,d2
            move.l            (a1)+,d0
            lsr.l             #2,d0
            CINTER_LONGMUL
.mdist:     lsr.w             #2,d0
            add.w             d0,d0
            move.w            (a0,d0.w),d0
            sub.w             #$1000,d4
            bcc.b             .mdist
            lsl.w             #4,d4

			; Modulation strength
            move.w            d0,d2
            add.w             #$8000,d2
            move.l            (a1),d3
            lsr.l             #3,d3
            move.l            (a1)+,d0
            lsr.l             #2,d0
            CINTER_LONGMUL
            sub.l             d0,d3

			; Base wave
            move.w            d6,d2
            move.l            (a1)+,d0
            lsr.l             #2,d0
            CINTER_LONGMUL
            sub.l             d3,d0                  ; Modulation
.bdist:     lsr.w             #2,d0
            add.w             d0,d0
            move.w            (a0,d0.w),d0
            sub.w             #$1000,d4
            bcc.b             .bdist
            lsl.w             #4,d4

			; Amplitude
            move.w            (a1)+,d1
.vpower:    muls.w            0(a1),d0               ; Dummy offset for better compression
            add.l             d0,d0
            swap.w            d0
            sub.w             #$1000,d4
            bcc.b             .vpower
            lsl.w             #4,d4

			; Final distortion
            bra.b             .fdist_in
.fdist:     lsr.w             #2,d0
            add.w             d0,d0
            move.w            (a0,d0.w),d0
.fdist_in:  sub.w             #$1000,d4
            bcc.b             .fdist

			; Write sample
            add.w             d0,d0
            bvc.b             .notover
            subq.w            #1,d0
.notover:   lsr.w             #8,d0

            moveq             #0,d2                  ; clear accumulator
            move.b            (a4),d2                ; get buffer
            add.b             #$80,d0                ; unsign cuz reasons
            add.w             d0,d2
            move.b            (a5,d2.w),(a4)+
            ;move.b            d0,(a4)+               ; output

			; Attack-Decay
            move.w            (a3)+,d2
            sub.w             d1,(a1)
            bvc.b             .nottop
            move.w            #32767,(a1)
            move.w            d2,-(a1)
.nottop:    bpl.b             .notzero
            clr.w             (a1)
.notzero:
			; Pitch and mod decays
            move.l            a6,a1
            rept              3
            move.l            (a1),d0
            move.w            (a3)+,d2
            beq.b             *+22                   ; Optimization, can be omitted
            CINTER_LONGMUL
            tst.w             d2
            bmi.b             *+4
            add.l             (a1),d0
            move.l            d0,(a1)+
            endr

            addq.l            #1,d6
            cmp.l             d5,d6
            blt.w             .sampleloop

            rts

cinter_state:
            dcb.l             6,0

	
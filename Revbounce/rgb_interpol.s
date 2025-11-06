
; define rgb_interpoltable as an offset to rgb_interpoltable_sizeof
; bytes in an area pointed to by a4 when calling these functions.

rgb_interpoltable_sizeof	=	2*31*16		; [-15..15]x[0..15] words

; d0.w: start color #rgb
; d1.w: end color #rgb
; d2.w:	step (0-15)
; out: d0.w: color #rgb
; a4: area for 
rgb_build_interpoltable:
	lea	(rgb_interpoltable,a4),a0
	moveq	#-15,d7
.LoopColor:
	moveq	#0,d6
.LoopScale:
	move.w	d7,d0
	muls.w	d6,d0
	divs.w	#15,d0
	move.b	d0,(a0)+
 	asl.b	#4,d0
 	move.b d0,(a0)+
	addq.w	#1,d6
	cmp.w	#16,d6
	bne.b	.LoopScale
	addq.w	#1,d7
	cmp.w	#16,d7
	bne.b	.LoopColor
	rts

rgb_interpolate:
	move.w	d3,-(a7)		; 8
	move.w	d4,-(a7)		; 8
	move.w	#$0f0,d3		; 8
	add.w	d3,d2			; 4
	add.w	d2,d2			; 4

	move.w	d3,d4			; 4
	and.w	d0,d3			; 4
	and.w	d1,d4			; 4
	sub.w	d3,d4			; 4
	add.w	d4,d4			; 4
	add.w	d2,d4			; 4
	add.b	(rgb_interpoltable+1,a4,d4.w),d0	; 14

	move.w	#$00f,d3		; 8
	move.w	d3,d4			; 4
	and.w	d0,d3			; 4
	and.w	d1,d4			; 4
	sub.w	d3,d4			; 4
	asl.w	#4+1,d4			; 6+2*5=16
	add.w	d2,d4			; 4
	add.b	(rgb_interpoltable,a4,d4.w),d0	; 14

	move.w	d0,d3			; 4
	clr.b	d3			; 4
	clr.b	d1			; 4
	sub.w	d3,d1			; 4
	asr.w	#8-(4+1),d1		; 6+2*3=12
	add.w	d2,d1			; 4
	move.w	(rgb_interpoltable,a4,d1.w),d1	; 14
	clr.b	d1			; 4
	add.w	d1,d0			; 4

	move.w	(a7)+,d4		; 8
	move.w	(a7)+,d3		; 8
	rts				; 16

;rb_interpoltable:
;	DS.W	31*16		; [-15..15]x[0..15]
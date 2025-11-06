
; calculate the x values for a -PI to PI half circle.
; it will generate a table indexed from -r to r (i.e. 2*r+1) points with x in [0,r].

; d0.w: radius (r)
; a0: 2*r+1 byte buffer for points
rb_halfcircle:
	movem.l		d2-d6,-(sp)
	move.w		d0,d1				; x
	moveq		#0,d2				; y
	move.w		d0,d3				; t1
	lsr.w		#4,d3				; r/16
.loop
	move.w		d0,d4
	add.w		d2,d4
	move.b		d1,(a0,d4.w)		; [r+y]=x
	move.w		d0,d4
	sub.w		d2,d4
	move.b		d1,(a0,d4.w)		; [r-y]=x
	move.w		d2,d6				; d6=y
	addq.w		#1,d2
	add.w		d2,d3
	move.w		d3,d5
	sub.w		d1,d5				; t2 = t1-x
	bmi			.skip
	move.w		d0,d4
	add.w		d1,d4
	move.b		d6,(a0,d4.w)		; [r+x]=y-1
	move.w		d0,d4
	sub.w		d1,d4
	move.b		d6,(a0,d4.w)		; [r-x]=y-1
	move.w		d5,d3
	subq.w		#1,d1
.skip
	cmp.w		d1,d2
	bls			.loop
	movem.l		(sp)+,d2-d6
	rts

; calc integer square root; see https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_numeral_system_.28base_2.29
; in:d0.w: n [0,65536[
; out:d0.w: sqrt(n)
rb_square_root:
	movem.l		d2-d3,-(sp)
	moveq		#0,d2				; c
	move.w		#1<<14,d3			; d largest power of 4 <= n
.loop1:
	cmp.w		d0,d3
	bls			.loop2
	lsr.w		#2,d3
	bra			.loop1
.loop2:
	tst.w		d3
	beq			.done
	move.w		d2,d1
	lsr.w		#1,d2				; c = c/2
	add.w		d3,d1				; = c+d
	cmp.w		d1,d0
	blo			.shiftd
	sub.w		d1,d0				; x -= c+d
	add.w		d3,d2				; c = c/2 + d
.shiftd:
	lsr.w		#2,d3
	bra			.loop2
.done
	move.w		d2,d0
	movem.l		(sp)+,d2-d3
	rts

rb_NUM_ATAN_ANGLES	= 256

; in:a0:arctan table 90 degrees same res as d2
; in:d0.w:y
; in:d1.w:x
; out:d0.w:angle
rb_lookup_atan2:
.IPI				= (rb_NUM_ATAN_ANGLES/2)
	tst.w		d1
	bne			.xnonzero
	tst.w		d0
	bne			.ynonzero
	move.w		#.IPI,d0
	rts
.ynonzero:
	blt			.ynegative
	move.w		#.IPI+.IPI/2,d0
	rts
.ynegative:
	move.w		#.IPI-.IPI/2,d0
	rts
.xnonzero:
	movem.l		d2-d3,-(sp)
	asl.w		#6,d0				; 1/64th resolution as used by the c version
	move.w		d0,d2
	ext.l		d2
	divs		d1,d2
	bgt			.quotpositive
	neg.w		d2
.quotpositive:
	move.b		(a0,d2.w),d2
	ext.w		d2

	move.w		#.IPI,d3
	tst.w		d0
	bge			.ynonnegative
	neg.w		d2
	neg.w		d3
.ynonnegative:
	tst.w		d1
	blt			.xnegative
	add.w		#.IPI,d2
	move.w		d2,d0
	movem.l		(sp)+,d2-d3
	rts
.xnegative:
	sub.w		d2,d3
	add.w		#.IPI,d3
	and.w		#rb_NUM_ATAN_ANGLES-1,d3
	move.w		d3,d0
	movem.l		(sp)+,d2-d3
	rts

; a0: (sqrt(n)-radiuss)*NUM_ATAN_ANGLES -- add radius clamps when generating table - see assert in polarrender.c line 179
; a1: in/out: code emit dest
; d1.w: x [-127,127] - dont trash
; d2.w: y [-127,127] - dont trash
; d0.b: next byte?
; max radius 127
rb_sample_polar:
	movem.l		d3-d4,-(sp)

	ifeq		rb_single_radius_enable
	move.w		d1,d3
	muls		d3,d3
	move.w		d2,d4
	muls		d4,d4
	add.w		d3,d4
	add.w		d4,d4
	move.w		(a0,d4.w),d4		; d4=(sqrt(x*x + y*y)-radiuss)*NUM_ATAN_ANGLES
	else
	moveq		#0,d4	; common radius
	endif

	move.b		d0,d3
	move.w		d2,d0
	lea			rb_arctan646463(pc),a0
	bsr			rb_lookup_atan2
	add.w		d0,d4
	lea			(.sample_code,pc),a0
	tst.b		d3
	bne			.newbyte
	move.w		(.add_code,pc),(a1)+
	addq.l		#4,a0
.newbyte:
	move.l		(a0),d0
	move.w		d4,d0
	move.l		d0,(a1)+
	movem.l		(sp)+,d3-d4
	rts

.sample_code:
	move.b		1234(a0),d0
	or.b		1234(a0),d0
.add_code:
	add.b		d0,d0

; a0:sqrt for sample_polar - must be preserved
; a1:code emit dest
; in:d0.w: x1
; in:d1.w: x2
; in:d2.w: y
; in/out:d3.w: byte advance
rb_emit_span:
	movem.l		d4-d5/a2,-(sp)
	move.l		a0,a2
	move.w		d0,d4
	add.w		#rb_center_x,d4
	lsr.w		#3,d4
	add.w		d4,d3
	beq.b		.noadd
	cmp.w		#8,d3
	bhi			.leaadd
	ror.w		#16-9,d3					; lsl.w #9
	or.w		#$508a,d3					; d3: addq.l #1-8,a2
	move.w		d3,(a1)+
	bra			.noadd
.leaadd
	move.w		#$45ea,(a1)+				; lea (x,a2),a2
	move.w		d3,(a1)+
.noadd:
	neg.w		d4
	move.w		d4,d3						; byte advance = -start offset

; emit-loop
	move.w		d1,d4						; save x2
	move.w		d0,d1						; d1=x loop var
	st			d0							; new byte always true for x==x1
.loop:
	move.l		a2,a0
	bsr			rb_sample_polar				; saves d1,d2
	move.w		d1,d5
	add.w		#rb_center_x,d5
	and.w		#7,d5
	subq.w		#7,d5
	seq			d0							; new byte? (x+center_x) & 0x7 == 0
	bne			.nooutputwrite
	move.w		#$811a,(a1)+				; or.b d0,(a2)+
	subq.w		#1,d3						; byte advance -= 1
.nooutputwrite:
	addq.w		#1,d1
	cmp.w		d4,d1
	ble			.loop

	add.w		#rb_center_x,d4
	not.w		d4
	and.w		#7,d4						; d4 = 7 - ((x2 + center_x) & 0x7)
	beq			.noshift
	cmp.w		#2,d4
	bhi			.lsl
	move.w		#$d000,(a1)+				; add.b d0,d0
	subq.w		#1,d4
	beq			.skiplsl
	move.w		#$d000,(a1)+				; add.b d0,d0
	bra			.skiplsl
.lsl:
	ror.w		#16-9,d4					; lsl.w #9
	or.w		#$e108,d4					; lsl.b #<d4>,d0
	move.w		d4,(a1)+
.skiplsl
	move.w		#$811a,(a1)+				; or.b d0,(a2)+
	subq.w		#1,d3						; byte advance -= 1
.noshift:
	move.l		a2,a0
	movem.l		(sp)+,d4-d5/a2
	rts

rb_MAX_RADIUS	= 63
rb_center_x		= 64
rb_center_y		= 64

; d0.w: small radius
; d1.w: big radius
; a1: code dest
rb_generate_ring:
	movem.l		d2-d7/a2-a3,-(sp)
	move.w		d1,d6
	move.w		d0,d5
	ifeq		rb_single_radius_enable
	lea			rb_sqrt7938,a0
	bsr			.sqrt_tab_for_ring
	endif
	move.w		d5,d0
; generate half circles for the two radii
	lea			rb_circle_s+rb_MAX_RADIUS,a0
	move.l		a0,a2
	sub.w		d0,a0
	bsr			rb_halfcircle
	move.w		d6,d0						; d0: radiusg
	lea			rb_circle_g+rb_MAX_RADIUS,a0
	move.l		a0,a3
	sub.w		d0,a0
	bsr			rb_halfcircle

	move.w		#rb_center_y,d3
	sub.w		d0,d3
	mulu		#rb_framebuffer_width_b,d3		; d3: byte advance

	move.w		d0,d4						; d4: radiusg
	move.w		d0,-(sp)					; save radiusg
	neg.w		d4							; first y coord, -radiusg
	neg.w		d5							; -radiuss
	ifeq		rb_single_radius_enable
	lea			rb_sqrt7938,a0
	endif
.loop1:
	moveq		#0,d0
	move.b		(a3,d4.w),d0				; d0: x from circle_g
	neg.w		d0
	moveq		#0,d1
	move.b		(a3,d4.w),d1				; d1: x from circle_g
	move.w		d4,d2
	bsr			rb_emit_span
	add.w		#rb_framebuffer_width_b,d3
	addq.w		#1,d4
	cmp.w		d5,d4
	ble			.loop1

.loop2:
	moveq		#0,d0
	move.b		(a3,d4.w),d0				; d0: x from circle_g
	move.w		d0,d6
	neg.w		d0
	moveq		#0,d1
	move.b		(-1,a2,d4.w),d1				; d1: x from circle_s
	move.w		d1,d7
	neg.w		d1
	move.w		d4,d2
	bsr			rb_emit_span
	move.w		d7,d0					; d0: x from circle_s
	move.w		d6,d1					; d1: x from circle_g
	bsr			rb_emit_span
	add.w		#rb_framebuffer_width_b,d3
	addq.w		#1,d4
	blt			.loop2

; centerline
	moveq		#0,d0
	move.b		(a3,d4.w),d0				; d0: x from circle_g
	move.w		d0,d6
	neg.w		d0
	moveq		#0,d1
	move.b		(a2,d4.w),d1				; d1: x from circle_s
	move.w		d1,d7
	neg.w		d1
	move.w		d4,d2
	bsr			rb_emit_span
	move.w		d7,d0					; d0: x from circle_s
	move.w		d6,d1					; d1: x from circle_g
	bsr			rb_emit_span
	add.w		#rb_framebuffer_width_b,d3
	addq.w		#1,d4

	neg.w		d5							; +radiuss

.loop3:
	moveq		#0,d0
	move.b		(a3,d4.w),d0				; d0: x from circle_g
	move.w		d0,d6
	neg.w		d0
	moveq		#0,d1
	move.b		(1,a2,d4.w),d1				; d1: x from circle_s
	move.w		d1,d7
	neg.w		d1
	move.w		d4,d2
	bsr			rb_emit_span
	move.w		d7,d0					; d0: x from circle_s
	move.w		d6,d1					; d1: x from circle_g
	bsr			rb_emit_span
	add.w		#rb_framebuffer_width_b,d3
	addq.w		#1,d4
	cmp.w		d5,d4
	blt			.loop3

	move.w		(sp)+,d5					; d5: +radiusg

.loop4:
	moveq		#0,d0
	move.b		(a3,d4.w),d0				; d0: x from circle_g
	neg.w		d0
	moveq		#0,d1
	move.b		(a3,d4.w),d1				; d1: x from circle_g
	move.w		d4,d2
	bsr			rb_emit_span
	add.w		#rb_framebuffer_width_b,d3
	addq.w		#1,d4
	cmp.w		d5,d4
	ble			.loop4

	movem.l		(sp)+,d2-d7/a2-a3
	rts

;a0: table space with 1 + MAX_RADIUS*MAX_RADIUS + MAX_RADIUS*MAX_RADIUS words
;d0: small radius
.sqrt_tab_for_ring:
	moveq		#0,d2
	move.w		d0,d3							; save small radius
.isqrt:
	move.w		d2,d0
	bsr			rb_square_root
	sub.w		d3,d0
	bge			.noclamp
	moveq		#0,d0							; small radius clamp - sometimes it'll get rounded to -1
.noclamp:
	mulu		#rb_NUM_ATAN_ANGLES,d0
	move.w		d0,(a0)+
	addq.w		#1,d2
	cmp.w		#rb_MAX_RADIUS*rb_MAX_RADIUS*2,d2
	bls			.isqrt
	rts

	include		"arctan646463.s"

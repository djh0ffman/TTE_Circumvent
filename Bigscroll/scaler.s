
; d0.w: offset for start pixel of render invisible
; d1.w: framebuffer width in bytes
; a0: buffer for 256 scalers of 128 words each
init_scales:
	movem.l		d2-d7/a2-a6,-(sp)
                ; scale #0 renders all pixels below the visible area (we cannot render a size of zero/nothing otherwise)
	move.w		#128-1,d7
.initnorenderscale:
	move.w		d0,(a0)+
	dbf			d7,.initnorenderscale

	move.w		#255-1,d7					; 256 scales/sizes
	moveq		#0,d0						; height: 1,3,5,... pixels
	moveq		#0,d3
.initscales:
	move.w		#-64,d4						; coord before scale
.initscale:
	move.w		d4,d2
	muls		d0,d2
	asr.l		#7,d2						; divs #128,d2
	bmi.s		.skipround
	addx.w		d3,d2						; round
.skipround:
	cmp.w		#-128,d2
	bge			.skipoutsidetop
	move.w		#-128,d2					; render pixels scaled above upper edge one line above display start
.skipoutsidetop:
	cmp.w		#128,d2
	ble			.skipoutsidebottom
	move.w		#128,d2						; render pixels scaled below lower edge one line below display stop; remember to reserve extra space for off-pixel line also
.skipoutsidebottom:
	muls		d1,d2
	move.w		d2,(a0)+
	addq.w		#1,d4
	cmp.w		#64,d4
	blt			.initscale
	addq.w		#2,d0
	dbf			d7,.initscales
	movem.l		(sp)+,d2-d7/a2-a6
	rts


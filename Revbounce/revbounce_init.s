
revbounce_discrete_init:
	movem.l		d0-d7/a0-a6,-(sp)

	lea			rb_notchlist(pc),a2
	lea			rb_ringdata,a4
.nextnotch
	move.l		(a2),d0
	bmi			.endnotch
	move.l		d0,a0
	lea			(a0,a4.l),a0	; add actual address to struct offset
	move.l		a0,(a2)+
	movem.w		(a2)+,d0-d2
	bsr			rb_generate_notch
	bra			.nextnotch
.endnotch

	ifeq		USE_PREBUILT_RINGRENDERERS

	rem ; how to make this work as an assert
	if (rs_rc_sizeof - rb_rc_sizeof2) >= 0
		error here
	endif
	erem

	lea			rb_ringcode,a5

	moveq		#7,d0
	moveq		#12,d1											; $982
	lea			(rb_ringcode1,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	moveq		#31,d0
	moveq		#35,d1											; $1c5c
	lea			(rb_ringcode5,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	moveq		#52,d0
	moveq		#58,d1											; $3fee
	lea			(rb_ringcode7,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	jsr			ClearCaches

CALLRING		macro
				jsr	((\1),a5)
				endm

	else

CALLRING		macro
				jsr	(\1)
				endm

	endif

; pre-render the three full rings
	lea			rb_full_ring_polar(a4),a0
	lea			rb_full_rings,a2
	CALLRING	rb_ringcode1
	lea			rb_full_rings,a2
	CALLRING	rb_ringcode5
	lea			rb_full_rings,a2
	CALLRING	rb_ringcode7

; ringcode for three pre-rendered rings no longer needed

	ifeq		USE_PREBUILT_RINGRENDERERS
	moveq		#13,d0
	moveq		#21,d1											; $18b6
	lea			(rb_ringcode2,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	moveq		#19,d0
	moveq		#25,d1											; $1966
	lea			(rb_ringcode3,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	moveq		#26,d0
	moveq		#30,d1											; $1838
	lea			(rb_ringcode4,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	lea			(rb_ringcode6,a5),a5

	moveq		#45,d0
	moveq		#51,d1											; $375e
	lea			(rb_ringcode6-rb_ringcode6,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts

	moveq		#59,d0
	moveq		#63,d1											; $34e6
	lea			(rb_ringcode8-rb_ringcode6,a5),a1
	bsr			rb_generate_ring
	move.w		#$4e75,(a1)+									; rts
	endif

	lea			rb_data,a4
	jsr			rgb_build_interpoltable

	movem.l		(sp)+,d0-d7/a0-a6
	rts

revbounce_init:
	movem.l		d0-d7/a0-a6,-(sp)

	lea			ScreenMem,a3
	lea			rb_data,a4
	lea			CUSTOM,a6
;	move.w		#$2,COPCON(a6)		; enable copper blitter access
	move.w		#$8240,DMACON(a6)

	move.w		#$0020,DMACON(a6)	; no sprites
	moveq		#0,d0
	move.l		d0,SPR0POS(a6)
	move.l		d0,SPR1POS(a6)
	move.l		d0,SPR2POS(a6)
	move.l		d0,SPR3POS(a6)
	move.l		d0,SPR4POS(a6)
	move.l		d0,SPR5POS(a6)
	move.l		d0,SPR6POS(a6)
	move.l		d0,SPR7POS(a6)

	bsr			rb_waitblit
	move.l		#rb_background+rb_background_width_b*rb_logo_image_offset_y*rb_background_depth,BLTAPT(a6)
	lea			(rb_c_bg_restore,a3),a0
	move.l		a0,BLTDPT(a6)
	move.w		#0,BLTAMOD(a6)
	move.w		#0,BLTDMOD(a6)
	move.l		#$ffffffff,BLTAFWM(a6)
	move.w		#0,BLTCON1(a6)
	move.w		#$09F0,BLTCON0(a6)
	move.w		#64*(rb_framebuffer_height-rb_logo_image_offset_y)*rb_background_depth+rb_background_width_b/2,BLTSIZE(a6)

	lea 		(rb_c_buffer1+3*rb_framebuffer_width_b*(98+4+8+127),a3),a0
	move.w		#3*rb_framebuffer_width_b*(98+4+8+127)/(4*3)-1,d0
	moveq		#0,d1
	moveq		#0,d2
	moveq		#0,d3
.clear:
	movem.l		d1-d3,-(a0)
	dbf			d0,.clear

	lea			(rb_c_buffer1,a3),a0
	lea			(rb_framebufferlist,a4),a1
	move.l		a0,(a1)+
	lea			(rb_c_buffer2-rb_c_buffer1,a0),a0
	move.l		a0,(a1)+
	lea			(rb_c_buffer3-rb_c_buffer2,a0),a0
	move.l		a0,(a1)+

	lea			revbounce_copperlist\.bplptr,a0
	move.l		(rb_framebufferlist+8,a4),d0
	move.l		d0,rb_buffertoshow(a4)
	move.w		d0,1*8+6(a0)
	move.w		d0,3*8+6(a0)
	swap		d0
	move.w		d0,1*8+2(a0)
	move.w		d0,3*8+2(a0)

	lea			rb_background,a1
	move.l		a1,d0
	move.w		d0,(0*8+6,a0)
	swap		d0
	move.w		d0,(0*8+2,a0)
	lea			(rb_background_width_b+rb_bounce_y_top*rb_background_depth*rb_background_width_b,a1),a1
;	lea			(rb_background_width_b,a1),a1
	move.l		a1,d0
	move.w		d0,(2*8+6,a0)
	swap		d0
	move.w		d0,(2*8+2,a0)
	; we enable the last bpl at line rb_wall_y_start, so skip data not fetched
	lea			(rb_background_width_b+(rb_wall_y_start-rb_bounce_y_top)*rb_background_depth*rb_background_width_b,a1),a1
;	lea			(rb_background_width_b,a1),a1
	move.l		a1,d0
	move.w		d0,(4*8+6,a0)
	swap		d0
	move.w		d0,(4*8+2,a0)

	move.w		#22,(rb_time,a4)
	move.w		#160-64,(rb_xpos,a4)
;	move.w		#2,(rb_xvelocity,a4)
;	move.w		#-4,(rb_angledir,a4)
;	move.w		#1,(rb_timestep,a4)

	move.l		#revbounce_copperlist,COP1LC(a6)
	move.w		#$83c0,DMACON(a6) ; bpls and copper

	movem.l		(sp)+,d0-d7/a0-a6
	rts

; d0: index of start angle
; d1: number of angle indexes to set
; d2: ring width/repetitions of angle data
; a0: target buffer
rb_generate_notch:
	subq.w		#1,d2
.loopr:			
	move.w		d0,d4
	move.w		d1,d3
.loopa:
	move.b		#1,(a0,d4.w)
	addq.b		#1,d4
	dbf			d3,.loopa
	lea			256(a0),a0
	dbf			d2,.loopr
	rts

rb_notchlist:
    dc.l        rb_ringdata2
    dc.w        256*279/360,256*(337-279)/360,rb_ring2width

    dc.l        rb_ringdata3
    dc.w        256*206/360,256*(249-206)/360,rb_ring3width
    dc.l        rb_ringdata3
    dc.w        256*95/360,256*(133-95)/360,rb_ring3width
    dc.l        rb_ringdata3
    dc.w        256*3/360,256*(19-3)/360,rb_ring3width

    dc.l        rb_ringdata4
    dc.w        256*345/360,256*(404-345)/360,rb_ring4width
    dc.l        rb_ringdata4
    dc.w        256*59/360,256*(150-59)/360,rb_ring4width
    dc.l        rb_ringdata4
    dc.w        256*163/360,256*(273-163)/360,rb_ring4width

    dc.l        rb_ringdata6
    dc.w        256*305/360,256*(367-305)/360,rb_ring6width
    dc.l        rb_ringdata6
    dc.w        256*66/360,256*(89-66)/360,rb_ring6width
    dc.l        rb_ringdata6
    dc.w        256*108/360,256*(119-108)/360,rb_ring6width
    dc.l        rb_ringdata6
    dc.w        256*180/360,256*(197-180)/360,rb_ring6width
    dc.l        rb_ringdata6
    dc.w        256*214/360,256*(225-214)/360,rb_ring6width
    dc.l        rb_ringdata6
    dc.w        256*251/360,256*(278-251)/360,rb_ring6width

    dc.l        rb_ringdata8
    dc.w        256*120/360,256*(178-120)/360,rb_ring8width
    dc.l        rb_ringdata8
    dc.w        256*306/360,256*(314-306)/360,rb_ring8width

	; reuse polar buffer after rendering 3 full rings!
    dc.l        rb_full_ring_polar
    dc.w        0,255,rb_fullringwidth

    dc.l        -1                                                                     ; end of notches

rgb_interpoltable	= rb_interpoltable
	include		"rgb_interpol.s"


;	include		"revbounce.i"

;	section		revbounce_code,code

; this may be used to run the tile wall effect on its own
rb_tiles_init:
	movem.l		d0-d7/a0-a6,-(sp)

	lea			ScreenMem,a3
	lea			rb_data,a4
	lea			CUSTOM,a6
	move.l		#revbounce_copperlist,COP1LC(a6)
;	move.w		#$2,COPCON(a6)		; enable copper blitter access
	move.w		#$8240,DMACON(a6)

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

	lea			revbounce_copperlist\.bplptr,a0
	; set bpl 2,4 to empty for now
	lea			(rb_c_buffer1,a3),a1
	move.l		a1,d0
	move.w		d0,(1*8+6,a0)
	move.w		d0,(3*8+6,a0)
	swap		d0
	move.w		d0,(1*8+2,a0)
	move.w		d0,(3*8+2,a0)

	lea			rb_background,a1
	move.l		a1,d0
	move.w		d0,(0*8+6,a0)
	swap		d0
	move.w		d0,(0*8+2,a0)
	lea			(rb_background_width_b,a1),a1
	move.l		a1,d0
	move.w		d0,(2*8+6,a0)
	swap		d0
	move.w		d0,(2*8+2,a0)
	; we enable the last bpl at line rb_wall_y_start, so skip data not fetched
	lea			(rb_background_width_b+rb_wall_y_start*rb_background_depth*rb_background_width_b,a1),a1
;	lea			(rb_background_width_b,a1),a1
	move.l		a1,d0
	move.w		d0,(4*8+6,a0)
	swap		d0
	move.w		d0,(4*8+2,a0)

	move.l		#rb_tile_pull_list,(rb_tile_to_pull,a4)
	bsr			rb_pull_tiles

	movem.l		(sp)+,d0-d7/a0-a6
	rts

rb_tiles_vbtick:
	movem.l		d2-d7/a2-a6,-(sp)

	lea			rb_data,a4
	lea			CUSTOM,a6


; two copies of bg - restore from background with logo
; bob data comes from bob image - org background but with crack line around logo (grid lines outside crack line not needed due to mask)
; bob must be masked according to crack line
; blit bob: "and" background with inverse mask, "and" bob with mask, or together, place on background
; only the area of tile which falls of the wall should be restored with logo - otherwise restore with original background

	cmp.w		#56,.time
	bgt			.do_time

	bsr			rb_advance_tiles

.do_time:
	subq.w		#1,.time
	bgt			.skip

	move.w		#56,.time
	bsr			rb_pull_tiles

.skip:
	movem.l		(sp)+,d2-d7/a2-a6
	rts

.time:
	dc.w		150

; a4: shared data ptr
; does nothing if tile instance count is zero
rb_advance_tiles:
	movem.l		d2/a1,-(sp)
	lea			(rb_tile_instances-rb_tile_sizeof,a4),a2
	move.b		(rb_tile_instance_count,a4),d2
	bra			.2
.1:
	bsr			rb_restore_background					; restore at "old" position
	move.w		(rb_tile_y,a2),d0
	add.w		(rb_tile_speed,a2),d0
	cmp.w		#rb_framebuffer_height-rb_bob_height,d0	; check if "new" position in range..
	bhs			.2										; ..skip if not
	move.w		d0,(rb_tile_y,a2)						; store "new" position
	addq.w		#1,(rb_tile_speed,a2)
	move.w		(rb_tile_dir,a2),d0
	add.w		d0,(rb_tile_x,a2)
	bsr			rb_place_bob
.2:
	addq.l		#rb_tile_sizeof,a2
	subq.b		#1,d2
	bge			.1
	movem.l		(sp)+,d2/a2
	rts

; start a new set of tiles (1-3)
; a4: shared data ptr
rb_pull_tiles:
	movem.l		d2/a2,-(sp)
	move.l		(rb_tile_to_pull,a4),d2
	beq			.end
	move.l		d2,a1
	lea			(rb_tile_instances-rb_tile_sizeof,a4),a2
	move.b		(a1)+,d2
	move.b		d2,(rb_tile_instance_count,a4)
	beq			.end
	bra			.2
.1:
	bsr			rb_pull_tile
.2:
	addq.l		#rb_tile_sizeof,a2
	subq.b		#1,d2
	bge			.1
	move.l		a1,(rb_tile_to_pull,a4)
.end:
	movem.l		(sp)+,d2/a2
	rts

; a2: tile instance pointer
rb_place_bob:
	; a bob
	; b mask
	; c bg
	; calc block address for sources/destination
	move.l		d2,-(sp)
	moveq		#rb_background_width_b*rb_background_depth,d1
	mulu		(rb_tile_y,a2),d1
	move.w		(rb_tile_x,a2),d0
	moveq		#$f,d2
	and.w		d0,d2
	ror.w		#4,d2
	lsr.w		#3,d0
	add.w		d1,d0
	bsr			rb_waitblit
	move.w		#$ffff,BLTADAT(a6)
	move.l		#rb_bob,BLTBPT(a6)
	lea			rb_background,a0
	lea			(a0,d0.w),a0
	move.l		a0,BLTCPT(a6)
	move.l		a0,BLTDPT(a6)
	move.w		#0-rb_bob_width_b,BLTBMOD(a6)
	move.w		#rb_background_width_b-2-rb_bob_width_b,BLTCMOD(a6)
	move.w		#rb_background_width_b-2-rb_bob_width_b,BLTDMOD(a6)
	move.l		#$ffff0000,BLTAFWM(a6) ; needs to match bob width
	move.w		d2,BLTCON1(a6)
	or.w		#$07CA,d2
	move.w		d2,BLTCON0(a6)
	move.w		#64*rb_bob_height*rb_bob_depth+1+rb_bob_width_b/2,BLTSIZE(a6)
	move.l		(sp)+,d2
	rts

; a2: tile instance pointer
rb_restore_background:
	moveq		#rb_background_width_b*rb_background_depth,d1
	mulu		(rb_tile_y,a2),d1
	move.w		(rb_tile_x,a2),d0
	lsr.w		#3,d0
	add.w		d1,d0
	lea			ScreenMem+rb_c_bg_restore-rb_background_width_b*rb_background_depth*rb_logo_image_offset_y,a0
	lea			(a0,d0.w),a0
	bsr			rb_waitblit
	move.l		a0,BLTAPT(a6)
	lea			rb_background,a0
	lea			(a0,d0.w),a0
	move.l		a0,BLTDPT(a6)
	move.w		#rb_background_width_b-2-rb_bob_width_b,BLTAMOD(a6)
	move.w		#rb_background_width_b-2-rb_bob_width_b,BLTDMOD(a6)
	move.l		#$ffffffff,BLTAFWM(a6)
	move.w		#$09F0,BLTCON0(a6) ; D=A
	move.w		#0,BLTCON1(a6)
	move.w		#64*rb_bob_height*rb_bob_depth+1+rb_bob_width_b/2,BLTSIZE(a6)
	rts

; a1: tile pull list pointer - is advanced to next tile/tileset
; a2: tile instance pointer
; replaces org bg with logo/wall gfx on the grid cell the tile is pulled from
rb_pull_tile:
	movem.l		d2-d4,-(sp)
	move.w		#64*rb_bob_height*rb_bob_depth+rb_bob_width_b/2,d2
	move.b		(a1)+,d0
	bge			.std_height
	move.w		#64*rb_bob_height_alternate*rb_bob_depth+rb_bob_width_b/2,d2
	neg.b		d0
.std_height:
	moveq		#0,d1
	move.b		(a1)+,d1
	ext.w		d0
	lsl.w		#3,d0
	move.w		d0,(rb_tile_x,a2)

	moveq		#1,d3
	cmp.w		#160,d0
	blo			.dir_ok
	neg.w		d3
.dir_ok:
	move.w		d3,(rb_tile_dir,a2)

	move.w		d1,(rb_tile_y,a2)
	move.w		#0,(rb_tile_speed,a2)
	move.w		d1,d4
	mulu		#rb_background_width_b*rb_background_depth,d1
	mulu		#rb_logo_image_width_b*rb_background_depth,d4
	lsr.w		#3,d0
	add.w		d0,d1
	add.w		d0,d4
	lea			rb_logo_data-rb_logo_image_width_b*rb_background_depth*rb_logo_image_offset_y-rb_logo_image_offset_x_b,a0
	lea			(a0,d4.w),a0
	bsr			rb_waitblit
	move.l		a0,BLTAPT(a6)
	lea			ScreenMem+rb_c_bg_restore-rb_background_width_b*rb_background_depth*rb_logo_image_offset_y,a0
	lea			(a0,d1.w),a0
	move.l		a0,BLTDPT(a6)
	move.w		#rb_logo_image_width_b-rb_bob_width_b,BLTAMOD(a6)
	move.w		#rb_background_width_b-rb_bob_width_b,BLTDMOD(a6)
	move.l		#$ffffffff,BLTAFWM(a6)
	move.w		#$09F0,BLTCON0(a6) ; D=A
	move.w		#0,BLTCON1(a6)
	move.w		d2,BLTSIZE(a6)
	movem.l		(sp)+,d2-d4
	rts

rb_waitblit:
;	btst		#14-8,DMACONR(a6)
.wait:
	btst		#14-8,DMACONR(a6)
	bne			.wait
	rts

******************************************************************

; number of tiles to pull at once, then coord sets for those
; zero number of tiles: end of list
; x,y
; x < 0: use alternate blit height for highlights on tile below
rb_tile_pull_list:
	dc.b		4
	dc.b		14*2,6*16
	dc.b		-15*2,7*16
	dc.b		06*2,3*16
	dc.b		-05*2,10*16
	dc.b		4
	dc.b		-07*2,3*16
	dc.b		12*2,8*16
	dc.b		07*2,6*16
	dc.b		14*2,4*16
	dc.b		4
	dc.b		10*2,6*16
	dc.b		13*2,7*16
	dc.b		04*2,5*16
	dc.b		11*2,3*16
	dc.b		3
	dc.b		15*2,6*16
	dc.b		-15*2,10*16
	dc.b		07*2,5*16
	dc.b		4
	dc.b		10*2,5*16
	dc.b		-04*2,6*16
	dc.b		05*2,6*16
	dc.b		11*2,4*16
	dc.b		3
	dc.b		08*2,6*16
	dc.b		11*2,9*16
	dc.b		-05*2,7*16
	dc.b		4
	dc.b		07*2,8*16
	dc.b		09*2,7*16
	dc.b		-13*2,5*16
	dc.b		06*2,4*16
	dc.b		4
	dc.b		11*2,7*16
	dc.b		11*2,5*16
	dc.b		13*2,8*16
	dc.b		-13*2,9*16
	dc.b		3
	dc.b		09*2,6*16
	dc.b		09*2,8*16
	dc.b		10*2,7*16
	dc.b		4
	dc.b		-11*2,10*16
	dc.b		14*2,7*16
	dc.b		08*2,4*16
	dc.b		05*2,5*16
	dc.b		3
	dc.b		09*2,5*16
	dc.b		-16*2,7*16
	dc.b		10*2,8*16
	dc.b		4
	dc.b		-04*2,8*16
	dc.b		07*2,7*16
	dc.b		15*2,5*16
	dc.b		-09*2,9*16
	dc.b		4
	dc.b		-10*2,9*16
	dc.b		08*2,5*16
	dc.b		11*2,8*16
	dc.b		-12*2,10*16
	dc.b		4
	dc.b		08*2,7*16
	dc.b		06*2,5*16
	dc.b		-07*2,9*16
	dc.b		-14*2,8*16
	dc.b		3
	dc.b		12*2,7*16
	dc.b		06*2,6*16
	dc.b		-12*2,5*16
	dc.b		4
	dc.b		12*2,9*16
	dc.b		12*2,4*16
	dc.b		-08*2,8*16
	dc.b		-06*2,7*16
	dc.b		4
	dc.b		14*2,5*16
	dc.b		-16*2,10*16
	dc.b		8*2,9*16
	dc.b		11*2,6*16

	dc.b		0
	cnop		0,2

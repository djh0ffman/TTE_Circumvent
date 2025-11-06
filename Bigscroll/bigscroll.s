
framebuffers = ScreenMem

SS_FILL_DURING_PLOT			=	1
SS_SHOW_RASTERTIME			=	0
SS_SHOW_BGTILES				=	1

	section		slicescroll_code,code

Bigscroll_discrete_init:
	movem.l		d2-d7/a2-a6,-(sp)
	lea			scales,a0
	move.w		#(SS_FRAMEBUFFER_HEIGHT_PX-2-SS_FRAMEBUFFER_CENTER_V)*SS_FRAMEBUFFER_WIDTH_B,d0
	moveq		#SS_FRAMEBUFFER_WIDTH_B,d1
	bsr			init_scales

	moveq		#SS_FRAMEBUFFER_WIDTH_B,d0
	lea			slice_renderer_offsets,a0
	bsr			init_renderers

	bsr			SS_gen_scale_seqinc
	movem.l		(sp)+,d2-d7/a2-a6
	rts

Bigscroll_init:
	movem.l		d2-d7/a0-a6,-(sp)
	lea			CUSTOM,a6
	move.w		#$0020,DMACON(a6)	; no sprites
	jsr			SS_init
	move.w		#$2,COPCON(a6)		; enable copper blitter access
	move.l		#SS_copperlist,COP1LC(a6)
	move.w		#$83c0,DMACON(a6)	; bitplane, blitter, copper
	moveq		#0,d0
	move.l		d0,SPR0POS(a6)
	move.l		d0,SPR1POS(a6)
	move.l		d0,SPR2POS(a6)
	move.l		d0,SPR3POS(a6)
	move.l		d0,SPR4POS(a6)
	move.l		d0,SPR5POS(a6)
	move.l		d0,SPR6POS(a6)
	move.l		d0,SPR7POS(a6)

	if			SS_FILL_DURING_PLOT = 1
	move.l		sequencepos(pc),a0
	jsr			SS_hacky_sin_z
	endif

	movem.l		(sp)+,d2-d7/a0-a6
	rts

Bigscroll_frame:
	movem.l		d2-d7/a2-a6,-(sp)

	ifne		SS_FILL_DURING_PLOT
	jsr			SS_render_frame
	endif

	move.l		sequencepos(pc),a0
	lea			slice_sequence_1+200,a1
	lea			slice_sequence_1_end-200,a2
	jsr			SS_advance_sequence_pos
	move.l		a0,sequencepos

; this anim uses sequence position as the center (x) slice
	jsr			SS_hacky_sin_z

	ifeq		SS_FILL_DURING_PLOT
	jsr			SS_render_frame
	endif

	ifne		SS_SHOW_RASTERTIME
	lea			CUSTOM,a6
	move.w		#$F00,COLOR00(a6)
	endif

	movem.l		(sp)+,d2-d7/a2-a6
	rts

    rem
	move.l          (animpos),a1
	bsr             SS_rot_around_y
	btst            #2,$dff016
	beq             .skipanimadvance
	cmp.l           #animend,a1
	blo.b           .animgood
	lea             (anim),a1
.animgood:
	move.l          a1,animpos
.skipanimadvance
    erem

    rem
    xref            SS_flat_z
	moveq           #127,d2
	move.w          #44,d1
	bsr             SS_flat_z
    erem


sequencepos:
				dc.l					slice_sequence_1+200
;animpos:
;				dc.l					anim

	include		"slicescroll.s"



	section		slicescroll_data,data

slice_sequence_1:
	dcb.b		400,0
	INCLUDE		"slice_sequence_example.i"
	dcb.b		700,0
slice_sequence_1_end:
	printt		"size of slice_sequence_1"
	printv		slice_sequence_1_end-slice_sequence_1

	INCDIR		"."  
	even
;anim:
;				INCLUDE					"blah.i"
animend:

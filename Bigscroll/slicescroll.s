; Main file for slicescroller


SS_FRAMEBUFFER_COUNT		=	3																			; 1/2/3
SS_FRAMEBUFFER_WIDTH_B		=	40
SS_FRAMEBUFFER_HEIGHT_PX	=	258
SS_FRAMEBUFFER_CENTER_V		=	128

SS_FRAMEBUFFER_WIDTH_PX		= (8*SS_FRAMEBUFFER_WIDTH_B)

; framebuffer layout:
; 258 total lines, one hidden above display (must be cleared+filled), two below
; 255 visible lines (line 128 center)
; currently we are showing line zero (256 lines) for diagnostics


	section		slicescroll_code,code

SS_init:
	lea			copperlist,a1
	ifne		SS_SHOW_BGTILES
	move.l		#SS_tile,d0
	move.w		d0,(bplpth+8+6-copperlist,a1)
	swap		d0
	move.w		d0,(bplpth+8+2-copperlist,a1)
	endif

	ifne		SS_FILL_DURING_PLOT
	move.l		(framebuffer_list+1*4,pc),d0
	else
	move.l		(framebuffer_list+2*4,pc),d0
	endif
	move.w		d0,(bltclear+6-copperlist,a1)
	swap		d0
	move.w		d0,(bltclear+2-copperlist,a1)
	ifne		SS_FILL_DURING_PLOT
	move.l		(framebuffer_list+2*4,pc),d0
	else
	move.l		(framebuffer_list+0*4,pc),d0
	endif
	move.l		d0,a0
	add.l		#SS_FRAMEBUFFER_WIDTH_B,d0
	move.w		d0,(bplpth+6-copperlist,a1)
	swap		d0
	move.w		d0,(bplpth+2-copperlist,a1)

	lea			(SS_FRAMEBUFFER_WIDTH_B*(SS_FRAMEBUFFER_HEIGHT_PX-2),a0),a0
	move.w		#SS_FRAMEBUFFER_WIDTH_B*(SS_FRAMEBUFFER_HEIGHT_PX-2)/(8*4)-1,d0
	moveq		#0,d1
	moveq		#0,d2
	moveq		#0,d3
	moveq		#0,d4
	moveq		#0,d5
	moveq		#0,d6
	move.l		d1,a1
	move.l		d1,a2
.clear:
	movem.l		d1-d6/a1-a2,-(a0)

	dbf			d0,.clear

	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; @param d0 
; @param a0 pointer to current position in slice sequence
; @param a1 pointer to start of slice sequence
; @param a2 pointer to end of slice sequence
; @return a0 pointer to new position in slice sequence
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SS_advance_sequence_pos:
;	addq.l					#8,a0
	lea						9(a0),a0
	cmp.l					a2,a0
	blo						.seqok
	lea						(a1),a0
.seqok:
	rts

SS_gen_scale_seqinc:
	move.w		#201-1,d7
	lea			scale_seqinc_table,a1
	moveq		#0,d0
.loop:
	move.w		d0,d1
	sub.w		#115,d1
	asl.w		#8,d1
	move.w		d1,(a1)+ ; scaler

	move.l		#16*250,d2
	move.w		d0,d1
	add.w		#11,d1	; this mainly affects the x-scale for tall sizes
	divu		d1,d2
	move.w		d2,(a1)+ ; slice offset

	addq.w		#1,d0
	dbf			d7,.loop

; scale sine by 4 to lookup above longs
	move.w		#1024-1,d7
	lea			SS_sinus,a1
.scaleloop:
	move.w		(a1),d0
	add.w		d0,d0
	add.w		d0,d0
	move.w		d0,(a1)+
	dbf			d7,.scaleloop

	rts

SS_hacky_sin_z:
    move.w		#SS_FRAMEBUFFER_WIDTH_PX/8-1,d7
	move.w		#2*1024-1,d1			; sin table length -1
	move.w		sinindex1(pc),d0
	addq.w		#3*2,d0
	move.w		d0,sinindex1
	move.w		sinindex2(pc),d2
	addq.w		#4*2,d2
	move.w		d2,sinindex2
	lea			SS_sinus,a1
	lea			sin_for_frame,a2
.sinloop:
	rept		8
	and.w		d1,d0
	and.w		d1,d2
	move.w		(a1,d0.w),d3
	add.w		(a1,d2.w),d3
	addq.w		#1*2,d0
	subq.w		#2*2,d2
	move.w		d3,(a2)+
	endr
	dbf			d7,.sinloop

	lea			scale_seqinc_table,a1
	lea			slicescale_buffer+4*SS_FRAMEBUFFER_WIDTH_PX/2,a2
	lea			(a2),a3
	lea			sin_for_frame+2*SS_FRAMEBUFFER_WIDTH_PX/2,a4
	lea			(a4),a5
	moveq		#0,d0																		; slice number, we need bits 15-8 cleared
	moveq		#0,d3						; left hand side sequence offset
	moveq		#0,d4																		; right hand side sequence offset
	moveq		#SS_FRAMEBUFFER_WIDTH_B/2-1,d7
; generates two entries per iteration
.loop:
	rept		8
	; left
	; ATT: must move decrementing data in reverse order!
	move.w		-(a4),d1
	move.l		(a1,d1.w),d1

	sub.w		d1,d3
	move.w		d3,d6
    asr.w		#6,d6
	move.b		(0,a0,d6.w),d0
	move.w		d0,d1	; store slice id
	move.l		d1,-(a2)

	; right
	move.w		(a5)+,d1
	move.l		(a1,d1.w),d1

	add.w		d1,d4
	move.w		d4,d6
	asr.w		#6,d6
	move.b		(0,a0,d6.w),d0
	move.w		d0,d1	; store slice id
	move.l		d1,(a3)+

	endr
	dbf			d7,.loop
	rts

SS_render_frame:

	; set plane pointer to latest plot buffer and start blitter fill
	; set copper to perform clear on other buffer after fill is done

  ; move current bpl pointer to blit clear destination (for next frame)
	ifne		SS_FILL_DURING_PLOT
	lea			copperlist,a1
	move.w		(bplpth+2-copperlist,a1),d1
	swap		d1
	move.w		(bplpth+6-copperlist,a1),d1
	sub.l		#SS_FRAMEBUFFER_WIDTH_B,d1
	move.w		d1,(bltclear+6-copperlist,a1)
	swap		d1
	move.w		d1,(bltclear+2-copperlist,a1)

	ifne		SS_SHOW_BGTILES
	lea			SS_tile,a0
	move.w		tile_offset,d0
	lea			(a0,d0.w),a0
	addq.w		#8,d0
	and.w		#511,d0
	move.w		d0,tile_offset
	move.l		a0,d0
	move.w		d0,(bplpth+8+6-copperlist,a1)
	swap		d0
	move.w		d0,(bplpth+8+2-copperlist,a1)
	endif

	lea			(framebuffer_list,pc),a0
	move.w		(framebuffer_index,pc),d0
	lsl.w		#2,d0
	move.l		(a0,d0.w),a0
	move.l		a0,d0
	add.l		#SS_FRAMEBUFFER_WIDTH_B,d0
	move.w		d0,(bplpth+6-copperlist,a1)
	swap		d0
	move.w		d0,(bplpth+2-copperlist,a1)

	lea			CUSTOM,a6
	move.w		#$8400,DMACON(a6)
.waitblt:
	btst		#14-8,DMACONR(a6)
	bne			.waitblt
	ifne		SS_SHOW_RASTERTIME
	move.w		#$0F0,COLOR00(a6)
	endif
	move.w		#$0400,DMACON(a6)
	move.w		#$0B5A,BLTCON0(a6)															; D=A^C
	move.w		#$0000,BLTCON1(a6)
	move.l		#-1,BLTAFWM(a6)
	move.w		#0,BLTAMOD(a6)
	move.w		#0,BLTCMOD(a6)
	move.w		#0,BLTDMOD(a6)
	move.l		a0,BLTAPT(a6)
	lea			(SS_FRAMEBUFFER_WIDTH_B,a0),a0
	move.l		a0,BLTCPT(a6)
	move.l		a0,BLTDPT(a6)
	move.w		#(SS_FRAMEBUFFER_HEIGHT_PX-3)*64+SS_FRAMEBUFFER_WIDTH_B/2,BLTSIZE(a6)
	endif

	move.w		(framebuffer_index,pc),d0
	addq.w		#1,d0														; global buffer increment
	cmp.w		#SS_FRAMEBUFFER_COUNT,d0
	blo.s		.index_ok
	moveq		#0,d0
.index_ok
	move.w		d0,framebuffer_index
	lsl.w		#2,d0
	lea			(framebuffer_list,pc),a1
	move.l		(a1,d0.w),a3
	lea			(SS_FRAMEBUFFER_WIDTH_B*SS_FRAMEBUFFER_CENTER_V,a3),a3		; vertical midpoint

	moveq		#SS_FRAMEBUFFER_WIDTH_B-1,d7

	lea			scales+128*128*2,a1											; each scale is 128 words
	lea			slice_renderer_offsets,a2

				;  a2: slice renderer offset table, a1: scalers, d1.w: scaler offset, d0.w: slice id*2
	macro					call_slice_renderer
	move.w		(a2,d0.w),d0																; 12 d0=offset to slice renderer
	lea			(a1,d1.w),a5																; 12 a5=adddress of scale
	lea			(.return\@,pc),a4
	jmp			(a2,d0.w)																	; jump to renderer
.return\@:
	endm

	lea			slicescale_buffer,a0	; 320 longs, hi word is scaler offset, lo word is slice id
	moveq		#8,d3
				; a3: bitplane, d3.b: column bit num, a2: slice renderer offset table, a1: scalers, d7.w: loops-1 
.sliceloop:
	rept		8
	move.w		(a0)+,d1
	move.w		(a0)+,d0
	add.w		d0,d0
	subq.b		#1,d3
	call_slice_renderer
	endr
	addq.w		#1,a3					; advance to next byte column
	dbf			d7,.sliceloop

	ifeq		SS_FILL_DURING_PLOT
	lea			(framebuffer_list,pc),a0
	move.w		(framebuffer_index,pc),d0
	lsl.w		#2,d0
	move.l		(a0,d0.w),a0

	lea			CUSTOM,a6
	move.w		#$8400,DMACON(a6)
.waitblt:
	btst		#14-8,DMACONR(a6)
	bne			.waitblt
	move.w		#$0400,DMACON(a6)
	move.w		#$0B5A,BLTCON0(a6)			; D=A^C
	move.w		#$0000,BLTCON1(a6)
	move.l		#-1,BLTAFWM(a6)
	move.w		#0,BLTAMOD(a6)
	move.w		#0,BLTCMOD(a6)
	move.w		#0,BLTDMOD(a6)
	move.l		a0,BLTAPT(a6)
	lea			(SS_FRAMEBUFFER_WIDTH_B,a0),a0
	move.l		a0,BLTCPT(a6)
	move.l		a0,BLTDPT(a6)
	move.w		#(SS_FRAMEBUFFER_HEIGHT_PX-3)*64+SS_FRAMEBUFFER_WIDTH_B/2,BLTSIZE(a6)

	move.l		a0,d0	; d0: first visible line

    ; move current bpl pointer to blit clear destination (for next frame)
	lea			copperlist,a1
	move.w		(bplpth+2-copperlist,a1),d1
	swap		d1
	move.w		(bplpth+6-copperlist,a1),d1
	sub.l		#SS_FRAMEBUFFER_WIDTH_B,d1
	move.w		d1,(bltclear+6-copperlist,a1)
	swap		d1
	move.w		d1,(bltclear+2-copperlist,a1)
    ; set buffer currently being filled as bpl pointer (for next frame)
	move.w		d0,(bplpth+6-copperlist,a1)
	swap		d0
	move.w		d0,(bplpth+2-copperlist,a1)

	ifne		SS_SHOW_BGTILES
	lea			SS_tile,a0
	move.w		tile_offset,d0
	lea			(a0,d0.w),a0
	addq.w		#8,d0
	and.w		#511,d0
	move.w		d0,tile_offset
	move.l		a0,d0
	move.w		d0,(bplpth+8+6-copperlist,a1)
	swap		d0
	move.w		d0,(bplpth+8+2-copperlist,a1)
	endif

	endif
	rts

	incdir		"."

	include		"renderer.s"

	include		"scaler.s"

framebuffer_index:
	dc.w		0
framebuffer_list:
	dc.l		framebuffers
	dc.l		framebuffers+1*SS_FRAMEBUFFER_WIDTH_B*SS_FRAMEBUFFER_HEIGHT_PX
	dc.l		framebuffers+2*SS_FRAMEBUFFER_WIDTH_B*SS_FRAMEBUFFER_HEIGHT_PX

sinindex1:
	dc.w		$29be
sinindex2:
	dc.w		$37a8

	section		slicescroll_data,data

	INCDIR		"."  

; after init_renderers has run, this data is no longer needed
slices:
	INCLUDE		"slices.i"
slices_end:

; only do this if scale_seqinc_table is initialized after renderers!
slices_size = slices_end-slices
	if			slices_size >= (4*201)
scale_seqinc_table = slices
	endif

SS_sinus:
	include		 "sin_1024_0-100w.s"

	section					slicescroll_bss,bss

;scale_seqinc_table:
;	ds.l		201	; number of possible values for number in sin_for_frame

	ifne		SS_SHOW_BGTILES
tile_offset:
	ds.w		1
	endif

sin_for_frame:
	ds.w		SS_FRAMEBUFFER_WIDTH_PX

slicescale_buffer:
	ds.w		2*SS_FRAMEBUFFER_WIDTH_PX

scales:
	ds.w		256*128

slice_renderer_offsets:
	ds.w		256
				; we should get the slice generator to output how much space actually is required (i.e. total spans and total slices)
	ds.b		256*(3*16+2)

	section		slicescroll_data_c,data,chip

SS_copperlist:
copperlist:
	ifne		SS_SHOW_BGTILES
	dc.w		BPLCON0,$2200
	else
	dc.w		BPLCON0,$1200
	endif
	dc.w		BPLCON1,$0

	dc.w		DIWSTRT,$2D81
	dc.w		DIWSTOP,$2CC1
	dc.w		DDFSTRT,$38
	dc.w		DDFSTOP,$D0

	dc.w		BPL1MOD,0
	dc.w		BPL2MOD,-40+8

	dc.w		COLOR00,$047
	dc.w		COLOR01,$fff
	dc.w		COLOR02,$036
	dc.w		COLOR03,$def

	ifne		SS_FILL_DURING_PLOT
	dc.w		$2007,$fffe															; don't remove this!
	endif
bplpth:
	dc.w		BPL1PTH,$0
	dc.w		BPL1PTL,$0
	dc.w		BPL2PTH,$0
	dc.w		BPL2PTL,$0

	dc.l		$00010000,$00010000													; double blitwait (blitwait bug)
					 ; clear using blitter
	dc.w		BLTCON0,$0100
	dc.w		BLTCON1,$0000
	dc.w		BLTDMOD,0
bltclear:
	dc.w		BLTDPTH,$0
	dc.w		BLTDPTL,$0
	dc.w		BLTSIZE,(SS_FRAMEBUFFER_HEIGHT_PX-2)*64+SS_FRAMEBUFFER_WIDTH_B/2
	ifne		SS_SHOW_RASTERTIME
	dc.w		COLOR00,$F0A
	endif

	rem ; doesn't work with bgtiles and fill during plot
	ifne		SS_SHOW_RASTERTIME
	dc.l		$00010000,$00010000													; double blitwait (blitwait bug)
	dc.w		COLOR00,$FA0
	endif
	erem

;	rem ; tile stuff
	rem
	dc.w		($2c+1*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*36 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		($2d+1*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0
;	erem
	dc.w		($2c+2*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*68 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		($2d+2*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0
;	rem
	dc.w		($2c+3*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*36 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		($2d+3*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0
	erem
	ifne		SS_SHOW_BGTILES
	dc.w		($2c+4*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*132 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		($2d+4*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0
	endif
	rem
	dc.w		($2c+5*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*36 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		($2d+5*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0
;	erem
	dc.w		($2c+6*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*68 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		($2d+6*32)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0

;	rem
	dc.w		$ffdf,$fffe

	dc.w		(($2c+7*32)&$ff)<<8+$d7,$fffe
	dc.w		BPL2MOD,-8*36 ;-SS_FRAMEBUFFER_WIDTH_B*64
	dc.w		(($2d+7*32)&$ff)<<8+$d7,$fffe
	dc.w		BPL2MOD,-40+8 ;0
	erem
;	erem

	dc.l		COPPER_HALT

	ifne		SS_SHOW_BGTILES
SS_tile:
	incbin		"backgroundtile.BPL"
	incbin		"backgroundtile.BPL"
	incbin		"backgroundtile.BPL"
	incbin		"backgroundtile.BPL"
	endif

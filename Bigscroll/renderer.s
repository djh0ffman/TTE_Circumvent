SLICE_SIZE_B			=	8


;				IF (jump_smc_template_end-plot_smc_template) != 18
;				FAIL expected slice renderer template size to be (up to) 18
;				ENDIF

; generates code which renders slices with up to 3 vertical spans.
; number of spans to render is determined during code generation.
; after the render code is generated, the slice data is no longer needed.
; a0: output buffer for slice renderer offsets followed by renderers (256 offsets (w) + )
; d0: framebuffer width in bytes
init_renderers:
			movem.l 	d2-d7/a2-a6,-(sp)
			lea			(a0),a3
			lea			slices,a1
			lea			plot_smc_template(pc),a2
			move.b		d0,15(a2)							; modify displacement (last byte) of last instruction (displacement for off-pixel)
;			lea			slice_renderer_offsets,a3
			move.l		a3,d0
			lea			2*256(a3),a0						; place renderers just after offset table
			moveq		#0,d1
			move.w		#256-1,d7
.initrenderers:
			move.l		a0,d2
			sub.l		d0,d2
			move.w		d2,(a3)+

			lea			(a1),a4

			move.b		(a4)+,d1							; on-pixel y-pos. already scaled by 2
			beq.b		.emitjumpback
			move.w		(a2),(a0)+
			move.w		d1,(a0)+
			move.l		4(a2),(a0)+
			move.b		(a4)+,d1							; off-pixel y-pos. already scaled by 2
			move.w		8(a2),(a0)+
			move.w		d1,(a0)+
			move.l		12(a2),(a0)+

			move.b		(a4)+,d1							; on-pixel y-pos. already scaled by 2
			beq.b		.emitjumpback
			move.w		(a2),(a0)+
			move.w		d1,(a0)+
			move.l		4(a2),(a0)+
			move.b		(a4)+,d1							; off-pixel y-pos. already scaled by 2
			move.w		8(a2),(a0)+
			move.w		d1,(a0)+
			move.l		12(a2),(a0)+

			move.b		(a4)+,d1							; on-pixel y-pos. already scaled by 2
			beq.b		.emitjumpback
			move.w		(a2),(a0)+
			move.w		d1,(a0)+
			move.l		4(a2),(a0)+
			move.b		(a4)+,d1							; off-pixel y-pos. already scaled by 2
			move.w		8(a2),(a0)+
			move.w		d1,(a0)+
			move.l		12(a2),(a0)+

.emitjumpback:
			move.w		jump_smc_template(pc),(a0)+
			addq.w		#SLICE_SIZE_B,a1
			dbf			d7,.initrenderers
			movem.l		(sp)+,d2-d7/a2-a6
			rts

plot_smc_template:
			move.w		$1234(a5),d0						; 12
			bchg		d3,(0,a3,d0.w)						; 18
			move.w		$2468(a5),d0						; 12
			bchg		d3,(0,a3,d0.w)						; 18 last byte is displacement
plot_smc_template_end:
jump_smc_template:
			jmp			(a4)
jump_smc_template_end:


;------------------------------
; Example inspired by Photon's Tutorial:
;  https://www.youtube.com/user/ScoopexUs
;

;---------- Includes ----------
				INCDIR								"../include"
				INCLUDE								"hw.i"
				INCLUDE								"funcdef.i"
				INCLUDE								"exec/exec_lib.i"
				INCLUDE								"graphics/graphics_lib.i"
				INCLUDE								"hardware/cia.i"
;---------- Const ----------

CIAA					=	$00bfe001
USE_PREBUILT_RINGRENDERERS=0


				section								code,code
init:

				movem.l								d0-a6,-(sp)
				move.l								4.w,a6																							; execbase
				clr.l								d0

				lea									gfxname,a1																						; librairy name
				jsr									_LVOOldOpenLibrary(a6) 
				move.l								d0,a1
				move.l								38(a1),CopperSave																				; copper list pointer to save
				jsr									_LVOCloseLibrary(a6)

				lea									CUSTOM,a6																						; adresse de base
				move.w								INTENAR(a6),INTENARSave																			; Copie de la valeur des interruptions 
				move.w								DMACONR(a6),DMACONSave																			; sauvegarde du dmacon 
				move.w								#$138,d0																						; wait for eoframe paramètre pour la routine de WaitRaster - position à attendre
				bsr.w								WaitRaster																						; Appel de la routine wait raster - bsr = jmp,mais pour des adresses moins distantes
				move.w								#$7fff,INTENA(a6)																				; désactivation de toutes les interruptions bits : valeur + masque sur 7b
				move.w								#$7fff,INTREQ(a6)																				; disable all bits in INTREQ
				move.w								#$7fff,INTREQ(a6)																				; disable all bits in INTREQ
				move.w								#$7fff,DMACON(a6)																				; disable all bits in DMACON

				move.w								#$f00,COLOR00(a6)

				jsr									revbounce_discrete_init
				jsr									revbounce_init

;				lea			rb_data,a4
;				move.l		#rb_tile_pull_list,(rb_tile_to_pull,a4)
;				jsr			rb_pull_tiles

				move.l		#VblankISR,$6c.w


				; Wait for vertical blank before enabling copper dma
				move.w		#$01,d0				;No buffering, so wait until raster
				bsr.w		WaitRaster			;is below the Display Window.
				move.w		#$0020,INTREQ(a6)
				move.w		#$8380,DMACON(a6)																				; Activation classique pour démo
				move.w		#$c020,INTENA(a6)

******************************************************************	
mainloop:
				rem
		; Wait for vertical blank
				move.w								#$01,d0			;No buffering, so wait until raster
				bsr.w								WaitRaster		;is below the Display Window.
				move.w								#$02,d0			;No buffering, so wait until raster
				bsr.w								WaitRaster		;is below the Display Window.
				erem
;----------- main loop ------------------

				jsr									revbounce_background_thread

;				jsr									revbounce_frame
;				jsr									rb_tiles_vbtick

;				clr.w								framecounter

;----------- end main loop ------------------

checkmouse:
				btst								#CIAB_GAMEPORT0,CIAA+ciapra
				bne									mainloop

exit:			lea			 CUSTOM,a6
				move.w								#$7fff,DMACON(a6)																				; disable all bits in DMACON
				or.w								#$8200,(DMACONSave)																				; Bit mask inversion for activation
				move.l								(CopperSave),COP1LC(a6)																			; Restore values
				move.w								(DMACONSave),DMACON(a6)																			; Restore values
				or									#$c000,(INTENARSave)         
				move.w								(INTENARSave),INTENA(a6)																		; interruptions reactivation
				movem.l								(sp)+,d0-a6
				clr.l								d0																								; Return code of the program
				rts																																	; End


WaitRaster:				              ;Wait for scanline d0. Trashes d1.
.l:
				move.l								$dff004,d1
				lsr.l								#1,d1
				lsr.w								#7,d1
				cmp.w								d0,d1
				bne.s								.l																								;wait until it matches (eq)
				rts

VblankISR:
				movem.l								d0-d7/a0-a6,-(sp)
				addq.w								#1,framecounter
				moveq								#20,d0
				bsr 								WaitRaster
				jsr									revbounce_vbtick
				move.w								#$20,INTREQ+$dff000
				move.w								#$20,INTREQ+$dff000
				movem.l								(sp)+,d0-d7/a0-a6
				rte

gfxname:
				GRAFNAME																															; inserts the graphics library name

				EVEN

DMACONSave:		DC.w								1
CopperSave:		DC.l								1
INTENARSave:	DC.w								1

framecounter:	dc.w								0

				section bss_c,bss,chip

ScreenMem:
				ds.b	rb_c_sizeof

	include	"revbounce.s"
				
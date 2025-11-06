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

				section								code,code
init:
				movem.l								d0-a6,-(sp)
				move.l								4.w,a6																							; execbase
				clr.l								d0

				lea									gfxname(pc),a1																						; librairy name
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

				jsr		Bigscroll_discrete_init

				jsr		Bigscroll_init

; Activate Copper list
;				move.w								#$83c0,DMACON(a6)																				; Activation classique pour démo

******************************************************************	
mainloop:

		; Wait for vertical blank
				move.w								#$01,d0																							;No buffering, so wait until raster
				bsr.w								WaitRaster																						;is below the Display Window.

;----------- main loop ------------------

				jsr									Bigscroll_frame

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
				clr									d0																								; Return code of the program
				rts																																	; End

WaitRaster:				              ;Wait for scanline d0. Trashes d1.
.l:
				move.l								$dff004,d1
				lsr.l								#1,d1
				lsr.w								#7,d1
				cmp.w								d0,d1
				bne.s								.l																								;wait until it matches (eq)
				rts
******************************************************************

gfxname:
				GRAFNAME																															; inserts the graphics library name

				EVEN

DMACONSave:		DC.w								1
CopperSave:		DC.l								1
INTENARSave:	DC.w								1

	include		"bigscroll.s"


	section					bss_c,bss,chip

ScreenMem:
	ds.b					SS_FRAMEBUFFER_COUNT*SS_FRAMEBUFFER_WIDTH_B*SS_FRAMEBUFFER_HEIGHT_PX

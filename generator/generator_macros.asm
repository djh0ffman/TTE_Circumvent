

CINTER_LONGMUL	MACRO
            move.w     d0,d1
            swap.w     d0
            mulu.w     d2,d0
            mulu.w     d2,d1
            clr.w      d1
            swap.w     d1
            add.l      d1,d0
            endm

; 1 = data register sample
CLAMP_SAMPLE MACRO
            cmp.w      #$7f,\1
            ble.b      .\@notover
            moveq      #$7f,\1
.\@notover  cmp.w      #-$7f,\1
            bge.b      .\@notunder
            moveq      #-$7f,\1
.\@notunder     

            endm

CLAMP_UBYTE MACRO
            cmp.w      #$ff,\1
            ble.b      .\@notover
            move.w     #$ff,\1
.\@notover  cmp.w      #0,\1
            bge.b      .\@notunder
            moveq      #0,\1
.\@notunder     
            endm

; calc rate
; 1 = base period
; 2 = destination period
; 3 = temp 

CALCDELTA32 MACRO
            swap       \1                   ; clear top half as div uses 32 bits
            clr.w      \1
            swap       \1
            move.l     \1,-(sp)             ; backup render period
            divu       \2,\1                ; divide the periods
            swap       \1                   ; swap to remainder in lower
            tst.w      \1                   ; test if remainder exists
            beq.b      .\@nofraction        ; no remainder, skip on..
            moveq      #0,\3                ; clear 
            move.w     \1,\3                ; copy remainder to working register
	
            mulu       #$8000,\3            ; multiply remainder
            divu       \2,\3                ; divide by original value
            asl.w      #1,\3                ; shift up the edge
            move.w     \3,\1                ; copy in fraction
.\@nofraction
            move.l     \1,\2
            move.l     (sp)+,\1
            ENDM



CALCDELTA32S MACRO
            movem.l    \1/\3,-(sp)          ; backup 1 and 3
            divs       \2,\1                ; divide the periods
            swap       \1                   ; swap to remainder in lower
            tst.w      \1                   ; test if remainder exists
            beq.b      .\@nofraction        ; no remainder, skip on..
            moveq      #0,\3                ; clear 
            move.w     \1,\3                ; copy remainder to working register
	
            muls       #$4000,\3            ; multiply remainder
            divs       \2,\3                ; divide by original value
            asl.w      #2,\3                ; shift up the edge
            move.w     \3,\1                ; copy in fraction
.\@nofraction
            move.l     \1,\2
            movem.l    (sp)+,\1/\3
            ENDM

; divide with 16:16 result
; \1 = value
; \2 = divider
; \3 = result
; \4 = temp1
; \5 = temp2

DIVIDE32 MACRO
            movem.l    \1/\2/\4/\5,-(sp)
            swap       \1                   ; move val << 16
            divu       \2,\1                ; divide
            bvc.b      .\@ready             ; has worked, go lets go

            swap       \1                   ; do manual division
            move.w     \1,\5                ; backup original value
            divu       \2,\1
            swap       \1                   ; move main to upper
            moveq      #0,\4                ; clear fraction temp
            move.w     \1,\4                ; move in fraction

            mulu.w     #$8000,\4            ; mul up
            divu.w     \5,\4                ; divide by original
            asl.w      #1,\4                ; shift up now we have decimal
            move.w     \4,\1
            bra.b      .\@go
             
.\@ready    swap       \1
            clr.w      \1
            swap       \1

.\@go         
            move.l     \1,\3                ; move result
            movem.l    (sp)+,\1/\2/\4/\5
            endm

; Note to period 
; \1 = period table address
; \2 = data reg note value word (High Byte Note Id / Low byte fine tune)
; \3 = data reg temp
; \4 = data reg temp
; \5 - data reg temp
NOTETOPERIOD MACRO
            lea        period_table,a0
            cmp.b      #0,\2
            beq.b      .\@nofine

            move.w     \2,\3                ; copy note
            ext.w      \3                   ; extend fraction
            clr.b      \2
            add.w      \3,\2                ; note should now be correct if fraction was negative

            and.w      #$007f,\3            ; clean fraction to positive
            clr.b      \2
            lsr.w      #7,\2                ; note lookup
            move.w     \2,\4              
            addq.w     #2,\4                ; note loopup + 1
          
            move.w     (\1,\2.w),\2
            move.w     (\1,\4.w),\4

            move.w     \2,\5
            sub.w      \4,\5                ; difference
            mulu       \3,\5                ; multiply fraction
            divu       #127,\5              ; now fraction diff
            sub.w      \5,\2                ; result
            bra.b      .\@quit

.\@nofine   lsr.w      #7,\2                ; note look up
            move.w     (\1,\2.w),\2
.\@quit   
            ENDM

 
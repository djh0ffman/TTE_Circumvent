
PUSHALL     MACRO
            movem.l  d0-a6,-(sp)
            ENDM

POPALL      MACRO
            movem.l  (sp)+,d0-a6
            ENDM
                   

WAITBLIT    MACRO
            tst.b    $02(a6)
.\@         btst     #6,$02(a6)
            bne.b    .\@
            ENDM



** jump index
** 1 = index

JMPINDEX    MACRO
            add.w    \1,\1
            move.w   .\@jmplist(pc,\1.w),\1
            jmp      .\@jmplist(pc,\1.w)
.\@jmplist
            ENDM

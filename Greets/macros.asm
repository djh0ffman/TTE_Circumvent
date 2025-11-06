
PUSHALL        MACRO
               movem.l    d0-a6,-(sp)
               ENDM

POPALL         MACRO
               movem.l    (sp)+,d0-a6
               ENDM

PUSHMOST       MACRO
               movem.l    d0-a4,-(sp)
               ENDM

POPMOST        MACRO
               movem.l    (sp)+,d0-a4
               ENDM


PUSHM          MACRO
               movem.l    \1,-(sp)
               ENDM

POPM           MACRO
               movem.l    (sp)+,\1
               ENDM
                                               
RANDOMWORD     MACRO
               move.l     d1,-(sp)
               move.l     RandomSeed(a5),d0
               move.l     d0,d1
               swap.w     d0
               mulu.w     #$9D3D,d1
               add.l      d1,d0
               move.l     d0,RandomSeed(a5)
               clr.w      d0
               swap.w     d0
               move.l     (sp)+,d1
               ENDM

WAITBLITN      MACRO
               move.w     #BLITPRI_ENABLE,DMACON(a6)
               tst.b      $02(a6)
.\@            btst       #6,$02(a6)
               bne.b      .\@
               move.w     #BLITPRI_DISABLE,DMACON(a6)                
               ENDM


PART_LIFE      MACRO
               subq.w     #1,(a0)+
               bpl        .\@alive
               move.w     d1,(a1)+
               addq.w     #1,d2                          ; inc dead particle counter
.\@alive
               addq.w     #2,d1                          ; dead id x2
               ENDM

** pointer rotate long  
** 1 = address register
** 2 = count

ROTATE_LONG    MACRO 

               ifeq       \2-7
               move.l     (\2-1)*4(\1),d7
               movem.l    (\1)+,d0/d1/d2/d3/d4/d5
               addq.l     #4,\1
               movem.l    d0/d1/d2/d3/d4/d5,-(\1)
               move.l     d7,-(\1)
               endif

               ifeq       \2-6
               move.l     (\2-1)*4(\1),d7
               movem.l    (\1)+,d0/d1/d2/d3/d4
               addq.l     #4,\1
               movem.l    d0/d1/d2/d3/d4,-(\1)
               move.l     d7,-(\1)
               endif

               ifeq       \2-5
               move.l     (\2-1)*4(\1),d7
               movem.l    (\1)+,d0/d1/d2/d3
               addq.l     #4,\1
               movem.l    d0/d1/d2/d3,-(\1)
               move.l     d7,-(\1)
               endif

               ifeq       \2-4
               move.l     (\2-1)*4(\1),d7
               movem.l    (\1)+,d0/d1/d2
               addq.l     #4,\1
               movem.l    d0/d1/d2,-(\1)
               move.l     d7,-(\1)
               endif

               ifeq       \2-3
               move.l     (\2-1)*4(\1),d7
               movem.l    (\1)+,d0/d1
               addq.l     #4,\1
               movem.l    d0/d1,-(\1)
               move.l     d7,-(\1)
               endif

               ifeq       \2-2
               movem.l    (\1)+,d0/d1
               exg        d0,d1
               movem.l    d0/d1,-(\1)
               endif

               ENDM

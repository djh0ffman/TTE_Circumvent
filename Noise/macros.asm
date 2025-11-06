
PUSHALL       MACRO
              movem.l    d0-a6,-(sp)
              ENDM

POPALL        MACRO
              movem.l    (sp)+,d0-a6
              ENDM
                   
RANDOMWORD    MACRO
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

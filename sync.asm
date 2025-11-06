
Sync:
    lea       SampleTrigger(a5),a1
    move.w    #SYNC_COL_COUNT-2,d5
    lea       SyncKick(a5),a0
    cmp.w     #5,(a1)
    beq       .trigger
    lea       SyncSnare(a5),a0
    cmp.w     #6,(a1)
    beq       .trigger
    bra       .notrigger

.trigger
    move.w    d5,(a0)
    clr.w     (a1)
.notrigger
    lea       SyncPal(pc),a0
    move.w    SyncKick(a5),d0
    move.w    SyncSnare(a5),d1
    move.w    (a0,d0.w),cpKickColor+2
    move.w    (a0,d1.w),cpSnareColor+2

    tst.w     SyncKick(a5)
    beq       .skipkick
    subq.w    #2,SyncKick(a5)
.skipkick
    tst.w     SyncSnare(a5)
    beq       .skipsnare
    subq.w    #2,SyncSnare(a5)
.skipsnare
    rts

SYNC_COL_COUNT = SyncPalEnd-SyncPal

SyncPal:
    dc.w      $a22,$b22,$c33,$c44,$e55,$e66,$f88,$faa
SyncPalEnd

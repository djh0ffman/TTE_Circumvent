; const
BLITPRI_ENABLE  = $8400                ; enable blitter priority
BLITPRI_DISABLE = $0400                ; disable blitter priority
; frames counts
FRM_NOTE        = 7
FRM_BEAT        = FRM_NOTE*4
FRM_BAR         = FRM_BEAT*4
                    RSRESET
RandomSeed:         rs.l       1
TickCounter:        rs.w       1
TopazPtr:           rs.l       1
TopazMod:           rs.w       1

Tunnel_Pos:         rs.w       1
Tunnel_Sine:        rs.w       1
Tunnel_ZStep:       rs.w       1
Tunnel_WallId:      rs.w       1
Tunnel_Points:      rs.w       1


SampleTrigger       rs.w       1
;Tunnel_PointDelta:         rs.w       1
;Tunnel_PointDeltaNext:     rs.w       1
;Tunnel_PointDeltaCount:    rs.w       1
;Tunnel_PointDeltaDelta:    rs.w       1

RandomList:         rs.w       1024


sys_gfxbase:        rs.l       1
Variables_Sizeof    rs.w       0
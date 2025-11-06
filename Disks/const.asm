; const
; frames counts
FRM_NOTE = 7
FRM_BEAT = FRM_NOTE*4
FRM_BAR  = FRM_BEAT*4

                    RSRESET
RandomSeed:         rs.l     1
SampleTrigger:      rs.w     1
SamplePointer:      rs.l     1
SampleVolume:       rs.w     1
TickCounter:        rs.w     1
Variables_Sizeof    rs.w     0
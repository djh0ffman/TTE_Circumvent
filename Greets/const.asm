; const

                       RSRESET
RandomSeed:            rs.l       1

; - greets variables

ParticlesLive:         rs.w       1 
SparticlesLive:        rs.w       1
ParticleLifeList:      rs.w       MAX_OBJECT_POINTS
RandomFrame:           rs.w       1
ForeBufferPtr:         rs.l       4                    ; foreground buffers	
ParticleYLookUpNeg:    rs.w       DISPLAY_HEIGHT
ParticleYLookUp:       rs.w       DISPLAY_HEIGHT*2
ParticleMax:           rs.w       1
PointBufferPtr:        rs.l       1
GreetsCharPtrs:        rs.l       2
GreetsPointPtrs:       rs.l       2
GreetsActive:          rs.w       1
DemoEnabled:           rs.w       1
MusicEnabled:          rs.w       1
TickCounter:           rs.w       1
VBlankPtr:             rs.l       1
CopperIntPtr:          rs.l       1
Variables_Sizeof       rs.w       0


                         RSRESET
GreetChar_PosX:          rs.l       1
GreetChar_PosY:          rs.l       1
GreetChar_OffsetX:       rs.w       1
GreetChar_SinePos:       rs.w       1
GreetChar_PosXActual:    rs.w       1
GreetChar_Char:          rs.w       1
GreetChar_Timer:         rs.w       1
GreetChar_PointPtr:      rs.l       1
GreetChar_Sizeof:        rs.w       0


                         RSRESET
GreetCopper_Wait         rs.l       1
GreetCopper_Colors       rs.l       3
GreetCopper_Sizeof       rs.w       0



; chip ram useage
                         RSRESET
ParticleSMC:             rs.l       PARTICLES_OCS
ParticleSMCRTS:          rs.w       1
ParticlePositions:       rs.w       (PARTICLES_MAX_GUARD)*2            ; x / y positions of particles
SparticlePositions:      rs.w       (PARTICLES_MAX_GUARD)*2            ; x / y positions of particles
SparticleFlicker:        rs.w       PARTICLES_MAX_GUARD+32
;ForeBufferA_Guard:     rs.b       FORE_VERT_GUARD_SIZE
ForeBufferA:             rs.b       FORE_SIZE
;ForeBufferB_Guard:     rs.b       FORE_VERT_GUARD_SIZE
ForeBufferB:             rs.b       FORE_SIZE
;ForeBufferC_Guard:     rs.b       FORE_VERT_GUARD_SIZE
ForeBufferC:             rs.b       FORE_SIZE
;ForeBufferD_Guard:     rs.b       FORE_VERT_GUARD_SIZE
FloorPlane1:             rs.b       FLOOR_PLANE_SIZE
FloorPlane2:             rs.b       FLOOR_PLANE_SIZE
FloorPlane1B:            rs.b       FLOOR_PLANE_SIZE
FloorPlane2B:            rs.b       FLOOR_PLANE_SIZE
GreetCopperGrad:         rs.b       ((GreetCopper_Sizeof*64)*2)+4*4
Greets_ChipSize          rs.w       0


FLOOR_WIDTH            = 320
FLOOR_WIDTH_BYTE       = FLOOR_WIDTH/8
FLOOR_WIDTH_WORD       = FLOOR_WIDTH/16
FLOOR_HEIGHT           = 128
FLOOR_DEPTH            = 2
FLOOR_PLANE_SIZE       = FLOOR_WIDTH_BYTE*FLOOR_HEIGHT
FLOOR_SIZE             = FLOOR_PLANE_SIZE*FLOOR_DEPTH
FLOOR_MODULO           = 0

PARTICLE_SMC           = ScreenMem+ParticleSMC
PARTICLE_SMCRTS        = ScreenMem+ParticleSMCRTS
PARTICLE_POS           = ScreenMem+ParticlePositions
SPARTICLE_POS          = ScreenMem+SparticlePositions
SPARTICLE_FLICKER      = ScreenMem+SparticleFlicker
GREET_COPPER_GRAD      = ScreenMem+GreetCopperGrad

FORE_BLIT_MOD          = FORE_WIDTH_BYTE-DISPLAY_WIDTH_BYTE
FORE_BLIT_SIZE         = ((DISPLAY_HEIGHT*DISPLAY_DEPTH)<<6)+DISPLAY_WIDTH_WORD ;
;FORE_HALF_BLIT_SIZE     =          (((DISPLAY_HEIGHT/2)*DISPLAY_DEPTH)<<6)+DISPLAY_WIDTH_WORD    ;
FORE_HALF_BLIT_SIZE    = ((140*DISPLAY_DEPTH)<<6)+DISPLAY_WIDTH_WORD   ;

FORE_BUFFER_A          = ScreenMem+ForeBufferA
FORE_BUFFER_B          = ScreenMem+ForeBufferB
FORE_BUFFER_C          = ScreenMem+ForeBufferC

FLOOR_PLANE1           = ScreenMem+FloorPlane1
FLOOR_PLANE2           = ScreenMem+FloorPlane2
FLOOR_PLANE1B          = ScreenMem+FloorPlane1B
FLOOR_PLANE2B          = ScreenMem+FloorPlane2B

FORE_SIZE              = FORE_WIDTH_BYTE*FORE_HEIGHT*DISPLAY_DEPTH
FORE_MODULO            = (FORE_WIDTH_BYTE*DISPLAY_DEPTH)-DISPLAY_WIDTH_BYTE

PARTICLES_FLICKER_TIME = 7                                             ; half a beat
PARTICLE_OBJECT_LIFE   = 7*2

PARTICLES_OCS          = PARTICLES_MAX
PARTICLES_MAX          = 900
PARTICLES_MAX_GUARD    = PARTICLES_MAX+10

BLITPRI_ENABLE         = $8400                                         ; enable blitter priority
BLITPRI_DISABLE        = $0400                                         ; disable blitter priority

MAX_OBJECT_POINTS      = 16*16

FORE_WIDTH             = 512
FORE_WIDTH_BYTE        = FORE_WIDTH/8
FORE_HEIGHT            = 256
FORE_STRIDE            = FORE_WIDTH_BYTE*DISPLAY_DEPTH
GUARD_WIDTH            = FORE_WIDTH-DISPLAY_WIDTH
GUARD_WIDTH_BYTE       = GUARD_WIDTH/8
GUARD_WIDTH_WORD       = GUARD_WIDTH/16

FORE_VERT_GUARD        = 64
FORE_VERT_GUARD_SIZE   = FORE_VERT_GUARD*FORE_WIDTH_BYTE*DISPLAY_DEPTH

DISPLAY_WIDTH          = DISPLAY_WIDTH_TILES*TILE_WIDTH
DISPLAY_WIDTH_BYTE     = DISPLAY_WIDTH/8
DISPLAY_WIDTH_WORD     = DISPLAY_WIDTH/16

TILE_WIDTH             = 16
TILE_HEIGHT            = 16
DISPLAY_WIDTH_TILES    = 20                                            ; visible tiles
DISPLAY_HEIGHT_TILES   = 16        
DISPLAY_DEPTH          = 2
DISPLAY_HEIGHT         = DISPLAY_HEIGHT_TILES*TILE_HEIGHT


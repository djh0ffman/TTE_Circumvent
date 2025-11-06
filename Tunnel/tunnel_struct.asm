


                     RSRESET
TunnelCop_Wait       rs.l       1                 
TunnelCop_Scroll     rs.l       1
TunnelCop_BplMod     rs.l       1
TunnelCop_WaitEnd    rs.l       1                 
TunnelCop_Sizeof     rs.w       0

TUNNELCOP_SIZE         = (TunnelCop_Sizeof*TUNNEL_HEIGHT)+2*4

                     RSRESET
Param_Value          rs.w       1
Param_Current        rs.w       1
Param_Next           rs.w       1
Param_Diff           rs.w       1
Param_Angle          rs.w       1
Param_Step           rs.w       1
Param_Count          rs.w       1
Param_Active         rs.w       1
Param_Sizeof         rs.w       1

                     RSRESET
TunnelCopper1        rs.b       TUNNELCOP_SIZE
TunnelCopper2        rs.b       TUNNELCOP_SIZE
TunnelPlanes         rs.b       TUNNEL_PLANE_SIZE*TUNNEL_BUFFERS
SolidPlanes          rs.b       TUNNEL_PLANE_SIZE*SOLID_BUFFERS
TunnelSizeof         rs.w       0

TUNNEL_PLANES          = ScreenMem+TunnelPlanes
SOLID_PLANES           = ScreenMem+SolidPlanes

TUNNEL_BOX_SIZE        = 350
TUNNEL_DEPTH           = 4
TUNNEL_ZSTEP           = 70
TUNNEL_TWIST           = 20
TUNNEL_ROT_COUNT       = 1024

TUNNEL_WIDTH           = 256
TUNNEL_WIDTH_BYTE      = TUNNEL_WIDTH/8
TUNNEL_WIDTH_WORD      = TUNNEL_WIDTH/16
TUNNEL_HEIGHT          = 256
TUNNEL_BUFFERS         = 3
TUNNEL_PLANE_SIZE      = TUNNEL_WIDTH_BYTE*TUNNEL_HEIGHT
TUNNEL_CLEAR_BLIT_SIZE = (TUNNEL_HEIGHT<<6)+TUNNEL_WIDTH_WORD

SOLID_BUFFERS          = 3

TUNNEL_CENTER_X        = TUNNEL_WIDTH/2
TUNNEL_CENTER_Y        = TUNNEL_HEIGHT/2


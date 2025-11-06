
                             RSRESET
Logo_Plane1                  rs.l       1                      
Logo_Plane2                  rs.l       1
Logo_Color1                  rs.w       1
Logo_Color2                  rs.w       1
Logo_Color3                  rs.w       1
Logo_Sizeof                  rs.w       0


                             RSRESET
DisksChip_SpriteBanks        rs.b       SPRITE_MAX_SIZE*SPRITE_COUNT
DisksChip_Planes             rs.b       DISK_SCREEN_SIZE
DisksChip_WavePlane          rs.b       DISK_WAVE_PLANE_SIZE
DisksChip_CopperBuffer1      rs.b       DISK_COPPER_TOTAL
DisksChip_CopperBuffer2      rs.b       DISK_COPPER_TOTAL
DisksChip_CopperBufferRes    rs.b       DISK_COPPER_TOTAL
DisksChip_Sizeof             rs.w       0

                             RSRESET
DiskSprite_BasePointer       rs.l       1
DiskSprite_CurrentPointer    rs.l       1
DiskSprite_BackupLine        rs.l       1
DiskSprite_Pos               rs.l       1
DiskSprite_Length            rs.w       1
DiskSprite_Delta             rs.l       1
DiskSprite_Height            rs.l       1
DiskSprite_PosLeft           rs.w       1
DiskSprite_PosRight          rs.w       1
DiskSprite_Sizeof            rs.w       0




                             RSRESET
DiskCopper_WaitEdge          rs.l       1                               ;    dc.w       $2b01,$ff00                                      ; wait line

DiskCopper_LogoPlanes        rs.l       4

; -- wave stuff
DiskCopper_CopyStart         rs.w       0
DiskCopper_Planes            rs.l       4
DiskCopper_WaveColor         rs.l       2                               ; color01 & color03
DiskCopper_CopyEnd           rs.w       0

DiskCopper_PosLeft           rs.l       SPRITE_COUNT                    ;    dc.w       SPR0POS,SPRITE1_POSL

DiskCopper_LogoColors        rs.l       9

DiskCopper_WaitCenter        rs.l       1                               ;    dc.w       $0081,$fffe
DiskCopper_PosRight          rs.l       SPRITE_COUNT                    ;    dc.w       SPR0POS,SPRITE1_POSR



;DiskCopper_WaitEnd           rs.l       1                               ;    dc.w       $80df,$80fe                                      ; wait for end of line
DiskCopper_Sizeof            rs.w       0


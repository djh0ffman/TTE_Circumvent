
                        RSRESET
NoiseCopper_Wait:       rs.l       1
NoiseCopper_Planes:     rs.l       NOISE_SCREEN_DEPTH*2
NoiseCopper_WaitEnd:    rs.l       1
NoiseCopper_Sizeof:     rs.w       0

                        RSRESET
NoiseChip_RandPlane:    rs.b       NOISE_SIZE_BYTES
NoiseChip_Copper:       rs.l       NoiseCopper_Sizeof*NOISE_SCREEN_HEIGHT
NoiseChip_CopperEnd:    rs.l       2
NoiseChip_Sizeof:       rs.w       0




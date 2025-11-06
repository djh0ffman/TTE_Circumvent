
AR_WIDTH      = 640
AR_WIDTH_BYTE = AR_WIDTH/8
AR_HEIGHT     = 256
AR_DEPTH      = 1
AR_SIZE       = AR_WIDTH_BYTE*AR_HEIGHT*AR_DEPTH

              RSRESET
AR_Screen:    rs.b       AR_SIZE
AR_Sizeof:    rs.w       0

    section  main_chipram,bss_c
; tunnel background
; 128 > 128 down
;
Tunnel_BKGFix:
    ds.b     (256/8)*128*2

ScreenOffset:
    ds.b     BANNER_SCREEN_WIDTH_BYTE*4
ScreenMem:
    ds.b     $24000
    ;ds.b       HOFFBANNER_PLANE_SIZE,0

ScreenMemEnd:

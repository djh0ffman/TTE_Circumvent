; mem fast

; ram area
    section    main_bss_fast,bss

Variables:
    ds.b       Vars_sizeof
VariablesEnd:

RandomList:       
    ds.w       1024

FontTopaz:
    ds.b       FONT_CHAR_COUNT*8
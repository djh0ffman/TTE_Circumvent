; generator project data (all in source for some bloody reason!)

tune_instruments:
	dc.w	2						; -- Instrument
	dc.w	1667					; -- Size in words
	dc.l	instrument__noise
	dc.w	2						; -- Instrument
	dc.w	2955					; -- Size in words
	dc.l	instrument__ttebass
	dc.w	2						; -- Instrument
	dc.w	1718					; -- Size in words
	dc.l	instrument__ttekick
	dc.w	2						; -- Instrument
	dc.w	198					; -- Size in words
	dc.l	instrument__ttehat
	dc.w	2						; -- Instrument
	dc.w	1168					; -- Size in words
	dc.l	instrument__ttesnare
	dc.w	2						; -- Instrument
	dc.w	4622					; -- Size in words
	dc.l	instrument__ttewarp
	dc.w	2						; -- Instrument
	dc.w	6574					; -- Size in words
	dc.l	instrument__ttecrash
	dc.w	2						; -- Instrument
	dc.w	495					; -- Size in words
	dc.l	instrument__tteplink
	dc.w	2						; -- Instrument
	dc.w	3663					; -- Size in words
	dc.l	instrument__tteplucky
	dc.w	2						; -- Instrument
	dc.w	3815					; -- Size in words
	dc.l	instrument__ttebass_a
	dc.w	2						; -- Instrument
	dc.w	8346					; -- Size in words
	dc.l	instrument__ttebass_b
	dc.w	2						; -- Instrument
	dc.w	7969					; -- Size in words
	dc.l	instrument__downsynthlower
	dc.w	2						; -- Instrument
	dc.w	3861					; -- Size in words
	dc.l	instrument__wub1
	dc.w	2						; -- Instrument
	dc.w	2196					; -- Size in words
	dc.l	instrument__toney
	dc.w	3						; -- Unused
	dc.w	0					; -- Size in words
	dc.l	0
	dc.w	2						; -- Instrument
	dc.w	3026					; -- Size in words
	dc.l	instrument__twang
	dc.w	2						; -- Instrument
	dc.w	10986					; -- Size in words
	dc.l	instrument__reesey
	dc.w	2						; -- Instrument
	dc.w	4395					; -- Size in words
	dc.l	instrument__303test_a1
	dc.w	3						; -- Unused
	dc.w	0					; -- Size in words
	dc.l	0
	dc.w	2						; -- Instrument
	dc.w	2514					; -- Size in words
	dc.l	instrument__aressey
	dc.w	2						; -- Instrument
	dc.w	3798					; -- Size in words
	dc.l	instrument__303test_b3
	dc.w	2						; -- Instrument
	dc.w	2437					; -- Size in words
	dc.l	instrument__retro_bass
	dc.w	0						; -- Sample
	dc.w	2320					; -- Size in words
	dc.l	sample_hilead
	dc.w	2						; -- Instrument
	dc.w	2481					; -- Size in words
	dc.l	instrument__aressey_flt
	dc.w	3						; -- Unused
	dc.w	0					; -- Size in words
	dc.l	0
	dc.w	3						; -- Unused
	dc.w	0					; -- Size in words
	dc.l	0
	dc.w	3						; -- Unused
	dc.w	0					; -- Size in words
	dc.l	0
	dc.w	1						; -- DrumLoop
	dc.w	14022					; -- Size in words
	dc.l	drumloop_drums_003
	dc.w	1						; -- DrumLoop
	dc.w	18217					; -- Size in words
	dc.l	drumloop_drums_002
	dc.w	1						; -- DrumLoop
	dc.w	13964					; -- Size in words
	dc.l	drumloop_drums_001
	dc.w	1						; -- DrumLoop
	dc.w	13964					; -- Size in words
	dc.l	drumloop_drums_000

drumloop_sample_pointers:
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0					; -- spacer
	dc.w	1453				; -- size in words
	dc.l	sample_clicky_8SVX
	dc.w	0					; -- spacer
	dc.w	2763				; -- size in words
	dc.l	sample_ride_done_8SVX
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0					; -- spacer
	dc.w	1793				; -- size in words
	dc.l	sample_kick_8SVX
	dc.w	0					; -- spacer
	dc.w	1062				; -- size in words
	dc.l	sample_hat1_8SVX
	dc.w	0					; -- spacer
	dc.w	3240				; -- size in words
	dc.l	sample_oh_8SVX
	dc.w	0					; -- spacer
	dc.w	1984				; -- size in words
	dc.l	sample_snare_8SVX
	dc.w	0					; -- spacer
	dc.w	2460				; -- size in words
	dc.l	sample_shaker_8SVX
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0					; -- spacer
	dc.w	5434				; -- size in words
	dc.l	sample_blockpitch_8SVX
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0					; -- spacer
	dc.w	1351				; -- size in words
	dc.l	sample_blocksd2
	dc.w	0					; -- spacer
	dc.w	2807				; -- size in words
	dc.l	sample_blocksd3
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0
	dc.w	0			;----- not used / empty
	dc.w	0			;----- not used / empty
	dc.l	0

instrument__noise:
	dc.w	$00A0,$5013,$0001,$0004,$0000,$00FF
instrument__ttebass:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$05FE,$0003,$0200,$D8F0,$6662,$0002,$0000,$FFFE,$0000
instrument__ttekick:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$1C82,$0005,$050A,$D8F0,$0046,$0006,$FFB3,$FFF5,$FFED
instrument__ttehat:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$5FE4,$0005,$F1A2,$D8F0,$2667,$0032,$FFB3,$FFF5,$1B26
instrument__ttesnare:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$0659,$003F,$21E7,$D8F0,$0575,$0007,$FFE0,$FFF7,$FFF7
instrument__ttewarp:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$1000,$0014,$2000,$FFF9,$0612,$0002,$0000,$FFF5,$FFC0
instrument__ttecrash:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$BFC9,$0000,$F1A2,$D8F0,$2651,$0001,$FFFF,$FFF7,$1B26
instrument__tteplink:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$4000,$0056,$1000,$FE80,$0052,$0006,$0000,$FE25,$0000
instrument__tteplucky:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$4000,$0010,$0400,$FFE5,$5532,$0003,$0000,$FFF5,$FFDB
instrument__ttebass_a:
	dc.w	$00D6,$6AE3,$0002,$0014,$0004,$05FE,$0003,$0200,$D8F0,$6662,$0002,$0000,$FFFE,$0000,$0016,$0008,$0019,$00D8,$007D,$0001,$0713,$0014,$C402,$C402,$0000,$005F
instrument__ttebass_b:
	dc.w	$00A0,$5013,$0002,$0014,$0004,$05FE,$0003,$0200,$D8F0,$6662,$0000,$0000,$FFFE,$0000,$0016,$0008,$0016,$00FA,$3C67,$FFFF,$0976,$0014,$FFFF,$FFFF,$0000,$0059
instrument__downsynthlower:
	dc.w	$011D,$8EAE,$0005,$0004,$0000,$000B,$000E,$0001,$001F,$0050,$001F,$0050,$0C0E,$0CD8,$0016,$0008,$0017,$00B8,$0001,$0001,$2E27,$0000,$932D,$932D,$0001,$003A,$0004,$0005,$012C,$000E,$0002,$0001,$932D,$0D3E,$0028,$0D3E,$0D3E
instrument__wub1:
	dc.w	$00A0,$5013,$0002,$0014,$0004,$05FE,$0014,$0400,$D8F0,$5110,$0000,$0000,$0002,$0000,$0016,$0008,$0000,$00A8,$03C6,$0001,$03C6,$0000,$FFFF,$FFFF,$0000,$0064
instrument__toney:
	dc.w	$00A0,$5013,$0001,$0014,$0004,$0BFD,$0014,$0800,$D8F0,$5110,$0000,$0000,$0002,$0000
instrument__twang:
	dc.w	$00D6,$6AE3,$0002,$0014,$0004,$0400,$0017,$0400,$D8F0,$0019,$0000,$0000,$FFF4,$0000,$000E,$0002,$0001,$01F5,$0713,$0010,$08A4,$16A8
instrument__reesey:
	dc.w	$00A0,$5013,$0002,$0014,$0004,$05FE,$0002,$0400,$D8F0,$7010,$0000,$0000,$0007,$0000,$0008,$0007,$0000,$0056,$0064
instrument__303test_a1:
	dc.w	$00A0,$5013,$0004,$000E,$0001,$0008,$0050,$0008,$0050,$0C00,$0C00,$0016,$0008,$0026,$0028,$0001,$0001,$1798,$0000,$0001,$0001,$0000,$0140,$0004,$0005,$00C7,$000E,$0002,$0001,$0A7C,$1798,$0028,$1798,$0001
instrument__aressey:
	dc.w	$01AC,$D5C7,$0002,$000E,$0001,$001F,$0050,$001F,$0050,$0C00,$0CC4,$000E,$0001,$0008,$0050,$0008,$0050,$0C00,$0CC4
instrument__303test_b3:
	dc.w	$00A0,$5013,$0004,$000E,$0001,$0008,$0050,$0008,$0050,$1800,$1800,$0016,$0008,$0026,$00AF,$0001,$0001,$1798,$0000,$0001,$0001,$0000,$0140,$0004,$0005,$00C7,$000E,$0002,$0001,$0001,$201D,$0028,$1798,$0001
instrument__retro_bass:
	dc.w	$00D6,$6AE3,$0002,$000E,$0001,$0008,$0050,$0008,$0050,$0C00,$0CEF,$0016,$0008,$0019,$0031,$0001,$0001,$11A4,$0014,$C402,$C402,$0000,$004A
instrument__aressey_flt:
	dc.w	$01AC,$D5C7,$0003,$000E,$0001,$001F,$0050,$001F,$0050,$0C00,$0CC4,$000E,$0001,$0008,$0050,$0008,$0050,$0C00,$0CC4,$0008,$0007,$0000,$0055,$0064

drumloop_drums_003:
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0711,$070F,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 1600
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$020D,$ffff,$070C,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 2c00
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$020D,$ffff,$070F,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 4200
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$020D,$ffff,$0710,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$0417,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 5800
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$020D,$ffff,$0712,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$2		; -- End
drumloop_drums_002:
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$070F,$0110,$ffff,$040D
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0710,$ffff,$060D
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	232		; -- length POSITION = 2c00
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0110,$0712,$040D
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 4200
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$0715,$ffff,$ffff,$FFFFFFFF0D
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 5800
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 6e00
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$0718,$ffff,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$ffff,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$0717,$ffff,$ffff,$ffff
	dc.w	$2		; -- End
drumloop_drums_001:
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$070F,$0110,$ffff,$0413
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 1600
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0710,$ffff,$0413
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 2c00
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0110,$0712,$0413
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 4200
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$070F,$0110,$0711,$0413
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0710,$ffff,$0413
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$2		; -- End
drumloop_drums_000:
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$070F,$0110,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 1600
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0710,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 2c00
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0110,$0712,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$1		; -- Spacer
	dc.w	116		; -- length POSITION = 4200
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$070F,$0110,$0711,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0710,$ffff,$ffff
	dc.w	$0		; -- Render
	dc.w	2758		; -- length
	dc.w	$ffff,$0310,$ffff,$ffff
	dc.w	$2		; -- End


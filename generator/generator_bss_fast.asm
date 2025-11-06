; generator public ram

                    section    generator_bss_fast,bss

delay_maxdelaybuffer = 10000
freq_positions       = 256

sample_pointers:    ds.l       31

render_period:      ds.w       1
render_length:      ds.w       1
render_pointer:     ds.l       1
base_period         ds.w       1

clamp4u:            ds.b       $80                       ; clamp for 4 unsinged channels to unsigned output
clamp3u:            ds.b       $80                       ; clamp for 3 unsigned channels to unsigned output
clamp2u:            ds.b       $300                      ; clamp for 2 unsigned channels to unsigned output

clamp4:             ds.b       $80                       ; clamp for 4 unsinged channels to signed output
clamp3:             ds.b       $80                       ; clamp for 3 unsigned channels to signed output
clamp2:             ds.b       $300                      ; clamp for 2 unsigned channels to signed output

amp_1:              ds.b       256
amp_2:              ds.b       256

freq_table:         ds.w       freq_positions
biquad_coeff:       ds.l       freq_positions*5

envelope_table:     ds.w       256*2*3                   ; TODO: determine how much space is needed for this

delay_delaybuf:     ds.b       delay_maxdelaybuffer

noise:              ds.b       noise_len                 ; noise buffer

sinus:              ds.w       sine_degrees

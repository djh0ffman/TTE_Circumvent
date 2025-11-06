
                  section    generator_data_fast,data

                  include    "tunedata\lspmap.asm"

                  include    "generator_period_table.asm"
                  even 

wave_count = 45
wave_pointers:    dcb.l      wave_count,0

                ; TODO - unused waveforms now removed, but we've got empty space
waves:            include    "tunedata\waveforms.i"

                ; project data
                
                  include    "tunedata\project.i"
                  include    "tunedata\drumplan.i"
                  include    "tunedata\samples_fast.i"


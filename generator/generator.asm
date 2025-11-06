; generator
;
; core code block
                     RSRESET
LSPIns_Type          rs.w       1
LSPIns_BankId        rs.w       1
LSPIns_Offset        rs.l       1
LSPIns_LoopOffset    rs.l       1
LSPIns_Sizeof        rs.w       0
                        


                     section    generator_core,code

generator_precalc:    
                     movem.l    d0-a6,-(sp)   
                     jsr        shared_init
                     lea        sample_ram,a1
                     jsr        project_render
                     movem.l    (sp)+,d0-a6
                     rts

project_render:
                     lea        tune_instruments,a5
                     lea        instrument_pointers,a4
                     lea        sample_pointers,a6
                     moveq      #31-1,d7                                          ; 31 max instruments
                     moveq      #0,d2                                             ; instrument counter

.insloop             move.w     (a5)+,d6                                          ; ins type
                     add.l      d6,d6
                     add.l      d6,d6                                             ; * 4
                     moveq      #0,d0
                     move.w     (a5)+,d0                                          ; render length (words)
                     move.w     d0,d3                                             ; backup word length for p61 loading
                     add.l      d0,d0                                             ; double for byte length
                     move.l     (a5)+,a0                                          ; instrument / data pointer

                     cmp.l      #instrument__303test_b3,a0
                     bne        .noacid

                     nop
.noacid
                     move.l     (a4,d6.w),d4                                      ; get function pointer
                     beq.b      .skip                                             ; no pointer
                     move.l     d4,a3
                     jsr        (a3)                                              ; run render function

                     move.l     a1,d5                                             ; current pointer
                     tst.w      d6
                     bne.b      .notsample
                     move.l     a0,d5                                             ; use sample in place
                     moveq      #0,d0                                             ; clear length for next iteration

.notsample           move.l     d5,(a6)

                     add.l      d0,a1                                             ; move to next buffer position (after sample)
.skip                
                     addq.l     #4,a6
                     addq.b     #1,d2                                             ; next ins count

                     move.l     a1,progress_pointer                               ; for progress bar
                                                  ; better bar, divide sample length by number of 
                                                  ; devices, then move progress pointer that each time
                                                  ; nice ;)

                     dbra       d7,.insloop
                     rts

progress_pointer:  
                     dc.l       sample_ram

instrument_pointers:
                     dc.l       sample_loader                                     ; TODO: sample loader (4bit delta?)
                     dc.l       0                                                 ; enable this function to render all drum loops up front
                     dc.l       instrument_render
                     dc.l       0                                                 ; unused instrument (at the moment)


            ; a0 = sample data
            ; a1 = output buffer
            ; d0 = length (bytes)
sample_loader:
                     movem.l    d0-a6,-(sp)
                     move.l     a0,a1                                             ; assuming here all tune samples reside in chip ram
          ; not packed
                     ifeq       generator_pack_mode
                     subq.w     #1,d0
.loop                move.b     (a0)+,(a1)+
                     dbra       d0,.loop
                     endc
          ; delta
                     ifeq       generator_pack_mode-1
                     subq.w     #1,d0
                     moveq      #0,d1
.loop                add.b      (a0)+,d1
                     move.b     d1,(a1)+
                     dbra       d0,.loop
                     endc

          ; double delta
                     ifeq       generator_pack_mode-2
                     subq.w     #1,d0
                     moveq      #0,d1
.loop                add.b      (a0)+,d1
                     move.b     d1,d2
                     add.b      d2,d2
                     move.b     d2,(a1)+
                     dbra       d0,.loop
                     endc
          ; p61 delta
                     ifeq       generator_pack_mode-3

                     move.w     d0,d7
                     lsr.w      #1,d7
                     lea        (a0,d7.w),a0

                     subq.l     #1,d7                                             ; dbra!

                     moveq      #4,d1                                             ; shift (1st nibble)
                     moveq      #$f,d2                                            ; and value (2nd nibble)
                     moveq      #0,d3                                             ; source byte (1st nibble)
                     moveq      #0,d4                                             ; source byte (2nd nibble)
                     moveq      #0,d5                                             ; delta sample
                     lea        .table(pc),a3

.unpackloop  
                     move.b     (a0)+,d3                                          ; get source byte
                     move.b     d3,d4                                             ; copy byte 
                     lsr.b      d1,d3                                             ; shift first nibble
                     and        d2,d4                                             ; and second nibble
	
                     sub.b      (a3,d3),d5                                  
                     move.b     d5,(a1)+
                     sub.b      (a3,d4),d5
                     move.b     d5,(a1)+
                     dbf        d7,.unpackloop
	
                     endc
                     movem.l    (sp)+,d0-a6
                     rts

.table   
                     dc.b       0,1,2,4,8,16,32,64,128,-64,-32,-16,-8,-4,-2,-1

            ; a0 = instrument data
            ; a1 = output buffer
            ; d0 = render length
instrument_render:    
                     movem.l    d0-a6,-(sp)
                     move.w     (a0)+,render_period                               ; instrument render period
                     move.w     (a0)+,base_period                                 ; higher rated period value for delta calcs on waveforms
                     move.w     d0,render_length
                     move.l     a1,render_pointer

                     move.l     a0,-(sp)
                     move.l     render_pointer,a0
                     move.w     render_length,d7
                     bsr        prep_buffer
                     move.l     (sp)+,a0

         
                     move.w     (a0)+,d7                                          ; device count
                     moveq      #0,d5                                             ; device inc


                     lea        device_pointers(pc),a1
                     moveq      #0,d6
.loop                move.w     (a0)+,d6                                          ; chunk size
            
                     movem.l    d0-a6,-(sp)
            
                     move.w     (a0)+,d0                                          ; device id
                     muls       #4,d0
                     move.l     (a1,d0.w),a2                                      ; get code pointer
                     jsr        (a2)                                              ; run device
            
                     movem.l    (sp)+,d0-a6

                     add.l      d6,a0                                             ; move to next device chunk

                     addq.w     #1,d5

                     moveq      #0,d4                                             ; progress based on each device in the chain being done
                     move.w     render_length,d4
                     mulu.w     d5,d4
                     divu       d7,d4
                     swap       d4
                     clr.w      d4
                     swap       d4
                     add.l      render_pointer,d4
                     move.l     d4,progress_pointer

                     cmp.w      d7,d5
                     blo.b      .loop

                     move.l     render_pointer,a0                                 ; TODO: hot switch macro for last device in the chain
                     move.w     render_length,d7
                     bsr        sign_buffer

                     clr.w      (a0)                                              ; clear first word to prevent hi pitch nasty

                     movem.l    (sp)+,d0-a6
                     rts

drum_loop_render_full:
                     movem.l    d0-a6,-(sp)
                     bsr        drum_loop_init
                     bsr        drum_loop_render
                     clr        drm_active
                     movem.l    (sp)+,d0-a6
                     rts

device_pointers:
                     dc.l       voice_noise
                     dc.l       voice_twin
                     dc.l       envelope
                     dc.l       delay
                     dc.l       cinter
                     dc.l       gain
                     dc.l       gain_lfo
                     dc.l       biquad
                     dc.l       biquad_env
                     even 

; includes
                     include    generator_macros.asm
                     include    generator_gain.asm
                     include    generator_gain_lfo.asm
                     include    generator_voice_noise.asm
                     include    generator_voice_twin.asm
;       include    voice_sync.asm
                     include    generator_envelope.asm
                     include    generator_delay.asm
                     include    generator_cinter4.asm
                     include    generator_shared.asm
                     include    generator_biquad.asm
                     include    generator_drum_loop.asm
                     include    generator_lspmapper.asm
       ; data sections

                     include    generator_data_fast.asm    
                     include    generator_data_chip.asm

       ; bss sections (ram required)

                     include    generator_bss_fast.asm
                     include    generator_bss_chip.asm





************************************************************************
* SEQ2SMP
*
* by Hoffman / Focus Design
*
* mixes drum samples together into a single sample.  All samples have to
* at the sample freq / period.
*
* a0 = pattern data
* a6 = output buffer
*************************************************************************
drm_volpos       = 8
drm_runsizeframe = 8*6

drum_loop_runtime:
                  ;movem.l          d0-a6,-(sp)
                  lea              drm_songpos(pc),a0
                  move.w           (a0),d0
                  move.w           TickCounter(a5),d1
                  cmp.w            d0,d1
                  bne              .render
                  ;subq.w           #1,(a0)
                  ;bne              .render
                  ;move.w           P61_Pos,d0
                  ;cmp.w            (a0),d0
                  ;bne.b            .render
                  ;cmp.w            #1,P61_CRow
                  ;bne.b            .render

.doit             move.w           #drm_runsizeframe,d0
                  bsr.b            drum_loop_next

.render           bsr              drum_loop_render
.done             ;movem.l          (sp)+,d0-a6
                  rts

                ; d0 = render length per frame
                ; 0 = full render
drum_loop_next:    
                  move.l           drm_buffers(pc),d5                                 ; swap buffers
                  move.l           drm_buffers+4(pc),d6                               
                  move.l           d6,drm_buffers
                  move.l           d5,drm_buffers+4
              
                  move.l           drm_planptr(pc),a3
                  move.w           (a3)+,d3                                           ; next song pos
                  move.w           d3,drm_songpos
                  move.w           (a3)+,d3                                           ; sample id

                  ;tst.w            (a3)                                               ; test for end  TODO, this might screw up!
                  ;bpl.b            .notdone
                  cmp.w            #-1,(a3)
                  bne              .notdone
                  move.l           #drum_plan,a3
.notdone          move.l           a3,drm_planptr                                     ; store plan posotion

                  move.l           drm_buffers(pc),a1                                 ; buffer to write

                  lea              tune_instruments,a2
                  move.w           d3,d4
                  lsl.w            #3,d4
                  move.l           4(a2,d4.w),a0                                      ; pattern pointer
                  tst.w            d0
                  bne.b            .goinit
                  move.w           2(a2,d4.w),d0                                      ; zero passed, full render
                  add.w            d0,d0                                              ; doubel size
.goinit           bsr              drum_loop_init

                  move.w           2(a2,d4.w),d0                                      ; sample length

                  ;lea              sample_pointers,a6                                 ; load it into P61
                  ;addq.w           #1,d3
                  ;move.w           d3,d6
                  ;addq.w           #1,d6
                  ;lsl.w            #2,d6                                              ; size of pointers in p61 (no longer!)
                  ;move.l           d5,(a6,d6.w)                                       ; store pointer
                  bsr              LSPDrumMapper
                  rts

    ; precals volume lookup
drum_loop_precalc
                  movem.l          d0-a6,-(sp)
                  lea              drm_vlut,a0
                  moveq            #drm_volpos-1,d7                                   ; total volume positions
                  moveq            #0,d1                                              ; volume
.vol              moveq            #0,d0                                              ; sample
                  move.w           #255,d6
.smp              move.w           d0,d2
                  ext.w            d2
                  muls             d1,d2
                  divs.w           #drm_volpos-1,d2
                  add.b            #$80,d2
                  move.b           d2,(a0)+
                  addq.w           #1,d0
                  dbra             d6,.smp
                  addq.w           #1,d1
                  dbra             d7,.vol

                  moveq            #31-1,d7
                  moveq            #0,d0
                  lea              drumloop_sample_pointers,a6                        ; unpack samples TODO: P61 delta
.nextsmp          move.w           (a6)+,d6                                           ; unused
                  move.w           (a6)+,d0                                           ; length
                  add.l            d0,d0                                              ; now in bytes
                  move.l           (a6)+,a0
                  move.l           a0,a1
                  tst.w            d0
                  beq.b            .empty
                  bsr              sample_loader
.empty            dbra             d7,.nextsmp

                  lea              drm_buffers(pc),a6                                 ; prep buffer pointers
                  move.l           #drum_ram,d6
                  move.l           d6,(a6)
                  add.l            #generator_drum_ram/2,d6                           ; fuck knows why this is underlined!
                  move.l           d6,4(a6)

                  moveq            #0,d0                                              ; full render
                  bsr              drum_loop_next
                  bsr              drum_loop_render
                  clr.w            drm_active

                  ;moveq            #0,d0                                              ; full render
                  ;bsr              drum_loop_next
                  ;bsr              drum_loop_render
                  ;clr.w            drm_active

                  move.w           #drm_runsizeframe,d0                               ; queue up next sample ready for vblank
                  bsr              drum_loop_next

                  movem.l          (sp)+,d0-a6
                  rts

                ; d0 = sample index
                ; a1 = output buffer
drm_render_single:
                  movem.l          d0-a6,-(sp)
                  lea              tune_instruments,a0
                  lsl.w            #3,d0
                  lea              (a0,d0.w),a0                                       ; now at drum pointer
                                                                                    ; saftey check of a0 = drum loop???
                  move.w           2(a0),d0
                  move.l           4(a0),a0
                  bsr              drum_loop_init
                  bsr              drum_loop_render
                  clr.w            drm_active
                  movem.l          (sp)+,d0-a6
                  rts

drm_min           MACRO
                  tst.w            \1
                  beq.b            .\@skip
                  cmp.w            \1,\2
                  bls.b            .\@skip
                  move.w           \1,\2
.\@skip
                  ENDM
drm_load          MACRO
                  tst.b            (a0)
                  bpl.b            .\@
                  addq.l           #2,a0
                  bra.b            .\@leave
.\@               moveq            #0,d\1
                  move.b           1(a0),d\1
                  lsl.w            #3,d\1
                  move.l           4(a5,d\1.w),a\1                                    ; pointer
                  move.w           2(a5,d\1.w),d\1                                    ; length
                  add.w            d\1,d\1
                  swap             d\1                                                ; swap to higher
                  move.w           (a0)+,d\1                                          ; grab the volume
                  swap             d\1                                                ; swap to counter
.\@leave
                  ENDM

drm_planptr:      dc.l             drum_plan
drm_buffers:      dc.l             0
                  dc.l             0
drm_songpos:      dc.w             -1
drm_pattern:      dc.l             0
drm_output:       dc.l             0
drm_active:       dc.w             0
drm_runsize:      dc.w             0
drm_state:        dcb.l            13,0
drm_state_end:    dc.l             0
drm_nextpos:      dc.b             0
                  even

               ; a0 = pattern data
               ; a1 = output
               ; d0 = render size
drum_loop_init:
                  tst.w            drm_active
                  bne.b            .drm_race                                          ; race condition (requested new loop before previous finished)
                  move.l           a0,drm_pattern
                  move.l           a1,drm_output
                  move.w           #1,drm_active                                      ; active stage 1 init
                  move.w           d0,drm_runsize
                  rts

.drm_race         move.w           #$f00,$dff180
                  bra.b            .drm_race

drum_loop_render:
                  movem.l          d0-a6,-(sp)
                  move.w           drm_active(pc),d0
                  beq.b            .drm_norun
                  subq.w           #1,d0
                  beq.b            .drm_start
                  subq.w           #1,d0
                  beq              .drm_cont
.drm_norun        movem.l          (sp)+,d0-a6
                  rts

.drm_start
                  move.w           drm_runsize(pc),d0
                  move.l           drm_pattern(pc),a0                                 ; patternd data
                  move.l           drm_output(pc),a6                                  ; output
              
                  moveq            #0,d1                                              ; clear channels
                  moveq            #0,d2
                  moveq            #0,d3
                  moveq            #0,d4

.nextpos          move.w           (a0)+,d7                                           ; command
                  subq.w           #1,d7
                  bmi.b            .render
                  sub.w            #1,d7
                  bmi.b            .spacer
                  bra              .quit

.spacer           move.w           (a0)+,d7
                  subq.w           #1,d7
.clear            clr.b            (a6)+
                  dbra             d7,.clear
                  bra.b            .nextpos

.render           move.w           (a0)+,d7                                           ; render length size
                  lea              drumloop_sample_pointers,a5
                  drm_load         1
                  drm_load         2
                  drm_load         3
                  drm_load         4
.mixloop        
                  subq.w           #1,d1                                              ; calc active chans
                  subq.w           #1,d2
                  subq.w           #1,d3
                  subq.w           #1,d4

                  move.w           d1,d5
                  add.l            d5,d5
                  move.w           d2,d5
                  add.l            d5,d5
                  move.w           d3,d5
                  add.l            d5,d5
                  move.w           d4,d5
                  add.l            d5,d5
                  swap             d5
                  not.w            d5
                  and.w            #$f,d5                                             ; d5 = active chans

                  addq.w           #1,d1
                  addq.w           #1,d2
                  addq.w           #1,d3
                  addq.w           #1,d4
                  move.w           d7,d6                                              ; current samples to mix
                  drm_min          d1,d6
                  drm_min          d2,d6
                  drm_min          d3,d6
                  drm_min          d4,d6                                              ; mininum to mix
                  drm_min          d0,d6                                              ; including run size

                  sub.w            d6,d0                                              ; subtract from run size

                  btst             #3,d5                                              ; sub minimum sample count
                  beq.b            .skipA
                  sub.w            d6,d1
.skipA
                  btst             #2,d5
                  beq.b            .skipB
                  sub.w            d6,d2
.skipB
                  btst             #1,d5
                  beq.b            .skipC
                  sub.w            d6,d3
.skipC
                  btst             #0,d5
                  beq.b            .skipD
                  sub.w            d6,d4
.skipD
                  sub.w            d6,d7
                  swap             d7
                  move.w           d6,d7                                              ; new min counter
                  subq.w           #1,d7

                  lea              drm_vlut,a5                                        ; repoint
                  bra              .doMixJump

.mixdone          swap             d7
                
                  tst.w            d0                                                 ; check if run is finished
                  beq.b            .run_done                                          ; carry on

                  tst.w            d7
                  bne              .mixloop
                  bra              .nextpos


.run_done         move.w           #2,drm_active
                  move.w           drm_runsize,d0
                  lea              drm_state_end(pc),a5                               ; store state and get out
                  movem.l          d0/d1/d2/d3/d4/d6/d7/a0/a1/a2/a3/a4/a6,-(a5)
                  movem.l          (sp)+,d0-a6
                  rts

.drm_cont         lea              drm_state(pc),a5                                   ; restore state and get running again
                  movem.l          (a5)+,d0/d1/d2/d3/d4/d6/d7/a0/a1/a2/a3/a4/a6

                  tst.w            d7
                  bne              .mixloop
                  bra              .nextpos

.quit             move.w           a6,d0                                              ; check for even
                  btst             #0,d0
                  beq.b            .done
                  clr.b            (a6)+
                
.done             move.w           #0,drm_active
                  movem.l          (sp)+,d0-a6
                  rts


                ; do mix jump
.doMixJump
                  add.w            d5,d5
                  move.w           .mixJump(pc,d5.w),d5
                  jmp              .mixJump(pc,d5.w)

.mixJump
                  dc.w             .mixRout_0000-.mixJump
                  dc.w             .mixRout_0001-.mixJump
                  dc.w             .mixRout_0010-.mixJump
                  dc.w             .mixRout_0011-.mixJump
                  dc.w             .mixRout_0100-.mixJump
                  dc.w             .mixRout_0101-.mixJump
                  dc.w             .mixRout_0110-.mixJump
                  dc.w             .mixRout_0111-.mixJump
                  dc.w             .mixRout_1000-.mixJump
                  dc.w             .mixRout_1001-.mixJump
                  dc.w             .mixRout_1010-.mixJump
                  dc.w             .mixRout_1011-.mixJump
                  dc.w             .mixRout_1100-.mixJump
                  dc.w             .mixRout_1101-.mixJump
                  dc.w             .mixRout_1110-.mixJump
                  dc.w             .mixRout_1111-.mixJump
drm_UnrollLog2   = 3
drm_Mix_None      MACRO
                  move.w           d7,d6
                  lsr.w            #drm_UnrollLog2,d7
                  not.w            d6
                  and.w            #(1<<drm_UnrollLog2)-1,d6
                  mulu.w           #(.\@blockend-.\@sample)/(1<<drm_UnrollLog2),d6
                  jmp              .\@sample(pc,d6.w)
.\@sample
                  REPT             (1<<drm_UnrollLog2)
                  clr.b            (a6)+
                  ENDR
.\@blockend
                  dbra             d7,.\@sample
                  ENDM
drm_Mix_One       MACRO                                                               ; source
                  swap             d\1
                  moveq            #-$80,d5
                  move.w           d7,d6
                  lsr.w            #drm_UnrollLog2,d7
                  not.w            d6
                  and.w            #(1<<drm_UnrollLog2)-1,d6
                  mulu.w           #(.\@blockend-.\@sample)/(1<<drm_UnrollLog2),d6
                  jmp              .\@sample(pc,d6.w)
.\@sample
                  REPT             (1<<drm_UnrollLog2)
                  move.b           (a\1)+,d\1
                  move.b           (a5,d\1.w),d6
                  eor.b            d5,d6
                  move.b           d6,(a6)+
                  ENDR
.\@blockend
                  dbra             d7,.\@sample
                  swap             d\1
                  ENDM
drm_Mix_Two       MACRO                                                               ; source1, source2, spare
                  swap             d\1
                  swap             d\2
                  lea              clamp2,a\3
                  moveq            #0,d5
                  move.w           d7,d6
                  lsr.w            #drm_UnrollLog2,d7
                  not.w            d6
                  and.w            #(1<<drm_UnrollLog2)-1,d6
                  mulu.w           #(.\@blockend-.\@sample)/(1<<drm_UnrollLog2),d6
                  jmp              .\@sample(pc,d6.w)
.\@sample
                  REPT             (1<<drm_UnrollLog2)
                  moveq            #0,d6
                  move.b           (a\1)+,d\1
                  move.b           (a5,d\1.w),d6
                  move.b           (a\2)+,d\2
                  move.b           (a5,d\2.w),d5
                  add.w            d5,d6
                  move.b           (a\3,d6.w),(a6)+
                  ENDR
.\@blockend
                  dbra             d7,.\@sample
                  swap             d\1
                  swap             d\2
                  ENDM
drm_Mix_Three     MACRO                                                               ; source1, source2, source3, spare
                  moveq            #0,d5
                  swap             d\1
                  swap             d\2
                  swap             d\3
                  lea              clamp3,a\4
                  move.w           d7,d6
                  lsr.w            #drm_UnrollLog2,d7
                  not.w            d6
                  and.w            #(1<<drm_UnrollLog2)-1,d6
                  mulu.w           #(.\@blockend-.\@sample)/(1<<drm_UnrollLog2),d6
                  jmp              .\@sample(pc,d6.w)
.\@sample
                  REPT             (1<<drm_UnrollLog2)
                  moveq            #0,d6
                  move.b           (a\1)+,d\1
                  move.b           (a5,d\1.w),d6

                  move.b           (a\2)+,d\2
                  move.b           (a5,d\2.w),d5
                  add.w            d5,d6
                  move.b           (a\3)+,d\3
                  move.b           (a5,d\3.w),d5
                  add.w            d5,d6
                  move.b           (a\4,d6.w),(a6)+
                  ENDR
.\@blockend
                  dbra             d7,.\@sample
                  swap             d\1
                  swap             d\2
                  swap             d\3
                  ENDM
drm_Mix_Four      MACRO                                                               ; source1,2,3,4
                  move.l           a0,-(a7)
                  swap             d\1
                  swap             d\2
                  swap             d\3
                  swap             d\4

                  moveq            #0,d5
                  lea              clamp4,a0
                ; different volumes, more vlut
                  move.w           d7,d6
                  lsr.w            #drm_UnrollLog2,d7
                  not.w            d6
                  and.w            #(1<<drm_UnrollLog2)-1,d6
                  mulu.w           #(.\@blockend-.\@sample)/(1<<drm_UnrollLog2),d6
                  jmp              .\@sample(pc,d6.w)
.\@sample
                  REPT             (1<<drm_UnrollLog2)
                  moveq            #0,d6
                  move.b           (a\1)+,d\1
                  move.b           (a5,d\1.w),d6
                  move.b           (a\2)+,d\2
                  move.b           (a5,d\2.w),d5
                  add.w            d5,d6

                  move.b           (a\3)+,d\3
                  move.b           (a5,d\3.w),d5
                  add.w            d5,d6
                  move.b           (a\4)+,d\4
                  move.b           (a5,d\4.w),d5
                  add.w            d5,d6
                  move.b           (a0,d6.w),(a6)+
                  ENDR
.\@blockend
                  dbra             d7,.\@sample
                  swap             d\1
                  swap             d\2
                  swap             d\3
                  swap             d\4
                  move.l           (a7)+,a0
                  ENDM
.mixRout_0000
                  drm_Mix_None
                  bra              .mixdone
.mixRout_0001
                  drm_Mix_One      4
                  bra              .mixdone
.mixRout_0010
                  drm_Mix_One      3
                  bra              .mixdone
.mixRout_0011
                  drm_Mix_Two      4,3,2,1
                  bra              .mixdone
.mixRout_0100
                  drm_Mix_One      2
                  bra              .mixdone
.mixRout_0101
                  drm_Mix_Two      4,2,3,1
                  bra              .mixdone
.mixRout_0110
                  drm_Mix_Two      3,2,4,1
                  bra              .mixdone
.mixRout_0111
                  drm_Mix_Three    4,3,2,1
                  bra              .mixdone
.mixRout_1000
                  drm_Mix_One      1
                  bra              .mixdone
.mixRout_1001
                  drm_Mix_Two      4,1,3,2
                  bra              .mixdone
.mixRout_1010
                  drm_Mix_Two      3,1,4,2
                  bra              .mixdone
.mixRout_1011
                  drm_Mix_Three    4,3,1,2
                  bra              .mixdone
.mixRout_1100
                  drm_Mix_Two      2,1,4,3
                  bra              .mixdone
.mixRout_1101
                  drm_Mix_Three    4,2,1,3
                  bra              .mixdone
.mixRout_1110
                  drm_Mix_Three    3,2,1,4
                  bra              .mixdone
.mixRout_1111
                  drm_Mix_Four     4,3,2,1
                  bra              .mixdone
        ; --- data area ---

;           section          bss,bss


drm_vlut          dcb.b            256*drm_volpos,0



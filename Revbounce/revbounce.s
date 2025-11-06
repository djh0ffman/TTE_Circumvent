; issues:
; rotation/x hit: rotation dir should change a frame earlier
; shuffle tiledrop better
; reduce number of tile drop sets (to make runtime shorter)
; ringdata can be reduced to 2 "radii" per ring as long as we only render square notches.
; ringdata not in shared data area
; store images compressed until actually needed, then decompress to ScreenMem

rb_bob_width_b           = 2
rb_bob_height            = 16
rb_bob_height_alternate  = 18                                                          ; used for blitting logo to bg where next tile below has bright edge
rb_bob_depth             = 3
rb_logo_image_width_b    = 26
rb_logo_image_offset_x_b = 8
rb_logo_image_offset_y   = 48
rb_background_width_b    = 40
rb_background_depth      = 3
rb_bounce_y_top          = 256-98-8-4-127
rb_wall_y_start          = 48
rb_framebuffer_width_b   = 44
rb_framebuffer_height    = 256

    include     "revbounce.i"

    section     revbounce_code,code

    include     "revbounce_init.s"

revbounce_vbtick:
    lea         rb_data,a0
    addq.b      #1,(rb_framecount,a0)
    rts

revbounce_background_thread:
    lea         rb_data,a0
    cmp.b       #2,(rb_framecount,a0)
    bhs         revbounce_frame
    rts
	; fall-through!!!
revbounce_frame:
    movem.l     d2-d7/a2-a6,-(sp)

    lea         rb_data,a4
    lea         CUSTOM,a6

    sf          (rb_framecount,a4)   ; zero framecount

; lateral and angular motion

    move.w      (rb_xpos,a4),d0
    add.w       (rb_xvelocity,a4),d0
    cmp.w       #319-127,d0
    bge         .reversevelocity
    tst.w       d0
    bgt         .xposok
.reversevelocity:
    neg.w       (rb_xvelocity,a4)
    neg.w       (rb_angledir,a4)
.xposok:
; constant speed left/right motion
    move.w      d0,(rb_xpos,a4)
    moveq       #15,d1
    and.w       d0,d1
    lsl.w       #4,d1
    move.w      d1,revbounce_copperlist\.bplscroll
    lsr.w       #4,d0
    add.w       d0,d0
    moveq       #0,d2
    move.w      d0,d2

; polynomial y speed
    move.w      (rb_time,a4),d0
    moveq       #2*14,d3                                                               ; 2*v0 (14 gives a bounce every 28 frames rendered)
    sub.w       d0,d3                                                                  ; 2*v0-t
    muls        d0,d3                                                                  ; d3 = (2*v0-t)*t
    asr.w       #1,d3                                                                  ; since we doubled the polynomial coefficients (for rounding reasons), div by two here
    cmp.w       (rb_bounce_y_limit,a4),d3
    sle         .bounce
    bgt         .yok

	; here we have hit the ground!
	; when d3 < 0, we also need to move background

    clr.w       (rb_time,a4)

    move.w      #-3,(rb_shake_y_offset,a4)

.yok:

	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    basereg     revbounce_copperlist,a0
    lea         revbounce_copperlist,a0

    move.w      d3,d1
    blt         .drop_bg
    move.w      (rb_shake_y_offset,a4),d1

.drop_bg:

    moveq       #$18,d0
    sub.w       d1,d0
    move.b      d0,(revbounce_copperlist\.background_color,a0)
    cmp.w       #$ff,d0                                                                ; copwait past line $ff?
    shi         (revbounce_copperlist\.background_color-4,a0)

    moveq       #$2c,d0
    sub.w       d1,d0
    move.b      d0,(revbounce_copperlist\.background_y_top,a0)
    cmp.w       #$ff,d0                                                                ; copwait past line $ff?
    shi         (revbounce_copperlist\.background_y_top-4,a0)

    moveq       #$2c+rb_bounce_y_top,d0
    sub.w       d1,d0
    move.b      d0,(revbounce_copperlist\.bounce_y_top,a0)
    cmp.w       #$ff,d0                                                                ; copwait past line $ff?
    shi         (revbounce_copperlist\.bounce_y_top-4,a0)

    moveq       #$2c+rb_wall_y_start,d0
    sub.w       d1,d0
    move.b      d0,(revbounce_copperlist\.wall_y_start,a0)
    cmp.w       #$ff,d0                                                                ; copwait past line $ff?
    shi         (revbounce_copperlist\.wall_y_start-4,a0)

    addq.w      #8,d3                                                                  ; boing logo ground offset

    move.w      #$2c+128,d0
    sub.w       d3,d0
    cmp.w       #$12c,d0
    bhi         .modok
    moveq       #0,d1
    move.b      (revbounce_copperlist\.wall_y_start-4,a0),d1
    addq.w      #1,d1                                                                  ; d1 $100 or $1
    move.b      (revbounce_copperlist\.wall_y_start,a0),d1
    cmp.w       d1,d0
    bhs         .mod2
    move.b      d0,(revbounce_copperlist\.modulo1even,a0)
    move.w      #rb_framebuffer_width_b-40,(revbounce_copperlist\.modulo1even+6,a0)
    bra         .modok
.mod2:
    move.w      #-40,(revbounce_copperlist\.modulo1even+6,a0)
    move.b      d0,(revbounce_copperlist\.modulo2even,a0)
    cmp.w       #$ff,d0                                                                ; copwait past line $ff?
    shi         (revbounce_copperlist\.modulo2even-4,a0)
.modok:

    endb        a0
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

				; preload buffer we just showed with static rings
    move.l      (rb_buffertoshow,a4),a3
    lea         (4*rb_framebuffer_width_b,a3),a3                                       ; space for shadow

    lea         (rb_framebufferlist,a4),a1
    move.w      (rb_framebufferindex,a4),d1
    lsl.w       #2,d1
    move.l      (a1,d1.w),d1
    move.l      d1,(rb_buffertoshow,a4)
    sub.l       d2,d1
    lea         revbounce_copperlist\.bplptr,a0
    move.w      d1,(1*8+6,a0)
    swap        d1
    move.w      d1,(1*8+2,a0)
    swap        d1
    add.l       #rb_framebuffer_width_b*4-4,d1
    move.w      d1,(3*8+6,a0)
    swap        d1
    move.w      d1,(3*8+2,a0)

    move.w      (rb_framebufferindex,a4),d1
    addq.w      #1,d1
    cmp.w       #3,d1
    blo         .index_ok
    moveq       #0,d1
.index_ok:
    move.w      d1,(rb_framebufferindex,a4)

    tst.b       .bounce
    beq         .skip_pull
    tst.l       (rb_tile_to_pull,a4)
    beq         .skip_advance
    bsr         rb_pull_tiles
    bra         .skip_advance
.skip_pull:
    bsr         rb_advance_tiles
.skip_advance:

    bsr         rb_waitblit
    move.l      #rb_full_rings,BLTAPT(a6)
    move.l      #$ffffffff,BLTAFWM(a6)
    move.w      #rb_framebuffer_width_b-128/8,BLTAMOD(a6)
    move.l      a3,BLTDPT(a6)
    move.w      #$09F0,BLTCON0(a6)
    move.w      #0,BLTCON1(a6)
    move.w      #rb_framebuffer_width_b-128/8,BLTDMOD(a6)
    move.w      #128*64+128/16,BLTSIZE(a6)

    move.w      (rb_framebufferindex,a4),d1
    lsl.w       #2,d1
    lea         (rb_framebufferlist,a4),a1
    move.l      (a1,d1.w),a3
    lea         (4*rb_framebuffer_width_b,a3),a3                                       ; space for shadow

    addq.w      #1,(rb_shake_y_offset,a4)
    ble         .shake_ok
    clr.w       (rb_shake_y_offset,a4)
.shake_ok:

    move.w      (rb_angle,a4),d2
    lsr.w       #2,d2
    bsr         rb_render_rings

;	move.w		#$aa0,COLOR00(a6)

    move.w      (rb_angle,a4),d0
    add.w       (rb_angledir,a4),d0
    and.w       #256<<2-1,d0
    move.w      d0,(rb_angle,a4)

    move.w      (rb_timestep,a4),d0
    add.w       d0,(rb_time,a4)

    bsr         .do_script

    moveq       #0,d0
    lea         (.heart_colors,pc),a0
    move.b      (.heart_fade_index,pc),d0
;    bmi         .no_heart_fade
    subq.b      #1,d0
    bge         .heart_fade_index_ok
    moveq       #14-1,d0
.heart_fade_index_ok
    move.b      d0,.heart_fade_index
    add.b       d0,d0
    move.w      (a0,d0.w),revbounce_copperlist\.color+9*4+2
.no_heart_fade:
    movem.l     (sp)+,d2-d7/a2-a6
    rts

.heart_colors:
    dc.w        $f7f,$f7f,$f7f,$f7d,$f6d,$f6c,$f6b,$f6a,$f5a,$f59,$f58,$f47,$f46,$f6b

.heart_fade_index:
    dc.b        14
.bounce:
    dc.b        0
    even

.script_ptr:
    dc.l        .script

.do_script:
    move.l      .script_ptr,a0
    tst.w       (a0)+
    beq         .scriptend
    move.l      (4,a0),a0
    jsr         (a0)                                                                   ; run "iterate"-function
    move.l      .script_ptr,a0
    subq.w      #1,(a0)+
    bgt         .scriptend
    addq.l      #8,a0                                                                  ; next block - skip function pointers
    move.l      a0,.script_ptr
    move.l      (2,a0),a0
    jmp         (a0)                                                                   ; run "once"-function
.scriptend:
    rts

.nonefunc:
    rts

; .w: number of iterations for block (zero to end)
; .l: run "once" function (this is mandatory, also for end-block) - not called for first block
; .l: "iteration" function
; repeat
.script:
    dc.w        16
    dc.l        .nonefunc
    dc.l        .fadein_logo
    dc.w        28-16
    dc.l        .nonefunc
    dc.l        .nonefunc
    dc.w        1*56-(28-22)
    dc.l        .nonefunc
    dc.l        .rotate_start
    dc.w        28-22                                                                  ; rb_time initial value is 22
    dc.l        .bounce_start
    dc.l        .fadein_wall
    dc.w        16-(28-22)                                                             ; 16 steps total for fadein_wall
    dc.l        .side2side_start
    dc.l        .fadein_wall
    dc.w        2*28-(16-(28-22))                                                      ; delay before start dropping tiles
    dc.l        .nonefunc
    dc.l        .nonefunc
    dc.w        18*28
    dc.l        .droptile_enable
    dc.l        .nonefunc

    dc.w        1                                                                      ; final wallbounce
    dc.l        .nonefunc
    dc.l        .nonefunc
    dc.w        1
    dc.l        .drop_revert_ydir
    dc.l        .nonefunc

    dc.w        14                                                                     ; 13 iterations to drop everything off screen
    dc.l        .droplogo_start
    dc.l        .nonefunc
    dc.w        28-14-1-1
    dc.l        .droplogo_stop
    dc.l        .nonefunc
    dc.w        0
    dc.l        .nonefunc                                                              ; MUST end with valid "once"-function pointer

.fade:
    dc.w        0

.fadein_logo:
    moveq       #$000,d0                                                               ; start color all black
    move.w      #rb_color_logo,d1
    move.w      .fade(pc),d2
    addq.w      #1,.fade
    bsr         rgb_interpolate
    lea         revbounce_copperlist\.color+16*4+2,a0
    moveq       #16-1,d1
.1
    move.w      d0,(a0)
    addq.l      #4,a0
    dbf         d1,.1
    rts

.fadein_wall:
    lea         revbounce_copperlist\.color+2,a0
    lea         rb_colors_final(pc),a1
    moveq       #8-1,d3
.3
    moveq       #$000,d0                                                               ; start color all black
    move.w      (a1)+,d1
    move.w      .fade(pc),d2
    bsr         rgb_interpolate
    move.w      d0,(a0)
    addq.l      #4,a0
    dbf         d3,.3
    ; copy bg color
    move.w      revbounce_copperlist\.color+2,revbounce_copperlist\.background_color+6
    addq.w      #1,.fade
    rts
.rotate_start:
    cmp.w       #-4,(rb_angledir,a4)
    beq         .2
    subq.w      #1,(rb_angledir,a4)
.2
    rts
.bounce_start:
    clr.w       .fade
    move.w      #1,(rb_timestep,a4)
    rts
.side2side_start:
    move.w      #2,(rb_xvelocity,a4)
    rts
.droptile_enable:
    move.l      #rb_tile_pull_list,(rb_tile_to_pull,a4)
    rts
.drop_revert_ydir:
    moveq       #28,d0
    sub.w       (rb_time,a4),d0
    move.w      d0,(rb_time,a4)
.droplogo_start:
    move.w      #-300,(rb_bounce_y_limit,a4)
    move.w      #$000,revbounce_copperlist\.color+2
    rts
.droplogo_stop:
    clr.w       (rb_timestep,a4)
    rts

rb_colors_final:
    dc.w        rb_color_background
    dc.w        rb_color_grid
    dc.w        rb_color_wall2
    dc.w        rb_color_wall3
    dc.w        rb_color_background_shade
    dc.w        rb_color_grid_shade
    dc.w        rb_color_wall2_shade
    dc.w        rb_color_wall3_shade

; d2: angle
; a3: framebuffer
rb_render_rings:
    movem.l     d2/a4-a5,-(sp)
    ifeq        USE_PREBUILT_RINGRENDERERS
    lea         rb_ringcode,a5
    endif

    lea         rb_ringdata,a4

    lea         (rb_ringdata2,a4),a0
    lea         (a0,d2.w),a0
    lea         (a3),a2
    CALLRING    rb_ringcode2

    lea         (rb_ringdata3,a4),a0
    lea         (a0,d2.w),a0
    lea         (a3),a2
    CALLRING    rb_ringcode3

    lea         (rb_ringdata4,a4),a0
    lea         (a0,d2.w),a0
    lea         (a3),a2
    CALLRING    rb_ringcode4

    ifeq        USE_PREBUILT_RINGRENDERERS
.ringcode_offset=rb_ringcode6
    lea         (.ringcode_offset,a5),a5
    else
.ringcode_offset=0
    endif

    lea         (rb_ringdata6,a4),a0
    lea         (a0,d2.w),a0
    lea         (a3),a2
    CALLRING    rb_ringcode6-.ringcode_offset

    lea         (rb_ringdata8,a4),a0
    lea         (a0,d2.w),a0
    lea         (a3),a2
    CALLRING    rb_ringcode8-.ringcode_offset

	; the frame just rendered should be the next one shown
    movem.l     (sp)+,d2/a4-a5
    rts

******************************************************************

    include     "tiles.s"

    INCDIR      "." 

    ifeq        USE_PREBUILT_RINGRENDERERS

    include     "halfcircle.s"

    else
rb_ringcode2:
    include     "ring2.s"
    rts
rb_ringcode3:
    include     "ring3.s"
    rts
rb_ringcode4:
    include     "ring4.s"
    rts
rb_ringcode6:
    include     "ring6.s"
    rts
rb_ringcode8:
    include     "ring8.s"
    rts

rb_ringcode1:
    include     "ring1.s"
    rts
rb_ringcode5:
    include     "ring5.s"
    rts
rb_ringcode7:
    include     "ring7.s"
    rts

    endif

    section     revbounce_data_c,data,chip

revbounce_copperlist:
    dc.w        BPLCON0,$0200
    dc.w        BPL1MOD,rb_background_depth*rb_background_width_b-40
    dc.w        BPL2MOD,-40                                                            ;rb_framebuffer_width_b-40
    dc.w        DIWSTRT,$2c81
    dc.w        DIWSTOP,$2cc1
    dc.w        DDFSTRT,$0038
    dc.w        DDFSTOP,$00d0

.color: 		; order must match rb_colors_final !!!!!!!!!!!!!!!!!!!!!!!!!
    dc.w        COLOR00,0                                                              ;rb_color_background
    dc.w        COLOR01,0                                                              ;rb_color_grid
    dc.w        COLOR04,0                                                              ;rb_color_wall2
    dc.w        COLOR05,0                                                              ;rb_color_wall3
    dc.w        COLOR08,0                                                              ;rb_color_background_shade
    dc.w        COLOR09,0                                                              ;rb_color_grid_shade
    dc.w        COLOR12,0                                                              ;rb_color_wall2_shade
    dc.w        COLOR13,0                                                              ;rb_color_wall3_shade

    dc.w        COLOR16,rb_color_wall4
    dc.w        COLOR17,rb_color_wall5
    dc.w        COLOR20,rb_color_wall6
    dc.w        COLOR21,rb_color_wall7
    dc.w        COLOR24,rb_color_wall4_shade
    dc.w        COLOR25,rb_color_wall5_shade
    dc.w        COLOR28,rb_color_wall6_shade
    dc.w        COLOR29,rb_color_wall7_shade

    dc.w        COLOR02,0                                                              ;rb_color_logo
    dc.w        COLOR03,0                                                              ;rb_color_logo
    dc.w        COLOR06,0                                                              ;rb_color_logo
    dc.w        COLOR07,0                                                              ;rb_color_logo
    dc.w        COLOR10,0                                                              ;rb_color_logo
    dc.w        COLOR11,0                                                              ;rb_color_logo
    dc.w        COLOR14,0                                                              ;rb_color_logo
    dc.w        COLOR15,0                                                              ;rb_color_logo
    dc.w        COLOR18,0                                                              ;rb_color_logo
    dc.w        COLOR19,0                                                              ;rb_color_logo
    dc.w        COLOR22,0                                                              ;rb_color_logo
    dc.w        COLOR23,0                                                              ;rb_color_logo
    dc.w        COLOR26,0                                                              ;rb_color_logo
    dc.w        COLOR27,0                                                              ;rb_color_logo
    dc.w        COLOR30,0                                                              ;rb_color_logo
    dc.w        COLOR31,0                                                              ;rb_color_logo

    dc.w        $18df,$fffe
    dc.w        BPLCON1
.bplscroll:
    dc.w        $0
.bplptr:
    dc.w        BPL1PTH,$0,BPL1PTL,$0
    dc.w        BPL2PTH,$0,BPL2PTL,$0
    dc.w        BPL3PTH,$0,BPL3PTL,$0
    dc.w        BPL4PTH,$0,BPL4PTL,$0
    dc.w        BPL5PTH,$0,BPL5PTL,$0

    dc.w        $00df,$fffe
.background_color:
    dc.w        $1807,$fffe
    dc.w        COLOR00,0

    dc.w        $00df,$fffe
.background_y_top:
    dc.w        ($2c)<<8+$07,$fffe
    dc.w        BPLCON0,$1200

    dc.w        $00df,$fffe
.bounce_y_top:
    dc.w        ($2c+rb_bounce_y_top)<<8+$07,$fffe
    dc.w        BPLCON0,$4200

.modulo1even:
    dc.w        $4307,$fffe
    dc.w        BPL2MOD,rb_framebuffer_width_b-40

    dc.w        $00df,$fffe
.wall_y_start:
    dc.w        ($2c+rb_wall_y_start)<<8+$07,$fffe
    dc.w        BPLCON0,$5200

    dc.w        $00df,$fffe
.modulo2even:
    dc.w        $2c07,$fffe
    dc.w        BPL2MOD,rb_framebuffer_width_b-40

    dc.l        COPPER_HALT


rb_bob:
    dc.w        %1111111111111111,0,%1111111111111110
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1000000000000001,0,%1000000000000000
    dc.w        %1111111111111111,0,%1000000000000000

; shown on screen - bobs are drawn/restored here
rb_background:
    incbin      "boing-bg-i.BPL"
    blk.b       6*rb_background_width_b*rb_background_depth,0                          ; background is 250 pixels tall

; when a tile is pulled from the wall, its area is copied from here to bg restore
rb_logo_data:
    incbin      "boing_tiles.BPL"

    section     revbounce_bss_c,bss,chip

rb_full_rings:
    ds.b        1*rb_framebuffer_width_b*128

    section     revbounce_bss,bss

	; remember to clear these areas if they become shared!!!!
rb_data:
    ds.b        rb_data_sizeof
rb_ringdata:
    ds.b        rb_ringdata_sizeof

    ifeq        USE_PREBUILT_RINGRENDERERS
rb_ringcode:
    ds.b        rb_rc_sizeof

	; this is also not needed after generating rb_ringcodex
    include     "halfcircle_bss.s"
    endif

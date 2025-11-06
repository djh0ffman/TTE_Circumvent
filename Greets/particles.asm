

;-------------------------------------
;
; particle engine
;
;-------------------------------------

ParticleInit:
    ; y look up table
    move.l        #$DEADBEEF,RandomSeed(a5)

    lea           ParticleYLookUp(a5),a0
    move.w        #(DISPLAY_HEIGHT*2)-1,d7
    move.w        #0,d0
.loop
    move.w        d0,(a0)+
    add.w         #FORE_STRIDE,d0
    dbra          d7,.loop

    move.w        #PARTICLES_MAX_GUARD+32-1,d7
    lea           SPARTICLE_FLICKER,a0
.loopflicker
    RANDOMWORD
    and.w         #1,d0
    or.w          #$01e8,d0
    move.w        d0,(a0)+
    dbra          d7,.loopflicker

    move.w        #$4e75,PARTICLE_SMCRTS
    move.w        #PARTICLES_OCS,ParticleMax(a5)

    ; Particle Life Lookup

    lea           ParticleLifeList(a5),a0
    move.w        #MAX_OBJECT_POINTS-1,d7
.lifeloop
    RANDOMWORD
    and.w         #32-1,d0
    add.w         #PARTICLE_OBJECT_LIFE,d0
    move.w        d0,(a0)+
    dbra          d7,.lifeloop
    rts




;-------------------------------------
;
; kill all particles
;
;-------------------------------------


ParticleKill:
    clr.w         ParticlesLive(a5)                              ; clear live count
    clr.w         SparticlesLive(a5)
    rts    


;-------------------------------------
;
; add particle object
;
; a1 = particle object
; a2 = actor
;
;-------------------------------------

OBJECT_UNROLL_LOG2 = 5

ParticleAddObject:
    PUSHMOST
    move.w        ParticleMax(a5),d7
    sub.w         ParticlesLive(a5),d7                           ; particles available
    bcs           .full
    ;beq            .full
    
    moveq         #0,d5                                          ; particle object inc

    move.w        (a1)+,d6                                       ; particle count of object
    cmp.w         d6,d7                                          ; we have enough free particles?
    bcc           .goload                                        ; yes, go and load them

    lsr.w         #1,d6                                          ; half the number from this object
    moveq         #8,d5                                          ; skip value for each point
    cmp.w         d6,d7                                          ; we have enough free particles?
    bcc           .goload                                        ; yes, go and load them

    lsr.w         #1,d6                                          ; half again!
    moveq         #16,d5                                         ; skip value for each point
    cmp.w         d6,d7                                          ; we have enough free particles?
    bcc           .goload                                        ; yes, go and load them

    lsr.w         #1,d6                                          ; half again!
    moveq         #32,d5                                         ; skip value for each point
    cmp.w         d6,d7                                          ; we have enough free particles?
    bcc           .goload                                        ; yes, go and load them

    move.w        d7,d6                                          ; use the last remaining particles

.goload
    move.w        d6,d7

    moveq         #0,d2
    move.w        ParticlesLive(a5),d2                           ; index
    add.w         d7,ParticlesLive(a5)                           ; add the number of particles we're adding

    subq.w        #1,d7
    bmi           .full

    ;move.w        Actor_X(a2),d0
    ;move.w        Actor_Y(a2),d1
    ;move.w        #DISPLAY_WIDTH/2,d0
    ;move.w        #DISPLAY_HEIGHT/2,d1

    asl.w         #6,d0
    asl.w         #7,d1

    lea           ParticleLife,a0
    lea           PARTICLE_POS,a2
    lea           ParticleSpeeds,a3

    add.w         d2,d2                                          ; x2
    add.l         d2,a0                                          ; life
    add.w         d2,d2                                          ; x4
    add.l         d2,a2                                          ; positions
    add.l         d2,a3                                          ; speeds

    lea           ParticleLifeList(a5),a4                        ; life list

    move.w        d7,d6
    lsr.w         #OBJECT_UNROLL_LOG2,d7
    not.w         d6
    and.w         #(1<<OBJECT_UNROLL_LOG2)-1,d6
    mulu.w        #(.bend-.bstart)/(1<<OBJECT_UNROLL_LOG2),d6
    jmp           .bstart(pc,d6.w)

.bstart
    REPT          1<<OBJECT_UNROLL_LOG2
    move.w        (a4)+,(a0)+                                    ; copy life counter

    move.w        d0,d2
    add.w         (a1)+,d2                                       ; position offset x
    move.w        d2,(a2)+

    move.w        d1,d2
    add.w         (a1)+,d2                                       ; position offset y
    move.w        d2,(a2)+

    move.l        (a1)+,(a3)+                                    ; speed x / y

    add.l         d5,a1
    ENDR
.bend

    dbra          d7,.bstart

.full   
    POPMOST
    rts



;-------------------------------------
;
; add a single particle
;
; d0 = life?
; d1 = x (word)
; d2 = y (word)
; d3 = speed x
; d4 = speed y
;
;-------------------------------------

ParticleAddOne:
    cmp.w         #PARTICLES_FLICKER_TIME,d0
    bgt           .particle

.sparticle
    move.w        SparticlesLive(a5),d6
    cmp.w         ParticleMax(a5),d6
    bcc           .exits

    asl.w         #6,d1                                          ; x 
    asl.w         #7,d2                                          ; y 

    asl.l         #6,d3                                          ; delta x
    asl.l         #7,d4                                          ; delta y
    clr.w         d3
    clr.w         d4
    swap          d3
    swap          d4

    add.w         d6,d6                                          ; x2
    lea           SparticleLife,a0
    move.w        d0,(a0,d6.w)    
    add.w         d6,d6                                          ; x4
    lea           SPARTICLE_POS,a0
    move.w        d1,(a0,d6.w)    
    move.w        d2,2(a0,d6.w)    
    lea           SparticleSpeeds,a0
    move.w        d3,(a0,d6.w)    
    move.w        d4,2(a0,d6.w)    
    addq.w        #1,SparticlesLive(a5)
.exits
    rts


.particle
    sub.w         #PARTICLES_FLICKER_TIME,d0
    move.w        ParticlesLive(a5),d6
    cmp.w         ParticleMax(a5),d6
    bcc           .exitp

    asl.w         #6,d1                                          ; x 
    asl.w         #7,d2                                          ; y 

    asl.l         #6,d3                                          ; delta x
    asl.l         #7,d4                                          ; delta y
    clr.w         d3
    clr.w         d4
    swap          d3
    swap          d4

    add.w         d6,d6                                          ; x2
    lea           ParticleLife,a0
    move.w        d0,(a0,d6.w)    
    add.w         d6,d6                                          ; x4
    lea           PARTICLE_POS,a0
    move.w        d1,(a0,d6.w)    
    move.w        d2,2(a0,d6.w)    
    lea           ParticleSpeeds,a0
    move.w        d3,(a0,d6.w)    
    move.w        d4,2(a0,d6.w)    
    addq.w        #1,ParticlesLive(a5)
.exitp
    rts


;-------------------------------------
;
; new 68000 turbo particle system
;
; developed by Emoon / TBL - based on the method
; in the demo Abosolute Inebriation
;
;-------------------------------------

ParticleProcessDraw:
    bsr           SparticleLifeCheck
    bsr           SparticleMove
    bsr           ParticleLifeCheck
    bsr           ParticleMove
    ;move.w        #$005,COLOR00(a6)
    rts


;-------------------------------------
;
; particle move
;
;-------------------------------------

SparticleMove:
    lea           SparticleSpeeds,a0
    lea           SPARTICLE_POS,a1
    
    moveq         #0,d0
    move.w        SparticlesLive(a5),d0

    moveq         #0,d1
    moveq         #0,d2

    tst           d0
    bne.s         .p
    rts
.p
    bsr           ParticleUpdateUnroll

    moveq         #0,d3
    move.w        RandomFrame(a5),d3
    and.w         #$3e,d3                                        ; 64 but even
    add.l         #SPARTICLE_FLICKER,d3


        ; these blitter passes are used to patch up the plotting code
        ; we currently busy wait on the blitter to finish so either do
        ; 1. Other stuff while these blits are running
        ; 2. Use blitter nasty in DMACON to give blitter priority to finish

        ; The first blit needs the source to be address to patch - 4
        ; so we caculate the correct offset here * 4 as each bset instruction is 4 bytes

    add.w         d2,d2
    add.w         d2,d2                                          ; * 4 as bset inst is 4 bytes

    lea           PARTICLE_SMC,a0                                ; Code that we need to patch
    add.l         d2,a0                                          ; target for blitter patching
    lea           SPARTICLE_POS,a2                               ; positions to read from
    lea           2(a0),a4                                       ; offset for next blit, but save a0 for later
    lea           2(a2),a3                                       ; positions to read from + 2

        ; blit size (count x 1)
    lsl.w         #6,d0
    or.w          #1,d0



        ; patch dn bit in 
        ; We only need to shift 4 here as value is pre-shifted 4
    WAITBLITN
    move.l        #$07ea3002,bltcon0(a6)                         ; operation: b << 4 shift, D=C+B, minterm = c | (b & a). descend mode
    move.w        #$0e00,bltadat(a6)                             ; operation = C=0x01e8/9 | (B & A=0x0e00) 
    move.l        #$ffffffff,bltafwm(a6)                         ; MASK 
    move.l        d3,bltcpt(a6)                                  ; C SOURCE
    move.l        a2,bltbpt(a6)                                  ; B SOURCE
    move.l        a0,bltdpt(a6)                                  ; D DEST
    move.l        #$fffcfffa,bltcmod(a6)                         ; C / B mod
    move.l        #$0000fffa,bltamod(a6)                         ; A / D mod
    move.w        d0,bltsize(a6)                                 ; BLTSIZE
        
        ; patch offset
    WAITBLITN
    move.l        #$07ac9000,bltcon0(a6)                         ; operation: b >> 9, D=B+C, minterm = (b & ~a) | (c & a)
    move.w        #$ff80,bltadat(a6)                             ;          ; ADAT
    move.l        a2,bltbpt(a6)                                  ; B source
    move.l        a3,bltcpt(a6)                                  ; C source 
    move.l        a4,bltdpt(a6)                                  ; D dest
    move.l        #$00020002,bltcmod(a6)                         ; C / B mod
    move.l        #$00000002,bltamod(a6)                         ; A / D mod
    move.w        d0,bltsize(a6)                                 ; BLTSIZE
    WAITBLITN
        
        ; prepare registers for the plotting and jump to
        ; the blitter generated code
    move.l        a0,a2
    move.l        ForeBufferPtr(a5),a0
    lea           FORE_WIDTH_BYTE(a0),a1

    moveq         #7,d0
    moveq         #6,d1
    moveq         #5,d2
    moveq         #4,d3
    moveq         #3,d4
    moveq         #2,d5
    moveq         #1,d6
    moveq         #0,d7
    jmp           (a2)




ParticleMove:
    lea           ParticleSpeeds,a0
    lea           PARTICLE_POS,a1
    
    moveq         #0,d0
    move.w        ParticlesLive(a5),d0

    moveq         #0,d1
    moveq         #0,d2

    tst           d0
    bne.s         .p
    rts
.p
    bsr           ParticleUpdateUnroll
        ; these blitter passes are used to patch up the plotting code
        ; we currently busy wait on the blitter to finish so either do
        ; 1. Other stuff while these blits are running
        ; 2. Use blitter nasty in DMACON to give blitter priority to finish

        ; The first blit needs the source to be address to patch - 4
        ; so we caculate the correct offset here * 4 as each bset instruction is 4 bytes

    add.w         d2,d2
    add.w         d2,d2                                          ; * 4 as bset inst is 4 bytes

    lea           PARTICLE_SMC,a0                                ; Code that we need to patch
    add.l         d2,a0                                          ; target for blitter patching
    lea           PARTICLE_POS,a2                                ; positions to read from
    lea           2(a0),a4                                       ; offset for next blit, but save a0 for later
    lea           2(a2),a3                                       ; positions to read from + 2

        ; blit size (count x 1)
    lsl.w         #6,d0
    or.w          #1,d0

        ; patch dn bit in 
        ; We only need to shift 4 here as value is pre-shifted 4
    WAITBLITN
    move.l        #$05ea3002,bltcon0(a6)                         ; operation: b << 4 shift, D=B, minterm = c | (b & a). descend mode
    move.w        #$0e00,bltadat(a6)                             ; operation = C=0x01e8 | (B & A=0x0e00) 
    move.w        #$01e8,bltcdat(a6)                             ; operation = C=0x01e8 | (B & A=0x0e00) 
    move.l        #$ffffffff,bltafwm(a6)                         ; MASK 
    move.l        a2,bltbpt(a6)                                  ; B SOURCE
    move.l        a0,bltdpt(a6)                                  ; D DEST
    move.l        #$0000fffa,bltcmod(a6)                         ; C / B mod
    move.l        #$0000fffa,bltamod(a6)                         ; A / D mod
    move.w        d0,bltsize(a6)                                 ; BLTSIZE
        
        ; patch offset
    WAITBLITN
    move.l        #$07ac9000,bltcon0(a6)                         ; operation: b >> 9, D=B+C, minterm = (b & ~a) | (c & a)
    move.w        #$ff80,bltadat(a6)                             ;          ; ADAT
    move.l        a2,bltbpt(a6)                                  ; B source
    move.l        a3,bltcpt(a6)                                  ; C source 
    move.l        a4,bltdpt(a6)                                  ; D dest
    move.l        #$00020002,bltcmod(a6)                         ; C / B mod
    move.l        #$00000002,bltamod(a6)                         ; A / D mod
    move.w        d0,bltsize(a6)                                 ; BLTSIZE
    WAITBLITN
        
        ; prepare registers for the plotting and jump to
        ; the blitter generated code

    move.l        a0,a2
    ;move.l         ScreenDraw,a0
    move.l        ForeBufferPtr(a5),a0
    move.l        a0,a1

    moveq         #7,d0
    moveq         #6,d1
    moveq         #5,d2
    moveq         #4,d3
    moveq         #3,d4
    moveq         #2,d5
    moveq         #1,d6
    moveq         #0,d7
    jmp           (a2)


ParticleUpdateUnroll:
        ; each unroll here is 8 bytes so we need to jump to
        ; the correct location depending on count
    move.w        #PARTICLES_OCS,d1
    sub.w         d0,d1
    move.w        d1,d2
    lsr.w         #3,d1
    mulu          #20,d1
    PUSHM         d0/d2
    jmp           2(pc,d1.w)

    rept          (PARTICLES_OCS/8)+1

    movem.l       (a0)+,d0-d7                                    ; speed x/y
    add.l         d0,(a1)+                                       ; pos x/y
    add.l         d1,(a1)+                                       ; pos x/y
    add.l         d2,(a1)+                                       ; pos x/y
    add.l         d3,(a1)+                                       ; pos x/y
    add.l         d4,(a1)+                                       ; pos x/y
    add.l         d5,(a1)+                                       ; pos x/y
    add.l         d6,(a1)+                                       ; pos x/y
    add.l         d7,(a1)+                                       ; pos x/y

    endr

    POPM          d0/d2

    rts


;    move.w         #PARTICLES_OCS,d1
;    sub.w          d0,d1
;    move.w         d1,d2
;    lsl.w          #2,d1
;    jmp            2(pc,d1.w)

;    rept           PARTICLES_OCS
;    move.l         (a0)+,d6                                       ; speed x/y
;    add.l          d6,(a1)+                                       ; pos x/y
;    endr

;    rts

;-------------------------------------
;
; particle life check
;
; subs the life counter and adds the id to a table if
; its dead. 
;
; copies dead ones into sparticles
; copies live ones into empty spaces
;
;-------------------------------------

LIFE_UNROLL_LOG2   = 5

ParticleLifeCheck:
    moveq         #0,d0
    move.w        ParticlesLive(a5),d0
    bne           .p
    rts

.p
    lea           ParticleLife,a0
    lea           ParticlesDead,a1

    bsr           ParticleLifeUnroll

    ; list of dead particles determined

    tst.w         d2
    beq           .nonedead                                      ; early out, zero particles have died
    sub.w         d2,ParticlesLive(a5)                           ; new live count

    moveq         #0,d3                                        
    move.w        SparticlesLive(a5),d3                          ; get sparticle position

    move.w        d3,d4                                          ; comparator
    add.w         d2,d4                                          ; new end point
 
    sub.w         ParticleMax(a5),d4
    bmi           .moveparticles                                 ; already at max
    beq           .moveparticles
  
    sub.w         d4,d2
    beq           .nonedead

.moveparticles
    add.w         d2,SparticlesLive(a5)                          ; add to live count

    subq.w        #1,d2                                          ; dead loop counter
    bmi           .nonedead

    lea           ParticleLife,a0
    lea           PARTICLE_POS,a2
    lea           ParticleSpeeds,a3

    lea           SparticleLife,a4
    lea           SPARTICLE_POS,a5                               ; warning common registers used
    lea           SparticleSpeeds,a6

    add.w         d3,d3                                          ; setup sparticle pointers
    add.l         d3,a4                                          ; life
    add.w         d3,d3
    add.l         d3,a5                                          ; positions
    add.l         d3,a6                                          ; speeds

.copyloop
    move.w        -(a1),d3                                       ; dead id
.retry
    subq.w        #2,d1
    bmi           .runout
    cmp.w         d3,d1
    beq           .retry
    tst.w         (a0,d1.w) 
    bmi           .retry

.copypart
    move.w        d1,d4                                          ; source id
    move.w        d3,d5                                          ; destination id
    move.w        #PARTICLES_FLICKER_TIME,(a4)+                  ; sparticle life  ; TODO: constant in register
    move.w        (a0,d4.w),(a0,d5.w)                            ; copy life
    add.w         d4,d4                                          ; x4
    add.w         d5,d5                                          ; x4
    move.l        (a2,d5.w),(a5)+                                ; copy position to sparticle
    ;move.l        (a3,d5.w),(a6)+                                ; copy speed to sparticle

    move.l        (a3,d5.w),d6
    asr.w         #2,d6
    swap          d6
    asr.w         #2,d6
    swap          d6
    move.l        d6,(a6)+

    move.l        (a2,d4.w),(a2,d5.w)                            ; copy position
    move.l        (a3,d4.w),(a3,d5.w)                            ; copy speed
    dbra          d2,.copyloop
.runout
    lea           Variables,a5                                   ; used common registers, reload
    lea           CUSTOM,a6

.nonedead
    rts

;-------------------------------------
;
; sparticle life check
;
; subs the life counter and adds the id to a table if
; its dead. then copies live items into dead ones
;
;-------------------------------------

SparticleLifeCheck:
    moveq         #0,d0
    move.w        SparticlesLive(a5),d0
    bne           .p
    rts

.p
    lea           SparticleLife,a0
    lea           ParticlesDead,a1

    bsr           ParticleLifeUnroll

    ; list of dead particles determined

    sub.w         d2,d0                                          ; new live count
    move.w        d0,SparticlesLive(a5)

    subq.w        #1,d2                                          ; dead loop counter
    bmi           .nonedead

    lea           SparticleLife,a0
    lea           SPARTICLE_POS,a2
    lea           SparticleSpeeds,a3

.copyloop
    move.w        -(a1),d3                                       ; dead id
.retry
    subq.w        #2,d1
    bmi           .nonedead
    cmp.w         d3,d1
    beq           .retry
    tst.w         (a0,d1.w) 
    bmi           .retry

.copypart
    move.w        d1,d4                                          ; source id
    move.w        d3,d5                                          ; destination id
    move.w        (a0,d4.w),(a0,d5.w)                            ; copy life
    add.w         d4,d4                                          ; x4
    add.w         d5,d5                                          ; x4
    move.l        (a2,d4.w),(a2,d5.w)                            ; copy position
    move.l        (a3,d4.w),(a3,d5.w)                            ; copy speed
    dbra          d2,.copyloop

.nonedead
    rts


ParticleLifeUnroll:
    move.w        d0,d7
    subq.w        #1,d7
    moveq         #0,d1                                          ; id
    moveq         #0,d2                                          ; dead count

    move.w        d7,d6
    lsr.w         #LIFE_UNROLL_LOG2,d7
    not.w         d6
    and.w         #(1<<LIFE_UNROLL_LOG2)-1,d6
    mulu.w        #(.bend-.bstart)/(1<<LIFE_UNROLL_LOG2),d6
    jmp           .bstart(pc,d6.w)
.bstart
    REPT          (1<<LIFE_UNROLL_LOG2)
    PART_LIFE
    ENDR
.bend    
    dbra          d7,.bstart
    rts


;-------------------------------------
;
; particle throttle
;
; reduces live particles and max when under load
;
;-------------------------------------

ParticleThrottle:
    move.w        ParticlesLive(a5),d0
    move.w        SparticlesLive(a5),d1
    move.w        ParticleMax(a5),d2

    move.w        #100,d3

    sub.w         d3,d0
    bpl           .plive
    moveq         #0,d0
.plive

    sub.w         d3,d1
    bpl           .slive
    moveq         #0,d1
.slive

    sub.w         d3,d2
    bpl           .max
    moveq         #0,d2
.max

    move.w        d0,ParticlesLive(a5)
    move.w        d1,SparticlesLive(a5)
    move.w        d2,ParticleMax(a5)

    rts




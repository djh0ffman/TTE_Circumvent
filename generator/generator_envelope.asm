

clock_constant = 3546895                  ; pal
tick_divider   = clock_constant/128       ; tick divider (0-255 attack = 2 seconds based on period)

; a0 = param data
; env block..  see blah!

envelope:  move.w    #$0,d0               ; start value
           move.w    #$ff,d1              ;  range
           bsr       make_env

           move.l    render_pointer,a0
           move.w    render_length,d7
           subq.w    #1,d7
           lea       envelope_table,a1

           moveq     #-$80,d3             ; signer
           move.w    (a1)+,d6             ; env counter
           move.w    (a1)+,d5             ; volume

.sample    moveq     #0,d0                ; sample
           move.b    (a0),d0
           add.b     d3,d0                ; signed
           ext.w     d0
           muls      d5,d0
           divs      #255,d0              ; scaled

           add.b     d3,d0                ; unsign
           move.b    d0,(a0)+

           subq.w    #1,d6                ; sub env coutner
           bcc.b     .cont                ; still positive, continue

           move.w    (a1)+,d6             ; env wait
           move.w    (a1)+,d5             ; env value

.cont      dbra      d7,.sample
           rts
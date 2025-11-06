
rb_color_background				=	$aaa
rb_color_logo					=	$fff
rb_color_grid					=	$c0b
rb_color_wall2					=	$547
rb_color_wall3					=	$963
rb_color_wall4					=	$07F
rb_color_wall5					=	$F7F
rb_color_wall6					=	$A85
rb_color_wall7					=	$8FF

rb_color_background_shade		=	$777
rb_color_grid_shade				=	$707
rb_color_wall2_shade			=	$334
rb_color_wall3_shade			=	$542
rb_color_wall4_shade			=	$048
rb_color_wall5_shade			=	$848
rb_color_wall6_shade			=	$653
rb_color_wall7_shade			=	$588

rb_st_fadein	=	0
rb_st_rotate	=	1
rb_st_bounce	=	2
rb_st_droptiles	=	3

; note: be aware if prebuilt renderers were generated for this
rb_single_radius_enable			=	1
	
; times 2 to avoid overlap between radii when changing start angle (and we want change the polar buffer at runtime for cracks)
; width from small to big radius, inclusive
; this doubling is actually not necessary as long as the render code only has 256 steps between radii (i.e. no angle doubling for rotation purposes).
; it still works only because the polar data is the same across all radii
	ifeq						rb_single_radius_enable
rb_ring2width					=	(1+21-13)+1
rb_ring3width					=	(1+25-19)+1
rb_ring4width					=	(1+30-26)+1
rb_ring6width					=	(1+51-45)+1
rb_ring8width					=	(1+63-59)+1
rb_fullringwidth				=	(1+58-52)
	else
rb_ring2width					=	1+1
rb_ring3width					=	1+1
rb_ring4width					=	1+1
rb_ring6width					=	1+1
rb_ring8width					=	1+1
rb_fullringwidth				=	1
	endif

					RSRESET
rb_framecount		rs.b	1
.rb_pad0			rs.b	1
rb_time				rs.w	1 ; 14
rb_timestep			rs.w	1
rb_angle			rs.w	1 ; 0
rb_angledir			rs.w	1 ; -1
rb_xpos				rs.w	1 ; 0
rb_xvelocity		rs.w	1 ;	2
rb_bounce_y_limit	rs.w	1
rb_framebufferlist	rs.l	3
rb_framebufferindex	rs.w	1
rb_buffertoshow		rs.l	1
rb_shake_y_offset	rs.w	1
rb_tile_to_pull		rs.l	1
rb_tile_instance_count rs.b	1
.rb_pad1			rs.b	1
rb_tile_instances	rs.b	4*rb_tile_sizeof
rb_interpoltable	rs.b	rgb_interpoltable_sizeof
rb_data_sizeof		rs.w	0


					RSRESET
rb_ringdata2		rs.b	rb_ring2width*256
rb_ringdata3		rs.b	rb_ring3width*256
rb_ringdata4		rs.b	rb_ring4width*256
rb_ringdata6		rs.b	rb_ring6width*256
rb_ringdata8		rs.b	rb_ring8width*256
rb_full_ring_polar	rs.b	rb_fullringwidth*256
rb_ringdata_sizeof	rs.w	0

	ifeq		USE_PREBUILT_RINGRENDERERS
					RSRESET
rb_ringcode2		rs.b	$18b6
rb_ringcode3		rs.b	$1966
rb_ringcode4		rs.b	$1838
rb_ringcode6		rs.b	$375e
rb_ringcode8		rs.b	$34e6
rb_rc_sizeof		rs.w	0
					RSRESET
rb_ringcode1		rs.b	$982
rb_ringcode5		rs.b	$1c5c
rb_ringcode7		rs.b	$3fee
rb_rc_sizeof2		rs.w	0
	endif

; tile instance
					RSRESET
rb_tile_x			rs.w	1
rb_tile_y			rs.w	1
rb_tile_speed		rs.w	1
rb_tile_dir			rs.w	1
rb_tile_sizeof		rs.w	0

; chipmem buffers
					RSRESET
rb_c_bg_restore		rs.b	rb_background_width_b*(rb_framebuffer_height-rb_logo_image_offset_y)*rb_background_depth
rb_c_buffer1		rs.b	rb_framebuffer_width_b*(98+4+8+127)
rb_c_buffer2		rs.b	rb_framebuffer_width_b*(98+4+8+127)
rb_c_buffer3		rs.b	rb_framebuffer_width_b*(98+4+8+127)
rb_c_sizeof			rs.w	0

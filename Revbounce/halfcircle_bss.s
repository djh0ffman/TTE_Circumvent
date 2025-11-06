
rb_circle_s:
	ds.b		2*rb_MAX_RADIUS+1
rb_circle_g:
	ds.b		2*rb_MAX_RADIUS+1
	ifeq		rb_single_radius_enable
rb_sqrt7938:
	ds.w		1+rb_MAX_RADIUS*rb_MAX_RADIUS*2
	endif
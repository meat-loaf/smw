includefrom "status.asm"

function pack_props(flip, priority, palette, page) = ((flip&03)<<$06)|((priority&03)<<$04)|((palette&$07)<<1)|(page&$01)

macro get_next_oam_tile(oam_tiles_tbl, abort_func)
?loop:
	DEX
	BPL ?cont
	JMP.w <abort_func>
?cont:
	LDY <oam_tiles_tbl>,x
	LDA $0201|!addr,y
	CMP #$F0
	BNE ?loop
endmacro

macro draw_static_tile_propram(x_pos,y_pos,tile,tileflip,palette,page,size,use_propram,propram)
	LDA.b #<x_pos>
	STA.w $0200|!addr,y
	LDA.b #<y_pos>
	STA.w $0201|!addr,y
	LDA.b #<tile>
	STA.w $0202|!addr,y
	LDA.b #pack_props(<tileflip>,!status_prio_props,<palette>,<page>)
if <use_propram> != 0
	ORA   <propram>
endif
	STA $0203|!addr,y
	LDY.w .oam_tiles_small,x
	LDA.b #<size>
	STA.w $0420|!addr,y
endmacro

macro draw_static_tile(x_pos,y_pos,tile,tileflip,palette,page,size)
	%draw_static_tile_propram(<x_pos>,<y_pos>,<tile>,<tileflip>,<palette>,<page>,<size>,$00,$00)
endmacro

macro draw_digit_tile_sk_prop(x_pos,y_pos,source_addr,tileflip,palette,page,size,do_skip,ix_skip,branch_skip,use_propram,propram)
	LDY  <source_addr>
	if <do_skip> != 0
	  if <ix_skip> != 0
	    CPY #<ix_skip>
	  endif
	  BNE.b ?cont
	  LDY.w .oam_tiles,x
	  ; BRA is often out of range. This isn't empirically slower.
	  JMP.w <branch_skip>
	endif
?cont
	LDA.w .number_tilenums,y
	LDY.w .oam_tiles,x
	STA.w $0202|!addr,y
	LDA.b #<x_pos>
	STA.w $0200|!addr,y
	LDA.b #<y_pos>
	STA.w $0201|!addr,y
	LDA.b #pack_props(<tileflip>,!status_prio_props,<palette>,<page>)
	if <use_propram> != 0
	  ORA <propram>
	endif
	STA $0203|!addr,y
	LDY.w .oam_tiles_small,x
	LDA.b #<size>
	STA.w $0420|!addr,y
endmacro

macro draw_digit_tile_sk(x_pos,y_pos,source_addr,tileflip,palette,page,size,do_skip,ix_skip,branch_skip)
	%draw_digit_tile_sk_prop(<x_pos>,<y_pos>,<source_addr>,<tileflip>,<palette>,<page>,<size>,<do_skip>,<ix_skip>,<branch_skip>,$00,$00)
endmacro

macro draw_digit_tile_propram(x_pos,y_pos,source_addr,tileflip,palette,page,size,use_propram,propram)
	%draw_digit_tile_sk_prop(<x_pos>,<y_pos>,<source_addr>,<tileflip>,<palette>,<page>,<size>,!false,$00,$00,<use_propram>,<propram>)
endmacro

macro draw_digit_tile(x_pos,y_pos,source_addr,tileflip,palette,page,size)
	%draw_digit_tile_sk_prop(<x_pos>,<y_pos>,<source_addr>,<tileflip>,<palette>,<page>,<size>,!false,$00,$00,!false,$00)
endmacro

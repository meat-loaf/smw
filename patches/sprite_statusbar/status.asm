if read1($00FFD5) == $23
	if read1($00FFD7) == $0D ; full 6/8 mb sa-1 rom
		fullsa1rom
		!fullsa1 = 1
	else
		sa1rom
	endif
	sa1rom
	!sa1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000
else
	lorom
	!sa1 = 0
	!fullsa1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!bank8 = $80
endif

incsrc "statusbar_defs.asm"
incsrc "statusbar_macros.asm"
incsrc "status_tweaks.asm"

macro draw_item_box(return)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(\
		!item_box_tl_xpos,!item_box_tl_ypos,!item_box_tile,\
		!tile_noflip,$0B,$00,$02)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(\
		!item_box_tr_xpos,!item_box_tr_ypos,!item_box_tile,\
		!tile_xflip,$0B,$00,$02)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(\
		!item_box_bl_xpos,!item_box_bl_ypos,!item_box_tile,\
		!tile_yflip,$0B,$00,$02)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(\
		!item_box_br_xpos,!item_box_br_ypos,!item_box_tile,\
		!tile_yxflip,$0B,$00,$02)
	<return>
endmacro

macro draw_timer(return)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!timer_clock_xpos,!timer_clock_ypos,!clock_tile,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!timer_100s_xpos,!timer_100s_ypos,$0F25|!addr,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!timer_tens_xpos,!timer_tens_ypos,$0F26|!addr,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!timer_ones_xpos,!timer_ones_ypos,$0F27|!addr,\
			!tile_noflip,$00,$00,$00)
	<return>
endmacro

macro draw_score(return)
?sc:
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!score_ones_xpos,!score_ones_ypos,!zero_digit_tile,\
		!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!score_tens_xpos,!score_tens_ypos,!score_tmap_ram_start+$05,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!score_100s_xpos,!score_100s_ypos,!score_tmap_ram_start+$04,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!score_thous_xpos,!score_thous_ypos,!score_tmap_ram_start+$03,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile_sk(!score_10thous_xpos,!score_10thous_ypos,!score_tmap_ram_start+$02,\
			!tile_noflip,$00,$00,$00,!do_skip,!blank_digit_ix,.skip)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile_sk(!score_hunthous_xpos,!score_hunthous_ypos,!score_tmap_ram_start+$01,\
			!tile_noflip,$00,$00,$00,!do_skip,!blank_digit_ix,.skip)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile_sk(!score_mils_xpos,!score_mils_ypos,!score_tmap_ram_start,\
			!tile_noflip,$00,$00,$00, !do_skip,!blank_digit_ix,.skip)
.skip:
	<return>
endmacro

macro draw_ycoins(return)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!ccoin_1_x,!ccoin_ypos_base,$0EFF|!addr,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!ccoin_2_x,!ccoin_ypos_base,$0F00|!addr,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!ccoin_3_x,!ccoin_ypos_base,$0F01|!addr,\
			!tile_noflip,$00,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!ccoin_4_x,!ccoin_ypos_base,$0F02|!addr,\
			!tile_noflip,$00,$00,$00)
	; the status bar routine can be modified to draw all 5 yoshi coins
	; if you wish. If you use LX5's star coins, this will also work
	; with the status bar hijack in that patch.
	;%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	;%draw_digit_tile(!ccoin_5_x,!ccoin_ypos_base,$0F03|!addr,\
	;		!tile_noflip,$00,$00,$00)
	<return>
endmacro

macro draw_lives(return)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!lives_xpos_1,!lives_ypos_1,!m_t1_tile,\
			!tile_noflip,$0C,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!lives_xpos_2,!lives_ypos_2,!m_t2_tile,\
			!tile_noflip,$0C,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!lives_xpos_3,!lives_ypos_3,!m_t3_tile,\
			!tile_noflip,$0C,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!lives_xpos_4,!lives_ypos_4,!m_t4_tile,\
			!tile_noflip,$0C,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!lives_xpos_5,!lives_ypos_5,!m_t5_tile,\
			!tile_noflip,$0C,$00,$00)

	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!lives_xpos_6,!lives_ypos_6,!x_tile, \
			!tile_noflip,$09,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!lives_xpos_7,!lives_ypos_7,$0F16|!addr,\
			!tile_noflip,$0C,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!lives_xpos_8,!lives_ypos_8,$0F17|!addr,\
			!tile_noflip,$0C,$00,$00)

	<return>
endmacro

macro draw_coins(return)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!coins_xpos_1,!coins_ypos,!coin_tile,\
		!tile_noflip,$08,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!coins_xpos_2,!coins_ypos,!x_tile,\
		!tile_noflip,$08,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!coins_xpos_3,!coins_ypos,$0F13|!addr,\
			!tile_noflip,$08,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!coins_xpos_4,!coins_ypos,$0F14|!addr,\
			!tile_noflip,$0C,$00,$00)
	<return>
endmacro

macro draw_bonusstars(return)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!star_xpos,!star_ypos,!star_tile,\
			!tile_noflip,$0C,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_static_tile(!star_xpos_1,!star_ypos,!x_tile,\
			!tile_noflip, $01,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!star_xpos_2,!star_ypos, $0F1E|!addr,\
			!tile_noflip, $01,$00,$00)
	%get_next_oam_tile(status_bar_oam_tiles, no_oam_left)
	%draw_digit_tile(!star_xpos_3,!star_ypos, $0F1F|!addr,\
			!tile_noflip, $01,$00,$00)
	<return>
endmacro


if not(!sa1)
org $00A2E6|!bank
	autoclean JSL status_bar
else
org $00A2EA|!bank
status_hijack_sa1:
	autoclean JML status_setup_hook_sa1
	NOP : NOP
.done:
endif

; skip layer 3 scroll fuckery
org $00A5A8|!bank
       BRA $01 : NOP

freecode
if !sa1
status_setup_hook_sa1:
	; setup sa1 finish oam hook
	LDA.b #status_bar
	STA   $0110|!addr
	LDA.b #status_bar>>8
	STA   $0111|!addr
	LDA.b #status_bar>>16
	STA   $0112|!addr
	; restore original code
	PLA
	STA $1D
	PLA
	STA $1C
	; compact oam tile size
	JML status_hijack_sa1_done
endif

; abort
no_oam_left:
	PLA            ; \ clean the stack
	PLA            ; /
	PLB            ; get stored bank byte
.exit:
	RTL            ; return to main code (stop drawing)

status_bar:
if not(!sa1)
	; restore original code on non-sa1 (do this first to make sure all oam alloc is done here)
	JSL $028AB1|!bank
endif
	LDA $0100|!addr
	CMP #$0B
	BEQ .continue
	CMP #$0A+$01
	BCC no_oam_left_exit
.continue:
	PHB
	PHK
	PLB
if !multi_status_bar_configs
	LDA !status_bar_config_ram
	ASL
	TAX
	JMP (.configurations,x)
.configurations:
	dw .standard_config
	dw .ibox_only
; if disabled, above falls through
endif

.standard_config:
	LDX.b #!oam_tbl_start_index
	JSR.w .timer
	JSR.w .item_box
	JSR.w .coins
	JSR.w .lives
	JSR.w .yosh_coin
	JSR.w .bonus_stars
	JSR.w .score

	PLB
	RTL

if !multi_status_bar_configs
.ibox_only
	LDX.b #!oam_tbl_start_index
	JSR.w .item_box

	PLB
	RTL
; If desired, create more status bar configurations here. Make sure
; to add them to the `.configurations' table above.
endif

.item_box:
	%draw_item_box(RTS)
.timer:
	%draw_timer(RTS)
.score:
	%draw_score(RTS)
.yosh_coin:
	%draw_ycoins(RTS)
.lives:
	%draw_lives(RTS)
.coins:
	%draw_coins(RTS)
.bonus_stars:
	%draw_bonusstars(RTS)

.number_tilenums:
	db !zero_digit_tile,!one_digit_tile,!two_digit_tile,!three_digit_tile
	db !four_digit_tile,!five_digit_tile,!six_digit_tile,!seven_digit_tile
	db !eight_digit_tile,!nine_digit_tile,!a_digit_tile,!b_digit_tile
	db !c_digit_tile,!d_digit_tile,!e_digit_tile,!f_digit_tile
	db !empty_coin_tile,!blank_digit_tile,!coin_tile
.oam_tiles:
	db $FC,$F8,$F4,$F0
	db $EC,$E8,$E4,$E0
	db $DC,$D8,$D4,$D0
	db $CC,$C8,$C4,$C0
	db $BC,$B8,$B4,$B0
	db $AC,$A8,$A4,$A0
	db $9C,$98,$94,$90
	db $8C,$88,$84,$80
	db $7C,$78,$74,$70
	db $6C,$68,$64,$60
	db $5C,$58,$54,$50
	db $4C,$48,$44,$40
	db $3C,$38,$34,$30
	db $2C,$28,$24,$20
	db $1C,$18,$14,$10
	db $0C,$08,$04,$00
.oam_tiles_small:
	db $3F,$3E,$3D,$3C
	db $3B,$3A,$39,$38
	db $37,$36,$35,$34
	db $33,$32,$31,$30
	db $2F,$2E,$2D,$2C
	db $2B,$2A,$29,$28
	db $27,$26,$25,$24
	db $23,$22,$21,$20
	db $1F,$1E,$1D,$1C
	db $1B,$1A,$19,$18
	db $17,$16,$15,$14
	db $13,$12,$11,$10
	db $0F,$0E,$0D,$0C
	db $0B,$0A,$09,$08
	db $07,$06,$05,$04
	db $03,$02,$01,$00

incsrc "disable_irq_lorom.asm"
print "status bar patch uses ", freespaceuse, " bytes"

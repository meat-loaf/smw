includefrom "status.asm"
includeonce

!true = 1
!false = 0

; settings
!multi_status_bar_configs = !false
; used only if the above is set to !true
!status_bar_config_ram    = $14BE|!addr

; counter ram stuff
!timer_hundreds       = $0F31|!addr
!timer_tens           = $0F32|!addr
!timer_ones           = $0F33|!addr

!score_tmap_ram_start = $0F29|!addr

; skip the lowest 3 OAM slots so yoshi's tongue isnt above some tiles and below others.
; Skip the following 5 because the original message boxes seem to clear them when closing
; for some reason.
; $40 is the lowest possible index, if the previous two things aren't an issue to you,
; you can start from there.
;!oam_tbl_start_index  = $3D

!oam_tbl_start_index  = $38

!status_prio_props   = %00000011

!tile_noflip         = %00000000
!tile_yflip          = %00000010
!tile_xflip          = %00000001
!tile_yxflip         = !tile_yflip|!tile_xflip

!empty_coin_tile     = $1D
!x_tile              = $7F

!item_box_tile       = $C0
!clock_tile          = $CD
!zero_digit_tile     = $C8
!one_digit_tile      = $C9
!two_digit_tile      = $CA
!three_digit_tile    = $CB
!four_digit_tile     = $CC
!five_digit_tile     = $D8
!six_digit_tile      = $D9
!seven_digit_tile    = $DA
!eight_digit_tile    = $DB
!nine_digit_tile     = $DC
; generally unused, but feel free to define these
; if you need text/hex counters.
!a_digit_tile        = $20
!b_digit_tile        = $21
!c_digit_tile        = $22
!d_digit_tile        = $30
!e_digit_tile        = $31
!f_digit_tile        = $32

!blank_digit_tile    = $D1
!coin_tile           = $DD
!x_tile              = $90
!star_tile           = $EF
!m_t1_tile           = $80
!m_t2_tile           = !m_t1_tile+$01
!m_t3_tile           = $C2
!m_t4_tile           = !m_t3_tile+$01
!m_t5_tile           = $91

!do_skip             = $1
!empty_coin_tile_ix  = 16
!blank_digit_ix      = 17
!coin_tile_ix        = 18

!item_box_tl_xpos    = $70
!item_box_tl_ypos    = $07
!item_box_tr_xpos    = !item_box_tl_xpos+$10
!item_box_tr_ypos    = !item_box_tl_ypos
!item_box_bl_xpos    = !item_box_tl_xpos
!item_box_bl_ypos    = !item_box_tl_ypos+$10
!item_box_br_xpos    = !item_box_tl_xpos+$10
!item_box_br_ypos    = !item_box_tl_ypos+$10

!timer_ypos          = !item_box_tl_ypos+$08
!timer_clock_xpos    = !item_box_tl_xpos+$30
!timer_clock_ypos    = !timer_ypos
!timer_100s_xpos     = !timer_clock_xpos-$08
!timer_100s_ypos     = !timer_ypos+$08
!timer_tens_xpos     = !timer_100s_xpos+$08
!timer_tens_ypos     = !timer_ypos+$08
!timer_ones_xpos     = !timer_tens_xpos+$08
!timer_ones_ypos     = !timer_ypos+$08

!ccoin_xpos_base     = $40
!ccoin_ypos_base     = !item_box_tl_ypos+$08
!ccoin_1_x           = !ccoin_xpos_base
!ccoin_2_x           = !ccoin_1_x+$08
!ccoin_3_x           = !ccoin_2_x+$08
!ccoin_4_x           = !ccoin_3_x+$08
!ccoin_5_x           = !ccoin_4_x+$08

!lives_xpos          = $10
!lives_ypos          = !item_box_tl_ypos+$08

!lives_xpos_1        = !lives_xpos
!lives_ypos_1        = !lives_ypos
!lives_xpos_2        = !lives_xpos_1+$08
!lives_ypos_2        = !lives_ypos
!lives_xpos_3        = !lives_xpos_2+$08
!lives_ypos_3        = !lives_ypos
!lives_xpos_4        = !lives_xpos_3+$08
!lives_ypos_4        = !lives_ypos
!lives_xpos_5        = !lives_xpos_4+$08
!lives_ypos_5        = !lives_ypos

!lives_xpos_6        = !lives_xpos_2
!lives_ypos_6        = !lives_ypos+$08
!lives_xpos_7        = !lives_xpos_6+$08
!lives_ypos_7        = !lives_ypos+$08
!lives_xpos_8        = !lives_xpos_7+$08
!lives_ypos_8        = !lives_ypos+$08

!coins_xpos          = !score_10thous_xpos
!coins_ypos          = !score_10thous_ypos-$08

!coins_xpos_1        = !coins_xpos
!coins_xpos_2        = !coins_xpos_1+$08
!coins_xpos_3        = !coins_xpos_2+$10
!coins_xpos_4        = !coins_xpos_3+$08

!star_ypos	     = $18
!star_xpos	     = !item_box_bl_xpos-$20

!star_xpos_1         = !star_xpos+$8
!star_xpos_2         = !star_xpos_1+$08
!star_xpos_3         = !star_xpos_2+$08

!score_ypos          = !item_box_tl_ypos+$10

!score_mils_xpos     = $B0
!score_mils_ypos     = !score_ypos
!score_hunthous_xpos = !score_mils_xpos+$08
!score_hunthous_ypos = !score_ypos
!score_10thous_xpos  = !score_hunthous_xpos+$08
!score_10thous_ypos  = !score_ypos
!score_thous_xpos    = !score_10thous_xpos+$08
!score_thous_ypos    = !score_ypos
!score_100s_xpos     = !score_thous_xpos+$08
!score_100s_ypos     = !score_ypos
!score_tens_xpos     = !score_100s_xpos+$08
!score_tens_ypos     = !score_ypos
!score_ones_xpos     = !score_tens_xpos+$08
!score_ones_ypos     = !score_ypos

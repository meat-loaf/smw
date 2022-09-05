; this patch cleans up the enemy_stack hijack if you had `move_with_plats' enabled
; and wish to remove the sprite from your list.
; You can also achieve this by disabling the define and re-running PIXI, but this
; is simply here for convinence.

org $01B49C|!bank
	BNE solid_plats_move_mario_abort_contact
org $01B4A6|!bank
solid_plats_move_mario:
	CLC
	ADC $94
	STA $94
	TYA
	ADC $94+$01
	STA $94+$01
.abort_contact:
	SEC
	RTS
warnpc $01B4B2|!bank

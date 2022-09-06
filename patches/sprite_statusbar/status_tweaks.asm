includefrom "status.asm"

pushpc
; replace leading zero in time with space
org $008E8A+$01|!bank
	db !blank_digit_ix

; replace leading zero in score with space
org $008EE5+$01|!bank
	db !blank_digit_ix
org $008EE5+$01|!bank
	db !blank_digit_ix

; replace leading zero in lives with space
org $008F53+$01|!bank
	db !blank_digit_ix

; replace leading zero in coins with space
org $008F7C+$01|!bank
	db !blank_digit_ix

; replace spaces in dragon coin counter with space
org $008FE6+$01|!bank
	db !blank_digit_ix

; replace dragon coin tile index
org $008FEC+$01|!bank
	db !coin_tile_ix

; replace the index to the 'empty' character used for bonus stars
org $008FA3|!bank
	db !blank_digit_ix

; skip over the code that draws the big bonus star numbers
; over the small ones.
org $008FAF|!bank
    BRA no_beeg_bonus
org $008FC0|!bank
no_beeg_bonus:

pullpc

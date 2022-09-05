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
	!bank8 = $00
else
	lorom
	!sa1 = 0
	!fullsa1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!bank8 = $80
endif

; puff of smoke
org $02972D|!bank
	autoclean JML puff_sprite_store_1
	NOP
puff_store_done_1:

org $029776|!bank
	autoclean JSL puff_sprite_store_2
	NOP

org $02A39C|!bank
	autoclean JSL puff_sprite_store_2
	NOP

org $029776|!bank

; contact graphic
org $0297EA|!bank
	autoclean JML contact_props
contact_tile_store:
warnpc $0297EE|!bank

org $029981|!bank
	autoclean JML turn_smoke_props
	NOP
turn_smoke_tile_store:
warnpc $029986|!bank

freecode
puff_sprite_store_1:
	ORA.b $64
	      ; your palette (yxppccct)
	ORA.b #$02
	STA.w $0303|!addr,y
	JML puff_store_done_1|!bank
puff_sprite_store_2:
	ORA.b $64
	      ; your palette (yxppccct)
	ORA.b #$02
	STA.w $0203|!addr,y
	RTL
;	JML puff_store_done_2|!bank
contact_props:
	AND.b #$40
	      ; your palette (yxppccct)
	ORA.b #$02
	ORA.b $64
	JML contact_tile_store|!bank

turn_smoke_props:
	      ; your palette (yxppccct)
	LDA.b #$02
	ORA.b $64
	STA.w $0203|!addr,y
	JML turn_smoke_tile_store|!bank

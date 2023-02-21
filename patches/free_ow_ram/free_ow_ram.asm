; This is a dumb hijack that initializes the overworld
; sprite ram in gamemode 0c instead of gamemode 04.
; frees up 0ddf through 0ef4 (inclusive) for use in levels.
; note that the ram is not cleared during level load

if read1($00FFD5) == $23
	sa1rom
	!bank = $000000
	!addr = $6000
else
	lorom
	!bank = $800000
	!addr = $0000
endif

; gamemode 04: original ow sprite initialization
;              not necessary to nop this here but it shows the patch works
org $009AA4|!bank
	nop #4

org $00A08A|!bank
autoclean \
	jml overworld_load_hijack

freecode
overworld_load_hijack:
	; load overworld sprites
	jsl $04F675|!bank

	; restore hijacked code...
	lda $1b9c|!addr
	beq .no_star_warp
	jsl $04853B|!bank
.no_star_warp:
	; return to original code
	jml $00A093|!bank

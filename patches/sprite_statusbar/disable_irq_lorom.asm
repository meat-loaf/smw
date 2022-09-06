includefrom "status.asm"
; use an alternate means of disabling the status bar IRQ on sa1, such as kevin's patch
; here: https://www.smwcentral.net/?p=section&a=details&id=28449
; You can use his patch with lorom instead of mine as well, if you like.
if not(!sa1)

pushpc
; this is pretty much just kevin's patch. thanks kevin for making a sane patch

org $0081F4|!bank
	NOP #3         ; subroutine call to DrawStatusBar
org $0082E8|!bank
	NOP #3         ; subroutine call to DrawStatusBar

; i think this should be able to be done inline, but i fucked up
; the overworld when i tried it
org $008294|!bank
	JML check_flag_2


; disable bg3 dma to vram
org $00A5A8|!bank
	NOP #3

pullpc
check_flag_2:
	; Always enable the IRQ in mode 7 boss rooms.
	LDA $0D9B|!addr
	BMI .enable
	LDA #$81 : STA $4200
	LDA $22 : STA $2111
	LDA $23 : STA $2111
	LDA $24 : STA $2112
	LDA $25 : STA $2112
	LDA $3E : STA $2105
	LDA $40 : STA $2131
	JML $0082B0|!bank
.enable:
	LDA $4211
	STY $4209
	JML $00829A|!bank
endif

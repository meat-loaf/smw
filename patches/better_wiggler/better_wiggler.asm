;;;;;;;;;;;;;;;~~better wiggler~~;;;;;;;;;;;;;;;;
; by: meatloaf                                  ;
;  This patch rewrites a lot of wigglers code   ;
;  to:                                          ;
;    * use a ring for the segment buffer        ;
;      management, saving over 800 cycles per   ;
;      frame for each on-screen wiggler         ;
;    * using any sprite header with wigglers    ;
;    * can increase number of allowed wigglers  ;
;      if desired                               ;
;    * as a bonus, makes it easy to remap       ;
;      wiggler if you like, as I rewrote the    ;
;      graphics routine anyway.                 ;
;                                               ;
;  Most of the changes are in-place, the only   ;
;  freecode needed is for the 'segment buffer   ;
;  slot' finding logic, as that simply won't    ;
;  fit in-place.                                ;
;                                               ;
;  The biggest downside by far is it fails      ;
;  to work properly with the proper sprite      ;
;  header from the original game ($0A).         ;
;  You probably want to use another oam         ;
;  allocation mechanism anyway.                 ;
;                                               ;
;  Please see the readme and read the provided  ;
;  comments here, especially with regards to    ;
;  changing ram addresses or the number of      ;
;  available wigglers. If the patch fails an    ;
;  assertion, you broke something (:            ;
;                                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; number of allowed active wigglers
; note: ensure both buffers are large enough if using more than four wigglers!
;       each wiggler needs a buffer segment 128 ($80) bytes large, see the
;       !wiggler_segment_buffer define.
;       A small array is also used for tracking active wigglers, it needs to be a
;       contiguous piece of freeram large enough for the number of wigglers chosen.
;       It must also be in the wram mirror. The default location is exactly 4 bytes.
!nwigglers = 4

; set to nonzero to use the game's original sprite load table address.
; pixi and the sa1 patch move it by default.
!disable_255_sprites_per_lvl = 0

; graphics stuff. remap if you like.
!wiggler_head_tile       = $8C
!wiggler_angry_eyes_tile = $88
!wiggler_flower_tile     = $98
!wiggler_body_1          = $C4
!wiggler_body_2          = $C6
!wiggler_body_3          = $C8
; yxppccct
!wiggler_flower_palette  = $0A

if read1($00FFD5) == $23
	sa1rom
	!sa1 = 1
	!dp = $3000
	!addr = $6000
	!bank = $000000

	!wiggler_segment_buffer = $418800

	!spl_255_disabled = 0

	; do not change these, unless the sa1 patch does!
	!sprite_y_low_pointer = $CC
	!sprite_x_low_pointer = $EE
	!sprite_num_cache = $87
else
	lorom
	!sa1 = 0
	!fullsa1 = 0
	!dp = $0000
	!addr = $0000
	!bank = $800000
	!spl_255_disabled = !disable_255_sprites_per_lvl

	!wiggler_segment_buffer = $7F9A7B
endif


macro define_sprite_table(name, addr, addr_sa1)
	if !sa1 == 0
		!<name> = <addr>
	else
		!<name> = <addr_sa1>
	endif
endmacro

macro spr_x_low(op, ix)
	if not(!sa1)
		<op>.b $E4,<ix>
	else
		<op>.b (!sprite_x_low_pointer)
	endif
endmacro

macro spr_y_low(op, ix)
	if not(!sa1)
		<op>.b $D8,<ix>
	else
		<op>.b (!sprite_y_low_pointer)
	endif
endmacro

macro sprite_num(op, ix)
	if not(!sa1)
		<op>.b $9E,<ix>
	else
		<op>.b !sprite_num_cache
	endif
endmacro


%define_sprite_table("C2", $C2, $D8)
%define_sprite_table(sprite_status, $14C8, $3242)
%define_sprite_table("160E", $160E, $33E4)
%define_sprite_table("151C", $151C, $3284)
%define_sprite_table("1528", $1528, $329A)
%define_sprite_table("1570", $1570, $331E)
%define_sprite_table("157C", $157C, $3334)
%define_sprite_table("15EA", $15EA, $33A2)
%define_sprite_table("15F6", $15F6, $33B8)
%define_sprite_table("161A", $161A, $7578)

if not(!spl_255_disabled)
	%define_sprite_table("sprite_load_table", $7FAF00, $418A00)
else
	!sprite_load_table = $1938
endif

; leave this
!wiggler_segment_ptr      = $D5

; (previously) unused sprite tables
!wiggler_buffer_index     = !160E
!wiggler_segbuff_position = !1528

; freeram, at least !nwigglers in size.
; if it is too small and spills into unrelated memory,
; wigglers will end up sharing slots and will
; appear in seemingly random places

; really, it should be initialized to all #$80
; (or anything negative), but in practice, zero
; initialized is fine.
!wiggler_segment_slots    = $0DC3|!addr

org $02EFEA|!bank
padbyte $EA
pad $02EFF2|!bank
wiggler_init:
	PHB
	PHK
	PLB
	JSR.w $02D4FA|!bank
autoclean \
	JML.l wiggler_init_find_segslot
.segptr_init:
	JSR.w wiggler_segment_ptr_init
	LDY.b #$7F
.seg_buff_init_loop:
	%spr_y_low(LDA,x)
	STA.b [!wiggler_segment_ptr],y
	DEY
	%spr_x_low(LDA,x)
	STA.b [!wiggler_segment_ptr],y
	DEY
	BPL.b .seg_buff_init_loop
.seg_init_done:
	PLB
	RTL

wiggler_segment_ptr_init:
	LDY !wiggler_buffer_index,x
	LDA.b #!wiggler_segment_buffer
	CLC
	ADC.w wiggler_seg_off_lo|!bank,y
	STA.b !wiggler_segment_ptr+$0
	LDA.b #!wiggler_segment_buffer>>8
	ADC.w wiggler_seg_off_hi|!bank,y
	STA.b !wiggler_segment_ptr+$1
	LDA.b #!wiggler_segment_buffer>>16
	STA.b !wiggler_segment_ptr+$2
	RTS
warnpc $02F029|!bank
assert wiggler_init == $02EFF2|!bank, "Wiggler init routine moved"

; very beginning of wiggler main (after the wrapper)
org $02F035|!bank
	JSR.w wiggler_segment_ptr_init|!bank
org $02F067|!bank
wiggler_offscreen_invoc:
	JMP.w wiggler_offscreen_call|!bank
.done:

org $02F0DB|!bank
wiggler_update_segment_buffer:
	LDA   !wiggler_segbuff_position,x
	DEC
	DEC
	AND.b #$7E
	STA   !wiggler_segbuff_position,x
	TAY
	%spr_x_low(LDA,x)
	STA.b [!wiggler_segment_ptr],y
	INY
	%spr_y_low(LDA,x)
	STA.b [!wiggler_segment_ptr],y
	RTS
wiggler_offscreen_call:
	JSR.w $02D025|!bank
	LDA.w !sprite_status,x
	BNE.b .nodespawn
	LDA.b #$80
	LDY.w !wiggler_buffer_index,x
	STA.w !wiggler_segment_slots,y
.nodespawn:
	JMP.w wiggler_offscreen_invoc_done
warnpc $02F104|!bank


;; graphics routine stuff follows
; this is relocated slightly
org $02F0D8|!bank
	JMP.w wiggler_gfx|!bank

org $02F2D3|!bank
wiggler_small_tile_xoffs:
	db $00,$08
	db $04,$04

; note: original graphics stuff start
org $02F103|!bank
; moved to allow room for expansion
wiggler_seg_off_lo:
	db $00,$80,$00,$80
wiggler_seg_off_hi:
	db $00,$00,$01,$01

; pads the graphics routine; the assertion
; at the end needs to pass, there's more
; (of the original) code that follows it
; i'm not just going to branch to the
; original location, thats ridiculous
	padbyte $EA
	pad $02F113|!bank
wiggler_segment_buff_offs:
	db $00,$1E,$3E,$5E,$7E
wiggler_segment_yoffs:
	db $00,$01,$02,$01
wiggler_body_tiles:
	db !wiggler_body_1
	db !wiggler_body_2
	db !wiggler_body_3
	db !wiggler_body_1
wiggler_small_tiles:
	db !wiggler_flower_tile
	db !wiggler_flower_tile
	db !wiggler_angry_eyes_tile
	db !wiggler_angry_eyes_tile
wiggler_small_tile_yoffs:
	db $F8,$F8
	db $00,$00
wiggler_gfx:
	JSR.w $02D378|!bank
	LDA.w !1570,x     ; \ animation frame counter
	STA.b $03         ; /
	LDA.w !15F6,x     ; \ yxppccct
	STA.b $07         ; /
	LDA.w !151C,x     ; \ wiggler is angry flag
	STA.b $08         ; /
	LDA   !C2,x       ; \ bitfield: segment direction flag
	STA.b $02         ; /
	LDA   !wiggler_segbuff_position,x
	STA.b $0C
	LDX.b #$00
.draw_loop:
	INY   #4          ; angry face/flower tile drawn later
	STY.b $0A         ; > sprite OAM index
	STX.b $05
	LDA.b $03
	LSR   #3
	CLC
	ADC.b $05         ; current loop index
	AND.b #$03
	STA.b $06         ; body tile yoff table index
	LDA.w wiggler_segment_buff_offs,x
	LDY.b $08
	BEQ.b .no_angry
	LSR
	AND.b #$FE
.no_angry:
	CLC
	ADC.b $0C
	AND.b #$7E
	TAY
	STY.b $09         ; index to segment buffer
	LDA.b [!wiggler_segment_ptr],y
	SEC
	SBC.b $1A
	LDY.b $0A
	STA.w $0300|!addr,y
	LDY.b $09
	INY
	LDA.b [!wiggler_segment_ptr],y
	SEC
	SBC.b $1C
	LDX.b $06
	SEC
	SBC.w wiggler_segment_yoffs,x
	LDY.b $0A
	STA.w $0301|!addr,y
	LDA.b #!wiggler_head_tile
	LDX.b $05
	BEQ .draw_head
	LDX.b $06
	LDA.w wiggler_body_tiles,x
.draw_head:
	LDY.b $0A
	STA.w $0302|!addr,y
	LDA.b $07
	ORA.b $64
	LSR.B $02
	BCS .no_flip
	ORA.b #$40
.no_flip:
	STA.w $0303|!addr,y
	LDX.b $05
	; changing this to a DEX/BPL would require reversing the bitfield
	; in the C2 table, at least
	INX
	CPX.b #$05
	BNE.b .draw_loop
	LDX.w $15E9|!addr
	LDY.w !15EA,x
	LDA.b $08
	ASL
	ORA.w !157C,x           ; horz facing dir
	TAX
	LDA.w wiggler_small_tiles,x
	STA.w $0302|!addr,y
	; carry clear free from above: won't overflow
	LDA.w $0304|!addr,y
	ADC.w wiggler_small_tile_xoffs,x
	STA.w $0300|!addr,y
	LDA.w $0305|!addr,y
	CLC
	ADC.w wiggler_small_tile_yoffs,x
	STA.w $0301|!addr,y
	LDA.w $0307|!addr,y
	CPX.b #$02
	BCS.b .not_flower
	AND.b #$F1
	ORA.b #!wiggler_flower_palette
.not_flower:
	STA.w $0303|!addr,y
	TYA
	LSR   #2
	TAY
	; store tilesizes
	; this is shorter and less cycles than
	; staying in 8-bit mode
	REP.b #$20
	LDA.w #$0200
	STA.w $0460|!addr,y
	; this is one byte larger but one cycle
	; faster than two INCs
	LDA.w #$0202
	STA.w $0462|!addr,y
	STA.w $0464|!addr,y
	SEP.b #$20

	LDX.w $15E9|!addr
	LDA.b #$05
	LDY.b #$FF
	; call finish oam write routine
	JSL.l $01B7B3|!bank
	; drop into original code
.fin:
assert .fin == $02F202|!bank
warnpc $02F202|!bank


freecode
wiggler_init_find_segslot:
	TYA               ; \ restore code
	STA.w !157C,x     ; /
	LDY #!nwigglers-1
.findslot_loop
	LDX.w !wiggler_segment_slots,y
	; if negative, a wiggler despawned and cleared the slot
	BMI .found
	; check that we've spawned in a slot
	; that a wiggler sat in previously
	CPX.w $15E9|!addr
	BEQ .found
	%sprite_num(LDA,x)
	CMP.b #$86
	BNE.b .found
	LDA.w !sprite_status,x
	BEQ.b .found
	DEY
	BPL.b .findslot_loop
.spawn_fail:
	LDX.w $15E9|!addr
	; kill self: no room to spawn (ensure enabling respawn)
if !spl_255_disabled
	LDA.b #$00
	LDY.w !161A,x
	STA.w !sprite_status,x
else
	LDA.w !161A,x
	TAX
	LDA.b #$00
	STA.l !sprite_load_table,x
	LDX.w $15E9|!addr
endif
	STZ.w !sprite_status,x
	JML.l wiggler_init_seg_init_done|!bank
.found:
	LDA.w $15E9|!addr
	; store this wigglers sprite slot number to
	; track what slot has what index
	STA.w !wiggler_segment_slots,y
	; x gets sprite slot
	TAX
	; a gets wiggler segment buffer index
	TYA
	; track the buffer index in a previously unused sprite table
	STA.w !wiggler_buffer_index,x
	JML.l wiggler_init_segptr_init|!bank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                  ;;
;; Super Mario Maker-styled Enemy stacks                            ;;
;; by meatloaf, inspired by d^4's version                           ;;
;;  It uses a table to control sprite spawns instead                ;;
;;  of extra bytes (with the table index from extra bytes). The     ;;
;;  stack is a 'slave' to the bottom-most sprite: it will respawn   ;;
;;  if the bottom sprite despawns and will not respawn if the       ;;
;;  bottom sprite dies.                                             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                  ;;
;; The tables are a little clunky to setup at first. (Search        ;;
;; for the 'spawn_table_start()' macro invocation below.            ;;
;; An entry is 'wrapped' by invocations of                          ;;
;; spawn_table_entry_start/finish(). Sprites are defined with       ;;
;; one of 5 macros, for the number of extra bytes that sprite       ;;
;; will spawn with, up to 4. The arguments to these macros are      ;;
;; as follows:                                                      ;;
;;  * sprite number: Sprite number you want to spawn. PIXI list     ;;
;;                   number for custom sprites, as is tradition     ;;
;;  * sprite state: The state (i.e. $14C8 val) you want the         ;;
;;                  sprite to spawn in. Generally, 01, 08 or 09.    ;;
;;                  for init, main (skipping init) and carryable.   ;;
;;                  Use koopa in state 09 for shells!               ;;
;;  * is_custom: 1 to spawn a custom sprite,                        ;;
;;               0 to spawn a normal sprite                         ;;
;;  * exbit: 1 to set the extra bit. 0 to unset it.                 ;;
;;  * Then, the values of each extra bit, from 1 to 4, follow.      ;;
;; names of the macros are spawn_table_spr_entry_[N]_exbyte,        ;;
;; where [N] gets replaced by the number of extra bytes that        ;;
;; you wish that slot to have (e.g. spawn_table_spr_entry_3_exbyte) ;;
;; The stack entries are bottom-to-top (the macro that is           ;;
;; higher towards the top of the file will appear lower on the      ;;
;; stack).                                                          ;;
;; See some of the examples to get an idea how to set up a stack,   ;;
;; or the readme for mroe detailled information on this sprite.     ;;
;;                                                                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!nsprites                = !C2
!self_spawned_flag       = !1570
!stack_sprite_1_ix       = !151C
!stack_sprite_2_ix       = !1528
!stack_sprite_3_ix       = !1534
!stack_sprite_4_ix       = !157C
!stack_sprite_5_ix       = !1594
!stack_sprite_6_ix       = !1602
!stack_sprite_7_ix       = !160E
!stack_sprite_8_ix       = !1626
if !sa1
!stack_sprite_9_ix       = !1504
!stack_sprite_10_ix      = !1510
!stack_sprite_11_ix      = !187B
!stack_sprite_12_ix      = !1FD6
endif
; used as a backup of last frame's sway index, if swaying is enabled
!sway_last_frame         = !1588

; this is a timer, so it will clear itself
; as long as we only set it to 1 :)
!on_plat                 = !1FE2

if !sa1
	!stack_size_max = 12
else
	!stack_size_max = 8
endif

; sway the sprites in the stack back and forth slightly
!sway = 1

; set to 0 to not move mario with platforms.
!move_with_plats = 1

; if `move_with_plats' and `sway' are both enabled,
; sway the player with the platform
; TODO currently buggy
!do_plat_sway = 0

!plat_sway #= !sway&!do_plat_sway

; freeram that holds the sprite index of the platform mario is
; standing on. used if `move_with_plats' is enabled.
!plat_ix_ram = !on_platform_ix

!wiggler_segment_ptr = $D5
!num_sprites = !SprSize

; used as scratch when spawning, to hold current position to spawn
; a sprite at.
!spr_xpos_scratch = $48
!spr_ypos_scratch = $4A
; used to offset mario with the swaying of the platforms,
; if `sway' is enabled
; used  as scratch when `move_with_plats' is set.

!scr_spawned_count = $8A
!scr_spawn_nsprs   = $8B
!scr_ebits_ebytes  = $8C

!scr_sway_diff     = $09
!scr_ix_tbl_lo     = $0A
!scr_ix_tbl_hi     = $0B
!scr_sway_val_lo   = $0C
!scr_sway_val_hi   = $0D
!scr_sway_off      = $0E
!scr_is_carrying   = $0F

; spawn_safe define:
; when set to non-zero, don't spawn into the last two
; sprite slots, which are typically reserved for powerups.
; If you're not using NMSTL or another oam allocator, you'll
; have issues with sprites using more than one oam tile in these
; slots.

; maybe it should use the games original spawn routine JSL.
; at any rate, you likely want this: otherwise things spawned
; from blocks can eject many sprites in high slots, replacing
; things in your stack!
!spawn_safe = 1


if !spawn_safe
	!spawn_slot_ix_start = !num_sprites-$03
else
	!spawn_slot_ix_start = !num_sprites-$01
endif

print "INIT", hex(estack_init)
print "MAIN", hex(estack_main)

; set up current position in scratch
macro pos_to_scratch(reg)
	LDA !E4,<reg>
	STA !spr_xpos_scratch
	LDA !14E0,<reg>
	STA !spr_xpos_scratch+$01
	LDA !D8,<reg>
	STA !spr_ypos_scratch
	LDA !14D4,<reg>
	STA !spr_ypos_scratch+$01
endmacro

; bits packed are:
; ---z zzec
; z: number of extra bytes
; e: extra bit
; c: 'is custom; extra bit

function pack_exbits_nbytes(is_custom, exbit, n_exbytes) = ((n_exbytes&$07)<<2)|((exbit&$01)<<1)|(is_custom&$01)

macro spawn_table_start()
assert not(defined("_n_spawntable_entries")), "Only use the `spawn_table_start` macro once!"
!_n_spawntable_entries #= 0
spawn_table:
endmacro

macro spawn_table_finish()
spawn_table_ptrs:
	!_ix #= 0
	while !_ix < !_n_spawntable_entries
		dw spawn_table__!{_ix}
		!_ix #= !_ix+1
	endif
endmacro

macro spawn_table_entry_start()
	assert not(defined("_n_entries")), "Use the `spawn_table_entry_finish' macro before starting to define a new stack."
	!_n_entries #= 0
endmacro

; builds a table with the following data for a single sprite stack:
; * number of sprites to spawn
; * then the following for each sprite in the stack:
;   * state to spawn the sprite in 
;   * packed extra bits/how many extra bytes
;     * the values for each extra byte follow
macro spawn_table_entry_finish()
	assert !_n_entries <= !stack_size_max, "Max configured stack size is !{stack_size_max}, stack index !{_n_spawntable_entries} has !{_n_entries} entries."
._!{_n_spawntable_entries}:
	db !_n_entries
	!_spr_ix #= 0
	while !_spr_ix < !_n_entries
		db !{_spr_!{_spr_ix}_state}
		db !{_spr_!{_spr_ix}_exbiby}
		db !{_spr_!{_spr_ix}_num}
		!_spr_arg_ix #= 0
		assert defined("_spr_!{_spr_ix}_sz"), "Sprite !_spr_ix doesn't have exbyte size defined"
		while !_spr_arg_ix < !{_spr_!{_spr_ix}_sz}
			db !{_spr_!{_spr_ix}_arg_!{_spr_arg_ix}}
			undef "_spr_!{_spr_ix}_arg_!{_spr_arg_ix}"
			!_spr_arg_ix #= !_spr_arg_ix+1
		endif
		undef "_spr_!{_spr_ix}_sz"
		undef "_spr_arg_ix"
		undef "_spr_!{_spr_ix}_state"
		undef "_spr_!{_spr_ix}_exbiby"

		!_spr_ix #= !_spr_ix+1
	endif
	undef "_spr_ix"
	undef "_n_entries"

	!_n_spawntable_entries #= !_n_spawntable_entries+1
endmacro

; TODO maybe these can be consolidated with a variadic helper macro
; but variadic macros expanding defines on definition (and not invocation) makes it
; kinda hard
macro spawn_table_spr_entry_0_exbyte(spr_num, spr_state, is_custom, exbit)
	assert defined("_n_entries"), "Use the `spawn_table_entry_start` macro before declaring a new stack index."
	!{_spr_!{_n_entries}_num}    #= <spr_num>
	!{_spr_!{_n_entries}_state}  #= <spr_state>
	!{_spr_!{_n_entries}_exbiby} #= pack_exbits_nbytes(<is_custom>, <exbit>, 0)
	!{_spr_!{_n_entries}_sz}     #= 0
	!_n_entries #= !_n_entries+1
endmacro

macro spawn_table_spr_entry_1_exbyte(spr_num, spr_state, is_custom, exbit, eb1)
	assert defined("_n_entries"), "Use the `spawn_table_entry_start` macro before declaring a new stack index."
	!{_spr_!{_n_entries}_num}   #= <spr_num>
	!{_spr_!{_n_entries}_state} #= <spr_state>
	!{_spr_!{_n_entries}_sz}    #= 1
	!{_spr_!{_n_entries}_exbiby} #= pack_exbits_nbytes(<is_custom>, <exbit>, 1)
	!{_spr_!{_n_entries}_arg_0} #= <eb1>
	!_n_entries #= !_n_entries+1
endmacro

macro spawn_table_spr_entry_2_exbyte(spr_num, spr_state, is_custom, exbit, eb1, eb2)
	assert defined("_n_entries"), "Use the `spawn_table_entry_start` macro before declaring a new stack index."
	!{_spr_!{_n_entries}_num}   #= <spr_num>
	!{_spr_!{_n_entries}_state} #= <spr_state>
	!{_spr_!{_n_entries}_sz}    #= 2
	!{_spr_!{_n_entries}_exbiby} #= pack_exbits_nbytes(<is_custom>, <exbit>, 2)
	!{_spr_!{_n_entries}_arg_0} #= <eb1>
	!{_spr_!{_n_entries}_arg_1} #= <eb2>
	!_n_entries #= !_n_entries+1
endmacro

macro spawn_table_spr_entry_3_exbyte(spr_num, spr_state, is_custom, exbit, eb1, eb2, eb3)
	assert defined("_n_entries"), "Use the `spawn_table_entry_start` macro before declaring a new stack index."
	!{_spr_!{_n_entries}_num}   #= <spr_num>
	!{_spr_!{_n_entries}_state} #= <spr_state>
	!{_spr_!{_n_entries}_sz}    #= 3
	!{_spr_!{_n_entries}_exbiby} #= pack_exbits_nbytes(<is_custom>, <exbit>, 3)
	!{_spr_!{_n_entries}_arg_0} #= <eb1>
	!{_spr_!{_n_entries}_arg_1} #= <eb2>
	!{_spr_!{_n_entries}_arg_2} #= <eb3>
	!_n_entries #= !_n_entries+1
endmacro

macro spawn_table_spr_entry_4_exbyte(spr_num, spr_state, is_custom, exbit, eb1, eb2, eb3, eb4)
	assert defined("_n_entries"), "Use the `spawn_table_entry_start` macro before declaring a new stack index."
	!{_spr_!{_n_entries}_num}   #= <spr_num>
	!{_spr_!{_n_entries}_state} #= <spr_state>
	!{_spr_!{_n_entries}_sz}    #= 4
	!{_spr_!{_n_entries}_exbiby} #= pack_exbits_nbytes(<is_custom>, <exbit>, 4)
	!{_spr_!{_n_entries}_arg_0} #= <eb1>
	!{_spr_!{_n_entries}_arg_1} #= <eb2>
	!{_spr_!{_n_entries}_arg_2} #= <eb3>
	!{_spr_!{_n_entries}_arg_3} #= <eb4>
	!_n_entries #= !_n_entries+1
endmacro

;; START SPRITE STACK DEFINITIONS ;;
%spawn_table_start()
	; entry 00 00: chargin chuck, grey platform that falls
	%spawn_table_entry_start()
	%spawn_table_spr_entry_0_exbyte($91, $08, $00, $00)
	%spawn_table_spr_entry_0_exbyte($C4, $08, $00, $00)
	%spawn_table_entry_finish()

	; entry 01 00: red koopa, volcano lotus
	%spawn_table_entry_start()
	%spawn_table_spr_entry_0_exbyte($05, $01, $00, $00)
	%spawn_table_spr_entry_0_exbyte($99, $01, $00, $00)
	%spawn_table_entry_finish()

	; entry 02 00: jumpin' piranha plant (spits fireballs), key, vert/horz turn block bridge
	%spawn_table_entry_start()
	%spawn_table_spr_entry_0_exbyte($71, $01, $00, $00)
	%spawn_table_spr_entry_0_exbyte($80, $09, $00, $00)
	%spawn_table_spr_entry_0_exbyte($59, $08, $00, $00)
	%spawn_table_entry_finish()

%spawn_table_finish()

;; END SPRITE STACK DEFINITIONS ;;

if !move_with_plats
pushpc
org $01B49C|!bank
	BNE solid_plats_hijack_done
org $01B4A6|!bank
solid_plats_hijack:
	JML.l solid_plats_move_mario|!bank
.done:
	; note: this value is stale if mario does not touch
	; a platform during a frame. Check that $1471 is non-zero
	; before using.
	STX !plat_ix_ram
	SEC
	RTS
warnpc $01B4B2|!bank
pullpc
solid_plats_move_mario:
	CLC
	ADC $94
	STA $94
	TYA
	ADC $94+$01
	STA $94+$01
	JML.l solid_plats_hijack_done|!bank
else
pushpc
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
pullpc
endif


if !move_with_plats
; used to respawn self in lowest possible sprite slot
; note: extra bits not preserved as they aren't used
respawn_self:
	LDA !E4,x
	STA !E4,y
	LDA !14E0,x
	STA !14E0,y
	LDA !D8,x
	STA !D8,y
	LDA !14D4,x
	STA !14D4,y

	STZ !14C8,x
	LDA #$01
	STA !14C8,y

	LDA !9E,x
	STA !9E,y

	LDA !161A,x
	STA !161A,y

	LDA !extra_byte_1,x
	STA $00
	LDA !extra_byte_2,x
	STA $01

	LDA !new_sprite_num,x
	TYX
	STA !new_sprite_num,x
	LDA $00
	STA !extra_byte_1,x
	LDA $01
	STA !extra_byte_2,x

	LDA #$08
	STA !extra_bits,x
	STA !self_spawned_flag,x
	
	LDX $15E9|!addr
	RTL
endif

estack_init:
if !move_with_plats
	LDA !self_spawned_flag,x
	BNE .skip_spawn_loop
	LDY #$00
.low_loop:
	LDA !14C8,y
	BEQ respawn_self
	INY
	CPY $15E9|!addr
	BNE .low_loop
.skip_spawn_loop:
endif
if !plat_sway
	LDA #$FF
	STA !sway_last_frame,x
endif
	; fall through to here if we're in the lowest possible slot already
	%pos_to_scratch(x)

	LDA #spawn_table_ptrs>>16
	STA !wiggler_segment_ptr+$02
	LDA !extra_byte_2,x
	XBA
	LDA !extra_byte_1,x
	REP #$30
	ASL
	TAX
	; note: table is macro-generated
	LDA.l spawn_table_ptrs|!bank,x
	STA !wiggler_segment_ptr+$00
	SEP #$30

	LDY #$00
	LDA [!wiggler_segment_ptr],y  ; load number of sprites to try and spawn
        ; counter for number of sprites actually spawned
	STZ !scr_spawned_count
	; total number to attempt to spawn
	STA !scr_spawn_nsprs
	LDX #!spawn_slot_ix_start
.spawn_loop:
	LDA !14C8,x
	BEQ .spawn
	DEX
	BPL .spawn_loop
	JMP .done
.spawn:
	INY          ; y = index to initial sprite state
	LDA [!wiggler_segment_ptr],y
	STA !14C8,x
	INY          ; y = index to packed extra bits/bytes
	LDA [!wiggler_segment_ptr],y
	LSR          ; carry has if sprite is custom
	STA !scr_ebits_ebytes
	INY          ; y = index to sprite number
	LDA [!wiggler_segment_ptr],y
	STA !9E,x
	STA !new_sprite_num,x
	JSL $07F7D2|!bank
	BCC .not_custom_2
	LDA #$08
	STA !extra_bits,x
	JSL $0187A7|!bank
.not_custom_2:
	; setup position
	LDA !spr_xpos_scratch
	STA !E4,x
	LDA !spr_xpos_scratch+$01
	STA !14E0,x

	LDA !spr_ypos_scratch
	STA !D8,x

	LDA !spr_ypos_scratch+$01
	STA !14D4,x

	LDA !scr_ebits_ebytes
	LSR
	STA !scr_ebits_ebytes
	BCC .no_exbit
	LDA.b #$04
	ORA !extra_bits,x
	STA !extra_bits,x
.no_exbit:
	BEQ .cont
	INY
	LDA [!wiggler_segment_ptr],y
	STA !extra_byte_1,x
	DEC !scr_ebits_ebytes
	BEQ .cont
	INY
	LDA [!wiggler_segment_ptr],y
	STA !extra_byte_2,x
	DEC !scr_ebits_ebytes
	BEQ .cont
	INY
	LDA [!wiggler_segment_ptr],y
	STA !extra_byte_3,x
	DEC !scr_ebits_ebytes
	BEQ .cont
	INY
	LDA [!wiggler_segment_ptr],y
	STA !extra_byte_4,x
.cont:
	; this might be able to be condensed, this is quite a bit of register
	; fuckery. This init is already somewhat cycle-intensive.
	; Issue is, the way its written both Y (our index into the sprite spawn
	; info table) and X (our loop index) Are expected to be preserved here.
	PHX
	LDA !scr_spawned_count
	ASL
	TAX
	LDA $15E9|!addr
	REP #$20
	AND #$00FF
	CLC
	ADC.l spr_index_table_vals,x
	STA !scr_ix_tbl_lo
	SEP #$20
	PLA
	STA (!scr_ix_tbl_lo)
	TAX

	INC !scr_spawned_count

	DEC !scr_spawn_nsprs
	BEQ .done

	DEX
	BMI .done

	JMP .spawn_loop
.done:
	LDX $15E9|!addr
	LDA !scr_spawned_count
	STA !nsprites,x
	; kill self if we spawned no sprites, or only one sprite.
	CMP #$02
	BCS .nodie
.die:
	; TODO allow respawns?
	STZ !14C8,x
.nodie:
	RTL

estack_main:
	PHB
	PHK
	PLB
	JSR estack_main_rt

if !move_with_plats
	LDA $1471|!addr
	BEQ .no_plat
	LDA !on_plat,x
	BEQ .no_plat

	; load the sprite index of the platform...
	LDY !stack_sprite_1_ix,x
	; check if mario is blocked on the sides
	LDA $77
	AND #$03
	BNE .on_plat_vert
.on_plat:
	LDA !E4,x
	STA $00
	LDA !14E0,x
	STA $01
	LDA !14E0,y
	STA !14E0,x
	XBA
	LDA !E4,y
	STA !E4,x
	REP #$20
if !plat_sway
	CLC : ADC !scr_sway_val_lo
endif
	SEC
	SBC $00

	CLC : ADC $94
	STA $94
	SEP #$20
..vert:
	; check if mario is blocked on the top, or in the middle
	; of a block
	LDA $77
	AND #$18
	BNE ..done

	LDA !D8,x
	STA $00
	LDA !14D4,x
	STA $01
	LDA !14D4,y
	STA !14D4,x
	XBA
	LDA !D8,y
	STA !D8,x
	REP #$20
	SEC : SBC $00
	CLC : ADC $96
	STA $96
	SEP #$20
..done:
	PLB
	RTL

; sync the bottom sprites x/y position with the wrapper's
; for offset calc
.no_plat:
if !plat_sway
	LDA #$FF
	STA !sway_last_frame,x
endif
	LDY !stack_sprite_1_ix,x
	LDA !E4,y
	STA !E4,x
	LDA !14E0,y
	STA !14E0,x
	LDA !D8,y
	STA !D8,x
	LDA !14D4,y
	STA !14D4,x
endif
	PLB
	RTL

; don't despawn this wrapper when the last sprite is left:
; tie respawning it to the respawn state of the bottom-most
; sprite.
estack_short_circuit_one:
	LDA !14C8,y
	CMP #$08
	BCC die_maybe_no_respawn
	RTS

die_maybe_no_respawn:
	LDX !161A,y

if !Disable255SpritesPerLevel
	LDA !1938,x
else
	LDA.l !7FAF00,x
endif
	LDX $15E9|!addr
	CMP #$FF
	BEQ .not_despawned
if !Disable255SpritesPerLevel
	LDA #$00
	LDY !161A,x
	STA !1938,y
else
	LDA !161A,x
	TAX
	LDA   #$00
	STA.l !7FAF00,x             ;$41A800 in SA-1 ROM, so it can't be Y indexed!
	LDX $15E9|!addr
endif
.not_despawned:
	STZ !14C8,x
	RTS

estack_abort_loop:
	TXA
	LDX $15E9|!addr
	STA !nsprites,x
	RTS

estack_main_rt:
if !sway
	; swaying offset index
	LDA $14
	LSR #2
  if !plat_sway
	AND #$0F
  endif
	STA !scr_sway_off
  if !plat_sway
	STZ !scr_sway_diff
	CMP !sway_last_frame,x
	BEQ .sway_same
	STA !sway_last_frame,x
	INC !scr_sway_diff
  endif
.sway_same:
endif

	STZ !scr_is_carrying

	LDY !stack_sprite_1_ix,x

	LDA !nsprites,x
	STA !scr_spawned_count
	DEC
	BEQ estack_short_circuit_one

	LDA !14C8,y
	CMP #$08
	; if the bottom of the stack is dead, (maybe) kill self
	BCC die_maybe_no_respawn
	CMP #$0B
	ROL !scr_is_carrying
	
	%pos_to_scratch(y)

	LDX #$01
.spr_loop:
	; AHHHHHH FUCK FUCK FUCK FUCK
	PHX
	TXA
	ASL
	TAX
	LDA $15E9|!addr
	REP #$20
	AND #$00FF
	CLC
	ADC spr_index_table_vals,x
	STA !scr_ix_tbl_lo
	SEP #$20
	PLX

	LDA (!scr_ix_tbl_lo)
	TAY

	; if sprite in the middle of the stack is dead,
	; abort stacking logic completely
	LDA !14C8,y
	CMP #$08
	BCC estack_abort_loop
	CMP #$0B
	BEQ estack_abort_loop

	; nuke speed
	LDA #$00
	STA.w !AA|!dp,y
	STA.w !B6|!dp,y

	; position update
	STX !scr_spawn_nsprs

	; TODO wram mirror check
	TYX
	LDA !extra_bits,x
	AND #$04
	BNE .custom_offs
	LDA !9E,x
	TAX
	LDA orig_spr_stack_yoff,x
	STA $00
	LDA orig_spr_stack_xoff,x
	STA $01
	LDA orig_spr_stack_height,x
	STA $02
	BRA .offs_done
.custom_offs:
	LDA !new_sprite_num,x
	TAX
	LDA cust_spr_stack_yoff,x
	STA $00
	LDA cust_spr_stack_xoff,x
	STA $01
	LDA cust_spr_stack_height,x
	STA $02
.offs_done:
if !sway
	LDA !scr_sway_off
	AND #$0F
	TAX
	LDA sway_offs,x
  if !plat_sway
	LDX !scr_sway_diff
	BEQ .no_swayoff
	STA !scr_sway_val_lo
	CPY !plat_ix_ram
	BNE .sway_done
	LDA !scr_sway_val_lo
	BPL .sway_done
	DEC !scr_sway_val_hi
.no_swayoff:
	STZ !scr_sway_val_hi
	STZ !scr_sway_val_lo
.sway_done:
	INC !scr_sway_off
  endif
	CLC : ADC $01
	STA $01
endif

	LDX !scr_spawn_nsprs

	LDA !spr_xpos_scratch
	CLC : ADC $01
	STA !E4,y
	LDA $01
; TODO cursed as fuck
	BMI +
	LDA !spr_xpos_scratch+$01
	ADC #$00
	STA !14E0,y
	BRA ++
+
	LDA !spr_xpos_scratch+$01
	SBC #$00
	STA !14E0,y
++

	LDA !spr_ypos_scratch
	SEC : SBC $02

	STA !D8,y
	STA !spr_ypos_scratch

	LDA !spr_ypos_scratch+$01
	SBC #$00
	STA !14D4,y
	STA !spr_ypos_scratch+$01

; check each index to ensure the plat mario is on
; is actually part of this stack...
if !move_with_plats
.check_standing:
	CPY !plat_ix_ram
	BNE .not_this
	LDX $15E9|!addr
	INC !on_plat,x
.not_this:
endif
	LDX !scr_spawn_nsprs

	LDA !scr_is_carrying
	BEQ .skip
	; contact disable timer
	LDA #$08
	STA !154C,y
.skip:
	INX
	CPX !scr_spawned_count
	BEQ .end
	JMP .spr_loop
.end:
	LDX $15E9|!addr
	RTS

spr_index_table_vals:
	dw (!stack_sprite_1_ix)
	dw (!stack_sprite_2_ix)
	dw (!stack_sprite_3_ix)
	dw (!stack_sprite_4_ix)
	dw (!stack_sprite_5_ix)
	dw (!stack_sprite_6_ix)
	dw (!stack_sprite_7_ix)
	dw (!stack_sprite_8_ix)
if !sa1
	dw (!stack_sprite_9_ix)
	dw (!stack_sprite_10_ix)
	dw (!stack_sprite_11_ix)
	dw (!stack_sprite_12_ix)
endif


; offsets for swaying the stack left/right slightly, like in smm
sway_offs:
db $00, $01, $02, $03, $03, $02, $01, $00, $00, $FF, $FE, $FD, $FD, $FE, $FF, $00

;;; below tables are the same as d^4's original. Generally, there's no need to
;;; modify the ones for original sprites, but you can set your custom sprite 
;;; offsets yourself here.

;;; there is also a 'plat check' table. This is a flag for if each sprite is a platform
;;; (that is, it calls the solid sprite routine), which prevents mario from being moved
;;; by the wrapper entirely when the bottom sprite is a platform.

; y-offset to apply before placing sprite on stack 
cust_spr_stack_yoff:
;   00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;00-0F
db $10, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;10-1F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;20-2F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;30-3F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;40-4F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;50-5F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;60-6F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;70-7F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;80-8F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;90-9F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;A0-AF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;B0-BF
db $00, $00, $00, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;C0-CF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;D0-DF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;E0-EF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;F0-FF

; height of the sprite being placed on the stack (shifts position of next sprite)
cust_spr_stack_height:
;   00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;00-0F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;10-1F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;20-2F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;30-3F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;40-4F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;50-5F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;60-6F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;70-7F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;80-8F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;90-9F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;A0-AF
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;B0-BF
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;C0-CF
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;D0-DF
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;E0-EF
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;F0-FF

cust_spr_stack_xoff:
;   00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;00-0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $F0 ;10-1F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;20-2F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;30-3F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;40-4F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;50-5F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;60-6F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;70-7F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;80-8F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;90-9F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;A0-AF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;B0-BF
db $00, $00, $00, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;C0-CF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;D0-DF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;E0-EF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;F0-FF

; y-offset to apply before placing sprite on stack 
orig_spr_stack_yoff:
;   00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;00-0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;10-1F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;20-2F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0E ;30-3F
db $0E, $00, $00, $00, $00, $00, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;40-4F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $08 ;50-5F
db $00, $00, $08, $08, $08, $26, $06, $10, $00, $00, $00, $00, $00, $00, $0E, $00 ;60-6F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;70-7F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;80-8F
db $00, $04, $04, $04, $04, $04, $00, $04, $04, $00, $04, $00, $00, $0B, $00, $00 ;90-9F
db $00, $1E, $04, $00, $08, $00, $06, $00, $00, $00, $00, $10, $00, $00, $00, $00 ;A0-AF
db $00, $00, $00, $00, $00, $00, $00, $08, $00, $00, $00, $00, $00, $00, $00, $0E ;B0-BF
db $00, $00, $00, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;C0-CF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;D0-DF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;E0-EF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;F0-FF

; height of the sprite being placed on the stack (shifts position of next sprite)
orig_spr_stack_height:
;   00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
db $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0E, $0F ;00-0F
db $0F, $0E, $00, $0E, $0E, $0E, $0E, $0E, $0E, $00, $1E, $10, $0E, $0E, $10, $1E ;10-1F
db $10, $10, $1E, $1E, $1E, $1E, $1E, $10, $40, $00, $1E, $10, $10, $10, $10, $10 ;20-2F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $1E, $1E, $1E, $10, $10, $10 ;30-3F
db $10, $10, $10, $1E, $10, $10, $10, $10, $10, $10, $10, $1E, $10, $10, $10, $10 ;40-4F
db $10, $10, $10, $10, $10, $0C, $1E, $0C, $1E, $10, $10, $10, $0C, $1E, $1E, $08 ;50-5F
db $10, $10, $08, $0C, $48, $08, $28, $10, $10, $10, $10, $08, $08, $10, $10, $10 ;60-6F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $08, $10, $10, $10, $10 ;70-7F
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;80-8F
db $3E, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $3E ;90-9F
db $10, $10, $10, $10, $16, $10, $12, $10, $10, $2E, $10, $10, $50, $50, $1E, $10 ;A0-AF
db $10, $10, $10, $08, $20, $10, $10, $10, $10, $10, $10, $20, $10, $10, $10, $10 ;B0-BF
db $10, $10, $10, $18, $10, $3E, $10, $10, $10, $00, $10, $00, $00, $00, $00, $00 ;C0-CF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $10, $10, $10, $10, $10 ;D0-DF
db $10, $00, $00, $00, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;E0-EF
db $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10 ;F0-FF

; how far to shift the current stacked sprite left/right
orig_spr_stack_xoff:
;   00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04, $00 ;00-0F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;10-1F
db $00, $00, $00, $00, $00, $00, $00, $00, $EC, $00, $00, $00, $00, $00, $00, $00 ;20-2F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $F8, $F8, $F8, $00, $00, $00 ;30-3F
db $00, $F4, $F4, $00, $F8, $00, $00, $00, $00, $F8, $00, $00, $00, $00, $00, $00 ;40-4F
db $00, $00, $F0, $00, $00, $E0, $F0, $E0, $F0, $00, $00, $F0, $E0, $F0, $F0, $58 ;50-5F
db $F8, $00, $08, $08, $08, $08, $08, $08, $00, $00, $00, $04, $04, $00, $00, $00 ;60-6F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FC, $00, $00, $00, $00 ;70-7F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;80-8F
db $EA, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E8 ;90-9F
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;A0-AF
db $00, $00, $00, $00, $00, $00, $00, $F8, $F8, $00, $F8, $F8, $00, $00, $00, $F8 ;B0-BF
db $F0, $F0, $00, $00, $E8, $EE, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;C0-CF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;D0-DF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;E0-EF
db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ;F0-FF

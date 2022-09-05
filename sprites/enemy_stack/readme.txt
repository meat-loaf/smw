This is a sprite which enables you to create 'stacks' of enemies a la Super Mario Maker.
It was written from scratch, aside from the offset tables, which were ripped from dtothefourth's
(who is hereafter referred to as d^4) version.
I wrote my own as d^4's was quite hard to work with/make changes to, I thought it could
be improved from an efficiency and readability standpoint, and I wanted proper extra byte support.
At the moment, it's nearly at feature parity. It lacks a few minor things, currently:
  * The 'sprite height' table is entirely unused currently, which is probably the biggest omission.
  * No updating of stacked sprite facing directions at all, yet.
  * d^4's had some special handlings for different sprites in the middle of the stack (the goal tape
    and the diagonal platforms, at least) while this sprite has no such handling, currently.
  * An assemble-time toggle for stacks being carryable.
Aside from fixing the first two points above, I intend to add the following at some point:
  * Support for 'sub-stacks': that is, being able to pick apart different carryable parts of a stack and retain
    the 'stack-ness'. This almost works currently (by defining a stack to spawn another stack), but
    the positioning is off currently when doing this.
Current bugs in the implementation:
  * Sometimes (very rarely) the stack double-spawns. I think this happens because of the
    'respawn-self-in-lowest-slot' logic when standing on platforms is enabled, but I can't say for sure yet.
    It also seems like it might only occur when the screen is scrolling left.
    When this happens, it seems like only the bottom-most sprite is duplicated, though, not the entire stack.
  * Mario swaying with standable platforms currently doesn't work properly, the direction appears to be
    inversed.

Usage (defining stacks):
  Stacks are defined using provided macros. The `spawn_table_start' macro starts the entire
  list of all stacks, and is closed by the `spawn_table_finish' macro. The finish macro
  generates the list of pointers to each stack, as stacn entries variable-width.
  Each different stack is wrapped with macros as well: `spawn_table_entry_start' and
  `spawn_table_entry_finish'. To actually define sprites in the stack, the following 5 macros
  are to be used:
  * spawn_table_spr_entry_0_exbyte
  * spawn_table_spr_entry_1_exbyte
  * spawn_table_spr_entry_2_exbyte
  * spawn_table_spr_entry_3_exbyte
  * spawn_table_spr_entry_4_exbyte
  One for each of the number of extra bytes you can spawn sprites with. I couldn't come up with
  a mechanism that detected this automatically (I do not think using a variadic macro will work
  due to the way they are currently implemented in asar). The arguments to these macros are as
  follows:
  * Sprite number (for custom sprites, it's the number you provided in your sprite list file)
  * Sprite state (value of 14C8 that your sprite shall spawn in. Typically you want 1, 8, or 9 for
    init, main, or carryable respectively.). For spawning shells, use regular koopas in state 9.
  * Sprite is custom flag: 0 to spawn a normal sprite, 1 to spawn a custom sprite.
  * Extra bit: 0 to unset the extra bit in the spawned sprite, 1 to set it.
  * Extra byte values: Depending on the macro used, the appropriate number of extra bytes you wish
    to use follow the above.
  Please see the provided stacks for examples if you are confused. These macros are quite ugly, but
  they do have some logic in them to detect if they are used in the incorrect order, so you should
  get a reasonable error message (somewhere in the list of errors) if the order is incorrect when
  inserting the sprite.

Usage (inserting the sprite to your level)
  By default, the stack uses the first two extra bytes to determine which stack to invoke, allowing
  for up to 65,536 different stack combinations. The least-significant byte is first, followed by
  the most significant byte (in otherwords, it is little-endian), and is 0-based. So the first stack
  defined will have '00 00' in the Extension field in Lunar Magic, the 72nd (decimal) sprite will have
  '47 00', and the 257th entry will have '00 01'.
  Currently, the stack does not use the extra bit at all.

Usage notes:
  * There are no safeguards to ensure what you provide in Lunar Magic's extension field is a valid stack index.
    If you spawn a stack with a higher index than actually exists, you will spawn complete garbage, potentially
    crashing the game.
  * Enabling standing on platforms modifies a small part of the game's original 'solid sprites' routine, to
    store the slot of the sprite Mario is standing on to some freeram. Disabling this feature and reapplying
    sprites properly restores the routine to its original state. If you remove the sprite from your custom
    sprites list and don't clean this up, the game will crash when Mario stands on a sprite and isn't blocked
    from moving. There is a small asar patch that will clean this up so you don't have to un-toggle and reapply
    this sprite to do so.
  * Standing on platforms updates Mario's Y position as well as his X position. I don't think this ultimately
    causes any problems, but I can't say for sure as I haven't done extremely thorough testing on it yet. It does
    fix issues where the `host' sprite moves too quickly vertically and cases Mario to pass through the platform
    instead of staying on it, though.
  * On SA1, if you wish to have more stacks, you can start using some of the unused non-misc tables, such as
    the tweaker tables, 'sprite-in-water' table and others, as none of the game's routines that check these
    are used by the sprite. Note that $1588 (the sprite blocked status table) is used if 'swaying with platforms'
    is enabled, by default. Remember to update the 'stack_size_max' define when doing this (I couldn't get this
    to be set up automatically).

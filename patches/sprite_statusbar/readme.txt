This is a sprite status bar patch. It was designed mostly to fit my requirements (efficient
enough on non-sa1 to not eat up a considerable amount of scanlines drawing sprite tiles, easy
customizability), but I think (hope) it is enough to be useful generally. It's really a
'build your own sprite status bar kit' more than it is something ready to be used
out-of-the-box, but I like to think it offers simpler flexibility (once you get used to
the weird macros to place the tiles) than a lot of other sprite status bar options. It also
has compatibility with patches that modify the original status bar tilemap, as it reuses
the status bar counter update code at $008E1A. The main drawback to its current design as
it eats a rather large amount of ROM space (easily 2,000 bytes or more depending on the number
of sprite tiles you wish to draw), but it slightly boosts runtime performance as there are no cycles
wasted dealing with loop counters or branching, especially when there are a lot of counters to draw.
The base setup comes with a sample GFX01, which overwrites the shelless koopas and some
other things. It is meant as an example, not as the 'canonical' setup for this patch or anything.

The main patch to be patched to your SMW ROM is 'status.asm'.

Notes:
The included 'disable_irq.asm' completely disables the irq used by the status bar. It's interpreted
from Kevin's toggleable version. You can use any patch to disable irq that you like, however, but
this is here for completeness' sake. It only works on lorom: use another patch on SA1 to disable the
status bar irq.
By default, many of the tile position defines are relative to each other. This should make it quite
easy to shift around the provided counters however you like.
The hijack used on SA1 utilizes the OAM hijack provided by SA1 in v1.40 of the patch. I don't intend
to support changes to the patch to work on any other version.

Current limitations:
* No setup to dynamically update the Mario/Luigi player name for the lives counter. It can be done
  statically with the 'digit' counter macros, though, and some modifications to the original status
  bar code. A sprite status bar already requires quite a bit of sprite tile space, though.
* The status bar code doesn't handle the item box item at all. This is planned to be supported in
  the future, however.

Creating counters:
Realistically, you can do this however you like via the provided macros (See 'Macro information'
below), but I set up the provided ones as follows:
I defined a macro for each 'piece' of the status bar to be drawn (item box, score, coins, etc) and
this macro invokes get_next_oam_tile, draw_static_tile/draw_digit_tile in sequence. I then create a
label where the macro is invoked to expand it into code, and JSR to the label from my desired status
bar configurations.
If you don't desire to have configurations or think this is too cumbersome, you certainly can dump
all your counter macro invocations in a single place and call it a day, though.

Macro information:
There are three macros that drive the core functionality. You can use a composite of these to
create your own status bar counters (see the provided example macros in status.asm).

`get_next_oam_tile':        takes two arguments, the table of OAM offsets, and a label that is
                            jumped to when there are no tiles left in low-oam. Expects X to have
                            the current index into the provided OAM offset table, and checks tile
                            availibility by comparing the OAM tile y-position to #$F0. Simply copying
                            the provided invocations in any new counters you set up is sufficient.
                            Insure invoke this before drawing any (new) tile, or you will overwrite a
                            previously drawn tile, or complete garbage if this has not been invoked at all.
`draw_static_tile':         Draws a tile that does not change (in other words, a hardcoded tile not backed
                            by a ram address). Arguments, in order:
                              * X-Position (screen-relative) to draw the tile.
                              * Y-Position (screen-relative) to draw the tile.
                              * The tile number.
                              * Flip properties (you can use helper defines `!tile_xflip', '!tile_yflip',
                                `!tile_xyflip', and `!tile_noflip' as this argument).
                              * Palette: palette of the tile. You can use LM palette numbers here.
                              * Page: 0 for SP1/2, 1 for SP3/4
                              * Size: 0 for 8x8, 1 for 16x16
`draw_static_tile_propram': Same arguments as `draw_static_tile', with two additional arguments proceeding:
                              * Use propram toggle. Set to !true to use the ram. Otherwise,
                                is exactly the same as `draw_static_tile'.
                              * A ram address. Will be or'd in with the other static property
                                values provided. If the 'Use propram toggle' is set to true.
`draw_digit_tile':          Draws a tile based on a ram address. The code this macro generates expects
                            the ram address to be an index into the `number_tilenums' table in the main
                            status.asm file. Arguments, in order (pretty much the same as draw_static_tile):
                              * X-Position (screen-relative) to draw the tile.
                              * Y-Position (screen-relative) to draw the tile.
                              * The ram address that will contain the tile index into the previously mentioned table.
                              * Flip properties (you can use helper defines `!tile_xflip', '!tile_yflip',
                                `!tile_xyflip', and `!tile_noflip' as this argument).
                              * Palette: palette of the tile. You can use LM palette numbers here.
                              * Page: 0 for SP1/2, 1 for SP3/4
                              * Size: 0 for 8x8, 1 for 16x16
`draw_digit_tile_propram':  Same idea as 'draw_static_tile_propram'. Same arguments as 'draw_digit_tile'
                            along with the following proceeding it:
                              * Use propram toggle. Set to !true to use the ram. Otherwise,
                                is exactly the same as `draw_static_tile'.
                              * A ram address. Will be or'd in with the other static property
                                values provided. If the 'Use propram toggle' is set to true.
`draw_digit_tile_sk':       Draws a digit tile, but jumps to a specified label if the ram index is equal
                            to a provided value. This is a really minor optimization for long counters (such as score)
                            whose higher values are scarcely drawn, and you probably will not need or want to use this.
                            Arguments proceeding 'draw_digit_tile' args:
                              * Flag to generate the skipping code. Set to `!true'.
                              * The tile index that invokes the skipping logic (i.e. if your provided ram value contains
                                this value, the skip label is jumped to)
                              * The lable to jump to when skipping.
`draw_digit_tile_sk_prop':  A combination of both the previous. `draw_digit_tile' arguments come first, then the `sk' variant
                            arguments, then the `propram' variant arguments.

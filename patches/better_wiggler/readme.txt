    This is a patch that overhauls a lot of Wiggler's code for the sake of
efficiency and to remove limits the original sprite had.
It:
  1) Rewrites the segment buffer handling to properly use
     a ring instead of an MVP shuffle, saving about
     800 cycles per on-screen wiggler every frame.
  2) Allows an arbitrary number of wigglers to be on-screen
     at the same time, up to the entity limit (if you can
     find enough available ram, anyway)
  3) Removes the need to use sprite header $0A with wigglers.
     * Caveat: This patch actually breaks sprite header $0A in one
       specific case, see below.
  4) Enables easy graphics remapping with a more optimized
     graphics routine
     * This is an added bonus, but the graphics routine needed
       to account for new segment buffer handling anyway.

    As a result, The Wiggler's init routine, the segment buffer update routine,
and the entire graphics routine is rewritten. The actual core entity behavior
was almost completely untouched (except to repoint the moved graphics routine).
Most of these rewrites were to save space to enable the new code to fit in-line
over the old wiggler code. As such, there aren't any 'typical' hijacks, and only
the 'segment buffer slot' locating code needs freespace.

    The biggest downside, by far, is there is a bug with the original sprite header:
If a wiggler is spawned on level load, its slot seems to be able to be shifted
around, so the buffer initialization is bugged in this one case, and wiggler will
use stale values until the buffer fills (a total of 80 frames). If, for some reason,
you are not an alternative oam allocation mechanism (such as No More Sprite Tile Limits),
you can avoid this by not having wigglers able to be spawned when the level loads.
    I have no plans to fix this, the original games OAM management is horrendous as it is.
You could probably just patch the 'slot shifting' junk but I've little desire to figure
out exactly how it works.

    There are a few defines that you should know about:
  * !wiggler_segment_buffer
    * Address of the buffer for wiggler's segment positions. If you wish
      to use more than 4 wigglers, it may need to be moved (especially on SA1).
      Each wiggler requires $80 (128) bytes. On non-sa1 it might be fine, if you're
      not using any patches that use freeram starting at 7F9C7B (The wiggler buffer
      location is right up next to the extra freeram in bank 7F)
  * !wiggler_segment_slots
    * an array which stores the sprite slots of active wigglers, 'reserving'
      a chunk of the segment buffer. This is to allow quickly finding which
      chunk of the buffer a newly spawned wiggler can use. Default $0DC3 is
      only four bytes large.
  * !nwigglers
    * maximum number of allowd wigglers. !wiggler_segment_buffer and
      !wiggler_segment_slots must be evaluated for size requirements
      if this is to be changed.

The new code also uses two previously unused miscellaneous sprite tables, 160E and 1528 by default.
It doesn't matter what these are, but the one used for the segment buffer position
(!wiggler_segbuff_position) was only tested with a zero-initialized table, but it may work with
an uninitialized one.

 -- LUNAR MAGIC SPRITE COLLECTION GENERATOR --

This is a small library (and driver script) you can use
  to automatically generate a custom sprite listing (known
  in the editor as the 'Custom Collection of Sprites') for use
  with Lunar Magic. It does this by parsing JSON representing the
  sprite entry to create, and the driver script will use the library
  to create the ssc, mwt, and mw2 files for you. You must create the s16
  yourself within Lunar Magic.

It is somewhat manual, but far superior to setting up the files
  by yourself, and the JSON format used has support for the majority
  of features that LM allows within this menu. Structurally, the code
  is rather messy, but currently gets the job done.


 -- DRIVER SCRIPT ARGUMENTS --
Invoking the `generate_sprite_collection.py' script with the `--help' flag
  will provide information on the available flags, but some further usage information
  may be helpful for some:
 * --base-ssc
    * A base ssc file to use. This file is copied to where the ssc will go.
    * Useful for things such as users that want custom Mario entrance poses,
      ExternalGraphics usage, and other such things that are out of the scope of
      these scripts.
  * --name-prefix
    * The prefix of your ROM's file name.
      * e.g. if your rom file is named `coolhack.smc', you probably want to provide `coolhack' to this argument.
    * Lunar Magic will only read auxillary files which match the file name, sans extension of course.
    * Defaults to `smw'
  * --tooltip-bg-default, --tooltip-fg-default
   * These are not yet implemented.
  * The rest of the arguments should be straightforward.
* Positional arguments are all expected to be paths to the JSON files you wish to process.

 -- JSON FILE FORMAT --

Each JSON file can be a single object, or an array of objects. There's only a handful of
  required keys. Numeric values can be integers or strings. Strings will be interpreted as hex.
There are three samples provided in the samples directory: two for a piranha plant
  which is controllable via the extra bytes, and one for a dynamic Woozy Guy, which has different colors
  based on its x-position.
Available fields:
* id
  * Numeric (hex only)
  * The sprite number when inserting into Lunar Magic.
  * Required.
* name
  * String
  * The name of the sprite in your custom list.
  * Required.
* desc
  * String
  * The text that is displayed in the sprite's tooltip.
  * Required.
* category
  * String
  * Unused.
  * For a future feature where sprites can be organized in LM's list by 'category' rather than sprite id.
* back_color
  * String
  * A hexidecimal string, used as the color value for the tooltip box.
  * Defaults to not present, using Lunar Magic's default.
    * Note, there is an option for changing the default, but it is not currently implemented.
* text_color
  * String
  * A hexidecimal string, used as the color value for the tooltip's text.
  * Defaults to not present, using Lunar Magic's default.
    * Note, there is an option for changing the default, but it is not currently implemented.
* display_xoff
  * Numeric
  * The x offset in LM's display window.
  * Positive is right, negative is left.
  * Defaults to 0. Note the driver script will provide a configurable 'center' value, which defaults to 7 (the center of the window)
* display_yoff
  * Numeric
  * Same as above, except in the Y direction
  * Positive is down, negative is up.
* custom
  * Boolean
  * The value of the most significant extra bit (in PIXI's custom sprite engine, used to flag that the sprite is custom).
  * Required
* extra_bit
  * Boolean
  * The value of the least significant extra bit (in PIXI's custom sprite engine, used by sprites in a variety of ways)
  * Required
* n_exbytes
  * The number of extra bytes this sprite uses.
  * Easily the most error prone bit of the whole setup. An incorrect number here will break the list.
  * Defaults to 0.
* which_exbyte
  * Used for having different displays for sprites with different extra byte values: specifies the index
    of the extra byte that controls this.
  * Defaults to not present, in which case this feature is not used
* which_exbyte_val
  * The value of the extra byte specified in the `which_exbyte' key.
* reqfiles
  * Object
    * sp1
      * Numeric
    * sp2
      * Numeric
    * sp3
      * Numeric
    * sp4
      * Numeric
  * The required sprite files for this sprite, for showing SPX=yy in the top-right of the
    sprite's window.
* smap16
  * This key has a couple of different valid formats: Direct tiles to draw, or a set for use with
    the 'different graphics based on x-or-y-position' features. The latter is mutually exclusive
    with the `which_exbyte' setup, and will cause an error if used together.
  * Format for direct tiles:
    * Object, or array of objects
      * xoff
        * Numeric
        * The x offset of this tile from the sprite's position, in pixels
        * Defaults to 0
     * yoff
        * same as xoff, but for y.
     * tile
       * Numeric
       * The sprite map16 tile number to use.
       * Required
  * Format for x/yoff position based tiles:
    * Array of Objects
      * xmask
        * Numeric (1-7)
        * the bitmask of the sprite's X value to use for this tile arrangement
      * ymask
        * same as xmask, but for y.
      * dat
        * Object, or array of objects
        * Takes the form of the previously described object for direct tiles.


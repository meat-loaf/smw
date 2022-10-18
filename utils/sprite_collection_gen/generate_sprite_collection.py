#!/bin/env python3
import argparse
import json
import shutil
import sys

from lm_sprite_collections.sprite_collection_entry import sprite_collection_entry
from lm_sprite_collections.smap16_entry import smap16_entry

BG_COLOR_DEFAULT = "E1E1FF"
FG_COLOR_DEFAULT = "000000"
ED_XPOS_DEFAULT  = "7"
ED_YPOS_DEFAULT  = "7"

def validate_args(parser) -> list:
	errs = []
	parser.xpos_origin = int(parser.xpos_origin, 16)
	parser.ypos_origin = int(parser.ypos_origin, 16)
	if parser.xpos_origin < 0x00 or parser.xpos_origin > 0x0F:
		errs.append("Bad xpos origin. Must be positive and less than F (hex).")
	if parser.ypos_origin < 0x00 or parser.ypos_origin > 0x0F:
		errs.append("Bad ypos origin. Must be positive and less than F (hex).")
	return errs

def parse_args(passed_args):
	parser = argparse.ArgumentParser(description="Generates a custom sprite collection for Lunar Magic from a set of specially-formatted JSON files.")
	parser.add_argument("-n", "--name-prefix", dest="name", required=False, default="smw",
	                                           help="The name to prefix the generated files with. Default `smw'")
	parser.add_argument("--base-ssc", dest="base_ssc", required=False, type=str,
	                                  help="Path to a base ssc file to use, which will be copied before generating the remaining ssc data.")
	parser.add_argument("-b", "--tooltip-bg-default", dest="bg_color", required=False, type=str, default=BG_COLOR_DEFAULT,
	                          help="The default background color of each sprite's tooltip, if one is not supplied (default 0x{}).".format(BG_COLOR_DEFAULT))
	parser.add_argument("-f", "--tooltip-fg-default", dest="fg_color", required=False, type=str, default=FG_COLOR_DEFAULT,
	                          help="The default foreground (text) color of each sprite's tooltip, if one is not supplied (default 0x{}).".format(FG_COLOR_DEFAULT))
	parser.add_argument("-x", "--display-xpos-origin", dest="xpos_origin", required=False, type=str, default=ED_XPOS_DEFAULT,
	                          help="The sprite position that sprite offsets are applied from, if one is not supplied (default {}).".format(ED_XPOS_DEFAULT))
	parser.add_argument("-y", "--display-ypos-origin", dest="ypos_origin", required=False, type=str, default=ED_XPOS_DEFAULT,
	                          help="The sprite position that sprite offsets are applied from, if one is not supplied (default {}).".format(ED_YPOS_DEFAULT))
	parser.add_argument("--no-ssc", dest="gen_ssc", action="store_false",
	                          help="Disable ssc file generation.")
	parser.add_argument("--no-mwt", dest="gen_mwt", action="store_false",
	                          help="Disable mwt file generation.")
	parser.add_argument("--no-mw2", dest="gen_mw2", action="store_false",
	                          help="Disable mw2 file generation.")
	parser.add_argument("jsons", metavar="JSON", type=str, nargs='+',
	                             help="The JSON file(s) to process.")
	args = parser.parse_args(passed_args)
	e = validate_args(args)
	if len(e) != 0:
		return e
	return args

def main(argv) -> int:
	r = parse_args(argv[1:])
	if type(r) == list:
		print("\n".join(r), file=sys.stderr)
		return 1
	collections = []
	for json_filename in r.jsons:
		with open(json_filename) as json_file:
			print("load file {}...".format(json_filename))
			dat = json.load(json_file)
			if type(dat) == list:
				for j in dat:
					collections.append(sprite_collection_entry(j))
			else:
				collections.append(sprite_collection_entry(dat))
		collections.sort()
	ssc = None
	mwt = None
	mw2 = None
	if r.gen_ssc:
		if r.base_ssc is not None:
			shutil.copy(r.base_ssc, r.name + ".ssc")
			ssc = open(r.name + ".ssc", "at")
		else:
			ssc = open(r.name + ".ssc", "wt")
	if r.gen_mwt:
		mwt = open(r.name + ".mwt", "wt")
	if r.gen_mw2:
		mw2 = open(r.name + ".mw2", "wb")
		# header
		mw2.write(b'\x00')

	last_id = None
	last_custom = None
	for c in collections:
		if ssc is not None:
			ssc.write(c.to_ssc_entries())
		if mwt is not None:
			mwt.write(c.to_mwt_entry(last_id == c.id and last_custom == c.custom))
			mwt.write('\n')
		if mw2 is not None:
			mw2.write(c.to_mw2_entry(r.xpos_origin, r.ypos_origin))
		last_id = c.id
		last_custom = c.custom
	if ssc is not None:
		ssc.close()
	if mwt is not None:
		mwt.close()
	if mw2 is not None:
		# terminator
		mw2.write(b'\xFF')
		mw2.close()
	return 0

if __name__ == '__main__':
	sys.exit(main(sys.argv))

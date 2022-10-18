class smap16_entry:
	def __init__(self, xoff, yoff, tile):
		self.xoff = int(xoff, 16) if type(xoff) == str else int(xoff)
		self.yoff = int(yoff, 16) if type(yoff) == str else int(yoff)
		self.tile = int(tile, 16) if type(tile) == str else int(tile)
	def __repr__(self):
		return "{},{},{:03X}".format(self.xoff, self.yoff, self.tile)
	

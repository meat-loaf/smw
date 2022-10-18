# TODO fully realize this, there's more possible than this
class req_gfx_file_entry():
	def __coerce_entry(self, name, value):
		if value is None:
			setattr(self, name, 0x7F)
		elif type(value) is str:
			setattr(self, name, int(value, 16))
		elif type(value) is int:
			setattr(self, name, value)
		else:
			raise TypeError("Bad type for graphics file entry (got {} of type {})".format(value, type(value)))

	def __init__(self, gfx_list):
		req_gfx_file_entry.__coerce_entry(self, "sp1", gfx_list.get("sp1", None))
		req_gfx_file_entry.__coerce_entry(self, "sp2", gfx_list.get("sp2", None))
		req_gfx_file_entry.__coerce_entry(self, "sp3", gfx_list.get("sp3", None))
		req_gfx_file_entry.__coerce_entry(self, "sp4", gfx_list.get("sp4", None))
	
	def __str__(self):
		return "{:02X},{:02X},{:02X},{:02X}".format(self.sp1, self.sp2, self.sp3, self.sp4)

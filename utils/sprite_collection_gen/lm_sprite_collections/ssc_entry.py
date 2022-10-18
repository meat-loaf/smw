class ssc_entry():
	def __init__(self, index, exbits, data, kind, exbyte=None, exbyte_val=None, xmask=None, ymask=None, back_color=None, text_color=None):
		if exbyte is not None and exbyte_val is not None:
			self.kind = ssc_entry.ssc_kind_exbyte(kind, exbits, exbyte, exbyte_val)
		elif xmask is not None and ymask is not None:
			self.kind = ssc_entry.ssc_kind_xymask(kind, exbits, xmask, ymask)
		else:
			self.kind = ssc_entry.ssc_kind_base(kind, exbits)
		self.index = index
		self.data = data

		# TODO try to remove special casing...
		if kind == ssc_entry.ssc_kind_base.SSC_KIND_DESC:
			if back_color is not None:
				self.data += "\\b{:06X}".format(int(back_color, 16))
			if text_color is not None:
				self.data += "\\f{:06X}".format(int(text_color, 16))
	def __str__(self):
		return "{:02X} {} {}".format(self.index, self.kind, self.data)

	class ssc_kind_base():
		SSC_KIND_DESC = 0
		SSC_KIND_SMAP16 = 2
		SSC_KIND_REQFILES = 8
		KINDS = (SSC_KIND_DESC, SSC_KIND_SMAP16, SSC_KIND_REQFILES)

		def err(v, k, t):
			if (type(v) is not t):
				raise TypeError("{} must be {} (got {} with data {})".format(k, t, type(v), v))
	
		def __init__(self, base, exbits):
			ssc_entry.ssc_kind_base.err(base, "base", int)
			ssc_entry.ssc_kind_base.err(exbits, "exbits", int)
			self.base = base;
			self.exbits = exbits
	
		def __str__(self):
			return "000{}{}".format(self.exbits, self.base)

	class ssc_kind_exbyte(ssc_kind_base):
		def __init__(self, base, exbits, exbyte, exbyte_val):
			self.exbyte = exbyte
			self.exbyte_val = exbyte_val

			ssc_entry.ssc_kind_base.err(exbyte, "exbyte", int)
			ssc_entry.ssc_kind_base.err(exbyte_val, "exbyte_val", int)
				
			if exbits > 4:
				raise ValueError("Exbits value is invalid.")
			if exbyte_val is not None:
				if exbyte_val > 0xFF:
					raise ValueError("Byte value cannot exceed 0xFF")
			if exbyte > 4:
				raise ValueError("Extension byte to look at cannot be greater than 4.")
			elif exbyte < 0:
				raise ValueError("Don't pass negative numbers for exbyte.")
			exbyte += 2
			if base not in ssc_entry.ssc_kind_base.KINDS:
					raise ValueError("Bad base `{}'.".format(base))
			self.exbyte = exbyte
			self.exbyte_val = exbyte_val
			super().__init__(base, exbits)

		def __str__(self):
			eb_nb = "{:02X}".format(self.exbyte_val)
			return "{}{}{}{}".format(self.exbyte, eb_nb, self.exbits, self.base)

	class ssc_kind_xymask(ssc_kind_base):
		def __init__(self, base, exbits, xmask, ymask):
			if xmask is not None and xmask > 3:
				raise ValueError("xmask can't be greater than 3.")
			if ymask is not None and ymask > 3:
				raise ValueError("xmask can't be greater than 3.")
			self.xmask = xmask
			self.ymask = ymask
			super().__init__(base, exbits)
		def __str__(self):
			return "0{}{}{}{}".format(self.ymask, self.xmask, self.exbits, self.base)



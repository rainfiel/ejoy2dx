#coding:utf-8

import wx
import wx.propgrid as wxpg

import enum

class Int32ColorProperty(wxpg.PyProperty):
	""" Demonstrates a property with few children.
	"""
	def __init__(self, label, name = wxpg.LABEL_AS_NAME, value=0):
		wxpg.PyProperty.__init__(self, label, name)

		a,r,g,b = value>>24, value>>16&0xFF, value>>8&0xFF, value&0xFF
		self.AddPrivateChild(wxpg.ColourProperty("RGB", value=wx.Colour(r,g,b)))
		self.AddPrivateChild(wxpg.IntProperty("Alpha", value=a))

		self.m_value = value

	def GetClassName(self):
		return self.__class__.__name__

	def GetEditor(self):
		return "TextCtrl"

	def RefreshChildren(self):
		value = self.m_value
		a,r,g,b = value>>24, value>>16&0xFF, value>>8&0xFF, value&0xFF
		print(a,r,g,b)

		self.Item(0).SetValue(wx.Colour(r,g,b,a))
		self.Item(1).SetValue(int(a))

	def ChildChanged(self, thisValue, childIndex, childValue):
		value = self.m_value
		if childIndex == 0:
			value = ((value>>24)<<24)|(childValue[0]<<16|childValue[1]<<8|childValue[2])
		elif childIndex == 1:
			value = (value&0xFFFFFF) | (childValue<<24)
		else:
			raise AssertionError

		self.m_value = value
		return value

class MatProperty(wxpg.PyProperty):
	""" Demonstrates a property with few children.
	"""
	def __init__(self, label, name = wxpg.LABEL_AS_NAME, value=[1024, 0, 0, 1024, 0, 0]):
		wxpg.PyProperty.__init__(self, label, name)

		for i in xrange(6):
			self.AddPrivateChild( wxpg.IntProperty(str(i+1), value=value[i]) )

		self.m_value = value

	def GetClassName(self):
		return self.__class__.__name__

	def GetEditor(self):
		return "TextCtrl"

	def RefreshChildren(self):
		size = self.m_value
		for i in xrange(6):
			self.Item(i).SetValue( size[i] )

	def ChildChanged(self, thisValue, childIndex, childValue):
		# FIXME: This does not work yet. ChildChanged needs be fixed "for"
		#        wxPython in wxWidgets SVN trunk, and that has to wait for
		#        2.9.1, as wxPython 2.9.0 uses WX_2_9_0_BRANCH.

		size = self.m_value
		size[childIndex] = childValue
		return size

class PosProperty(wxpg.PyProperty):
	""" Demonstrates a property with few children.
	"""
	def __init__(self, label, name = wxpg.LABEL_AS_NAME, value={"x":0,"y":0}):
		wxpg.PyProperty.__init__(self, label, name)

		self.AddPrivateChild( wxpg.IntProperty("X", value=value["x"]) )
		self.AddPrivateChild( wxpg.IntProperty("Y", value=value["y"]) )

		self.m_value = value

	def GetClassName(self):
		return self.__class__.__name__

	def GetEditor(self):
		return "TextCtrl"

	def RefreshChildren(self):
		size = self.m_value
		self.Item(0).SetValue( size["x"] )
		self.Item(1).SetValue( size["y"] )

	def ChildChanged(self, thisValue, childIndex, childValue):
		# FIXME: This does not work yet. ChildChanged needs be fixed "for"
		#        wxPython in wxWidgets SVN trunk, and that has to wait for
		#        2.9.1, as wxPython 2.9.0 uses WX_2_9_0_BRANCH.
		size = self.m_value
		if childIndex == 0:
			size["x"] = childValue
		elif childIndex == 1:
			size["y"] = childValue
		else:
			raise AssertionError

		return size

class PropBase(object):
	def init_props(self, scheme, data, name=None, parent=None):
		pg = self.pg
		if not parent:
			parent = [wxpg.PropertyCategory("properties")]
			pg.Append(parent[-1])
		for idx, item in enumerate(scheme):
			if item["name"] not in data: continue

			fullname = name and (".".join(name)+"."+item["name"]) or item["name"]
			type = self.type_config.get(fullname, None) or getattr(self, item.get("type", ""), None)
			if "body" in item and not type:
				cat = wxpg.PropertyCategory(item["name"])

				if not parent or len(parent) == 0:
					pg.Append( cat )
					parent = []
				else:
					pg.AppendIn(parent[-1], cat )

				parent.append(cat)
				_name = name or []
				_name.append(item["name"])
				self.init_props(item["body"], data[item["name"]], _name, parent)
				parent.pop(-1)
				_name.pop(-1)
			else:
				p = (parent and len(parent) > 0) and parent[-1] or None
				self.new_prop_item(item, p, fullname, data[item["name"]])

	def new_prop_item(self, item, parent=None, name=None, val=None):
		prop = None

		t = name and self.type_config.get(name, None) or item["type"]
		cfg = getattr(enum, t, None)
		if cfg:
			prop = self.enum(item, name, val, cfg)
		else:
			func = getattr(self, t, None)
			if not func and item.get("is_pointer", False):
				func = self.pointer

			if func:
				prop = func(item, name, val)
			else:
				print(item.get("is_pointer", False), item)
				print("ignore type:"+str(name)+"|"+item["type"])

		if prop:
			if not parent:
				self.pg.Append(prop)
			else:
				self.pg.AppendIn(parent, prop)

			if name in self.readonly:
				prop.Enable(False)

		return prop

	def prop_str(self, prop):
		name = prop.GetName()
		ptype = prop.GetValueType()
		val = prop.GetValue()

		ctype = self.type_config.get(name, None)
		if ctype == "int32_color":
			return "'%s', %d" % (name, val)

		print(ptype, name, val, prop.__class__)
		print(prop.m_value, type(val))

		if ptype == "string":
			return ("'%s', '%s'" % (name, val)).encode('utf-8')
		elif ptype == "double":
			return "'%s', %f" % (name, val)
		elif ptype == "wxColour":
			return "{[[%s]],[[%s]],[[%s]]},{%f,%f,%f}" % \
						(name+".r", name+".g", name+".b", val.Red()/255, val.Green()/255, val.Blue()/255)
		elif ptype == "PyObject*":
			if type(val)==type({}) and "x" in val and "y" in val:
				return "{[[%s]],[[%s]]}, {%d, %d}" % (name+".x", name+".y", val["x"], val["y"])
		elif ptype == "wxArrayInt":
			return "'%s.m', {%s}" % ( name, ",".join([str(i) for i in val]))
		else:
			return "'%s', %d" % (name, val)

	def pointer(self, item, name, val):
		pro = wxpg.StringProperty(item["name"], name, value="0x%.2X"%val)
		pro.Enable(False)
		return pro

	def int(self, item, name, val):
		return wxpg.IntProperty(item["name"], name, value=val)

	def uint16_t(self, item, name, val):
		return wxpg.IntProperty(item["name"], name, value=val)

	def int32_color(self, item, name, val):
		return Int32ColorProperty(item["name"], name, value=val)

	def bool(self, item, name, val):
		return wxpg.BoolProperty(item["name"], name, value=val)

	def float(self, item, name, val):
		return wxpg.FloatProperty(item["name"], name, value=val)

	def enum(self, item, name, val, cfg):
		return wxpg.EnumProperty(item["name"],name, 
															cfg["keys"], cfg["vals"], val)

	def point(self, item, name, val):
		return PosProperty(item["name"], name, value=val)

	def matrix(self, item, name, val):
		return MatProperty(item["name"], name, value=val["m"])

	def color(self, item, name, val):
		c = wx.Colour(val["r"]*255, val["g"]*255, val["b"]*255)
		cp = wxpg.ColourProperty(item["name"], name, value=c)
		cp.AppendChild(wxpg.FloatProperty("alpha", "a", value=val["a"]))
		return cp

	def string(self, item, name, val):
		return wxpg.StringProperty(item["name"], name, value=val)

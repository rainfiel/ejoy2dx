#coding:utf-8

import wx
import wx.propgrid as wxpg

import enum

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
			fullname = name and (".".join(name)+"."+item["name"]) or item["name"]
			type = self.type_config.get(fullname, None)
			if "body" in item and not type:
				if item["name"] in data:
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
			if func:
				prop = func(item, name, val)

		if prop:
			if not parent:
				self.pg.Append(prop)
			else:
				self.pg.AppendIn(parent, prop)

		return prop

	def prop_str(self, prop):
		name = prop.GetName()
		type = prop.GetValueType()
		val = prop.GetValue()

		if type == "string":
			return ("'%s', '%s'" % (name, val)).encode('utf-8')
		elif type == "double":
			return "'%s', %f" % (name, val)
		elif type == "wxColour":
			return "{[[%s]],[[%s]],[[%s]]},{%f,%f,%f}" % \
						(name+".r", name+".g", name+".b", val.Red()/255, val.Green()/255, val.Blue()/255)
		elif type == "PyObject*":
			if "x" in val and "y" in val:
				return "{[[%s]],[[%s]]}, {%d, %d}" % (name+".x", name+".y", val["x"], val["y"])
		else:
			return "'%s', %d" % (name, val)

	def int(self, item, name, val):
		return wxpg.IntProperty(item["name"], name, value=val)

	def bool(self, item, name, val):
		return wxpg.BoolProperty(item["name"], name, value=val)

	def float(self, item, name, val):
		return wxpg.FloatProperty(item["name"], name, value=val)

	def enum(self, item, name, val, cfg):
		return wxpg.EnumProperty(item["name"],name, 
															cfg["keys"], cfg["vals"], val)

	def position(self, item, name, val):
		return PosProperty(item["name"], name, value=val)

	def color(self, item, name, val):
		c = wx.Colour(val["r"]*255, val["g"]*255, val["b"]*255)
		cp = wxpg.ColourProperty(item["name"], name, value=c)
		cp.AppendChild(wxpg.FloatProperty("alpha", "a", value=val["a"]))
		return cp

	def string(self, item, name, val):
		return wxpg.StringProperty(item["name"], name, value=val)

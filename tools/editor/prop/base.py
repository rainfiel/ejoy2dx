#coding:utf-8

import wx
import wx.propgrid as wxpg

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
			else:
				p = (parent and len(parent) > 0) and parent[-1] or None
				self.new_prop_item(item, p, fullname, data[item["name"]])

	def new_prop_item(self, item, parent=None, name=None, val=None):
		t = name and self.type_config.get(name, None) or item["type"]
		func = getattr(self, t, None)
		if func:
			prop = func(item, name, val)

			if not parent:
				self.pg.Append(prop)
			else:
				self.pg.AppendIn(parent, prop)

			return prop

	def prop_str(self, prop):
		name = prop.GetName()
		# if "." in name:
		# 	name = name.split(".")[-1]

		type = prop.GetValueType()
		val = prop.GetValue()
		print(".....prop_str:", name, type, val)

		if type == "string":
			return ("'%s', '%s'" % (name, val)).encode('utf-8')
		elif type == "double":
			return "'%s', %f" % (name, val)
		elif type == "wxColour":
			return "{[[%s]],[[%s]],[[%s]]},{%f,%f,%f}" % \
						(name+".r", name+".g", name+".b", val.Red()/255, val.Green()/255, val.Blue()/255)
		else:
			return "'%s', %d" % (name, val)

	def int(self, item, name, val):
		return wxpg.IntProperty(item["name"], name, value=val)

	def float(self, item, name, val):
		return wxpg.FloatProperty(item["name"], name, value=val)

	def enum(self, item, name, val):
		return wxpg.EnumProperty(item["name"],name, 
															item["enum_keys"], item["enum_values"], 0)

	def color(self, item, name, val):
		c = wx.Colour(val["r"]*255, val["g"]*255, val["b"]*255)
		cp = wxpg.ColourProperty(item["name"], name, value=c)
		print("................color:"+name)
		cp.AppendChild(wxpg.FloatProperty("alpha", "a", value=val["a"]))
		return cp

	def string(self, item, name, val):
		return wxpg.StringProperty(item["name"], name, value=val)
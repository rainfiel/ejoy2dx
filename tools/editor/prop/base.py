#coding:utf-8

import wx
import wx.propgrid as wxpg

class PropBase(object):
	def new_prop_item(self, item, parent=None):
		t = item["type"]
		func = getattr(self, t, None)
		if func:
			prop = func(item)

			if not parent:
				return self.pg.Append(prop)
			else:
				return self.pg.AppendIn(parent, prop)

	def prop_str(self, prop):
		name = prop.GetName()
		if "." in name:
			name = name.split(".")[-1]

		type = prop.GetValueType()
		val = prop.GetValue()

		if type == "string":
			return ("'%s', '%s'" % (name, val)).encode('utf-8')
		elif type == "double":
			return "'%s', %f" % (name, val)
		else:
			return "'%s', %d" % (name, val)

	def int(self, item):
		return wxpg.IntProperty(item["name"], value=int(item["default"]))

	def float(self, item):
		return wxpg.FloatProperty(item["name"], value=float(item["default"]))

	def enum(self, item):
		return wxpg.EnumProperty(item["name"],item["name"], 
															item["enum_keys"], item["enum_values"], 0)

	def color(self, item):
		return wxpg.ColourProperty(item["name"], value=item["default"])

	def string(self, item):
		return wxpg.StringProperty(item["name"], value=item["default"])
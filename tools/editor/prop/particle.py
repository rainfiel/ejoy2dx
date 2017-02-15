#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json

template_path = os.path.join(os.path.dirname(__file__), "particle.json")
with open(template_path) as f:
	template = json.loads(f.read())

colorMap = {
	"startColor":("startColorRed", "startColorGreen", "startColorBlue"),\
	"startColorVariance":("startColorVarianceRed", "startColorVarianceGreen", "startColorVarianceBlue"),\
	"finishColor":("finishColorRed", "finishColorGreen", "finishColorBlue"),\
	"finishColorVariance":("finishColorVarianceRed", "finishColorVarianceGreen", "finishColorVarianceBlue"),\
}
rootCats = ("Emitter", "ParticleSettings", "ColorSettings")
emitterTypes = ("Gravity", "Radial")

class ParticleProp( wx.Panel ):

	def __init__( self, parent, edit_callback ):
		wx.Panel.__init__(self, parent, wx.ID_ANY)
		self.edit_callback = edit_callback

		self.panel = panel = wx.Panel(self, wx.ID_ANY)
		topsizer = wx.BoxSizer(wx.VERTICAL)

		# Difference between using PropertyGridManager vs PropertyGrid is that
		# the manager supports multiple pages and a description box.
		self.pg = pg = wxpg.PropertyGridManager(panel,
																						style=wxpg.PG_SPLITTER_AUTO_CENTER |
																						# wxpg.PG_AUTO_SORT |
																						wxpg.PG_TOOLBAR)

		# Show help as tooltips
		# pg.SetExtraStyle(wxpg.PG_EX_HELP_AS_TOOLTIPS)

		pg.Bind( wxpg.EVT_PG_CHANGED, self.OnPropGridChange )
		# pg.Bind( wxpg.EVT_PG_PAGE_CHANGED, self.OnPropGridPageChange )
		# pg.Bind( wxpg.EVT_PG_SELECTED, self.OnPropGridSelect )
		# pg.Bind( wxpg.EVT_PG_RIGHT_CLICK, self.OnPropGridRightClick )

		self.data = {}
		self.emitter_prop = None

		topsizer.Add(pg, 1, wx.EXPAND)
		panel.SetSizer(topsizer)
		topsizer.SetSizeHints(panel)

		sizer = wx.BoxSizer(wx.VERTICAL)
		sizer.Add(panel, 1, wx.EXPAND)
		self.SetSizer(sizer)
		self.SetAutoLayout(True)

	def SetEmitter(self, emitterType):
		self.emitter_prop.DeleteChildren()

		emitterName = emitterTypes[emitterType]
		items = template.get(emitterName)
		for item in items:
			prop = self.new_prop_item(item, self.emitter_prop)
			key = item["name"]
			val = self.data.get(key, None)
			if val != None:
				prop.SetValue(val)

	def ShowData(self, data):
		if self.pg.GetPageCount() > 0:
			self.pg.RemovePage(0)
		self.pg.AddPage( "Particle" )
		self.init_prop()

		self.data = data
		subdata = {}
		for cat in rootCats:
			items = template.get(cat)
			for item in items:
				key = item["name"]
				val = data.get(key, None)
				if val != None:
					subdata[key] = val
		subdata["emitterType"] = emitterType = int(subdata.get("emitterType", 0))

		for k, v in colorMap.iteritems():
			color=wx.Colour(data[v[0]]*255, 
											data[v[1]]*255, 
											data[v[2]]*255)
			subdata[k] = color

		self.SetEmitter(emitterType)

		subdata.pop("gravityx", None)
		subdata.pop("gravityy", None)
		self.pg.SetPropertyValues(subdata)

	def OnPropGridChange(self, event):
		p = event.GetProperty()
		if p and self.edit_callback:
			name = p.GetName()
			val = p.GetValue()
			if name in colorMap:
				color = p
				for i, v in enumerate(colorMap[name]):
					self.edit_callback(v, color[i])
			else:
				if "." in name:
					name = name.split(".")[-1]
				self.edit_callback(name, val)

			if name == "emitterType":
				self.SetEmitter(int(val))

	def init_prop(self):
		pg = self.pg

		for cat in rootCats:
			items = template.get(cat)
			pg.Append( wxpg.PropertyCategory(cat) )
			for item in items:
				prop = self.new_prop_item(item)
				if item["name"] == "emitterType":
					self.emitter_prop = prop

	def new_prop_item(self, item, parent=None):
		t = item["type"]
		func = getattr(self, t, None)
		if func:
			prop = func(item)

			if not parent:
				return self.pg.Append(prop)
			else:
				return self.pg.AppendIn(parent, prop)

	def int(self, item):
		return wxpg.IntProperty(item["name"], value=int(item["default"]))

	def float(self, item):
		return wxpg.FloatProperty(item["name"], value=float(item["default"]))

	def enum(self, item):
		return wxpg.EnumProperty(item["name"],item["name"], 
															item["enum_keys"], item["enum_values"], 0)

	def color(self, item):
		return wxpg.ColourProperty(item["name"], value=item["default"])
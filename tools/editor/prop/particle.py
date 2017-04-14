#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json

from base import PropBase

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

class ParticleProp(PropBase):

	def __init__( self, parent, edit_callback ):
		self.edit_callback = edit_callback

		self.pg = parent

		self.data = {}
		self.emitter_prop = None

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
		subdata["blendFuncSource"] = int(subdata.get("blendFuncSource", 0))
		subdata["blendFuncDestination"] = int(subdata.get("blendFuncDestination", 0))

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
				color = val
				for i, v in enumerate(colorMap[name]):
					self.edit_callback("set_particle_attr('%s', %f)" % (v, color[i]/255.0))
			else:
				self.Apply(p)

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

	def Apply(self, prop):
		args = self.prop_str(prop)
		self.edit_callback("set_particle_attr(%s)" % (args))

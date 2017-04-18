#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json

from base import PropBase

typeConfig = {
	"startColor":"color",\
	"startColorVar":"color",\
	"endColor":"color",\
	"endColorVar":"color",\
	"srcBlend":"BLEND_FUNC",\
	"dstBlend":"BLEND_FUNC", \
	"positionType":"POSITION_TYPE", \
	"emitterMode":"EMITTER_TYPE"
}
rootCats = ("Emitter", "ParticleSettings", "ColorSettings")
emitterTypes = ("Gravity", "Radial")

class ParticleProp(PropBase):

	def __init__( self, parent, edit_callback ):
		self.edit_callback = edit_callback

		self.pg = parent
		self.type_config = typeConfig

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

	def ShowData(self, scheme, data):
		self.pg.AddPage( "Particle" )
		self.init_props(scheme, data)
		

	def OnPropGridChange(self, event):
		p = event.GetProperty()
		if p and self.edit_callback:
			self.Apply(p)
			# name = p.GetName()
			# val = p.GetValue()
			# if name in colorMap:
			# 	color = val
			# 	for i, v in enumerate(colorMap[name]):
			# 		self.edit_callback("set_particle_attr('%s', %f)" % (v, color[i]/255.0))
			# else:
			# 	self.Apply(p)

			# if name == "emitterType":
			# 	self.SetEmitter(int(val))

	def Apply(self, prop):
		args = self.prop_str(prop)
		self.edit_callback("set_particle_attr(%s)" % (args))

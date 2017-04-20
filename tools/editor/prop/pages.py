#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json

from base import PropBase

particle_cfg = {
	"name" : "particle_config",
	"apply_name" : "set_particle_attr(%s)",
	"type_config" : {
		"startColor":"color",\
		"startColorVar":"color",\
		"endColor":"color",\
		"endColorVar":"color",\
		"srcBlend":"BLEND_FUNC",\
		"dstBlend":"BLEND_FUNC", \
		"positionType":"POSITION_TYPE", \
		"emitterMode":"EMITTER_TYPE", 
	}
}

label_cfg = {
	"name" : "pack_label",
	"apply_name" : "set_label_attr(%s)",
	"type_config" : {}
}

sprite_raw = {
	"name" : "sprite",
	"apply_name" : "set_sprite_attr(%s)",
	"type_config" : {
		"t.color":"int32_color", 
		"t.additive":"int32_color", 
		"type":"SPRITE_TYPE"
		},
	"readonly" : ["type", "id"]
}

class CommonPage(PropBase):
	def __init__( self, parent, edit_callback ):
		self.edit_callback = edit_callback
		self.pg = parent
		self.config = None

	def ShowData(self, config, scheme, data):
		self.config = config
		self.type_config = config["type_config"]
		self.readonly = config.get("readonly", [])
		self.pg.AddPage( config["name"] )
		self.init_props(scheme, data)
		
	def OnPropGridChange(self, event):
		p = event.GetProperty()
		if p and self.edit_callback:
			self.Apply(p)

	def Apply(self, prop):
		if self.config["apply_name"]:
			args = self.prop_str(prop)
			self.edit_callback( self.config["apply_name"] % (args))

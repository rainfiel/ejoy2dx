#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json

from base import PropBase

class LabelProp(PropBase):

	def __init__( self, parent, edit_callback ):
		self.edit_callback = edit_callback

		self.pg = parent
		self.type_config = {}

	def ShowData(self, scheme, data):
		self.pg.AddPage( "Label" )
		self.init_props(scheme, data)

	def OnPropGridChange(self, event):
		p = event.GetProperty()
		if p and self.edit_callback:
			self.Apply(p)


	def Apply(self, prop):
		args = self.prop_str(prop)
		self.edit_callback("set_label_attr(%s)" % (args))

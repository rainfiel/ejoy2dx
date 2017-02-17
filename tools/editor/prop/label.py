#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json

from base import PropBase

template_path = os.path.join(os.path.dirname(__file__), "label.json")
with open(template_path) as f:
	template = json.loads(f.read())

class LabelProp(PropBase):

	def __init__( self, parent, edit_callback ):
		self.edit_callback = edit_callback

		self.pg = parent

	def ShowData(self, data):
		self.pg.AddPage( "Label" )
		self.init_prop()

		self.pg.SetPropertyValues(data)

	def OnPropGridChange(self, event):
		p = event.GetProperty()
		if p and self.edit_callback:
			self.Apply(p)

	def init_prop(self):
		pg = self.pg

		for cat, items in template.iteritems():
			pg.Append( wxpg.PropertyCategory(cat) )
			for item in items:
				prop = self.new_prop_item(item)

	def Apply(self, prop):
		args = self.prop_str(prop)
		self.edit_callback("set_label_attr(%s)" % (args))

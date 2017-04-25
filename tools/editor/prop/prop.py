#coding:utf-8

import wx
import wx.propgrid as wxpg

import os
import json
import pages

class ButtonEditor(wxpg.PyTextCtrlEditor):
	edit_callback = None
	def __init__(self):
		wxpg.PyTextCtrlEditor.__init__(self)

	def CreateControls(self, propGrid, property, pos, sz):
		buttons = wxpg.PGMultiButton(propGrid, sz)
		buttons.AddButton("+")

		wnd = self.CallSuperMethod("CreateControls",
		                           propGrid,
		                           property,
		                           pos,
		                           buttons.GetPrimarySize())
		buttons.Finalize(propGrid, pos);
		self.buttons = buttons

		return (wnd, buttons)

	def DoCallback(self, prop):
		client = prop.GetClientData()
		cb = client.get("btn_callback", None)
		arg = client.get("btn_callback_arg", None)
		if cb:
			if arg != None: cb = cb % arg
			print("callback:"+cb)
			ButtonEditor.edit_callback(cb)

	def OnEvent(self, propGrid, prop, ctrl, event):
		if event.GetEventType() == wx.wxEVT_COMMAND_BUTTON_CLICKED:
			buttons = self.buttons
			evtId = event.GetId()

			if evtId == buttons.GetButtonId(0):
				self.DoCallback(prop)
				return False  # Return false since value did not change

		return self.CallSuperMethod("OnEvent", propGrid, prop, ctrl, event)

class PropPanel( wx.Panel ):

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

		pg.RegisterEditor(ButtonEditor)
		ButtonEditor.edit_callback = edit_callback

		self.page = None
		self.child_page = None
		self.current_page = None

		# Show help as tooltips
		# pg.SetExtraStyle(wxpg.PG_EX_HELP_AS_TOOLTIPS)

		pg.Bind( wxpg.EVT_PG_CHANGED, self.OnPropGridChange )
		# pg.Bind( wxpg.EVT_PG_PAGE_CHANGED, self.OnPropGridPageChange )
		# pg.Bind( wxpg.EVT_PG_SELECTED, self.OnPropGridSelect )
		# pg.Bind( wxpg.EVT_PG_RIGHT_CLICK, self.OnPropGridRightClick )


		# self.pg.AddPage( "Particle" )
		# self.init_prop()
		
		topsizer.Add(pg, 1, wx.EXPAND)
		panel.SetSizer(topsizer)
		topsizer.SetSizeHints(panel)

		sizer = wx.BoxSizer(wx.VERTICAL)
		sizer.Add(panel, 1, wx.EXPAND)
		self.SetSizer(sizer)
		self.SetAutoLayout(True)

	def Clear(self):
		while self.pg.GetPageCount() > 0:
			self.pg.RemovePage(0)

		self.page = None
		self.child_page = None

	def SetData(self, data):
		if data.get("root", False):
			self.Clear()

		ope = data.get("ope", None)
		if not ope: return

		cfg = getattr(pages, ope, {})

		self.current_page = None
		if not self.page:
			self.page = pages.CommonPage(self.pg, cfg, self.edit_callback)
			self.current_page = self.page
		else:
			if self.child_page:
				self.pg.RemovePage(1)
			self.child_page = pages.CommonPage(self.pg, cfg, self.edit_callback)
			self.current_page = self.child_page

		self.pg.SelectPage(self.current_page.name)
		self.current_page.ShowData(data["scheme"], data["data"])

	def OnPropGridChange(self, event):
		self.current_page.OnPropGridChange(event)
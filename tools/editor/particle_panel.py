#coding:utf-8
import wx

import os
import sys
from custom_tree import CustomTreeCtrl
import pack_tree

try:
    from agw import customtreectrl as CT
except ImportError:  # if it's not there locally, try the wxPython lib.
    import wx.lib.agw.customtreectrl as CT


class particle_panel(wx.Panel):

    def __init__(self, parent, style):
        wx.Panel.__init__(self, parent.book, style=style)
        # scroll = wx.ScrolledWindow(self, -1, style=wx.SUNKEN_BORDER)
        # scroll.SetScrollRate(20,20)

        self.main = parent
        # Create the CustomTreeCtrl, using a derived class defined below
        self.tree = CustomTreeCtrl(self, -1, rootLable="particle",
                                   style=wx.SUNKEN_BORDER,
                                   agwStyle=CT.TR_HAS_BUTTONS | CT.TR_HAS_VARIABLE_ROW_HEIGHT)

        self.tree.menu_callback = self.show_menu

        mainsizer = wx.BoxSizer(wx.VERTICAL)
        mainsizer.Add(self.tree, 4, wx.EXPAND)
        mainsizer.Layout()
        self.SetSizer(mainsizer)

        self.menu_data = None

    def set_data(self, data):
        self.tree.Reset()

        for k, v in data.iteritems():
            pack = self.tree.AppendItem(self.tree.root, k)
            for name, data in v.iteritems():
                p = self.tree.AppendItem(pack, name)
                self.tree.SetPyData(p, [k, name, data])
            
    def new_particle(self, evt):
        if not self.menu_data: return
        self.main.NewParticle(self.menu_data[0], self.menu_data[1])

    def show_menu(self, tree, item):
        self.menu_data = tree.GetPyData(item)
        if not self.menu_data or len(self.menu_data) < 3:
            self.menu_data = None
            return

        menu = wx.Menu()

        item1 = menu.Append(wx.ID_ANY, "New particle")
        menu.AppendSeparator()

        tree.Bind(wx.EVT_MENU, self.new_particle, item1)

        tree.PopupMenu(menu)
        menu.Destroy()

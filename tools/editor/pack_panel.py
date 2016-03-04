import wx

import os
import sys
from custom_tree import CustomTreeCtrl
import pack_tree

try:
    from agw import customtreectrl as CT
except ImportError:  # if it's not there locally, try the wxPython lib.
    import wx.lib.agw.customtreectrl as CT


class pack_panel(wx.Panel):

    def __init__(self, parent, style):
        wx.Panel.__init__(self, parent.book, style=style)
        # scroll = wx.ScrolledWindow(self, -1, style=wx.SUNKEN_BORDER)
        # scroll.SetScrollRate(20,20)

        self.main = parent
        # Create the CustomTreeCtrl, using a derived class defined below
        self.tree = CustomTreeCtrl(self, -1, rootLable="packs",
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
            for idx, p in v.iteritems():
                export = p.get('export')

                if export:
                    root = self.tree.AppendItem(pack, export)
                    self.tree.SetPyData(root, [k, export])
                    pack_tree.show_sprite(self.tree, root, p, v)
                else:
                    if 'id' in p:
                        root = self.tree.AppendItem(pack, "id:" + p['id'])
                        self.tree.SetPyData(root, [k, p['id']])
                        pack_tree.show_sprite(self.tree, root, p, v)

    def new_sprite(self, evt):
        if len(self.menu_data) == 2:
            if self.menu_data[1].isdigit():
                self.main.Send("new_sprite('%s',%s)" % (self.menu_data[0], self.menu_data[1]))
            else:
                self.main.Send("new_sprite('%s', '%s')" % (self.menu_data[0], self.menu_data[1]))

    def show_menu(self, tree, item):
        self.menu_data = tree.GetPyData(item)
        if not self.menu_data or len(self.menu_data) < 2:
            self.menu_data = None
            return

        menu = wx.Menu()

        item1 = menu.Append(wx.ID_ANY, "New sprite")
        menu.AppendSeparator()

        tree.Bind(wx.EVT_MENU, self.new_sprite, item1)

        tree.PopupMenu(menu)
        menu.Destroy()

import wx

import os
import sys
from custom_tree import CustomTreeCtrl
from wx.py import dispatcher
import pack_tree

try:
    from agw import customtreectrl as CT
except ImportError:  # if it's not there locally, try the wxPython lib.
    import wx.lib.agw.customtreectrl as CT


def id_cmp(x, y):
    return cmp(int(x), int(y))

class render_panel(wx.Panel):

    def __init__(self, parent, style):
        wx.Panel.__init__(self, parent.book, style=style)
        # scroll = wx.ScrolledWindow(self, -1, style=wx.SUNKEN_BORDER)
        # scroll.SetScrollRate(20,20)

        self.main = parent
        # Create the CustomTreeCtrl, using a derived class defined below
        self.tree = CustomTreeCtrl(self, -1, rootLable="renders",
                                   style=wx.SUNKEN_BORDER,
                                   agwStyle=CT.TR_HAS_BUTTONS | CT.TR_HAS_VARIABLE_ROW_HEIGHT)
        self.tree.SetBackgroundColour('#dddddd')

        self.tree.menu_callback = self.show_menu
        self.tree.check_callback = self.on_item_check
        self.tree.select_callback = self.on_item_select

        mainsizer = wx.BoxSizer(wx.VERTICAL)
        mainsizer.Add(self.tree, 4, wx.EXPAND)
        mainsizer.Layout()
        self.SetSizer(mainsizer)

        self.processing = False

        dispatcher.connect(receiver=self.set_edit_mode,
                           signal="Editor.EditMode")

    def set_edit_mode(self, edit_mode):
        if not edit_mode:
            self.tree.SetBackgroundColour('#dddddd')
        else:
            self.tree.SetBackgroundColour(wx.WHITE)

    def on_item_check(self, tree, evt):
        if self.processing:
            return
        item = evt.GetItem()
        data = tree.GetPyData(item)
        if len(data) == 1:
            self.main.Send("set_render_visible(%s, %d)" %
                           (data[0], int(item.IsChecked())))
        elif len(data) == 2:
            self.main.Send("set_sprite_visible(%s, %s, %d)" %
                           (data[0], data[1], int(item.IsChecked())))
        elif len(data) > 2:
            arg = "%s,%s" % (data[0], data[1])
            for i in data[2:]:
                arg += ",'%s'" % i
            self.main.Send("toggle_child_visible(%s)" % arg)

    def on_item_select(self, tree, evt):
        item = evt.GetItem()
        data = tree.GetPyData(item)
        if data and len(data) >= 2:
            arg = "%s,%s" % (data[0], data[1])
            for i in data[2:]:
                arg += ",'%s'" % i
            print(self.main.Send("select_sprite(%s)" % (arg)))

    def show_menu(self, tree, item):
        menu = wx.Menu()

        item1 = menu.Append(wx.ID_ANY, "Change item background colour")
        item2 = menu.Append(wx.ID_ANY, "Modify item text colour")
        menu.AppendSeparator()

        if False:
            strs = "Make item text not bold"
        else:
            strs = "Make item text bold"

        item3 = menu.Append(wx.ID_ANY, strs)
        item4 = menu.Append(wx.ID_ANY, "Change item font")
        menu.AppendSeparator()

        if False:
            strs = "Set item as non-hyperlink"
        else:
            strs = "Set item as hyperlink"

        item5 = menu.Append(wx.ID_ANY, strs)
        menu.AppendSeparator()

        item13 = menu.Append(wx.ID_ANY, "Insert separator")
        menu.AppendSeparator()

        if False:
            enabled = tree.GetItemWindowEnabled(item)
            if enabled:
                strs = "Disable associated widget"
            else:
                strs = "Enable associated widget"
        else:
            strs = "Enable associated widget"

        item6 = menu.Append(wx.ID_ANY, strs)

        if not False:
            item6.Enable(False)

        item7 = menu.Append(wx.ID_ANY, "Disable item")

        menu.AppendSeparator()
        item8 = menu.Append(wx.ID_ANY, "Change item icons")
        menu.AppendSeparator()
        item9 = menu.Append(wx.ID_ANY, "Get other information for this item")
        menu.AppendSeparator()

        item10 = menu.Append(wx.ID_ANY, "Delete item")
        if item == tree.GetRootItem():
            item10.Enable(False)
            item13.Enable(False)

        item11 = menu.Append(wx.ID_ANY, "Prepend an item")
        item12 = menu.Append(wx.ID_ANY, "Append an item")

        tree.Bind(wx.EVT_MENU, tree.OnItemBackground, item1)
        tree.Bind(wx.EVT_MENU, tree.OnItemForeground, item2)
        tree.Bind(wx.EVT_MENU, tree.OnItemBold, item3)
        tree.Bind(wx.EVT_MENU, tree.OnItemFont, item4)
        tree.Bind(wx.EVT_MENU, tree.OnItemHyperText, item5)
        tree.Bind(wx.EVT_MENU, tree.OnEnableWindow, item6)
        tree.Bind(wx.EVT_MENU, tree.OnDisableItem, item7)
        tree.Bind(wx.EVT_MENU, tree.OnItemIcons, item8)
        tree.Bind(wx.EVT_MENU, tree.OnItemInfo, item9)
        tree.Bind(wx.EVT_MENU, tree.OnItemDelete, item10)
        tree.Bind(wx.EVT_MENU, tree.OnItemPrepend, item11)
        tree.Bind(wx.EVT_MENU, tree.OnItemAppend, item12)
        tree.Bind(wx.EVT_MENU, tree.OnSeparatorInsert, item13)

        tree.PopupMenu(menu)
        menu.Destroy()

    def set_data(self, data, packs):
        self.tree.Reset()

        self.processing = True
        root = self.tree.root
        editable = self.main.edit_mode
        ids = data.keys()
        ids.sort(id_cmp)
        for k in ids:
            v = data[k]
            name = v.get('name', "") + "(layer_%s)" % v.get('layer', '?')
            sprites = v.get('sorted_sprites')
            has_child = sprites and isinstance(sprites, type({}))
            offscreen = v.get("drawonce", False)
            ct_type = (has_child and not offscreen and editable) and 1 or 0
            rd = self.tree.AppendItem(root, name, ct_type=ct_type)
            layer = v['layer']
            self.tree.SetPyData(rd, [layer])
            if has_child:
                if not offscreen:
                    if ct_type == 1 and v.get('draw_call', False):
                        self.tree.CheckItem(rd)
                for i, s in sprites.iteritems():
                    edit = s.get('edit')
                    name = edit and "%s.%s" % (
                        edit['packname'], edit['name']) or repr(s)
                    proot = self.tree.AppendItem(
                        rd, name, ct_type=editable and 1 or 0)
                    if offscreen:
                        self.tree.EnableItem(proot, False)
                        self.tree.SetPyData(proot, [layer, i])
                    else:
                        self.tree.CheckItem(proot)
                        self.tree.SetPyData(proot, [layer, i])

                    if edit:
                        self.set_pack_data(proot, packs, edit)
        self.processing = False

    def set_pack_data(self, root, packs, para):
        package = packs.get(para['packname'], {})
        sprite = pack_tree.get_export(package, para['name'])
        if not sprite:
            return
        pack_tree.show_sprite(self.tree, root, sprite, package)

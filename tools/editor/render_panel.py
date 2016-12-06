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
        self.tree.drag_begin_callback = self.on_drag_begin
        self.tree.drag_end_callback = self.on_drag_end

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

    def pydata_to_sprite(self, data):
        if data and len(data) >= 2:
            arg = "%s,%s" % (data[0], data[1])
            for i in data[2:]:
                arg += ",'%s'" % i
            return arg


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
            arg = self.pydata_to_sprite(data)
            if arg:
                self.main.Send("toggle_child_visible(%s)" % arg)

    def on_drag_begin(self, tree, evt):
        self.drag_item = evt.GetItem()
        self.drag_type = "LeftDrag"

    def is_parent_node(self, src, tar):
        if not src or not tar or len(tar) == 0: return False
        if len(src) == len(tar) + 1:
            for k, v in enumerate(tar):
                if src[k] != v:
                    return False
            return True
        return False

    def on_drag_end(self, tree, evt):
        target = evt.GetItem()
        if not target.IsOk(): return

        source = self.drag_item
        if not source: return

        if self.tree.ItemIsChildOf(target, source):
            print "the tree item can not be moved in to itself! "
            self.tree.Unselect()
            return

        src_data = tree.GetPyData(source)
        tar_data = tree.GetPyData(target)
        if not src_data or not tar_data: return
        if len(src_data) == 1 and len(tar_data) == 1: return

        if self.is_parent_node(src_data, tar_data):
            print("no need to remove")
            return

        print(src_data)
        print(tar_data)
        if len(tar_data) == 1 and len(src_data) == 2:
            arg = self.pydata_to_sprite(src_data)
            self.main.Move(arg, tar_data[0])

    def on_item_select(self, tree, evt):
        item = evt.GetItem()
        data = tree.GetPyData(item)
        arg = self.pydata_to_sprite(data)
        if arg:
            self.main.Send("select_sprite(%s)" % (arg))

    def del_sprite(self, evt):
        arg = self.pydata_to_sprite(self.menu_data)
        if arg:
            self.main.DelSprite(arg)

    def show_menu(self, tree, item):
        self.menu_data = tree.GetPyData(item)
        if not self.menu_data:
            self.menu_data = None
            return

        menu = wx.Menu()

        if len(self.menu_data) >= 2:
            item1 = menu.Append(wx.ID_ANY, "Del sprite")
            tree.Bind(wx.EVT_MENU, self.del_sprite, item1)

        menu.AppendSeparator()

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

import wx
import os
import sys

try:
    from agw import customtreectrl as CT
except ImportError:  # if it's not there locally, try the wxPython lib.
    import wx.lib.agw.customtreectrl as CT


class CustomTreeCtrl(CT.CustomTreeCtrl):

    def __init__(self, parent, id=wx.ID_ANY, pos=wx.DefaultPosition,
                 size=wx.DefaultSize,
                 style=wx.SUNKEN_BORDER | wx.WANTS_CHARS,
                 agwStyle=CT.TR_HAS_BUTTONS | CT.TR_HAS_VARIABLE_ROW_HEIGHT,
                 log=None, rootLable="RootItem"):

        CT.CustomTreeCtrl.__init__(
            self, parent, id, pos, size, style, agwStyle)

        self.SetBackgroundColour(wx.WHITE)
        self.item = None

        self.count = 0
        self.log = log
        self.menu_callback = None
        self.check_callback = None
        self.select_callback = None

        # NOTE:  For some reason tree items have to have a data object in
        #        order to be sorted.  Since our compare just uses the labels
        #        we don't need any real data, so we'll just use None below for
        #        the item data.

        self.rootLable = rootLable
        self.Reset()

        self.Bind(wx.EVT_LEFT_DCLICK, self.OnLeftDClick)
        self.Bind(wx.EVT_IDLE, self.OnIdle)

        self.eventdict = {'EVT_TREE_BEGIN_DRAG': self.OnBeginDrag, 'EVT_TREE_BEGIN_LABEL_EDIT': self.OnBeginEdit,
                          'EVT_TREE_BEGIN_RDRAG': self.OnBeginRDrag, 'EVT_TREE_DELETE_ITEM': self.OnDeleteItem,
                          'EVT_TREE_END_DRAG': self.OnEndDrag, 'EVT_TREE_END_LABEL_EDIT': self.OnEndEdit,
                          'EVT_TREE_ITEM_ACTIVATED': self.OnActivate, 'EVT_TREE_ITEM_CHECKED': self.OnItemCheck,
                          'EVT_TREE_ITEM_COLLAPSED': self.OnItemCollapsed,
                          'EVT_TREE_ITEM_COLLAPSING': self.OnItemCollapsing, 'EVT_TREE_ITEM_EXPANDED': self.OnItemExpanded,
                          'EVT_TREE_ITEM_EXPANDING': self.OnItemExpanding, 'EVT_TREE_ITEM_GETTOOLTIP': self.OnToolTip,
                          'EVT_TREE_ITEM_MENU': self.OnItemMenu,
                          'EVT_TREE_KEY_DOWN': self.OnKey, 'EVT_TREE_SEL_CHANGED': self.OnSelChanged,
                          'EVT_TREE_SEL_CHANGING': self.OnSelChanging, "EVT_TREE_ITEM_HYPERLINK": self.OnHyperLink}

        for k, v in self.eventdict.iteritems():
            self.Bind(eval("CT." + k), v)
        self.Bind(wx.EVT_RIGHT_DOWN, self.OnRightDown)
        self.Bind(wx.EVT_RIGHT_UP, self.OnRightUp)

        if not(self.GetAGWWindowStyleFlag() & CT.TR_HIDE_ROOT):
            self.SelectItem(self.root)
            self.Expand(self.root)

    def Reset(self):
        self.DeleteAllItems()

        self.root = self.AddRoot(self.rootLable)

        if not(self.GetAGWWindowStyleFlag() & CT.TR_HIDE_ROOT):
            self.SetPyData(self.root, None)
            self.SetItemImage(self.root, 24, CT.TreeItemIcon_Normal)
            self.SetItemImage(self.root, 13, CT.TreeItemIcon_Expanded)

    def ChangeStyle(self, combos):

        style = 0
        for combo in combos:
            if combo.GetValue() == 1:
                style = style | eval("CT." + combo.GetLabel())

        if self.GetAGWWindowStyleFlag() != style:
            self.SetAGWWindowStyleFlag(style)

    def OnCompareItems(self, item1, item2):

        t1 = self.GetItemText(item1)
        t2 = self.GetItemText(item2)

        # self.log.write('compare: ' + t1 + ' <> ' + t2 + "\n")

        if t1 < t2:
            return -1
        if t1 == t2:
            return 0

        return 1

    def OnIdle(self, event):
        pass

    def OnRightDown(self, event):
        pt = event.GetPosition()
        item, flags = self.HitTest(pt)

        if item:
            self.item = item
            self.SelectItem(item)

    def OnRightUp(self, event):

        item = self.item

        if not item:
            event.Skip()
            return

        if not self.IsItemEnabled(item):
            event.Skip()
            return

        # Item Text Appearance
        ishtml = self.IsItemHyperText(item)
        back = self.GetItemBackgroundColour(item)
        fore = self.GetItemTextColour(item)
        isbold = self.IsBold(item)
        font = self.GetItemFont(item)

        # Icons On Item
        normal = self.GetItemImage(item, CT.TreeItemIcon_Normal)
        selected = self.GetItemImage(item, CT.TreeItemIcon_Selected)
        expanded = self.GetItemImage(item, CT.TreeItemIcon_Expanded)
        selexp = self.GetItemImage(item, CT.TreeItemIcon_SelectedExpanded)

        # Enabling/Disabling Windows Associated To An Item
        haswin = self.GetItemWindow(item)

        # Enabling/Disabling Items
        enabled = self.IsItemEnabled(item)

        # Generic Item's Info
        children = self.GetChildrenCount(item)
        itemtype = self.GetItemType(item)
        text = self.GetItemText(item)
        pydata = self.GetPyData(item)
        separator = self.IsItemSeparator(item)

        self.current = item
        self.itemdict = {"ishtml": ishtml, "back": back, "fore": fore, "isbold": isbold,
                         "font": font, "normal": normal, "selected": selected, "expanded": expanded,
                         "selexp": selexp, "haswin": haswin, "children": children,
                         "itemtype": itemtype, "text": text, "pydata": pydata, "enabled": enabled,
                         "separator": separator}

        if self.menu_callback:
            self.menu_callback(self, self.current)

    def OnItemBackground(self, event):

        colourdata = wx.ColourData()
        colourdata.SetColour(self.itemdict["back"])
        dlg = wx.ColourDialog(self, colourdata)

        dlg.GetColourData().SetChooseFull(True)

        if dlg.ShowModal() == wx.ID_OK:
            data = dlg.GetColourData()
            col1 = data.GetColour().Get()
            self.SetItemBackgroundColour(self.current, col1)
        dlg.Destroy()

    def OnItemForeground(self, event):

        colourdata = wx.ColourData()
        colourdata.SetColour(self.itemdict["fore"])
        dlg = wx.ColourDialog(self, colourdata)

        dlg.GetColourData().SetChooseFull(True)

        if dlg.ShowModal() == wx.ID_OK:
            data = dlg.GetColourData()
            col1 = data.GetColour().Get()
            self.SetItemTextColour(self.current, col1)
        dlg.Destroy()

    def OnItemBold(self, event):

        self.SetItemBold(self.current, not self.itemdict["isbold"])

    def OnItemFont(self, event):

        data = wx.FontData()
        font = self.itemdict["font"]

        if font is None:
            font = wx.SystemSettings_GetFont(wx.SYS_DEFAULT_GUI_FONT)

        data.SetInitialFont(font)

        dlg = wx.FontDialog(self, data)

        if dlg.ShowModal() == wx.ID_OK:
            data = dlg.GetFontData()
            font = data.GetChosenFont()
            self.SetItemFont(self.current, font)

        dlg.Destroy()

    def OnItemHyperText(self, event):

        self.SetItemHyperText(self.current, not self.itemdict["ishtml"])

    def OnEnableWindow(self, event):

        enable = self.GetItemWindowEnabled(self.current)
        self.SetItemWindowEnabled(self.current, not enable)

    def OnDisableItem(self, event):

        self.EnableItem(self.current, False)

    def OnItemIcons(self, event):

        bitmaps = [self.itemdict["normal"], self.itemdict["selected"],
                   self.itemdict["expanded"], self.itemdict["selexp"]]

        wx.BeginBusyCursor()
        dlg = TreeIcons(self, -1, bitmaps=bitmaps)
        wx.EndBusyCursor()
        dlg.ShowModal()

    def SetNewIcons(self, bitmaps):

        self.SetItemImage(self.current, bitmaps[0], CT.TreeItemIcon_Normal)
        self.SetItemImage(self.current, bitmaps[1], CT.TreeItemIcon_Selected)
        self.SetItemImage(self.current, bitmaps[2], CT.TreeItemIcon_Expanded)
        self.SetItemImage(self.current, bitmaps[
                          3], CT.TreeItemIcon_SelectedExpanded)

    def OnItemInfo(self, event):

        itemtext = self.itemdict["text"]
        numchildren = str(self.itemdict["children"])
        itemtype = self.itemdict["itemtype"]
        pydata = repr(type(self.itemdict["pydata"]))

        if itemtype == 0:
            itemtype = "Normal"
        elif itemtype == 1:
            itemtype = "CheckBox"
        else:
            itemtype = "RadioButton"

        strs = "Information On Selected Item:\n\n" + "Text: " + itemtext + "\n" \
               "Number Of Children: " + numchildren + "\n" \
               "Item Type: " + itemtype + "\n" \
               "Item Data Type: " + pydata + "\n"

        dlg = wx.MessageDialog(
            self, strs, "CustomTreeCtrlDemo Info", wx.OK | wx.ICON_INFORMATION)
        dlg.ShowModal()
        dlg.Destroy()

    def OnItemDelete(self, event):

        strs = "Are You Sure You Want To Delete Item " + \
            self.GetItemText(self.current) + "?"
        dlg = wx.MessageDialog(None, strs, 'Deleting Item',
                               wx.YES_NO | wx.NO_DEFAULT | wx.CANCEL | wx.ICON_QUESTION)

        if dlg.ShowModal() in [wx.ID_NO, wx.ID_CANCEL]:
            dlg.Destroy()
            return

        dlg.Destroy()

        self.DeleteChildren(self.current)
        self.Delete(self.current)
        self.current = None

    def OnItemPrepend(self, event):

        dlg = wx.TextEntryDialog(
            self, "Please Enter The New Item Name", 'Item Naming', 'Python')

        if dlg.ShowModal() == wx.ID_OK:
            newname = dlg.GetValue()
            newitem = self.PrependItem(self.current, newname)
            self.EnsureVisible(newitem)

        dlg.Destroy()

    def OnItemAppend(self, event):

        dlg = wx.TextEntryDialog(
            self, "Please Enter The New Item Name", 'Item Naming', 'Python')

        if dlg.ShowModal() == wx.ID_OK:
            newname = dlg.GetValue()
            newitem = self.AppendItem(self.current, newname)
            self.EnsureVisible(newitem)

        dlg.Destroy()

    def OnSeparatorInsert(self, event):

        newitem = self.InsertSeparator(
            self.GetItemParent(self.current), self.current)
        self.EnsureVisible(newitem)

    def OnBeginEdit(self, event):

        # self.log.write("OnBeginEdit" + "\n")
        # show how to prevent edit...
        item = event.GetItem()
        if item and self.GetItemText(item) == "The Root Item":
            wx.Bell()
            # self.log.write("You can't edit this one..." + "\n")

            # Lets just see what's visible of its children
            cookie = 0
            root = event.GetItem()
            (child, cookie) = self.GetFirstChild(root)

            # while child:
            #     self.log.write("Child [%s] visible = %d" % (self.GetItemText(child), self.IsVisible(child)) + "\n")
            #     (child, cookie) = self.GetNextChild(root, cookie)

            event.Veto()

    def OnEndEdit(self, event):
        pass
        # self.log.write("OnEndEdit: %s %s" %(event.IsEditCancelled(), event.GetLabel()))
        # show how to reject edit, we'll not allow any digits
        # for x in event.GetLabel():
        #     if x in string.digits:
        #         self.log.write(", You can't enter digits..." + "\n")
        #         event.Veto()
        #         return

        # self.log.write("\n")

    def OnLeftDClick(self, event):

        pt = event.GetPosition()
        item, flags = self.HitTest(pt)
        # if item and (flags & CT.TREE_HITTEST_ONITEMLABEL):
        #     if self.GetAGWWindowStyleFlag() & CT.TR_EDIT_LABELS:
        #         self.log.write("OnLeftDClick: %s (manually starting label edit)"% self.GetItemText(item) + "\n")
        #         self.EditLabel(item)
        #     else:
        #         self.log.write("OnLeftDClick: Cannot Start Manual Editing, Missing Style TR_EDIT_LABELS\n")

        event.Skip()

    def OnItemExpanded(self, event):

        item = event.GetItem()
        # if item:
        #     self.log.write("OnItemExpanded: %s" % self.GetItemText(item) + "\n")

    def OnItemExpanding(self, event):

        item = event.GetItem()
        # if item:
        #     self.log.write("OnItemExpanding: %s" % self.GetItemText(item) + "\n")

        event.Skip()

    def OnItemCollapsed(self, event):

        item = event.GetItem()
        # if item:
        #     self.log.write("OnItemCollapsed: %s" % self.GetItemText(item) + "\n")

    def OnItemCollapsing(self, event):

        item = event.GetItem()
        # if item:
        #     self.log.write("OnItemCollapsing: %s" % self.GetItemText(item) + "\n")

        event.Skip()

    def OnSelChanged(self, event):
        if self.select_callback:
            self.select_callback(self, event)
        event.Skip()

    def OnSelChanging(self, event):

        item = event.GetItem()
        olditem = event.GetOldItem()

        if item:
            if not olditem:
                olditemtext = "None"
            else:
                olditemtext = self.GetItemText(olditem)
            # self.log.write("OnSelChanging: From %s" % olditemtext + " To %s" % self.GetItemText(item) + "\n")

        event.Skip()

    def OnBeginDrag(self, event):

        self.item = event.GetItem()
        if self.item:
            # self.log.write("Beginning Drag..." + "\n")

            event.Allow()

    def OnBeginRDrag(self, event):

        self.item = event.GetItem()
        if self.item:
            # self.log.write("Beginning Right Drag..." + "\n")

            event.Allow()

    def OnEndDrag(self, event):

        self.item = event.GetItem()
        # if self.item:
        #     self.log.write("Ending Drag!" + "\n")

        event.Skip()

    def OnDeleteItem(self, event):

        item = event.GetItem()

        if not item:
            return

        # self.log.write("Deleting Item: %s" % self.GetItemText(item) + "\n")
        event.Skip()

    def OnItemCheck(self, event):
        if self.check_callback:
            self.check_callback(self, event)
        event.Skip()

    def OnItemChecking(self, event):

        item = event.GetItem()
        # self.log.write("Item " + self.GetItemText(item) + " Is Being Checked...\n")
        event.Skip()

    def OnToolTip(self, event):

        item = event.GetItem()
        if item:
            event.SetToolTip(wx.ToolTip(self.GetItemText(item)))

    def OnItemMenu(self, event):

        item = event.GetItem()
        # if item:
        #     self.log.write("OnItemMenu: %s" % self.GetItemText(item) + "\n")

        event.Skip()

    def OnKey(self, event):

        # keycode = event.GetKeyCode()
        # keyname = keyMap.get(keycode, None)

        # if keycode == wx.WXK_BACK:
        #     # self.log.write("OnKeyDown: HAHAHAHA! I Vetoed Your Backspace! HAHAHAHA\n")
        #     return

        # if keyname is None:
        #     if "unicode" in wx.PlatformInfo:
        #         keycode = event.GetUnicodeKey()
        #         if keycode <= 127:
        #             keycode = event.GetKeyCode()
        #         keyname = "\"" + unichr(event.GetUnicodeKey()) + "\""
        #         if keycode < 27:
        #             keyname = "Ctrl-%s" % chr(ord('A') + keycode - 1)

        #     elif keycode < 256:
        #         if keycode == 0:
        #             keyname = "NUL"
        #         elif keycode < 27:
        #             keyname = "Ctrl-%s" % chr(ord('A') + keycode - 1)
        #         else:
        #             keyname = "\"%s\"" % chr(keycode)
        #     else:
        #         keyname = "unknown (%s)" % keycode

        # # self.log.write("OnKeyDown: You Pressed '" + keyname + "'\n")

        event.Skip()

    def OnActivate(self, event):

        # if self.item:
        #     self.log.write("OnActivate: %s" % self.GetItemText(self.item) + "\n")

        event.Skip()

    def OnHyperLink(self, event):

        item = event.GetItem()
        # if item:
        #     self.log.write("OnHyperLink: %s" % self.GetItemText(self.item) + "\n")

    def OnTextCtrl(self, event):

        char = chr(event.GetKeyCode())
        # self.log.write("EDITING THE TEXTCTRL: You Wrote '" + char + \
        #                "' (KeyCode = " + str(event.GetKeyCode()) + ")\n")
        event.Skip()

    def OnComboBox(self, event):

        selection = event.GetEventObject().GetValue()
        # self.log.write("CHOICE FROM COMBOBOX: You Chose '" + selection + "'\n")
        event.Skip()

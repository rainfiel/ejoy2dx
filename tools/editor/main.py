import wx

import os
import sys
import json

from wx.py import dispatcher
try:
    dirName = os.path.dirname(os.path.abspath(__file__))
except:
    dirName = os.path.dirname(os.path.abspath(sys.argv[0]))

sys.path.append(os.path.split(dirName)[0])

try:
    import agw.flatnotebook as FNB
except ImportError: # if it's not there locally, try the wxPython lib.
    import wx.lib.agw.flatnotebook as FNB

import pack_panel
import render_panel
import images

#----------------------------------------------------------------------
import connect

class FlatNotebookDemo(wx.Frame):

    def __init__(self, parent, log):

        wx.Frame.__init__(self, parent, title="FlatNotebook Demo", size=(800,600))
        self.log = log

        self._bShowImages = False
        self._bVCStyle = False
        self._newPageCounter = 0

        self._ImageList = wx.ImageList(16, 16)
        self._ImageList.Add(images._book_red.GetBitmap())
        self._ImageList.Add(images._book_green.GetBitmap())
        self._ImageList.Add(images._book_blue.GetBitmap())

        self.statusbar = self.CreateStatusBar(2, wx.ST_SIZEGRIP)
        self.statusbar.SetStatusWidths([-2, -1])
        # statusbar fields
        statusbar_fields = [("----------------"),
                            ("Jai Guru de Va Om!")]

        for i in range(len(statusbar_fields)):
            self.statusbar.SetStatusText(statusbar_fields[i], i)

        self.SetIcon(images.Mondrian.GetIcon())
        self.CreateMenuBar()
        self.CreateRightClickMenu()
        self.LayoutItems()

        # self.Bind(FNB.EVT_FLATNOTEBOOK_PAGE_CHANGING, self.OnPageChanging)
        # self.Bind(FNB.EVT_FLATNOTEBOOK_PAGE_CHANGED, self.OnPageChanged)
        # self.Bind(FNB.EVT_FLATNOTEBOOK_PAGE_CLOSING, self.OnPageClosing)
        
        # self.Bind(wx.EVT_UPDATE_UI, self.OnDropDownArrowUI, id=MENU_USE_DROP_ARROW_BUTTON)
        # self.Bind(wx.EVT_UPDATE_UI, self.OnHideNavigationButtonsUI, id=MENU_HIDE_NAV_BUTTONS)
        # self.Bind(wx.EVT_UPDATE_UI, self.OnAllowForeignDndUI, id=MENU_ALLOW_FOREIGN_DND)

        self.discover = connect.create_discover()
        self.discover_timer = wx.Timer(self)
        self.discover_timer.Start(1000/30.0)
        self.Bind(wx.EVT_TIMER, self.OnTimer)
        self.connect = None

        self.edit_mode = False

    def OnTimer(self, evt):
        if not self.discover: return
        data = connect.discover(self.discover)
        if not data: return

        self.discover.close()
        self.discover = None
        self.discover_timer.Stop()
        self.discover_timer = None

        exp = "connect('%s', %s)" % (data['ip'], data['port'])
        self.connect = connect.connect(data['ip'], data['port'])
        connect.send_file(self.connect, "lua/bdbox.lua")
        connect.send_file(self.connect, "lua/crust.lua")

    def CreateMenuBar(self):

        menuBar = wx.MenuBar(wx.MB_DOCKABLE)
        menu = wx.Menu()
        item = menu.Append(-1, "&Refresh\tF5", "Refresh data")
        self.Bind(wx.EVT_MENU, self.OnRefreshEnv, item)

        item = menu.Append(-1, "&Edit Mode\tF4", "Toggle edit mode")
        self.Bind(wx.EVT_MENU, self.OnToggleEditMode, item)

        menu.AppendSeparator()

        item = menu.Append(wx.ID_EXIT, "E&xit\tCtrl-Q", "Exit")
        self.Bind(wx.EVT_MENU, self.OnExitApp, item)
        menuBar.Append(menu, "&File")

        self.SetMenuBar(menuBar)


    def CreateRightClickMenu(self):
        pass
        # self._rmenu = wx.Menu()
        # item = wx.MenuItem(self._rmenu, MENU_EDIT_DELETE_PAGE, "Close Tab\tCtrl+F4", "Close Tab")
        # self._rmenu.AppendItem(item)


    def LayoutItems(self):

        mainSizer = wx.BoxSizer(wx.HORIZONTAL)
        self.SetSizer(mainSizer)

        bookStyle = FNB.FNB_NODRAG

        self.book = FNB.FlatNotebook(self, wx.ID_ANY, agwStyle=bookStyle)
        self.packs = pack_panel.pack_panel(self, style=wx.SUNKEN_BORDER|wx.TAB_TRAVERSAL)
        self.book.AddPage(self.packs, "pack", True)

        self.renders = render_panel.render_panel(self, style=wx.SUNKEN_BORDER|wx.TAB_TRAVERSAL)
        self.book.AddPage(self.renders, "render", True)
        # self.render_tree = custom_tree.CustomTreeCtrl(renders)

        self.book.Tile(wx.HORIZONTAL)

        bookStyle &= ~(FNB.FNB_NODRAG)
        bookStyle |= FNB.FNB_ALLOW_FOREIGN_DND 
        self.secondBook = FNB.FlatNotebook(self, wx.ID_ANY, agwStyle=bookStyle)

        # Set right click menu to the notebook
        # self.book.SetRightClickMenu(self._rmenu)

        # Set the image list 
        self.book.SetImageList(self._ImageList)
        mainSizer.Add(self.book, 6, wx.EXPAND)

        # Add spacer between the books
        spacer = wx.Panel(self, -1)
        spacer.SetBackgroundColour(wx.SystemSettings_GetColour(wx.SYS_COLOUR_3DFACE))
        mainSizer.Add(spacer, 0, wx.ALL | wx.EXPAND)

        mainSizer.Add(self.secondBook, 2, wx.EXPAND)

        # Add some pages to the second notebook
        self.Freeze()

        text = wx.TextCtrl(self.secondBook, -1, "Second Book Page 1\n", style=wx.TE_MULTILINE | wx.TE_READONLY)
        self.secondBook.AddPage(text, "Second Book Page 1")

        text = wx.TextCtrl(self.secondBook, -1, "Second Book Page 2\n", style=wx.TE_MULTILINE | wx.TE_READONLY)
        self.secondBook.AddPage(text,  "Second Book Page 2")

        self.Thaw()

        mainSizer.Layout()
        self.SendSizeEvent()

    def OnExitApp(self, evt):
        self.Close(True)

    def OnToggleEditMode(self, evt):
        self.edit_mode = not self.edit_mode
        self.Send("edit_mode(%d)" % int(self.edit_mode))
        self.Refresh()

        dispatcher.send(signal='Editor.EditMode', sender=self, edit_mode=self.edit_mode)

    def Refresh(self):
        msg = self.Send("env(5)")
        if msg:
            msg = json.loads(msg)
            ps = msg.get('package_source')
            if ps:
                self.packs.set_data(ps)
            rd = msg.get('renders')
            if rd:
                self.renders.set_data(rd, ps)

    def OnRefreshEnv(self, evt):
        self.Refresh()

    def Send(self, exp):
        if self.connect:
            data = connect.send(self.connect, exp)
            if data is True:
                pass
            elif data:
                msg = data.get('msg')
                type = data.get('type', 'error')
                if type == 'error':
                    print(data)
                return msg

#---------------------------------------------------------------------------


class TestPanel(wx.Panel):
    def __init__(self, parent, log):
        self.log = log
        wx.Panel.__init__(self, parent, -1)

        b = wx.Button(self, -1, " Test FlatNotebook ", (50,50))
        self.Bind(wx.EVT_BUTTON, self.OnButton, b)


    def OnButton(self, evt):
        self.win = FlatNotebookDemo(self, self.log)
        self.win.Show(True)

#----------------------------------------------------------------------

def runTest(frame, nb, log):
    win = TestPanel(nb, log)
    return win

#----------------------------------------------------------------------


overview = FNB.__doc__



if __name__ == '__main__':
    import sys,os
    import run
    run.main(['', os.path.basename(sys.argv[0])] + sys.argv[1:])


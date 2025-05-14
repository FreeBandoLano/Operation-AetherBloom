import win32api
import win32con
import win32gui

class WindowsBalloonTip:
    def __init__(self, title, msg):
        message_map = {
            win32con.WM_DESTROY: self.OnDestroy,
        }
        # Register the Window class
        wc = win32gui.WNDCLASS()
        hinst = wc.hInstance = win32api.GetModuleHandle(None)
        wc.lpszClassName = "PythonTaskbar"
        wc.lpfnWndProc = message_map
        classAtom = win32gui.RegisterClass(wc)
        # Create the Window
        style = win32con.WS_OVERLAPPED | win32con.WS_SYSMENU
        self.hwnd = win32gui.CreateWindow(classAtom, "Taskbar", style,
                                          0, 0, win32con.CW_USEDEFAULT, win32con.CW_USEDEFAULT,
                                          0, 0, hinst, None)
        win32gui.UpdateWindow(self.hwnd)
        icon_flags = win32con.LR_LOADFROMFILE | win32con.LR_DEFAULTSIZE
        try:
            hicon = win32gui.LoadImage(hinst, "python.ico", win32con.IMAGE_ICON, 0, 0, icon_flags)
        except:
            hicon = win32gui.LoadIcon(0, win32con.IDI_APPLICATION)
        flags = win32gui.NIF_ICON | win32gui.NIF_MESSAGE | win32gui.NIF_TIP
        nid = (self.hwnd, 0, flags, win32con.WM_USER+20, hicon, "Aetherbloom Notification")
        win32gui.Shell_NotifyIcon(win32gui.NIM_ADD, nid)
        win32gui.Shell_NotifyIcon(win32gui.NIM_MODIFY,
                             (self.hwnd, 0, win32gui.NIF_INFO, win32con.WM_USER+20,
                              hicon, "Balloon  tooltip", msg, 200, title))
        print("Notification shown!")
        
    def OnDestroy(self, hwnd, msg, wparam, lparam):
        win32gui.Shell_NotifyIcon(win32gui.NIM_DELETE, (self.hwnd, 0))
        win32gui.PostQuitMessage(0)

if __name__ == '__main__':
    print("Showing notification...")
    WindowsBalloonTip("Test Notification", "This is a test message from Aetherbloom")
    print("Done!") 
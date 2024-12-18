import tkinter as tk
from ctypes import windll

class TranslucentWindow(tk.Tk):
    def __init__(self):
        super().__init__()

        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self.attributes('-transparentcolor', 'white')

        hwnd = windll.user32.GetParent(self.winfo_id())
        style = windll.user32.GetWindowLongW(hwnd, -20)
        style |= 0x00080000  # WS_EX_LAYERED
        windll.user32.SetWindowLongW(hwnd, -20, style)
        windll.user32.SetLayeredWindowAttributes(hwnd, 0, 255, 0x00000001)

        self.canvas = tk.Canvas(self, bg='white', highlightthickness=0)
        self.canvas.pack(fill='both', expand=True)

        self.bind('<Button-1>', self.start_move)
        self.bind('<B1-Motion>', self.do_move)

    def start_move(self, event):
        self.x = event.x
        self.y = event.y

    def do_move(self, event):
        x = self.winfo_pointerx() - self.x
        y = self.winfo_pointery() - self.y
        self.geometry(f'+{x}+{y}')

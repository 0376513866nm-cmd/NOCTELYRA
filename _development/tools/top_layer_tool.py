"""Small local batch PNG compositor. Originals are never overwritten."""
from pathlib import Path
from datetime import datetime
import os
import queue
import sys
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from PIL import Image, ImageTk

DEFAULT_SOURCE = Path.home() / 'Downloads' / 'NPC_Idle_39_Frames_8FPS'


def make_layer(overlay, canvas_size, scale=100., x=0, y=0, opacity=100.):
    """100% fits inside the frame, centered; offsets use original frame pixels."""
    ratio = min(canvas_size[0] / overlay.width, canvas_size[1] / overlay.height) * scale / 100
    size = (max(1, round(overlay.width * ratio)), max(1, round(overlay.height * ratio)))
    if size[0] * size[1] > 50_000_000:
        raise ValueError('Ảnh phủ quá lớn. Hãy giảm kích thước.')
    layer = overlay.convert('RGBA').resize(size, Image.Resampling.LANCZOS)
    if opacity < 100:
        layer.putalpha(layer.getchannel('A').point(lambda a: round(a * opacity / 100)))
    target = Image.new('RGBA', canvas_size)
    left = (canvas_size[0] - size[0]) // 2 + x
    top = (canvas_size[1] - size[1]) // 2 + y
    target.alpha_composite(layer, (left, top))
    return target


def composite(base, overlay, **settings):
    return Image.alpha_composite(base.convert('RGBA'), make_layer(overlay, base.size, **settings))


class App:
    def __init__(self, root, host=None):
        self.root = root
        root.title('Ghép ảnh phủ lên nhiều khung hình')
        root.geometry('820x820')
        root.minsize(700, 680)
        self.source = tk.StringVar(value=str(DEFAULT_SOURCE))
        self.top_path = tk.StringVar()
        self.automatic = tk.BooleanVar(value=True)
        self.status = tk.StringVar(value='Chọn ảnh phủ để tự ghép vào bộ 39 ảnh. Ảnh gốc được giữ nguyên.')
        self.values = {k: tk.StringVar(value=v) for k,v in [('scale','100'),('x','0'),('y','0'),('opacity','100')]}
        self.overlay = None
        self.preview_base = None
        self.output = None
        self.busy = False
        self.events = queue.Queue()
        self.preview_job = None
        body = ttk.Frame(host if host is not None else root, padding=14)
        body.pack(fill='both', expand=True)
        body.columnconfigure(1, weight=1)
        ttk.Label(body, text='Thư mục ảnh gốc:').grid(row=0, column=0, sticky='w', pady=5)
        ttk.Entry(body, textvariable=self.source).grid(row=0, column=1, sticky='ew', padx=8)
        ttk.Button(body, text='Chọn thư mục', command=self.pick_source).grid(row=0, column=2)
        ttk.Label(body, text='Ảnh phủ trên cùng:').grid(row=1, column=0, sticky='w', pady=5)
        ttk.Entry(body, textvariable=self.top_path, state='readonly').grid(row=1, column=1, sticky='ew', padx=8)
        self.pick_button = ttk.Button(body, text='Chọn ảnh phủ…', command=self.pick_top)
        self.pick_button.grid(row=1, column=2)
        ttk.Checkbutton(body, text='Tự xuất cả bộ ngay sau khi chọn ảnh phủ', variable=self.automatic).grid(row=2, column=0, columnspan=3, sticky='w', pady=9)
        settings = ttk.Frame(body)
        settings.grid(row=3, column=0, columnspan=3, sticky='ew', pady=3)
        for i,(key,label,lo,hi) in enumerate([('scale','Kích thước %',1,400),('x','Dịch X (px)',-5000,5000),('y','Dịch Y (px)',-5000,5000),('opacity','Độ đậm %',0,100)]):
            ttk.Label(settings, text=label).grid(row=0,column=i,padx=8,sticky='w')
            ttk.Spinbox(settings, textvariable=self.values[key], from_=lo, to=hi, width=12).grid(row=1,column=i,padx=8,pady=5)
            self.values[key].trace_add('write', self.schedule_preview)
        ttk.Label(body, text='100% = ảnh phủ vừa khung và đặt giữa. X dương: sang phải; Y dương: xuống dưới.').grid(row=4,column=0,columnspan=3,sticky='w',pady=4)
        ttk.Label(body, text='Ảnh PNG trong suốt cùng kích thước khung sẽ giữ đúng vị trí thiết kế.').grid(row=5,column=0,columnspan=3,sticky='w')
        self.canvas = tk.Canvas(body, background='#303438', highlightthickness=0)
        self.canvas.grid(row=6,column=0,columnspan=3,sticky='nsew',pady=10)
        body.rowconfigure(6, weight=1)
        self.canvas.bind('<Configure>', self.schedule_preview)
        actions=ttk.Frame(body)
        actions.grid(row=7,column=0,columnspan=3,sticky='ew')
        self.export_button=ttk.Button(actions,text='Xuất toàn bộ ảnh',command=self.export)
        self.export_button.pack(side='left')
        self.open_button=ttk.Button(actions,text='Mở thư mục kết quả',command=self.open_output,state='disabled')
        self.open_button.pack(side='left',padx=10)
        self.progress=ttk.Progressbar(body)
        self.progress.grid(row=8,column=0,columnspan=3,sticky='ew',pady=10)
        ttk.Label(body,textvariable=self.status,wraplength=760).grid(row=9,column=0,columnspan=3,sticky='w')
        self.refresh_source()
        root.after(80,self.poll)

    def files(self):
        folder=Path(self.source.get())
        if not folder.is_dir():
            raise ValueError('Không tìm thấy thư mục ảnh gốc.')
        top=Path(self.top_path.get()).resolve() if self.top_path.get() else None
        files=sorted(p for p in folder.iterdir() if p.is_file() and p.suffix.lower()=='.png' and p.resolve()!=top)
        if not files:
            raise ValueError('Thư mục không có ảnh PNG.')
        return files

    def settings(self):
        v={k:float(value.get()) for k,value in self.values.items()}
        if not (1<=v['scale']<=400 and 0<=v['opacity']<=100):
            raise ValueError('Kích thước từ 1–400%; độ đậm từ 0–100%.')
        v['x'],v['y']=round(v['x']),round(v['y'])
        return v

    def refresh_source(self):
        try:
            files=self.files()
            with Image.open(files[0]) as image:
                self.preview_base=image.convert('RGBA')
            self.status.set(f'{len(files)} ảnh PNG • {self.preview_base.width} × {self.preview_base.height} px. Chọn ảnh phủ để ghép.')
            self.schedule_preview()
        except Exception as exc:
            self.preview_base=None
            self.status.set(str(exc))

    def pick_source(self):
        if self.busy:return
        folder=filedialog.askdirectory(title='Chọn thư mục các khung PNG',initialdir=str(Path.home()/'Downloads'))
        if folder:
            self.source.set(folder)
            self.refresh_source()

    def pick_top(self):
        if self.busy:return
        path=filedialog.askopenfilename(title='Chọn ảnh phủ trên cùng',initialdir=str(Path.home()/'Downloads'),filetypes=[('Ảnh PNG','*.png'),('Ảnh khác','*.jpg *.jpeg *.webp')])
        if not path:return
        try:
            with Image.open(path) as image:
                self.overlay=image.convert('RGBA')
            self.top_path.set(path)
            self.preview()
            if self.automatic.get():self.export()
        except Exception as exc:
            messagebox.showerror('Không mở được ảnh',str(exc))

    def schedule_preview(self,*_):
        if self.preview_job:self.root.after_cancel(self.preview_job)
        self.preview_job=self.root.after(180,self.preview)

    def preview(self):
        self.preview_job=None
        if self.preview_base is None:return
        try:
            image=composite(self.preview_base,self.overlay,**self.settings()) if self.overlay is not None else self.preview_base.copy()
            # Checkerboard makes transparent pixels visible without changing exported PNGs.
            image.thumbnail((max(50,self.canvas.winfo_width()-16),max(50,self.canvas.winfo_height()-16)),Image.Resampling.LANCZOS)
            bg=Image.new('RGBA',image.size,'#ddd')
            from PIL import ImageDraw
            draw=ImageDraw.Draw(bg)
            for y in range(0,image.height,16):
                for x in range(0,image.width,16):
                    if (x//16+y//16)%2:draw.rectangle((x,y,x+15,y+15),fill='#aaa')
            bg.alpha_composite(image)
            self.photo=ImageTk.PhotoImage(bg)
            self.canvas.delete('all')
            self.canvas.create_image(self.canvas.winfo_width()/2,self.canvas.winfo_height()/2,image=self.photo)
        except (ValueError,tk.TclError):
            pass

    def export(self):
        if self.busy:return
        try:
            if self.overlay is None:raise ValueError('Hãy chọn ảnh phủ trước.')
            files=self.files()
            settings=self.settings()
            overlay=self.overlay.copy()
            out=Path(self.source.get())/('top_layer_'+datetime.now().strftime('%Y%m%d_%H%M%S_%f'))
            out.mkdir(exist_ok=False)
        except Exception as exc:
            messagebox.showerror('Chưa xuất được',str(exc));return
        self.busy=True
        self.pick_button.config(state='disabled')
        self.export_button.config(state='disabled')
        self.progress.config(maximum=len(files),value=0)
        self.status.set(f'Đang ghép {len(files)} ảnh…')
        def worker():
            try:
                for i,path in enumerate(files,1):
                    with Image.open(path) as base:
                        result=composite(base,overlay,**settings)
                        result.save(out/path.name)
                    self.events.put(('progress',i))
                self.events.put(('done',(out,len(files))))
            except Exception as exc:self.events.put(('error',str(exc)))
        threading.Thread(target=worker,daemon=True).start()

    def poll(self):
        try:
            while True:
                kind,value=self.events.get_nowait()
                if kind=='progress':self.progress.config(value=value)
                else:
                    self.busy=False
                    self.pick_button.config(state='normal')
                    self.export_button.config(state='normal')
                    if kind=='done':
                        self.output,count=value
                        self.status.set(f'Đã xuất {count} ảnh. Ảnh gốc giữ nguyên.\n{self.output}')
                        self.open_button.config(state='normal')
                    else:
                        self.status.set('Xuất chưa hoàn tất; ảnh gốc vẫn giữ nguyên.')
                        messagebox.showerror('Lỗi khi ghép',value)
        except queue.Empty:pass
        self.root.after(80,self.poll)

    def open_output(self):
        if self.output:os.startfile(str(self.output))


def self_test():
    base=Image.new('RGBA',(20,20),(0,0,255,255))
    overlay=Image.new('RGBA',(20,20),(255,0,0,0))
    overlay.putpixel((10,10),(255,0,0,255))
    result=composite(base,overlay)
    assert result.getpixel((10,10))==(255,0,0,255)
    assert result.getpixel((0,0))==(0,0,255,255)
    assert base.getpixel((10,10))==(0,0,255,255)
    half=composite(base,overlay,x=2,y=-1,opacity=50)
    assert half.getpixel((12,9))==(128,0,127,255)
    clipped=composite(base,overlay,x=200)
    assert clipped.tobytes()==base.tobytes()
    print('PASS: layer order, transparent pixels, opacity, offsets, clipping, original preserved')


if __name__=='__main__':
    if '--self-test' in sys.argv:self_test()
    else:
        root=tk.Tk()
        from npc_atlas_tool import AtlasPanel
        notebook=ttk.Notebook(root)
        notebook.pack(fill='both',expand=True)
        overlay_tab=ttk.Frame(notebook)
        notebook.add(overlay_tab,text='1. Ghép ảnh phủ')
        App(root,overlay_tab)
        atlas_tab=AtlasPanel(notebook,root)
        notebook.add(atlas_tab,text='2. Xóa nền + Atlas Godot')
        notebook.select(atlas_tab)
        root.title('Công cụ NPC — Ghép ảnh / Xóa nền / Atlas Godot')
        root.mainloop()

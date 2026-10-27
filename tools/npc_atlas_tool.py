"""Batch background removal and consistent Godot SpriteFrames atlas export."""
from pathlib import Path
from datetime import datetime
import json
import math
import os
import queue
import re
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import cv2
import numpy as np
from PIL import Image, ImageTk


def remove_background(image, threshold=225, mode='white'):
    rgba=np.array(image.convert('RGBA'))
    if mode=='keep':return Image.fromarray(rgba)
    rgb=rgba[:,:,:3]
    near_white=np.min(rgb,axis=2)>=threshold
    candidate=(near_white | (rgba[:,:,3]==0)).astype(np.uint8)
    _,labels=cv2.connectedComponents(candidate,connectivity=8)
    edge_labels=np.unique(np.concatenate([labels[0,:],labels[-1,:],labels[:,0],labels[:,-1]]))
    edge_labels=edge_labels[edge_labels!=0]
    bg=np.isin(labels,edge_labels).astype(np.float32)
    # Only remove near-white regions connected to the canvas boundary, so enclosed
    # white eyes, teeth and clothing stay. Feather one pixel and decontaminate white.
    soft=cv2.GaussianBlur(bg,(3,3),0.55)
    coverage=np.where(bg>0.5,0.0,1.0-soft)
    original_alpha=rgba[:,:,3].astype(np.float32)/255
    result_alpha=coverage*original_alpha
    safe=np.maximum(coverage[:,:,None],0.001)
    clean=(rgb.astype(np.float32)-255*(1-coverage[:,:,None]))/safe
    rgba[:,:,:3]=np.clip(clean,0,255).astype(np.uint8)
    rgba[:,:,3]=np.rint(result_alpha*255).astype(np.uint8)
    rgba[rgba[:,:,3]==0,:3]=0
    return Image.fromarray(rgba)


def natural_key(path):
    return [int(s) if s.isdigit() else s.lower() for s in re.split(r'(\d+)',path.name)]


def build_atlas(folder, threshold=225, mode='white', height=384, fps=8, progress=lambda *_:None):
    folder=Path(folder)
    files=sorted((p for p in folder.iterdir() if p.is_file() and p.suffix.lower()=='.png'),key=natural_key)
    if not files:raise ValueError('Thư mục đã chọn không có ảnh PNG.')
    if not 1<=len(files)<=500:raise ValueError('Chọn từ 1 đến 500 ảnh PNG.')
    with Image.open(files[0]) as first:size=first.size
    for path in files:
        with Image.open(path) as image:
            if image.size!=size:raise ValueError(f'{path.name} khác kích thước. Các khung cần cùng kích thước để giữ đúng vị trí.')
    out=folder/('npc_atlas_'+datetime.now().strftime('%Y%m%d_%H%M%S_%f'))
    frames_dir=out/'frames'
    frames_dir.mkdir(parents=True,exist_ok=False)
    box=None
    for i,path in enumerate(files):
        with Image.open(path) as image:clean=remove_background(image,threshold,mode)
        # Use one bounding rectangle for the entire animation, never center frames separately.
        bounds=clean.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox()
        if bounds:
            box=bounds if box is None else (min(box[0],bounds[0]),min(box[1],bounds[1]),max(box[2],bounds[2]),max(box[3],bounds[3]))
        clean.save(frames_dir/f'idle_{i+1:03d}.png')
        progress(i+1,2*len(files),'Xóa nền')
    if box is None:raise ValueError('Sau khi xóa nền không còn nhân vật. Hãy giảm mức xóa nền hoặc chọn Giữ alpha.')
    box=(max(0,box[0]-8),max(0,box[1]-8),min(size[0],box[2]+8),min(size[1],box[3]+8))
    width=max(1,round((box[2]-box[0])*height/(box[3]-box[1])))
    gutter=2
    cell_w,cell_h=width+2*gutter,height+2*gutter
    columns=min(8,len(files),8192//cell_w)
    if columns<1:raise ValueError('Khung quá rộng. Hãy giảm chiều cao xuất.')
    rows=math.ceil(len(files)/columns)
    if rows*cell_h>8192:raise ValueError('Atlas quá lớn. Hãy giảm chiều cao xuất hoặc số khung.')
    atlas=Image.new('RGBA',(columns*cell_w,rows*cell_h))
    records=[]
    for i,path in enumerate(files):
        frame_path=frames_dir/f'idle_{i+1:03d}.png'
        with Image.open(frame_path) as image:
            frame=image.crop(box).resize((width,height),Image.Resampling.LANCZOS)
        frame.save(frame_path)
        x=(i%columns)*cell_w+gutter
        y=(i//columns)*cell_h+gutter
        atlas.paste(frame,(x,y))
        # Extrude edge pixels in the gutter to prevent neighboring-frame bleed.
        atlas.paste(frame.crop((0,0,1,height)).resize((gutter,height)),(x-gutter,y))
        atlas.paste(frame.crop((width-1,0,width,height)).resize((gutter,height)),(x+width,y))
        atlas.paste(frame.crop((0,0,width,1)).resize((width,gutter)),(x,y-gutter))
        atlas.paste(frame.crop((0,height-1,width,height)).resize((width,gutter)),(x,y+height))
        records.append(dict(index=i+1,source=path.name,region=[x,y,width,height]))
        progress(len(files)+i+1,2*len(files),'Đóng atlas')
    atlas.save(out/'npc_idle_atlas.png')
    resource=[f'[gd_resource type="SpriteFrames" load_steps={len(files)+2} format=3]',
              '', '[ext_resource type="Texture2D" path="npc_idle_atlas.png" id="1"]','']
    for record in records:
        resource.extend([f'[sub_resource type="AtlasTexture" id="Frame_{record["index"]}"]',
                         'atlas = ExtResource("1")',f'region = Rect2({", ".join(map(str,record["region"]))})','filter_clip = true',''])
    resource.extend(['[resource]','animations = [{','"frames": ['])
    resource.append(',\n'.join('{"duration": 1.0, "texture": SubResource("Frame_%d")}'%r['index'] for r in records))
    resource.extend(['],','"loop": true,','"name": &"idle",',f'"speed": {float(fps)}','}]'])
    (out/'npc_idle.tres').write_text('\n'.join(resource),encoding='utf-8')
    metadata=dict(fps=fps,count=len(files),frame_size=[width,height],columns=columns,rows=rows,gutter=gutter,
                  source_size=size,shared_crop=box,frames=records)
    (out/'atlas.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    (out/'HUONG_DAN.txt').write_text(
        'KẾT QUẢ\nframes/: PNG trong suốt, cùng khung cắt và kích thước.\n'
        'npc_idle_atlas.png: atlas có đệm 2px.\nnpc_idle.tres: SpriteFrames, hoạt ảnh idle chạy xuôi ở 8 FPS (hoặc FPS đã chọn).\n\n'
        'DÙNG TRONG GODOT\n1. Chép cả npc_idle_atlas.png và npc_idle.tres vào cùng một thư mục trong project.\n'
        '2. Gán npc_idle.tres vào Sprite Frames của AnimatedSprite2D; chọn idle và bật Autoplay.\n'
        '3. Đặt Centered = Off, Offset X = -nửa chiều rộng khung, Offset Y = -chiều cao khung; chỉnh Scale cho vừa NPC.\n'
        '4. Ẩn ảnh NPC cũ. Nếu video đã có nhịp thở thì tắt track nhún VisualRoot để tránh chồng chuyển động.\n'
        'Ảnh gốc không bị thay đổi. Có thể chỉnh ngưỡng nếu mất chi tiết sáng sát mép; nền trắng bao kín trong nhân vật được giữ lại.\n',encoding='utf-8')
    return out,metadata


class AtlasPanel(ttk.Frame):
    def __init__(self,parent,root):
        super().__init__(parent,padding=14)
        self.root=root
        self.folder=tk.StringVar(value=str(Path.home()/'Downloads'/'NPC_Idle_39_Frames_8FPS'))
        self.mode=tk.StringVar(value='Nền trắng')
        self.threshold=tk.IntVar(value=225)
        self.height=tk.IntVar(value=384)
        self.fps=tk.IntVar(value=8)
        self.auto=tk.BooleanVar(value=True)
        self.status=tk.StringVar(value='Chọn thư mục ảnh đã hoàn thiện. Tool xóa nền trắng, giữ cùng khung cắt và tạo atlas.')
        self.events=queue.Queue()
        self.busy=False
        self.output=None
        self.columnconfigure(0,weight=1)
        ttk.Label(self,text='Thư mục khung PNG:').grid(row=0,column=0,sticky='w')
        ttk.Entry(self,textvariable=self.folder).grid(row=1,column=0,sticky='ew',pady=8)
        self.choose=ttk.Button(self,text='Chọn thư mục…',command=self.pick)
        self.choose.grid(row=1,column=1,padx=8)
        ttk.Checkbutton(self,text='Tự xử lý ngay sau khi chọn thư mục',variable=self.auto).grid(row=2,column=0,columnspan=2,sticky='w')
        controls=ttk.Frame(self)
        controls.grid(row=3,column=0,columnspan=2,sticky='ew',pady=15)
        ttk.Label(controls,text='Nền').grid(row=0,column=0,padx=5)
        ttk.Combobox(controls,textvariable=self.mode,values=['Nền trắng','Giữ alpha có sẵn'],state='readonly',width=21).grid(row=1,column=0,padx=5)
        for col,(label,var,lo,hi) in enumerate([('Ngưỡng trắng',self.threshold,180,250),('Chiều cao khung',self.height,128,1024),('FPS',self.fps,1,60)],1):
            ttk.Label(controls,text=label).grid(row=0,column=col,padx=5)
            ttk.Spinbox(controls,textvariable=var,from_=lo,to=hi,width=12).grid(row=1,column=col,padx=5)
        ttk.Label(self,text='Mặc định: nền trắng, 384px/khung, 8 FPS, phát xuôi. Không ghi đè ảnh gốc.\nCác ảnh phải cùng kích thước; tool tự sắp theo số trong tên file.\nNếu ảnh đã trong suốt, chọn “Giữ alpha có sẵn”.',wraplength=740).grid(row=4,column=0,columnspan=2,sticky='w')
        self.canvas=tk.Canvas(self,bg='#303438',highlightthickness=0)
        self.canvas.grid(row=5,column=0,columnspan=2,sticky='nsew',pady=12)
        self.rowconfigure(5,weight=1)
        actions=ttk.Frame(self)
        actions.grid(row=6,column=0,columnspan=2,sticky='ew')
        self.run=ttk.Button(actions,text='Xóa nền + xuất atlas',command=self.start)
        self.run.pack(side='left')
        self.open=ttk.Button(actions,text='Mở kết quả',state='disabled',command=lambda:os.startfile(str(self.output)))
        self.open.pack(side='left',padx=10)
        self.progress=ttk.Progressbar(self)
        self.progress.grid(row=7,column=0,columnspan=2,sticky='ew',pady=10)
        ttk.Label(self,textvariable=self.status,wraplength=740).grid(row=8,column=0,columnspan=2,sticky='w')
        root.after(80,self.poll)

    def pick(self):
        if self.busy:return
        folder=filedialog.askdirectory(title='Chọn thư mục ảnh PNG đã phủ xong',initialdir=str(Path.home()/'Downloads'))
        if folder:
            self.folder.set(folder)
            if self.auto.get():self.start()

    def start(self):
        if self.busy:return
        try:
            folder=Path(self.folder.get())
            if not folder.is_dir():raise ValueError('Không tìm thấy thư mục.')
            threshold,height,fps=self.threshold.get(),self.height.get(),self.fps.get()
            if not(180<=threshold<=250 and 128<=height<=1024 and 1<=fps<=60):raise ValueError('Thông số ngoài khoảng cho phép.')
            mode='white' if self.mode.get()=='Nền trắng' else 'keep'
        except Exception as exc:messagebox.showerror('Chưa chạy được',str(exc));return
        self.busy=True
        self.run.config(state='disabled')
        self.choose.config(state='disabled')
        self.status.set('Đang kiểm tra và xử lý…')
        def worker():
            try:
                out,meta=build_atlas(folder,threshold,mode,height,fps,lambda n,total,stage:self.events.put(('progress',(n,total,stage))))
                self.events.put(('done',(out,meta)))
            except Exception as exc:self.events.put(('error',str(exc)))
        threading.Thread(target=worker,daemon=True).start()

    def poll(self):
        try:
            while True:
                kind,data=self.events.get_nowait()
                if kind=='progress':
                    n,total,stage=data
                    self.progress.config(maximum=total,value=n)
                    self.status.set(f'{stage}: {n}/{total}')
                else:
                    self.busy=False
                    self.run.config(state='normal')
                    self.choose.config(state='normal')
                    if kind=='error':
                        self.status.set('Chưa hoàn tất; ảnh gốc vẫn giữ nguyên.')
                        messagebox.showerror('Xử lý chưa hoàn tất',data)
                    else:
                        self.output,meta=data
                        self.open.config(state='normal')
                        self.status.set(f'Xong {meta["count"]} ảnh • {meta["frame_size"][0]} × {meta["frame_size"][1]} • {meta["fps"]} FPS\n{self.output}')
                        with Image.open(self.output/'frames'/'idle_001.png') as image:preview=image.copy()
                        preview.thumbnail((max(100,self.canvas.winfo_width()-20),max(100,self.canvas.winfo_height()-20)))
                        self.photo=ImageTk.PhotoImage(preview)
                        self.canvas.delete('all')
                        self.canvas.create_image(self.canvas.winfo_width()/2,self.canvas.winfo_height()/2,image=self.photo)
        except queue.Empty:pass
        self.root.after(80,self.poll)

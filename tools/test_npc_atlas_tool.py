from pathlib import Path
import json
import tkinter as tk
from PIL import Image, ImageDraw
from npc_atlas_tool import remove_background, build_atlas, AtlasPanel

base=Path(__file__).resolve().parents[1]/'artifacts'/'atlas_tool_test'
base.mkdir(exist_ok=True)
for i in range(3):
    image=Image.new('RGBA',(120,160),'white')
    draw=ImageDraw.Draw(image)
    draw.rectangle((30+i*3,20,85+i*3,145),fill='#38694c')
    draw.rectangle((45+i*3,60,65+i*3,90),fill='white')
    image.save(base/f'frame_{i+1}.png')
clean=remove_background(image)
assert clean.getpixel((0,0))[3]==0
assert clean.getpixel((55,75))[3]==255, 'Interior white clothing should remain'
assert clean.getpixel((40,45))[3]==255
transparent=Image.new('RGBA',(20,20),(15,80,40,0))
transparent.putpixel((10,10),(255,255,255,255))
assert remove_background(transparent,mode='keep').tobytes()==transparent.tobytes()
output,meta=build_atlas(base,height=128)
assert meta['count']==3 and meta['fps']==8
assert len(list((output/'frames').glob('*.png')))==3
frames=[Image.open(output/'frames'/f'idle_{i+1:03d}.png') for i in range(3)]
assert len({f.size for f in frames})==1
assert len({f.getchannel('A').getbbox()[3] for f in frames})==1, 'Feet must remain aligned'
atlas=Image.open(output/'npc_idle_atlas.png')
for i,record in enumerate(meta['frames']):
    x,y,w,h=record['region']
    assert atlas.crop((x,y,x+w,y+h)).tobytes()==frames[i].tobytes()
assert Image.open(base/'frame_1.png').getpixel((0,0))==(255,255,255,255)
root=tk.Tk()
root.withdraw()
panel=AtlasPanel(root,root)
panel.pack()
root.update()
assert panel.fps.get()==8 and panel.auto.get()
root.destroy()
(base/'latest.json').write_text(json.dumps({'resource':str((output/'npc_idle.tres').relative_to(base.parents[1])).replace('\\','/')}))
print('PASS: background alpha, interior whites, frame alignment, atlas regions, originals unchanged, GUI initialized')
print(output)

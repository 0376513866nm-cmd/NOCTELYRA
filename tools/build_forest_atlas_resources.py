"""Create editable Godot atlas regions, without modifying source images."""
from pathlib import Path
import json
import cv2
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/environment/modular_forest'
OUT.mkdir(parents=True,exist_ok=True)
ROCKS='res://assets/asset/Mossy Rock Collection Spritesheet.png'
im=Image.open(ROOT/'assets/asset/Mossy Rock Collection Spritesheet.png').convert('RGBA')
mask=cv2.morphologyEx((np.asarray(im)[:,:,3]>80).astype(np.uint8),cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))
_,_,stats,_=cv2.connectedComponentsWithStats(mask,8)
boxes=[list(map(int,s[:4])) for s in stats[1:] if s[4]>600]
boxes.sort(key=lambda r:(r[1]//240,r[0]))
if len(boxes)!=24: raise RuntimeError(f'Expected 24 rocks, found {len(boxes)}')
for i,(x,y,w,h) in enumerate(boxes):
    x0,y0=max(0,x-3),max(0,y-3)
    x1,y1=min(im.width,x+w+3),min(im.height,y+h+3)
    (OUT/f'rock_{i:02}.tres').write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{ROCKS}" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({x0}, {y0}, {x1-x0}, {y1-y0})
filter_clip = true
''')
(OUT/'rock_regions.json').write_text(json.dumps(boxes,indent=2))
print(f'Created {len(boxes)} rock atlas resources in {OUT}')
BAMBOO='res://assets/asset/f30717e1f37801f4ee55ce276fddd781-Photoroom.png'
parts={'bamboo_green_a':(62,27,25,407),'bamboo_green_b':(124,27,25,407),'bamboo_dry':(477,34,26,407),'bamboo_leaves_a':(233,32,124,102),'bamboo_leaves_b':(279,348,101,112)}
for name,(x,y,w,h) in parts.items():
    (OUT/f'{name}.tres').write_text(f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]

[ext_resource type="Texture2D" path="{BAMBOO}" id="1"]

[resource]
atlas = ExtResource("1")
region = Rect2({x}, {y}, {w}, {h})
filter_clip = true
''')
print(f'Created {len(parts)} editable bamboo part resources')

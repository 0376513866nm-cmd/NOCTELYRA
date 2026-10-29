"""Inspect every source frame and rank unmodified trim boundaries."""
from pathlib import Path
import json
import cv2
import numpy as np
from PIL import Image, ImageDraw

SOURCE = Path(r'C:\Users\ngoma\Downloads\grok_video_2026-10-25-16-38-50.mp4')
OUT = Path(__file__).resolve().parents[1] / 'artifacts/idle_loop_review'
OUT.mkdir(parents=True, exist_ok=True)
cap = cv2.VideoCapture(str(SOURCE))
fps = cap.get(cv2.CAP_PROP_FPS)
frames = []
while True:
    ok, frame = cap.read()
    if not ok:
        break
    frames.append(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
cap.release()
small = np.array([cv2.resize(f, (88, 160), interpolation=cv2.INTER_AREA) for f in frames], dtype=np.float32) / 255
mask = (small.min(axis=(0, 3)) < .90).astype(np.float32)
mask = cv2.dilate(mask, np.ones((3, 3), np.uint8))
mask[:2] = 0
feature = np.array([cv2.GaussianBlur(f, (3, 3), .7) for f in small])[:, mask > 0]
# Give the face enough weight to reject cuts in the middle of a blink.
face = np.array([cv2.resize(f[90:240, 260:470], (64, 48), interpolation=cv2.INTER_AREA) for f in frames], dtype=np.float32) / 255
face = np.array([cv2.GaussianBlur(f, (3, 3), .7) for f in face]).reshape(len(frames), -1, 3)
feature = np.concatenate([feature, face, face], axis=1)
velocity = np.diff(feature, axis=0)
normal = np.mean(abs(velocity), axis=(1, 2))
rows = []
for a in range(len(frames)-48):
    for b in range(a + 48, len(frames)):
        pose = float(np.mean(abs(feature[a] - feature[b])))
        incoming = velocity[max(0, b - 2):b].mean(axis=0)
        outgoing = velocity[a:min(a + 2, len(velocity))].mean(axis=0)
        speed = float(np.mean(abs(incoming - outgoing)))
        # Matching several neighboring poses penalizes a same-pose/opposite-motion seam.
        context = []
        for k in range(-2, 3):
            if 0 <= a+k < len(frames) and 0 <= b+1+k < len(frames):
                context.append(float(np.mean(abs(feature[a+k] - feature[b+1+k]))))
        neighborhood = float(np.mean(context)) if context else pose
        score = neighborhood + speed * 1.5 + pose * .15
        rows.append(dict(start=a, end=b, frames=b-a+1, duration=(b-a+1)/fps,
                         pose=pose, velocity_mismatch=speed, context=neighborhood, score=score))
rows.sort(key=lambda r: r['score'])
diverse = []
for row in rows:
    if all(abs(row['start']-r['start']) + abs(row['end']-r['end']) > 12 for r in diverse):
        diverse.append(row)
    if len(diverse) == 12:
        break
report = dict(fps=fps, count=len(frames), duration=len(frames)/fps,
              mean_adjacent_difference=float(normal.mean()), per_frame_difference=normal.tolist(),
              best=rows[:30], diverse=diverse)
report['original'] = next(r for r in rows if r['start']==0 and r['end']==144)
report['trim_end_only'] = sorted([r for r in rows if r['start']==0], key=lambda r:r['score'])[:3]
report['trim_start_only'] = sorted([r for r in rows if r['end']==144], key=lambda r:r['score'])[:3]
(OUT/'analysis.json').write_text(json.dumps(report, indent=2))

def sheet(indices, name, columns=10, width=105):
    height = round(width * frames[0].shape[0] / frames[0].shape[1])
    canvas = Image.new('RGB', (columns*width, ((len(indices)+columns-1)//columns)*(height+24)), '#ddd')
    draw = ImageDraw.Draw(canvas)
    for j, i in enumerate(indices):
        x,y = (j%columns)*width, (j//columns)*(height+24)
        canvas.paste(Image.fromarray(frames[i]).resize((width,height)), (x,y))
        draw.text((x+3,y+height+3), f'{i:03}  {i/fps:.3f}s', fill='black')
    canvas.save(OUT/name)
sheet(list(range(len(frames))), 'all_frames.png', 15, 82)
sheet(list(range(0, len(frames), 12)), 'overview.png', 7, 155)
for j, row in enumerate(diverse[:5]):
    a,b = row['start'],row['end']
    sheet(list(range(max(0,b-3),b+1))+list(range(a,a+4)), f'candidate_{j+1}_{a}_{b}.png', 8, 135)
print(json.dumps({k:report[k] for k in ['fps','count','mean_adjacent_difference','diverse']}, indent=2))

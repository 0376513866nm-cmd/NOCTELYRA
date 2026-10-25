"""Extract source frames 110..180, mirror first, remove black, stabilize hips.

Run from the project root. Pixel frames are never blended or synthesized.
"""
from pathlib import Path
import json
import cv2
import numpy as np
from PIL import Image, ImageDraw

SOURCE = Path('assets/gemini_generated_video_d5dcd5f1.mp4')
OUTPUT = Path('assets/sprites/player/player_hop_atlas.png')
ARTIFACTS = Path('artifacts/low_hop')
START, APEX, END = 110, 140, 180
CELL = (256, 360)
ROOT = np.array([128.0, 172.0])
SCALE = 0.267


def foreground(frame):
    rgb = frame.astype(np.float32)
    # Black backdrop, with no black material in the character. Keep the largest
    # connected body to discard the detached Gemini watermark and video noise.
    strength = rgb.max(axis=2)
    alpha = np.clip((strength - 10.0) / 27.0, 0.0, 1.0)
    binary = (alpha > 0.12).astype(np.uint8)
    _, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    label = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    keep = cv2.dilate((labels == label).astype(np.uint8), np.ones((3, 3), np.uint8))
    alpha *= keep
    # Unmatte the original black edge so linear filtering cannot leave a halo.
    rgb = np.clip(rgb / np.maximum(alpha[..., None], 0.15), 0, 255)
    return Image.fromarray(np.dstack((rgb.astype(np.uint8), np.uint8(np.rint(alpha * 255)))), 'RGBA')


def track_hips(frames):
    # Absolute waist landmarks avoid optical-flow drift from the moving cloth.
    # This costume's pale belt is distinct from skin and the black backdrop.
    roots = []
    for frame in frames:
        rgb = frame.astype(np.float32)
        belt = (rgb[:,:,2] > rgb[:,:,0]*0.8) & (rgb[:,:,1] > rgb[:,:,0]*0.8) & (rgb.max(axis=2) > 110)
        belt[:350] = False
        belt[900:] = False
        belt[:,:220] = False
        belt[:,500:] = False
        ys, _ = np.nonzero(belt)
        if len(ys) < 500:
            raise RuntimeError('Could not identify the waist landmark')
        y = float(np.percentile(ys, 8)) + 65.0
        torso = rgb[int(y)-20:int(y)+25,250:460].max(axis=2) > 40
        _, xs = np.nonzero(torso)
        x = float(np.median(xs)) + 250.0
        roots.append([x,y])
    roots = np.array(roots, np.float32)
    # Smooth only the measured translation, never blend character pictures.
    return cv2.GaussianBlur(roots, (1,7), 0, sigmaY=1.2, borderType=cv2.BORDER_REPLICATE)


def main():
    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    cap = cv2.VideoCapture(str(SOURCE))
    fps = cap.get(cv2.CAP_PROP_FPS)
    frames = []
    for index in range(END + 1):
        ok, frame = cap.read()
        if not ok:
            raise RuntimeError(f'Missing video frame {index}')
        if index >= START:
            # Mirror the source before masking, tracking, cropping or resampling.
            frames.append(cv2.cvtColor(cv2.flip(frame, 1), cv2.COLOR_BGR2RGB))
    cap.release()
    roots = track_hips(frames)
    atlas = Image.new('RGBA', (CELL[0]*8, CELL[1]*9))
    cells = []
    metadata = []
    for index, (frame, root) in enumerate(zip(frames, roots)):
        subject = foreground(frame)
        matrix = np.array([[SCALE, 0, ROOT[0]-root[0]*SCALE], [0, SCALE, ROOT[1]-root[1]*SCALE]], np.float32)
        # Transform premultiplied RGBA to keep transparent boundaries clean.
        rgba = np.asarray(subject).astype(np.float32) / 255.0
        rgba[:,:,:3] *= rgba[:,:,3:4]
        warped = cv2.warpAffine(rgba, matrix, CELL, flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT)
        warped[:,:,:3] /= np.maximum(warped[:,:,3:4], 1.0/255.0)
        cell = Image.fromarray(np.uint8(np.rint(np.clip(warped,0,1)*255)), 'RGBA')
        box = cell.getbbox()
        if box is None or box[0] < 2 or box[1] < 2 or box[2] > CELL[0]-2 or box[3] > CELL[1]-2:
            raise RuntimeError(f'Clipped cell at source frame {START+index}: {box}')
        cells.append(cell)
        atlas.paste(cell, (index%8*CELL[0], index//8*CELL[1]))
        metadata.append({'source_frame': START+index, 'hip_source': root.tolist(), 'alpha_bbox':box})
    atlas.save(OUTPUT, optimize=True)
    contact = Image.new('RGBA', (8*160, 9*230), '#252c31')
    draw = ImageDraw.Draw(contact)
    for i, cell in enumerate(cells):
        thumb = cell.resize((151,201), Image.Resampling.LANCZOS)
        at = (i%8*160, i//8*230)
        contact.alpha_composite(thumb, at)
        draw.text((at[0]+5, at[1]+205), str(START+i), fill='white')
    contact.convert('RGB').save(ARTIFACTS/'rebuilt_contact.png')
    # Preview source poses only; Godot supplies the actual jump trajectory.
    preview = []
    for cell in cells:
        bg = Image.new('RGBA', CELL, '#252c31')
        bg.alpha_composite(cell)
        preview.append(bg.convert('RGB'))
    preview[0].save(ARTIFACTS/'rebuilt_poses.gif', save_all=True, append_images=preview[1:], duration=42, loop=0)
    (ARTIFACTS/'extraction.json').write_text(json.dumps({'source':str(SOURCE),'source_fps':fps,'mirrored':True,'first':START,'apex':APEX,'last':END,'scale':SCALE,'target_hip':ROOT.tolist(),'frames':metadata}, indent=2))
    print(f'Saved {len(cells)} mirrored, hip-stabilized frames: {OUTPUT} ({atlas.size})')
    print('First / apex / last hip:', roots[0], roots[APEX-START], roots[-1])


if __name__ == '__main__':
    main()

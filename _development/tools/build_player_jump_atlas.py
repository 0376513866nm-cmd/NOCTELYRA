"""Build a root-motion-free player jump atlas from a chroma-blue video.

The source clip contains a long slow-motion hold.  Frames are deliberately
sampled non-linearly and aligned around the character's pelvis so Godot's
CharacterBody2D remains the only source of world-space jump movement.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import cv2
import numpy as np
from PIL import Image


CELL_WIDTH = 256
CELL_HEIGHT = 340
COLUMNS = 4
ROWS = 10
VIDEO_SCALE = 0.29
TARGET_ROOT = (128, 170)

# (video frame, estimated pelvis/root x, estimated pelvis/root y)
JUMP_FRAMES = [
    (28, 440, 735),
    (34, 425, 700),
    (38, 384, 634),
    (42, 350, 520),
    (46, 336, 464),
    (48, 355, 448),
    (50, 400, 425),
    (52, 400, 410),
]

FALL_FRAMES = [
    (88, 410, 414),
    (94, 410, 418),
    (98, 410, 432),
    (100, 405, 450),
    (102, 390, 480),
    (104, 375, 510),
    (106, 380, 565),
    (108, 380, 620),
]

LAND_FRAMES = [
    (112, 405, 710),
    (116, 410, 700),
    (124, 415, 640),
    (132, 385, 545),
    (136, 385, 535),
    (140, 385, 535),
]


def read_video_frames(path: Path, frame_numbers: set[int]) -> dict[int, np.ndarray]:
    capture = cv2.VideoCapture(str(path))
    if not capture.isOpened():
        raise RuntimeError(f"Cannot open source video: {path}")

    result: dict[int, np.ndarray] = {}
    index = 0
    while True:
        ok, frame = capture.read()
        if not ok:
            break
        if index in frame_numbers:
            result[index] = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        index += 1
    capture.release()

    missing = sorted(frame_numbers.difference(result))
    if missing:
        raise RuntimeError(f"Missing video frames: {missing}")
    return result


def corner_background(frame: np.ndarray) -> np.ndarray:
    corners = np.concatenate(
        (
            frame[:40, :40].reshape(-1, 3),
            frame[:40, -40:].reshape(-1, 3),
            frame[-40:, :40].reshape(-1, 3),
            frame[-40:, -40:].reshape(-1, 3),
        )
    )
    return np.median(corners, axis=0).astype(np.float32)


def remove_blue_background(frame: np.ndarray) -> Image.Image:
    rgb = frame.astype(np.float32)
    background = corner_background(frame)
    distance = np.linalg.norm(rgb - background, axis=2)

    # Keep the soft encoded edge, while discarding blue compression noise.
    alpha = np.clip((distance - 28.0) / 38.0, 0.0, 1.0)
    binary = (alpha > 0.08).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
    if count > 1:
        largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        keep = labels == largest
        keep = cv2.dilate(keep.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
        alpha *= keep

    # Remove the blue matte from partially transparent edge pixels.
    safe_alpha = np.maximum(alpha[..., None], 0.12)
    foreground = (rgb - (1.0 - alpha[..., None]) * background) / safe_alpha
    # Despill the saturated blue left by H.264 chroma subsampling. The source
    # character has no blue materials, so this safely removes the key fringe.
    neutral_limit = foreground[..., 0] * 1.12 + 8.0
    foreground[..., 1] = np.minimum(foreground[..., 1], neutral_limit)
    foreground[..., 2] = np.minimum(foreground[..., 2], neutral_limit)
    foreground = np.clip(foreground, 0.0, 255.0).astype(np.uint8)
    rgba = np.dstack((foreground, np.rint(alpha * 255.0).astype(np.uint8)))
    return Image.fromarray(rgba, "RGBA")


def make_cell(frame: np.ndarray, root_x: int, root_y: int) -> Image.Image:
    subject = remove_blue_background(frame)
    scaled = subject.resize(
        (round(subject.width * VIDEO_SCALE), round(subject.height * VIDEO_SCALE)),
        Image.Resampling.LANCZOS,
    )
    root_scaled = (round(root_x * VIDEO_SCALE), round(root_y * VIDEO_SCALE))
    cell = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT), (0, 0, 0, 0))
    paste_x = TARGET_ROOT[0] - root_scaled[0]
    paste_y = TARGET_ROOT[1] - root_scaled[1]
    cell.alpha_composite(scaled, (paste_x, paste_y))

    # The generated clip faces left; project art faces right at scale.x = 1.
    return cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT)


def old_cell(atlas: Image.Image, index: int) -> Image.Image:
    x = (index % 4) * CELL_WIDTH
    y = (index // 4) * CELL_HEIGHT
    return atlas.crop((x, y, x + CELL_WIDTH, y + CELL_HEIGHT))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("video", type=Path)
    parser.add_argument("legacy_atlas", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    selected = JUMP_FRAMES + FALL_FRAMES + LAND_FRAMES
    frames = read_video_frames(args.video, {item[0] for item in selected})
    legacy = Image.open(args.legacy_atlas).convert("RGBA")
    if legacy.size != (1024, 2040):
        raise RuntimeError(f"Unexpected legacy atlas size: {legacy.size}")

    cells = [make_cell(frames[index], x, y) for index, x, y in selected]
    cells.extend(old_cell(legacy, index) for index in range(8, 16))
    cells.extend(old_cell(legacy, index) for index in range(16, 24))
    while len(cells) < COLUMNS * ROWS:
        cells.append(Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT), (0, 0, 0, 0)))

    atlas = Image.new(
        "RGBA", (COLUMNS * CELL_WIDTH, ROWS * CELL_HEIGHT), (0, 0, 0, 0)
    )
    for index, cell in enumerate(cells):
        atlas.alpha_composite(
            cell, ((index % COLUMNS) * CELL_WIDTH, (index // COLUMNS) * CELL_HEIGHT)
        )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(args.output, optimize=True)
    print(f"Wrote {args.output} ({atlas.width}x{atlas.height}, {len(cells)} cells)")


if __name__ == "__main__":
    main()

"""
Tool tự động tạo NPC từ Video cho NOCTELYRA (Godot 4.3)
Quy trình tự động hóa:
1. Trích xuất khung hình (frame extraction) từ video (hỗ trợ mp4, webm, avi, mov, mkv, gif).
2. Xóa nền đen thông minh (bảo vệ chi tiết đen bên trong cơ thể, khử viền đen/unpremultiply)
   hoặc AI Matting (rembg) / Green screen / White background.
3. Tự động tìm bounding box chung của toàn bộ animation và crop đồng bộ (giữ cố định trọng tâm).
4. Đóng gói Sprite Sheet (Atlas) tối ưu có rãnh bảo vệ chống tràn texture (gutter extrusion).
5. Tự động sinh file Godot 4 SpriteFrames resource (.tres) với animation 'idle'.
6. Tự động sinh file Godot 4 NPC Scene (.tscn) đầy đủ các component tương tác, tên, bóng chân, va chạm.
7. Tự động gọi Godot headless import (nếu có) để nạp tài nguyên ngay lập tức.
8. Hỗ trợ cả giao diện đồ họa (GUI Tkinter) với xem trước ảnh và dòng lệnh (CLI).
"""

import sys
import os
import re
import math
import shutil
import subprocess
import argparse
import threading
from pathlib import Path

# Đảm bảo UTF-8 cho Windows Console
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

import cv2
import numpy as np
from PIL import Image

# ==============================================================================
# 0. TÌM KIẾM TRÌNH THỰC THI GODOT
# ==============================================================================

def find_godot_executable() -> str:
    """Tìm file thực thi Godot trên máy để tự động biên dịch resource."""
    candidates = [
        r"D:\program\Godot\Godot_v4.3-stable_win64_console.exe",
        r"D:\program\Godot\Godot_v4.3-stable_win64.exe",
        r"C:\Program Files\Godot\Godot_v4.3-stable_win64_console.exe",
        "godot"
    ]
    for p in candidates:
        if os.path.isfile(p):
            return p
        if shutil.which(p):
            return p
    return ""


# ==============================================================================
# 1. THUẬT TOÁN XÓA NỀN THÔNG MINH
# ==============================================================================

def remove_black_background(
    image: Image.Image,
    threshold: int = 35,
    feather: float = 0.8,
    decontaminate: bool = True
) -> Image.Image:
    """
    Xóa nền đen thông minh:
    - Tìm các pixel màu đen/tối kết nối trực tiếp với 4 cạnh viền ngoài (boundary-connected).
    - Giữ nguyên 100% các chi tiết màu đen/tối BÊN TRONG nhân vật (tóc đen, mắt, ủng, giáp, dây lưng).
    - Khử viền đen (unpremultiply decontamination) giúp viền nhân vật sắc nét, không bị lem vệt đen.
    """
    rgba = np.array(image.convert("RGBA"))
    rgb = rgba[:, :, :3]
    h, w = rgba.shape[:2]

    # Pixel gần đen: max(R, G, B) <= threshold
    dark_mask = (np.max(rgb, axis=2) <= threshold).astype(np.uint8)

    # Nếu ảnh có sẵn alpha = 0, gộp vào dark_mask
    dark_mask = np.bitwise_or(dark_mask, (rgba[:, :, 3] == 0).astype(np.uint8))

    # Tìm các thành phần liên thông
    num_labels, labels = cv2.connectedComponents(dark_mask, connectivity=8)

    # Lấy nhãn của tất cả pixel nằm ở 4 đường biên (top, bottom, left, right)
    border_labels = set(np.unique(np.concatenate([
        labels[0, :],
        labels[-1, :],
        labels[:, 0],
        labels[:, -1]
    ])))
    border_labels.discard(0)  # 0 là vùng nhân vật sáng

    if not border_labels:
        return Image.fromarray(rgba)

    # Vùng nền đen bên ngoài là các vùng có nhãn thuộc border_labels
    bg_mask = np.isin(labels, list(border_labels)).astype(np.float32)

    # Làm mềm viền nhẹ (feathering) để chống răng cưa
    if feather > 0:
        ksize = int(math.ceil(feather * 3))
        if ksize % 2 == 0:
            ksize += 1
        ksize = max(3, ksize)
        soft_bg = cv2.GaussianBlur(bg_mask, (ksize, ksize), feather)
    else:
        soft_bg = bg_mask

    # Tính toán alpha mới: 0 ở nền, 1 ở nhân vật
    alpha_factor = np.clip(1.0 - soft_bg, 0.0, 1.0)
    current_alpha = rgba[:, :, 3].astype(np.float32) / 255.0
    new_alpha = alpha_factor * current_alpha

    # Khử viền đen (Decontaminate black):
    # Khi viền nhân vật hòa trộn với nền đen, giá trị RGB bị giảm tỷ lệ thuận với alpha.
    # Phục hồi màu gốc: RGB_goc = RGB / alpha
    if decontaminate:
        safe_alpha = np.maximum(new_alpha[:, :, None], 0.05)
        mask_trans = (new_alpha[:, :, None] > 0.05) & (new_alpha[:, :, None] < 0.98)
        clean_rgb = rgb.astype(np.float32) / safe_alpha
        clean_rgb = np.where(mask_trans, clean_rgb, rgb.astype(np.float32))
        clean_rgb = np.clip(clean_rgb, 0, 255).astype(np.uint8)
    else:
        clean_rgb = rgb

    rgba[:, :, :3] = clean_rgb
    rgba[:, :, 3] = np.rint(new_alpha * 255).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0, :3] = 0

    return Image.fromarray(rgba)


def remove_white_background(
    image: Image.Image,
    threshold: int = 225,
    feather: float = 0.55
) -> Image.Image:
    """Xóa nền trắng kết nối biên, bảo vệ mắt và áo trắng bên trong."""
    rgba = np.array(image.convert("RGBA"))
    rgb = rgba[:, :, :3]
    near_white = (np.min(rgb, axis=2) >= threshold).astype(np.uint8)
    candidate = np.bitwise_or(near_white, (rgba[:, :, 3] == 0).astype(np.uint8))
    _, labels = cv2.connectedComponents(candidate, connectivity=8)
    edge_labels = set(np.unique(np.concatenate([
        labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]
    ])))
    edge_labels.discard(0)
    if not edge_labels:
        return Image.fromarray(rgba)
    bg = np.isin(labels, list(edge_labels)).astype(np.float32)
    soft = cv2.GaussianBlur(bg, (3, 3), feather)
    coverage = np.where(bg > 0.5, 0.0, 1.0 - soft)
    safe = np.maximum(coverage[:, :, None], 0.001)
    clean = (rgb.astype(np.float32) - 255 * (1 - coverage[:, :, None])) / safe
    rgba[:, :, :3] = np.clip(clean, 0, 255).astype(np.uint8)
    rgba[:, :, 3] = np.rint(coverage * (rgba[:, :, 3].astype(np.float32) / 255.0) * 255).astype(np.uint8)
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return Image.fromarray(rgba)


def remove_green_screen(
    image: Image.Image,
    threshold: int = 60
) -> Image.Image:
    """Xóa nền xanh lá (Chroma Key Green Screen)."""
    rgba = np.array(image.convert("RGBA"))
    r = rgba[:, :, 0].astype(np.float32)
    g = rgba[:, :, 1].astype(np.float32)
    b = rgba[:, :, 2].astype(np.float32)
    diff = g - np.maximum(r, b)
    is_green = diff > (threshold / 2.0)
    alpha = np.where(is_green, 0, rgba[:, :, 3]).astype(np.uint8)
    rgba[:, :, 3] = alpha
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return Image.fromarray(rgba)


def remove_ai_matting(image: Image.Image, session=None) -> Image.Image:
    """Xóa nền bằng mạng thần kinh nhân tạo AI rembg (U2-Net)."""
    try:
        from rembg import remove
        return remove(image, session=session)
    except Exception as e:
        print(f"[Cảnh báo] Lỗi rembg ({e}), chuyển sang chế độ nền đen...")
        return remove_black_background(image)


# ==============================================================================
# 2. TRÍCH XUẤT FRAME TỪ VIDEO
# ==============================================================================

def extract_frames_from_video(
    video_path: Path,
    target_fps: float = 8.0,
    max_frames: int = 36,
    progress_callback=None
) -> list[Image.Image]:
    """
    Trích xuất danh sách frame PIL Image từ video theo FPS mục tiêu và giới hạn số frame.
    """
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise ValueError(f"Không thể mở tệp video: {video_path}")

    video_fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    total_video_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or 0
    duration_sec = total_video_frames / video_fps if video_fps > 0 else 1.0

    if target_fps <= 0:
        target_fps = 8.0

    desired_total = int(round(duration_sec * target_fps))
    if max_frames > 0 and desired_total > max_frames:
        desired_total = max_frames
    desired_total = max(1, desired_total)

    if total_video_frames > 0:
        sample_indices = np.linspace(0, total_video_frames - 1, desired_total, dtype=int)
    else:
        sample_indices = None

    frames = []
    current_idx = 0
    sampled_set = set(sample_indices) if sample_indices is not None else set()

    while True:
        ret, frame_bgr = cap.read()
        if not ret:
            break

        if sample_indices is not None:
            if current_idx in sampled_set:
                frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
                frames.append(Image.fromarray(frame_rgb))
                if progress_callback:
                    progress_callback(len(frames), desired_total, f"Đang trích xuất frame {len(frames)}/{desired_total}...")
        else:
            if current_idx % max(1, int(round(video_fps / target_fps))) == 0:
                frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
                frames.append(Image.fromarray(frame_rgb))
                if max_frames > 0 and len(frames) >= max_frames:
                    break

        current_idx += 1
        if max_frames > 0 and len(frames) >= max_frames:
            break

    cap.release()

    if not frames:
        raise ValueError("Không trích xuất được khung hình nào từ video.")

    return frames


# ==============================================================================
# 3. ĐÓNG GÓI ATLAS VÀ XUẤT RESOURCE GODOT
# ==============================================================================

def build_npc_assets(
    frames: list[Image.Image],
    output_dir: Path,
    npc_id: str,
    npc_name: str,
    npc_title: str,
    mode: str = "black",
    black_threshold: int = 35,
    target_height: int = 512,
    anim_fps: float = 8.0,
    progress_callback=None
) -> dict:
    """
    Quy trình xử lý hoàn chỉnh:
    1. Xóa phông toàn bộ frames.
    2. Xác định unified bounding box và crop.
    3. Ghép thành sprite atlas với padding/gutter.
    4. Tạo file .tres (SpriteFrames).
    5. Tạo file .tscn (NPC Scene).
    6. Tự động gọi Godot headless import (nếu tìm thấy engine).
    """
    output_dir = Path(output_dir)
    sprites_dir = output_dir / "assets" / "sprites" / "npc" / npc_id / "idle"
    scene_dir = output_dir / "src" / "actors" / "npc"
    sprites_dir.mkdir(parents=True, exist_ok=True)
    scene_dir.mkdir(parents=True, exist_ok=True)

    total = len(frames)
    cleaned_frames = []

    ai_session = None
    if mode == "ai":
        try:
            from rembg import new_session
            ai_session = new_session("u2net")
        except Exception:
            pass

    # Bước 1: Xóa nền
    common_box = None
    for idx, raw_frame in enumerate(frames, 1):
        if progress_callback:
            progress_callback(idx, total * 2, f"Đang xóa phông ({mode}) frame {idx}/{total}...")

        if mode == "black":
            clean = remove_black_background(raw_frame, threshold=black_threshold)
        elif mode == "ai":
            clean = remove_ai_matting(raw_frame, session=ai_session)
        elif mode == "green":
            clean = remove_green_screen(raw_frame, threshold=black_threshold)
        elif mode == "white":
            clean = remove_white_background(raw_frame, threshold=225)
        else:
            clean = raw_frame.convert("RGBA")

        alpha_channel = clean.getchannel("A")
        bounds = alpha_channel.point(lambda a: 255 if a > 16 else 0).getbbox()
        if bounds:
            if common_box is None:
                common_box = bounds
            else:
                common_box = (
                    min(common_box[0], bounds[0]),
                    min(common_box[1], bounds[1]),
                    max(common_box[2], bounds[2]),
                    max(common_box[3], bounds[3])
                )
        cleaned_frames.append(clean)

    if common_box is None:
        raise ValueError("Sau khi xóa nền không còn chi tiết nhân vật. Vui lòng hạ ngưỡng đen hoặc kiểm tra lại video.")

    orig_w, orig_h = cleaned_frames[0].size
    common_box = (
        max(0, common_box[0] - 8),
        max(0, common_box[1] - 8),
        min(orig_w, common_box[2] + 8),
        min(orig_h, common_box[3] + 8)
    )

    box_w = common_box[2] - common_box[0]
    box_h = common_box[3] - common_box[1]

    final_h = target_height if target_height > 0 else box_h
    final_w = max(1, round(box_w * final_h / box_h))

    gutter = 2
    cell_w = final_w + 2 * gutter
    cell_h = final_h + 2 * gutter

    columns = min(8, total, max(1, 8192 // cell_w))
    rows = math.ceil(total / columns)

    atlas_w = columns * cell_w
    atlas_h = rows * cell_h

    atlas_img = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
    regions = []

    # Bước 2: Ghép vào Atlas
    for idx, clean_img in enumerate(cleaned_frames):
        if progress_callback:
            progress_callback(total + idx + 1, total * 2, f"Đang ghép vào Atlas {idx + 1}/{total}...")

        cropped = clean_img.crop(common_box)
        resized = cropped.resize((final_w, final_h), Image.Resampling.LANCZOS)

        col = idx % columns
        row = idx // columns
        x = col * cell_w + gutter
        y = row * cell_h + gutter

        atlas_img.paste(resized, (x, y))

        # Extrude viền 2px để chống tràn viền texture
        atlas_img.paste(resized.crop((0, 0, 1, final_h)).resize((gutter, final_h)), (x - gutter, y))
        atlas_img.paste(resized.crop((final_w - 1, 0, final_w, final_h)).resize((gutter, final_h)), (x + final_w, y))
        atlas_img.paste(resized.crop((0, 0, final_w, 1)).resize((final_w, gutter)), (x, y - gutter))
        atlas_img.paste(resized.crop((0, final_h - 1, final_w, final_h)).resize((final_w, gutter)), (x, y + final_h))

        regions.append({
            "index": idx + 1,
            "region": [x, y, final_w, final_h]
        })

    atlas_filename = f"npc_{npc_id}_idle_atlas.png"
    atlas_path = sprites_dir / atlas_filename
    atlas_img.save(atlas_path, "PNG")

    # Bước 3: Tạo file SpriteFrames .tres
    tres_filename = f"npc_{npc_id}_idle.tres"
    tres_path = sprites_dir / tres_filename
    godot_atlas_res_path = f"res://assets/sprites/npc/{npc_id}/idle/{atlas_filename}"

    tres_content = [
        f'[gd_resource type="SpriteFrames" load_steps={total + 2} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{godot_atlas_res_path}" id="1"]',
        ""
    ]

    for reg in regions:
        r = reg["region"]
        tres_content.append(f'[sub_resource type="AtlasTexture" id="Frame_{reg["index"]}"]')
        tres_content.append('atlas = ExtResource("1")')
        tres_content.append(f'region = Rect2({r[0]}, {r[1]}, {r[2]}, {r[3]})')
        tres_content.append('filter_clip = true')
        tres_content.append("")

    tres_content.append('[resource]')
    tres_content.append('animations = [{')
    tres_content.append('"frames": [')
    frames_json_list = []
    for reg in regions:
        frames_json_list.append(f'{{"duration": 1.0, "texture": SubResource("Frame_{reg["index"]}")}}')
    tres_content.append(",\n".join(frames_json_list))
    tres_content.append('],')
    tres_content.append('"loop": true,')
    tres_content.append('"name": &"idle",')
    tres_content.append(f'"speed": {float(anim_fps)}')
    tres_content.append('}]')

    with open(tres_path, "w", encoding="utf-8") as f:
        f.write("\n".join(tres_content) + "\n")

    # Bước 4: Tạo file Scene .tscn cho NPC
    scene_filename = f"npc_{npc_id}.tscn"
    scene_path = scene_dir / scene_filename
    godot_tres_res_path = f"res://assets/sprites/npc/{npc_id}/idle/{tres_filename}"

    # Chuẩn kích thước game NOCTELYRA: nhân vật cao ~105-115px
    standard_in_game_height = 105.0
    scale_factor = round(standard_in_game_height / float(final_h), 5)
    in_game_width = round(final_w * scale_factor, 1)

    capsule_radius = max(14.0, round(in_game_width * 0.35, 1))
    capsule_height = round(standard_in_game_height * 0.95, 1)
    center_y = -round(standard_in_game_height / 2.0, 1)
    nametag_y = -round(standard_in_game_height + 18.0, 1)
    prompt_y = -round(standard_in_game_height + 35.0, 1)

    tscn_content = f"""[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://src/actors/npc/npc.gd" id="1_npc"]
[ext_resource type="Script" path="res://src/interaction/interaction_component.gd" id="2_interact"]
[ext_resource type="SpriteFrames" path="{godot_tres_res_path}" id="3_spriteframes"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_npc"]
radius = {capsule_radius}
height = {capsule_height}

[sub_resource type="Animation" id="Animation_idle"]
resource_name = "idle"
length = 1.2
loop_mode = 1
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("VisualRoot:position")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {{
"times": PackedFloat32Array(0, 0.3, 0.6, 0.9),
"transitions": PackedFloat32Array(1, 1, 1, 1),
"update": 1,
"values": [Vector2(0, 0), Vector2(0, -1.5), Vector2(0, 0), Vector2(0, -0.75)]
}}

[sub_resource type="AnimationLibrary" id="AnimationLibrary_npc"]
_data = {{
"idle": SubResource("Animation_idle")
}}

[sub_resource type="CircleShape2D" id="CircleShape2D_detect"]
radius = 85.0

[node name="NPC" type="CharacterBody2D"]
collision_layer = 0
script = ExtResource("1_npc")
npc_name = "{npc_name}"
title = "{npc_title}"

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, {center_y})
shape = SubResource("CapsuleShape2D_npc")

[node name="GroundShadow" type="Polygon2D" parent="."]
z_index = -2
color = Color(0, 0, 0, 0.42)
polygon = PackedVector2Array(-22, -2, -16, -5, 0, -6, 16, -5, 22, -2, 22, 2, 16, 5, 0, 6, -16, 5, -22, 2)

[node name="VisualRoot" type="Node2D" parent="."]
position = Vector2(0, 0)

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {{
"": SubResource("AnimationLibrary_npc")
}}
autoplay = "idle"

[node name="NameTag" type="Label" parent="."]
offset_left = -60.0
offset_top = {nametag_y}
offset_right = 60.0
offset_bottom = {nametag_y + 23.0}
text = "{npc_name}"
horizontal_alignment = 1

[node name="PromptLabel" type="Label" parent="."]
visible = false
offset_left = -70.0
offset_top = {prompt_y}
offset_right = 70.0
offset_bottom = {prompt_y + 23.0}
text = "[E] Nói chuyện"
horizontal_alignment = 1

[node name="InteractionComponent" type="Area2D" parent="."]
script = ExtResource("2_interact")

[node name="CollisionShape2D" type="CollisionShape2D" parent="InteractionComponent"]
position = Vector2(0, {center_y})
shape = SubResource("CircleShape2D_detect")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
z_index = -2
position = Vector2(0, {center_y})
scale = Vector2({scale_factor}, {scale_factor})
sprite_frames = ExtResource("3_spriteframes")
animation = &"idle"
autoplay = "idle"
"""

    with open(scene_path, "w", encoding="utf-8") as f:
        f.write(tscn_content)

    # Bước 5: Tự động chạy Godot import nếu tìm thấy engine
    godot_bin = find_godot_executable()
    if godot_bin and (output_dir / "project.godot").is_file():
        try:
            if progress_callback:
                progress_callback(total * 2, total * 2, "Đang gọi Godot import tài nguyên...")
            subprocess.run(
                [godot_bin, "--headless", "--editor", "--quit", "--path", str(output_dir)],
                capture_output=True,
                timeout=15
            )
        except Exception:
            pass

    return {
        "npc_id": npc_id,
        "npc_name": npc_name,
        "atlas_path": atlas_path,
        "tres_path": tres_path,
        "scene_path": scene_path,
        "frames_count": total,
        "atlas_size": (atlas_w, atlas_h),
        "frame_size": (final_w, final_h),
        "scale_factor": scale_factor,
        "sample_frame": cleaned_frames[0].crop(common_box)
    }


# ==============================================================================
# 4. GIAO DIỆN ĐỒ HỌA (GUI TKINTER)
# ==============================================================================

def launch_gui(default_project_dir: str = None):
    import tkinter as tk
    from tkinter import ttk, filedialog, messagebox
    from PIL import ImageTk

    root = tk.Tk()
    root.title("NOCTELYRA - Tool Tự Động Tạo NPC Từ Video")
    root.geometry("820x720")
    root.minsize(760, 640)

    # Variables
    video_path_var = tk.StringVar()
    npc_id_var = tk.StringVar(value="luna")
    npc_name_var = tk.StringVar(value="Luna")
    npc_title_var = tk.StringVar(value="Phù Thủy Ánh Trăng")
    project_dir_var = tk.StringVar(value=default_project_dir or os.getcwd())
    mode_var = tk.StringVar(value="black")
    threshold_var = tk.IntVar(value=35)
    fps_var = tk.DoubleVar(value=8.0)
    max_frames_var = tk.IntVar(value=32)
    status_var = tk.StringVar(value="Sẵn sàng. Hãy chọn file Video để bắt đầu.")
    progress_val = tk.DoubleVar(value=0)
    is_processing = [False]

    # Main container
    main_frame = ttk.Frame(root, padding="15")
    main_frame.pack(fill=tk.BOTH, expand=True)

    header = ttk.Label(
        main_frame,
        text="🎬 CHUYỂN ĐỔI VIDEO THÀNH NPC HOÀN CHỈNH CHO NOCTELYRA",
        font=("Segoe UI", 12, "bold")
    )
    header.pack(anchor=tk.W, pady=(0, 10))

    # 1. Chọn Video
    video_group = ttk.LabelFrame(main_frame, text=" 1. Tệp Video Đầu Vào ", padding="8")
    video_group.pack(fill=tk.X, pady=4)

    v_box = ttk.Frame(video_group)
    v_box.pack(fill=tk.X)
    v_entry = ttk.Entry(v_box, textvariable=video_path_var, font=("Segoe UI", 9))
    v_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))

    def browse_video():
        fn = filedialog.askopenfilename(
            title="Chọn Video Nhân Vật",
            filetypes=[
                ("Video Files", "*.mp4 *.webm *.avi *.mov *.mkv *.gif"),
                ("Tất cả tệp", "*.*")
            ]
        )
        if fn:
            video_path_var.set(fn)
            stem = re.sub(r'[^a-zA-Z0-9_]', '_', Path(fn).stem.lower())
            if stem and npc_id_var.get() in ["luna", ""]:
                npc_id_var.set(stem)
                npc_name_var.set(stem.capitalize())

    ttk.Button(v_box, text="Chọn Video...", command=browse_video).pack(side=tk.RIGHT)

    # 2. Thông tin NPC
    info_group = ttk.LabelFrame(main_frame, text=" 2. Thông Tin NPC ", padding="8")
    info_group.pack(fill=tk.X, pady=4)

    i_grid = ttk.Frame(info_group)
    i_grid.pack(fill=tk.X)

    ttk.Label(i_grid, text="Mã ID (thư mục/file):").grid(row=0, column=0, sticky=tk.W, pady=3)
    ttk.Entry(i_grid, textvariable=npc_id_var, width=18).grid(row=0, column=1, sticky=tk.W, padx=5, pady=3)

    ttk.Label(i_grid, text="Tên hiển thị:").grid(row=0, column=2, sticky=tk.W, pady=3, padx=(15, 0))
    ttk.Entry(i_grid, textvariable=npc_name_var, width=22).grid(row=0, column=3, sticky=tk.W, padx=5, pady=3)

    ttk.Label(i_grid, text="Danh hiệu (Title):").grid(row=1, column=0, sticky=tk.W, pady=3)
    ttk.Entry(i_grid, textvariable=npc_title_var, width=30).grid(row=1, column=1, columnspan=3, sticky=tk.W, padx=5, pady=3)

    # 3. Tùy chọn tách nền
    opt_group = ttk.LabelFrame(main_frame, text=" 3. Cài Đặt Tách Nền & Hoạt Họa ", padding="8")
    opt_group.pack(fill=tk.X, pady=4)

    o_grid = ttk.Frame(opt_group)
    o_grid.pack(fill=tk.X)

    ttk.Label(o_grid, text="Chế độ tách nền:").grid(row=0, column=0, sticky=tk.W, pady=3)
    mode_combo = ttk.Combobox(
        o_grid,
        textvariable=mode_var,
        values=["black", "ai", "green", "white", "keep"],
        state="readonly",
        width=12
    )
    mode_combo.grid(row=0, column=1, sticky=tk.W, padx=5, pady=3)
    ttk.Label(o_grid, text="(black: Nền đen thông minh + khử viền | ai: rembg U2-Net | green: Phông xanh)", font=("Segoe UI", 8), foreground="#555").grid(row=0, column=2, columnspan=2, sticky=tk.W, padx=5)

    ttk.Label(o_grid, text="Ngưỡng đen (0-100):").grid(row=1, column=0, sticky=tk.W, pady=3)
    ttk.Spinbox(o_grid, from_=5, to=100, increment=5, textvariable=threshold_var, width=8).grid(row=1, column=1, sticky=tk.W, padx=5, pady=3)

    ttk.Label(o_grid, text="FPS xuất:").grid(row=1, column=2, sticky=tk.W, padx=(15, 0), pady=3)
    ttk.Spinbox(o_grid, from_=4, to=30, increment=1, textvariable=fps_var, width=8).grid(row=1, column=3, sticky=tk.W, padx=5, pady=3)

    ttk.Label(o_grid, text="Số frame tối đa:").grid(row=2, column=0, sticky=tk.W, pady=3)
    ttk.Spinbox(o_grid, from_=8, to=120, increment=4, textvariable=max_frames_var, width=8).grid(row=2, column=1, sticky=tk.W, padx=5, pady=3)

    # 4. Thư mục dự án
    proj_group = ttk.LabelFrame(main_frame, text=" 4. Thư Mục Dự Án Game (NOCTELYRA) ", padding="8")
    proj_group.pack(fill=tk.X, pady=4)

    p_box = ttk.Frame(proj_group)
    p_box.pack(fill=tk.X)
    p_entry = ttk.Entry(p_box, textvariable=project_dir_var, font=("Segoe UI", 9))
    p_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))

    def browse_proj():
        d = filedialog.askdirectory(title="Chọn thư mục gốc dự án NOCTELYRA")
        if d:
            project_dir_var.set(d)

    ttk.Button(p_box, text="Chọn Thư Mục...", command=browse_proj).pack(side=tk.RIGHT)

    # 5. Preview & Tiến trình
    action_frame = ttk.Frame(main_frame, padding="5")
    action_frame.pack(fill=tk.BOTH, expand=True, pady=6)

    p_bar = ttk.Progressbar(action_frame, variable=progress_val, maximum=100)
    p_bar.pack(fill=tk.X, pady=(0, 4))

    status_lbl = ttk.Label(action_frame, textvariable=status_var, font=("Segoe UI", 9, "italic"))
    status_lbl.pack(anchor=tk.W, pady=(0, 6))

    btn_box = ttk.Frame(action_frame)
    btn_box.pack(fill=tk.X, pady=4)

    run_btn = ttk.Button(btn_box, text="🚀 BẮT ĐẦU TẠO NPC", style="Accent.TButton")
    run_btn.pack(side=tk.LEFT, padx=(0, 10), ipadx=10, ipady=4)

    open_scene_btn = ttk.Button(btn_box, text="📂 Mở Thư Mục Scene", state=tk.DISABLED)
    open_scene_btn.pack(side=tk.LEFT, padx=(0, 5))

    open_atlas_btn = ttk.Button(btn_box, text="🖼️ Mở Thư Mục Atlas", state=tk.DISABLED)
    open_atlas_btn.pack(side=tk.LEFT)

    last_scene_dir = [""]
    last_atlas_dir = [""]

    def open_scene_folder():
        if last_scene_dir[0] and os.path.exists(last_scene_dir[0]):
            os.startfile(last_scene_dir[0])

    def open_atlas_folder():
        if last_atlas_dir[0] and os.path.exists(last_atlas_dir[0]):
            os.startfile(last_atlas_dir[0])

    open_scene_btn.config(command=open_scene_folder)
    open_atlas_btn.config(command=open_atlas_folder)

    # Preview box
    preview_box = ttk.LabelFrame(action_frame, text=" Xem Trước Kết Quả ", padding="6")
    preview_box.pack(fill=tk.BOTH, expand=True, pady=4)

    preview_lbl = ttk.Label(preview_box, text="Chưa có bản xem trước. Hãy chọn video và nhấn nút Tạo NPC.")
    preview_lbl.pack(anchor=tk.CENTER, pady=10)
    preview_img_ref = [None]

    def update_preview(pil_img: Image.Image):
        # Resize thumbnail
        thumb = pil_img.copy()
        thumb.thumbnail((180, 180), Image.Resampling.LANCZOS)
        # Background ô cờ caro
        bg = Image.new("RGBA", thumb.size, (220, 220, 220, 255))
        # Ghép
        bg.paste(thumb, (0, 0), thumb)
        tk_img = ImageTk.PhotoImage(bg)
        preview_img_ref[0] = tk_img
        preview_lbl.config(image=tk_img, text="")

    def worker():
        try:
            v_path = Path(video_path_var.get().strip())
            if not v_path.is_file():
                raise ValueError("Vui lòng chọn một tệp video hợp lệ!")

            p_dir = Path(project_dir_var.get().strip())
            if not p_dir.is_dir():
                raise ValueError("Thư mục dự án không hợp lệ!")

            n_id = re.sub(r'[^a-zA-Z0-9_]', '_', npc_id_var.get().strip().lower())
            if not n_id:
                raise ValueError("Vui lòng nhập Mã ID cho NPC (chữ thường không dấu)!")

            n_name = npc_name_var.get().strip() or n_id.capitalize()
            n_title = npc_title_var.get().strip() or "Nhân Vật"

            def on_progress(cur, total, msg):
                pct = (cur / total) * 100.0 if total > 0 else 0
                progress_val.set(pct)
                status_var.set(msg)

            status_var.set("Đang phân tích video...")
            frames = extract_frames_from_video(
                v_path,
                target_fps=fps_var.get(),
                max_frames=max_frames_var.get(),
                progress_callback=lambda c, t, m: on_progress(c, t * 2, m)
            )

            res = build_npc_assets(
                frames=frames,
                output_dir=p_dir,
                npc_id=n_id,
                npc_name=n_name,
                npc_title=n_title,
                mode=mode_var.get(),
                black_threshold=threshold_var.get(),
                target_height=512,
                anim_fps=fps_var.get(),
                progress_callback=on_progress
            )

            last_scene_dir[0] = str(res["scene_path"].parent)
            last_atlas_dir[0] = str(res["atlas_path"].parent)

            progress_val.set(100)
            status_var.set(f"✅ Thành công! Đã tạo NPC '{n_name}' ({res['frames_count']} frames).")
            open_scene_btn.config(state=tk.NORMAL)
            open_atlas_btn.config(state=tk.NORMAL)

            if "sample_frame" in res and res["sample_frame"] is not None:
                update_preview(res["sample_frame"])

            messagebox.showinfo(
                "Tạo NPC Thành Công!",
                f"Đã tạo hoàn tất các tệp cho NPC '{n_name}':\n\n"
                f"1. Sprite Atlas : assets/sprites/npc/{n_id}/idle/{res['atlas_path'].name}\n"
                f"2. SpriteFrames : assets/sprites/npc/{n_id}/idle/{res['tres_path'].name}\n"
                f"3. NPC Scene    : src/actors/npc/{res['scene_path'].name}\n\n"
                f"Tất cả tệp đã được tạo khớp 100% chuẩn Godot 4.3 của NOCTELYRA!\n"
                f"Bây giờ bạn mở Godot Editor và kéo file Scene vào bản đồ."
            )
        except Exception as e:
            status_var.set(f"❌ Lỗi: {e}")
            messagebox.showerror("Đã xảy ra lỗi", str(e))
        finally:
            is_processing[0] = False
            run_btn.config(state=tk.NORMAL)

    def start_process():
        if is_processing[0]:
            return
        is_processing[0] = True
        run_btn.config(state=tk.DISABLED)
        open_scene_btn.config(state=tk.DISABLED)
        open_atlas_btn.config(state=tk.DISABLED)
        threading.Thread(target=worker, daemon=True).start()

    run_btn.config(command=start_process)

    root.mainloop()


# ==============================================================================
# 5. DÒNG LỆNH (CLI)
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(description="Tool tự động tạo NPC từ Video cho NOCTELYRA (Godot 4.3)")
    parser.add_argument("--video", "-v", help="Đường dẫn tệp video đầu vào")
    parser.add_argument("--id", help="Mã ID NPC (viết thường, vd: luna, merchant_kailen)")
    parser.add_argument("--name", "-n", help="Tên hiển thị NPC (vd: 'Luna', 'Trưởng Làng')")
    parser.add_argument("--title", "-t", default="Nhân Vật", help="Danh hiệu NPC")
    parser.add_argument("--project", "-p", default=None, help="Thư mục gốc của project NOCTELYRA")
    parser.add_argument("--mode", "-m", choices=["black", "ai", "green", "white", "keep"], default="black", help="Chế độ xóa nền")
    parser.add_argument("--threshold", type=int, default=35, help="Ngưỡng đen (0-100)")
    parser.add_argument("--fps", type=float, default=8.0, help="FPS của hoạt ảnh")
    parser.add_argument("--max-frames", type=int, default=32, help="Số frame tối đa")
    parser.add_argument("--height", type=int, default=512, help="Chiều cao frame chuẩn hóa trong atlas (pixel)")
    parser.add_argument("--cli", action="store_true", help="Chạy chế độ dòng lệnh không mở GUI")

    args = parser.parse_args()

    default_proj = args.project
    if not default_proj:
        candidate = Path(__file__).resolve().parent
        while candidate != candidate.parent:
            if (candidate / "project.godot").is_file():
                default_proj = str(candidate)
                break
            candidate = candidate.parent
    if not default_proj:
        default_proj = os.getcwd()

    if args.cli or (args.video and args.id):
        if not args.video:
            print("Lỗi: Cần cung cấp --video khi chạy CLI.", file=sys.stderr)
            sys.exit(1)
        v_path = Path(args.video)
        if not v_path.is_file():
            print(f"Lỗi: Không tìm thấy file video {v_path}", file=sys.stderr)
            sys.exit(1)

        n_id = args.id or v_path.stem.lower()
        n_name = args.name or n_id.capitalize()

        print(f"--- ĐANG XỬ LÝ VIDEO -> NPC: {n_name} (ID: {n_id}) ---")
        print(f"Video: {v_path}")
        print(f"Project: {default_proj}")
        print(f"Chế độ xóa nền: {args.mode} (ngưỡng: {args.threshold})")

        frames = extract_frames_from_video(
            v_path,
            target_fps=args.fps,
            max_frames=args.max_frames,
            progress_callback=lambda c, t, m: print(f"[{c}/{t}] {m}")
        )

        res = build_npc_assets(
            frames=frames,
            output_dir=Path(default_proj),
            npc_id=n_id,
            npc_name=n_name,
            npc_title=args.title,
            mode=args.mode,
            black_threshold=args.threshold,
            target_height=args.height,
            anim_fps=args.fps,
            progress_callback=lambda c, t, m: print(f"[{c}/{t}] {m}")
        )

        print("\n=== HOÀN TẤT XUẤT NPC ===")
        print(f"1. Sprite Atlas : {res['atlas_path']}")
        print(f"2. SpriteFrames : {res['tres_path']}")
        print(f"3. NPC Scene    : {res['scene_path']}")
        print(f"Số frames: {res['frames_count']}, Kích thước Atlas: {res['atlas_size']}")
    else:
        launch_gui(default_project_dir=default_proj)


if __name__ == "__main__":
    main()

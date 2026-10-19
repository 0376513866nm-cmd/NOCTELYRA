# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M0)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục dự án

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ thư mục cache .godot/
├── README.md                       # Tài liệu hướng dẫn
├── project.godot                   # File cấu hình engine Godot 4.3 (1280x720, stretch mode)
├── run_game.bat                    # Script 1-Click chạy game test ngay lập tức
├── open_editor.bat                 # Script 1-Click mở Godot Editor
├── export_code_for_ai.bat          # Script gom toàn bộ code thành 1 file text để gửi AI review
│
├── assets\
│   └── sprites\
│       └── player\
│           ├── player_idle_strip.png         # Sprite Idle (48 frames)
│           ├── player_idle_strip.png.import  # File import của Godot
│           ├── player_run_strip.png          # Sprite Run (14 frames)
│           └── player_run_strip.png.import   # File import của Godot
│
└── src\
    ├── actors\
    │   └── player\
    │       ├── player.gd                    # State Machine: IDLE, RUN, JUMP, FALL, DASH
    │       ├── player.tscn                  # Scene Player (CharacterBody2D, Capsule, AnimPlayer)
    │       └── player_movement_data.gd      # Resource thông số di chuyển, nhảy, dash
    └── world\
        ├── test_level.gd                    # Logic Pause/Resume và HUD hiển thị State
        └── test_level.tscn                  # Map test: mặt đất 3400px, 4 bục platform, Camera2D
```

---

## 2. Các phím điều khiển (Controls)

| Phím | Chức năng | Ghi chú |
| :--- | :--- | :--- |
| **A / D** hoặc **Mũi tên** | Di chuyển Trái / Phải | Có gia tốc mượt, tự động quay mặt nhân vật |
| **Space** | Nhảy / Nhảy đôi | Nhấn lần 1 nhảy, nhấn lần 2 trên không để Double Jump |
| **Shift** | Lướt nhanh (Dash) | Lướt ngang tốc độ cao (0.2s), có thể Dash trên không |
| **S + Space** | Rơi xuyên bục | Xuyên qua các bục lơ lửng (One-way platform) |
| **Esc** | Pause / Resume | Tạm dừng hoặc tiếp tục game (bằng phím hoặc nút Resume) |

---

## 3. Các cải tiến & sửa lỗi theo Review Milestone M0

1. **State Machine (`player.gd`)**:
   - Khắc phục triệt để lỗi ghi đè state: Khi ấn di chuyển + nhảy cùng lúc, state `JUMP` được ưu tiên và thực thi trọn vẹn, không bị `RUN` ghi đè trong cùng 1 frame.
   - Hỗ trợ **Air Dash**: Có thể bấm Shift để lướt khi đang ở trạng thái `JUMP` hoặc `FALL`.
   - Trong thời gian lướt (0.2s), trạng thái `DASH` được giữ ổn định và cooldown (0.8s) được đếm ngược độc lập.
   - Tiếp đất khôi phục lượt nhảy đôi chính xác.

2. **Hệ thống Pause/Resume (`test_level.gd`)**:
   - `test_level.gd` được thiết lập `process_mode = PROCESS_MODE_ALWAYS`.
   - Phím `Esc` lần đầu mở menu Pause, phím `Esc` lần 2 đóng menu và tiếp tục game.
   - Nút **Resume** hoạt động hoàn hảo, sau khi tiếp tục không bị kẹt điều khiển hay trôi nhân vật.

3. **Sprite & Animation**:
   - Sử dụng AnimationPlayer đồng bộ hóa dải frame Idle và Run.
   - Có cơ chế visual placeholder cho Jump, Fall, Dash bằng cách bắt frame chuyển động đặc trưng, đảm bảo khi thay thế spritesheet mới không cần sửa logic gameplay.

---

## 4. Cách chạy và kiểm thử dự án

- **Cách 1 (Nhanh nhất):** Click đúp vào file `run_game.bat` nằm ngay trong thư mục dự án.
- **Cách 2:** Mở bằng Godot 4 Editor bằng cách click đúp vào file `open_editor.bat`.

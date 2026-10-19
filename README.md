# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M0)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục dự án

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ thư mục cache .godot/
├── README.md                       # Tài liệu hướng dẫn
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
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
    ├── ui\
    │   └── pause_controller.gd              # Node quản lý Pause độc lập (PROCESS_MODE_ALWAYS)
    └── world\
        ├── test_level.gd                    # Gameplay test level (PROCESS_MODE_PAUSABLE)
        └── test_level.tscn                  # Map test: mặt đất 3400px, 4 bục platform, Camera2D
```

---

## 2. Các phím điều khiển (Controls)

| Phím | Chức năng | Ghi chú |
| :--- | :--- | :--- |
| **A / D** hoặc **Mũi tên** | Di chuyển Trái / Phải | Có gia tốc mượt, tự động quay mặt nhân vật |
| **Space** | Nhảy / Nhảy đôi | Nhấn lần 1 nhảy, nhấn lần 2 trên không để Double Jump |
| **Shift** | Lướt nhanh (Dash) | Lướt ngang tốc độ cao (0.2s), có thể Air-Dash trên không |
| **Esc** | Pause / Resume | Tạm dừng hoặc tiếp tục game (bằng phím hoặc nút Resume) |

---

## 3. Kiến trúc hệ thống Milestone M0

1. **State Machine (`player.gd`)**:
   - Khi ấn di chuyển + nhảy cùng lúc: State `JUMP` được ưu tiên và thực thi trọn vẹn, không bị `RUN` ghi đè trong cùng 1 frame.
   - Hỗ trợ **Air Dash**: Có thể bấm Shift để lướt khi đang ở trạng thái `JUMP` hoặc `FALL`.
   - Trong thời gian lướt (0.2s), trạng thái `DASH` được giữ ổn định và cooldown (0.8s) được đếm ngược độc lập.
   - Tiếp đất khôi phục lượt nhảy đôi chính xác.

2. **Kiến trúc Pause / Resume chuẩn Godot**:
   - `TestLevel` (Scene gốc) và các node gameplay con hoạt động ở chế độ `PROCESS_MODE_PAUSABLE`.
   - `PauseController` được tách thành node riêng chạy độc lập ở chế độ `PROCESS_MODE_ALWAYS` để bắt sự kiện phím `Esc`.
   - Menu Pause (`PauseMenu`) hoạt động ở chế độ `PROCESS_MODE_WHEN_PAUSED`.
   - **Xác minh dừng tuyệt đối:** Khi game ở trạng thái Pause, toàn bộ chuyển động nhân vật, animation và timer của Player hoàn toàn dừng hẳn, không bị trôi thời gian hay trôi vận tốc.
   - Phím `Esc` lần đầu Pause, `Esc` lần hai Resume. Nút **Resume** hoạt động hoàn hảo mà không làm kẹt điều khiển.

3. **Sprite & Assets**:
   - Đầy đủ file `icon.svg` hợp lệ trong `project.godot`.
   - Sử dụng AnimationPlayer với dải frame Idle và Run; kèm cơ chế visual placeholder cho Jump, Fall, Dash đảm bảo sau này thay sprite mới từ video mà không cần viết lại logic code.

---

## 4. Cách chạy và kiểm thử dự án

- **Cách 1 (Nhanh nhất):** Click đúp vào file `run_game.bat` nằm ngay trong thư mục dự án.
- **Cách 2:** Mở bằng Godot 4 Editor bằng cách click đúp vào file `open_editor.bat`.

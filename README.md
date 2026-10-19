# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M1 Combat)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục dự án

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ thư mục cache .godot/
├── README.md                       # Tài liệu hướng dẫn & kiến trúc M1
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Cấu hình engine Godot 4.3 (1280x720, input maps: J, K)
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
    │   ├── player\
    │   │   ├── player.gd                    # Player Controller: State Machine, Jump, Dash, Combat
    │   │   ├── player.tscn                  # Player Scene (HealthComp, CombatComp, Hurtbox, Hitbox)
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy, dash
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI State Machine (IDLE, CHASE, ATTACK, HURT, DEAD)
    │       └── enemy.tscn                   # Enemy Scene (HealthComp, Hurtbox, AttackHitbox, HPBar)
    ├── combat\
    │   ├── damage_info.gd                   # Struct dữ liệu sát thương & lực đẩy lùi (Knockback)
    │   ├── health_component.gd              # Quản lý HP, MP, hồi mana & thời gian miễn nhiễm (I-frames)
    │   ├── hurtbox.gd                       # Vùng nhận đòn chuyển tiếp tới HealthComponent
    │   ├── hitbox.gd                        # Vùng gây sát thương chém cận chiến / đòn cắn
    │   ├── combat_component.gd              # Quản lý cooldown chém thường và bắn ma pháp
    │   ├── magic_projectile.gd              # Script đạn phép ma pháp bay thẳng gây nổ
    │   └── magic_projectile.tscn            # Scene đạn phép ma pháp với hiệu ứng ánh sáng core
    ├── ui\
    │   └── pause_controller.gd              # Quản lý Pause/Resume độc lập (PROCESS_MODE_ALWAYS)
    └── world\
        ├── test_level.gd                    # Gameplay test level kết nối thanh HP/MP lên HUD
        └── test_level.tscn                  # Level test tích hợp Player, TestEnemy, Camera2D, HUD
```

---

## 2. Các phím điều khiển (Controls)

| Phím | Chức năng | Cơ chế hoạt động |
| :--- | :--- | :--- |
| **A / D** hoặc **Mũi tên** | Di chuyển Trái / Phải | Gia tốc mượt, tự động quay mặt nhân vật |
| **Space** | Nhảy / Nhảy đôi | Nhấn lần 1 nhảy, nhấn lần 2 trên không để Double Jump |
| **Shift** | Lướt nhanh (Dash) | Lướt ngang tốc độ cao (0.2s), có thể Air-Dash trên không |
| **J** | **Đánh thường (Melee)** | Chém cận chiến (25 DMG), có cooldown (0.35s) và đẩy lùi quái |
| **K** | **Ma pháp (Magic Spell)** | Bắn quả cầu ma pháp (30 DMG), tiêu hao 15 MP, có cooldown |
| **Esc** | Pause / Resume | Tạm dừng hoặc tiếp tục game (bằng phím Esc hoặc nút Resume) |

---

## 3. Kiến trúc Hệ thống Chiến đấu M1 (Combat Modules)

1. **`HealthComponent` & I-frames**:
   - Quản lý thanh máu `current_health` và thanh năng lượng `current_mana`.
   - Có cơ chế tự động hồi phục Mana dần theo thời gian (`mana_regen_rate = 6.0 MP/s`).
   - Hỗ trợ thời gian miễn nhiễm (`invulnerability_duration`): Sau khi Player trúng đòn, nhân vật chuyển sang trạng thái nhấp nháy đỏ và miễn nhiễm sát thương trong 0.8s, chống bị mất máu dồn dập trong 1 đòn đánh.
2. **`Hitbox` & `Hurtbox` tái sử dụng**:
   - Tách rời theo chuẩn Godot Component Pattern: Dùng chung cho cả Player, Quái vật và Đạn ma pháp.
   - Cơ chế `_already_hit_nodes` ngăn ngừa việc một nhát chém gây sát thương nhiều lần cho cùng 1 mục tiêu.
   - Tính toán vector đẩy lùi Knockback chính xác dựa trên vị trí tương đối giữa người ra đòn và mục tiêu.
3. **`Enemy AI` 5 Trạng thái (FSM)**:
   - **IDLE:** Đứng quan sát, tìm mục tiêu Player trong tầm phát hiện (`detection_range = 380px`).
   - **CHASE:** Di chuyển đuổi theo Player khi phát hiện, tự quay mặt về hướng Player.
   - **ATTACK:** Kích hoạt đòn cắn cận chiến khi tới gần (`attack_range = 55px`), chớp màu vàng và kích hoạt Hitbox.
   - **HURT:** Bị khựng nhẹ và giật lùi về phía sau (Knockback) khi trúng kiếm hoặc trúng đạn ma pháp.
   - **DEAD:** Khi HP = 0, quái chuyển sang trạng thái DEAD, tắt toàn bộ va chạm, mờ dần trong 1 giây rồi biến mất hoàn toàn.
4. **Giao diện HUD**:
   - Thanh HP (Màu đỏ/xanh lá) và thanh MP (Màu xanh dương) trên góc màn hình hiển thị trực tiếp chỉ số của Player.
   - Trên đầu Quái vật có thanh HP mini hiển thị lượng máu còn lại của quái theo thời gian thực.
5. **Độc lập Pause Mode**:
   - Toàn bộ combat logic (chém, đạn bay, quái đuổi) đều tuân thủ `PROCESS_MODE_PAUSABLE`, dừng tuyệt đối khi bấm `Esc` và tiếp tục mượt mà sau khi `Resume`.

---

## 4. Cách chạy và kiểm thử nhanh

- **Chạy game test ngay:** Click đúp vào file `run_game.bat` nằm ngay trong thư mục dự án.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Xuất toàn bộ code cho AI:** Click đúp vào file `export_code_for_ai.bat`.

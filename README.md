# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M1.1 + M2 Final)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc & kiểm thử
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Main Scene: noctis_forest.tscn (1280x720, forward_plus)
├── run_game.bat                    # 1-Click chạy game test ngay lập tức
├── open_editor.bat                 # 1-Click mở Godot Editor
├── export_code_for_ai.bat          # 1-Click gom toàn bộ source code thành file text gửi AI
│
├── assets\
│   └── sprites\
│       └── player\
│           ├── player_idle_atlas.png         # Đã tối ưu Atlas 2048x2040 (8 cols x 6 rows, 48 frames)
│           ├── player_idle_atlas.png.import
│           ├── player_run_atlas.png          # Đã tối ưu Atlas 1024x1360 (4 cols x 4 rows, 14 frames)
│           └── player_run_atlas.png.import
│
└── src\
    ├── actors\
    │   ├── player\
    │   │   ├── player.gd                    # FSM Player (IDLE, RUN, JUMP, FALL, DASH, DEAD), Respawn
    │   │   ├── player.tscn                  # Scene Player (HealthComp, CombatComp, Hurtbox, Hitbox)
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC, đối thoại đa phân đoạn & trigger nhiệm vụ
    │   │   └── npc.tscn                     # Scene NPC Elyra, trượng phép & nhãn [E]
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI (IDLE, CHASE, ATTACK, HURT, DEAD), bỏ mục tiêu khi player chết
    │       └── enemy.tscn                   # Scene Enemy với thanh máu HPBar mini, hitbox & hurtbox
    ├── combat\
    │   ├── damage_info.gd                   # Struct dữ liệu sát thương & knockback
    │   ├── health_component.gd              # Quản lý HP, MP, hồi mana & I-frames miễn nhiễm
    │   ├── hurtbox.gd                       # Vùng nhận đòn chuyển tiếp tới HealthComponent
    │   ├── hitbox.gd                        # Vùng gây sát thương chém cận chiến / đòn cắn
    │   ├── combat_component.gd              # Quản lý cooldown chém thường và bắn ma pháp
    │   ├── magic_projectile.gd              # Quả cầu ma pháp bay thẳng gây nổ sát thương
    │   └── magic_projectile.tscn            # Scene đạn phép ma pháp
    ├── interaction\
    │   └── interaction_component.gd         # Area2D tương tác nhận diện Player phạm vi gần
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # Quản lý vòng lặp nhiệm vụ, tiến độ 3/3 và trả thưởng Vàng
    ├── ui\
    │   ├── game_ui.gd                       # Quản lý toàn bộ HUD, HP/MP, Vàng, Nhiệm vụ, DialogueBox, GameOver
    │   ├── game_ui.tscn                     # CanvasLayer giao diện hoàn chỉnh
    │   └── pause_controller.gd              # Quản lý Pause/Resume độc lập (PROCESS_MODE_ALWAYS)
    └── world\
        ├── noctis_forest.gd                 # Main Scene M2: Quản lý vòng lặp thế giới, respawn, nhiệm vụ
        ├── noctis_forest.tscn               # Màn chơi Bìa Rừng Noctis (Làng Ánh Nguyệt + Rừng Hắc Nguyệt)
        ├── test_level.gd                    # Màn test M1 cũ (vẫn được lưu giữ)
        └── test_level.tscn
```

---

## 2. Các phím điều khiển (Controls)

| Phím | Chức năng | Chi tiết |
| :--- | :--- | :--- |
| **A / D** hoặc **Mũi tên** | Di chuyển Trái / Phải | Có gia tốc mượt, tự động quay mặt nhân vật |
| **Space** | Nhảy / Nhảy đôi | Nhấn lần 1 nhảy, nhấn lần 2 trên không để Double Jump |
| **Shift** | Lướt nhanh (Dash) | Lướt ngang tốc độ cao (0.2s), có thể Air-Dash trên không |
| **J** | **Đánh thường (Melee)** | Chém cận chiến (25 DMG), có cooldown (0.35s) và đẩy lùi quái |
| **K** | **Ma pháp (Magic Spell)** | Bắn quả cầu ma pháp (30 DMG), tiêu hao 15 MP, có cooldown |
| **E** | **Tương tác (Interact)** | Nói chuyện với NPC Elyra, nhận nhiệm vụ và chuyển hội thoại |
| **Esc** | Pause / Resume | Tạm dừng hoặc tiếp tục game (bằng phím Esc hoặc nút Resume) |

---

## 3. Các tính năng cốt lõi đã hoàn thiện (M1.1 + M2)

### Giai đoạn A: Hoàn thiện M1.1
1. **Hệ thống Chết & Hồi sinh (Game Over & Retry)**:
   - Khi HP = 0: Player chuyển sang `State.DEAD`, vô hiệu hóa toàn bộ di chuyển, nhảy, dash, tấn công hoặc bắn phép.
   - Hộp thoại **Game Over** hiển thị với nút **Hồi sinh (Retry)**.
   - Nhấn Retry: Đưa nhân vật trở lại điểm xuất phát (`spawn_position`), khôi phục 100% HP & MP, mở lại Hurtbox và khôi phục trạng thái hoạt động bình thường.
2. **Sửa AI Quái vật**:
   - Khi Player chết, Quái tự động hủy mục tiêu và quay về trạng thái `IDLE`.
   - Một khi Quái đã vào trạng thái `DEAD`, quái không thể bị ghi đè bởi `HURT` hay `ATTACK`.
   - Cơ chế `_has_reported_death` đảm bảo mỗi quái vật chỉ phát tín hiệu tiêu diệt và cộng tiến độ nhiệm vụ đúng 1 lần.
3. **Tối ưu hóa Sprite (Atlas 2048x2048)**:
   - Thay thế dải ảnh ngang cũ 24.576 px bằng Atlas dạng lưới vuông:
     - `player_idle_atlas.png`: Lưới 8 cột x 6 hàng = 2048 x 2040 px (48 frames chuẩn Mobile GPU).
     - `player_run_atlas.png`: Lưới 4 cột x 4 hàng = 1024 x 1360 px (14 frames).
   - Tỷ lệ hiển thị, vị trí chân và va chạm vật lý giữ nguyên 100%.

### Giai đoạn B & C: Thế giới Ma pháp M2 (Bìa Rừng Noctis)
1. **Bản đồ 2 vùng nối liền**:
   - **Vùng 1 — Làng Ánh Nguyệt (Tọa độ 0 - 1800 px):** Yên bình, có ánh trăng, nhà cửa, hoa phát sáng, đài tinh thể ma pháp và NPC Elyra cùng bảng hướng dẫn điều khiển.
   - **Vùng 2 — Rừng Hắc Nguyệt (Tọa độ 1800 - 4400 px):** Khung cảnh u tối, sương mù tím, cây cổ thụ, các bục nhảy platform và 3 sinh vật ma nhiễm bị tha hóa (`CorruptedEnemy1`, `2`, `3`).
2. **NPC Elyra & Hệ thống Tương tác**:
   - Khi Player đến gần Elyra trong bán kính 65px, nhãn `[E] Nói chuyện` sẽ hiện ra.
   - Nhấn E mở cửa sổ đối thoại, có thể nhấn phím để duyệt từng câu thoại. Trong lúc đối thoại, input chiến đấu bị chặn để tránh thao tác nhầm.
3. **Nhiệm vụ đầu tiên: "Ánh Sáng Bị Nuốt Chửng"**:
   - Nhận nhiệm vụ từ Elyra. HUD góc trên bên phải cập nhật tiến độ `Tiêu diệt sinh vật: 0/3`.
   - Tiến vào Rừng Hắc Nguyệt, tiêu diệt lần lượt 3 sinh vật tha hóa (tiến độ nhảy `1/3`, `2/3`, `3/3`).
   - Quay về gặp Elyra báo cáo: Nhận thưởng **50 Vàng** và được thanh tẩy **hồi phục toàn bộ HP & MP**.
   - Có cơ chế chống nhận thưởng 2 lần.

---

## 4. Kết quả kiểm thử tự động trên Godot 4.3 Engine

Đã khởi chạy kịch bản kiểm thử tích hợp tự động toàn diện (`auto_m2_integration_test.gd`):

```text
==================================================
   BAT DAU KIEM THU TICH HOP TOAN DIEN M1.1 & M2   
==================================================
[PASS] Test A1: Atlas moi 2048x2040 khoi tao va hien thi thanh cong
[PASS] Test A2: Khi HP = 0, Player dung yen o State DEAD, moi input bi khoa triet de
[PASS] Test A3: AI Quai vat bo muc tieu va khong tan cong khi Player da chet
[PASS] Test A4: Retry hoat dong hoan hao, hoi phuc 100% chi so va vi tri
[PASS] Test B1: Noi chuyen voi Elyra, nhan nhiem vu thanh cong
[PASS] Test B2: Tieu diet du 3 quai vat, tien do 3/3 khong trung lap
[PASS] Test B3: Tra quest cho Elyra nhan 50 Vang va hoi phuc tron ven HP/MP
[PASS] Test B4: Chong nhan thuong trung lap hoat dong 100%
[PASS] Test C: Pause / Resume hoat dong on dinh trong the gioi M2
==================================================
   TAT CA 8 BAI TEST TICH HOP M1.1 & M2 PASS 100%!   
==================================================
```
- **Console / Debugger:** Không có lỗi script hoặc thiếu tài nguyên nào (`0 Errors, 0 Warnings`).

---

## 5. Hướng dẫn chạy và trải nghiệm trực tiếp

- **Cách chạy 1-Click:** Click đúp vào file `run_game.bat` ngay trong thư mục dự án.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Trải nghiệm vòng lặp gameplay:**
  1. Xuất hiện tại Làng Ánh Nguyệt, chạy sang phải gặp **NPC Elyra** và nhấn **E** để nhận nhiệm vụ.
  2. Tiếp tục chạy sang phải qua bảng ranh giới để tiến vào **Rừng Hắc Nguyệt**.
  3. Dùng phím **J** (chém kiếm) và **K** (bắn ma pháp) tiêu diệt 3 sinh vật ma nhiễm.
  4. Sau khi tiêu diệt đủ 3/3, chạy ngược về làng gặp Elyra nhấn **E** để trả nhiệm vụ, nhận **50 Vàng** và hồi đầy thanh HP/MP.
  5. Thử để quái đánh chết: Màn hình Game Over xuất hiện, bấm **Hồi sinh (Retry)** sẽ lập tức đưa nhân vật về làng với đầy đủ sinh lực.

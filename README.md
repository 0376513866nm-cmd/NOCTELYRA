# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M2.1 FINAL)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M2.1)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc & kết quả kiểm thử
├── CODE_EXPORT.txt                 # Mã nguồn tổng hợp toàn dự án cho AI review
├── test_m2_1_flow.gd               # Kịch bản kiểm thử tự động toàn diện qua input (42/42 tests pass)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Main Scene: noctis_forest.tscn (1280x720, forward_plus)
├── run_game.bat                    # 1-Click chạy game test ngay lập tức
├── open_editor.bat                 # 1-Click mở Godot Editor
├── export_code_for_ai.bat          # 1-Click gom toàn bộ source code thành file CODE_EXPORT.txt
│
├── source_assets\                  # TÀI NGUYÊN NGUỒN (Được cách ly bằng .gdignore, không đưa vào build)
│   ├── .gdignore                   # Khai báo Godot Engine bỏ qua thư mục này khi import/export
│   ├── README.md                   # Hướng dẫn tái tạo Atlas từ ảnh Strip
│   ├── repack_sprites.ps1          # Script PowerShell tự động cắt và đóng gói lại Atlas vuông
│   ├── player_idle_strip.png       # Dải ảnh gốc 48 frame Idle (24.576 x 680 px)
│   └── player_run_strip.png        # Dải ảnh gốc 14 frame Run (7.168 x 680 px)
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
    │   │   ├── player.gd                    # FSM Player (IDLE, RUN, JUMP, FALL, DASH, DEAD), Grace Cooldown
    │   │   ├── player.tscn                  # Scene Player (HealthComp, CombatComp, Hurtbox, Hitbox)
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC Elyra, đối thoại đa phân đoạn & trigger nhiệm vụ
    │   │   └── npc.tscn                     # Scene NPC Elyra (collision_layer = 0: xuyên người mượt mà)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI (Single-path kill signal, anti-duplicate protection)
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
    │   ├── interaction_coordinator.gd       # [MỚI M2.1] Bộ điều phối Input tập trung cho tương tác & hội thoại
    │   └── interaction_component.gd         # Area2D tương tác nhận diện Player phạm vi gần
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # Quản lý vòng lặp nhiệm vụ, tiến độ 3/3 và trả thưởng Vàng
    ├── ui\
    │   ├── game_ui.gd                       # Quản lý toàn bộ HUD, HP/MP, Vàng, Nhiệm vụ, DialogueBox, Grace Cooldown
    │   ├── game_ui.tscn                     # CanvasLayer giao diện hoàn chỉnh
    │   └── pause_controller.gd              # Quản lý Pause/Resume độc lập (PROCESS_MODE_ALWAYS)
    └── world\
        ├── noctis_forest.gd                 # Main Scene M2.1: Quản lý vòng lặp thế giới, kết nối sự kiện
        ├── noctis_forest.tscn               # Màn chơi Bìa Rừng Noctis tích hợp InteractionCoordinator
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
| **E** | **Tương tác (Interact)** | Tương tác NPC khi chưa mở thoại; duyệt/đóng câu khi đang mở thoại |
| **Esc** | Pause / Resume | Tạm dừng hoặc tiếp tục game (bằng phím Esc hoặc nút Resume) |

---

## 3. Các cải tiến kiến trúc cốt lõi trong M2.1

### 1. Khắc phục triệt để lỗi va chạm và Race Condition hội thoại NPC
- **NPC xuyên người hoàn toàn:** Đặt `collision_layer = 0` trên NPC `CharacterBody2D`. Player có thể chạy qua, nhảy qua hoặc đứng cùng vị trí với Elyra mà không hề bị cản trở. Vùng tương tác `InteractionComponent` (Area2D) vẫn phát hiện chính xác người chơi.
- **Bộ điều phối Input tập trung (`InteractionCoordinator`):**
  - Loại bỏ hoàn toàn sự cạnh tranh phím `E` qua `_unhandled_input()` giữa NPC và GameUI.
  - Khi chưa mở hội thoại: Phím `E` dùng để kích hoạt tương tác với NPC gần nhất.
  - Khi đang mở hội thoại: Phím `E` **chỉ** dùng để chuyển câu tiếp theo hoặc đóng hội thoại. Tuyệt đối không thể kích hoạt lại hội thoại từ đầu khi đang mở.
  - **Grace Cooldown (0.25s):** Sau khi hội thoại đóng, một khoảng chờ ngắn ngăn chặn nhấn đúp làm mở lại hội thoại tức thì.
  - **Bảo vệ chống nhận nhầm phím J / Space:** Trong suốt quá trình hội thoại và thời gian Grace Cooldown, toàn bộ input hành động (Tấn công, Nhảy, Ma pháp, Dash) bị chặn triệt để, không để người chơi vô tình vung kiếm hoặc nhảy khi vừa đóng thoại.

### 2. Dọn dẹp kiến trúc thông báo Quái vật bị tiêu diệt
- **Đường thông báo duy nhất:** Quái vật khi chết (`Enemy._notify_kill_once`) chỉ phát duy nhất một tín hiệu `enemy_defeated(self)`.
- Signal này được `NoctisForest` kết nối tới `QuestManager.register_enemy_kill(enemy)`.
- Loại bỏ lệnh gọi trực tiếp trùng lặp trước đây, duy trì cơ chế chống đếm trùng ở cả 2 cấp:
  1. `_has_reported_death` trong từng `Enemy`.
  2. `_killed_enemy_ids` trong `QuestManager`.

### 3. Tách biệt Source Assets và Tài liệu tái tạo Atlas
- Đã di chuyển toàn bộ dải ảnh gốc dung lượng lớn (`player_idle_strip.png` 24.576 px và `player_run_strip.png` 7.168 px) ra khỏi thư mục `assets/sprites/player/`, đặt vào thư mục `source_assets/`.
- Cấu hình file `.gdignore` trong `source_assets/` đảm bảo Godot Engine bỏ qua hoàn toàn, không đưa các file nguồn dung lượng lớn vào bản build xuất bản game.
- Bổ sung PowerShell script tự động `source_assets/repack_sprites.ps1` và tài liệu hướng dẫn cho phép tái tạo 100% hai file atlas `player_idle_atlas.png` (2048x2040) và `player_run_atlas.png` (1024x1360) khi có cập nhật ảnh mới.

---

## 4. Báo cáo kiểm thử tự động thực tế trên Godot 4.3 Engine

Script kiểm thử tích hợp thực tế `test_m2_1_flow.gd` được chạy trực tiếp bằng console của Godot 4.3 (`Godot_v4.3-stable_win64_console.exe --headless -s test_m2_1_flow.gd`):

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M2.1] INTEGRATION TEST SUITE STARTING
==================================================

--- PHASE 1: Kiếm tra thực thể và kiến trúc điều phối ---
  [PASS] Player tồn tại trong scene
  [PASS] NPC Elyra tồn tại trong scene
  [PASS] GameUI tồn tại trong scene
  [PASS] QuestManager tồn tại trong scene
  [PASS] InteractionCoordinator tồn tại trong scene

--- PHASE 2: Kiểm tra vật cản NPC (Xuyên người) ---
  [PASS] NPC collision_layer = 0 (không cản Player di chuyển)
  [PASS] Player có thể di chuyển và đứng trùng vị trí NPC Elyra mà không bị kẹt va chạm

--- PHASE 3: Trạng thái ban đầu của Nhiệm vụ & Hội thoại ---
  [PASS] Nhiệm vụ ban đầu là NOT_STARTED
  [PASS] Hội thoại ban đầu đóng
  [PASS] NPC Elyra có thể tương tác khi Player đứng gần

--- PHASE 4: Tương tác mở hội thoại bằng Input 'E' ---
  [PASS] Nhấn E lần 1: Hội thoại đã mở thành công
  [PASS] Người nói là Elyra

--- PHASE 5: Bảo vệ chống nhận nhầm phím J (Tấn công) / Space (Nhảy) khi đang thoại ---
  [PASS] Nhấn J/Space trong lúc thoại không làm đóng hội thoại
  [PASS] Nhấn J/Space trong lúc thoại không kích hoạt chém kiếm hay nhảy
  [PASS] Melee hitbox của Player vẫn tắt an toàn

--- PHASE 6: Đọc tuần tự 3 câu hội thoại bằng Input 'E' ---
  [PASS] Nhấn E: Chuyển sang câu thứ 2
  [PASS] Nhấn E: Chuyển sang câu thứ 3
  [PASS] Nhấn E lần cuối: Hội thoại đóng lại thành công
  [PASS] Nhiệm vụ chuyển sang trạng thái ACTIVE
  [PASS] Số lượng tiêu diệt ban đầu là 0/3

--- PHASE 7: Grace Cooldown chống nhấn đúp re-open tức thì ---
  [PASS] Nhấn E ngay khi vừa đóng: Bị chặn bởi Grace Cooldown, không re-open tức thì

--- PHASE 8: Tiêu diệt quái & Xác minh đường thông báo duy nhất ---
  [PASS] Có ít nhất 3 quái vật trên bản đồ (thực tế: 3)
  [PASS] Diệt quái 1: Tiến độ cập nhật 1/3
  [PASS] Bảo vệ chống đếm trùng: Quái 1 không bị đếm lần 2
  [PASS] Diệt quái 2: Tiến độ cập nhật 2/3
  [PASS] Diệt quái 3: Tiến độ cập nhật 3/3
  [PASS] Nhiệm vụ chuyển sang READY_TO_TURN_IN

--- PHASE 9: Trả nhiệm vụ bằng Input 'E' & Nhận thưởng ---
  [PASS] Vàng ban đầu là 0 G
  [PASS] Nhấn E: Mở hội thoại hoàn thành nhiệm vụ
  [PASS] Hội thoại trả nhiệm vụ đã đóng
  [PASS] Nhiệm vụ chuyển sang COMPLETED
  [PASS] Player nhận đúng 50 Vàng (hiện tại: 50 G)
  [PASS] HP của Player được hồi phục đầy (100/100)
  [PASS] MP của Player được hồi phục đầy (100/100)

--- PHASE 10: Tương tác lần nữa không nhận thêm thưởng ---
  [PASS] Nhấn E: Mở hội thoại cảm ơn sau hoàn thành
  [PASS] Hội thoại cảm ơn đã đóng
  [PASS] Vàng vẫn giữ nguyên đúng 50 G, không nhận thêm thưởng lặp lại

--- PHASE 11: Kiểm tra hệ thống Pause / Resume ---
  [PASS] Hệ thống ban đầu chưa pause
  [PASS] Esc lần 1: Đã kích hoạt Pause
  [PASS] Pause menu hiển thị
  [PASS] Esc lần 2: Đã kích hoạt Resume
  [PASS] Pause menu ẩn sau khi resume

==================================================
 [NOCTELYRA M2.1] KẾT QUẢ KIỂM THỬ TỔNG HỢP:
 Tổng số test: 42 | Đạt: 42 | Thất bại: 0
==================================================
>>> ALL TESTS PASSED SUCCESSFULLY! M2.1 READY. <<<
```

- **Kết quả nghiệm thu:** 42/42 bài test đạt 100%. Exit code: 0. Không có bất kỳ cảnh báo hay lỗi Debugger nào.

---

## 5. Hướng dẫn chạy và trải nghiệm trực tiếp

- **Chạy game test ngay:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Chạy kiểm thử tự động M2.1:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --path "D:\project\game\NOCTELYRA" --headless -s test_m2_1_flow.gd
  ```
- **Quy trình trải nghiệm vòng nhiệm vụ:**
  1. Xuất hiện tại Làng Ánh Nguyệt, di chuyển sang phải đến chỗ **NPC Elyra**. Bạn có thể đi xuyên qua Elyra hoàn toàn tự nhiên.
  2. Khi nhãn `[E] Nói chuyện` xuất hiện, nhấn **E** để mở đối thoại.
  3. Nhấn **E** lần lượt để đọc hết 3 câu. Thử nhấn **J** hoặc **Space** trong lúc thoại để xác nhận nhân vật không vô tình chém kiếm hay nhảy.
  4. Sau câu thứ 3, nhấn **E** để đóng thoại. Nhiệm vụ chuyển sang `ACTIVE` (0/3).
  5. Tiến vào Rừng Hắc Nguyệt, dùng **J** (chém) và **K** (phép) tiêu diệt 3 sinh vật ma hóa. HUD cập nhật chính xác `1/3 → 2/3 → 3/3`.
  6. Sau khi đủ 3/3, quay về gặp Elyra, nhấn **E** để đọc và đóng đối thoại hoàn thành.
  7. Nhận đúng **50 Vàng**, HP và MP được thanh tẩy hồi phục trọn vẹn 100%.
  8. Tương tác với Elyra lần nữa: Chỉ hiển thị lời chúc bình an, số Vàng vẫn giữ nguyên 50 G (không đếm thưởng lặp).

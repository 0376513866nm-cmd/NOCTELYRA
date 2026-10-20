# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M5.1 STABILIZATION: Magic Combat System)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M5.1 STABILIZATION)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, bảng phép thuật & kết quả kiểm thử M5.1
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M5.1 Final)
├── test_m5_flow.gd                 # [M5.1] Kịch bản kiểm thử 26 nhóm tính năng ma pháp & vật lý (100/100 tests PASS 100%)
├── test_m4_flow.gd                 # Kịch bản kiểm thử 17 hạng mục Boss M4 (87/87 tests PASS 100%)
├── test_m3_2_flow.gd               # Kịch bản kiểm thử M3.2 (50/50 tests PASS 100%)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (41/41 tests PASS 100%)
├── test_m3_flow.gd                 # Kịch bản kiểm thử M3 (67/67 tests PASS 100%)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử M2.1 (42/42 tests PASS 100%)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Main Scene: main_menu.tscn (1280x720, forward_plus, input maps M5.1)
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
    │   │   ├── player.gd                    # FSM Player, dọn sạch đạn khi chết/hồi sinh, phím 1/2/3/U, combat
    │   │   ├── player.tscn                  # Scene Player có SpellbookComponent
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy đôi, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC Elyra, mở khóa Cổng Ma Pháp sau khi trả nhiệm vụ
    │   │   └── npc.tscn                     # Scene NPC Elyra (collision_layer = 0: xuyên người mượt mà)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI, làm chậm 35%, rơi Tinh thể Ma lực an toàn
    │       └── enemy.tscn                   # Scene Enemy với thanh máu HPBar mini, hitbox & hurtbox
    ├── boss\                                # MODULE BOSS LUNARETH — LINH LỘC NGUYỆT THỰC
    │   ├── boss_lunareth.gd                 # Miễn nhiễm slow, bất tử 1.3s Phase Transition, shockwave
    │   ├── boss_lunareth.tscn               # Scene Boss với HealthComponent (320 HP), Hurtbox, Hitbox
    │   ├── boss_visual.gd                   # Visual chuyển phase, aura tím, telegraph
    │   ├── boss_shockwave.gd                # Projectile group 'boss_projectiles'
    │   └── boss_shockwave.tscn              # Scene projectile sóng xung kích
    ├── combat\
    │   ├── damage_info.gd                   # Struct dữ liệu sát thương & knockback
    │   ├── health_component.gd              # Quản lý máu, MP, hồi MP tự nhiên, bất tử
    │   ├── hurtbox.gd                       # Vùng nhận đòn chuyển tiếp tới HealthComponent
    │   ├── hitbox.gd                        # Vùng gây sát thương chém cận chiến
    │   ├── combat_component.gd              # Điều phối chém kiếm và ủy quyền cast_spell sang SpellbookComponent
    │   ├── magic_projectile.gd              # Projectile cũ (giữ tương thích)
    │   └── magic_projectile.tscn
    ├── magic\                               # [M5.1] HỆ THỐNG PHÁP THUẬT CHIẾN ĐẤU
    │   ├── spell_definition.gd              # Custom Resource: tỉ lệ tăng cấp unrounded (100%, 115%, 130%), giá nâng cấp
    │   ├── spell_database.gd                # Thông số thiết kế chuẩn M5.1 (15 MP/0.6s, 25 MP/2.0s, 18 MP/1.0s)
    │   ├── spellbook_component.gd           # Quản lý danh sách phép, phép đang chọn, cấp độ, cooldown độc lập
    │   └── projectiles\
    │       ├── moon_bolt_projectile.gd      # Đạn ánh trăng 550 px/s, đơn mục tiêu (30.0 / 34.5 / 39.0 DMG)
    │       ├── moon_bolt_projectile.tscn
    │       ├── ember_bloom_projectile.gd    # Đạn lửa 380 px/s, nổ AoE 110 px (22.0 / 25.3 / 28.6 DMG, chống đòn trùng)
    │       ├── ember_bloom_projectile.tscn
    │       ├── frost_shard_projectile.gd    # Đạn băng 650 px/s, làm chậm quái 35% trong 2s (20.0 / 23.0 / 26.0 DMG)
    │       └── frost_shard_projectile.tscn
    ├── interaction\
    │   ├── interaction_coordinator.gd       # Bộ điều phối Input tập trung cho tương tác & hội thoại
    │   └── interaction_component.gd         # Area2D tương tác nhận diện Player phạm vi gần
    ├── inventory\                           # HỆ THỐNG VẬT PHẨM & TRANG BỊ
    │   ├── item_definition.gd               # Resource định nghĩa vật phẩm chuẩn
    │   ├── item_database.gd                 # Đăng ký mana_shard, health_potion, moonsteel_sword, moon_amulet, eclipse_fragment
    │   ├── inventory_component.gd           # Quản lý 16 ô túi đồ, clear(), remove_item_by_id()
    │   ├── equipment_component.gd           # Quản lý 2 ô trang bị & tính toán lại chỉ số
    │   ├── inventory_ui.gd                  # Controller giao diện túi đồ, lưới 16 ô
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ
    ├── loot\                                # HỆ THỐNG RƠI ĐỒ VÀ NHẶT VẬT PHẨM
    │   ├── loot_table.gd                    # Resource định nghĩa bảng tỷ lệ rơi đồ
    │   ├── item_pickup.gd                   # Gán pickup_id ổn định, tự hủy nếu đã nhặt trước đó
    │   └── item_pickup.tscn                 # Scene vật phẩm rơi với hiệu ứng nhấp nhô lơ lửng
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # Quản lý quest, lưu enemy_id chuỗi ổn định xuyên suốt
    ├── save\                                # HỆ THỐNG LƯU / TẢI TIẾN TRÌNH OFFLINE
    │   └── save_manager.gd                  # Version 1.2.0, lưu/nạp spellbook, tương thích ngược v1.0.0 & v1.1.0
    ├── ui\
    │   ├── spell_hotbar.gd                  # Controller thanh chọn phép 3 ô [1], [2], [3] & nút [U]
    │   ├── spell_hotbar.tscn                # Scene thanh hotbar hiển thị highlight, cooldown, MP, Lv
    │   ├── game_ui.gd                       # Tích hợp hotbar, hiển thị thông báo nâng cấp phép
    │   ├── game_ui.tscn                     # CanvasLayer HUD, Bars, Dialogue, PauseMenu, Hotbar
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập
    │   ├── main_menu.gd                     # Màn hình chính
    │   └── main_menu.tscn
    └── world\
        ├── magic_gate.gd                    # Cổng Ma Pháp tại X=4200
        ├── magic_gate.tscn                  # Scene Cổng Ma Pháp rào chắn vật lý
        ├── noctis_forest.gd                 # Tích hợp 7 Tinh thể Ma lực đặt sẵn, dọn projectile khi retry
        └── noctis_forest.tscn               # Màn chơi chứa 7 pickup Tinh thể Ma lực + 3 quái (tổng 10 Shards)
```

---

## 2. Thông số 3 Kỹ năng Ma pháp (Milestone M5.1 Chuẩn)

| Thuộc tính | 1. Nguyệt Quang Đạn (`moon_bolt`) | 2. Tinh Hỏa Bùng Nổ (`ember_bloom`) | 3. Hàn Tinh Tiễn (`frost_shard`) |
| :--- | :---: | :---: | :---: |
| **Phím tắt chọn** | **Phím [1]** | **Phím [2]** | **Phím [3]** |
| **Phím thi triển** | **Phím [K]** | **Phím [K]** | **Phím [K]** |
| **Tiêu hao MP** | **15 MP** | **25 MP** | **18 MP** |
| **Thời gian hồi (CD)** | **0.6 giây** (Độc lập) | **2.0 giây** (Độc lập) | **1.0 giây** (Độc lập) |
| **Tốc độ đạn** | **550 px/s** | **380 px/s** | **650 px/s** |
| **Cơ chế đòn đánh** | Đơn mục tiêu, đạn bay thẳng, tan biến khi chạm mục tiêu | Bắn cầu lửa phát nổ diện rộng **bán kính 110 px**, chống sát thương trùng | Đạn băng sắc bén, **làm chậm 35% tốc độ quái vật** trong **2.0 giây** |
| **Miễn nhiễm làm chậm** | — | — | **Boss Lunareth miễn nhiễm hoàn toàn** với hiệu ứng làm chậm |
| **Sát thương Cấp 1 (100%)** | **30.0 DMG** | **22.0 DMG** | **20.0 DMG** |
| **Sát thương Cấp 2 (115%)** | **34.5 DMG** (unrounded) | **25.3 DMG** (unrounded) | **23.0 DMG** (unrounded) |
| **Sát thương Cấp 3 (130%)** | **39.0 DMG** (unrounded) | **28.6 DMG** (unrounded) | **26.0 DMG** (unrounded) |
| **Chi phí nâng Cấp 2** | **3 Tinh thể Ma lực** (`mana_shard`) | **3 Tinh thể Ma lực** (`mana_shard`) | **3 Tinh thể Ma lực** (`mana_shard`) |
| **Chi phí nâng Cấp 3** | **6 Tinh thể Ma lực** (`mana_shard`) | **6 Tinh thể Ma lực** (`mana_shard`) | **6 Tinh thể Ma lực** (`mana_shard`) |

> **Ghi chú về sát thương:** Sát thương không được làm tròn số trong logic game (ví dụ: `34.5`, `25.3`, `28.6` được tính toán chính xác bằng số thực `float`).

---

## 3. Phân bổ Tài nguyên Tinh thể Ma lực (Mana Shard) trong Bản đồ

Để đảm bảo người chơi có thể nâng cấp đầy đủ từ Cấp 1 lên Cấp 3 (cần tổng cộng 3 + 6 = 9 Shards) trong một lượt chơi:
- **7 Tinh thể Ma lực đặt sẵn (`preplaced_pickups`):**
  1. `ForestPickup_Shard1` tại $(1000, 640)$ (Mặt đất khu vực đầu rừng)
  2. `ForestPickup_Shard2` tại $(1450, 640)$ (Gần cụm quái thứ 1)
  3. `ForestPickup_Shard3` tại $(2000, 640)$ (Giữa rừng)
  4. `ForestPickup_Shard4` tại $(2300, 440)$ (Platform cao bí mật thứ 1)
  5. `ForestPickup_Shard5` tại $(2800, 340)$ (Platform ngọn cây cao thứ 2)
  6. `ForestPickup_Shard6` tại $(3400, 430)$ (Platform tàn tích cổ)
  7. `ForestPickup_Shard7` tại $(3950, 640)$ (Trước Cổng Ma Pháp X=4200)
- **3 Tinh thể Ma lực từ Quái vật:** 3 quái vật tha hóa trong rừng mỗi con rơi 1 Tinh thể Ma lực khi bị tiêu diệt.
- **Tổng tài nguyên:** **10 Tinh thể Ma lực** (đáp ứng vượt mức yêu cầu $\ge 9$ Tinh thể để nâng cấp max Cấp 3).
- **Lưu trữ & Chống trùng lặp:** Mỗi vật phẩm đặt sẵn có `pickup_id` duy nhất (`pickup_forest_shard_1` đến `pickup_forest_shard_7`). Sau khi nhặt, `SaveManager` ghi nhận vào `collected_pickup_ids`, đảm bảo khi tải lại game các mảnh đã nhặt không hồi sinh và số lượng trong túi đồ không bị nhân đôi.

---

## 4. Kiểm thử Tích hợp Vật lý Thực tế (Godot Physics Server)

Các kịch bản kiểm thử M5.1 chạy qua `await physics_frame` mô phỏng trực tiếp trên Engine vật lý:
1. **Bay & Va chạm thực tế (Moon Bolt):** Đạn bay thực sự ở vận tốc 550 px/s, Physics Server phát hiện va chạm với Hurtbox của Quái vật (`collision_layer = 4`), gây 30 DMG và tự hủy.
2. **Kiểm tra bán kính nổ 110 px (Ember Bloom):**
   - Quái vật trong bán kính 110 px (cách tâm 70 px): Nhận 22 DMG.
   - Quái vật ngoài bán kính 110 px (cách tâm 160 px): Nhận 0 DMG.
   - Chống sát thương trùng: Kích hoạt thêm lần nữa trong cùng vụ nổ không gây thêm sát thương.
3. **Hiệu ứng làm chậm & Phục hồi (Frost Shard):**
   - Quái vật dính đạn bị giảm 35% vận tốc di chuyển (tốc độ còn 65%).
   - Sau 2.0 giây, vận tốc tự động khôi phục 100% nguyên bản.
   - Boss Lunareth nhận sát thương bình thường nhưng **miễn nhiễm 100%** với hiệu ứng làm chậm (vận tốc giữ nguyên).
4. **Không tự gây sát thương (No Self-Damage):** Đạn xuất hiện chạm người Player không gây sát thương lên người chơi.
5. **Hết thời gian tồn tại (Lifetime Expiration):** Đạn bay ra ngoài không gian tự giải phóng bộ nhớ sau thời gian sống (lifetime).
6. **Dọn dẹp đạn khi Chết & Retry:** Toàn bộ đạn trong nhóm `player_projectiles` và `boss_projectiles` lập tức bị xóa sạch khi Player chết hoặc khi bấm Retry bản đồ.

---

## 5. Ràng buộc Nâng cấp Phép & Giao diện Hotbar

- **Phím chọn phép:** `[1]`, `[2]`, `[3]`.
- **Phím bắn phép:** `[K]`.
- **Phím nâng cấp:** `[U]` (hoặc nhấp chuột vào nút trên Hotbar).
- **Ràng buộc an toàn:**
  + Chặn nâng cấp khi đang đấu Boss Lunareth (`boss_battle_started = true`).
  + Chặn nâng cấp khi Player đã chết (`Player.State.DEAD`).
  + Chặn nâng cấp khi đang tạm dừng (`paused`), mở hội thoại NPC hoặc mở túi đồ.
  + Chặn nâng cấp khi đã đạt Cấp tối đa (Cấp 3).

---

## 6. Hệ thống Lưu / Tải Dữ liệu v1.2.0 & Cách Ly File Thật

- **Phiên bản bản lưu:** `1.2.0`.
- **Khối dữ liệu `spellbook`:** Lưu trữ phép đang chọn, danh sách phép đã học, cấp độ của từng phép.
- **Tương thích ngược:** Nạp an toàn bản lưu cũ `1.0.0` (M3.2) và `1.1.0` (M4), tự động bù đắp dữ liệu mặc định mà không gây crash.
- **Cách ly tuyệt đối:** Bộ kiểm thử chỉ tương tác với file test riêng biệt `user://noctelyra_m5_test.json`. File save thật `user://noctelyra_slot1.json` được bảo vệ nguyên vẹn 100% với MD5 checksum đối chiếu không thay đổi.

---

## 7. Báo cáo Kiểm thử Tự động Tổng hợp trên Godot 4.3 Engine

Tất cả các bộ test đều chạy trong môi trường Engine thực tế (`Godot_v4.3-stable_win64_console.exe --headless`):

```text
========================================================================================
 BỘ KIỂM THỬ                         | SỐ TEST    | KẾT QUẢ      | MÃ THOÁT (EXIT CODE)
----------------------------------------------------------------------------------------
 test_m5_flow.gd (Ma pháp M5.1)      | 100 tests  | PASS 100%    | 0
 test_m4_flow.gd (Boss Lunareth M4)  |  87 tests  | PASS 100%    | 0
 test_m3_2_flow.gd (Save/Load M3.2)  |  50 tests  | PASS 100%    | 0
 test_m2_1_flow.gd (NPC & Quest M2)  |  42 tests  | PASS 100%    | 0
========================================================================================
 TỔNG CỘNG                           | 279 tests  | PASS 100%    | HOÀN HẢO KHÔNG LỖI
========================================================================================
```

---

## 8. Hướng dẫn Điều khiển & Trải nghiệm

| Phím bấm | Hành động |
| :--- | :--- |
| **A / D** | Di chuyển trái / phải |
| **Space** | Nhảy đơn / Nhảy đôi (Double Jump) |
| **Shift** | Lướt nhanh (Dash) |
| **J** | Tấn công cận chiến (Chém kiếm) |
| **K** | Thi triển phép thuật đang chọn (Bắn ma pháp, tiêu hao MP) |
| **1, 2, 3** | Chọn phép thuật: [1] Nguyệt Quang Đạn \| [2] Tinh Hỏa Bùng Nổ \| [3] Hàn Tinh Tiễn |
| **U** | Nâng cấp phép thuật đang chọn (Tiêu hao Tinh thể Ma lực `mana_shard`) |
| **E** | Tương tác NPC Elyra / Trò chuyện / Nhận & Trả nhiệm vụ |
| **I** | Mở / Đóng túi đồ (Inventory) & Bảng trang bị |
| **Esc** | Tạm dừng trò chơi (Pause Menu) / Đóng túi đồ |

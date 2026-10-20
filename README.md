# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M5 FINAL: Magic Combat System)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M5 FINAL)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, bảng phép thuật & kết quả kiểm thử M5
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M5 Final)
├── test_m5_flow.gd                 # [MỚI M5] Kịch bản kiểm thử 20 nhóm tính năng ma pháp (85/85 tests PASS 100%)
├── test_m4_flow.gd                 # Kịch bản kiểm thử 17 hạng mục Boss M4 (87/87 tests PASS 100%)
├── test_m3_2_flow.gd               # Kịch bản kiểm thử M3.2 (50/50 tests PASS 100%)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (41/41 tests PASS 100%)
├── test_m3_flow.gd                 # Kịch bản kiểm thử M3 (67/67 tests PASS 100%)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử M2.1 (42/42 tests PASS 100%)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Main Scene: main_menu.tscn (1280x720, forward_plus, input maps M5)
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
    │   │   ├── player.gd                    # FSM Player, tích hợp SpellbookComponent, phím 1/2/3/U, combat
    │   │   ├── player.tscn                  # Scene Player có SpellbookComponent
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy đôi, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC Elyra, mở khóa Cổng Ma Pháp sau khi trả nhiệm vụ
    │   │   └── npc.tscn                     # Scene NPC Elyra (collision_layer = 0: xuyên người mượt mà)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI, apply_slow(ratio, duration), khôi phục tốc độ chuẩn
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
    ├── magic\                               # [MỚI M5] HỆ THỐNG PHÁP THUẬT CHIẾN ĐẤU
    │   ├── spell_definition.gd              # Custom Resource: thông số, sát thương theo cấp, giá nâng cấp
    │   ├── spell_database.gd                # Registry tra cứu tĩnh 3 phép chuẩn theo ID
    │   ├── spellbook_component.gd           # Quản lý danh sách phép, phép đang chọn, cấp độ, cooldown độc lập
    │   └── projectiles\
    │       ├── moon_bolt_projectile.gd      # Đạn ánh trăng 550 px/s, đơn mục tiêu (30/40/55 DMG)
    │       ├── moon_bolt_projectile.tscn
    │       ├── ember_bloom_projectile.gd    # Đạn lửa 380 px/s, nổ AoE 110 px (22/30/40 DMG, chống đòn trùng)
    │       ├── ember_bloom_projectile.tscn
    │       ├── frost_shard_projectile.gd    # Đạn băng 650 px/s, làm chậm quái 35% trong 2s (20/28/38 DMG)
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
    │   ├── spell_hotbar.gd                  # [MỚI M5] Controller thanh chọn phép 3 ô [1], [2], [3] & nút [U]
    │   ├── spell_hotbar.tscn                # [MỚI M5] Scene thanh hotbar hiển thị highlight, cooldown, MP, Lv
    │   ├── game_ui.gd                       # Tích hợp hotbar, hiển thị thông báo nâng cấp phép
    │   ├── game_ui.tscn                     # CanvasLayer HUD, Bars, Dialogue, PauseMenu, Hotbar
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập
    │   ├── main_menu.gd                     # Màn hình chính
    │   └── main_menu.tscn
    └── world\
        ├── magic_gate.gd                    # Cổng Ma Pháp tại X=4200
        ├── magic_gate.tscn                  # Scene Cổng Ma Pháp rào chắn vật lý
        ├── noctis_forest.gd                 # Kết nối SpellHotbar, Boss, Arena, Checkpoint
        └── noctis_forest.tscn               # Màn chơi thế giới đầy đủ
```

---

## 2. Thông số 3 Kỹ năng Ma pháp (Milestone M5)

| Thuộc tính | 1. Nguyệt Quang Đạn (`moon_bolt`) | 2. Tinh Hỏa Bùng Nổ (`ember_bloom`) | 3. Hàn Tinh Tiễn (`frost_shard`) |
| :--- | :---: | :---: | :---: |
| **Phím tắt chọn** | **Phím [1]** | **Phím [2]** | **Phím [3]** |
| **Phím thi triển** | **Phím [K]** | **Phím [K]** | **Phím [K]** |
| **Tiêu hao MP** | **12 MP** | **18 MP** | **15 MP** |
| **Thời gian hồi (CD)** | **0.5 giây** (Độc lập) | **1.0 giây** (Độc lập) | **0.7 giây** (Độc lập) |
| **Tốc độ đạn** | **550 px/s** | **380 px/s** | **650 px/s** |
| **Cơ chế đòn đánh** | Đơn mục tiêu, đạn bay thẳng, tan biến khi chạm mục tiêu | Bắn cầu lửa phát nổ diện rộng **bán kính 110 px**, chống sát thương trùng | Đạn băng sắc bén, **làm chậm 35% tốc độ quái vật** trong **2.0 giây** |
| **Miễn nhiễm làm chậm** | — | — | **Boss Lunareth miễn nhiễm hoàn toàn** với hiệu ứng làm chậm |
| **Sát thương Cấp 1** | **30 DMG** | **22 DMG** | **20 DMG** |
| **Sát thương Cấp 2** | **40 DMG** | **30 DMG** | **28 DMG** |
| **Sát thương Cấp 3** | **55 DMG** | **40 DMG** | **38 DMG** |
| **Chi phí nâng Cấp 2** | **3 Tinh thể Ma lực** (`mana_shard`) | **3 Tinh thể Ma lực** (`mana_shard`) | **3 Tinh thể Ma lực** (`mana_shard`) |
| **Chi phí nâng Cấp 3** | **6 Tinh thể Ma lực** (`mana_shard`) | **6 Tinh thể Ma lực** (`mana_shard`) | **6 Tinh thể Ma lực** (`mana_shard`) |

---

## 3. Hệ thống Nâng cấp Phép & Ràng buộc Chiến thuật

- **Phím tắt nâng cấp:** **Phím [U]** (hoặc nhấp trực tiếp nút `[U] Nâng cấp` trên giao diện Hotbar).
- **Nguyên liệu:** Tiêu hao `mana_shard` (Tinh thể Ma lực) nhặt được từ việc tiêu diệt quái vật tha hóa trong Rừng Noctis.
- **Ràng buộc chiến thuật (Bảo vệ tính cân bằng):**
  1. **Chặn nâng cấp trong trận chiến Boss:** Khi Boss Lunareth đang giao chiến, người chơi không thể nâng cấp phép để tránh gian lận sức mạnh giữa trận.
  2. **Chặn nâng cấp khi đã chết:** Trạng thái `DEAD` vô hiệu hóa mọi thao tác nâng cấp.
  3. **Chặn nâng cấp khi đang Pause / Mở Hội thoại / Mở Túi đồ.**
  4. **Chặn nâng cấp khi đã đạt Cấp tối đa (Cấp 3).**
  5. **Thông báo hệ thống:** Mọi kết quả nâng cấp thành công hoặc lý do thất bại đều được hiển thị qua `GameUI.show_notification()`.

---

## 4. Thanh chọn phép (Spell Hotbar UI)

- Tọa lạc ở đáy màn hình chính giữa (Bottom-Center), không che chắn thanh HP/MP bên góc trái hay Quest Panel góc phải.
- Gồm 3 thẻ phép đại diện:
  + **Viền sáng (Highlight):** Nhận diện phép thuật đang kích hoạt.
  + **Overlay & Số đếm hồi chiêu:** Hiển thị lớp phủ tối kèm thời gian hồi độc lập `X.Xs` khi phép đang cooldown.
  + **Thông tin trực quan:** Icon màu sắc, nhãn phím `[1]`, `[2]`, `[3]`, cấp độ hiện tại `Lv.X`, lượng tiêu hao `X MP`.
  + **Tương tác chuột:** Cho phép nhấp chuột trái vào từng ô để đổi phép, hoặc nhấp nút `[U]` để nâng cấp nhanh.

---

## 5. Hệ thống Lưu / Tải Dữ liệu v1.2.0 & Tính Tương thích Ngược

- **Định danh phiên bản mới:** `save_version: "1.2.0"`.
- **Cấu trúc khối ma pháp:**
  ```json
  "spellbook": {
      "selected_spell": "ember_bloom",
      "known_spells": ["moon_bolt", "ember_bloom", "frost_shard"],
      "spell_levels": {
          "moon_bolt": 3,
          "ember_bloom": 1,
          "frost_shard": 1
      }
  }
  ```
- **Tương thích ngược hoàn hảo:**
  + Hỗ trợ load các file save cũ phiên bản `1.0.0` (M3.2) và `1.1.0` (M4).
  + Khi load save cũ thiếu khối `"spellbook"`, hệ thống tự động khởi tạo mặc định 3 phép thuật cơ bản ở Cấp 1, chọn sẵn `moon_bolt`, người chơi tiếp tục trải nghiệm mà không bị crash hay mất dữ liệu.
- **Cách ly dữ liệu kiểm thử 100%:**
  + Bộ test sử dụng đường dẫn `user://noctelyra_m5_test.json`.
  + File save thật của người chơi `user://noctelyra_slot1.json` được bảo vệ nguyên vẹn 100%, kiểm tra đối chiếu MD5 checksum trước và sau test không đổi.

---

## 6. Báo cáo Kiểm thử Tự động Tổng hợp trên Godot 4.3 Engine

Tất cả các bộ test đều chạy trong môi trường Engine thực tế (`Godot_v4.3-stable_win64_console.exe --headless`):

```text
========================================================================================
 BỘ KIỂM THỬ                         | SỐ TEST   | KẾT QUẢ      | MÃ THOÁT (EXIT CODE)
----------------------------------------------------------------------------------------
 test_m5_flow.gd (Ma pháp M5)        | 85 tests  | PASS 100%    | 0
 test_m4_flow.gd (Boss Lunareth M4)  | 87 tests  | PASS 100%    | 0
 test_m3_2_flow.gd (Save/Load M3.2)  | 50 tests  | PASS 100%    | 0
 test_m2_1_flow.gd (NPC & Quest M2)  | 42 tests  | PASS 100%    | 0
========================================================================================
 TỔNG CỘNG                           | 264 tests | PASS 100%    | HOÀN HẢO KHÔNG LỖI
========================================================================================
```

---

## 7. Hướng dẫn Điều khiển & Trải nghiệm

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

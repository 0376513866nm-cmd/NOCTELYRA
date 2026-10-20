# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M6.1 STABILIZATION: World Expansion & Camera/UI Fixes)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M6.1 STABILIZATION)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu kiến trúc, bản vá M6.1 & kết quả kiểm thử
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M6.1 Final)
├── test_m6_flow.gd                 # [M6.1] Kịch bản kiểm thử 19 nhóm tính năng (117/117 tests PASS 100%)
├── test_m5_flow.gd                 # Kịch bản kiểm thử 26 nhóm tính năng ma pháp (100/100 tests PASS 100%)
├── test_m4_flow.gd                 # Kịch bản kiểm thử 17 hạng mục Boss M4 (87/87 tests PASS 100%)
├── test_m3_2_flow.gd               # Kịch bản kiểm thử M3.2 (50/50 tests PASS 100%)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (41/41 tests PASS 100%)
├── test_m3_flow.gd                 # Kịch bản kiểm thử M3 (67/67 tests PASS 100%)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử M2.1 (42/42 tests PASS 100%)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Main Scene: main_menu.tscn (1280x720, forward_plus, autoload ZoneManager)
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
    │   │   ├── player.gd                    # FSM Player, dọn sạch đạn khi chết/hồi sinh, combat, di chuyển
    │   │   ├── player.tscn                  # Scene Player có SpellbookComponent & InventoryComponent
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy đôi, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC đa năng: Elyra (Noctis), Kaelis (Elyndra), Rhaek (Vharok)
    │   │   └── npc.tscn                     # Scene NPC (collision_layer = 0: xuyên người mượt mà)
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
    ├── magic\                               # HỆ THỐNG PHÁP THUẬT CHIẾN ĐẤU
    │   ├── spell_definition.gd              # Custom Resource: tỉ lệ tăng cấp unrounded (100%, 115%, 130%), giá nâng cấp
    │   ├── spell_database.gd                # Thông số thiết kế chuẩn M5.1 (15 MP/0.6s, 25 MP/2.0s, 18 MP/1.0s)
    │   ├── spellbook_component.gd           # Quản lý danh sách phép, phép đang chọn, cấp độ, cooldown độc lập
    │   └── projectiles\
    │       ├── moon_bolt_projectile.gd      # Đạn ánh trăng 550 px/s, đơn mục tiêu (30.0 / 34.5 / 39.0 DMG)
    │       ├── moon_bolt_projectile.tscn
    │       ├── ember_bloom_projectile.gd    # Đạn lửa 380 px/s, nổ AoE 110 px (22.0 / 25.3 / 28.6 DMG)
    │       ├── ember_bloom_projectile.tscn
    │       ├── frost_shard_projectile.gd    # Đạn băng 650 px/s, làm chậm quái 35% trong 2s (20.0 / 23.0 / 26.0 DMG)
    │       └── frost_shard_projectile.tscn
    ├── interaction\
    │   ├── interaction_coordinator.gd       # Bộ điều phối Input tập trung cho NPC, Cổng dịch chuyển & Cổ Tinh Thạch
    │   └── interaction_component.gd         # Area2D tương tác nhận diện Player phạm vi gần
    ├── inventory\                           # HỆ THỐNG VẬT PHẨM & TRANG BỊ
    │   ├── item_definition.gd               # Resource định nghĩa vật phẩm chuẩn
    │   ├── item_database.gd                 # Đăng ký mana_shard, health_potion, moonsteel_sword, moon_amulet, eclipse_fragment
    │   ├── inventory_component.gd           # Quản lý 16 ô túi đồ, clear(), remove_item_by_id()
    │   ├── equipment_component.gd           # Quản lý 2 ô trang bị & tính toán lại chỉ số
    │   ├── inventory_ui.gd                  # Controller giao diện túi đồ, fix lambda connect đa trùng lặp
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ
    ├── loot\                                # HỆ THỐNG RƠI ĐỒ VÀ NHẶT VẬT PHẨM
    │   ├── loot_table.gd                    # Resource định nghĩa bảng tỷ lệ rơi đồ
    │   ├── item_pickup.gd                   # Gán pickup_id ổn định, tự hủy nếu đã nhặt trước đó
    │   └── item_pickup.tscn                 # Scene vật phẩm rơi với hiệu ứng nhấp nhô lơ lửng
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # Quản lý quest, lưu enemy_id chuỗi ổn định xuyên suốt
    ├── save\                                # HỆ THỐNG LƯU / TẢI TIẾN TRÌNH OFFLINE
    │   └── save_manager.gd                  # Version 1.3.0, lưu current_zone_id & zone_states, tương thích 1.0.0 -> 1.2.0
    ├── ui\
    │   ├── spell_hotbar.gd                  # Controller thanh chọn phép 3 ô [1], [2], [3] & nút [U]
    │   ├── spell_hotbar.tscn                # Scene thanh hotbar hiển thị highlight, cooldown, MP, Lv
    │   ├── game_ui.gd                       # Tích hợp hotbar, thông báo Zone Banner & nhãn ZoneLabel
    │   ├── game_ui.tscn                     # CanvasLayer HUD, Bars, Dialogue, PauseMenu, Hotbar, Zone HUD
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập
    │   ├── main_menu.gd                     # Màn hình chính (Continue nạp trực tiếp scene khu vực đã lưu)
    │   └── main_menu.tscn
    └── world\                               # HỆ THỐNG MỞ RỘNG THẾ GIỚI & DỊCH CHUYỂN KHU VỰC
        ├── zone_definition.gd               # Resource metadata khu vực (zone_id, name, subtitle, scene_path, default_spawn)
        ├── zone_spawn_point.gd              # Điểm xuất hiện an toàn trong khu vực (spawn_point_id, facing_direction)
        ├── zone_portal.gd                   # Cổng dịch chuyển liên khu vực, điều kiện mở khóa, kiểm tra tương tác
        ├── zone_portal.tscn                 # Scene Area2D Cổng dịch chuyển với prompt nhấp nháy
        ├── ancient_crystal.gd               # Cổ Tinh Thạch tương tác đọc truyền thuyết (Lore object)
        ├── ancient_crystal.tscn             # Scene Cổ Tinh Thạch với visual tinh thể phát sáng
        ├── base_zone.gd                     # [M6.1] Tách biệt setup_signals, setup_camera, setup_ui độc lập
        ├── zone_manager.gd                  # [M6.1] Snap camera tức thì khi spawn, gắn Player vào inventory_ui
        ├── magic_gate.gd                    # Cổng Ma Pháp tại X=4200 (khóa arena Boss Lunareth)
        ├── magic_gate.tscn                  # Scene Cổng Ma Pháp rào chắn vật lý
        ├── noctis_forest.gd                 # [M6.1] Rừng Noctis kế thừa BaseZone, setup_ui độc lập
        ├── noctis_forest.tscn
        ├── elyndra_glade.gd                 # [Zone 2] Thánh Lâm Elyndra (0-2400px), NPC Kaelis, Cổ Tinh Thạch
        ├── elyndra_glade.tscn               # [M6.1] Bổ sung RemoteTransform2D bám sát Camera2D
        ├── vharok_outpost.gd                # [Zone 3] Tiền Đồn Vharok (0-2400px), NPC Rhaek
        └── vharok_outpost.tscn              # [M6.1] Bổ sung RemoteTransform2D bám sát Camera2D
```

---

## 2. Các Bản Vá Chính trong Milestone M6.1

### 2.1. Sửa Cơ Chế Camera Bám Player tại Elyndra & Vharok
- **Nguyên nhân trước M6.1:** Scene `elyndra_glade.tscn` và `vharok_outpost.tscn` có node `Camera2D` nằm ở gốc scene nhưng thiếu node `RemoteTransform2D` dưới `Player`, khiến camera đứng yên tại $(300, 630)$ khi Player chạy, nhảy hoặc di chuyển khắp bản đồ.
- **Giải pháp:**
  1. Thêm `RemoteTransform2D` vào node `Player` trong cả 2 scene, cấu hình `remote_path = NodePath("../../Camera2D")` và `update_scale = false`.
  2. Bổ sung hàm `setup_camera()` và `snap_camera_to_player()` trong [`base_zone.gd`](file:///d:/project/game/NOCTELYRA/src/world/base_zone.gd).
  3. Trong [`zone_manager.gd`](file:///d:/project/game/NOCTELYRA/src/world/zone_manager.gd), khi đặt Player tại điểm spawn (`_place_player_at_spawn`), camera lập tức được cập nhật tọa độ trùng với điểm spawn và gọi `cam.reset_smoothing()`.
  4. Đảm bảo khi dịch chuyển từ Vharok sang Elyndra tại $X = 2120$, camera cập nhật ngay tức thì tại $X = 2120$, loại bỏ hoàn toàn hiện tượng camera đứng yên ở $X=300$ hoặc trượt chậm trên màn hình.

### 2.2. Ổn Định Vòng Đời Khởi Tạo UI (Decoupled UI Initialization)
- **Nguyên nhân trước M6.1:** Logic kết nối `game_ui.retry_requested` đi kèm khối khởi tạo `inventory_ui.setup_player()` và `spell_hotbar.set_spellbook()`. Khi được gọi trong `_enter_tree()`, các node `@onready` của `GameUI` chưa sẵn sàng; đến khi `_ready()` chạy thì cờ `is_connected` đã là `true` khiến toàn bộ khối khởi tạo UI bị bỏ qua.
- **Giải pháp:**
  1. Tách biệt hoàn toàn `setup_signals()` (kết nối tín hiệu an toàn với `is_connected`) và `setup_ui()` (gắn đối tượng Player, Spellbook, cập nhật thanh HP/MP/Gold/Quest/Zone).
  2. `setup_ui()` được gọi sau khi các node con đã hoàn tất `_ready()`, cho phép gọi nhiều lần an toàn sau khi dịch chuyển portal, Save/Continue hoặc Retry.
  3. Sửa lỗi kết nối lambda không tên trong `inventory_ui.gd` bằng phương thức có tên `_on_equipment_changed`, ngăn ngừa tạo nhiều kết nối trùng lặp.

### 2.3. Bổ Sung Kiểm Thử M6.1 & Phân Biệt Test Rõ Ràng
- Nâng cấp [`test_m6_flow.gd`](file:///d:/project/game/NOCTELYRA/test_m6_flow.gd) lên **117 bài kiểm tra (100% PASS)**:
  + Kiểm tra Camera Elyndra bám sát Player khi chạy và nhảy lên platform cao.
  + Kiểm tra Camera Vharok bám sát Player.
  + Kiểm tra Camera snap tức thì tại $X=2120$ khi đi từ Vharok về Elyndra.
  + Kiểm tra `inventory_ui.player` và `spell_hotbar._spellbook` được trỏ chính xác vào instance Player của từng scene sau khi đổi màn, nạp save và bấm Retry.
  + Kiểm tra vùng tương tác Portal (ngoài vùng tương tác -> từ chối, đang cooldown -> từ chối, trong vùng và hết cooldown -> cho phép).
  + **Phân biệt rõ ràng:**
    * **Group 18:** `Integration Test: Simulated State Portal Chain` (kiểm thử chuỗi dịch chuyển mô phỏng trạng thái).
    * **Group 19:** `Genuine End-to-End Gameplay Loop` (chơi thực tế từ nhận quest NPC Elyra $\rightarrow$ diệt 3 quái $\rightarrow$ trả quest $\rightarrow$ mở cổng MagicGate $\rightarrow$ kích hoạt Boss Lunareth $\rightarrow$ đánh qua Phase 2 $\rightarrow$ hạ gục Boss $\rightarrow$ bước qua Moonveil Portal sang Elyndra $\rightarrow$ qua Vharok $\rightarrow$ lưu game).

---

## 3. Báo Cáo Kiểm Thử Tự Động Toàn Diện trên Godot 4.3 Engine

Tất cả các bộ test đều chạy trực tiếp trên engine (`Godot_v4.3-stable_win64_console.exe --headless`):

```text
========================================================================================
 BỘ KIỂM THỬ                         | SỐ TEST    | KẾT QUẢ      | MÃ THOÁT (EXIT CODE)
----------------------------------------------------------------------------------------
 test_m6_flow.gd (Thế giới & M6.1)   | 117 tests  | PASS 100%    | 0
 test_m5_flow.gd (Ma pháp M5.1)      | 100 tests  | PASS 100%    | 0
 test_m4_flow.gd (Boss Lunareth M4)  |  87 tests  | PASS 100%    | 0
 test_m3_2_flow.gd (Save/Load M3.2)  |  50 tests  | PASS 100%    | 0
 test_m2_1_flow.gd (NPC & Quest M2)  |  42 tests  | PASS 100%    | 0
========================================================================================
 TỔNG CỘNG                           | 396 tests  | PASS 100%    | HOÀN HẢO KHÔNG LỖI
========================================================================================
```

---

## 4. Hướng dẫn Điều khiển & Trải nghiệm

| Phím bấm | Hành động |
| :--- | :--- |
| **A / D** | Di chuyển trái / phải (Camera bám sát mượt mà) |
| **Space** | Nhảy đơn / Nhảy đôi (Double Jump) |
| **Shift** | Lướt nhanh (Dash) |
| **J** | Tấn công cận chiến (Chém kiếm) |
| **K** | Thi triển phép thuật đang chọn (Bắn ma pháp, tiêu hao MP) |
| **1, 2, 3** | Chọn phép thuật: [1] Nguyệt Quang Đạn \| [2] Tinh Hỏa Bùng Nổ \| [3] Hàn Tinh Tiễn |
| **U** | Nâng cấp phép thuật đang chọn (Tiêu hao Tinh thể Ma lực `mana_shard`) |
| **E** | Tương tác NPC (Elyra, Kaelis, Rhaek) / Kích hoạt Cổng dịch chuyển / Đọc Cổ Tinh Thạch |
| **I** | Mở / Đóng túi đồ (Inventory) & Bảng trang bị |
| **Esc** | Tạm dừng trò chơi (Pause Menu) / Đóng túi đồ / Đóng hội thoại |

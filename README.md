# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M8: Character Origins & Progression)

Dự án game Action RPG 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Milestone M8 FINAL)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu kiến trúc Milestone M8 & kết quả kiểm thử
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M8 Final)
├── test_m8_flow.gd                 # [M8] Kịch bản kiểm thử 18 nhóm tính năng Chủng tộc & Tiến trình (158/158 tests PASS 100%)
├── test_m7_flow.gd                 # Kịch bản kiểm thử vùng đất mở rộng & nhiệm vụ (156/156 tests PASS 100%)
├── test_m6_flow.gd                 # Kịch bản kiểm thử thế giới mở rộng & cổng dịch chuyển (117/117 tests PASS 100%)
├── test_m5_flow.gd                 # Kịch bản kiểm thử 26 nhóm tính năng ma pháp (100/100 tests PASS 100%)
├── test_m4_flow.gd                 # Kịch bản kiểm thử 17 hạng mục Boss M4 (87/87 tests PASS 100%)
├── test_m3_2_flow.gd               # Kịch bản kiểm thử M3.2 (50/50 tests PASS 100%)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (41/41 tests PASS 100%)
├── test_m3_flow.gd                 # Kịch bản kiểm thử M3 (67/67 tests PASS 100%)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử M2.1 (42/42 tests PASS 100%)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Cấu hình dự án, Input Map (thêm phím C: character_sheet)
├── run_game.bat                    # 1-Click chạy game test ngay lập tức
├── open_editor.bat                 # 1-Click mở Godot Editor
├── export_code_for_ai.bat          # 1-Click gom toàn bộ source code thành file CODE_EXPORT.txt
│
├── assets\
│   └── sprites\
│       └── player\
│           ├── player_idle_atlas.png         # Atlas nhân vật Idle
│           ├── player_run_atlas.png          # Atlas nhân vật Run
│           └── ...
│
└── src\
    ├── actors\
    │   ├── player\
    │   │   ├── player.gd                    # FSM Player, tích hợp Progression & Stats, Race Visuals, khóa điều khiển UI
    │   │   ├── player.tscn                  # Scene Player chứa PlayerProgressionComponent & PlayerStatsComponent
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy đôi, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC: Elyra (Noctis), Kaelis (Elyndra), Rhaek (Vharok)
    │   │   └── npc.tscn                     # Scene NPC xuyên người mượt mà (collision_layer = 0)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI: MELEE, LUNGE, RANGED, Leash, Stop on Player Death, rớt drop_item_id
    │       ├── enemy.tscn                   # Scene Enemy mô đun hóa (Health, Hitbox, Hurtbox, Visual)
    │       ├── enemy_definition.gd          # Custom Resource EnemyDefinition (5 presets cấu hình)
    │       ├── enemy_projectile.gd          # Đạn ma pháp / cầu lửa của quái tầm xa (mask 2: Player hurtbox)
    │       ├── enemy_projectile.tscn        # Scene đạn quái vật
    │       └── enemy_visual.gd              # Bộ điều khiển hiển thị 5 trạng thái (idle, move, telegraph, attack, hit, death)
    ├── boss\                                # MODULE BOSS LUNARETH — LINH LỘC NGUYỆT THỰC
    │   ├── boss_lunareth.gd                 # Boss 2 Phase, shockwave, telegraph, bất tử lúc chuyển giai đoạn
    │   ├── boss_lunareth.tscn               # Scene Boss với HealthComponent (320 HP)
    │   ├── boss_visual.gd                   # Visual chuyển phase, aura tím, telegraph
    │   ├── boss_shockwave.gd                # Projectile group 'boss_projectiles'
    │   └── boss_shockwave.tscn              # Scene projectile sóng xung kích
    ├── combat\
    │   ├── combat_component.gd              # Quản lý combo kiếm, thời gian hồi đòn
    │   ├── damage_info.gd                   # DTO sát thương (amount, source, knockback)
    │   ├── health_component.gd              # Quản lý HP/MP, invulnerability timer, hồi MP
    │   ├── hitbox.gd                        # Vùng gây sát thương (chống đếm trùng reset_hits)
    │   └── hurtbox.gd                       # Vùng nhận sát thương
    ├── inventory\
    │   ├── item_database.gd                 # Cơ sở dữ liệu vật phẩm (thêm ember_core Lõi Tàn Hỏa)
    │   ├── item_definition.gd               # Custom Resource ItemDefinition
    │   ├── inventory_component.gd           # Túi đồ 16 ô, stack item, kiểm tra can_receive_items an toàn
    │   ├── equipment_component.gd           # Quản lý 2 ô trang bị (weapon, accessory), đồng bộ qua PlayerStatsComponent
    │   ├── inventory_ui.gd                  # UI túi đồ 16 ô
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ
    ├── magic\
    │   ├── spell_database.gd                # Danh mục phép thuật: moon_bolt, ember_bloom, frost_shard
    │   ├── spell_definition.gd              # Resource cấu hình phép
    │   ├── spellbook_component.gd           # Quản lý sách phép, cấp độ, nâng cấp, hệ số magic_damage_multiplier
    │   └── projectiles\                     # Đạn phép thuật của Player
    ├── progression\                         # [MỚI M8] MODULE TIẾN TRÌNH & KINH NGHIỆM
    │   ├── exp_database.gd                  # Quản lý mức thưởng EXP tập trung (quái vật, Boss, nhiệm vụ)
    │   └── player_progression_component.gd  # Quản lý Cấp độ (1..10), EXP curve, rollover, chống nhận trùng
    ├── quest\
    │   ├── quest_data.gd                    # Nhiệm vụ chính của Elyra (M0–M6)
    │   ├── quest_definition.gd              # Resource nhiệm vụ phụ: reward_exp, KILL_ENEMY_TYPE & COLLECT_ITEMS
    │   ├── quest_journal_component.gd       # Nhật ký nhiệm vụ, cộng EXP thưởng khi hoàn thành
    │   └── quest_manager.gd                 # Quản lý nhiệm vụ chính và Vàng
    ├── race\                                # [MỚI M8] MODULE CHỦNG TỘC (RACE SYSTEM)
    │   ├── race_definition.gd               # Custom Resource RaceDefinition: lore, chỉ số cơ bản, pros/cons, colors
    │   └── race_database.gd                 # Đăng ký 3 chủng tộc: Nhân tộc (human), Tinh Linh (elf), Quỷ thú (demon_beast)
    ├── save\
    │   └── save_manager.gd                  # [M8 v1.5.0] Lưu trữ race_id, level, current_exp, claimed_exp_sources, backward v1.0-v1.4
    ├── stats\                               # [MỚI M8] MODULE CHỈ SỐ THỐNG NHẤT (UNIFIED STATS)
    │   └── player_stats_component.gd        # Nguồn chân lý duy nhất (Single Source of Truth): Base + Growth + Gear
    ├── ui\
    │   ├── character_creation_ui.gd         # Giao diện chọn chủng tộc khi bắt đầu Game Mới (New Game Flow)
    │   ├── character_creation_ui.tscn
    │   ├── character_sheet_ui.gd            # Giao diện Thông Tin Nhân Vật (Phím C): Cấp, EXP, chỉ số, trang bị
    │   ├── character_sheet_ui.tscn
    │   ├── game_ui.gd                       # HUD chính: kết nối Q, I, C, Esc, xử lý Grace Cooldown chống chém vô ý
    │   ├── game_ui.tscn
    │   ├── main_menu.gd                     # Menu chính: New Game mở Character Creation, Continue nạp bản lưu
    │   ├── main_menu.tscn
    │   ├── quest_journal_ui.gd              # UI Sổ Nhiệm Vụ (Phím Q)
    │   ├── quest_journal_ui.tscn
    │   ├── spell_hotbar.gd                  # Thanh kỹ năng ma pháp HUD
    │   └── spell_hotbar.tscn
    └── world\
        ├── base_zone.gd                     # Thế giới cơ sở: kết nối thăng cấp, cộng EXP quái, khởi tạo tộc
        ├── zone_manager.gd                  # Chuyển cảnh, bảo toàn tiến trình tộc, cấp, EXP qua các vùng
        ├── zone_definition.gd               # Đăng ký thông tin và scene 3 khu vực
        ├── zone_portal.gd                   # Cổng ma pháp dịch chuyển giữa các vùng
        ├── zone_portal.tscn                 # Scene cổng dịch chuyển
        ├── ancient_crystal.gd               # Cổ Tinh Thạch tại Elyndra
        ├── noctis_forest.gd                 # Vùng 1: Rừng Noctis & Đấu trường Boss (Thưởng 150 EXP Lunareth)
        ├── noctis_forest.tscn
        ├── elyndra_glade.gd                 # Vùng 2: Thánh Lâm Elyndra (Kaelis, Mooncap, Mana Wisp)
        ├── elyndra_glade.tscn
        ├── vharok_outpost.gd                # Vùng 3: Tiền Đồn Vharok (Rhaek, Ashfang Wolf, Ember Lizard)
        └── vharok_outpost.tscn
```

---

## 2. Hệ Thống Chủng Tộc & Chỉ Số Cơ Bản (Milestone M8)

| Thuộc tính | Nhân tộc (`human`) | Tinh Linh tộc (`elf`) | Quỷ tộc bán thú (`demon_beast`) |
| :--- | :--- | :--- | :--- |
| **Danh hiệu** | Người Bảo Vệ Làng Ánh Nguyệt | Người Gìn Giữ Tinh Mạch Elyndra | Chiến Binh Dãy Núi Tro Tàn |
| **Sinh Lực (HP)** | 100 HP | 90 HP | **125 HP** |
| **Ma Lực (MP)** | 60 MP | **80 MP** | 50 MP |
| **Tấn Công (ATK)** | 25 ATK | 23 ATK | **30 ATK** |
| **Hồi MP** | 5.0 MP/s | **7.0 MP/s** | 4.0 MP/s |
| **Tốc độ chạy** | 270 px/s | **275 px/s** | 260 px/s |
| **Hệ số Ma pháp** | 1.0x (100%) | **1.1x (+10% sát thương phép)** | 1.0x (100%) |
| **Đặc trưng thị giác** | Khăn choàng lam/bạc | Tai nhọn ngọc bích | Cặp sừng đỏ thẫm & Đuôi thú |

---

## 3. Hệ Thống Tăng Trưởng & Công Thức EXP

1. **Công thức EXP chuẩn:**
   $$\text{EXP Yêu Cầu}(\text{level}) = 60 + 40 \times (\text{level} - 1)$$
   - Cấp 1 $\to$ 2: 60 EXP
   - Cấp 2 $\to$ 3: 100 EXP
   - Cấp 3 $\to$ 4: 140 EXP
   - Cấp 4 $\to$ 5: 180 EXP
   - Cấp 9 $\to$ 10: 380 EXP
   - Cấp 10: **Tối đa (Max Level)**, không tăng lên cấp 11, xóa EXP dư thừa.

2. **Tăng trưởng chỉ số mỗi cấp (Growth Per Level):**
   - **Max HP:** +10 HP / cấp
   - **Max MP:** +5 MP / cấp
   - **Sát thương vật lý (ATK):** +2 ATK / cấp

3. **Cơ chế Rollover & An Toàn Sinh Mệnh:**
   - Khi nhận lượng lớn EXP vượt ngưỡng, hệ thống tự động tính toán thăng nhiều cấp liên tiếp và bảo lưu chính xác phần EXP dư thừa còn lại.
   - Khi lên cấp, lượng Max HP/MP tăng thêm được cộng dồn tương ứng vào HP/MP hiện tại (Delta gain), tuyệt đối **không tự động hồi đầy máu (No full-heal exploit)** để giữ nguyên tính thử thách sinh tồn.

4. **Nguồn Thưởng EXP Tập Trung (`ExpDatabase`) & Chống Nhận Trùng:**
   - Quái thường: 20–30 EXP (Sói tha hóa 20, Nấm mộng 20, Tinh linh tha hóa 25, Sói nanh tro 25, Thằn lằn tro 30).
   - Boss Lunareth: 150 EXP.
   - Nhiệm vụ: Elyra 50 EXP, Kaelis 60 EXP, Rhaek 70 EXP.
   - Mọi nguồn EXP đều được xác thực qua định danh nguồn (`claimed_exp_sources`), ngăn chặn tuyệt đối việc nhận lặp lại khi giao chiến lại hoặc nạp save.

---

## 4. Hệ Thống Giao Diện & Tương Tác (UI / UX)

1. **Luồng Khởi Tạo Nhân Vật (New Game Flow):**
   - Nhấn **New Game** tại Menu chính sẽ mở giao diện `CharacterCreationUI`.
   - Người chơi xem chi tiết lore, ưu/nhược điểm và bảng chỉ số của 3 tộc trước khi quyết định.
   - Nhấn **Quay Lại (Cancel):** Trở về Menu chính, **bảo toàn nguyên vẹn bản lưu hiện có**.
   - Nhấn **Xác Nhận (Confirm):** Bắt đầu New Game tại Rừng Noctis với chủng tộc đã chọn.

2. **Bảng Thông Tin Nhân Vật (`CharacterSheetUI` — Phím C):**
   - Mở/đóng bằng phím **C**, hiển thị trực quan: Chủng tộc, Cấp độ, Thanh tiến trình EXP %, Chỉ số HP/MP, ATK, Sát thương phép thuật, Hồi MP, Tốc độ chạy và 2 ô trang bị hiện tại.
   - Khóa toàn bộ input di chuyển và chiến đấu của Player khi bảng đang mở.

3. **Loại Trừ Lẫn Nhau & Grace Cooldown (Khắc Phục Lỗi Phím J):**
   - **Loại trừ lẫn nhau (Mutual Exclusivity):** Mở Bảng Nhân Vật (C) sẽ tự động đóng Túi Đồ (I) và Sổ Nhiệm Vụ (Q), và ngược lại.
   - **Khắc phục lỗi phím J chém gió vô ý:** Khi đóng bất kỳ giao diện nào (Journal, Inventory, Character Sheet), hệ thống kích hoạt **Grace Cooldown ngắn (0.15s)** và tiêu thụ hoàn toàn event input, đảm bảo Player không tung đòn đánh vô ý thức trên frame đóng UI.

---

## 5. Định Dạng Bản Lưu v1.5.0 & Tương Thích Ngược

- Schema Save v1.5.0 lưu đầy đủ: `race_id`, `progression` (`level`, `current_exp`, `claimed_exp_sources`).
- **Thứ tự nạp an toàn:** (1) Khôi phục Race & Level $\to$ (2) Nạp Trang bị $\to$ (3) Tính lại Final Stats thống nhất $\to$ (4) Khôi phục HP/MP hiện tại giới hạn theo Max mới.
- **Tương thích ngược hoàn hảo:** Bản lưu cũ v1.0.0 – v1.4.0 tự động gán chủng tộc Nhân tộc (`human`), Cấp 1, 0 EXP, danh sách nguồn rỗng (không hồi tố nhiệm vụ cũ), và giữ nguyên toàn bộ tiến trình trang bị, thế giới và Boss.

---

## 6. Báo Cáo Kiểm Thử Tự Động Toàn Diện trên Godot 4.3 Engine

Tất cả các bộ test đều chạy trực tiếp trên engine (`Godot_v4.3-stable_win64_console.exe --headless`):

```text
========================================================================================
 BỘ KIỂM THỬ                         | SỐ TEST    | KẾT QUẢ      | MÃ THOÁT (EXIT CODE)
----------------------------------------------------------------------------------------
 test_m8_flow.gd (Chủng tộc & Level) | 158 tests  | PASS 100%    | 0
 test_m7_flow.gd (Khu vực & M7.1)    | 156 tests  | PASS 100%    | 0
 test_m6_flow.gd (Thế giới & M6.1)   | 117 tests  | PASS 100%    | 0
 test_m5_flow.gd (Ma pháp M5.1)      | 100 tests  | PASS 100%    | 0
 test_m4_flow.gd (Boss Lunareth M4)  |  87 tests  | PASS 100%    | 0
 test_m3_2_flow.gd (Save/Load M3.2)  |  50 tests  | PASS 100%    | 0
 test_m2_1_flow.gd (NPC & Quest M2)  |  42 tests  | PASS 100%    | 0
========================================================================================
 TỔNG CỘNG                           | 710 tests  | PASS 100%    | HOÀN HẢO KHÔNG LỖI
========================================================================================
```

---

## 7. Hướng dẫn Điều khiển

| Phím bấm | Hành động |
| :--- | :--- |
| **A / D** | Di chuyển trái / phải (Camera bám sát mượt mà) |
| **Space** | Nhảy đơn / Nhảy đôi (Double Jump) |
| **Shift** | Lướt nhanh (Dash) |
| **J** | Tấn công cận chiến (Chém kiếm) \| Đóng UI khi đang mở |
| **K** | Thi triển phép thuật đang chọn (Bắn ma pháp, tiêu hao MP) |
| **1, 2, 3** | Chọn phép thuật: [1] Nguyệt Quang Đạn \| [2] Tinh Hỏa Bùng Nổ \| [3] Hàn Tinh Tiễn |
| **U** | Nâng cấp phép thuật đang chọn (Tiêu hao Tinh thể Ma lực `mana_shard`) |
| **E** | Tương tác NPC (Elyra, Kaelis, Rhaek) / Cổng dịch chuyển / Cổ Tinh Thạch |
| **C** | **Mở / Đóng Bảng Thông Tin Nhân Vật (Character Sheet)** |
| **Q** | **Mở / Đóng Sổ Nhiệm Vụ (Quest Journal)** |
| **I** | Mở / Đóng túi đồ (Inventory) & Bảng trang bị |
| **Esc** | Tạm dừng (Pause Menu) / Đóng bảng đang mở / Đóng hội thoại |

# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M7.1: Gameplay Stabilization)

Dự án game Action RPG 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Milestone M7.1)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu kiến trúc Milestone M7.1 & kết quả kiểm thử
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M7.1 Final)
├── test_m7_flow.gd                 # [M7.1] Kịch bản kiểm thử 14 nhóm tính năng và ổn định gameplay (156/156 tests PASS 100%)
├── test_m6_flow.gd                 # Kịch bản kiểm thử thế giới mở rộng & cổng dịch chuyển (117/117 tests PASS 100%)
├── test_m5_flow.gd                 # Kịch bản kiểm thử 26 nhóm tính năng ma pháp (100/100 tests PASS 100%)
├── test_m4_flow.gd                 # Kịch bản kiểm thử 17 hạng mục Boss M4 (87/87 tests PASS 100%)
├── test_m3_2_flow.gd               # Kịch bản kiểm thử M3.2 (50/50 tests PASS 100%)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (41/41 tests PASS 100%)
├── test_m3_flow.gd                 # Kịch bản kiểm thử M3 (67/67 tests PASS 100%)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử M2.1 (42/42 tests PASS 100%)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Cấu hình dự án, Input Map (thêm phím Q: quest_journal)
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
    │   │   ├── player.gd                    # FSM Player, tích hợp QuestJournalComponent, khóa điều khiển khi mở Journal
    │   │   ├── player.tscn                  # Scene Player có đủ các Component chiến đấu và dữ liệu
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
    │   ├── equipment_component.gd           # Quản lý 2 ô trang bị (weapon, accessory)
    │   ├── inventory_ui.gd                  # UI túi đồ 16 ô
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ
    ├── magic\
    │   ├── spell_database.gd                # Danh mục phép thuật: moon_bolt, ember_bloom, frost_shard
    │   ├── spell_definition.gd              # Resource cấu hình phép
    │   ├── spellbook_component.gd           # Quản lý sách phép, cấp độ, nâng cấp
    │   └── projectiles\                     # Đạn phép thuật của Player
    ├── quest\
    │   ├── quest_data.gd                    # Nhiệm vụ chính của Elyra (M0–M6)
    │   ├── quest_definition.gd              # Resource nhiệm vụ phụ: KILL_ENEMY_TYPE & COLLECT_ITEMS
    │   ├── quest_journal_component.gd       # Component quản lý nhật ký nhiệm vụ, chống kẹt diệt quái sớm, đồng bộ nhặt đồ
    │   └── quest_manager.gd                 # Quản lý nhiệm vụ chính và Vàng
    ├── save\
    │   └── save_manager.gd                  # [M7 v1.4.0] Ghi nguyên tử, lưu Quest Journal & _kill_history, backward-compatible
    ├── ui\
    │   ├── game_ui.gd                       # HUD chính, kết nối phím Q/J đóng mở Sổ Nhiệm Vụ, thoại NPC Kaelis/Rhaek
    │   ├── game_ui.tscn                     # CanvasLayer HUD, tích hợp QuestJournalUI
    │   ├── quest_journal_ui.gd              # UI Sổ Nhiệm Vụ: hiển thị 3 nhiệm vụ, tiến độ, phần thưởng, badge
    │   ├── quest_journal_ui.tscn            # Scene Sổ Nhiệm Vụ
    │   ├── spell_hotbar.gd                  # Thanh kỹ năng ma pháp HUD
    │   └── spell_hotbar.tscn                # Scene thanh kỹ năng ma pháp
    └── world\
        ├── base_zone.gd                     # Quản lý thế giới cơ sở, kết nối tín hiệu quái, hồi phục thế giới
        ├── zone_manager.gd                  # Chuyển cảnh, bảo toàn quest journal và dữ liệu người chơi
        ├── zone_definition.gd               # Đăng ký thông tin và scene 3 khu vực
        ├── zone_portal.gd                   # Cổng ma pháp dịch chuyển giữa các vùng
        ├── zone_portal.tscn                 # Scene cổng dịch chuyển
        ├── ancient_crystal.gd               # Cổ Tinh Thạch tại Elyndra
        ├── noctis_forest.gd                 # Vùng 1: Rừng Noctis & Đấu trường Boss
        ├── noctis_forest.tscn
        ├── elyndra_glade.gd                 # Vùng 2: Thánh Lâm Elyndra
        ├── elyndra_glade.tscn               # (Chứa NPC Kaelis, 3 Corrupted Mooncap, 2 Corrupted Mana Wisp)
        ├── vharok_outpost.gd                # Vùng 3: Tiền Đồn Vharok
        └── vharok_outpost.tscn              # (Chứa NPC Rhaek, 3 Ashfang Wolf, 2 Ember Lizard)
```

---

## 2. Các điểm cải tiến và khắc phục lỗi trong M7.1 Stabilization

1. **Khắc phục triệt để nguy cơ kẹt nhiệm vụ Kaelis (Softlock Prevention):**
   - Bổ sung `_kill_history` trong `QuestJournalComponent` để tự động ghi nhận mọi quái vật bị hạ gục trước khi nhận quest.
   - Khi nhận nhiệm vụ `quest_elyndra_cleansing`, hệ thống tự động đồng bộ số Mooncap đã diệt trước đó từ `_kill_history` và `defeated_enemy_ids` của bản đồ.
   - Nếu đã diệt 1, 2 hoặc cả 3 Mooncap trước khi nói chuyện với Kaelis, tiến độ lập tức được ghi nhận chính xác (1/3, 2/3, 3/3 `READY_TO_TURN_IN`) mà không bị kẹt 0/3.
   - Lịch sử diệt quái được serialize/deserialize nguyên vẹn trong Save v1.4.0.

2. **Sửa rơi đồ của Ember Lizard (Lõi Tàn Hỏa - Ember Core):**
   - Trong `Enemy._spawn_loot()`, tôn trọng thuộc tính `definition.drop_item_id` nếu có (đối với `ember_lizard` là `"ember_core"`), chỉ fallback về `"mana_shard"` nếu không cấu hình.
   - Khi Ember Lizard bị tiêu diệt, luôn sinh ra `ItemPickup` hợp lệ chứa `"ember_core"`.

3. **Xử lý túi đồ đầy khi trả quest (Atomic Turn-in):**
   - Bổ sung hàm `can_receive_items(items_to_add, items_to_remove)` trong `InventoryComponent` để mô phỏng chính xác không gian túi đồ sau khi trừ vật phẩm quest và cộng phần thưởng.
   - Cả `QuestJournalComponent.can_turn_in()`, `turn_in_quest()` và đối thoại NPC Kaelis/Rhaek đều kiểm tra điều kiện này.
   - Nếu túi đồ không đủ chỗ, từ chối giao dịch an toàn: không mất quest items, không trao vàng/đồ dang dở, không autosave lỗi, giữ nguyên trạng thái `READY_TO_TURN_IN` và hướng dẫn người chơi dọn chỗ trống.

4. **Khóa thao tác Player khi mở Quest Journal & Loại trừ lẫn nhau:**
   - Trong `Player._physics_process()`, kiểm tra `ui.is_quest_journal_open()` để khóa toàn bộ input di chuyển, nhảy, dash, tấn công cận chiến và niệm phép.
   - Khi đóng Journal (phím Q, phím J, ESC hoặc nút Close), Player phục hồi điều khiển bình thường.
   - Thiết lập tính loại trừ lẫn nhau (mutual exclusivity) giữa Inventory (phím I) và Quest Journal (phím Q/J): mở cái này sẽ tự động đóng cái kia, không mở đè lên nhau.

5. **Đồng bộ tiến độ thu thập khi nhặt đồ:**
   - Kết nối tín hiệu `inventory_updated` của `InventoryComponent` vào `QuestJournalComponent`.
   - Tiến độ thu thập Lõi Tàn Hỏa tự động cập nhật ngay khi nhặt từ mặt đất hoặc thay đổi số lượng trong túi đồ, có cơ chế chặn vòng lặp tín hiệu vô hạn (chỉ phát tín hiệu khi giá trị hoặc trạng thái thực sự thay đổi).

---

## 3. Báo Cáo Kiểm Thử Tự Động Toàn Diện trên Godot 4.3 Engine

Tất cả các bộ test đều chạy trực tiếp trên engine (`Godot_v4.3-stable_win64_console.exe --headless`):

```text
========================================================================================
 BỘ KIỂM THỬ                         | SỐ TEST    | KẾT QUẢ      | MÃ THOÁT (EXIT CODE)
----------------------------------------------------------------------------------------
 test_m7_flow.gd (Mở rộng & M7.1)    | 156 tests  | PASS 100%    | 0
 test_m6_flow.gd (Thế giới & M6.1)   | 117 tests  | PASS 100%    | 0
 test_m5_flow.gd (Ma pháp M5.1)      | 100 tests  | PASS 100%    | 0
 test_m4_flow.gd (Boss Lunareth M4)  |  87 tests  | PASS 100%    | 0
 test_m3_2_flow.gd (Save/Load M3.2)  |  50 tests  | PASS 100%    | 0
 test_m2_1_flow.gd (NPC & Quest M2)  |  42 tests  | PASS 100%    | 0
========================================================================================
 TỔNG CỘNG                           | 552 tests  | PASS 100%    | HOÀN HẢO KHÔNG LỖI
========================================================================================
```

---

## 4. Hướng dẫn Điều khiển & Trải nghiệm

| Phím bấm | Hành động |
| :--- | :--- |
| **A / D** | Di chuyển trái / phải (Camera bám sát mượt mà) |
| **Space** | Nhảy đơn / Nhảy đôi (Double Jump) |
| **Shift** | Lướt nhanh (Dash) |
| **J** | Tấn công cận chiến (Chém kiếm) \| Đóng Quest Journal khi đang mở |
| **K** | Thi triển phép thuật đang chọn (Bắn ma pháp, tiêu hao MP) |
| **1, 2, 3** | Chọn phép thuật: [1] Nguyệt Quang Đạn \| [2] Tinh Hỏa Bùng Nổ \| [3] Hàn Tinh Tiễn |
| **U** | Nâng cấp phép thuật đang chọn (Tiêu hao Tinh thể Ma lực `mana_shard`) |
| **E** | Tương tác NPC (Elyra, Kaelis, Rhaek) / Kích hoạt Cổng dịch chuyển / Đọc Cổ Tinh Thạch |
| **Q** | **Mở / Đóng Sổ Nhiệm Vụ (Quest Journal)** |
| **I** | Mở / Đóng túi đồ (Inventory) & Bảng trang bị |
| **Esc** | Tạm dừng trò chơi (Pause Menu) / Đóng túi đồ / Đóng Sổ Nhiệm Vụ / Đóng hội thoại |

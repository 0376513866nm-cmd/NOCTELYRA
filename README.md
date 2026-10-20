# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M7: Regional Gameplay Expansion)

Dự án game Action RPG 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Milestone M7)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu kiến trúc Milestone M7 & kết quả kiểm thử
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M7 Final)
├── test_m7_flow.gd                 # [M7] Kịch bản kiểm thử 13 nhóm tính năng mở rộng vùng đất (116/116 tests PASS 100%)
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
    │   │   ├── player.gd                    # FSM Player, tích hợp QuestJournalComponent
    │   │   ├── player.tscn                  # Scene Player có đủ các Component chiến đấu và dữ liệu
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy đôi, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC: Elyra (Noctis), Kaelis (Elyndra), Rhaek (Vharok)
    │   │   └── npc.tscn                     # Scene NPC xuyên người mượt mà (collision_layer = 0)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI đa hình thái: MELEE, LUNGE, RANGED, Leash, Stop on Player Death
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
    │   ├── inventory_component.gd           # Túi đồ 16 ô, stack item, kiểm tra chỗ trống an toàn
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
    │   ├── quest_definition.gd              # [M7] Resource nhiệm vụ phụ: KILL_ENEMY_TYPE & COLLECT_ITEMS
    │   ├── quest_journal_component.gd       # [M7] Component quản lý nhật ký nhiệm vụ, lọc quái, trao thưởng an toàn
    │   └── quest_manager.gd                 # Quản lý nhiệm vụ chính và Vàng
    ├── save\
    │   └── save_manager.gd                  # [M7 v1.4.0] Ghi nguyên tử, lưu Quest Journal, world state, backward-compatible
    ├── ui\
    │   ├── game_ui.gd                       # HUD chính, kết nối phím Q bật Sổ Nhiệm Vụ, thoại NPC Kaelis/Rhaek
    │   ├── game_ui.tscn                     # CanvasLayer HUD, tích hợp QuestJournalUI
    │   ├── quest_journal_ui.gd              # [M7] UI Sổ Nhiệm Vụ: hiển thị 3 nhiệm vụ, tiến độ, phần thưởng, badge
    │   ├── quest_journal_ui.tscn            # [M7] Scene Sổ Nhiệm Vụ
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
        └── vharok_outpost.tscn              # (Chứa NPC Rhaek, 3 Ashfang Wolf, 2 Ember Lizard, 3 Ember Core pickups)
```

---

## 2. Chi Tiết Triển Khai Milestone M7

### A. Hệ thống Sinh vật & Chiến đấu Vùng miền (Regional Creatures)
- **Kiến trúc dữ liệu:**
  + Sử dụng `EnemyDefinition` để cấu hình thông số riêng biệt cho từng loài quái, tách biệt dữ liệu khỏi mã logic.
  + Hỗ trợ 3 kiểu tấn công: `MELEE` (cận chiến), `LUNGE` (lao tới tốc độ cao), `RANGED` (bắn đạn ma thuật/cầu lửa từ xa).
  + Hỗ trợ giai đoạn báo trước (`telegraph`) và thời gian khựng nghỉ (`recovery`), tạo nhịp điệu chiến đấu side-scrolling rõ ràng, công bằng cho người chơi.
  + **Cơ chế Leash Protection:** Quái vật rượt đuổi người chơi nhưng tự động hủy mục tiêu và quay về khi vượt quá `leash_distance` tính từ điểm sinh ban đầu.
  + **Dừng tấn công khi Player tử vong:** Quái vật tự động hủy mục tiêu và tắt hitbox tấn công ngay lập tức khi Player chết.
  + **Chống sát thương trùng lặp (No Infinite Damage Loop):** Sử dụng `reset_hits()` và bộ đệm kiểm tra mục tiêu đã trúng đòn trong cùng một lượt đánh.
- **Sinh vật Thánh Lâm Elyndra:**
  + **Corrupted Mooncap (Nấm Mộng Tha Hóa):** Cận chiến, di chuyển chậm, có thời gian rung lắc báo hiệu trước khi tấn công. Rơi Tinh thể Ma lực (`mana_shard`).
  + **Corrupted Mana Wisp (Linh Hồn Tinh Mạch):** Sinh vật bay lơ lửng không chịu trọng lực rơi, bắn đạn ma pháp tím định hướng (`enemy_projectile`) gây 12 DMG.
- **Sinh vật Tiền Đồn Vharok:**
  + **Ashfang Wolf (Sói Tro):** Di chuyển nhanh (180 px/s), gầm báo hiệu (0.5s) rồi lao vụt tới (460 px/s) gây 18 DMG, có thời gian nghỉ hồi phục (0.85s).
  + **Ember Lizard (Hỏa Tích Hắc Nham):** Tấn công tầm xa, tích tụ lửa và bắn cầu lửa cam (15 DMG, 280 px/s), có xác suất đánh rơi Lõi Tàn Hỏa (`ember_core`).
- **Hiển thị Placeholder Phân biệt (`EnemyVisual`):**
  + Mỗi loại quái có bảng màu, kích thước và chi tiết đặc trưng (Nấm có mũ đốm sáng ma thuật, Wisp có lõi năng lượng lơ lửng, Sói có mắt đỏ nhe răng, Thằn lằn có vảy đá gai lưng).
  + Hỗ trợ đầy đủ 5 animation state: `idle`, `move`, `telegraph`, `attack`, `hit`, `death`, sẵn sàng thay thế trực tiếp bằng `AnimatedSprite2D` khi có sprite art hoàn chỉnh.

### B. Hệ thống Nhiệm vụ Phụ & Đối thoại NPC
- **Nhiệm vụ Thánh Lâm — Kaelis (`quest_elyndra_cleansing`):**
  + Kaelis nhờ thanh tẩy các cây Nấm Mộng Tha Hóa làm ô nhiễm dòng chảy Tinh Mạch.
  + Mục tiêu: Tiêu diệt 3 `corrupted_mooncap`. Giết các loài quái khác không làm tăng tiến độ.
  + Phần thưởng: **80 Vàng + 2 Bình Máu (`health_potion`)**.
  + Sau khi hoàn thành: Kaelis chia sẻ lore về lịch sử Tinh Mạch và mối quan hệ cổ xưa giữa Tinh Linh và Quỷ tộc bán thú.
- **Nhiệm vụ Tiền Đồn — Rhaek (`quest_vharok_embers`):**
  + Rhaek cần Lõi Tàn Hỏa để duy trì ngọn lửa rèn của Tiền Đồn.
  + Mục tiêu: Thu thập 3 `ember_core` (nhặt từ 3 vị trí trên bản đồ Tiền Đồn Vharok hoặc đánh rơi từ Hỏa Tích Hắc Nham).
  + Khi trả nhiệm vụ: Hệ thống tự động kiểm tra và **trừ đúng 3 `ember_core`** khỏi Inventory của người chơi.
  + Phần thưởng: **100 Vàng + 3 Mảnh Chân Ma (`mana_shard`)**.
  + Sau khi hoàn thành: Rhaek khen ngợi lòng quả cảm của người chơi và kể về tinh thần trọng danh dự của Quỷ tộc.
- **Bảo vệ chống nhận thưởng lặp lại:** Cờ `reward_claimed` ngăn chặn tuyệt đối việc nhận vàng hay vật phẩm nhiều lần khi tương tác lại.
- **Bảo vệ túi đồ đầy:** Nếu túi đồ không còn chỗ trống khi nhận thưởng, vật phẩm tự động rơi xuống mặt đất dưới dạng item pickup an toàn, không bị mất dữ liệu.

### C. Sổ Nhiệm Vụ (Quest Journal UI — Phím Q)
- Bật/tắt nhanh bằng phím **Q**, nút **[✕]** hoặc phím **ESC**.
- Hiển thị danh sách đầy đủ cả 3 nhiệm vụ:
  1. **Nhiệm vụ chính:** Thanh Tẩy Rừng Noctis (Elyra)
  2. **Nhiệm vụ phụ 1:** Thanh Tẩy Thánh Lâm (Kaelis)
  3. **Nhiệm vụ phụ 2:** Lửa Rèn Tiền Đồn (Rhaek)
- Mỗi thẻ nhiệm vụ hiển thị trực quan: Tên nhiệm vụ, Người giao, Khu vực, Mô tả, Mục tiêu & Tiến độ chi tiết, Phần thưởng và Huy hiệu Trạng thái màu sắc: `[Chưa nhận]`, `[Đang thực hiện]`, `[Sẵn sàng trả]`, `[Đã hoàn thành]`.
- Tự động tạm khóa các phím hành động (đánh, nhảy, lướt, dùng phép) khi Sổ Nhiệm Vụ đang mở.

### D. Nâng cấp Hệ thống Lưu & Tải Tiến trình v1.4.0
- Nâng cấp `CURRENT_VERSION = "1.4.0"`.
- Lưu trữ toàn bộ dữ liệu `QuestJournalComponent`: trạng thái nhiệm vụ, tiến độ, cờ đã nhận thưởng, danh sách quái đã hạ gục.
- Lưu trữ trạng thái thế giới của từng khu vực: các quái vật đã bị tiêu diệt và các vật phẩm đã nhặt tại Elyndra Glade và Vharok Outpost được lưu nhớ chính xác, không bị hồi sinh hay tạo lại khi tải game.
- **Tương thích ngược hoàn hảo:** Tải an toàn các bản lưu cũ v1.0.0, v1.1.0, v1.2.0, v1.3.0 mà không gây crash hoặc lỗi dữ liệu.

---

## 3. Báo Cáo Kiểm Thử Tự Động Toàn Diện trên Godot 4.3 Engine

Tất cả các bộ test đều chạy trực tiếp trên engine (`Godot_v4.3-stable_win64_console.exe --headless`):

```text
========================================================================================
 BỘ KIỂM THỬ                         | SỐ TEST    | KẾT QUẢ      | MÃ THOÁT (EXIT CODE)
----------------------------------------------------------------------------------------
 test_m7_flow.gd (Mở rộng vùng M7)   | 116 tests  | PASS 100%    | 0
 test_m6_flow.gd (Thế giới & M6.1)   | 117 tests  | PASS 100%    | 0
 test_m5_flow.gd (Ma pháp M5.1)      | 100 tests  | PASS 100%    | 0
 test_m4_flow.gd (Boss Lunareth M4)  |  87 tests  | PASS 100%    | 0
 test_m3_2_flow.gd (Save/Load M3.2)  |  50 tests  | PASS 100%    | 0
 test_m2_1_flow.gd (NPC & Quest M2)  |  42 tests  | PASS 100%    | 0
========================================================================================
 TỔNG CỘNG                           | 512 tests  | PASS 100%    | HOÀN HẢO KHÔNG LỖI
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
| **Q** | **Mở / Đóng Sổ Nhiệm Vụ (Quest Journal)** |
| **I** | Mở / Đóng túi đồ (Inventory) & Bảng trang bị |
| **Esc** | Tạm dừng trò chơi (Pause Menu) / Đóng túi đồ / Đóng Sổ Nhiệm Vụ / Đóng hội thoại |

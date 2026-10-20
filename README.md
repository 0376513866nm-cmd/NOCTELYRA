# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M4 FINAL)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M4 FINAL)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, boss guide & kết quả kiểm thử M4
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M4)
├── test_m4_flow.gd                 # [MỚI M4] Kịch bản kiểm thử 15 hạng mục Boss M4 (63/63 tests PASS 100%)
├── test_m3_2_flow.gd               # Kịch bản kiểm thử M3.2 (50/50 tests PASS)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (41/41 tests PASS)
├── test_m3_flow.gd                 # Kịch bản kiểm thử M3 (67/67 tests PASS)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử M2.1 (42/42 tests PASS)
├── icon.svg                        # Icon chuẩn của dự án (128x128 SVG)
├── project.godot                   # Main Scene: main_menu.tscn (1280x720, forward_plus)
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
    │   │   ├── player.gd                    # FSM Player, tích hợp Inventory, Equipment, Combat
    │   │   ├── player.tscn                  # Scene Player hoàn chỉnh
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC Elyra, mở khóa Cổng Ma Pháp sau khi trả nhiệm vụ
    │   │   └── npc.tscn                     # Scene NPC Elyra (collision_layer = 0: xuyên người mượt mà)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI, gán enemy_id ổn định, tích hợp rơi đồ LootTable
    │       └── enemy.tscn                   # Scene Enemy với thanh máu HPBar mini, hitbox & hurtbox
    ├── boss\                                # [MỚI M4] MODULE BOSS LUNARETH — LINH LỘC NGUYỆT THỰC
    │   ├── boss_lunareth.gd                 # FSM Boss 8 trạng thái, 2 giai đoạn chiến đấu, 2 chiêu thức
    │   ├── boss_lunareth.tscn               # Scene Boss với HealthComponent (320 HP), Hurtbox, Hitbox, Detection
    │   ├── boss_visual.gd                   # Render hình dáng linh thú 4 chân, sừng ma pháp, bảng màu theo phase
    │   ├── boss_shockwave.gd                # Sóng chấn ba Hắc Nguyệt Chấn Ba (25 DMG, bay sát mặt đất, né bằng nhảy)
    │   └── boss_shockwave.tscn              # Scene projectile sóng xung kích
    ├── combat\
    │   ├── damage_info.gd                   # Struct dữ liệu sát thương & knockback
    │   ├── health_component.gd              # Quản lý HP, MP, hồi mana & I-frames miễn nhiễm
    │   ├── hurtbox.gd                       # Vùng nhận đòn chuyển tiếp tới HealthComponent
    │   ├── hitbox.gd                        # Vùng gây sát thương chém cận chiến / đòn húc / chấn ba
    │   ├── combat_component.gd              # Quản lý cooldown chém thường và bắn ma pháp
    │   ├── magic_projectile.gd              # Quả cầu ma pháp bay thẳng gây nổ sát thương
    │   └── magic_projectile.tscn            # Scene đạn phép ma pháp
    ├── interaction\
    │   ├── interaction_coordinator.gd       # Bộ điều phối Input tập trung cho tương tác & hội thoại
    │   └── interaction_component.gd         # Area2D tương tác nhận diện Player phạm vi gần
    ├── inventory\                           # HỆ THỐNG VẬT PHẨM & TRANG BỊ
    │   ├── item_definition.gd               # Resource định nghĩa vật phẩm chuẩn (ID, tên, loại, chỉ số, công dụng)
    │   ├── item_database.gd                 # [CẬP NHẬT M4] Đăng ký vật phẩm ID 5: eclipse_fragment (Mảnh Nguyệt Thực)
    │   ├── inventory_component.gd           # Quản lý 16 ô túi đồ, kiểm tra tràn túi khi nhận thưởng Boss
    │   ├── equipment_component.gd           # Quản lý 2 ô trang bị & tính toán lại chỉ số
    │   ├── inventory_ui.gd                  # Controller giao diện túi đồ, lưới 16 ô, xem chi tiết & nút bấm
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ đẹp mắt, hỗ trợ chuột và cảm ứng
    ├── loot\                                # HỆ THỐNG RƠI ĐỒ VÀ NHẶT VẬT PHẨM
    │   ├── loot_table.gd                    # Resource định nghĩa bảng tỷ lệ rơi đồ của quái vật
    │   ├── item_pickup.gd                   # Gán pickup_id ổn định, tự hủy nếu đã nhặt trước đó
    │   └── item_pickup.tscn                 # Scene vật phẩm rơi với hiệu ứng nhấp nhô lơ lửng
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # Quản lý quest, lưu enemy_id chuỗi ổn định xuyên suốt
    ├── save\                                # HỆ THỐNG LƯU / TẢI TIẾN TRÌNH OFFLINE
    │   └── save_manager.gd                  # [CẬP NHẬT M4] Hỗ trợ version 1.1.0 & tương thích ngược 1.0.0, lưu boss_state, mở rộng tọa độ tới 6200.0
    ├── ui\
    │   ├── game_ui.gd                       # [CẬP NHẬT M4] Boss HUD (HP Bar 320, Phase 1/2), Warning, Announcement, Victory Screen, chặn Lưu khi đấu Boss
    │   ├── game_ui.tscn                     # CanvasLayer giao diện in-game
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập, Esc đóng túi đồ trước
    │   ├── main_menu.gd                     # Màn hình chính: Chơi mới (xác nhận ghi đè), Tiếp tục, Thoát
    │   └── main_menu.tscn                   # Scene Main Menu
    └── world\
        ├── magic_gate.gd                    # [MỚI M4] Cổng Ma Pháp chặn lối vào đấu trường, chỉ mở khi Quest COMPLETED
        ├── magic_gate.tscn                  # Scene Cổng Ma Pháp rào chắn vật lý cao 400px
        ├── noctis_forest.gd                 # [CẬP NHẬT M4] Mở rộng sàn tới X=6400, trigger đấu trường, rào chắn arena, retry checkpoint (4120, 630), thưởng Boss
        ├── noctis_forest.tscn               # Màn chơi hoàn chỉnh kết hợp Làng Elyra, Bìa Rừng, Quái vật và Đấu trường Boss
        ├── test_level.gd                    # Màn test M1 cũ
        └── test_level.tscn
```

---

## 2. Thiết kế Boss Lunareth — Linh Lộc Nguyệt Thực

### 2.1. Cốt truyện & Định danh Chủng tộc
- **Tên:** Lunareth — Linh Lộc Nguyệt Thực (*Eclipse Stag*).
- **Xuất thân:** Lunareth là linh thú bảo hộ Rừng Noctis từ ngàn xưa, mang đôi sừng kết tinh ma pháp ánh trăng cổ xưa. Do ma lực bóng tối tha hóa, linh thú mất đi lý trí và tấn công kẻ lạc lối.
- **Quan trọng:** Lunareth **không phải Quỷ tộc**. Quỷ tộc bán thú trong thế giới NOCTELYRA là một chủng tộc văn minh, không mặc định phản diện. Khi bị đánh bại, Lunareth **được thanh tẩy ma lực**, lấy lại ánh sáng thuần khiết, cúi đầu tạ ơn và tan biến trong thanh thản (không chết thê thảm).

### 2.2. Trạng thái & Cơ chế chiến đấu (FSM 8 trạng thái)
- **Máu cơ bản:** 320 HP.
- **Trạng thái FSM:**
  1. `DORMANT`: Đứng yên, đợi Player bước vào kích hoạt.
  2. `INTRO`: Hú gầm ma pháp, rung chuyển màn hình, hiện thanh máu Boss và biểu ngữ cảnh báo.
  3. `APPROACH`: Tiếp cận Player giữ cự ly giao tranh.
  4. `TELEGRAPH`: Báo hiệu trước đòn đánh (sáng sừng, hiển thị chỉ báo cảnh báo).
  5. `ATTACK`: Thi triển một trong 2 chiêu thức.
  6. `RECOVERY`: Nghỉ ngắn sau đòn đánh (Phase 1: 1.2s; Phase 2: 0.6s).
  7. `PHASE_TRANSITION`: Kích hoạt khi HP <= 160 (50%). Boss bất tử tạm thời, gầm chấn động, sừng chuyển màu tím sẫm, tốc độ tăng gấp rưỡi.
  8. `DEFEATED`: Thanh tẩy, sừng chuyển màu trắng vàng linh thánh, mở rào đấu trường, trao thưởng.

### 2.3. Hai Chiêu thức của Boss
1. **Nguyệt Giác Xung Kích (Crescent Horn Charge):**
   - *Báo hiệu (Telegraph):* Dừng lại 0.7s (Phase 1) hoặc 0.4s (Phase 2), sừng phát sáng rực rỡ, hiển thị đường tấn công màu đỏ/vàng.
   - *Hành vi:* Lao nhanh về phía Player (tốc độ 420 px/s), húc trúng gây **30 sát thương** + văng xa (knockback).
   - *Khắc chế:* Nhảy đôi vượt qua thân Boss hoặc Dash lướt ngược chiều khi Boss bắt đầu lao.
2. **Hắc Nguyệt Chấn Ba (Dark Moon Shockwave):**
   - *Báo hiệu:* Nâng hai chân trước lên cao trong 0.8s.
   - *Hành vi:* Dậm mạnh xuống đất tạo sóng chấn ba ma pháp lan sát mặt đất với vận tốc 280 px/s, gây **25 sát thương**.
   - *Khắc chế:* Nhảy qua sóng chấn ba.

---

## 3. Đấu trường & Vòng lặp Gameplay Hoàn chỉnh

```text
[Làng Tân Thủ: X=0..1200]
       │
       ▼ (Gặp Elyra, nhận nhiệm vụ tiêu diệt 3 quái)
[Bìa Rừng Noctis: X=1200..3800]
       │
       ▼ (Diệt 3 quái, nhặt Mana Shard / Kiếm / Bùa, trả Quest nhận 50 Vàng)
[Cổng Ma Pháp: X=4000] ──[Bị khóa nếu chưa xong Quest]──> (Mở khi Quest COMPLETED)
       │
       ▼ (Bước qua X=4200: Arena Barrier khóa lại tại X=4180 và X=6350)
[Đấu trường Lunareth: X=4200..6350]
       │
   ┌───┴───────────────────────────────┐
   ▼                                   ▼
[Player chết]                  [Lunareth Defeated]
   │                                   │
   ▼                                   ▼
Màn hình Game Over             Thanh tẩy linh thú, mở rào đấu trường
Nút Retry đưa về               Thưởng: 100 Vàng + Mảnh Nguyệt Thực
Checkpoint (X=4120, Y=630)     (Nếu đầy túi đồ: rơi trên đất)
Reset Boss về đầy máu          Tự do khám phá tiếp hoặc Lưu game!
```

---

## 4. Các phím điều khiển (Controls)

| Phím | Chức năng | Chi tiết |
| :--- | :--- | :--- |
| **A / D** hoặc **Mũi tên** | Di chuyển Trái / Phải | Có gia tốc mượt, tự động quay mặt nhân vật |
| **Space** | Nhảy / Nhảy đôi | Nhấn lần 1 nhảy, nhấn lần 2 trên không để Double Jump |
| **Shift** | Lướt nhanh (Dash) | Lướt ngang tốc độ cao (0.2s), có thể Air-Dash trên không |
| **J** | **Đánh thường (Melee)** | Chém cận chiến (cơ bản 25 DMG, trang bị Kiếm thành 35 DMG) |
| **K** | **Ma pháp (Magic Spell)** | Bắn quả cầu ma pháp (30 DMG), tiêu hao 15 MP |
| **E** | **Tương tác (Interact)** | Nói chuyện với Elyra; duyệt/đóng câu hội thoại |
| **I** | **Túi đồ (Inventory)** | Mở/đóng Túi đồ & Trang bị (không pause thế giới) |
| **Esc** | Pause / Thoát | Đóng túi đồ nếu đang mở; hoặc Tạm dừng / Tiếp tục game |

> **Lưu ý trong trận đấu Boss:** Nút "Lưu Game" trong Pause Menu bị vô hiệu hóa an toàn nhằm ngăn chặn tình trạng lưu giữa combat gây kẹt logic. Khi Boss bị đánh bại hoặc người chơi ở ngoài đấu trường, chức năng Lưu Game hoạt động bình thường.

---

## 5. Báo cáo kiểm thử tự động thực tế trên Godot 4.3 Engine

### 5.1. Bộ test Boss M4 (`test_m4_flow.gd`) — 63/63 Tests PASS (100%)

Chạy thực tế qua lệnh:
`& "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "d:\project\game\NOCTELYRA" -s "test_m4_flow.gd"`

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M4] INTEGRATION TEST SUITE STARTING 
==================================================

--- CATEGORY 1: Khởi tạo Boss Lunareth và Thông số ban đầu ---
  [PASS] Boss Lunareth tồn tại trong scene
  [PASS] Boss bắt đầu ở trạng thái DORMANT
  [PASS] Boss có đúng 320 HP khởi đầu
  [PASS] Boss Max HP là 320
  [PASS] Boss Visual controller tồn tại
  [PASS] Boss Phase ban đầu là 1

--- CATEGORY 2: Cổng Ma Pháp (Magic Gate) chặn trước khi hoàn thành Quest ---
  [PASS] Cổng Ma Pháp tồn tại trong scene
  [PASS] Nhiệm vụ chưa hoàn thành, cổng ma pháp đang ĐÓNG
  [PASS] Va chạm của cổng ma pháp đang BẬT (chặn người chơi)

--- CATEGORY 3: Cổng Ma Pháp MỞ sau khi hoàn thành Quest của Elyra ---
  [PASS] Cổng ma pháp đã MỞ sau khi Quest hoàn thành
  [PASS] Va chạm cổng ma pháp đã TẮT (cho phép đi qua)

--- CATEGORY 4: Kích hoạt Đấu trường Boss & Khóa Rào Chắn ---
  [PASS] Rào chắn đấu trường tồn tại
  [PASS] Boss chuyển từ DORMANT sang INTRO khi người chơi bước vào
  [PASS] Rào chắn đấu trường đã ĐÓNG để nhốt người chơi
  [PASS] Va chạm rào chắn đấu trường đã BẬT

--- CATEGORY 5: Giao diện Boss (Boss UI HUD) & Cảnh báo Telegraph ---
  [PASS] Boss Bar Panel hiển thị khi bắt đầu trận đấu
  [PASS] Giá trị hiển thị trên thanh máu Boss là 320 / 320
  [PASS] Nhãn Giai đoạn 1 hiển thị chính xác

--- CATEGORY 6: Chiêu thức 1 - Nguyệt Giác Xung Kích (Crescent Horn Charge) ---
  [PASS] Boss có thể chuyển sang TELEGRAPH
  [PASS] Telegraph đang hoạt động
  [PASS] Boss chuyển sang ATTACK
  [PASS] Hitbox của Boss đã BẬT trong đòn đánh
  [PASS] Sát thương của chiêu húc là 30.0

--- CATEGORY 7: Chiêu thức 2 - Hắc Nguyệt Chấn Ba (Dark Moon Shockwave) ---
  [PASS] Boss có thể tạo sóng chấn ba
  [PASS] Sóng chấn ba tồn tại trong scene
  [PASS] Sát thương của sóng chấn ba là 25.0
  [PASS] Tốc độ sóng chấn ba lớn hơn 0
  [PASS] Sóng chấn ba bay sát mặt đất (Y gần mặt sàn)

--- CATEGORY 8: Chuyển Giai đoạn 2 (Phase Transition tại HP <= 160) ---
  [PASS] Boss nhận sát thương còn 160 HP
  [PASS] Boss tự động kích hoạt PHASE_TRANSITION
  [PASS] Giai đoạn chuyển thành Phase 2
  [PASS] Trong chuyển phase Boss được miễn nhiễm (invulnerable)
  [PASS] Nhãn HUD hiển thị đúng Phase 2

--- CATEGORY 9: Tăng tốc độ và tần suất chiêu thức trong Giai đoạn 2 ---
  [PASS] Thời gian telegraph Phase 2 (0.4s) nhanh hơn Phase 1 (0.7s)
  [PASS] Thời gian hồi chiêu Phase 2 (0.6s) ngắn hơn Phase 1 (1.2s)
  [PASS] Tốc độ lao Phase 2 (500 px/s) nhanh hơn Phase 1 (420 px/s)

--- CATEGORY 10: Lunareth bị đánh bại, Thanh Tẩy & Mở rào đấu trường ---
  [PASS] Boss nhận sát thương chí mạng về 0 HP
  [PASS] Boss chuyển sang trạng thái DEFEATED
  [PASS] Boss visual chuyển sang trạng thái DEFEATED (thanh tẩy)
  [PASS] Rào chắn đấu trường MỞ RA sau khi Boss bị đánh bại
  [PASS] Boss Bar Panel ẩn sau khi kết thúc trận đấu
  [PASS] Bảng thông báo chiến thắng (Victory Panel) hiển thị

--- CATEGORY 11: Phần thưởng Boss - Vàng và Mảnh Nguyệt Thực ---
  [PASS] Người chơi nhận được 100 Vàng sau chiến thắng
  [PASS] Vật phẩm Mảnh Nguyệt Thực (eclipse_fragment) tồn tại trong Database
  [PASS] Người chơi nhận được Mảnh Nguyệt Thực trong túi đồ

--- CATEGORY 12: Xử lý an toàn khi Túi Đồ ĐẦY lúc nhận thưởng Boss ---
  [PASS] Đã làm đầy 16 ô túi đồ của Player
  [PASS] Nhận thưởng Boss khi túi đồ đầy không gây lỗi
  [PASS] Túi đồ vẫn chứa đúng 16 ô
  [PASS] Mảnh Nguyệt Thực rơi trên mặt đất dưới dạng ItemPickup

--- CATEGORY 13: Retry sau khi chết trong Đấu Trường Boss ---
  [PASS] Người chơi chết trong đấu trường
  [PASS] Rào chắn đấu trường mở khi người chơi chết
  [PASS] Sau khi retry, Player hồi sinh tại Checkpoint trước đấu trường (X=4120)
  [PASS] Sau khi retry, Boss Lunareth được hồi phục đầy đủ 320 HP
  [PASS] Boss quay về trạng thái sẵn sàng chiến đấu lại

--- CATEGORY 14: Hệ thống Lưu/Tải M4 & Chặn Lưu trong Combat Boss ---
  [PASS] Nút Lưu game bị vô hiệu hóa an toàn trong trận đấu Boss
  [PASS] Nút Lưu game được mở lại sau khi Boss bị đánh bại
  [PASS] Dữ liệu Boss đã lưu trữ vào cấu trúc save (Version 1.1.0)
  [PASS] Tải lại bản lưu thành công
  [PASS] Trạng thái Boss đã bị đánh bại được phục hồi chính xác
  [PASS] Giới hạn tọa độ mở rộng an toàn hỗ trợ đến khu vực đấu trường (> 4000)

--- CATEGORY 15: Tương thích ngược phiên bản Save 1.0.0 (M3.2) ---
  [PASS] has_save chấp nhận bản lưu phiên bản cũ 1.0.0
  [PASS] load_game nạp thành công bản lưu phiên bản cũ 1.0.0
  [PASS] Boss mặc định chưa bị đánh bại khi nâng cấp từ bản lưu cũ

==================================================
 [NOCTELYRA M4] KẾT QUẢ KIỂM THỬ TỔNG HỢP:
 Tổng số test: 63 | Đạt: 63 | Thất bại: 0
==================================================
>>> ALL M4 TEST SCENARIOS PASSED 100%! <<<
```

### 5.2. Kết quả kiểm thử hồi quy toàn bộ hệ thống
- **M3.2 FINAL (`test_m3_2_flow.gd`):** 50/50 Tests PASS (100%)
- **M3.1 FINAL (`test_m3_1_flow.gd`):** 41/41 Tests PASS (100%)
- **M3 FINAL (`test_m3_flow.gd`):** 67/67 Tests PASS (100%)
- **M2.1 FINAL (`test_m2_1_flow.gd`):** 42/42 Tests PASS (100%)
- **TỔNG CỘNG:** **263 / 263 Tests PASS (100%)** không một lỗi lầm trên Godot 4.3 Engine!

---

## 6. Hướng dẫn chạy và kiểm thử

- **Chạy game chơi thử:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Xuất toàn bộ mã nguồn cho AI review:** Click đúp vào file `export_code_for_ai.bat`.
- **Chạy bộ test M4 (Boss Lunareth):**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m4_flow.gd
  ```
- **Chạy bộ test M3.2:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m3_2_flow.gd
  ```
- **Chạy bộ test M2.1:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m2_1_flow.gd
  ```

# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M3.2 FINAL)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M3.2 FINAL)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, sơ đồ & kết quả kiểm thử M3.2
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review
├── test_m3_2_flow.gd               # [MỚI M3.2] Kịch bản kiểm thử 12 hạng mục M3.2 (50/50 tests PASS)
├── test_m3_1_flow.gd               # Kịch bản kiểm thử M3.1 (Đã fix an toàn 100%, 40/40 tests PASS)
├── test_m3_flow.gd                 # Kịch bản kiểm thử hồi quy 15 giai đoạn M3 (67/67 tests PASS)
├── test_m2_1_flow.gd               # Kịch bản kiểm thử hồi quy M2.1 (42/42 tests PASS)
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
    │   │   ├── player.gd                    # FSM Player, tích hợp InventoryComponent & EquipmentComponent
    │   │   ├── player.tscn                  # Scene Player hoàn chỉnh
    │   │   └── player_movement_data.gd      # Resource thông số di chuyển, nhảy, dash
    │   ├── npc\
    │   │   ├── npc.gd                       # Logic NPC Elyra, đối thoại đa phân đoạn & trigger nhiệm vụ
    │   │   └── npc.tscn                     # Scene NPC Elyra (collision_layer = 0: xuyên người mượt mà)
    │   └── enemy\
    │       ├── enemy.gd                     # Enemy AI, gán enemy_id ổn định, tích hợp rơi đồ LootTable
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
    │   ├── interaction_coordinator.gd       # Bộ điều phối Input tập trung cho tương tác & hội thoại
    │   └── interaction_component.gd         # Area2D tương tác nhận diện Player phạm vi gần
    ├── inventory\                           # HỆ THỐNG VẬT PHẨM & TRANG BỊ
    │   ├── item_definition.gd               # Resource định nghĩa vật phẩm chuẩn (ID, tên, loại, chỉ số, công dụng)
    │   ├── item_database.gd                 # Registry tra cứu vật phẩm ổn định theo ID
    │   ├── inventory_component.gd           # [CẬP NHẬT M3.2] Kiểm tra an toàn truy xuất slot amount, chống crash
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
    │   └── save_manager.gd                  # [VIẾT LẠI M3.2] Nạp trang bị trước để tính đúng Max MP, fault injection rollback, validation nghiêm ngặt
    ├── ui\
    │   ├── game_ui.gd                       # HUD, thanh máu, phím I mở túi đồ, PauseMenu tích hợp Save Game
    │   ├── game_ui.tscn                     # CanvasLayer giao diện in-game
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập, Esc đóng túi đồ trước
    │   ├── main_menu.gd                     # Màn hình chính: Chơi mới (xác nhận ghi đè), Tiếp tục, Thoát
    │   └── main_menu.tscn                   # Scene Main Menu
    └── world\
        ├── noctis_forest.gd                 # Quản lý pickup nhặt/rơi, khôi phục trạng thái thế giới
        ├── noctis_forest.tscn               # Màn chơi Bìa Rừng Noctis với ID pickup ổn định cho làng
        ├── test_level.gd                    # Màn test M1 cũ
        └── test_level.tscn
```

---

## 2. Các điểm sửa đổi trọng tâm trong phiên bản M3.2 FINAL

### 2.1. Bảo vệ tuyệt đối file save thật của người chơi trong toàn bộ kịch bản kiểm thử
- Loại bỏ 100% mọi thao tác `WRITE`, `REMOVE`, `RENAME` trên file save thật (`user://noctelyra_slot1.json`) trong toàn bộ các file test (`test_m3_1_flow.gd`, `test_m3_2_flow.gd`, `test_m3_flow.gd`).
- Toàn bộ dữ liệu kiểm thử được định tuyến độc lập vào `user://noctelyra_m3_2_test.json` hoặc `user://noctelyra_m3_1_test.json`.
- Kịch bản kiểm tra cách ly chỉ đọc (`read-only`) trạng thái và checksum MD5 của file save thật trước/sau test:
  - Nếu file thật đã tồn tại: xác minh sau toàn bộ bài test file vẫn nguyên vẹn 100% với checksum MD5 không đổi.
  - Nếu file thật chưa tồn tại: xác minh hệ thống test không tự ý tạo file giả định trên đường dẫn thật.

### 2.2. Khôi phục Current MP chính xác theo Max MP sau trang bị
- **Vấn đề trước đây:** Trong `SaveManager.load_game()`, Player HP/MP được nạp trước khi nạp Trang bị (Equipment). Khi đó `max_mana` của nhân vật vẫn là giá trị cơ bản (60.0). Nếu người chơi lưu game khi đang đeo `moon_amulet` (Max MP = 80.0) với `current_mana` = 75.0, giá trị này bị clamp sai về 60.0.
- **Giải pháp M3.2:**
  - Khôi phục `EquipmentComponent` và `InventoryComponent` **TRƯỚC**.
  - `EquipmentComponent` kích hoạt `_recalculate_stats()`, cập nhật tức thì `p_health.max_mana` thành 80.0 (nếu đeo `moon_amulet`) hoặc 60.0 (nếu không đeo).
  - Tiếp theo, nạp `current_mana` và clamp theo `p_health.max_mana` mới: Giá trị 75.0 được giữ nguyên vẹn 75.0 / 80.0.
  - Đã bổ sung bộ test kiểm tra nạp MP cho cả 2 trường hợp: có trang bị bùa và không có trang bị bùa.

### 2.3. Kiểm thử an toàn ghi file thực chất (Fault Injection & Rollback Testing)
- Bổ sung các cờ kiểm thử tiêm lỗi (fault injection) an toàn trong `SaveManager`:
  - `simulate_tmp_write_error`: Mô phỏng lỗi khi ghi file tạm `.tmp`.
  - `simulate_backup_error`: Mô phỏng lỗi khi tạo bản sao lưu `.bak`.
  - `simulate_replace_error`: Mô phỏng lỗi khi đổi tên thay thế file save chính.
- Kiểm thử xác minh:
  - Khi có lỗi xảy ra ở bất kỳ giai đoạn nào, `save_game()` ngay lập tức trả về `false`.
  - Bản lưu cũ trước đó được bảo toàn nguyên vẹn 100% (so sánh nội dung và MD5 checksum).
  - Cơ chế tự động khôi phục từ `.bak` và dọn dẹp các file rác `.tmp`, `.bak` hoạt động hoàn hảo.

### 2.4. Thẩm định (Validation) nghiêm ngặt file save
- `has_save()`:
  - Từ chối file JSON sai cú pháp hoặc rỗng.
  - Từ chối các phiên bản `save_version` không được hỗ trợ (chỉ chấp nhận các phiên bản trong `SUPPORTED_VERSIONS = ["1.0.0"]`).
  - Từ chối file save thiếu các khối dữ liệu cốt lõi bắt buộc (`player`, `quest`).
- `load_game()`:
  - Từ chối tải và trả về `false` khi thế giới thiếu `Player` hoặc `QuestManager`.
  - Xử lý an toàn khi các trường con bên trong `player` hoặc `quest` bị thiếu hoặc sai kiểu (tọa độ rác, chuỗi thay vì số, số âm), tự động clamp về ngưỡng an toàn của game mà không gây crash.

---

## 3. Các phím điều khiển (Controls)

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

---

## 4. Chi tiết 4 vật phẩm ban đầu

1. **Tinh thể Ma lực (`mana_shard`)**:
   - Loại: *Nguyên liệu (Material)*. Xếp chồng tối đa 99. Giá trị: 5 Vàng.
   - Rơi 100% từ sinh vật ma nhiễm trong Rừng Hắc Nguyệt.
2. **Bình Sinh Lực (`health_potion`)**:
   - Loại: *Tiêu hao (Consumable)*. Xếp chồng tối đa 20. Giá trị: 15 Vàng.
   - Hồi ngay lập tức 30 HP (giới hạn theo Max HP, không tràn máu). Giảm 1 bình sau khi dùng. Không thể uống khi Player đã chết (HP = 0).
3. **Kiếm Ánh Trăng (`moonsteel_sword`)**:
   - Loại: *Vũ khí (Weapon)*. Không xếp chồng (max_stack = 1). Giá trị: 100 Vàng.
   - Khi trang bị: Sát thương đánh thường tăng từ **25 lên 35**. Tháo ra hoàn trả chính xác về **25**.
4. **Bùa Nguyệt Quang (`moon_amulet`)**:
   - Loại: *Phụ kiện (Accessory)*. Không xếp chồng (max_stack = 1). Giá trị: 120 Vàng.
   - Khi trang bị: Max MP tăng từ **60 lên 80**. Tháo ra hoàn trả chính xác về **60** và tự động giới hạn Current MP về 60 (không tràn).

---

## 5. Báo cáo kiểm thử tự động thực tế trên Godot 4.3 Engine

### 5.1. Kết quả kiểm thử chuyên sâu M3.2 FINAL (`test_m3_2_flow.gd`) — 50/50 Tests PASS (100%)

Chạy thực tế qua lệnh:
`& "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "d:\project\game\NOCTELYRA" -s "test_m3_2_flow.gd"`

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M3.2] INTEGRATION TEST SUITE STARTING 
==================================================

--- TEST 1: Khôi phục MP khi CÓ trang bị Bùa Nguyệt Quang (moon_amulet) ---
  [PASS] Đã trang bị Bùa Nguyệt Quang, Max MP đạt 80.0
  [PASS] Lưu game với MP = 75.0 / 80.0 thành công
  [PASS] Tải bản lưu thành công
  [PASS] Trang bị Bùa Nguyệt Quang đã được khôi phục
  [PASS] Max MP được tính toán chính xác là 80.0
  [PASS] Current MP được áp dụng chính xác tuyệt đối là 75.0 / 80.0 (không bị clamp về 60)

--- TEST 2: Khôi phục MP khi KHÔNG có trang bị Bùa Nguyệt Quang ---
  [PASS] Đã tháo Bùa, Max MP trở lại 60.0
  [PASS] Lưu game với MP = 45.0 / 60.0 thành công
  [PASS] Tải bản lưu không có phụ kiện thành công
  [PASS] Ô phụ kiện trống đúng thực tế
  [PASS] Max MP giữ đúng 60.0
  [PASS] Current MP được nạp chính xác 45.0 / 60.0

--- TEST 3: Kiểm thử Fault Injection - Lỗi ghi file tạm (.tmp) ---
  [PASS] Đã thiết lập bản lưu gốc chuẩn
ERROR: [Mô phỏng lỗi]: Thất bại khi ghi file tạm!
   at: push_error (core/variant/variant_utility.cpp:1092)
  [PASS] Hàm save_game từ chối và trả về false khi ghi file tạm lỗi
  [PASS] Bản lưu trước đó vẫn giữ nguyên vẹn nội dung
  [PASS] MD5 checksum bản lưu trước đó không hề thay đổi

--- TEST 4: Kiểm thử Fault Injection - Lỗi ở bước tạo Backup (.bak) ---
ERROR: [Mô phỏng lỗi]: Thất bại ở bước tạo bản sao lưu .bak!
   at: push_error (core/variant/variant_utility.cpp:1092)
  [PASS] Hàm save_game từ chối và trả về false khi tạo backup lỗi
  [PASS] Bản lưu trước đó không bị ảnh hưởng khi backup thất bại
  [PASS] File tạm .tmp đã được dọn dẹp sạch sẽ

--- TEST 5: Kiểm thử Fault Injection - Lỗi khi Thay thế (Replace) & Phục hồi tự động ---
ERROR: Failed to open C:/Users/ngoma/AppData/Roaming/Godot/app_userdata/NOCTELYRA/noctelyra_m3_2_test.json.tmp
   at: (core/io/dir_access.cpp:348)
ERROR: Lỗi khi thay thế file save! Phục hồi bản lưu cũ từ backup.
   at: push_error (core/variant/variant_utility.cpp:1092)
  [PASS] Hàm save_game báo false khi quá trình thay thế file bị gián đoạn
  [PASS] File save chính vẫn tồn tại sau cơ chế rollback
  [PASS] Nội dung bản lưu cũ được phục hồi chính xác 100% từ backup
  [PASS] MD5 checksum bản lưu khớp tuyệt đối sau phục hồi
  [PASS] File .bak đã được hoàn tất dọn dẹp
  [PASS] File .tmp đã được dọn dẹp
  [PASS] Tải lại bản lưu sau sự cố rollback thành công hoàn hảo

--- TEST 6: has_save() từ chối JSON sai cú pháp hoặc hỏng ---
  [PASS] has_save() từ chối file JSON sai cú pháp
  [PASS] load_game() từ chối tải file JSON sai cú pháp

--- TEST 7: has_save() từ chối phiên bản không hỗ trợ (Unsupported Version) ---
  [PASS] has_save() từ chối phiên bản không hỗ trợ ('99.0.0')
  [PASS] load_game() từ chối tải phiên bản không hỗ trợ

--- TEST 8: has_save() từ chối JSON thiếu cấu trúc dữ liệu bắt buộc ---
  [PASS] has_save() từ chối khi thiếu khối 'player' hoặc 'quest'
  [PASS] load_game() từ chối khi cấu trúc không hợp lệ

--- TEST 9: load_game() an toàn khi thiếu trường con hoặc sai kiểu dữ liệu ---
  [PASS] has_save() chấp nhận vì có đủ khối dữ liệu gốc
  [PASS] load_game() xử lý an toàn không crash khi gặp trường con sai kiểu
  [PASS] HP được clamp >= 0.0 an toàn
  [PASS] MP không vượt quá Max MP
  [PASS] Vàng được clamp >= 0
  [PASS] Tọa độ được clamp trong giới hạn an toàn

--- TEST 10: load_game() từ chối khi World thiếu Player hoặc QuestManager ---
  [PASS] load_game(null) trả về false
ERROR: load_game thất bại: World thiếu Player hoặc QuestManager.
   at: push_error (core/variant/variant_utility.cpp:1092)
  [PASS] load_game() trả về false khi node không có Player/QuestManager

--- TEST 11: Kiểm tra cách ly 100% đối với file save thật ---
  [PASS] File save thật vẫn tồn tại nguyên vẹn
  [PASS] Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI

--- TEST 12: Kiểm tra hồi quy toàn diện M0 -> M3 ---
  [PASS] M2.1: NPC Elyra collision_layer = 0 (xuyên người mượt mà)
  [PASS] M0: Hệ thống Double Jump nguyên vẹn
  [PASS] M0: PauseController tồn tại
  [PASS] M0: Pause game thành công
  [PASS] M0: Resume game thành công
  [PASS] M1: Melee Hitbox tồn tại
  [PASS] M1: Combat Component tồn tại
  [PASS] M3: Inventory 16 ô tồn tại

==================================================
 [NOCTELYRA M3.2] KẾT QUẢ KIỂM THỬ TỔNG HỢP:
 Tổng số test: 50 | Đạt: 50 | Thất bại: 0
==================================================
>>> ALL M3.2 TEST SCENARIOS PASSED 100%! <<<
```

### 5.2. Kết quả kiểm thử an toàn M3.1 (`test_m3_1_flow.gd`) — 40/40 Tests PASS (100%)
Kịch bản kiểm thử M3.1 đã được sửa đổi loại bỏ hoàn toàn các thao tác ghi/xóa/sửa trên file thật, đạt 40/40 tests PASS.

### 5.3. Kết quả kiểm thử hồi quy M3 (`test_m3_flow.gd`) — 67/67 Tests PASS (100%)
Toàn bộ 15 giai đoạn kiểm thử M3 đạt 67/67 tests PASS.

### 5.4. Kết quả kiểm thử hồi quy M2.1 (`test_m2_1_flow.gd`) — 42/42 Tests PASS (100%)
Toàn bộ tính năng hội thoại, nhiệm vụ, di chuyển xuyên NPC đạt 42/42 tests PASS.

---

## 6. Bảng tổng hợp sửa lỗi trong Milestone M3.2 FINAL

| STT | Vấn đề phát hiện | Giải pháp kiến trúc trong M3.2 FINAL | Kết quả kiểm thử |
| :--- | :--- | :--- | :--- |
| 1 | `test_m3_1_flow.gd` ghi và xóa trực tiếp file save thật `user://noctelyra_slot1.json` | Loại bỏ hoàn toàn ghi/xóa/sửa; chuyển 100% sang đường dẫn test riêng biệt; chỉ đọc MD5 kiểm tra tính nguyên vẹn | Test 11 PASS (100% cách ly) |
| 2 | Nạp Current MP trước Trang bị làm MP bị clamp sai về 60 thay vì 75 khi đeo `moon_amulet` | Đảo thứ tự nạp: Trang bị & Túi đồ nạp trước -> tính lại Max MP (80) -> nạp Current MP (75/80) | Test 1 & Test 2 PASS |
| 3 | Chưa có kiểm thử mô phỏng lỗi thực chất trong quá trình ghi file tạm và thay thế file save | Bổ sung hệ thống Fault Injection an toàn cho `save_game()`: kiểm thử lỗi ghi `.tmp`, lỗi `.bak`, lỗi thay thế và kiểm chứng rollback | Test 3, 4, 5 PASS (Zero data loss) |
| 4 | `has_save()` chưa kiểm tra phiên bản hỗ trợ và cấu trúc dữ liệu cốt lõi | Thẩm định cú pháp JSON, đối chiếu `save_version` trong `SUPPORTED_VERSIONS`, kiểm tra bắt buộc khối `player` và `quest` | Test 6, 7, 8 PASS |
| 5 | `load_game()` có nguy cơ crash hoặc nạp thành công sai khi dữ liệu không hợp lệ | Kiểm tra an toàn `world`, `Player`, `QuestManager`, xử lý an toàn dữ liệu sai kiểu, từ chối nạp khi dữ liệu rác | Test 9, 10 PASS |

---

## 7. Hướng dẫn chạy và kiểm thử

- **Chạy game chơi thử:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Chạy bộ test M3.2:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m3_2_flow.gd
  ```
- **Chạy bộ test M3.1:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m3_1_flow.gd
  ```
- **Chạy bộ test M3:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m3_flow.gd
  ```
- **Chạy bộ test M2.1:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m2_1_flow.gd
  ```

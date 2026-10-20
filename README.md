# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M3.1 FINAL)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M3.1)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, sơ đồ & kết quả kiểm thử M3.1
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review
├── test_m3_1_flow.gd               # [MỚI M3.1] Kịch bản kiểm thử tự động 10 danh mục M3.1 (41/41 tests PASS)
├── test_m3_flow.gd                 # Kịch bản kiểm thử tự động 15 giai đoạn M3 (67/67 tests PASS)
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
    │   ├── inventory_component.gd           # Component quản lý túi đồ 16 ô (thêm, xóa, stack, dùng)
    │   ├── equipment_component.gd           # [CẬP NHẬT M3.1] Quản lý 2 ô trang bị & thẩm định type an toàn khi load
    │   ├── inventory_ui.gd                  # Controller giao diện túi đồ, lưới 16 ô, xem chi tiết & nút bấm
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ đẹp mắt, hỗ trợ chuột và cảm ứng
    ├── loot\                                # HỆ THỐNG RƠI ĐỒ VÀ NHẶT VẬT PHẨM
    │   ├── loot_table.gd                    # Resource định nghĩa bảng tỷ lệ rơi đồ của quái vật
    │   ├── item_pickup.gd                   # [CẬP NHẬT M3.1] Gán pickup_id ổn định, tự hủy nếu đã nhặt trước đó
    │   └── item_pickup.tscn                 # Scene vật phẩm rơi với hiệu ứng nhấp nhô lơ lửng
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # [CẬP NHẬT M3.1] Quản lý quest, lưu enemy_id chuỗi ổn định xuyên suốt
    ├── save\                                # HỆ THỐNG LƯU / TẢI TIẾN TRÌNH OFFLINE
    │   └── save_manager.gd                  # [VIẾT LẠI M3.1] Ghi nguyên tử an toàn (atomic), backup .bak, validate & clamp toàn bộ
    ├── ui\
    │   ├── game_ui.gd                       # HUD, thanh máu, phím I mở túi đồ, PauseMenu tích hợp Save Game
    │   ├── game_ui.tscn                     # CanvasLayer giao diện in-game
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập, Esc đóng túi đồ trước
    │   ├── main_menu.gd                     # Màn hình chính: Chơi mới (xác nhận ghi đè), Tiếp tục, Thoát
    │   └── main_menu.tscn                   # Scene Main Menu
    └── world\
        ├── noctis_forest.gd                 # [CẬP NHẬT M3.1] Quản lý pickup nhặt/rơi, khôi phục trạng thái thế giới
        ├── noctis_forest.tscn               # Màn chơi Bìa Rừng Noctis với ID pickup ổn định cho làng
        ├── test_level.gd                    # Màn test M1 cũ
        └── test_level.tscn
```

---

## 2. Nâng cấp cốt lõi trong phiên bản M3.1

### 2.1. Quản lý trạng thái vật phẩm trên thế giới (World Pickup Persistence)
- **Vật phẩm đặt sẵn (Pre-placed Pickups):**
  - Gán `pickup_id` cố định: `pickup_village_potion_1`, `pickup_village_sword_1`, `pickup_village_amulet_1`.
  - Khi nhặt, ID được ghi vào `collected_pickup_ids` trong bản lưu. Khi tải game, nếu ID đã có trong danh sách đã nhặt, node tự động `queue_free()`, **không xuất hiện lần hai**.
- **Vật phẩm quái rơi (Dynamic Drops):**
  - Quái vật rơi đồ được gán cờ `is_dynamic = true` và `pickup_id` duy nhất dạng `drop_<item_id>_<timestamp>_<rand>`.
  - Nếu quái chết và rơi đồ nhưng Player chưa nhặt trước khi Lưu: Vị trí và số lượng vật phẩm rơi được lưu vào mảng `dropped_pickups`. Khi Tải, thế giới tái tạo chính xác các vật phẩm này trên mặt đất.
  - Khi nhặt đồ rơi thành công rồi Lưu/Tải: Vật phẩm KHÔNG bị nhân bản trên mặt đất.

### 2.2. Kiến trúc SaveManager nguyên tử (Atomic & Safe Save System)
- **Không bao giờ xóa file save cũ trước khi hoàn tất ghi:**
  1. Dữ liệu được ghi ra file tạm `.tmp`.
  2. Mở lại file tạm đọc và parse JSON để xác minh toàn vẹn cú pháp.
  3. Tạo bản sao lưu dự phòng `.bak` từ file save hiện tại (nếu có).
  4. Đổi tên file tạm `.tmp` đè lên file save chính thức.
  5. Nếu bất kỳ bước nào thất bại, hệ thống khôi phục ngay từ `.bak`, đảm bảo người chơi **không bao giờ bị mất save** khi xảy ra lỗi đột ngột.
- **Thẩm định dữ liệu sâu (Deep Validation & Clamping):**
  - Tọa độ Player: Giới hạn trong kích thước bản đồ hợp lệ `(-1000..5000, -500..1500)`.
  - HP / MP: Clamp trong khoảng `[0, Max]` (không bị âm hoặc vượt trần).
  - Vàng (Gold): Clamp `>= 0`.
  - Túi đồ: Bỏ qua slot rỗng, kiểm tra `ItemDatabase.has_item(id)` và clamp số lượng `[1, max_stack]`.
  - Trang bị: Kiểm tra bắt buộc đúng phân loại item (`WEAPON` cho slot vũ khí, `ACCESSORY` cho slot bùa/phụ kiện). Nếu file JSON bị sửa đổi hoặc gắn sai loại, tự động loại bỏ để chống crash.
  - Tiến độ nhiệm vụ: Validate `kill_count` trong khoảng `[0, required_kills]`.

### 2.3. Định danh kẻ địch ổn định (Stable Enemy ID Tracking)
- Kẻ địch trong thế giới có định danh chuỗi ổn định (`enemy_forest_1`, `enemy_forest_2`, `enemy_forest_3`).
- `QuestManager` lưu danh sách tiêu diệt bằng mảng chuỗi `_killed_enemy_ids: Array[String]`, không dựa vào `get_instance_id()` tạm thời của engine. Nhờ đó, trạng thái nhiệm vụ và danh sách quái đã diệt được đồng bộ hoàn hảo sau khi Save/Load.

### 2.4. Cách ly hoàn toàn dữ liệu kiểm thử (Test Isolation)
- Hỗ trợ `SaveManager.custom_save_path`: Toàn bộ các script test (`test_m3_1_flow.gd`, `test_m3_flow.gd`) sử dụng file test riêng (`user://noctelyra_m3_1_test.json`), tự động dọn dẹp sau khi chạy.
- File save thật của người chơi (`user://noctelyra_slot1.json`) được bảo toàn 100%, không bị ảnh hưởng hay ghi đè bởi bộ kiểm thử tự động.

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

### 5.1. Kết quả kiểm thử M3.1 (`test_m3_1_flow.gd`) — 41/41 Tests PASS (100%)

Chạy thực tế qua lệnh:
`& "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "d:\project\game\NOCTELYRA" -s "test_m3_1_flow.gd"`

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M3.1] INTEGRATION TEST SUITE STARTING 
==================================================

--- TEST 1: Nhặt vật phẩm đặt sẵn -> Save -> Tạo lại World -> Load -> Không xuất hiện lần 2 ---
  [PASS] Vật phẩm Kiếm đặt sẵn có pickup_id ổn định ('pickup_village_sword_1')
  [PASS] Player đã nhặt được Kiếm Ánh Trăng
  [PASS] Đã trang bị Kiếm, sát thương đạt 35
  [PASS] pickup_village_sword_1 đã được ghi vào collected_pickup_ids của world
  [PASS] Lưu game thành công vào test save
  [PASS] Nạp lại bản lưu vào World mới thành công
  [PASS] Player vẫn giữ nguyên trang bị Kiếm Ánh Trăng
  [PASS] Sát thương vẫn duy trì 35 sau khi tải
  [PASS] Kiếm đặt sẵn tại làng ĐÃ BỊ LOẠI BỎ, không xuất hiện lần hai!

--- TEST 2: Quái chết và rơi đồ -> Chưa nhặt -> Save -> Load -> Vật phẩm vẫn còn ---
  [PASS] Thế giới ghi nhận ít nhất 1 vật phẩm rơi động chưa nhặt (thực tế: 1)
  [PASS] Vật phẩm rơi từ quái chưa nhặt được khôi phục chính xác tại tọa độ (2500, 630)

--- TEST 3: Nhặt đồ rơi -> Save -> Load -> Không bị nhân bản ---
  [PASS] Đã nhặt 3 mana_shard vào túi
  [PASS] Túi đồ giữ đúng số lượng mana_shard
  [PASS] Vật phẩm rơi đã nhặt KHÔNG bị nhân bản trên mặt đất sau khi Load!

--- TEST 4: Inventory đầy -> Vật phẩm không bị mất trên đất ---
  [PASS] Túi đầy 16/16: Pickup không bị nuốt mất
  [PASS] Vật phẩm vẫn nằm nguyên vẹn trên mặt đất

--- TEST 5: Save lỗi -> Giữ nguyên bản lưu trước đó (Atomic Safety) ---
  [PASS] Đã có bản lưu hợp lệ hiện hữu
  [PASS] Hàm save_game trả về false khi gặp lỗi dữ liệu đầu vào
  [PASS] Bản lưu hợp lệ trước đó vẫn nguyên vẹn 100%, không bị xóa hay ghi đè hỏng

--- TEST 6: JSON sai cấu trúc -> Continue không crash & Validate an toàn ---
  [PASS] Hàm load_game xử lý an toàn không crash khi gặp kiểu dữ liệu sai
  [PASS] HP được clamp về khoảng an toàn (0 - 100)
  [PASS] MP được clamp không vượt quá Max MP
  [PASS] Tọa độ Player được clamp trong giới hạn bản đồ hợp lệ
  [PASS] Vàng được clamp >= 0, không bị âm
  [PASS] Vũ khí không tồn tại tự động bị loại bỏ
  [PASS] Trang bị sai loại tự động bị loại bỏ

--- TEST 7: Nhiệm vụ 2/3 -> Save -> Thoát World -> Continue -> Giữ đúng tiến độ ---
  [PASS] Nhiệm vụ vẫn ở trạng thái ACTIVE
  [PASS] Tiến độ nhiệm vụ giữ chính xác 2/3
  [PASS] Số vàng giữ đúng 30 G

--- TEST 8: Quest COMPLETED -> Continue -> Không nhận lại 50 vàng ---
  [PASS] Nhiệm vụ đã COMPLETED
  [PASS] Nhận thưởng 50 Vàng lần đầu (30 + 50 = 80 G)
  [PASS] Nhiệm vụ phục hồi trạng thái COMPLETED
  [PASS] complete_quest từ chối trả thưởng lần 2
  [PASS] Vàng vẫn giữ nguyên đúng 80 G, không nhận thêm thưởng lặp lại

--- TEST 9: Cách ly dữ liệu kiểm thử -> File save thật không bị ảnh hưởng ---
  [PASS] File save thật vẫn tồn tại
  [PASS] Nội dung file save thật hoàn toàn KHÔNG BỊ THAY ĐỔI hay ghi đè trong suốt bài test!

--- TEST 10: Kiểm tra hồi quy các chức năng cốt lõi M0-M2.1 ---
  [PASS] NPC Elyra collision_layer = 0 (Player xuyên người mượt mà)
  [PASS] Hệ thống nhảy đôi M0 hoạt động
  [PASS] PauseController hoạt động
  [PASS] Pause game thành công
  [PASS] Resume game thành công

==================================================
 [NOCTELYRA M3.1] KẾT QUẢ KIỂM THỬ TỔNG HỢP:
 Tổng số test: 41 | Đạt: 41 | Thất bại: 0
==================================================
>>> ALL 10 M3.1 REQUIREMENT CATEGORIES PASSED 100%! <<<
```

### 5.2. Kết quả kiểm thử hồi quy M3 (`test_m3_flow.gd`) — 67/67 Tests PASS (100%)
Toàn bộ 15 giai đoạn kiểm thử M3 (thêm, stack, dùng bình máu, trang bị, tháo đồ, tính toán chỉ số, lưu tải cơ bản) đạt 67/67 tests PASS.

### 5.3. Kết quả kiểm thử hồi quy M2.1 (`test_m2_1_flow.gd`) — 42/42 Tests PASS (100%)
Toàn bộ vòng lặp nhiệm vụ, FSM hội thoại NPC Elyra, tiêu diệt quái, nhận thưởng đạt 42/42 tests PASS.

---

## 6. Danh sách lỗi đã xử lý triệt để trong M3.1

| STT | Vấn đề phát hiện | Giải pháp kiến trúc trong M3.1 | Kết quả xác minh |
| :--- | :--- | :--- | :--- |
| 1 | Vật phẩm đặt sẵn xuất hiện lại sau khi Load dù đã nhặt | Gán `pickup_id` ổn định, ghi vào `collected_pickup_ids`, tự `queue_free()` khi khởi tạo nếu đã nhặt | Test 1 PASS |
| 2 | Vật phẩm rơi từ quái chưa nhặt bị biến mất sau khi Save/Load | Thu thập và nạp lại danh sách `dropped_pickups` với vị trí và số lượng đầy đủ | Test 2 PASS |
| 3 | Vật phẩm rơi bị nhân bản nếu đã nhặt rồi Save/Load | Tái tạo có chọn lọc, đánh dấu `is_dynamic` và đồng bộ túi đồ chính xác | Test 3 PASS |
| 4 | Lưu game thất bại có nguy cơ xóa trắng file save cũ | Triển khai Atomic Write với file `.tmp`, sao lưu `.bak`, hoàn tác khi lỗi | Test 5 PASS |
| 5 | Dữ liệu save bị sửa hoặc sai kiểu gây crash game | Bổ sung hàm validation & clamping toàn diện (HP, MP, Pos, Gold, Inventory, Equipment) | Test 6 PASS |
| 6 | Gắn nhầm Consumable/Material vào slot Weapon/Accessory | Kiểm tra đối chiếu `item_type` trong `EquipmentComponent.load_from_dict()` | Test 6 PASS |
| 7 | Nhận lại phần thưởng nhiệm vụ 50 Vàng nhiều lần sau khi Continue | `QuestManager` ghi nhận trạng thái `COMPLETED` và cấm gọi lại trả thưởng | Test 8 PASS |
| 8 | Test tự động ghi đè file save thật của người chơi | Thêm cơ chế `custom_save_path` cho test runner, bảo vệ `user://noctelyra_slot1.json` | Test 9 PASS |

---

## 7. Giới hạn đã biết (Known Limitations)

1. **Phạm vi M3.1:** Phiên bản này tập trung hoàn thiện hệ thống dữ liệu, độ ổn định lưu/tải thế giới và bảo vệ tính toàn vẹn của game chơi đơn. Chưa triển khai Boss chiến, hệ thống Chế tạo (Crafting) hay chế độ Multiplayer (sẽ được thực hiện trong các Milestone tiếp theo).
2. **Kéo thả slot (Drag & Drop):** Giao diện Túi đồ hiện tối ưu hóa cho tương tác Click chọn / Chạm nút trên màn hình cảm ứng; thao tác kéo thả tự do giữa các ô sẽ được bổ sung ở bản nâng cấp UI.

---

## 8. Hướng dẫn chạy và kiểm thử

- **Chạy game chơi thử ngay:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
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

# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M3 FINAL)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M3)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, sơ đồ & kết quả kiểm thử
├── CODE_EXPORT.txt                 # Mã nguồn tổng hợp toàn dự án cho AI review
├── test_m3_flow.gd                 # [MỚI M3] Kịch bản kiểm thử tự động 15 giai đoạn M3 (67/67 tests PASS)
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
    ├── inventory\                           # [MỚI M3] HỆ THỐNG VẬT PHẨM & TRANG BỊ
    │   ├── item_definition.gd               # Resource định nghĩa vật phẩm chuẩn (ID, tên, loại, chỉ số, công dụng)
    │   ├── item_database.gd                 # Registry tra cứu vật phẩm ổn định theo ID
    │   ├── inventory_component.gd           # Component quản lý túi đồ 16 ô (thêm, xóa, stack, dùng)
    │   ├── equipment_component.gd           # Component quản lý 2 ô trang bị (Weapon, Accessory) & tính chỉ số
    │   ├── inventory_ui.gd                  # Controller giao diện túi đồ, lưới 16 ô, xem chi tiết & nút bấm
    │   └── inventory_ui.tscn                # Scene giao diện túi đồ đẹp mắt, hỗ trợ chuột và cảm ứng
    ├── loot\                                # [MỚI M3] HỆ THỐNG RƠI ĐỒ VÀ NHẶT VẬT PHẨM
    │   ├── loot_table.gd                    # Resource định nghĩa bảng tỷ lệ rơi đồ của quái vật
    │   ├── item_pickup.gd                   # Entity vật phẩm rơi trên mặt đất, tự nhặt khi chạm
    │   └── item_pickup.tscn                 # Scene vật phẩm rơi với hiệu ứng nhấp nhô lơ lửng
    ├── quest\
    │   ├── quest_data.gd                    # Resource dữ liệu nhiệm vụ (4 trạng thái FSM)
    │   └── quest_manager.gd                 # Quản lý vòng lặp nhiệm vụ, tiến độ 3/3 và trả thưởng Vàng
    ├── save\                                # [MỚI M3] HỆ THỐNG LƯU / TẢI TIẾN TRÌNH OFFLINE
    │   └── save_manager.gd                  # Lưu file JSON user://noctelyra_slot1.json ghi tạm nguyên tử
    ├── ui\
    │   ├── game_ui.gd                       # HUD, thanh máu, phím I mở túi đồ, PauseMenu tích hợp Save Game
    │   ├── game_ui.tscn                     # CanvasLayer giao diện in-game
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập, Esc đóng túi đồ trước
    │   ├── main_menu.gd                     # Màn hình chính: Chơi mới (xác nhận ghi đè), Tiếp tục, Thoát
    │   └── main_menu.tscn                   # Scene Main Menu
    └── world\
        ├── noctis_forest.gd                 # Main Scene: kết nối rơi đồ, lưu danh sách quái đã diệt
        ├── noctis_forest.tscn               # Màn chơi Bìa Rừng Noctis đặt sẵn các vật phẩm test
        ├── test_level.gd                    # Màn test M1 cũ (vẫn được lưu giữ)
        └── test_level.tscn
```

---

## 2. Sơ đồ kiến trúc Module M3

```text
               ┌────────────────────────────────────────────────────────┐
               │                       MainMenu                         │
               │    [Continue (có save)]   [New Game]   [Quit]          │
               └───────────────────────────┬────────────────────────────┘
                                           │
                                           ▼
               ┌────────────────────────────────────────────────────────┐
               │                  NoctisForest (World)                  │
               │                                                        │
               │   ┌──────────────┐   ┌──────────────┐   ┌───────────┐  │
               │   │    Player    │   │  NPC Elyra   │   │  Enemies  │  │
               │   │ ──────────── │   │ ──────────── │   │ ───────── │  │
               │   │ Inventory    │   │ Dialogue [E] │   │ LootTable │  │
               │   │ Equipment    │   │ Quest Loop   │   │ Drops [M] │  │
               │   │ Combat / HP  │   └──────────────┘   └─────┬─────┘  │
               │   └──────┬───────┘                            │        │
               │          │ (nhặt đồ khi còn chỗ)              │ rơi đồ │
               │          ▼                                    ▼        │
               │   ┌─────────────────────────────────────────────────┐  │
               │   │            ItemPickup (Vật phẩm rơi)            │  │
               │   └─────────────────────────────────────────────────┘  │
               └───────────────────────────┬────────────────────────────┘
                                           │
         ┌─────────────────────────────────┼─────────────────────────────────┐
         ▼                                 ▼                                 ▼
┌──────────────────┐             ┌──────────────────┐             ┌──────────────────┐
│   GameUI (HUD)   │             │   SaveManager    │             │   ItemDatabase   │
│ ──────────────── │             │ ──────────────── │             │ ──────────────── │
│ HP/MP, Vàng, Q   │             │ user://slot1.json│             │ mana_shard       │
│ Inventory UI [I] │ ◄────────── │ Atomic tmp write │             │ health_potion    │
│ Pause Menu [Esc] │  (AutoSave  │ Defeated Enemies │             │ moonsteel_sword  │
│ [Save Game Btn]  │   khi xong) │ Clamping & Safe  │             │ moon_amulet      │
└──────────────────┘             └──────────────────┘             └──────────────────┘
```

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
| **I** | **Túi đồ (Inventory)** | **[MỚI M3]** Mở/đóng Túi đồ & Trang bị (không pause thế giới) |
| **Esc** | Pause / Thoát | Đóng túi đồ nếu đang mở; hoặc Tạm dừng / Tiếp tục game |

---

## 4. Chi tiết 4 vật phẩm ban đầu

1. **Tinh thể Ma lực (`mana_shard`)**:
   - Loại: *Nguyên liệu (Material)*. Xếp chồng tối đa 99. Giá trị: 5 Vàng.
   - 100% rơi từ 3 sinh vật ma nhiễm trong Rừng Hắc Nguyệt.
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

File kiểm thử tích hợp đầy đủ [`test_m3_flow.gd`](file:///D:/project/game/NOCTELYRA/test_m3_flow.gd) được bàn giao trực tiếp trong project. Đã chạy thử nghiệm thực tế bằng Godot Console (`Godot_v4.3-stable_win64_console.exe --headless -s test_m3_flow.gd`):

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M3] INTEGRATION TEST SUITE STARTING   
==================================================
  [PASS] Player khởi tạo thành công
  [PASS] InventoryComponent gắn vào Player thành công
  [PASS] EquipmentComponent gắn vào Player thành công
  [PASS] InventoryUI tích hợp trong GameUI thành công

--- TEST 1: Thêm vật phẩm vào Inventory ---
  [PASS] add_item thêm đủ 5 mana_shard (không thừa)
  [PASS] Tổng số lượng mana_shard trong túi là 5
  [PASS] Ô số 0 lưu đúng ID và số lượng 5

--- TEST 2: Stack vật phẩm đúng số lượng ---
  [PASS] Ô 0 cộng dồn thành 95
  [PASS] Thêm 10 mana_shard thành công
  [PASS] Ô 0 đạt giới hạn max_stack 99
  [PASS] Ô 1 tự động nhận 6 phần tử tràn stack
  [PASS] Tổng số mana_shard trên 2 ô là 105

--- TEST 3: Inventory đầy thì không làm mất vật phẩm trên đất ---
  [PASS] Kiểm tra can_add_item trả về false khi túi đầy 16/16
  [PASS] Pickup KHÔNG bị nhặt khi túi đồ đầy
  [PASS] Pickup vẫn tồn tại nguyên vẹn trên mặt đất, không bị mất
  [PASS] Túi đồ không có kiếm vì không nhặt được

--- TEST 4: Nhặt một Pickup không bị cộng hai lần ---
  [PASS] Đã có 1 ô trống, có thể nhặt kiếm
  [PASS] Pickup1 đã được nhặt thành công
  [PASS] Túi đồ nhận đúng 1 kiếm
  [PASS] Cơ chế chống nhặt trùng: Không bị cộng lần thứ 2

--- TEST 5: Sử dụng bình máu hồi đúng 30 HP và giảm 1 bình ---
  [PASS] HP ban đầu là 40/100
  [PASS] Sử dụng bình máu thành công
  [PASS] HP hồi đúng 30 đơn vị (40 -> 70)
  [PASS] Số lượng bình giảm từ 3 xuống 2
  [PASS] HP hồi đầy 100 (không vượt Max HP)
  [PASS] Không thể sử dụng bình máu khi Player đã chết (HP = 0)
  [PASS] Bình máu không bị trừ khi dùng thất bại

--- TEST 6: Trang bị kiếm tăng sát thương từ 25 lên 35 ---
  [PASS] Sát thương cơ bản ban đầu là 25
  [PASS] Trước đó không có vũ khí
  [PASS] Đã trang bị Kiếm Ánh Trăng
  [PASS] Sát thương tăng chính xác lên 35 (25 + 10)

--- TEST 7: Tháo kiếm trả sát thương về 25 ---
  [PASS] Tháo ra đúng Kiếm Ánh Trăng
  [PASS] Ô vũ khí hiện đang trống
  [PASS] Sát thương được hoàn trả chính xác về 25

--- TEST 8: Trang bị/tháo bùa thay đổi Max MP đúng 20 ---
  [PASS] Max MP cơ bản ban đầu là 60
  [PASS] Đã trang bị Bùa Nguyệt Quang
  [PASS] Max MP tăng chính xác lên 80 (60 + 20)
  [PASS] Ô phụ kiện hiện đang trống
  [PASS] Max MP hoàn trả chính xác về 60
  [PASS] Current MP tự động giới hạn về 60, không bị tràn

--- TEST 9: Không cộng dồn chỉ số khi equip/unequip lặp lại ---
  [PASS] Trang bị lặp lại 3 lần: Sát thương vẫn giữ nguyên 35, không bị cộng dồn
  [PASS] Trang bị lặp lại bùa: Max MP vẫn giữ nguyên 80
  [PASS] Sau khi tháo, cả hai chỉ số trở lại đúng giá trị gốc ban đầu

--- TEST 10: Lưu Inventory và Equipment rồi tải lại đúng ---
  [PASS] Lưu game thành công vào file save slot 1
  [PASS] RAM: Đã dọn sạch túi đồ
  [PASS] RAM: Đã tháo sạch trang bị
  [PASS] Tải game từ file save thành công
  [PASS] Phục hồi đúng 18 mana_shard
  [PASS] Phục hồi đúng 4 health_potion
  [PASS] Phục hồi đúng trang bị Kiếm Ánh Trăng
  [PASS] Phục hồi đúng trang bị Bùa Nguyệt Quang
  [PASS] Chỉ số sát thương tính toán đúng 35 sau khi tải
  [PASS] Chỉ số Max MP tính toán đúng 80 sau khi tải

--- TEST 11: Lưu và tải trạng thái nhiệm vụ 2/3 ---
  [PASS] Phục hồi đúng trạng thái nhiệm vụ ACTIVE
  [PASS] Phục hồi đúng tiến độ nhiệm vụ 2/3
  [PASS] Phục hồi đúng số Vàng 75 G

--- TEST 12: Quái đã chết trước khi save không bị phục hồi sai sau khi load ---
  [PASS] Quái enemy_forest_1 đã chết trước khi save không xuất hiện lại

--- TEST 13: Phần thưởng nhiệm vụ không nhận được lần hai ---
  [PASS] complete_quest trả về false khi quest đã COMPLETED
  [PASS] Vàng không bị cộng thêm lần 2

--- TEST 14: File save hỏng không làm game crash ---
  [PASS] Hàm load_game trả về false khi file save hỏng JSON
  [PASS] Game không bị crash khi load file hỏng, Player vẫn an toàn trong tree

--- TEST 15: Kiểm tra hồi quy các tính năng M0/M1/M2 ---
  [PASS] NPC Elyra collision_layer = 0 (xuyên người)
  [PASS] Hệ thống Double Jump M0 nguyên vẹn
  [PASS] PauseController pause game thành công
  [PASS] PauseController resume game thành công
  [PASS] Mở InventoryUI thành công
  [PASS] Đóng InventoryUI thành công

==================================================
 [NOCTELYRA M3] KẾT QUẢ KIỂM THỬ TỔNG HỢP:
 Tổng số test: 67 | Đạt: 67 | Thất bại: 0
==================================================
>>> ALL 15 M3 REQUIREMENT PHASES PASSED 100%! <<<
```

---

## 6. Báo cáo lỗi còn tồn tại (Known Issues & Limitations)

- **Cơ chế lưu offline tạm thời:** Dữ liệu lưu tại `user://noctelyra_slot1.json` là bản lưu client-side cho chơi đơn. Khi tiến lên giai đoạn MMO-lite, toàn bộ dữ liệu vật phẩm, trang bị và kinh tế sẽ do Dedicated Server quản lý qua Authoritative RPC.
- **Kéo - thả & chia stack:** UI M3 hiện tại sử dụng cơ chế Click chọn và nhấn nút thao tác (Use, Equip, Unequip, Drop) để tương thích tối đa cho cả chuột PC và màn hình cảm ứng Mobile; tính năng kéo thả slot (drag & drop) và chia stack số lượng sẽ được phát triển ở bản tối ưu UI tiếp theo.

---

## 7. Hướng dẫn chạy và trải nghiệm trực tiếp

- **Chạy game test ngay:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Chạy kiểm thử tự động M3:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --path "D:\project\game\NOCTELYRA" --headless -s test_m3_flow.gd
  ```
- **Quy trình trải nghiệm vòng lặp gameplay hoàn chỉnh:**
  1. Menu chính xuất hiện: Chọn **Chơi mới (New Game)** để bước vào Làng Ánh Nguyệt.
  2. Tại làng, có sẵn các vật phẩm thử nghiệm rơi trên đất: 2 Bình máu, 1 Kiếm Ánh Trăng, 1 Bùa Nguyệt Quang. Đi qua để nhặt vào túi đồ.
  3. Nhấn phím **I** để mở Túi đồ. Click vào Kiếm và bấm **Trang bị** (Sát thương tăng từ 25 -> 35). Click vào Bùa và bấm **Trang bị** (Max MP tăng từ 60 -> 80).
  4. Gặp **NPC Elyra**, nhấn **E** nhận nhiệm vụ tiêu diệt 3 sinh vật ma hóa.
  5. Tiến vào Rừng Hắc Nguyệt, chém kiếm (J) và bắn phép (K) hạ gục 3 quái vật. Mỗi quái vật rơi ra 1 Tinh thể Ma lực (`mana_shard`). Bước qua nhặt.
  6. Nếu mất máu, nhấn **I** mở túi, click vào Bình Sinh Lực và bấm **Dùng** để hồi phục 30 HP.
  7. Nhấn **Esc** mở Pause Menu, bấm **Save Game** để lưu lại tiến trình bất kỳ lúc nào.
  8. Sau khi diệt đủ 3/3 quái, quay về gặp Elyra nhấn **E** trả nhiệm vụ: Nhận 50 Vàng, hồi đầy HP/MP và game tự động lưu tiến trình.
  9. Thoát game ra Menu chính, chọn **Tiếp tục (Continue)**: Game phục hồi nguyên vẹn vị trí, HP/MP, túi đồ, trang bị và quái đã chết không bị hồi sinh sai!

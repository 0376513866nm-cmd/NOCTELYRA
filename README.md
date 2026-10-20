# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M4.1 STABILIZATION FINAL)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M4.1 STABILIZATION)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, boss guide & kết quả kiểm thử M4.1
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M4.1)
├── test_m4_flow.gd                 # [CẬP NHẬT M4.1] Kịch bản kiểm thử 16 hạng mục Boss M4.1 (75/75 tests PASS 100%)
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
    ├── boss\                                # MODULE BOSS LUNARETH — LINH LỘC NGUYỆT THỰC (M4.1 STABILIZED)
    │   ├── boss_lunareth.gd                 # [SỬA M4.1] Bất tử 1.3s Phase Transition, reset toàn diện, spawn shockwave đúng thứ tự
    │   ├── boss_lunareth.tscn               # Scene Boss với HealthComponent (320 HP), Hurtbox, Hitbox, Detection
    │   ├── boss_visual.gd                   # [SỬA M4.1] Thêm reset_visual() khôi phục màu P1, sừng, aura và tắt telegraph
    │   ├── boss_shockwave.gd                # [SỬA M4.1] Đưa vào group 'boss_projectiles', áp dụng màu P1/P2 không phụ thuộc @onready
    │   └── boss_shockwave.tscn              # Scene projectile sóng xung kích
    ├── combat\
    │   ├── damage_info.gd                   # Struct dữ liệu sát thương & knockback
    │   ├── health_component.gd              # [SỬA M4.1] Thêm set_invulnerable_duration() và cancel_invulnerability()
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
    │   ├── item_database.gd                 # Đăng ký vật phẩm ID 5: eclipse_fragment (Mảnh Nguyệt Thực)
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
    │   └── save_manager.gd                  # [SỬA M4.1] Chặn lưu khi đang giao tranh Boss (is_boss_combat_active), cho phép lưu sau chiến thắng
    ├── ui\
    │   ├── game_ui.gd                       # [SỬA M4.1] Tích hợp kiểm tra is_boss_combat_active khi bấm Save, HUD Boss, thông báo chiến thắng
    │   ├── game_ui.tscn                     # CanvasLayer giao diện in-game
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập, Esc đóng túi đồ trước
    │   ├── main_menu.gd                     # Màn hình chính: Chơi mới (xác nhận ghi đè), Tiếp tục, Thoát
    │   └── main_menu.tscn                   # Scene Main Menu
    └── world\
        ├── magic_gate.gd                    # Cổng Ma Pháp cao 400px, chặn Dash & Double Jump, chỉ mở khi Quest COMPLETED
        ├── magic_gate.tscn                  # Scene Cổng Ma Pháp rào chắn vật lý
        ├── noctis_forest.gd                 # [SỬA M4.1] Dọn sạch boss_projectiles khi Retry và khi Defeated, checkpoint trước đấu trường (4120, 630)
        ├── noctis_forest.tscn               # Màn chơi hoàn chỉnh kết hợp Làng Elyra, Bìa Rừng, Quái vật và Đấu trường Boss
        ├── test_level.gd                    # Màn test M1 cũ
        └── test_level.tscn
```

---

## 2. Thông số Chiến đấu & Cơ chế Boss Lunareth (M4.1)

| Thông số / Thuộc tính | Giai đoạn 1 (Phase 1) | Giai đoạn 2 (Phase 2 - Hắc Nguyệt) | Ghi chú |
| :--- | :---: | :---: | :--- |
| **Máu cơ bản (HP)** | **320 / 320** | $\le$ **160** (50% HP) | Kích hoạt chuyển Phase duy nhất 1 lần |
| **Thời gian chuyển Phase** | — | **1.3 giây** | **Miễn nhiễm sát thương toàn bộ 1.3s**, hết 1.3s nhận sát thương bình thường |
| **Tốc độ di chuyển (Walk)** | **160 px/s** | **195 px/s** | Tiếp cận Player mượt mà |
| **Đòn 1: Nguyệt Giác Xung Kích** | **20 DMG**, lao 550 px/s | **20 DMG**, lao 620 px/s | Telegraph **0.7s** (sừng sáng rực + vệt đỏ trên sàn). Chống sát thương trùng |
| **Đòn 2: Hắc Nguyệt Chấn Ba** | **25 DMG**, sóng 380 px/s | **25 DMG**, sóng 440 px/s | Telegraph **0.9s** (dậm chân + vòng ma pháp). Né bằng nhảy |
| **Thời gian hồi đòn (Recovery)** | **1.4s** | **1.1s** (giảm ~21%) | Thời điểm vàng cho người chơi phản công |
| **Bảng màu hiển thị** | Xanh Lam Nguyệt (Cyan) | Tím Hắc Nguyệt (Dark Violet) | Được khôi phục hoàn toàn về Phase 1 khi Retry |

---

## 3. Các cải tiến & sửa lỗi trọng tâm trong Milestone M4.1

1. **Cơ chế chuyển Phase 2 hoàn hảo:**
   - Trong `HealthComponent`, bổ sung 2 phương thức: `set_invulnerable_duration(duration)` và `cancel_invulnerability()`.
   - Trong `BossLunareth`, trạng thái `PHASE_TRANSITION` kéo dài 1.3s đồng thời duy trì `is_invulnerable = true` xuyên suốt.
   - Khi kết thúc 1.3s, `cancel_invulnerability()` được gọi ngay lập tức đưa Boss về trạng thái nhận sát thương bình thường.
   - Cơ chế chỉ kích hoạt duy nhất một lần qua cờ `_phase_2_triggered`.

2. **Reset hoàn toàn Boss và Visual khi Retry:**
   - Bổ sung hàm `reset_visual()` trong `BossVisual`: đặt `is_phase_2 = false`, `VisualState.IDLE`, khôi phục màu sừng Lam Nguyệt (`P1_ANTLER_COLOR`), hào quang (`P1_AURA_COLOR`), và ẩn toàn bộ telegraph.
   - Trong `BossLunareth.reset_boss()`: khôi phục HP 320/320, trạng thái `DORMANT`, tắt hitbox tấn công, bật lại collision shape của hurtbox, xóa timer và danh sách đối tượng đã trúng đòn. Không tạo thêm bản sao Boss.

3. **Dọn dẹp projectile của Boss:**
   - Gán `BossShockwave` vào group `"boss_projectiles"`.
   - Bổ sung `clear_boss_projectiles()` trong `NoctisForest`, tự động gọi khi Player hy sinh & Retry, hoặc khi Boss bị thanh tẩy.
   - Không ảnh hưởng đến đạn phép của Player hay các vật phẩm rơi.

4. **Sửa thứ tự khởi tạo BossShockwave:**
   - Trong `BossShockwave`, tách logic cập nhật visual thành `_apply_visuals()`, tự động áp dụng màu sắc Phase 1 (Lam) hoặc Phase 2 (Tím) và tốc độ chính xác mà không bị phụ thuộc vào `@onready` khi gọi trước hoặc sau `add_child`.
   - Trong `BossLunareth._spawn_shockwaves()`, đưa `add_child` lên trước và cập nhật tọa độ thế giới chính xác.

5. **Bảo vệ toàn diện Save System:**
   - Bổ sung phương thức `SaveManager.is_boss_combat_active(world)`: kiểm tra cả cờ `boss_battle_started` của thế giới lẫn trạng thái FSM thực tế của Boss (`current_state != DORMANT` và `!= DEFEATED`).
   - Lớp `SaveManager.save_game()` từ chối lưu và trả về `false` khi đang trong combat Boss.
   - Nút Save trong Pause Menu thông báo chặn lưu rõ ràng.
   - Sau khi Boss bị thanh tẩy, autosave vẫn chạy thành công bình thường.
   - Vật phẩm thưởng rơi trên mặt đất khi túi đồ đầy được lưu vào `dropped_pickups` và khôi phục nguyên vẹn sau khi Load/Continue.
   - Tương thích ngược 100% với file save v1.0.0 (M3.2).

---

## 4. Báo cáo kiểm thử tự động thực tế trên Godot 4.3 Engine

### 4.1. Bộ test Boss M4.1 (`test_m4_flow.gd`) — 75/75 Tests PASS (100%)

Chạy thực tế qua lệnh:
`& "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "d:\project\game\NOCTELYRA" -s "test_m4_flow.gd"`

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M4.1] BOSS ENCOUNTER TEST SUITE START 
==================================================

--- CATEGORY 1: Khởi tạo Boss & Kiểm tra Cổng Ma Pháp khóa ban đầu ---
  [PASS] Boss Lunareth tồn tại trong scene
  [PASS] HP tối đa của Boss là 320
  [PASS] HP hiện tại của Boss là 320/320
  [PASS] Boss ban đầu ở trạng thái DORMANT
  [PASS] Boss bắt đầu ở Phase 1
  [PASS] Trận chiến Boss chưa bắt đầu
  [PASS] Cổng Ma Pháp đang ở trạng thái KHÓA
  [PASS] Va chạm vật lý của Cổng Ma Pháp đang BẬT

--- CATEGORY 2: Cổng vẫn khóa khi nhiệm vụ ở READY_TO_TURN_IN ---
  [PASS] Cổng Ma Pháp VẪN KHÓA khi nhiệm vụ ở READY_TO_TURN_IN (chưa trả quest)
  [PASS] Va chạm vật lý vẫn BẬT khi ở READY_TO_TURN_IN

--- CATEGORY 3: Kiểm thử va chạm vật lý thực tế của Cổng (Dash & Double Jump) ---
  [PASS] Dash bị chặn đứng bởi Cổng Ma Pháp (X: 3955.3 <= 4000)
  [PASS] Nhảy đôi trên không vẫn bị Cổng chặn hoàn toàn (X: 3954.0 <= 4000)

--- CATEGORY 4: Cổng Ma Pháp CHỈ MỞ khi nhiệm vụ chuyển sang COMPLETED ---
  [PASS] Cổng Ma Pháp đã MỞ khi nhiệm vụ đạt COMPLETED
  [PASS] Va chạm vật lý đã TẮT để cho phép người chơi đi qua
  [PASS] Player đi xuyên qua cổng đã mở thành công

--- CATEGORY 5: Kích hoạt Đấu trường & Rào chắn Arena khóa lại ---
  [PASS] Cờ boss_battle_started kích hoạt
  [PASS] Boss chuyển sang thức tỉnh
  [PASS] Rào chắn đấu trường khóa chặt Player bên trong
  [PASS] Thanh HUD Boss hiển thị trên màn hình

--- CATEGORY 6: Thời gian Telegraph thực tế (Charge 0.7s, Shockwave 0.9s) ---
  [PASS] Thời gian cảnh báo đòn Húc thực tế là 0.70s (yêu cầu >= 0.6s)
  [PASS] Hitbox húc TẮT trong thời gian Telegraph
  [PASS] Vùng cảnh báo đòn húc hiển thị
  [PASS] Thời gian cảnh báo đòn Chấn Ba thực tế là 0.90s (yêu cầu >= 0.8s)
  [PASS] Vòng ma pháp cảnh báo chấn ba hiển thị

--- CATEGORY 7: Kiểm thử sát thương thực tế & chống trùng đòn (Horn Charge) ---
  [PASS] Sát thương Horn Charge đúng 20.0
  [PASS] Lần húc đầu tiên THỰC SỰ gây sát thương: HP giảm từ 100 còn 80.0 (-20 DMG)
  [PASS] Cơ chế chống đòn trùng: Không gây thêm sát thương trong cùng lượt húc (HP giữ nguyên 80.0)

--- CATEGORY 8: Projectile BossShockwave (Tốc độ & Màu sắc Phase 1 / Phase 2) ---
  [PASS] Tốc độ sóng chấn ba Phase 1 là 380 px/s
  [PASS] Sát thương sóng chấn ba đúng 25 DMG
  [PASS] BossShockwave nằm trong group 'boss_projectiles'
  [PASS] Màu sắc sóng Phase 1 là tông Lam Nguyệt (Cyan/Blue)
  [PASS] Tốc độ sóng chấn ba Phase 2 tăng lên 440 px/s
  [PASS] Màu sắc sóng Phase 2 là tông Hắc Nguyệt (Dark Violet)
  [PASS] Shockwave gây đúng 25 DMG lên Player (HP: 80.0 -> 55.0)

--- CATEGORY 9: Miễn sát thương tuyệt đối trong toàn bộ 1.3s Phase Transition ---
  [PASS] Boss đã kích hoạt Phase 2 khi HP <= 160
  [PASS] Boss đang trong trạng thái PHASE_TRANSITION
  [PASS] Boss bật cờ bất tử khi bắt đầu chuyển phase
  [PASS] Đòn đánh bị từ chối ở đầu chuyển phase (taken == false)
  [PASS] HP vẫn giữ nguyên 160.0 không đổi
  [PASS] Boss VẪN BẤT TỬ ở giữa quá trình chuyển phase (t = 0.6s)
  [PASS] Đòn đánh bị từ chối ở giữa chuyển phase (không bị HealthComponent._process tắt sớm)
  [PASS] HP vẫn được bảo toàn nguyên vẹn 160.0

--- CATEGORY 10: Boss nhận sát thương trở lại bình thường sau khi chuyển Phase xong ---
  [PASS] Sau 1.3s, Boss kết thúc chuyển phase và sang RECOVERY
  [PASS] Cờ bất tử đã được gỡ bỏ an toàn, không bị bất tử vĩnh viễn
  [PASS] Boss nhận sát thương thành công sau khi hoàn tất chuyển phase
  [PASS] HP giảm chính xác còn 135.0 (160 - 25)
  [PASS] Phase 2 chỉ kích hoạt duy nhất một lần, không lặp lại

--- CATEGORY 11: Retry từ Phase 2 đưa màu sắc và trạng thái về chuẩn Phase 1 ---
  [PASS] Boss Visual hiện đang là Phase 2 (màu tím)
  [PASS] Boss logic trở về Phase 1 sau Retry
  [PASS] Boss AI trở về DORMANT sau Retry
  [PASS] HP Boss hồi phục đầy đủ 320/320
  [PASS] Boss Visual trở về Phase 1 sau Retry
  [PASS] Boss Visual state trở về IDLE
  [PASS] Hitbox tấn công tắt sau Retry
  [PASS] Hurtbox CollisionShape được khôi phục bật sau Retry

--- CATEGORY 12: Dọn dẹp sạch sẽ projectile khi Retry & Thanh Tẩy ---
  [PASS] Có projectile boss đang tồn tại
  [PASS] Không còn bất kỳ projectile Boss nào sót lại sau khi Retry

--- CATEGORY 13: Bảo vệ Save System (Chặn lưu khi đang giao tranh Boss) ---
  [PASS] Hệ thống nhận diện trận đánh Boss đang diễn ra
WARNING: SaveManager: Không thể lưu game trong khi trận đánh Boss đang diễn ra!
     at: push_warning (core/variant/variant_utility.cpp:1112)
  [PASS] SaveManager TỪ CHỐI lưu game khi đang giao chiến với Boss

--- CATEGORY 14: Đánh bại Boss, Autosave sau chiến thắng & Thưởng 100 Vàng + Mảnh Nguyệt Thực ---
  [PASS] Boss chuyển sang trạng thái DEFEATED
  [PASS] Cờ boss_defeated được xác lập
  [PASS] Nhận chính xác 100 Vàng thưởng
  [PASS] Nhận Mảnh Nguyệt Thực vào túi đồ
  [PASS] Chiến đấu đã kết thúc, không còn chặn lưu
  [PASS] Autosave sau chiến thắng chạy thành công hoàn hảo

--- CATEGORY 15: Túi đồ đầy -> Thưởng rơi mặt đất và khôi phục nguyên vẹn sau Save/Load ---
  [PASS] Mảnh Nguyệt Thực rơi trên mặt đất khi túi đồ đầy
  [PASS] Định danh pickup_id ổn định: drop_boss_eclipse_fragment
  [PASS] Lưu game chứa vật phẩm thưởng trên mặt đất thành công
  [PASS] Mảnh Nguyệt Thực rơi trên đất được PHỤC HỒI CHÍNH XÁC sau khi tải game
  [PASS] Player nhặt thành công Mảnh Nguyệt Thực vào túi sau khi dọn chỗ

--- CATEGORY 16: Tương thích ngược phiên bản Save 1.0.0 (M3.2) ---
  [PASS] has_save() chấp nhận bản lưu schema cũ v1.0.0
  [PASS] load_game() nạp thành công bản lưu v1.0.0 không lỗi
  [PASS] Boss mặc định chưa thanh tẩy trong bản lưu cũ

--- KIỂM TRA AN TOÀN DỮ LIỆU: File save thật không bị ảnh hưởng ---
  [PASS] File save thật vẫn tồn tại nguyên vẹn
  [PASS] Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI

==================================================
 [NOCTELYRA M4.1] KẾT QUẢ KIỂM THỬ TỔNG HỢP:
 Tổng số test: 75 | Đạt: 75 | Thất bại: 0
==================================================
>>> ALL M4.1 STABILIZATION TESTS PASSED 100%! <<<
```

### 4.2. Bảng kết quả kiểm thử toàn diện dự án
- **M4.1 STABILIZATION (`test_m4_flow.gd`):** **75 / 75 Tests PASS (100%)**
- **M3.2 FINAL (`test_m3_2_flow.gd`):** **50 / 50 Tests PASS (100%)**
- **M3.1 FINAL (`test_m3_1_flow.gd`):** **41 / 41 Tests PASS (100%)**
- **M3 FINAL (`test_m3_flow.gd`):** **67 / 67 Tests PASS (100%)**
- **M2.1 FINAL (`test_m2_1_flow.gd`):** **42 / 42 Tests PASS (100%)**
- **TỔNG CỘNG HỆ THỐNG:** **275 / 275 Tests PASS (100%)** không một lỗi lầm trên Godot 4.3 Engine!

---

## 5. Hướng dẫn chạy và kiểm thử

- **Chạy game chơi thử:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Xuất mã nguồn:** Click đúp vào file `export_code_for_ai.bat`.
- **Chạy bộ test M4.1:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m4_flow.gd
  ```
- **Chạy bộ test hồi quy M3.2:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m3_2_flow.gd
  ```

# NOCTELYRA — 2D Action RPG Cross-platform (Milestone M4 FINAL TEST CORRECTION)

Dự án game Fantasy 2D màn hình ngang phát triển bằng **Godot 4.3 (GDScript)**, hướng tới phát hành PC (Steam), Android và iOS.

---

## 1. Cấu trúc thư mục & Module dự án (Bản M4 FINAL)

```text
D:\project\game\NOCTELYRA\
├── .gitignore                      # Loại bỏ cache Godot (.godot/)
├── README.md                       # Tài liệu hướng dẫn, kiến trúc, boss guide & kết quả kiểm thử M4 Final
├── CODE_EXPORT.txt                 # Toàn bộ mã nguồn dự án cho AI review (đã cập nhật M4 Final)
├── test_m4_flow.gd                 # [CẬP NHẬT M4 FINAL] Kịch bản kiểm thử 17 hạng mục Boss M4 (87/87 tests PASS 100%)
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
    ├── boss\                                # MODULE BOSS LUNARETH — LINH LỘC NGUYỆT THỰC
    │   ├── boss_lunareth.gd                 # Bất tử 1.3s Phase Transition, reset toàn diện, spawn shockwave đúng thứ tự
    │   ├── boss_lunareth.tscn               # Scene Boss với HealthComponent (320 HP), Hurtbox, Hitbox, Detection
    │   ├── boss_visual.gd                   # reset_visual() khôi phục màu P1, sừng, aura và tắt telegraph
    │   ├── boss_shockwave.gd                # Projectile group 'boss_projectiles', màu P1/P2 không phụ thuộc @onready
    │   └── boss_shockwave.tscn              # Scene projectile sóng xung kích
    ├── combat\
    │   ├── damage_info.gd                   # Struct dữ liệu sát thương & knockback
    │   ├── health_component.gd              # Quản lý máu, MP, set_invulnerable_duration() và cancel_invulnerability()
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
    │   └── save_manager.gd                  # Chặn lưu khi đang giao tranh Boss (is_boss_combat_active), cho phép lưu sau chiến thắng
    ├── ui\
    │   ├── game_ui.gd                       # Kiểm tra is_boss_combat_active khi bấm Save, HUD Boss, thông báo chiến thắng
    │   ├── game_ui.tscn                     # CanvasLayer giao diện in-game
    │   ├── pause_controller.gd              # Quản lý Pause/Resume độc lập, Esc đóng túi đồ trước
    │   ├── main_menu.gd                     # Màn hình chính: Chơi mới (xác nhận ghi đè), Tiếp tục, Thoát
    │   └── main_menu.tscn                   # Scene Main Menu
    └── world\
        ├── magic_gate.gd                    # Cổng Ma Pháp tại X=4200 cao 400px, chặn Dash & Double Jump, chỉ mở khi Quest COMPLETED
        ├── magic_gate.tscn                  # Scene Cổng Ma Pháp rào chắn vật lý
        ├── noctis_forest.gd                 # Dọn sạch boss_projectiles khi Retry và khi Defeated, checkpoint trước đấu trường (4120, 630)
        ├── noctis_forest.tscn               # Màn chơi hoàn chỉnh kết hợp Làng Elyra, Bìa Rừng, Quái vật và Đấu trường Boss
        ├── test_level.gd                    # Màn test M1 cũ
        └── test_level.tscn
```

---

## 2. Thông số Chiến đấu & Cơ chế Boss Lunareth

| Thông số / Thuộc tính | Giai đoạn 1 (Phase 1) | Giai đoạn 2 (Phase 2 - Hắc Nguyệt) | Ghi chú |
| :--- | :---: | :---: | :--- |
| **Máu cơ bản (HP)** | **320 / 320** | $\le$ **160** (50% HP) | Kích hoạt chuyển Phase duy nhất 1 lần |
| **Thời gian chuyển Phase** | — | **1.3 giây** | **Miễn nhiễm sát thương toàn bộ 1.3s**, hết 1.3s nhận sát thương bình thường |
| **Tốc độ di chuyển (Walk)** | **160 px/s** | **195 px/s** | Tiếp cận Player mượt mà |
| **Đòn 1: Nguyệt Giác Xung Kích** | **20 DMG**, lao 550 px/s | **20 DMG**, lao 620 px/s | Telegraph **0.7s**. Va chạm vật lý PhysicsServer2D, chống sát thương trùng |
| **Đòn 2: Hắc Nguyệt Chấn Ba** | **25 DMG**, sóng 380 px/s | **25 DMG**, sóng 440 px/s | Telegraph **0.9s**. Va chạm vật lý PhysicsServer2D, tự hủy khi đâm trúng |
| **Thời gian hồi đòn (Recovery)** | **1.4s** | **1.1s** (giảm ~21%) | Thời điểm vàng cho người chơi phản công |
| **Bảng màu hiển thị** | Xanh Lam Nguyệt (Cyan) | Tím Hắc Nguyệt (Dark Violet) | Được khôi phục hoàn toàn về Phase 1 khi Retry |

---

## 3. Các điểm hiệu chỉnh trong đợt Final Test Correction

1. **Vị trí Cổng Ma Pháp & Kiểm thử va chạm vật lý thực tế:**
   - Cổng `MagicGate` thực tế tọa lạc tại $X = 4200, Y = 630$.
   - Kịch bản test Dash (800 px/s) và Double Jump (600 px/s) từ $X = 4120$ đã được cập nhật. Kết quả chứng minh Player bị chặn đứng cứng tại $X \approx 4164 \le 4175$ và tuyệt đối không thể chạm tới $X = 4200$. Nếu cố tình tắt collider của cổng, test sẽ **FAIL ngay lập tức**.
2. **Va chạm vật lý tự động qua Godot Physics Server:**
   - Thay vì chỉ gọi thủ công `_on_area_entered()`, kịch bản test sử dụng cơ chế phát hiện va chạm tự động của `PhysicsServer2D` (`await physics_frame`):
     - Đòn húc Horn Charge: Khi hitbox và hurtbox chồng lấn, engine vật lý tự phát hiện và trừ chính xác 20 HP. Khi tiếp tục chồng lấn qua nhiều frame physics tiếp theo, HP vẫn giữ nguyên 80 (chống sát thương trùng thực tế).
     - Đòn Shockwave: Engine vật lý tự phát hiện va chạm và trừ chính xác 25 HP, đồng thời projectile tự hủy (`queue_free`).
3. **Save/Continue sau khi đánh bại Lunareth:**
   - Kiểm tra lưu game sau khi thắng, giải phóng world, tạo instance world mới và `load_game`:
     - Trạng thái Boss bảo toàn `DEFEATED` (không hồi sinh).
     - Vàng bảo toàn chính xác (100 G, không tăng thêm).
     - Mảnh Nguyệt Thực giữ đúng 1 mảnh (không bị nhân đôi).
     - Gọi lại hàm phát thưởng không trao thêm phần thưởng lặp.
     - Kiểm tra trong scene chỉ tồn tại duy nhất 1 thực thể Boss (không sinh bản sao thứ hai).

---

## 4. Báo cáo kiểm thử tự động thực tế trên Godot 4.3 Engine

### 4.1. Bộ test Boss M4 Final (`test_m4_flow.gd`) — 87/87 Tests PASS (100%)

Chạy thực tế qua lệnh:
`& "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "d:\project\game\NOCTELYRA" -s "test_m4_flow.gd"`

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

==================================================
 [NOCTELYRA M4 FINAL] TEST SUITE STARTING         
==================================================

--- CATEGORY 1: Khởi tạo Boss & Vị trí Cổng Ma Pháp X=4200 ---
  [PASS] Boss Lunareth tồn tại trong scene
  [PASS] HP tối đa của Boss là 320
  [PASS] HP hiện tại của Boss là 320/320
  [PASS] Boss ban đầu ở trạng thái DORMANT
  [PASS] Boss bắt đầu ở Phase 1
  [PASS] Trận chiến Boss chưa bắt đầu
  [PASS] Cổng Ma Pháp tồn tại trong scene
  [PASS] Cổng Ma Pháp nằm chính xác tại tọa độ X=4200 (thực tế: 4200.0)
  [PASS] Cổng Ma Pháp đang ở trạng thái KHÓA
  [PASS] Va chạm vật lý của Cổng Ma Pháp đang BẬT

--- CATEGORY 2: Cổng vẫn khóa khi nhiệm vụ ở READY_TO_TURN_IN ---
  [PASS] Cổng Ma Pháp VẪN KHÓA khi nhiệm vụ ở READY_TO_TURN_IN (chưa trả quest)
  [PASS] Va chạm vật lý vẫn BẬT khi ở READY_TO_TURN_IN

--- CATEGORY 3: Kiểm thử va chạm vật lý thực tế của Cổng tại X=4200 (Dash & Double Jump) ---
  [PASS] Dash bị chặn đứng hoàn toàn bởi Cổng tại X=4200 (Player dừng tại X: 4164.0 <= 4175)
  [PASS] Player tuyệt đối không thể vượt qua Cổng khi đang khóa bằng Dash
  [PASS] Nhảy đôi trên không vẫn bị Cổng tại X=4200 chặn hoàn toàn (Player dừng tại X: 4156.0 <= 4175)
  [PASS] Player tuyệt đối không thể vượt qua Cổng khi đang khóa bằng Double Jump

--- CATEGORY 4: Cổng Ma Pháp CHỈ MỞ khi nhiệm vụ chuyển sang COMPLETED ---
  [PASS] Cổng Ma Pháp đã MỞ khi nhiệm vụ đạt COMPLETED
  [PASS] Va chạm vật lý đã TẮT để cho phép người chơi đi qua
  [PASS] Player đi xuyên qua cổng đã mở tại X=4200 thành công (X: 4252.0 > 4220)

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

--- CATEGORY 7: Va chạm vật lý thực tế qua Godot Physics Server (Horn Charge) ---
  [PASS] Sát thương Horn Charge đúng 20.0
  [PASS] Godot Physics Engine tự động phát hiện va chạm: Player mất 20 HP (100 -> 80)
  [PASS] Godot Physics chống sát thương trùng khi chồng lấn liên tục (HP giữ nguyên 80.0)

--- CATEGORY 8: Va chạm vật lý thực tế & Thuộc tính Projectile BossShockwave ---
  [PASS] Tốc độ sóng chấn ba Phase 1 là 380 px/s
  [PASS] Sát thương sóng chấn ba đúng 25 DMG
  [PASS] BossShockwave nằm trong group 'boss_projectiles'
  [PASS] Màu sắc sóng Phase 1 là tông Lam Nguyệt (Cyan/Blue)
  [PASS] Tốc độ sóng chấn ba Phase 2 tăng lên 440 px/s
  [PASS] Màu sắc sóng Phase 2 là tông Hắc Nguyệt (Dark Violet)
  [PASS] Godot Physics tự động phát hiện va chạm Shockwave: Player mất 25 HP (80 -> 55)
  [PASS] Shockwave tự hủy sau khi va chạm vật lý trúng Player

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
  [PASS] Nhận chính xác 100 Vàng thưởng (0 -> 100)
  [PASS] Nhận Mảnh Nguyệt Thực vào túi đồ
  [PASS] Chiến đấu đã kết thúc, không còn chặn lưu
  [PASS] Autosave sau chiến thắng chạy thành công hoàn hảo

--- CATEGORY 15: Save/Continue sau khi đánh bại Lunareth (Bảo toàn DEFEATED, không nhân đôi Vàng/Vật phẩm, không có Boss thứ 2) ---
  [PASS] Trạng thái boss_defeated vẫn là true sau khi Continue
  [PASS] Boss vẫn ở trạng thái DEFEATED sau khi Continue
  [PASS] Vàng không bị tăng thêm lần nữa (100 G)
  [PASS] Mảnh Nguyệt Thực không bị nhân đôi (đúng 1 mảnh)
  [PASS] Cơ chế chống nhận thưởng lặp: Vàng giữ nguyên sau khi gọi lại grant_boss_reward()
  [PASS] Cơ chế chống nhận thưởng lặp: Vật phẩm không bị trao lần 2
  [PASS] Chỉ duy nhất 1 thực thể Boss tồn tại trong scene (không xuất hiện Boss thứ hai)

--- CATEGORY 16: Túi đồ đầy -> Thưởng rơi mặt đất và khôi phục nguyên vẹn sau Save/Load ---
  [PASS] Mảnh Nguyệt Thực rơi trên mặt đất khi túi đồ đầy
  [PASS] Định danh pickup_id ổn định: drop_boss_eclipse_fragment
  [PASS] Lưu game chứa vật phẩm thưởng trên mặt đất thành công
  [PASS] Mảnh Nguyệt Thực rơi trên đất được PHỤC HỒI CHÍNH XÁC sau khi tải game
  [PASS] Player nhặt thành công Mảnh Nguyệt Thực vào túi sau khi dọn chỗ

--- CATEGORY 17: Tương thích ngược phiên bản Save 1.0.0 (M3.2) ---
  [PASS] has_save() chấp nhận bản lưu schema cũ v1.0.0
  [PASS] load_game() nạp thành công bản lưu v1.0.0 không lỗi
  [PASS] Boss mặc định chưa thanh tẩy trong bản lưu cũ

--- KIỂM TRA AN TOÀN DỮ LIỆU: File save thật không bị ảnh hưởng ---
  [PASS] File save thật vẫn tồn tại nguyên vẹn
  [PASS] Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI

==================================================
 [NOCTELYRA M4 FINAL] KẾT QUẢ KIỂM THỬ TỔNG HỢP:  
 Tổng số test: 87 | Đạt: 87 | Thất bại: 0
==================================================
>>> ALL M4 FINAL TESTS PASSED 100%! <<<
```

### 4.2. Bảng kết quả kiểm thử toàn diện dự án
- **M4 FINAL TEST SUITE:** **87 / 87 Tests PASS (100%)**
- **M3.2 FINAL Regression:** **50 / 50 Tests PASS (100%)**
- **M3.1 FINAL Regression:** **41 / 41 Tests PASS (100%)**
- **M3 FINAL Regression:** **67 / 67 Tests PASS (100%)**
- **M2.1 FINAL Regression:** **42 / 42 Tests PASS (100%)**
- **TỔNG CỘNG TOÀN DỰ ÁN:** **287 / 287 Tests PASS (100%)** trên Godot 4.3 Engine!

---

## 5. Hướng dẫn chạy và kiểm thử

- **Chạy game chơi thử:** Click đúp vào file `run_game.bat`.
- **Mở Godot Editor:** Click đúp vào file `open_editor.bat`.
- **Xuất mã nguồn:** Click đúp vào file `export_code_for_ai.bat`.
- **Chạy bộ test M4 Final:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m4_flow.gd
  ```
- **Chạy bộ test hồi quy M3.2:**
  ```powershell
  & "D:\program\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "D:\project\game\NOCTELYRA" -s test_m3_2_flow.gd
  ```

extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING MOBILE TOUCH CONTROLS (LIÊN QUÂN STYLE)")
	print("==================================================")

	var ui_scene = load("res://src/ui/game_ui.tscn")
	_assert(ui_scene != null, "Scene game_ui.tscn load thành công")
	var ui: GameUI = ui_scene.instantiate() as GameUI
	_assert(ui != null, "GameUI instantiate thành công")
	root.add_child(ui)
	await process_frame

	var touch_ctrl: TouchControls = ui.get_node_or_null("HUD/TouchControls") as TouchControls
	touch_ctrl.visible = true
	_assert(touch_ctrl != null, "HUD có node TouchControls")
	_assert(touch_ctrl.visible == true, "TouchControls đang hiển thị")

	# 1. TEST CẦN ANALOG JOYSTICK (BÊN TRÁI)
	print("\n--- TEST 1: Cần Điều Khiển Ảo Joystick (Bên Trái) ---")
	_assert(touch_ctrl.joystick_base_radius >= 60.0, "Joystick có bán kính đế mờ rộng rãi (>= 60px)")
	_assert(touch_ctrl.joystick_knob_radius >= 25.0, "Núm analog vừa vặn ngón cái")
	_assert(touch_ctrl.joystick_center.x < 300.0 and touch_ctrl.joystick_center.y > 400.0, "Joystick đặt ở góc dưới bên trái màn hình")

	# Kéo Joystick sang trái
	touch_ctrl._handle_touch_event(0, touch_ctrl.joystick_center, true)
	touch_ctrl._handle_drag_event(0, touch_ctrl.joystick_center + Vector2(-50, 0))
	_assert(Input.is_action_pressed("move_left"), "Kéo joystick sang trái kích hoạt action 'move_left'")

	# Kéo Joystick sang phải
	touch_ctrl._handle_drag_event(0, touch_ctrl.joystick_center + Vector2(50, 0))
	_assert(Input.is_action_pressed("move_right"), "Kéo joystick sang phải kích hoạt action 'move_right'")
	_assert(Input.get_action_strength("move_right") == 1.0, "Kéo cần gạt sang phải phát lực 1.0 (100% full run speed y hệt bàn phím PC)")
	_assert(not Input.is_action_pressed("move_left"), "Kéo sang phải tự nhả 'move_left'")

	# Thả tay khỏi Joystick
	touch_ctrl._handle_touch_event(0, touch_ctrl.joystick_center + Vector2(50, 0), false)
	_assert(not Input.is_action_pressed("move_right"), "Thả tay tự động nhả action di chuyển")
	_assert(touch_ctrl._joystick_current_pos == touch_ctrl.joystick_center, "Núm analog tự đàn hồi về tâm")

	# 2. TEST CỤM PHÍM BÊN PHẢI (CHUẨN PHONG CÁCH LIÊN QUÂN MOBILE)
	print("\n--- TEST 2: Cụm Nút Hành Động Liên Quân (Bên Phải) ---")
	_assert(touch_ctrl.btn_attack != null, "Nút Đánh Thường tồn tại")
	_assert(touch_ctrl.btn_attack.radius >= 45.0, "Nút Đánh Thường có kích thước LỚN NHẤT (bán kính >= 45px, đường kính ~100px)")
	_assert(touch_ctrl.btn_attack.action == "attack", "Nút lớn kích hoạt action 'attack'")

	# Kiểm tra các bóng chiêu thức vệ tinh xung quanh
	_assert(touch_ctrl.btn_jump != null, "Nút Nhảy vệ tinh tồn tại")
	_assert(touch_ctrl.btn_jump.action == "jump", "Nút Nhảy kích hoạt action 'jump'")
	_assert(touch_ctrl.btn_jump.center.y < touch_ctrl.btn_attack.center.y, "Nút Nhảy nằm phía trên nút đánh thường")

	_assert(touch_ctrl.btn_cast != null, "Nút Phép vệ tinh tồn tại")
	_assert(touch_ctrl.btn_cast.action == "cast_spell", "Nút Phép kích hoạt action 'cast_spell'")
	_assert(touch_ctrl.btn_cast.center.x < touch_ctrl.btn_attack.center.x, "Nút Phép nằm chếch góc trên-trái")

	_assert(touch_ctrl.btn_dash != null, "Nút Lướt vệ tinh tồn tại")
	_assert(touch_ctrl.btn_dash.action == "dash", "Nút Lướt kích hoạt action 'dash'")
	_assert(touch_ctrl.btn_dash.center.x < touch_ctrl.btn_attack.center.x, "Nút Lướt nằm chếch ngang bên trái")

	_assert(touch_ctrl.btn_interact != null, "Nút Tương Tác [E] tồn tại")
	_assert(touch_ctrl.btn_interact.action == "interact", "Nút Tương Tác kích hoạt action 'interact'")

	_assert(touch_ctrl.btn_menu != null, "Nút Menu góc trên phải tồn tại")
	_assert(touch_ctrl.btn_menu.action == "toggle_sidebar", "Nút Menu liên kết action 'toggle_sidebar'")
	_assert(touch_ctrl.mouse_filter == Control.MOUSE_FILTER_IGNORE, "TouchControls có mouse_filter = MOUSE_FILTER_IGNORE không chặn UI phía sau")

	# 3. TEST CHẠM NÚT & PHẢN HỒI XÚC GIÁC
	print("\n--- TEST 3: Chạm Nút & Phản Hồi Xúc Giác ---")
	# Chạm nút đánh
	touch_ctrl._handle_touch_event(1, touch_ctrl.btn_attack.center, true)
	_assert(Input.is_action_pressed("attack"), "Chạm nút Đánh kích hoạt 'attack'")
	_assert(touch_ctrl.btn_attack.is_pressed == true, "Trạng thái nút Đánh ghi nhận is_pressed")
	_assert(touch_ctrl.btn_attack.scale_anim < 1.0, "Nút co nhẹ tạo hiệu ứng phản hồi xúc giác khi bấm")

	touch_ctrl._handle_touch_event(1, touch_ctrl.btn_attack.center, false)
	_assert(not Input.is_action_pressed("attack"), "Thả tay tự động nhả 'attack'")
	_assert(touch_ctrl.btn_attack.scale_anim == 1.0, "Nút trở về kích thước ban đầu")

	# Chạm nút nhảy
	touch_ctrl._handle_touch_event(1, touch_ctrl.btn_jump.center, true)
	_assert(Input.is_action_pressed("jump"), "Chạm nút Nhảy kích hoạt 'jump'")
	touch_ctrl._handle_touch_event(1, touch_ctrl.btn_jump.center, false)
	_assert(not Input.is_action_pressed("jump"), "Thả tay tự động nhả 'jump'")

	# 4. TEST MULTI-TOUCH ĐA ĐIỂM (VỪA DI CHUYỂN VỪA ĐÁNH)
	print("\n--- TEST 4: Đa Điểm Multi-touch (Vừa Di Chuyển Vừa Đánh/Nhảy) ---")
	# Ngón trái kéo joystick sang phải (touch_id = 0)
	touch_ctrl._handle_touch_event(0, touch_ctrl.joystick_center, true)
	touch_ctrl._handle_drag_event(0, touch_ctrl.joystick_center + Vector2(50, 0))
	# Ngón phải đồng thời bấm Đánh (touch_id = 1)
	touch_ctrl._handle_touch_event(1, touch_ctrl.btn_attack.center, true)
	_assert(Input.is_action_pressed("move_right") and Input.is_action_pressed("attack"), "Vừa di chuyển vừa đánh thường cùng lúc thành công")

	# Thả ngón phải nhưng ngón trái vẫn đang di chuyển
	touch_ctrl._handle_touch_event(1, touch_ctrl.btn_attack.center, false)
	_assert(Input.is_action_pressed("move_right"), "Thả nút đánh không làm mất trạng thái di chuyển của joystick")
	_assert(not Input.is_action_pressed("attack"), "Nút đánh nhả độc lập")

	# Thả ngón trái
	touch_ctrl._handle_touch_event(0, touch_ctrl.joystick_center, false)
	_assert(not Input.is_action_pressed("move_right"), "Thả joystick nhả di chuyển")

	# 5. TEST TÍCH HỢP VỚI SIDEBAR & GIAO DIỆN
	print("\n--- TEST 5: Tích Hợp Ẩn/Hiện Khi Mở Sidebar Menu ---")
	# Chạm nút Menu trên màn hình cảm ứng để mở Sidebar
	touch_ctrl._handle_touch_event(2, touch_ctrl.btn_menu.center, true)
	_assert(ui.is_sidebar_open() == true, "Chạm nút Menu trên màn hình cảm ứng mở Sidebar thành công")
	_assert(touch_ctrl.visible == false, "Mở Sidebar tự động ẩn TouchControls để thao tác menu không bị vướng")
	ui.close_sidebar()
	_assert(ui.is_sidebar_open() == false, "Đóng Sidebar thành công")
	_assert(touch_ctrl.visible == true, "Đóng Sidebar tự động hiện lại TouchControls sẵn sàng chiến đấu")

	# 6. TEST RADIAL SPELL SELECTOR & SIDEBAR SPELL UPGRADES
	print("\n--- TEST 6: Vòng Chọn Phép (Radial Spell Selector) & Nâng Cấp Trong Sidebar ---")
	_assert(touch_ctrl.spell_radial_options.size() == 3, "Có đủ 3 tùy chọn phép thuật bung quanh nút Phép")
	_assert(touch_ctrl.spell_radial_options[0].spell_id == "moon_bolt", "Tùy chọn 1: Nguyệt Quang Đạn")
	_assert(touch_ctrl.spell_radial_options[1].spell_id == "ember_bloom", "Tùy chọn 2: Tinh Hỏa Bùng Nổ")
	_assert(touch_ctrl.spell_radial_options[2].spell_id == "frost_shard", "Tùy chọn 3: Hàn Tinh Tiễn")

	# Chạm giữ nút Phép để mở Radial Menu
	touch_ctrl._handle_touch_event(3, touch_ctrl.btn_cast.center, true)
	touch_ctrl._process(0.25)
	_assert(touch_ctrl._is_spell_menu_open == true, "Ấn giữ nút Phép >= 0.2s tự động bung vòng chọn 3 loại phép")

	# Di ngón tay chọn Tinh Hỏa Bùng Nổ (Lửa)
	var opt_fire = touch_ctrl.spell_radial_options[1]
	touch_ctrl._handle_drag_event(3, opt_fire.center)
	_assert(touch_ctrl._hovered_spell_id == "ember_bloom", "Lướt ngón tay trúng bóng phép Lửa ghi nhận hover")

	# Thả ngón tay để xác nhận chọn phép Lửa
	touch_ctrl._handle_touch_event(3, opt_fire.center, false)
	_assert(touch_ctrl._is_spell_menu_open == false, "Thả tay tự động đóng vòng chọn phép")
	_assert(touch_ctrl.btn_cast.label == "LỬA", "Nút Phép cập nhật nhãn thành 'LỬA'")

	# Kiểm tra Sidebar có cụm Nâng Cấp Phép
	ui.open_sidebar(0)
	_assert(ui.sidebar_shard_label != null, "Sidebar có nhãn Tinh Thể Ma Lực")
	_assert(ui.sidebar_upgrade_moon_btn != null, "Sidebar có nút nâng cấp Nguyệt Quang Đạn")
	_assert(ui.sidebar_upgrade_ember_btn != null, "Sidebar có nút nâng cấp Tinh Hỏa Bùng Nổ")
	_assert(ui.sidebar_upgrade_frost_btn != null, "Sidebar có nút nâng cấp Hàn Tinh Tiễn")
	ui.close_sidebar()

	ui.queue_free()
	print("\n==================================================")
	print(">>> TẤT CẢ TEST ĐIỀU KHIỂN CẢM ỨNG LIÊN QUÂN STYLE ĐẠT 100%! <<<")
	print("==================================================")
	quit(0)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] " + msg)
	else:
		printerr(" [FAIL] " + msg)
		quit(1)

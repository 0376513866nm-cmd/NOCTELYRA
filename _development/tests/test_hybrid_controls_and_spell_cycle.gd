extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING HYBRID CONTROLS & PC SPELL CYCLING")
	print("==================================================")

	var all_passed := true

	# --- TEST 1: SpellbookComponent Next & Prev Cycle ---
	print("\n--- TEST 1: Chu Kỳ Chuyển Phép (Spell Cycling) ---")
	var sb := SpellbookComponent.new()
	sb._ready()
	if sb.selected_spell_id == "moon_bolt":
		print("  [PASS] Phép khởi đầu mặc định là 'moon_bolt'")
	else:
		print("  [FAIL] Khởi đầu không phải moon_bolt: " + sb.selected_spell_id)
		all_passed = false

	# Next: moon_bolt -> ember_bloom
	sb.cycle_next_spell()
	if sb.selected_spell_id == "ember_bloom":
		print("  [PASS] cycle_next_spell() chuyển sang 'ember_bloom'")
	else:
		print("  [FAIL] cycle_next_spell() không thành ember_bloom")
		all_passed = false

	# Next: ember_bloom -> frost_shard
	sb.cycle_next_spell()
	if sb.selected_spell_id == "frost_shard":
		print("  [PASS] cycle_next_spell() chuyển sang 'frost_shard'")
	else:
		print("  [FAIL] cycle_next_spell() không thành frost_shard")
		all_passed = false

	# Next: frost_shard -> moon_bolt (loop)
	sb.cycle_next_spell()
	if sb.selected_spell_id == "moon_bolt":
		print("  [PASS] cycle_next_spell() vòng lại 'moon_bolt'")
	else:
		print("  [FAIL] cycle_next_spell() không vòng lại moon_bolt")
		all_passed = false

	# Prev: moon_bolt -> frost_shard (loop)
	sb.cycle_prev_spell()
	if sb.selected_spell_id == "frost_shard":
		print("  [PASS] cycle_prev_spell() lùi về 'frost_shard'")
	else:
		print("  [FAIL] cycle_prev_spell() không lùi về frost_shard")
		all_passed = false

	# --- TEST 2: Player Input Mouse Wheel ---
	print("\n--- TEST 2: Cuộn Chuột Trên Player (PC Wheel Inputs) ---")
	var player_scene: PackedScene = load("res://src/actors/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame

	# Simulate wheel down (next spell)
	var ev_down := InputEventMouseButton.new()
	ev_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev_down.pressed = true
	player._unhandled_input(ev_down)
	if player.spellbook_component.selected_spell_id == "ember_bloom":
		print("  [PASS] Cuộn chuột xuống (WHEEL_DOWN) chuyển sang 'ember_bloom'")
	else:
		print("  [FAIL] WHEEL_DOWN không chuyển sang ember_bloom")
		all_passed = false

	# Simulate wheel up (prev spell)
	var ev_up := InputEventMouseButton.new()
	ev_up.button_index = MOUSE_BUTTON_WHEEL_UP
	ev_up.pressed = true
	player._unhandled_input(ev_up)
	if player.spellbook_component.selected_spell_id == "moon_bolt":
		print("  [PASS] Cuộn chuột lên (WHEEL_UP) lùi về 'moon_bolt'")
	else:
		print("  [FAIL] WHEEL_UP không lùi về moon_bolt")
		all_passed = false

	player.queue_free()
	await process_frame

	# --- TEST 3: GameUI Hybrid Controls Toggle & F1 Key ---
	print("\n--- TEST 3: Giao Diện GameUI & Phím Ảo Lai (Hybrid Controls) ---")
	var ui_scene: PackedScene = load("res://src/ui/game_ui.tscn")
	var game_ui: GameUI = ui_scene.instantiate() as GameUI
	root.add_child(game_ui)
	await process_frame

	if game_ui.sidebar_hybrid_controls_btn != null:
		print("  [PASS] Nút SidebarHybridControlsBtn tồn tại trong Settings Panel")
	else:
		print("  [FAIL] Không tìm thấy SidebarHybridControlsBtn")
		all_passed = false

	# Test explicit toggle
	var initial_vis: bool = game_ui.touch_controls.visible
	game_ui.toggle_touch_controls()
	if game_ui.touch_controls.visible != initial_vis:
		print("  [PASS] toggle_touch_controls() đảo trạng thái hiển thị thành công (Hiện: %s)" % str(game_ui.touch_controls.visible))
	else:
		print("  [FAIL] toggle_touch_controls() không thay đổi trạng thái")
		all_passed = false

	if game_ui.sidebar_hybrid_controls_btn.text == ("BẬT" if game_ui.touch_controls.visible else "TẮT"):
		print("  [PASS] Nhãn nút Sidebar cập nhật chính xác: " + game_ui.sidebar_hybrid_controls_btn.text)
	else:
		print("  [FAIL] Nhãn nút Sidebar không khớp")
		all_passed = false

	# Test F1 hotkey
	var ev_f1 := InputEventKey.new()
	ev_f1.keycode = KEY_F1
	ev_f1.pressed = true
	var cur_vis_before_f1: bool = game_ui.touch_controls.visible
	game_ui._unhandled_input(ev_f1)
	if game_ui.touch_controls.visible != cur_vis_before_f1:
		print("  [PASS] Phím tắt F1 chuyển đổi bật/tắt phím ảo thành công (Hiện: %s)" % str(game_ui.touch_controls.visible))
	else:
		print("  [FAIL] Phím tắt F1 không đổi trạng thái phím ảo")
		all_passed = false

	# Test notification display
	game_ui._on_player_spell_selected("ember_bloom")
	if game_ui.notification_label.visible and "Tinh Hỏa Bùng Nổ" in game_ui.notification_label.text:
		print("  [PASS] Thông báo nổi khi chuyển phép hiển thị chính xác: " + game_ui.notification_label.text)
	else:
		print("  [FAIL] Thông báo chuyển phép không đúng")
		all_passed = false

	game_ui.queue_free()
	await process_frame

	# --- TEST 4: Đồng Bộ Nút Ảo Khi Cuộn Chuột Đổi Phép ---
	print("\n--- TEST 4: Đồng Bộ Nút Ảo Khi Cuộn Chuột Đổi Phép ---")
	var world := Node2D.new()
	world.name = "World"
	root.add_child(world)

	var p: Player = load("res://src/actors/player/player.tscn").instantiate() as Player
	p.name = "Player"
	world.add_child(p)

	var gui: GameUI = load("res://src/ui/game_ui.tscn").instantiate() as GameUI
	gui.name = "GameUI"
	world.add_child(gui)
	gui.set_touch_controls_visible(true)
	await process_frame

	var tc: TouchControls = gui.touch_controls
	if tc.btn_cast.label == "TRĂNG":
		print("  [PASS] Nút ảo khởi đầu hiển thị 'TRĂNG'")
	else:
		print("  [FAIL] Nút ảo khởi đầu không phải TRĂNG: " + tc.btn_cast.label)
		all_passed = false

	# Cuộn chuột xuống -> Tinh Hỏa Bùng Nổ (LỬA)
	var ev_scroll := InputEventMouseButton.new()
	ev_scroll.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev_scroll.pressed = true
	p._unhandled_input(ev_scroll)
	await process_frame

	if tc.btn_cast.label == "LỬA" and tc.btn_cast.icon == "flame":
		print("  [PASS] Cuộn chuột đổi sang Lửa -> Nút ảo tự động cập nhật 'LỬA' và icon flame!")
	else:
		print("  [FAIL] Nút ảo không cập nhật LỬA: label=" + tc.btn_cast.label + " icon=" + tc.btn_cast.icon)
		all_passed = false

	# Cuộn chuột xuống tiếp -> Hàn Tinh Tiễn (BĂNG)
	p._unhandled_input(ev_scroll)
	await process_frame

	if tc.btn_cast.label == "BĂNG" and tc.btn_cast.icon == "❄":
		print("  [PASS] Cuộn chuột đổi sang Băng -> Nút ảo tự động cập nhật 'BĂNG' và icon ❄!")
	else:
		print("  [FAIL] Nút ảo không cập nhật BĂNG: label=" + tc.btn_cast.label + " icon=" + tc.btn_cast.icon)
		all_passed = false

	world.queue_free()
	await process_frame

	print("\n==================================================")
	if all_passed:
		print(">>> TẤT CẢ TEST HYBRID CONTROLS & PC SPELL CYCLING ĐẠT 100%! <<<")
	else:
		print(">>> CÓ TEST THẤT BẠI! <<<")
	print("==================================================")

	quit(0 if all_passed else 1)

extends SceneTree

const TEST_SETTINGS_PATH := "user://input_locking_regression_settings.json"

var _settings_test_active := false
var _previous_settings_path := ""
var _previous_hybrid_controls_enabled := false

## Regression Test for Reason-based Input Locking & Decoupling (M8 Phase 1 Final Polish)
## Verifies that:
## 1. Multiple UI locks do not prematurely unlock when one UI closes.
## 2. Physics (gravity, friction, move_and_slide, ground shadow) continues while input is locked.
## 3. Airborne player falls and does not freeze midair.
## 4. GameUI opens/closes properly propagate locks to Player via signal.
## 5. InteractionCoordinator blocks NPC interaction when player is locked (Inventory, Cooldown),
##    and FAILs if no valid NPC exists.
## 6. InteractionCoordinator still advances and completely closes Dialogue on 'interact' key.
## 7. InteractionCoordinator blocks Portal and World Interactables when Player is locked.
## 8. TouchControls fallback respects Input Lock and dialogue cooldown.
## 9. Signals notification_posted and player_died cleanly propagate from Player to GameUI via BaseZone.

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- BẮT ĐẦU INPUT LOCKING & DECOUPLING REGRESSION TEST ---")
	
	# --- BÀI TEST 1: Logic Dictionary Reason-based Locks ---
	var player_scene := load("res://src/actors/player/player.tscn") as PackedScene
	if player_scene == null:
		_fail("Không thể tải res://src/actors/player/player.tscn")
		return
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame
	
	if player.is_input_blocked():
		_fail("Player không được khóa input lúc khởi tạo")
		return
	
	player.set_input_blocked("dialogue", true)
	if not player.is_input_blocked():
		_fail("Player phải bị khóa khi có reason dialogue")
		return
	
	player.set_input_blocked("inventory", true)
	player.set_input_blocked("dialogue", false)
	if not player.is_input_blocked():
		_fail("Đóng dialogue không được mở khóa nếu inventory vẫn mở!")
		return
	
	player.set_input_blocked("inventory", false)
	if player.is_input_blocked():
		_fail("Player phải được mở khóa khi hết mọi reason")
		return
	print("[PASS] Bài test 1: Logic khóa/mở nhiều tầng (Overlapping Locks) OK")
	
	# --- BÀI TEST 2: Xóa lock khi Respawn hoặc Clear ---
	player.set_input_blocked("temp_lock", true)
	player.clear_all_input_locks()
	if player.is_input_blocked():
		_fail("clear_all_input_locks không xóa sạch locks")
		return
	
	player.set_input_blocked("dead_lock", true)
	player.respawn()
	if player.is_input_blocked():
		_fail("respawn không xóa sạch locks")
		return
	print("[PASS] Bài test 2: Reset lock khi Respawn OK")
	
	# --- BÀI TEST 3: Vật lý khi bị khóa (Gravity & Friction, không treo trên không) ---
	player.position = Vector2(100.0, 100.0)
	player.velocity = Vector2(250.0, 0.0)
	player.set_input_blocked("pause_ui", true)
	
	var initial_vy := player.velocity.y
	var initial_vx := player.velocity.x
	
	# Giả lập physics frame khi không ở trên sàn
	player._physics_process(0.016)
	
	if player.velocity.y <= initial_vy:
		_fail("Gravity không được áp dụng khi khóa input (nhân vật có thể bị treo lơ lửng)!")
		return
	if player.velocity.x >= initial_vx:
		_fail("Friction không được áp dụng để giảm tốc độ ngang khi khóa input!")
		return
	if player.current_state != Player.State.FALL:
		_fail("Player trên không khi khóa input phải chuyển về state FALL!")
		return
	
	player.set_input_blocked("pause_ui", false)
	player.queue_free()
	await process_frame
	print("[PASS] Bài test 3: Bảo toàn Gravity & Friction khi khóa input OK")
	
	# --- BÀI TEST 4: Tích hợp thực tế giữa GameUI và Player trong Scene ---
	var forest_scene := load("res://src/world/noctis_forest.tscn") as PackedScene
	if forest_scene == null:
		_fail("Không thể tải res://src/world/noctis_forest.tscn")
		return
	var world := forest_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	
	var scene_player := world.get_node_or_null("Player") as Player
	var scene_ui := world.get_node_or_null("GameUI") as GameUI
	var coordinator := world.get_node_or_null("InteractionCoordinator") as InteractionCoordinator
	if scene_player == null or scene_ui == null or coordinator == null:
		_fail("Scene noctis_forest thiếu Player, GameUI hoặc InteractionCoordinator")
		return
	
	if scene_player.is_input_blocked():
		_fail("Scene Player không được khóa ban đầu")
		return
	
	# 4.1 Mở Inventory
	scene_ui.open_inventory()
	if not scene_player.is_input_blocked():
		_fail("Mở Inventory phải khóa Player input!")
		return
	if not scene_player.input_locks.has("inventory"):
		_fail("Player thiếu reason 'inventory'")
		return
	
	# 4.2 Mở tiếp Dialogue trong khi Inventory đang mở
	scene_ui.show_dialogue("Test NPC", ["Câu thoại 1"])
	if not scene_player.input_locks.has("dialogue"):
		_fail("Player thiếu reason 'dialogue'")
		return
	
	# 4.3 Đóng Inventory -> Player vẫn phải bị khóa vì Dialogue còn mở
	scene_ui.close_inventory()
	if not scene_player.is_input_blocked():
		_fail("Đóng Inventory không được mở khóa khi Dialogue còn mở!")
		return
	
	# 4.4 Đóng Dialogue -> Cooldown grace bắt đầu chạy
	scene_ui.close_dialogue()
	if not scene_player.is_input_blocked():
		_fail("Vừa đóng Dialogue phải có cooldown grace lock để chống bấm nhầm!")
		return
	
	# Chờ hết cooldown grace (0.25s)
	for i in range(25):
		scene_ui._process(0.02)
		await process_frame
	
	if scene_player.is_input_blocked():
		_fail("Sau khi hết cooldown grace, Player phải được mở khóa hoàn toàn!")
		return
	print("[PASS] Bài test 4: Tương tác Scene GameUI <-> Player Input Locking OK")
	
	# --- BÀI TEST 5: InteractionCoordinator tôn trọng Input Lock với NPC ---
	var npcs = get_nodes_in_group(GameGroups.NPCS)
	if npcs.is_empty():
		_fail("Bắt buộc phải có NPC trong scene noctis_forest để thực hiện bài test 5!")
		return
	
	var npc: NPC = npcs[0] as NPC
	scene_player.global_position = npc.global_position
	if npc.interaction_component:
		npc.interaction_component.is_player_nearby = true
	
	var ev_interact := InputEventAction.new()
	ev_interact.action = "interact"
	ev_interact.pressed = true
	
	# 5.1 Khi Inventory mở -> Phím E KHÔNG được kích hoạt thoại NPC
	scene_ui.open_inventory()
	coordinator._unhandled_input(ev_interact)
	if scene_ui.is_dialogue_open():
		_fail("Nhấn E khi đang mở Inventory không được kích hoạt NPC!")
		return
	
	# 5.2 Khi vừa đóng Inventory -> Cooldown grace (0.15s) vẫn phải chặn phím E
	scene_ui.close_inventory()
	coordinator._unhandled_input(ev_interact)
	if scene_ui.is_dialogue_open():
		_fail("Nhấn E trong thời gian cooldown sau khi đóng Inventory không được kích hoạt NPC!")
		return
	
	# Chờ hết cooldown
	for i in range(15):
		scene_ui._process(0.02)
		await process_frame
	
	# 5.3 Khi không bị khóa -> Phím E kích hoạt thoại bình thường
	coordinator._unhandled_input(ev_interact)
	if not scene_ui.is_dialogue_open():
		_fail("Nhấn E khi Player tự do phải kích hoạt hội thoại NPC thành công!")
		return
	
	# 5.4 Khi Dialogue đang mở -> Phím E chuyển câu và phải đóng hẳn sau khi hết thoại
	for step in range(15):
		if not scene_ui.is_dialogue_open():
			break
		coordinator._unhandled_input(ev_interact)
	
	if scene_ui.is_dialogue_open():
		_fail("Hội thoại NPC phải thực sự đóng sau khi advance hết các câu thoại!")
		return
	
	# Vô hiệu hóa tương tác NPC của Test 5 và đưa Player ra xa để không làm nhiễu Test 6
	if npc.interaction_component:
		npc.interaction_component.is_player_nearby = false
	scene_player.global_position = Vector2(8888.0, 8888.0)
	
	# Chờ hết dialogue cooldown sau khi đóng hội thoại
	for i in range(20):
		scene_ui._process(0.02)
		await process_frame
	print("[PASS] Bài test 5: InteractionCoordinator chặn thoại khi khóa và đóng thoại hoàn chỉnh OK")
	
	# --- BÀI TEST 6: Chặn tương tác Cổ Tinh Thạch & Cổng Dịch Chuyển (Portal/Interactables) ---
	# 6.1 Kiểm thử Vật thể Cổ Tinh Thạch (AncientCrystal)
	var test_crystal := load("res://src/world/ancient_crystal.tscn").instantiate() as Area2D
	world.add_child(test_crystal)
	test_crystal.global_position = scene_player.global_position
	test_crystal.set("_player_in_range", true)
	
	# Khóa input player -> Phím E KHÔNG được kích hoạt Cổ Tinh Thạch
	scene_player.set_input_blocked("crystal_test_lock", true)
	coordinator._unhandled_input(ev_interact)
	if scene_ui.is_dialogue_open():
		_fail("Cổ Tinh Thạch không được kích hoạt khi Player đang bị khóa input!")
		return
	
	# Mở khóa player -> Phím E kích hoạt thành công và CHÍNH XÁC là Cổ Tinh Thạch
	scene_player.set_input_blocked("crystal_test_lock", false)
	coordinator._unhandled_input(ev_interact)
	if not scene_ui.is_dialogue_open():
		_fail("Cổ Tinh Thạch phải kích hoạt được khi Player không bị khóa input!")
		return
	if scene_ui.dialogue_speaker == null or scene_ui.dialogue_speaker.text != "Cổ Tinh Thạch":
		_fail("Hội thoại phải được kích hoạt bởi chính 'Cổ Tinh Thạch', không phải NPC khác!")
		return
	
	scene_ui.close_dialogue()
	for i in range(20):
		scene_ui._process(0.02)
		await process_frame
	test_crystal.set("_player_in_range", false)
	test_crystal.queue_free()
	
	# 6.2 Kiểm thử Cổng Dịch Chuyển (ZonePortal)
	var test_portal := load("res://src/world/zone_portal.tscn").instantiate() as ZonePortal
	world.add_child(test_portal)
	test_portal.global_position = scene_player.global_position
	test_portal.set("_player_in_range", true)
	test_portal.is_locked = true
	test_portal.lock_reason = "KIỂM THỬ KHÓA CỔNG ZONE"
	
	# Khi Player bị khóa input -> Phím E không được kích hoạt tương tác cổng
	scene_player.set_input_blocked("portal_test_lock", true)
	coordinator._unhandled_input(ev_interact)
	if scene_ui.notification_label and scene_ui.notification_label.visible and scene_ui.notification_label.text == test_portal.lock_reason:
		_fail("Cổng dịch chuyển không được kích hoạt tương tác khi Player đang bị khóa input!")
		return
	
	# Khi Player mở khóa -> Phím E kích hoạt tương tác cổng và hiển thị lý do khóa cổng
	scene_player.set_input_blocked("portal_test_lock", false)
	coordinator._unhandled_input(ev_interact)
	if scene_ui.notification_label == null or not scene_ui.notification_label.visible or scene_ui.notification_label.text != test_portal.lock_reason:
		_fail("Cổng dịch chuyển phải kích hoạt được tương tác khi Player không bị khóa input!")
		return
	test_portal.queue_free()
	print("[PASS] Bài test 6: Chặn tương tác Cổ Tinh Thạch & Cổng Dịch Chuyển khi Input Lock OK")
	
	# --- BÀI TEST 7: TouchControls fallback tôn trọng Input Lock (Negative & Positive) ---
	var touch := scene_ui.touch_controls
	if touch == null:
		_fail("Không tìm thấy TouchControls trong GameUI!")
		return
	
	# Đưa Player lại gần NPC và bật tương tác NPC
	scene_player.global_position = npc.global_position
	if npc.interaction_component:
		npc.interaction_component.is_player_nearby = true
	
	# Tạm tháo InteractionCoordinator khỏi group để kích hoạt nhánh fallback 3, 4, 5
	coordinator.remove_from_group(GameGroups.INTERACTION_COORDINATOR)
	
	# 7.1 Negative test: Khi Player bị khóa -> Touch fallback KHÔNG được mở hội thoại
	scene_player.set_input_blocked("touch_lock", true)
	touch._trigger_interact()
	if scene_ui.is_dialogue_open():
		_fail("TouchControls fallback không được kích hoạt tương tác khi Player đang bị khóa input!")
		return
	
	# 7.2 Positive test: Khi Player mở khóa -> Touch fallback PHẢI mở được hội thoại thành công
	scene_player.set_input_blocked("touch_lock", false)
	touch._trigger_interact()
	if not scene_ui.is_dialogue_open():
		_fail("TouchControls fallback phải kích hoạt được hội thoại khi Player không bị khóa input!")
		return
	
	scene_ui.close_dialogue()
	coordinator.add_to_group(GameGroups.INTERACTION_COORDINATOR)
	print("[PASS] Bài test 7: TouchControls fallback tôn trọng Input Lock (Cả 2 chiều Chặn & Cho phép) OK")
	
	# --- BÀI TEST 8: Signal Notification & Game Over kết nối đúng sang GameUI ---
	# 8.1 Notification signal
	var test_msg := "THÔNG BÁO TEST SIGNAL THÀNH CÔNG"
	scene_player.emit_signal("notification_posted", test_msg)
	if scene_ui.notification_label == null or not scene_ui.notification_label.visible or scene_ui.notification_label.text != test_msg:
		_fail("Signal notification_posted từ Player không hiển thị đúng lên GameUI!")
		return
	
	# 8.2 Player died signal -> Game Over UI
	if scene_ui.game_over_panel.visible:
		_fail("GameOver panel không được hiển thị trước khi Player chết!")
		return
	scene_player.emit_signal("player_died")
	if not scene_ui.game_over_panel.visible:
		_fail("Signal player_died từ Player phải làm hiển thị Game Over panel trên GameUI!")
		return
	print("[PASS] Bài test 8: Signals notification_posted và player_died kết nối đúng sang GameUI OK")
	scene_ui.hide_game_over()
	
	# --- BÀI TEST 9: Bảo toàn trạng thái Hybrid Controls khi thay đổi trong Sidebar và sau khi đóng Sidebar ---
	_begin_isolated_settings_test()
	# 9.1 Bắt đầu với Hybrid Controls tắt
	scene_ui.set_touch_controls_visible(false)
	if touch.visible:
		_fail("Touch controls phải bị ẩn khi set_touch_controls_visible(false)!")
		return
	if not scene_ui.sidebar_toggle_btn.visible:
		_fail("SidebarToggleBtn phải hiển thị khi Touch controls bị ẩn!")
		return

	# 9.2 Mở Sidebar: Touch controls và ToggleBtn đều phải tạm thời bị ẩn
	scene_ui.open_sidebar(3) # Tab Settings
	if not scene_ui.is_sidebar_open():
		_fail("Sidebar phải mở thành công!")
		return
	if touch.visible:
		_fail("Touch controls phải tạm ẩn khi Sidebar đang mở!")
		return
	if scene_ui.sidebar_toggle_btn.visible:
		_fail("SidebarToggleBtn phải tạm ẩn khi Sidebar đang mở!")
		return

	# 9.3 Người chơi bật Hybrid Controls trong lúc Sidebar đang mở
	scene_ui.toggle_touch_controls()
	if not SettingsManager.hybrid_controls_enabled:
		_fail("hybrid_controls_enabled phải là true sau khi toggle_touch_controls()!")
		return
	if scene_ui.sidebar_hybrid_controls_btn and scene_ui.sidebar_hybrid_controls_btn.text != "BẬT":
		_fail("Nút SidebarHybridControlsBtn phải hiển thị 'BẬT'!")
		return

	# 9.4 Đóng Sidebar: Trạng thái Hybrid Controls vừa bật PHẢI được áp dụng và bảo toàn
	scene_ui.close_sidebar()
	if scene_ui.is_sidebar_open():
		_fail("Sidebar phải đóng thành công!")
		return
	if not touch.visible:
		_fail("Touch controls PHẢI hiển thị sau khi đóng Sidebar vì người chơi đã bật Hybrid Controls!")
		return
	if scene_ui.sidebar_toggle_btn.visible:
		_fail("SidebarToggleBtn PHẢI ẩn khi Touch controls đang hiển thị!")
		return

	# 9.5 Đảo chiều: Mở Sidebar và tắt Hybrid Controls
	scene_ui.open_sidebar(3)
	scene_ui.toggle_touch_controls()
	if SettingsManager.hybrid_controls_enabled:
		_fail("hybrid_controls_enabled phải là false sau khi toggle_touch_controls() lần 2!")
		return
	if scene_ui.sidebar_hybrid_controls_btn and scene_ui.sidebar_hybrid_controls_btn.text != "TẮT":
		_fail("Nút SidebarHybridControlsBtn phải hiển thị 'TẮT'!")
		return
	scene_ui.close_sidebar()
	if touch.visible:
		_fail("Touch controls PHẢI ẩn sau khi đóng Sidebar vì người chơi đã tắt Hybrid Controls!")
		return
	if not scene_ui.sidebar_toggle_btn.visible:
		_fail("SidebarToggleBtn PHẢI hiển thị sau khi đóng Sidebar vì Touch controls đã tắt!")
		return
	print("[PASS] Bài test 9: Bảo toàn trạng thái Hybrid Controls khi thay đổi trong Sidebar và sau khi đóng Sidebar OK")

	# --- BÀI TEST 10: Nút đóng trực tiếp của Inventory phải gỡ input lock cho cả cảm ứng và bàn phím ---
	scene_ui.set_touch_controls_visible(true)
	scene_ui.open_inventory()
	if not scene_player.input_locks.has("inventory"):
		_fail("Mở Inventory phải tạo input lock trước khi kiểm tra nút đóng trực tiếp!")
		return

	# Mô phỏng nút X của InventoryUI: nút này gọi InventoryUI.close(), không gọi GameUI.close_inventory().
	scene_ui.inventory_ui.close()
	if scene_player.input_locks.has("inventory"):
		_fail("Nút X của InventoryUI phải gỡ reason 'inventory' khỏi Player!")
		return
	if not scene_player.input_locks.has("ui_cooldown"):
		_fail("Đóng Inventory trực tiếp phải tạo cooldown ngắn để chống bấm nhầm!")
		return

	for i in range(10):
		scene_ui._process(0.02)
		await process_frame
	if scene_player.is_input_blocked():
		_fail("Player phải được mở khóa hoàn toàn sau cooldown của nút X Inventory!")
		return

	# Kiểm tra đường input cảm ứng qua joystick.
	var test_touch_id := 910
	var joystick_press: Vector2 = touch.joystick_base_pos + Vector2(45.0, 0.0)
	touch._handle_touch_event(test_touch_id, joystick_press, true)
	if not Input.is_action_pressed("move_right"):
		_fail("Joystick ảo phải phát move_right sau khi đóng Inventory!")
		return
	touch._handle_touch_event(test_touch_id, joystick_press, false)
	if Input.is_action_pressed("move_right"):
		_fail("Joystick ảo phải nhả move_right khi thả tay!")
		return

	# Kiểm tra đường input bàn phím dùng chung không còn bị khóa.
	Input.action_press("move_right")
	if scene_player.is_input_blocked() or scene_player._get_input_direction() <= 0.0:
		Input.action_release("move_right")
		_fail("Bàn phím phải điều khiển được sau khi đóng Inventory!")
		return
	Input.action_release("move_right")

	# Hai modal còn lại cũng có nút X gọi close() trực tiếp và phải dùng cùng cơ chế gỡ lock.
	scene_ui.open_quest_journal()
	scene_ui.quest_journal_ui.close()
	if scene_player.input_locks.has("quest_journal"):
		_fail("Nút X của QuestJournalUI phải gỡ reason 'quest_journal'!")
		return
	for i in range(10):
		scene_ui._process(0.02)
		await process_frame

	scene_ui.open_character_sheet()
	scene_ui.character_sheet_ui.close()
	if scene_player.input_locks.has("character_sheet"):
		_fail("Nút X của CharacterSheetUI phải gỡ reason 'character_sheet'!")
		return
	for i in range(10):
		scene_ui._process(0.02)
		await process_frame
	if scene_player.is_input_blocked():
		_fail("Player phải được mở khóa sau khi đóng trực tiếp mọi modal UI!")
		return
	print("[PASS] Bài test 10: Nút X của Inventory/Quest/Character gỡ lock; joystick ảo và bàn phím hoạt động lại OK")
	_end_isolated_settings_test()
	
	world.queue_free()
	await process_frame
	
	print("INPUT_LOCKING_REGRESSION_TEST_OK")
	quit(0)

func _fail(msg: String) -> void:
	_end_isolated_settings_test()
	push_error("LỖI TEST: " + msg)
	quit(1)

func _begin_isolated_settings_test() -> void:
	if _settings_test_active:
		return
	_settings_test_active = true
	_previous_settings_path = SettingsManager.custom_settings_path
	_previous_hybrid_controls_enabled = SettingsManager.hybrid_controls_enabled
	SettingsManager.custom_settings_path = TEST_SETTINGS_PATH
	SettingsManager.hybrid_controls_enabled = false
	var absolute_test_path: String = ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_test_path)

func _end_isolated_settings_test() -> void:
	if not _settings_test_active:
		return
	var absolute_test_path: String = ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_test_path)
	SettingsManager.custom_settings_path = _previous_settings_path
	SettingsManager.hybrid_controls_enabled = _previous_hybrid_controls_enabled
	_settings_test_active = false

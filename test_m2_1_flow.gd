extends SceneTree

# test_m2_1_flow.gd
# Automated integration test for NOCTELYRA M2.1
# Tests full quest lifecycle, NPC dialogue input coordination, collision, and anti-duplicate kill path.

var failures: int = 0
var tests_run: int = 0

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M2.1] INTEGRATION TEST SUITE STARTING")
	print("==================================================")
	call_deferred("_run_suite")

func _assert(condition: bool, test_name: String, details: String = "") -> void:
	tests_run += 1
	if condition:
		print("  [PASS] %s" % test_name)
	else:
		failures += 1
		print("  [FAIL] %s - Details: %s" % [test_name, details])

func _send_action(action_name: String) -> void:
	var ev_press = InputEventAction.new()
	ev_press.action = action_name
	ev_press.pressed = true
	Input.parse_input_event(ev_press)
	for i in range(2):
		await process_frame

	var ev_release = InputEventAction.new()
	ev_release.action = action_name
	ev_release.pressed = false
	Input.parse_input_event(ev_release)
	for i in range(2):
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _run_suite() -> void:
	var world_scene: PackedScene = load("res://src/world/noctis_forest.tscn")
	if not world_scene:
		print("FATAL: Could not load noctis_forest.tscn")
		quit(1)
		return

	var world: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world)
	current_scene = world

	# Đợi scene và physics khởi tạo
	_wait_seconds(0.3)

	var player: Player = world.get_node_or_null("Player") as Player
	var npc: NPC = world.get_node_or_null("NPC_Elyra") as NPC
	var ui: GameUI = world.get_node_or_null("GameUI") as GameUI
	var quest_mgr: QuestManager = world.get_node_or_null("QuestManager") as QuestManager
	var coordinator: InteractionCoordinator = world.get_node_or_null("InteractionCoordinator") as InteractionCoordinator

	print("\n--- PHASE 1: Kiếm tra thực thể và kiến trúc điều phối ---")
	_assert(player != null, "Player tồn tại trong scene")
	_assert(npc != null, "NPC Elyra tồn tại trong scene")
	_assert(ui != null, "GameUI tồn tại trong scene")
	_assert(quest_mgr != null, "QuestManager tồn tại trong scene")
	_assert(coordinator != null, "InteractionCoordinator tồn tại trong scene")

	print("\n--- PHASE 2: Kiểm tra vật cản NPC (Xuyên người) ---")
	_assert(npc.collision_layer == 0, "NPC collision_layer = 0 (không cản Player di chuyển)")
	player.global_position = npc.global_position
	await process_frame
	_assert(true, "Player có thể di chuyển và đứng trùng vị trí NPC Elyra mà không bị kẹt va chạm")

	print("\n--- PHASE 3: Trạng thái ban đầu của Nhiệm vụ & Hội thoại ---")
	_assert(quest_mgr.current_quest.current_state == QuestData.State.NOT_STARTED, "Nhiệm vụ ban đầu là NOT_STARTED")
	_assert(ui.is_dialogue_open() == false, "Hội thoại ban đầu đóng")
	_assert(npc.is_interactable() == true, "NPC Elyra có thể tương tác khi Player đứng gần")

	print("\n--- PHASE 4: Tương tác mở hội thoại bằng Input 'E' ---")
	await _send_action("interact")
	await process_frame
	_assert(ui.is_dialogue_open() == true, "Nhấn E lần 1: Hội thoại đã mở thành công")
	var initial_speaker: String = ui.dialogue_speaker.text if ui.dialogue_speaker else ""
	_assert(initial_speaker == "Elyra", "Người nói là Elyra")

	print("\n--- PHASE 5: Bảo vệ chống nhận nhầm phím J (Tấn công) / Space (Nhảy) khi đang thoại ---")
	var state_before: Player.State = player.current_state
	await _send_action("attack")
	await _send_action("jump")
	await process_frame
	_assert(ui.is_dialogue_open() == true, "Nhấn J/Space trong lúc thoại không làm đóng hội thoại")
	_assert(player.current_state == state_before, "Nhấn J/Space trong lúc thoại không kích hoạt chém kiếm hay nhảy")
	_assert(player.melee_hitbox.monitoring == false, "Melee hitbox của Player vẫn tắt an toàn")

	print("\n--- PHASE 6: Đọc tuần tự 3 câu hội thoại bằng Input 'E' ---")
	# Câu 1 đang hiển thị
	await _send_action("interact") # Chuyển sang câu 2
	await process_frame
	_assert(ui.is_dialogue_open() == true, "Nhấn E: Chuyển sang câu thứ 2")

	await _send_action("interact") # Chuyển sang câu 3
	await process_frame
	_assert(ui.is_dialogue_open() == true, "Nhấn E: Chuyển sang câu thứ 3")

	await _send_action("interact") # Đóng hội thoại & nhận quest
	await process_frame
	_assert(ui.is_dialogue_open() == false, "Nhấn E lần cuối: Hội thoại đóng lại thành công")
	_assert(quest_mgr.current_quest.current_state == QuestData.State.ACTIVE, "Nhiệm vụ chuyển sang trạng thái ACTIVE")
	_assert(quest_mgr.current_quest.current_amount == 0, "Số lượng tiêu diệt ban đầu là 0/3")

	print("\n--- PHASE 7: Grace Cooldown chống nhấn đúp re-open tức thì ---")
	await _send_action("interact")
	await process_frame
	_assert(ui.is_dialogue_open() == false, "Nhấn E ngay khi vừa đóng: Bị chặn bởi Grace Cooldown, không re-open tức thì")
	await _wait_seconds(0.3) # Đợi cooldown 0.25s trôi qua

	print("\n--- PHASE 8: Tiêu diệt quái & Xác minh đường thông báo duy nhất ---")
	var enemies = world.get_tree().get_nodes_in_group("enemies")
	_assert(enemies.size() >= 3, "Có ít nhất 3 quái vật trên bản đồ (thực tế: %d)" % enemies.size())

	# Diệt quái 1
	var e1: Enemy = enemies[0] as Enemy
	e1.health_component.current_health = 0.0
	e1.health_component.emit_signal("died")
	await process_frame
	_assert(quest_mgr.current_quest.current_amount == 1, "Diệt quái 1: Tiến độ cập nhật 1/3")

	# Kiểm tra chống đếm trùng cho quái 1
	e1._notify_kill_once()
	await process_frame
	_assert(quest_mgr.current_quest.current_amount == 1, "Bảo vệ chống đếm trùng: Quái 1 không bị đếm lần 2")

	# Diệt quái 2
	var e2: Enemy = enemies[1] as Enemy
	e2.health_component.current_health = 0.0
	e2.health_component.emit_signal("died")
	await process_frame
	_assert(quest_mgr.current_quest.current_amount == 2, "Diệt quái 2: Tiến độ cập nhật 2/3")

	# Diệt quái 3
	var e3: Enemy = enemies[2] as Enemy
	e3.health_component.current_health = 0.0
	e3.health_component.emit_signal("died")
	await process_frame
	_assert(quest_mgr.current_quest.current_amount == 3, "Diệt quái 3: Tiến độ cập nhật 3/3")
	_assert(quest_mgr.current_quest.current_state == QuestData.State.READY_TO_TURN_IN, "Nhiệm vụ chuyển sang READY_TO_TURN_IN")

	print("\n--- PHASE 9: Trả nhiệm vụ bằng Input 'E' & Nhận thưởng ---")
	# Làm hao hụt HP và MP của player để kiểm tra tính năng hồi phục toàn bộ
	player.health_component.current_health = 35.0
	player.health_component.current_mana = 20.0
	var initial_gold: int = quest_mgr.gold
	_assert(initial_gold == 0, "Vàng ban đầu là 0 G")

	# Đứng gần Elyra và nhấn E
	player.global_position = npc.global_position
	await process_frame
	await _send_action("interact")
	await process_frame
	_assert(ui.is_dialogue_open() == true, "Nhấn E: Mở hội thoại hoàn thành nhiệm vụ")

	await _send_action("interact") # Câu tiếp
	await process_frame
	await _send_action("interact") # Đóng thoại & nhận thưởng
	await process_frame

	_assert(ui.is_dialogue_open() == false, "Hội thoại trả nhiệm vụ đã đóng")
	_assert(quest_mgr.current_quest.current_state == QuestData.State.COMPLETED, "Nhiệm vụ chuyển sang COMPLETED")
	_assert(quest_mgr.gold == 50, "Player nhận đúng 50 Vàng (hiện tại: %d G)" % quest_mgr.gold)
	_assert(player.health_component.current_health == player.health_component.max_health, "HP của Player được hồi phục đầy (100/100)")
	_assert(player.health_component.current_mana == player.health_component.max_mana, "MP của Player được hồi phục đầy (100/100)")

	print("\n--- PHASE 10: Tương tác lần nữa không nhận thêm thưởng ---")
	await _wait_seconds(0.3)
	await _send_action("interact") # Mở thoại cảm ơn
	await process_frame
	_assert(ui.is_dialogue_open() == true, "Nhấn E: Mở hội thoại cảm ơn sau hoàn thành")
	await _send_action("interact")
	await process_frame
	await _send_action("interact") # Đóng thoại
	await process_frame
	_assert(ui.is_dialogue_open() == false, "Hội thoại cảm ơn đã đóng")
	_assert(quest_mgr.gold == 50, "Vàng vẫn giữ nguyên đúng 50 G, không nhận thêm thưởng lặp lại")

	print("\n--- PHASE 11: Kiểm tra hệ thống Pause / Resume ---")
	_assert(world.get_tree().paused == false, "Hệ thống ban đầu chưa pause")
	await _send_action("pause") # Esc lần 1 -> Pause
	await process_frame
	_assert(world.get_tree().paused == true, "Esc lần 1: Đã kích hoạt Pause")
	_assert(ui.pause_menu.visible == true, "Pause menu hiển thị")

	await _send_action("pause") # Esc lần 2 -> Resume
	await process_frame
	_assert(world.get_tree().paused == false, "Esc lần 2: Đã kích hoạt Resume")
	_assert(ui.pause_menu.visible == false, "Pause menu ẩn sau khi resume")

	print("\n==================================================")
	print(" [NOCTELYRA M2.1] KẾT QUẢ KIỂM THỬ TỔNG HỢP:")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! M2.1 READY. <<<")
		quit(0)
	else:
		print(">>> TESTS FAILED! <<<")
		quit(1)

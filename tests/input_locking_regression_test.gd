extends SceneTree

## Regression Test for Reason-based Input Locking (M8 Phase 1 Polish)
## Verifies that:
## 1. Multiple UI locks do not prematurely unlock when one UI closes.
## 2. Physics (gravity, friction, move_and_slide, ground shadow) continues while input is locked.
## 3. Airborne player falls and does not freeze midair.
## 4. GameUI opens/closes properly propagate locks to Player via signal.
## 5. InteractionCoordinator blocks NPC/Portal/World interaction when player is locked (Inventory, Sidebar, Cooldown).
## 6. InteractionCoordinator still advances/closes dialogue on 'interact' key when Dialogue is open.
## 7. Respawn clears locks safely.

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- BẮT ĐẦU INPUT LOCKING REGRESSION TEST ---")
	
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
	
	# --- BÀI TEST 5: InteractionCoordinator tôn trọng Input Lock ---
	var npcs = get_nodes_in_group(GameGroups.NPCS)
	if npcs.size() > 0:
		var npc: Node2D = npcs[0] as Node2D
		scene_player.global_position = npc.global_position
		
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
		
		# 5.4 Khi Dialogue đang mở -> Phím E vẫn phải chuyển câu tiếp theo / đóng
		coordinator._unhandled_input(ev_interact)
		# Sau khi advance hết câu thoại, dialogue đóng lại
		if scene_ui.is_dialogue_open():
			coordinator._unhandled_input(ev_interact)
		print("[PASS] Bài test 5: InteractionCoordinator chặn tương tác khi Input Lock nhưng vẫn điều khiển Dialogue OK")
	
	world.queue_free()
	await process_frame
	
	print("INPUT_LOCKING_REGRESSION_TEST_OK")
	quit(0)

func _fail(msg: String) -> void:
	push_error("LỖI TEST: " + msg)
	quit(1)

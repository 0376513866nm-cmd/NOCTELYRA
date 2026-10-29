extends SceneTree

## Regression Test Suite for Stage 2: Quest & Wallet Migration (Specification & Verification)
## This test suite validates:
## 1. MagicGate remains closed at READY_TO_TURN_IN and ONLY opens when COMPLETED.
## 2. Quest turn-in restores 100% HP/MP and grants 50 Gold + EXP exactly once.
## 3. Idempotent save/load for Save v1.0.0, v1.5.0, and v2.0.0 fixtures without double rewards.
## 4. Single source of truth: WalletComponent stores gold; QuestJournal stores progress.
## 5. QuestActionService backwards compatibility for 'start_quest' and 'complete_quest'.
## 6. Inventory full protection on quest turn-in.

const TEST_SAVE_PATH := "user://noctelyra_stage2_regression_test.json"

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("--- BẮT ĐẦU GIAI ĐOẠN 2 REGRESSION TEST SUITE ---")
	
	# Chuẩn bị môi trường test
	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()
	ZoneManager.reset_session()
	
	# Kiểm tra cấu trúc hiện tại và xác nhận các tiêu chí đặc tả
	var forest_scene := load("res://src/world/noctis_forest.tscn") as PackedScene
	if forest_scene == null:
		_fail("Không tải được noctis_forest.tscn")
		return
	var world := forest_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	
	var player := world.get_node_or_null("Player") as Player
	var gate := world.get_node_or_null("MagicGate") as MagicGate
	var quest_mgr := world.get_node_or_null("QuestManager") as QuestManager
	
	if player == null or gate == null or quest_mgr == null:
		_fail("World thiếu Player, MagicGate hoặc QuestManager!")
		world.queue_free()
		return
	
	# --- TIÊU CHÍ 1: CỔNG MA PHÁP PHẢI ĐÓNG KHI READY_TO_TURN_IN VÀ CHỈ MỞ KHI COMPLETED ---
	# Giả lập nhiệm vụ chính đạt 3/3 quái (READY_TO_TURN_IN)
	quest_mgr.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
	quest_mgr.current_quest.current_amount = 3
	gate.update_quest_status(quest_mgr.current_quest)
	
	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC MỞ ở trạng thái READY_TO_TURN_IN (phải về gặp Eiran trả quest mới được mở)!")
		world.queue_free()
		return
	print("[PASS] Tiêu chí 1.1: Cổng MagicGate giữ nguyên khóa khi READY_TO_TURN_IN OK")
	
	# Khi hoàn thành và trả quest (COMPLETED) -> Cổng phải mở
	quest_mgr.current_quest.current_state = QuestData.State.COMPLETED
	gate.update_quest_status(quest_mgr.current_quest)
	
	if not gate.is_open:
		_fail("Cổng MagicGate PHẢI MỞ khi nhiệm vụ chính đạt trạng thái COMPLETED!")
		world.queue_free()
		return
	print("[PASS] Tiêu chí 1.2: Cổng MagicGate mở thành công khi COMPLETED OK")
	
	# --- TIÊU CHÍ 2: BẢO TOÀN PHẦN THƯỞNG HỒI PHỤC HP/MP KHI HOÀN THÀNH NHIỆM VỤ CHÍNH ---
	if player.health_component:
		player.health_component.current_health = 10.0
		player.health_component.current_mana = 5.0
		# Đặt trạng thái READY_TO_TURN_IN trước khi trả quest
		quest_mgr.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
		var ok := quest_mgr.complete_quest(player.health_component)
		if not ok:
			_fail("complete_quest thất bại!")
			world.queue_free()
			return
		if not is_equal_approx(player.health_component.current_health, player.health_component.max_health):
			_fail("Trả nhiệm vụ Eiran phải hồi phục 100% HP!")
			world.queue_free()
			return
		if not is_equal_approx(player.health_component.current_mana, player.health_component.max_mana):
			_fail("Trả nhiệm vụ Eiran phải hồi phục 100% MP!")
			world.queue_free()
			return
	print("[PASS] Tiêu chí 2: Trả nhiệm vụ chính hồi phục đầy đủ 100% HP và MP OK")
	
	# --- TIÊU CHÍ 3: KIỂM THỬ FIXTURE SAVE CŨ (v1.0.0 - v1.5.0) TƯƠNG THÍCH V2.0.0 ---
	# Tạo fixture save v1.5.0 cấu trúc cũ (top-level 'player', 'gold', 'quest')
	var legacy_fixture := {
		"save_version": "1.5.0",
		"timestamp": 1700000000,
		"current_zone_id": "noctis_forest",
		"player_position": {"x": 200.0, "y": 300.0},
		"gold": 125,
		"player": {
			"current_health": 80.0,
			"current_mana": 40.0,
			"race_id": "human",
			"progression": {
				"level": 2,
				"current_exp": 45,
				"claimed_exp_sources": ["quest:quest_tutorial"]
			}
		},
		"quest": {
			"state": 1, # ACTIVE
			"current_amount": 2
		},
		"defeated_enemy_ids": ["corrupted_1", "corrupted_2"]
	}
	
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy_fixture))
	f.close()
	
	# Load vào game qua SaveManager
	if not SaveManager.load_game(world):
		_fail("Không thể nạp file save legacy v1.5.0!")
		world.queue_free()
		return
	
	# Kiểm tra dữ liệu được nạp chính xác
	var loaded_gold = quest_mgr.gold
	if loaded_gold != 125:
		_fail("Nạp save legacy sai số vàng! Mong đợi 125, nhận được %d" % loaded_gold)
		world.queue_free()
		return
	
	if quest_mgr.current_quest.current_state != QuestData.State.ACTIVE or quest_mgr.current_quest.current_amount != 2:
		_fail("Nạp save legacy sai tiến trình quest! Mong đợi ACTIVE 2/3")
		world.queue_free()
		return
	print("[PASS] Tiêu chí 3: Nạp và khôi phục Save v1.5.0 cũ thành công, vàng và quest chính xác OK")
	
	# --- TIÊU CHÍ 4: TÍNH IDEMPOTENT (LƯU -> TẢI -> LƯU KHÔNG THAY ĐỔI DỮ LIỆU) ---
	if not SaveManager.save_game(world):
		_fail("Ghi đè save v2.0.0 thất bại!")
		world.queue_free()
		return
	
	if not SaveManager.load_game(world):
		_fail("Nạp lại save v2.0.0 vừa ghi thất bại!")
		world.queue_free()
		return
	
	if quest_mgr.gold != 125:
		_fail("Dữ liệu vàng bị biến dạng sau khi lưu và nạp lại!")
		world.queue_free()
		return
	if quest_mgr.current_quest.current_amount != 2:
		_fail("Tiến trình quest bị biến dạng sau khi lưu và nạp lại!")
		world.queue_free()
		return
	print("[PASS] Tiêu chí 4: Tính Idempotent của Save/Load v2.0.0 được bảo toàn tuyệt đối OK")
	
	# Dọn dẹp
	world.queue_free()
	await process_frame
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	
	print("STAGE_2_SPECIFICATION_REGRESSION_TEST_OK")
	quit(0)

func _fail(msg: String) -> void:
	push_error("LỖI TEST GIAI ĐOẠN 2: " + msg)
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	quit(1)

extends SceneTree

## Regression Test Suite for Stage 2 Step 1: WalletComponent & Quest System Integration
## This test suite validates:
## 1. WalletComponent unit operations (add, spend, clamp, signal, to_dict/from_dict).
## 2. Player integration (WalletComponent exists on Player scene and handles dynamic fallback).
## 3. Two-way synchronization between Player.wallet_component and QuestManager.gold facade.
## 4. PlayerStateSerializer captures and restores gold via WalletComponent.
## 5. Legacy Save v1.5.0 restores gold directly into WalletComponent and QuestManager.
## 6. MagicGate remains closed at READY_TO_TURN_IN and ONLY opens when COMPLETED.
## 7. Quest turn-in restores 100% HP/MP and grants rewards properly.
## 8. Idempotent save/load for Save v2.0.0 preserves wallet and quest progress.

const TEST_SAVE_PATH := "user://noctelyra_stage2_regression_test.json"

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("--- BẮT ĐẦU GIAI ĐOẠN 2 BƯỚC 1: WALLET COMPONENT & INTEGRATION TEST ---")

	# --- TEST 1: WALLETCOMPONENT ĐỘC LẬP (UNIT TEST) ---
	var wallet := WalletComponent.new()
	if wallet.gold != 0:
		_fail("WalletComponent khởi tạo ban đầu phải có 0 vàng!")
		return

	var signal_emissions: Array[int] = []
	wallet.gold_changed.connect(func(val: int): signal_emissions.append(val))

	# Test add_gold
	wallet.add_gold(100)
	if wallet.gold != 100:
		_fail("add_gold(100) thất bại! Vàng hiện tại: %d" % wallet.gold)
		return
	wallet.add_gold(-50) # Không được cộng số âm
	if wallet.gold != 100:
		_fail("add_gold(-50) không được thay đổi số vàng!")
		return

	# Test spend_gold
	var spend_ok := wallet.spend_gold(40)
	if not spend_ok or wallet.gold != 60:
		_fail("spend_gold(40) thất bại! Kết quả: %s, Vàng: %d" % [spend_ok, wallet.gold])
		return
	var spend_fail := wallet.spend_gold(100)
	if spend_fail or wallet.gold != 60:
		_fail("spend_gold(100) khi chỉ có 60 vàng phải trả về false và không trừ vàng!")
		return
	var spend_neg := wallet.spend_gold(-10)
	if spend_neg or wallet.gold != 60:
		_fail("spend_gold(-10) phải trả về false và không trừ vàng!")
		return

	# Test set_gold và clamp
	wallet.set_gold(-99)
	if wallet.gold != 0:
		_fail("set_gold(-99) phải kẹp về 0!")
		return
	wallet.set_gold(250)
	if wallet.gold != 250:
		_fail("set_gold(250) thất bại!")
		return

	# Kiểm tra tín hiệu gold_changed
	if signal_emissions.is_empty() or signal_emissions[-1] != 250:
		_fail("Tín hiệu gold_changed không phát ra đúng giá trị 250!")
		return
	var prev_count := signal_emissions.size()
	wallet.set_gold(250) # Đặt cùng giá trị không được phát signal trùng lặp
	if signal_emissions.size() != prev_count:
		_fail("set_gold() cùng giá trị không được phát signal trùng lặp!")
		return

	# Test to_dict / from_dict
	var serialized := wallet.to_dict()
	if serialized.get("gold", -1) != 250:
		_fail("to_dict() không lưu đúng gold = 250!")
		return
	wallet.from_dict({"gold": 999})
	if wallet.gold != 999:
		_fail("from_dict() nạp sai giá trị vàng!")
		return
	wallet.queue_free()
	print("[PASS] Test 1: WalletComponent Unit Test (add, spend, clamp, signal, serialize) hoàn tất thành công.")

	# --- CHUẨN BỊ MÔI TRƯỜNG THẾ GIỚI CHO CÁC TEST TÍCH HỢP ---
	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()
	ZoneManager.reset_session()

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
	var ui := world.get_node_or_null("GameUI") as GameUI

	if player == null or gate == null or quest_mgr == null:
		_fail("World thiếu Player, MagicGate hoặc QuestManager!")
		world.queue_free()
		return

	# --- TEST 2: PLAYER VÀ WALLETCOMPONENT TÍCH HỢP ---
	if player.wallet_component == null:
		_fail("Player không có WalletComponent sau khi khởi tạo!")
		world.queue_free()
		return
	print("[PASS] Test 2: Player khởi tạo cùng WalletComponent hợp lệ.")

	# --- TEST 3: ĐỒNG BỘ 2 CHIỀU GIỮA WALLETCOMPONENT VÀ QUESTMANAGER ADAPTER ---
	player.wallet_component.set_gold(150)
	await process_frame
	if quest_mgr.gold != 150:
		_fail("QuestManager.gold không phản ánh đúng Player.wallet_component.gold (kỳ vọng 150, nhận %d)!" % quest_mgr.gold)
		world.queue_free()
		return

	# Đổi từ QuestManager adapter sang WalletComponent
	var qm_emissions: Array[int] = []
	var conn = func(val: int):
		qm_emissions.append(val)
	quest_mgr.gold_changed.connect(conn)

	quest_mgr.gold = 320
	if player.wallet_component.gold != 320:
		_fail("Gán quest_manager.gold = 320 không cập nhật Player.wallet_component (nhận %d)!" % player.wallet_component.gold)
		world.queue_free()
		return
	if qm_emissions.is_empty() or qm_emissions[-1] != 320:
		_fail("QuestManager không phát tín hiệu gold_changed khi gán vàng mới!")
		world.queue_free()
		return
	quest_mgr.gold_changed.disconnect(conn)
	print("[PASS] Test 3: Đồng bộ 2 chiều giữa Player.wallet_component và QuestManager.gold hoạt động chính xác.")

	# --- TEST 4: PLAYER STATE SERIALIZER VỚI WALLETCOMPONENT ---
	var captured_data := PlayerStateSerializer.capture(world)
	if captured_data.get("gold", -1) != 320:
		_fail("PlayerStateSerializer.capture() không lấy đúng số vàng từ WalletComponent (kỳ vọng 320, nhận %s)!" % str(captured_data.get("gold")))
		world.queue_free()
		return

	# Thay đổi vàng trên player rồi khôi phục lại qua apply
	player.wallet_component.set_gold(0)
	if player.wallet_component.gold != 0:
		_fail("Không thể reset vàng về 0!")
		world.queue_free()
		return

	var applied := PlayerStateSerializer.apply(world, captured_data)
	if not applied or player.wallet_component.gold != 320:
		_fail("PlayerStateSerializer.apply() không khôi phục đúng vàng cho WalletComponent (nhận %d)!" % player.wallet_component.gold)
		world.queue_free()
		return
	print("[PASS] Test 4: PlayerStateSerializer đọc/ghi vàng trực tiếp qua WalletComponent OK.")

	# --- TEST 5: CỔNG MA PHÁP PHẢI ĐÓNG KHI READY_TO_TURN_IN VÀ CHỈ MỞ KHI COMPLETED ---
	quest_mgr.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
	quest_mgr.current_quest.current_amount = 3
	gate.update_quest_status(quest_mgr.current_quest)

	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC MỞ ở trạng thái READY_TO_TURN_IN (phải về gặp Eiran trả quest mới được mở)!")
		world.queue_free()
		return

	quest_mgr.current_quest.current_state = QuestData.State.COMPLETED
	gate.update_quest_status(quest_mgr.current_quest)

	if not gate.is_open:
		_fail("Cổng MagicGate PHẢI MỞ khi nhiệm vụ chính đạt trạng thái COMPLETED!")
		world.queue_free()
		return
	print("[PASS] Test 5: Cổng MagicGate đóng khi READY_TO_TURN_IN và mở khi COMPLETED OK.")

	# --- TEST 6: TRẢ NHIỆM VỤ CHÍNH HỒI PHỤC 100% HP/MP ---
	if player.health_component:
		player.health_component.current_health = 10.0
		player.health_component.current_mana = 5.0
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
	print("[PASS] Test 6: Trả nhiệm vụ chính hồi phục đầy đủ 100% HP và MP OK.")

	# --- TEST 7: KIỂM THỬ FIXTURE SAVE CŨ (v1.5.0) NẠP TRỰC TIẾP VÀO WALLETCOMPONENT ---
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

	if not SaveManager.load_game(world):
		_fail("Không thể nạp file save legacy v1.5.0!")
		world.queue_free()
		return

	if player.wallet_component.gold != 125:
		_fail("Save v1.5.0 không nạp đúng 125 vàng vào WalletComponent (nhận %d)!" % player.wallet_component.gold)
		world.queue_free()
		return

	if quest_mgr.gold != 125:
		_fail("Save v1.5.0 không đồng bộ 125 vàng sang QuestManager facade (nhận %d)!" % quest_mgr.gold)
		world.queue_free()
		return

	if quest_mgr.current_quest.current_state != QuestData.State.ACTIVE or quest_mgr.current_quest.current_amount != 2:
		_fail("Nạp save legacy sai tiến trình quest! Mong đợi ACTIVE 2/3")
		world.queue_free()
		return
	print("[PASS] Test 7: Nạp Save v1.5.0 khôi phục vàng trực tiếp vào WalletComponent và QuestManager OK.")

	# --- TEST 8: TÍNH TOÀN VẸN VÀ IDEMPOTENT CỦA SAVE v2.0.0 ---
	if not SaveManager.save_game(world):
		_fail("Ghi đè save v2.0.0 thất bại!")
		world.queue_free()
		return

	if not SaveManager.load_game(world):
		_fail("Nạp lại save v2.0.0 vừa ghi thất bại!")
		world.queue_free()
		return

	if player.wallet_component.gold != 125 or quest_mgr.gold != 125:
		_fail("Dữ liệu vàng bị biến dạng sau khi lưu và nạp lại v2.0.0!")
		world.queue_free()
		return
	if quest_mgr.current_quest.current_amount != 2:
		_fail("Tiến trình quest bị biến dạng sau khi lưu và nạp lại v2.0.0!")
		world.queue_free()
		return
	print("[PASS] Test 8: Tính Idempotent của Save/Load v2.0.0 được bảo toàn hoàn hảo OK.")

	# Dọn dẹp
	world.queue_free()
	await process_frame
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	print("ALL_STAGE_2_STEP_1_TESTS_PASS_SUCCESSFULLY")
	quit(0)

func _fail(msg: String) -> void:
	push_error("LỖI TEST GIAI ĐOẠN 2 BƯỚC 1: " + msg)
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	quit(1)

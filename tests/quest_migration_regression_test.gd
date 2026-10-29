extends SceneTree

## Regression Test Suite for Stage 2 Step 1: WalletComponent & Currency System Hardening
## Validates:
## 1. WalletComponent unit operations (add, spend, clamp, signal debounce, serialize).
## 2. Player integration (WalletComponent exists on Player scene).
## 3. Strict Signal Accounting: zero duplicate signals across add_gold, spend_gold,
##    quest_mgr.gold facade setter, complete_quest(), and PlayerStateSerializer.apply().
## 4. PlayerStateSerializer captures and restores gold via WalletComponent.
## 5. MagicGate remains closed at READY_TO_TURN_IN and ONLY opens when COMPLETED.
## 6. Quest turn-in restores 100% HP/MP and grants rewards properly.
## 7. Legacy Save v1.5.0 restores gold directly into WalletComponent and QuestManager.
## 8. Idempotent save/load for Save v2.0.0 preserves wallet and quest progress.
## 9. Multi-zone travel A -> B -> A preserving and accumulating gold, followed by Save/Load.

const TEST_SAVE_PATH := "user://noctelyra_stage2_regression_test.json"

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("--- BẮT ĐẦU GIAI ĐOẠN 2 BƯỚC 1: HARDENED WALLET & INTEGRATION TESTS ---")

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
		_fail("add_gold(100) thất bại! Vàng: %d" % wallet.gold)
		return
	wallet.add_gold(-50)
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
		_fail("spend_gold(100) khi chỉ có 60 vàng phải trả về false!")
		return
	var spend_neg := wallet.spend_gold(-10)
	if spend_neg or wallet.gold != 60:
		_fail("spend_gold(-10) phải trả về false!")
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

	# Kiểm tra debounce tín hiệu: cùng giá trị không được phát signal
	var prev_count := signal_emissions.size()
	wallet.set_gold(250)
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
	print("[PASS] Test 1: WalletComponent Unit Test (add, spend, clamp, debounce, serialize) hoàn tất.")

	# --- CHUẨN BỊ MÔI TRƯỜNG THẾ GIỚI ---
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

	# --- TEST 3: KIỂM SOÁT TÍN HIỆU NGHIÊM NGẶT (STRICT SIGNAL ACCOUNTING) ---
	# Đếm chính xác số lần phát tín hiệu của cả Wallet và QuestManager
	var wallet_signals: Array[int] = []
	var qm_signals: Array[int] = []

	var wallet_cb = func(val: int): wallet_signals.append(val)
	var qm_cb = func(val: int): qm_signals.append(val)

	player.wallet_component.gold_changed.connect(wallet_cb)
	quest_mgr.gold_changed.connect(qm_cb)

	# 3.1. add_gold(100): đúng 1 signal trên mỗi bên
	player.wallet_component.set_gold(0) # reset
	wallet_signals.clear()
	qm_signals.clear()

	player.wallet_component.add_gold(100)
	if wallet_signals.size() != 1 or wallet_signals[0] != 100:
		_fail("add_gold(100) phải phát đúng 1 signal trên Wallet! Nhận %d lần" % wallet_signals.size())
		world.queue_free()
		return
	if qm_signals.size() != 1 or qm_signals[0] != 100:
		_fail("add_gold(100) phải phát đúng 1 signal trên QuestManager! Nhận %d lần" % qm_signals.size())
		world.queue_free()
		return

	# 3.2. spend_gold(40): đúng 1 signal trên mỗi bên
	wallet_signals.clear()
	qm_signals.clear()
	player.wallet_component.spend_gold(40)
	if wallet_signals.size() != 1 or wallet_signals[0] != 60:
		_fail("spend_gold(40) phải phát đúng 1 signal trên Wallet! Nhận %d lần" % wallet_signals.size())
		world.queue_free()
		return
	if qm_signals.size() != 1 or qm_signals[0] != 60:
		_fail("spend_gold(40) phải phát đúng 1 signal trên QuestManager! Nhận %d lần" % qm_signals.size())
		world.queue_free()
		return

	# 3.3. quest_mgr.gold = 300: đúng 1 signal trên mỗi bên
	wallet_signals.clear()
	qm_signals.clear()
	quest_mgr.gold = 300
	if wallet_signals.size() != 1 or wallet_signals[0] != 300:
		_fail("quest_mgr.gold = 300 phải phát đúng 1 signal trên Wallet! Nhận %d lần" % wallet_signals.size())
		world.queue_free()
		return
	if qm_signals.size() != 1 or qm_signals[0] != 300:
		_fail("quest_mgr.gold = 300 phải phát đúng 1 signal trên QuestManager! Nhận %d lần" % qm_signals.size())
		world.queue_free()
		return

	# 3.4. Gán cùng giá trị: đúng 0 signal trên cả hai
	wallet_signals.clear()
	qm_signals.clear()
	quest_mgr.gold = 300
	player.wallet_component.set_gold(300)
	if wallet_signals.size() != 0 or qm_signals.size() != 0:
		_fail("Gán cùng giá trị không được phát signal nào! Wallet: %d, QM: %d" % [wallet_signals.size(), qm_signals.size()])
		world.queue_free()
		return

	# 3.5. complete_quest(): đúng 1 signal duy nhất khi trao thưởng vàng
	wallet_signals.clear()
	qm_signals.clear()
	quest_mgr.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
	quest_mgr.current_quest.reward_gold = 50
	var prev_gold := player.wallet_component.gold
	quest_mgr.complete_quest(player.health_component)

	if player.wallet_component.gold != prev_gold + 50:
		_fail("complete_quest không cộng đúng 50 vàng!")
		world.queue_free()
		return
	if wallet_signals.size() != 1:
		_fail("complete_quest() phải phát đúng 1 signal trên Wallet! Nhận %d lần" % wallet_signals.size())
		world.queue_free()
		return
	if qm_signals.size() != 1:
		_fail("complete_quest() phát trùng signal trên QuestManager! Kỳ vọng 1 lần, nhận %d lần" % qm_signals.size())
		world.queue_free()
		return

	# 3.6. PlayerStateSerializer.apply(): đúng 1 signal duy nhất khi nạp giá trị mới
	wallet_signals.clear()
	qm_signals.clear()
	var test_data := PlayerStateSerializer.capture(world)
	test_data["gold"] = 777
	PlayerStateSerializer.apply(world, test_data)

	if wallet_signals.size() != 1:
		_fail("PlayerStateSerializer.apply() phải phát đúng 1 signal trên Wallet! Nhận %d lần" % wallet_signals.size())
		world.queue_free()
		return
	if qm_signals.size() != 1:
		_fail("PlayerStateSerializer.apply() phát trùng signal trên QuestManager! Kỳ vọng 1 lần, nhận %d lần" % qm_signals.size())
		world.queue_free()
		return

	# 3.7. PlayerStateSerializer.apply() với cùng số vàng: đúng 0 signal
	wallet_signals.clear()
	qm_signals.clear()
	PlayerStateSerializer.apply(world, test_data)
	if wallet_signals.size() != 0 or qm_signals.size() != 0:
		_fail("PlayerStateSerializer.apply() với số vàng không đổi không được phát signal!")
		world.queue_free()
		return

	player.wallet_component.gold_changed.disconnect(wallet_cb)
	quest_mgr.gold_changed.disconnect(qm_cb)
	print("[PASS] Test 3: Kiểm soát tín hiệu nghiêm ngặt (Strict Signal Accounting): 100% không phát trùng lặp.")

	# --- TEST 4: PLAYER STATE SERIALIZER ROUND-TRIP ---
	player.wallet_component.set_gold(450)
	var captured := PlayerStateSerializer.capture(world)
	if captured.get("gold", -1) != 450:
		_fail("capture() không lưu đúng gold = 450 từ WalletComponent!")
		world.queue_free()
		return
	player.wallet_component.set_gold(0)
	PlayerStateSerializer.apply(world, captured)
	if player.wallet_component.gold != 450 or quest_mgr.gold != 450:
		_fail("apply() không khôi phục đúng gold = 450!")
		world.queue_free()
		return
	print("[PASS] Test 4: PlayerStateSerializer round-trip thành công.")

	# --- TEST 5: CỔNG MA PHÁP PHẢI ĐÓNG KHI READY_TO_TURN_IN VÀ CHỈ MỞ KHI COMPLETED ---
	quest_mgr.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
	quest_mgr.current_quest.current_amount = 3
	gate.update_quest_status(quest_mgr.current_quest)

	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC MỞ ở trạng thái READY_TO_TURN_IN!")
		world.queue_free()
		return

	quest_mgr.current_quest.current_state = QuestData.State.COMPLETED
	gate.update_quest_status(quest_mgr.current_quest)

	if not gate.is_open:
		_fail("Cổng MagicGate PHẢI MỞ khi nhiệm vụ chính COMPLETED!")
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
			_fail("Trả nhiệm vụ phải hồi phục 100% HP!")
			world.queue_free()
			return
		if not is_equal_approx(player.health_component.current_mana, player.health_component.max_mana):
			_fail("Trả nhiệm vụ phải hồi phục 100% MP!")
			world.queue_free()
			return
	print("[PASS] Test 6: Trả nhiệm vụ chính hồi phục đầy đủ 100% HP và MP OK.")

	# --- TEST 7: KIỂM THỬ FIXTURE SAVE CŨ (v1.5.0) NẠP TRỰC TIẾP VÀO WALLET VÀ QUESTMANAGER ---
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
			"state": 1,
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

	if player.wallet_component.gold != 125 or quest_mgr.gold != 125:
		_fail("Save v1.5.0 không nạp đúng 125 vàng (Wallet: %d, QM: %d)!" % [player.wallet_component.gold, quest_mgr.gold])
		world.queue_free()
		return
	if quest_mgr.current_quest.current_state != QuestData.State.ACTIVE:
		_fail("Save v1.5.0 không khôi phục trạng thái ACTIVE (nhận: %d)!" % quest_mgr.current_quest.current_state)
		world.queue_free()
		return
	if quest_mgr.current_quest.current_amount != 2:
		_fail("Save v1.5.0 không khôi phục đúng tiến độ quái 2/3 (nhận: %d)!" % quest_mgr.current_quest.current_amount)
		world.queue_free()
		return
	if not ("corrupted_1" in quest_mgr._killed_enemy_ids and "corrupted_2" in quest_mgr._killed_enemy_ids):
		_fail("Save v1.5.0 không khôi phục danh sách killed_enemy_ids!")
		world.queue_free()
		return
	print("[PASS] Test 7.1: Nạp Save v1.5.0 ACTIVE (2/3 quái, killed_enemy_ids) khôi phục chính xác 100%.")

	# 7.2 Kiểm tra Save với READY_TO_TURN_IN (3/3 quái) -> Cổng phải ĐÓNG
	legacy_fixture["quest"]["state"] = 2 # READY_TO_TURN_IN
	legacy_fixture["quest"]["current_amount"] = 3
	legacy_fixture["defeated_enemy_ids"] = ["corrupted_1", "corrupted_2", "corrupted_3"]
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy_fixture))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp file save v1.5.0 READY_TO_TURN_IN!")
		world.queue_free()
		return
	if quest_mgr.current_quest.current_state != QuestData.State.READY_TO_TURN_IN or quest_mgr.current_quest.current_amount != 3:
		_fail("Khôi phục trạng thái READY_TO_TURN_IN 3/3 thất bại!")
		world.queue_free()
		return
	gate.update_quest_status(quest_mgr.current_quest)
	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC MỞ khi nạp save READY_TO_TURN_IN!")
		world.queue_free()
		return
	print("[PASS] Test 7.2: Nạp Save v1.5.0 READY_TO_TURN_IN giữ nguyên khóa Cổng Ma Pháp OK.")

	# 7.3 Kiểm tra Save với COMPLETED -> Cổng phải MỞ
	legacy_fixture["quest"]["state"] = 3 # COMPLETED
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy_fixture))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp file save v1.5.0 COMPLETED!")
		world.queue_free()
		return
	if quest_mgr.current_quest.current_state != QuestData.State.COMPLETED:
		_fail("Khôi phục trạng thái COMPLETED thất bại!")
		world.queue_free()
		return
	gate.update_quest_status(quest_mgr.current_quest)
	if not gate.is_open:
		_fail("Cổng MagicGate PHẢI MỞ khi nạp save COMPLETED!")
		world.queue_free()
		return
	print("[PASS] Test 7.3: Nạp Save v1.5.0 COMPLETED mở Cổng Ma Pháp OK.")

	# --- TEST 8: TÍNH TOÀN VẸN VÀ IDEMPOTENT CỦA SAVE v2.0.0 ---
	# Đặt trạng thái ACTIVE 2/3 để test lưu/nạp Idempotent
	quest_mgr.current_quest.current_state = QuestData.State.ACTIVE
	quest_mgr.current_quest.current_amount = 2
	quest_mgr._killed_enemy_ids = ["corrupted_1", "corrupted_2"]
	player.wallet_component.set_gold(125)

	if not SaveManager.save_game(world):
		_fail("Ghi đè save v2.0.0 thất bại!")
		world.queue_free()
		return

	if not SaveManager.load_game(world):
		_fail("Nạp lại save v2.0.0 thất bại!")
		world.queue_free()
		return

	if player.wallet_component.gold != 125 or quest_mgr.gold != 125:
		_fail("Dữ liệu vàng bị biến dạng sau khi lưu và nạp lại v2.0.0!")
		world.queue_free()
		return
	if quest_mgr.current_quest.current_state != QuestData.State.ACTIVE or quest_mgr.current_quest.current_amount != 2:
		_fail("Tiến trình quest bị biến dạng sau khi lưu và nạp lại v2.0.0!")
		world.queue_free()
		return
	if not ("corrupted_1" in quest_mgr._killed_enemy_ids and "corrupted_2" in quest_mgr._killed_enemy_ids):
		_fail("Danh sách killed_enemy_ids bị biến dạng sau khi lưu và nạp lại v2.0.0!")
		world.queue_free()
		return
	print("[PASS] Test 8: Tính Idempotent của Save/Load v2.0.0 (vàng, quest state, killed quái) bảo toàn hoàn hảo OK.")

	# Dọn dẹp world noctis_forest
	world.queue_free()
	await process_frame

	# --- TEST 9: CHUYỂN VÙNG A -> B -> A, TÍCH LŨY VÀNG VÀ SAVE/LOAD ---
	# 9.1 Khởi tạo Vùng A (Noctis Forest) với 50 vàng và tiến độ quest ACTIVE 2/3
	var world_a := forest_scene.instantiate()
	root.add_child(world_a)
	await process_frame
	await process_frame

	var player_a := world_a.get_node_or_null("Player") as Player
	var quest_mgr_a := world_a.get_node_or_null("QuestManager") as QuestManager
	player_a.wallet_component.set_gold(50)
	quest_mgr_a.current_quest.current_state = QuestData.State.ACTIVE
	quest_mgr_a.current_quest.current_amount = 2
	quest_mgr_a._killed_enemy_ids = ["corrupted_1", "corrupted_2"]

	# Lưu trạng thái phiên chuyển vùng
	ZoneManager.session_player_data = ZoneManager.extract_player_state(world_a)
	world_a.queue_free()
	await process_frame

	# 9.2 Chuyển sang Vùng B (Elyndra Glade)
	var elyndra_scene := load("res://src/world/elyndra_glade.tscn") as PackedScene
	if elyndra_scene == null:
		_fail("Không tải được elyndra_glade.tscn")
		return
	var world_b := elyndra_scene.instantiate()
	root.add_child(world_b)
	await process_frame
	await process_frame

	# Áp dụng dữ liệu phiên chuyển vùng sang Vùng B
	ZoneManager.apply_player_state(world_b, ZoneManager.session_player_data)
	var player_b := world_b.get_node_or_null("Player") as Player
	if player_b == null or player_b.wallet_component == null:
		_fail("Vùng B thiếu Player hoặc WalletComponent!")
		world_b.queue_free()
		return

	if player_b.wallet_component.gold != 50:
		_fail("Chuyển từ Vùng A sang Vùng B mất vàng! Kỳ vọng 50, nhận %d" % player_b.wallet_component.gold)
		world_b.queue_free()
		return

	# Tại Vùng B: Người chơi kiếm thêm 75 vàng
	player_b.wallet_component.add_gold(75)
	if player_b.wallet_component.gold != 125:
		_fail("Kiếm thêm 75 vàng ở Vùng B thất bại! Nhận %d" % player_b.wallet_component.gold)
		world_b.queue_free()
		return

	# Lưu trạng thái trước khi rời Vùng B
	ZoneManager.session_player_data = ZoneManager.extract_player_state(world_b)
	world_b.queue_free()
	await process_frame

	# 9.3 Chuyển ngược lại Vùng A (Noctis Forest)
	var world_a2 := forest_scene.instantiate()
	root.add_child(world_a2)
	await process_frame
	await process_frame

	ZoneManager.apply_player_state(world_a2, ZoneManager.session_player_data)
	var player_a2 := world_a2.get_node_or_null("Player") as Player
	var quest_mgr_a2 := world_a2.get_node_or_null("QuestManager") as QuestManager
	var ui_a2 := world_a2.get_node_or_null("GameUI") as GameUI

	if player_a2.wallet_component.gold != 125:
		_fail("Chuyển từ Vùng B về lại Vùng A mất vàng! Kỳ vọng 125, nhận %d" % player_a2.wallet_component.gold)
		world_a2.queue_free()
		return
	if quest_mgr_a2.gold != 125:
		_fail("QuestManager ở Vùng A không đồng bộ 125 vàng sau khi chuyển vùng về!")
		world_a2.queue_free()
		return
	if quest_mgr_a2.current_quest.current_state != QuestData.State.ACTIVE or quest_mgr_a2.current_quest.current_amount != 2:
		_fail("Tiến trình quest bị mất sau khi chuyển vùng về Vùng A!")
		world_a2.queue_free()
		return

	# Kiểm tra HUD tự động cập nhật qua signal (KHÔNG gọi thủ công ui_a2.update_gold)
	if ui_a2:
		var gold_label = ui_a2.get_node_or_null("TopBar/HBox/GoldContainer/GoldLabel") as Label
		if gold_label and gold_label.text != "125":
			_fail("HUD không tự động hiển thị đúng 125 vàng qua signal! Mong đợi '125', nhận '%s'" % gold_label.text)
			world_a2.queue_free()
			return

	# 9.4 Lưu game sau chuỗi chuyển vùng A -> B -> A
	if not SaveManager.save_game(world_a2):
		_fail("Save game sau chuỗi chuyển vùng A -> B -> A thất bại!")
		world_a2.queue_free()
		return
	world_a2.queue_free()
	await process_frame

	# 9.5 Nạp lại save game vào một instance hoàn toàn mới
	var world_a3 := forest_scene.instantiate()
	root.add_child(world_a3)
	await process_frame
	await process_frame

	if not SaveManager.load_game(world_a3):
		_fail("Nạp lại save game sau chuỗi chuyển vùng thất bại!")
		world_a3.queue_free()
		return

	var player_a3 := world_a3.get_node_or_null("Player") as Player
	var quest_mgr_a3 := world_a3.get_node_or_null("QuestManager") as QuestManager
	var ui_a3 := world_a3.get_node_or_null("GameUI") as GameUI

	if player_a3.wallet_component.gold != 125 or quest_mgr_a3.gold != 125:
		_fail("Nạp bản lưu sau chuỗi chuyển vùng bị sai số vàng! Wallet: %d, QM: %d" % [player_a3.wallet_component.gold, quest_mgr_a3.gold])
		world_a3.queue_free()
		return

	if quest_mgr_a3.current_quest.current_state != QuestData.State.ACTIVE or quest_mgr_a3.current_quest.current_amount != 2:
		_fail("Nạp bản lưu sau chuỗi chuyển vùng bị sai tiến trình quest! State: %d, Amount: %d" % [quest_mgr_a3.current_quest.current_state, quest_mgr_a3.current_quest.current_amount])
		world_a3.queue_free()
		return

	if ui_a3:
		var gold_label = ui_a3.get_node_or_null("TopBar/HBox/GoldContainer/GoldLabel") as Label
		if gold_label and gold_label.text != "125":
			_fail("HUD hiển thị sai sau khi nạp save! Kỳ vọng '125', nhận '%s'" % gold_label.text)
			world_a3.queue_free()
			return

	world_a3.queue_free()
	await process_frame
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	print("[PASS] Test 9: Chuyển vùng A -> B -> A, tích lũy vàng liên vùng và Save/Load thành công 100%.")

	print("ALL_STAGE_2_STEP_1_HARDENED_TESTS_PASS_SUCCESSFULLY")
	quit(0)

func _fail(msg: String) -> void:
	push_error("LỖI TEST GIAI ĐOẠN 2 BƯỚC 1: " + msg)
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	quit(1)

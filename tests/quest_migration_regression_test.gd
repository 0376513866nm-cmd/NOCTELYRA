extends SceneTree

## Regression Test Suite for Stage 2 Step 3: Idempotent Save & Quest Migration
## Validates:
## 1. WalletComponent unit operations (add, spend, clamp, signal debounce, serialize).
## 2. Player integration (WalletComponent exists on Player scene).
## 3. Strict Signal Accounting across all gold pathways: add_gold, spend_gold,
##    WalletComponent add_gold, spend_gold, set_gold, turn-in, Boss reward, Serializer apply.
## 4. PlayerStateSerializer captures and restores gold via WalletComponent.
## 5. MagicGate remains closed at READY_TO_TURN_IN and ONLY opens when COMPLETED.
## 6. Quest turn-in restores 100% HP/MP and grants rewards properly.
## 7. Migration Test Suite:
##    7.1: Legacy Save v1.5.0 ACTIVE (2/3 quái) -> Migrates into QuestJournal.
##    7.2: Save with both legacy_quest (ACTIVE 2/3) and unmigrated default quest_journal (NOT_STARTED).
##    7.3: Legacy Save v1.5.0 READY_TO_TURN_IN -> Gate auto-syncs closed.
##    7.4: Legacy Save v1.5.0 COMPLETED -> Gate auto-syncs OPEN, reward_claimed=true, double EXP blocked.
## 8. Idempotent round-trip (Save -> Load -> Save -> Load) produces zero distortion.
## 9. Multi-zone travel A -> B -> A preserving and accumulating gold, followed by Save/Load.

const TEST_SAVE_PATH := "user://noctelyra_stage2_regression_test.json"

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("--- BẮT ĐẦU GIAI ĐOẠN 2 BƯỚC 3: IDEMPOTENT QUEST & SAVE MIGRATION TEST SUITE ---")

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
	var ui := world.get_node_or_null("GameUI") as GameUI

	if player == null or gate == null or ui == null:
		_fail("World thiếu Player, MagicGate hoặc GameUI!")
		world.queue_free()
		return

	# --- TEST 2: PLAYER VÀ WALLETCOMPONENT TÍCH HỢP ---
	if player.wallet_component == null:
		_fail("Player không có WalletComponent sau khi khởi tạo!")
		world.queue_free()
		return
	print("[PASS] Test 2: Player khởi tạo cùng WalletComponent hợp lệ.")

	# --- TEST 3: KIỂM SOÁT TÍN HIỆU NGHIÊM NGẶT (STRICT SIGNAL ACCOUNTING) ---
	var wallet_signals: Array[int] = []
	var wallet_cb = func(val: int): wallet_signals.append(val)

	player.wallet_component.gold_changed.connect(wallet_cb)

	# 3.1. add_gold(100): đúng 1 signal
	player.wallet_component.set_gold(0)
	wallet_signals.clear()

	player.wallet_component.add_gold(100)
	if wallet_signals.size() != 1 or wallet_signals[0] != 100:
		_fail("add_gold(100) phải phát đúng 1 signal!")
		world.queue_free()
		return

	# 3.2. spend_gold(40): đúng 1 signal
	wallet_signals.clear()
	player.wallet_component.spend_gold(40)
	if wallet_signals.size() != 1 or wallet_signals[0] != 60:
		_fail("spend_gold(40) phải phát đúng 1 signal!")
		world.queue_free()
		return

	# 3.3. spend_gold quá số dư: không phát signal và trả về false
	wallet_signals.clear()
	var spend_failed := player.wallet_component.spend_gold(100)
	if spend_failed or wallet_signals.size() != 0:
		_fail("spend_gold quá số dư không được phát signal!")
		world.queue_free()
		return

	# 3.4. Gán cùng giá trị: đúng 0 signal (debounce)
	wallet_signals.clear()
	player.wallet_component.set_gold(60)
	if wallet_signals.size() != 0:
		_fail("Gán cùng giá trị không được phát signal nào!")
		world.queue_free()
		return

	# 3.5. Main Quest turn-in: đúng 1 signal duy nhất khi trao thưởng vàng
	wallet_signals.clear()
	var journal := player.quest_journal_component
	journal.reconcile_quest_state("quest_noctis_purify", QuestDefinition.State.READY_TO_TURN_IN, 3, false)
	var prev_gold := player.wallet_component.gold
	var turn_res := journal.turn_in_quest("quest_noctis_purify", player.inventory_component)
	if not turn_res.get("success", false):
		_fail("turn_in_quest cho Main Quest thất bại!")
		world.queue_free()
		return

	if player.wallet_component.gold != prev_gold + 50 or wallet_signals.size() != 1:
		_fail("turn_in_quest() phải phát đúng 1 signal trao thưởng vàng!")
		world.queue_free()
		return

	# 3.6. Side Quest turn-in: đúng 1 signal duy nhất khi nhận thưởng vàng
	wallet_signals.clear()
	var side_def := ContentRegistry.get_quest("quest_elyndra_cleansing")
	if side_def:
		journal.start_quest("quest_elyndra_cleansing")
		journal.reconcile_quest_state("quest_elyndra_cleansing", QuestDefinition.State.READY_TO_TURN_IN, side_def.target_amount, false)
		var prev_side_gold := player.wallet_component.gold
		var res := journal.turn_in_quest("quest_elyndra_cleansing", player.inventory_component)
		if not res.get("success", false):
			_fail("turn_in_quest thất bại!")
			world.queue_free()
			return
		if player.wallet_component.gold != prev_side_gold + side_def.reward_gold:
			_fail("turn_in_quest không cộng đúng vàng thưởng!")
			world.queue_free()
			return
		if wallet_signals.size() != 1:
			_fail("turn_in_quest phát trùng signal! Wallet: %d" % wallet_signals.size())
			world.queue_free()
			return

	# 3.7. Boss reward: đúng 1 signal duy nhất khi nhận thưởng 100 vàng
	wallet_signals.clear()
	world.boss_reward_claimed = false # reset để nhận thưởng test
	var prev_boss_gold := player.wallet_component.gold
	world.grant_boss_reward()
	if player.wallet_component.gold != prev_boss_gold + 100:
		_fail("grant_boss_reward() không cộng đúng 100 vàng!")
		world.queue_free()
		return
	if wallet_signals.size() != 1:
		_fail("grant_boss_reward() phát trùng signal! Wallet: %d" % wallet_signals.size())
		world.queue_free()
		return

	# 3.8. PlayerStateSerializer.apply(): đúng 1 signal duy nhất khi nạp giá trị mới
	wallet_signals.clear()
	var test_data := PlayerStateSerializer.capture(world)
	test_data["gold"] = 777
	PlayerStateSerializer.apply(world, test_data)

	if wallet_signals.size() != 1:
		_fail("PlayerStateSerializer.apply() phải phát đúng 1 signal!")
		world.queue_free()
		return

	# 3.9. PlayerStateSerializer.apply() với cùng số vàng: đúng 0 signal
	wallet_signals.clear()
	PlayerStateSerializer.apply(world, test_data)
	if wallet_signals.size() != 0:
		_fail("PlayerStateSerializer.apply() với số vàng không đổi không được phát signal!")
		world.queue_free()
		return

	player.wallet_component.gold_changed.disconnect(wallet_cb)
	print("[PASS] Test 3: Kiểm soát tín hiệu nghiêm ngặt (Strict Signal Accounting): 100% không phát trùng lặp.")

	# --- TEST 4: PLAYER STATE SERIALIZER ROUND-TRIP ---
	player.wallet_component.set_gold(450)
	var captured := PlayerStateSerializer.capture(world)
	if captured.get("gold", -1) != 450:
		_fail("capture() không lưu đúng gold = 450 từ WalletComponent!")
		world.queue_free()
		return
	if captured.has("legacy_quest") or captured.has("killed_enemy_ids"):
		_fail("capture() v2.0 không được chứa legacy_quest hay killed_enemy_ids!")
		world.queue_free()
		return
	player.wallet_component.set_gold(0)
	PlayerStateSerializer.apply(world, captured)
	if player.wallet_component.gold != 450:
		_fail("apply() không khôi phục đúng gold = 450!")
		world.queue_free()
		return
	print("[PASS] Test 4: PlayerStateSerializer round-trip thành công.")

	# --- TEST 5: CỔNG MA PHÁP PHẢI ĐÓNG KHI READY_TO_TURN_IN VÀ CHỈ MỞ KHI COMPLETED ---
	journal.reconcile_quest_state("quest_noctis_purify", QuestDefinition.State.READY_TO_TURN_IN, 3, false)
	gate.update_quest_status()

	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC MỞ ở trạng thái READY_TO_TURN_IN!")
		world.queue_free()
		return

	journal.reconcile_quest_state("quest_noctis_purify", QuestDefinition.State.COMPLETED, 3, true)
	gate.update_quest_status()

	if not gate.is_open:
		_fail("Cổng MagicGate PHẢI MỞ khi nhiệm vụ chính COMPLETED!")
		world.queue_free()
		return
	print("[PASS] Test 5: Cổng MagicGate đóng khi READY_TO_TURN_IN và mở khi COMPLETED OK.")

	# --- TEST 6: TRẢ NHIỆM VỤ CHÍNH HỒI PHỤC 100% HP/MP ---
	if player.health_component:
		player.health_component.current_health = 10.0
		player.health_component.current_mana = 5.0
		journal.reconcile_quest_state("quest_noctis_purify", QuestDefinition.State.READY_TO_TURN_IN, 3, false)
		var res := journal.turn_in_quest("quest_noctis_purify", player.inventory_component)
		if not res.get("success", false):
			_fail("turn_in_quest thất bại!")
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

	# --- TEST 7: BỘ KIỂM THỬ MIGRATION TOÀN DIỆN (BƯỚC 3) ---
	# 7.1: Nạp Save Legacy v1.5.0 ACTIVE 2/3 quái -> Đồng bộ sang Main Quest của QuestJournal
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
		_fail("Save v1.5.0 không nạp đúng 125 vàng!")
		world.queue_free()
		return

	# Xác minh Migration sang QuestJournal
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE:
		_fail("Legacy Quest ACTIVE không được migrate sang quest_noctis_purify trong Journal!")
		world.queue_free()
		return
	if journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Tiến độ 2/3 không được migrate sang quest_noctis_purify trong Journal!")
		world.queue_free()
		return
	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC TỰ MỞ khi nạp save ACTIVE 2/3!")
		world.queue_free()
		return
	print("[PASS] Test 7.1: Nạp Save v1.5.0 ACTIVE (2/3 quái) migrate tự động sang QuestJournal OK.")

	# 7.2: Save chứa đồng thời legacy_quest (ACTIVE 2/3) và quest_journal mặc định NOT_STARTED
	# Kiểm tra cơ chế ưu tiên dữ liệu từ Save Gốc, không bị bẫy bởi default NOT_STARTED của Journal
	var mixed_fixture := {
		"save_version": "2.0.0",
		"timestamp": 1700000001,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 45,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 125,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 0, # NOT_STARTED (mặc định chưa migrate)
					"current_amount": 0,
					"reward_claimed": false,
					"counted_enemy_ids": []
				}
			},
			"legacy_quest": {
				"state": 1, # ACTIVE thực sự
				"current_amount": 2
			},
			"killed_enemy_ids": ["corrupted_1", "corrupted_2"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(mixed_fixture))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp file save mixed v2.0.0!")
		world.queue_free()
		return

	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE or journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Save chứa quest_journal mặc định NOT_STARTED phải được ưu tiên ghi đè bởi legacy_quest có tiến trình!")
		world.queue_free()
		return
	print("[PASS] Test 7.2: Save chứa mixed journal NOT_STARTED & legacy ACTIVE 2/3 migrate chuẩn xác 100%.")

	# 7.3: Save READY_TO_TURN_IN (3/3 quái) -> Cổng phải tự động giữ KHÓA sau khi load save
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
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.READY_TO_TURN_IN:
		_fail("Journal không đạt READY_TO_TURN_IN sau khi migrate!")
		world.queue_free()
		return
	# KHÔNG gọi thủ công gate.update_quest_status() -> Kiểm tra cổng tự đồng bộ
	if gate.is_open:
		_fail("Cổng MagicGate KHÔNG ĐƯỢC MỞ khi nạp save READY_TO_TURN_IN (phải tự động khóa)!")
		world.queue_free()
		return
	print("[PASS] Test 7.3: Nạp Save v1.5.0 READY_TO_TURN_IN tự động giữ khóa Cổng Ma Pháp OK.")

	# 7.4: Save COMPLETED -> Cổng phải TỰ ĐỘNG MỞ và chặn nhận thưởng trùng tuyệt đối
	legacy_fixture["quest"]["state"] = 3 # COMPLETED
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy_fixture))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp file save v1.5.0 COMPLETED!")
		world.queue_free()
		return
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.COMPLETED:
		_fail("Journal không đạt COMPLETED sau khi migrate!")
		world.queue_free()
		return
	if not journal.is_reward_claimed("quest_noctis_purify"):
		_fail("Main Quest migrate COMPLETED phải có reward_claimed = true!")
		world.queue_free()
		return
	# Cổng Ma Pháp phải tự động MỞ sau khi load save mà KHÔNG cần gọi thủ công
	if not gate.is_open:
		_fail("Cổng MagicGate PHẢI TỰ ĐỘNG MỞ sau khi nạp save COMPLETED!")
		world.queue_free()
		return

	# Kiểm tra bảo vệ chống nhận thưởng trùng
	if not player.progression_component.has_claimed_source("quest:quest_tutorial"):
		_fail("Progression thiếu nguồn EXP 'quest:quest_tutorial'!")
		world.queue_free()
		return
	if not player.progression_component.has_claimed_source("quest:quest_noctis_purify"):
		_fail("Progression thiếu nguồn EXP 'quest:quest_noctis_purify'!")
		world.queue_free()
		return
	var double_exp_ok := player.progression_component.add_exp(50, "quest:quest_noctis_purify")
	if double_exp_ok:
		_fail("Bị lỗi nhận thưởng EXP trùng lặp trên quest đã COMPLETED!")
		world.queue_free()
		return
	var double_tutorial_ok := player.progression_component.add_exp(50, "quest:quest_tutorial")
	if double_tutorial_ok:
		_fail("Bị lỗi nhận thưởng EXP trùng lặp trên quest_tutorial!")
		world.queue_free()
		return
	print("[PASS] Test 7.4: Nạp Save COMPLETED tự động mở Cổng Ma Pháp & chống nhận thưởng trùng OK.")

	# 7.5 (P0): Legacy COMPLETED + Journal READY_TO_TURN_IN (reward_claimed = false)
	# Đảm bảo KHÔNG THỂ nhận thêm 50 vàng từ turn_in_quest và trạng thái phải là COMPLETED
	var fixture_75 := {
		"save_version": "2.0.0",
		"timestamp": 1700000005,
		"current_zone_id": "noctis_forest",
		"gold": 200,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 50,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 200,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 2, # READY_TO_TURN_IN
					"current_amount": 3,
					"reward_claimed": false,
					"counted_enemy_ids": ["noctis_wolf_1", "noctis_wolf_2", "noctis_wolf_3"]
				}
			},
			"legacy_quest": {
				"state": 3, # COMPLETED trong hệ cũ
				"current_amount": 3
			},
			"killed_enemy_ids": ["noctis_wolf_1", "noctis_wolf_2", "noctis_wolf_3"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_75))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.5!")
		world.queue_free()
		return

	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.COMPLETED:
		_fail("Test 7.5: Journal phải được chuyển sang COMPLETED khi Legacy đã COMPLETED!")
		world.queue_free()
		return
	if not journal.is_reward_claimed("quest_noctis_purify"):
		_fail("Test 7.5: reward_claimed phải là true khi Legacy đã COMPLETED!")
		world.queue_free()
		return
	if not gate.is_open:
		_fail("Test 7.5: Cổng Ma Pháp phải mở khi nhiệm vụ đã hoàn thành!")
		world.queue_free()
		return
	if journal.can_turn_in("quest_noctis_purify"):
		_fail("Test 7.5: can_turn_in() không được phép trả về true khi quest đã COMPLETED!")
		world.queue_free()
		return

	# Thử trả nhiệm vụ qua Journal -> Bắt buộc thất bại và không cộng thêm vàng
	var inv: InventoryComponent = player.get_node_or_null("InventoryComponent")
	var turn_in_res := journal.turn_in_quest("quest_noctis_purify", inv)
	if turn_in_res.get("success", false):
		_fail("Test 7.5: turn_in_quest() phải thất bại khi phần thưởng đã nhận trước đó!")
		world.queue_free()
		return
	if player.wallet_component.gold != 200:
		_fail("Test 7.5: Vàng bị tăng thêm sau khi cố trả nhiệm vụ đã hoàn thành! Hiện có: " + str(player.wallet_component.gold))
		world.queue_free()
		return
	print("[PASS] Test 7.5: Legacy COMPLETED + Journal READY chưa nhận thưởng -> Chống nhận thưởng trùng 100% OK.")

	# 7.6 (P1): Legacy ACTIVE 2/3 + Journal ACTIVE 1/3 (cùng state nhưng lệch tiến độ)
	var fixture_76 := {
		"save_version": "2.0.0",
		"timestamp": 1700000006,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 20,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 125,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 1, # ACTIVE
					"current_amount": 1,
					"reward_claimed": false,
					"counted_enemy_ids": ["noctis_wolf_1"]
				}
			},
			"legacy_quest": {
				"state": 1, # ACTIVE
				"current_amount": 2
			},
			"killed_enemy_ids": ["noctis_wolf_1", "noctis_wolf_2"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_76))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.6!")
		world.queue_free()
		return

	if journal.get_quest_progress("quest_noctis_purify") != 2 or journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE:
		_fail("Test 7.6: Tiến độ của Journal phải được nâng lên 2/3 theo tiến độ cao hơn!")
		world.queue_free()
		return
	if gate.is_open:
		_fail("Test 7.6: Cổng Ma Pháp phải đóng khi ACTIVE 2/3!")
		world.queue_free()
		return
	print("[PASS] Test 7.6: Legacy ACTIVE 2/3 + Journal ACTIVE 1/3 -> Đồng bộ chuẩn xác theo tiến độ cao nhất OK.")

	# 7.7 (P1): Legacy READY 3/3 + Journal ACTIVE 2/3 -> Nâng cả hai lên READY 3/3
	var fixture_77 := {
		"save_version": "2.0.0",
		"timestamp": 1700000007,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 30,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 125,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 1, # ACTIVE
					"current_amount": 2,
					"reward_claimed": false,
					"counted_enemy_ids": ["noctis_wolf_1", "noctis_wolf_2"]
				}
			},
			"legacy_quest": {
				"state": 2, # READY_TO_TURN_IN
				"current_amount": 3
			},
			"killed_enemy_ids": ["noctis_wolf_1", "noctis_wolf_2", "noctis_wolf_3"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_77))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.7!")
		world.queue_free()
		return

	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.READY_TO_TURN_IN or journal.get_quest_progress("quest_noctis_purify") != 3:
		_fail("Test 7.7: Journal phải đạt READY_TO_TURN_IN 3/3!")
		world.queue_free()
		return
	if gate.is_open:
		_fail("Test 7.7: Cổng Ma Pháp phải giữ khóa khi READY_TO_TURN_IN!")
		world.queue_free()
		return
	print("[PASS] Test 7.7: Legacy READY 3/3 + Journal ACTIVE 2/3 -> Không mất tiến trình, đồng bộ READY 3/3 OK.")

	# 7.8 (P1): Danh sách quái đã diệt chứa ID thật của Noctis Forest và quái khác loại (enemy_forest_1, enemy_forest_2, elyndra_mooncap_1)
	var fixture_78 := {
		"save_version": "2.0.0",
		"timestamp": 1700000008,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 40,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 125,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 1,
					"current_amount": 2,
					"reward_claimed": false,
					"counted_enemy_ids": ["enemy_forest_1", "enemy_forest_2"]
				}
			},
			"legacy_quest": {
				"state": 1,
				"current_amount": 2
			},
			"killed_enemy_ids": ["enemy_forest_1", "enemy_forest_2", "elyndra_mooncap_1"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_78))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.8!")
		world.queue_free()
		return

	if journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Test 7.8: Tiến trình quest sói phải là 2, nhận: " + str(journal.get_quest_progress("quest_noctis_purify")))
		world.queue_free()
		return
	var counted_78: Array = journal.get_quest_data("quest_noctis_purify").get("counted_enemy_ids", [])
	if counted_78.size() != 2:
		_fail("Test 7.8: Số lượng counted_enemy_ids phải bằng 2, nhận: " + str(counted_78.size()))
		world.queue_free()
		return
	if "elyndra_mooncap_1" in counted_78:
		_fail("Test 7.8: Quái mooncap không được lọt vào counted_enemy_ids của quest_noctis_purify!")
		world.queue_free()
		return
	if not ("elyndra_mooncap_1" in journal.get_kill_history("corrupted_mooncap")):
		_fail("Test 7.8: Quái mooncap phải được ghi nhận vào _kill_history['corrupted_mooncap']!")
		world.queue_free()
		return
	if not ("enemy_forest_1" in journal.get_kill_history("corrupted_wolf") and "enemy_forest_2" in journal.get_kill_history("corrupted_wolf")):
		_fail("Test 7.8: ID thật enemy_forest_1 và enemy_forest_2 phải được map vào _kill_history['corrupted_wolf']!")
		world.queue_free()
		return

	# Tạo mock Enemy sói thật (enemy_forest_3) để hoàn thành quest
	var mock_wolf := Enemy.new()
	mock_wolf.enemy_type_id = "corrupted_wolf"
	mock_wolf.enemy_id = "enemy_forest_3"
	journal.register_enemy_kill(mock_wolf)
	mock_wolf.free()

	if journal.get_quest_progress("quest_noctis_purify") != 3:
		_fail("Test 7.8: Sau khi diệt sói thứ 3 (enemy_forest_3), tiến trình phải là 3/3! Nhận: " + str(journal.get_quest_progress("quest_noctis_purify")))
		world.queue_free()
		return
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.READY_TO_TURN_IN:
		_fail("Test 7.8: Trạng thái quest phải là READY_TO_TURN_IN sau khi hoàn thành mục tiêu!")
		world.queue_free()
		return

	# Tạo mock Enemy mooncap để kiểm tra xem có làm lệch quest sói không
	var mock_mooncap := Enemy.new()
	mock_mooncap.enemy_type_id = "corrupted_mooncap"
	mock_mooncap.enemy_id = "elyndra_mooncap_2"
	journal.register_enemy_kill(mock_mooncap)
	mock_mooncap.free()

	if journal.get_quest_progress("quest_noctis_purify") != 3:
		_fail("Test 7.8: Diệt quái mooncap không được làm biến đổi số lượng của quest sói!")
		world.queue_free()
		return
	print("[PASS] Test 7.8: Ánh xạ ID thật noctis_forest (enemy_forest_1..3) & bóc tách quái chuẩn xác OK.")

	# 7.9 (P1): Quái có ID generic không xác định loại ("unknown_mob_99")
	# Bảo toàn số lượng tiến trình 2/3 nhưng KHÔNG được đưa vào _kill_history["corrupted_wolf"]
	var fixture_79 := {
		"save_version": "2.0.0",
		"timestamp": 1700000009,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 40,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 125,
			"quest_journal": {},
			"legacy_quest": {
				"state": 1,
				"current_amount": 2
			},
			"killed_enemy_ids": ["unknown_mob_99", "generic_creature_01"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_79))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.9!")
		world.queue_free()
		return

	if journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Test 7.9: Tiến trình quest phải bảo toàn là 2/3!")
		world.queue_free()
		return
	var wolf_history: Array = journal.get_kill_history("corrupted_wolf")
	if "unknown_mob_99" in wolf_history or "generic_creature_01" in wolf_history:
		_fail("Test 7.9: ID không rõ loại tuyệt đối không được đưa vào _kill_history['corrupted_wolf']!")
		world.queue_free()
		return
	print("[PASS] Test 7.9: ID không rõ loại bảo toàn tiến trình mà không làm sai lệch kill_history OK.")

	# 7.10 (P1): Reset trạng thái Quest khi load snapshot không đầy đủ (Save A -> Save B)
	# Save A có Side Quest quest_kaelis_cure COMPLETED và kill history mooncap
	var save_a_dict := {
		"save_version": "2.0.0",
		"timestamp": 1700000010,
		"current_zone_id": "noctis_forest",
		"gold": 100,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 50,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 100,
			"quest_journal": {
				"_kill_history": {
					"corrupted_mooncap": ["elyndra_mooncap_1", "elyndra_mooncap_2"]
				},
				"quest_kaelis_cure": {
					"state": 3, # COMPLETED
					"current_amount": 5,
					"reward_claimed": true,
					"counted_enemy_ids": []
				}
			}
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save_a_dict))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp Save A cho Test 7.10!")
		world.queue_free()
		return

	if journal.get_quest_state("quest_kaelis_cure") != QuestDefinition.State.COMPLETED:
		_fail("Test 7.10: Save A phải có quest_kaelis_cure COMPLETED!")
		world.queue_free()
		return
	if journal.get_kill_history("corrupted_mooncap").size() != 2:
		_fail("Test 7.10: Save A phải có 2 mooncap trong kill_history!")
		world.queue_free()
		return

	# Save B nạp tiếp trong cùng session: Chỉ có Main Quest, hoàn toàn không có quest_kaelis_cure hay _kill_history
	var save_b_dict := {
		"save_version": "2.0.0",
		"timestamp": 1700000011,
		"current_zone_id": "noctis_forest",
		"gold": 150,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 10,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 150,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 1, # ACTIVE
					"current_amount": 1,
					"reward_claimed": false,
					"counted_enemy_ids": ["enemy_forest_1"]
				}
			}
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save_b_dict))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp Save B cho Test 7.10!")
		world.queue_free()
		return

	# Kiểm tra dữ liệu của Save A KHÔNG ĐƯỢC RÒ RỈ sang Save B
	if journal.get_quest_state("quest_kaelis_cure") != QuestDefinition.State.NOT_STARTED:
		_fail("Test 7.10: quest_kaelis_cure từ Save A bị rò rỉ sang Save B! Nhận state: " + str(journal.get_quest_state("quest_kaelis_cure")))
		world.queue_free()
		return
	if not journal.get_kill_history("corrupted_mooncap").is_empty():
		_fail("Test 7.10: Lịch sử diệt mooncap từ Save A bị rò rỉ sang Save B!")
		world.queue_free()
		return
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE or journal.get_quest_progress("quest_noctis_purify") != 1:
		_fail("Test 7.10: Tiến độ Main Quest trong Save B không chuẩn xác!")
		world.queue_free()
		return
	print("[PASS] Test 7.10: Snapshot Isolation tuyệt đối (nạp Save A có Side Quest rồi nạp Save B chỉ có Main Quest, 0% rò rỉ dữ liệu) OK.")

	# 7.11 (P1): Legacy ACTIVE 2/3 nhưng killed_enemy_ids = []
	# Fallback tạo __legacy_credit_1..2: bảo toàn tiến trình 2/3 nhưng KHÔNG tạo Wolf kill history giả!
	var fixture_711 := {
		"save_version": "1.5.0",
		"timestamp": 1700000012,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player": {
			"race_id": "human",
			"current_health": 80.0,
			"current_mana": 40.0,
			"progression": {
				"level": 2,
				"current_exp": 40,
				"claimed_exp_sources": []
			}
		},
		"quest": {
			"state": 1, # ACTIVE
			"current_amount": 2
		},
		"defeated_enemy_ids": [] # Rỗng
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_711))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.11!")
		world.queue_free()
		return

	if journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Test 7.11: Tiến trình quest sói phải được bảo toàn là 2/3 khi killed_enemy_ids rỗng!")
		world.queue_free()
		return
	var counted_711: Array = journal.get_quest_data("quest_noctis_purify").get("counted_enemy_ids", [])
	if counted_711.size() != 2:
		_fail("Test 7.11: counted_enemy_ids phải chứa 2 credit fallback!")
		world.queue_free()
		return
	if not ("__legacy_credit_1" in counted_711 and "__legacy_credit_2" in counted_711):
		_fail("Test 7.11: counted_enemy_ids phải dùng prefix '__legacy_credit_' thay vì tên quái giả!")
		world.queue_free()
		return
	var wolf_history_711: Array = journal.get_kill_history("corrupted_wolf")
	if not wolf_history_711.is_empty():
		_fail("Test 7.11: Credit giả không được phép xuất hiện trong _kill_history['corrupted_wolf']! Nhận: " + str(wolf_history_711))
		world.queue_free()
		return

	# Tiêu diệt thêm 1 sói thật trong game (enemy_forest_3)
	var mock_wolf_real := Enemy.new()
	mock_wolf_real.enemy_type_id = "corrupted_wolf"
	mock_wolf_real.enemy_id = "enemy_forest_3"
	journal.register_enemy_kill(mock_wolf_real)
	mock_wolf_real.free()

	if journal.get_quest_progress("quest_noctis_purify") != 3:
		_fail("Test 7.11: Sau khi diệt sói thật thứ 3, tiến trình phải tăng đúng lên 3/3!")
		world.queue_free()
		return
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.READY_TO_TURN_IN:
		_fail("Test 7.11: Quest phải chuyển sang READY_TO_TURN_IN sau khi hoàn thành 3/3!")
		world.queue_free()
		return
	wolf_history_711 = journal.get_kill_history("corrupted_wolf")
	if wolf_history_711 != ["enemy_forest_3"]:
		_fail("Test 7.11: _kill_history['corrupted_wolf'] chỉ được chứa sói thật 'enemy_forest_3'! Nhận: " + str(wolf_history_711))
		world.queue_free()
		return
	print("[PASS] Test 7.11: Fallback credit (__legacy_credit_) bảo toàn 2/3, 0% sói giả trong kill_history và tăng đúng 3/3 khi diệt sói thật OK.")

	# 7.12 (P1): Tương thích ngược với save trung gian chứa 'legacy_wolf_1' + Idempotency
	# Đảm bảo 'legacy_wolf_' cũ không bị biến thành Wolf thật trong kill_history qua chu kỳ Save/Load
	var fixture_712 := {
		"save_version": "2.0.0",
		"timestamp": 1700000013,
		"current_zone_id": "noctis_forest",
		"gold": 125,
		"player_state": {
			"race_id": "human",
			"level": 2,
			"current_exp": 40,
			"claimed_exp_sources": [],
			"current_health": 80.0,
			"current_mana": 40.0,
			"gold": 125,
			"quest_journal": {
				"quest_noctis_purify": {
					"state": 1,
					"current_amount": 2,
					"reward_claimed": false,
					"counted_enemy_ids": ["legacy_wolf_1", "legacy_wolf_2"]
				}
			},
			"legacy_quest": {
				"state": 1,
				"current_amount": 2
			},
			"killed_enemy_ids": ["legacy_wolf_1", "legacy_wolf_2"]
		}
	}
	f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fixture_712))
	f.close()

	if not SaveManager.load_game(world):
		_fail("Không thể nạp fixture 7.12!")
		world.queue_free()
		return

	# Lần 1: Lưu -> Tải lại
	if not SaveManager.save_game(world) or not SaveManager.load_game(world):
		_fail("Test 7.12: Chu kỳ Save -> Load lần 1 thất bại!")
		world.queue_free()
		return
	# Lần 2: Lưu -> Tải lại lần nữa
	if not SaveManager.save_game(world) or not SaveManager.load_game(world):
		_fail("Test 7.12: Chu kỳ Save -> Load lần 2 thất bại!")
		world.queue_free()
		return

	if journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Test 7.12: Tiến trình 2/3 bị biến dạng sau chu kỳ Save/Load!")
		world.queue_free()
		return
	var wolf_history_712: Array = journal.get_kill_history("corrupted_wolf")
	if "legacy_wolf_1" in wolf_history_712 or "legacy_wolf_2" in wolf_history_712:
		_fail("Test 7.12: legacy_wolf_ cũ không được phép bị biến thành Wolf thật trong _kill_history!")
		world.queue_free()
		return
	if gate.is_open:
		_fail("Test 7.12: Cổng Ma Pháp phải giữ khóa khi quest đang ACTIVE 2/3!")
		world.queue_free()
		return
	if player.wallet_component.gold != 125:
		_fail("Test 7.12: Vàng bị biến dạng sau chu kỳ Save/Load!")
		world.queue_free()
		return
	print("[PASS] Test 7.12: Khử nhận nhầm 'legacy_wolf_' cũ thành Wolf thật & bảo toàn Idempotent tuyệt đối OK.")

	# --- TEST 8: TÍNH TOÀN VẸN VÀ IDEMPOTENT CỦA SAVE v2.0.0 (Save -> Load -> Save -> Load) ---
	journal.reconcile_quest_state("quest_noctis_purify", QuestDefinition.State.ACTIVE, 2, false)
	player.wallet_component.set_gold(125)

	# Lần 1: Lưu -> Tải
	if not SaveManager.save_game(world) or not SaveManager.load_game(world):
		_fail("Lưu/Tải lần 1 thất bại!")
		world.queue_free()
		return
	# Lần 2: Lưu -> Tải lại lần nữa
	if not SaveManager.save_game(world) or not SaveManager.load_game(world):
		_fail("Lưu/Tải lần 2 thất bại!")
		world.queue_free()
		return

	if player.wallet_component.gold != 125:
		_fail("Dữ liệu vàng bị biến dạng sau 2 chu kỳ Lưu/Nạp!")
		world.queue_free()
		return
	if journal.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE or journal.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Journal quest_noctis_purify bị biến dạng sau 2 chu kỳ Lưu/Nạp!")
		world.queue_free()
		return
	print("[PASS] Test 8: Chu trình Idempotent (Save -> Load -> Save -> Load) bảo toàn dữ liệu hoàn hảo.")

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
	var journal_a := player_a.quest_journal_component
	player_a.wallet_component.set_gold(50)
	journal_a.reconcile_quest_state("quest_noctis_purify", QuestDefinition.State.ACTIVE, 2, false)

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
	var ui_a2 := world_a2.get_node_or_null("GameUI") as GameUI
	var journal_a2 := player_a2.quest_journal_component

	if player_a2.wallet_component.gold != 125:
		_fail("Chuyển từ Vùng B về lại Vùng A mất vàng! Kỳ vọng 125, nhận %d" % player_a2.wallet_component.gold)
		world_a2.queue_free()
		return
	if journal_a2.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE or journal_a2.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Journal quest_noctis_purify bị mất tiến trình sau khi chuyển vùng về Vùng A!")
		world_a2.queue_free()
		return

	# Kiểm tra bắt buộc: FAIL nếu GameUI hoặc GoldLabel null
	if ui_a2 == null:
		_fail("GameUI không tồn tại ở Vùng A sau khi chuyển vùng về!")
		world_a2.queue_free()
		return
	var gold_label_a2 := ui_a2.gold_label
	if gold_label_a2 == null:
		_fail("GoldLabel không tồn tại trong GameUI ở Vùng A!")
		world_a2.queue_free()
		return
	if gold_label_a2.text != "Vàng: 125 G" or ui_a2._current_gold != 125:
		_fail("HUD không tự động hiển thị đúng 125 vàng qua signal! Mong đợi 'Vàng: 125 G', nhận '%s'" % gold_label_a2.text)
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
	var ui_a3 := world_a3.get_node_or_null("GameUI") as GameUI
	var journal_a3 := player_a3.quest_journal_component

	if player_a3.wallet_component.gold != 125:
		_fail("Nạp bản lưu sau chuỗi chuyển vùng bị sai số vàng! Wallet: %d" % player_a3.wallet_component.gold)
		world_a3.queue_free()
		return
	if journal_a3.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE or journal_a3.get_quest_progress("quest_noctis_purify") != 2:
		_fail("Nạp bản lưu sau chuỗi chuyển vùng bị sai tiến trình quest!")
		world_a3.queue_free()
		return

	# Kiểm tra bắt buộc GameUI & GoldLabel trên instance mới
	if ui_a3 == null:
		_fail("GameUI không tồn tại trên world mới sau khi load save!")
		world_a3.queue_free()
		return
	var gold_label_a3 := ui_a3.gold_label
	if gold_label_a3 == null:
		_fail("GoldLabel không tồn tại trong GameUI sau khi load save!")
		world_a3.queue_free()
		return
	if gold_label_a3.text != "Vàng: 125 G" or ui_a3._current_gold != 125:
		_fail("HUD hiển thị sai sau khi nạp save! Kỳ vọng 'Vàng: 125 G', nhận '%s'" % gold_label_a3.text)
		world_a3.queue_free()
		return

	world_a3.queue_free()
	await process_frame
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	print("[PASS] Test 9: Chuyển vùng A -> B -> A, tích lũy vàng liên vùng và Save/Load thành công 100%.")

	# --- TEST 10: COMMIT A GAMEPLAY INTEGRATION (EIRAN -> QUÝT -> MAGIC GATE -> REWARD) ---
	var world_flow := forest_scene.instantiate()
	root.add_child(world_flow)
	await process_frame
	await process_frame

	var player_flow := world_flow.get_node_or_null("Player") as Player
	var eiran_flow := world_flow.get_node_or_null("NPC_Elyra") as NPC
	var gate_flow := world_flow.get_node_or_null("MagicGate") as MagicGate
	var journal_flow := player_flow.quest_journal_component

	if eiran_flow == null:
		_fail("Test 10: Không tìm thấy NPC Eiran (NPC_Elyra) trong Noctis Forest!")
		world_flow.queue_free()
		return

	# 10.1: Kiểm tra quest_id của Eiran đã được gán sang quest_noctis_purify
	if eiran_flow.quest_id != "quest_noctis_purify":
		_fail("Test 10: Eiran phải liên kết với quest_noctis_purify, nhận: " + eiran_flow.quest_id)
		world_flow.queue_free()
		return

	# 10.2: Tương tác với Eiran khi NOT_STARTED -> kiểm tra lời thoại gốc chính xác
	var interact_offer := eiran_flow._get_catalog_quest_interaction(player_flow)
	var offer_lines: Array = interact_offer.get("lines", [])
	if offer_lines.is_empty() or not offer_lines[0].begins_with("Mừng con đã trở về Tổ Ấm Đèn Nguyệt"):
		_fail("Test 10: Lời thoại nhận nhiệm vụ của Eiran không khớp bản gốc! Nhận: " + str(offer_lines))
		world_flow.queue_free()
		return
	if interact_offer.get("action") != "start_quest:quest_noctis_purify":
		_fail("Test 10: Action nhận nhiệm vụ phải là start_quest:quest_noctis_purify, nhận: " + str(interact_offer.get("action")))
		world_flow.queue_free()
		return

	# 10.2b: Kiểm tra quái bị diệt TRƯỚC khi nhận quest KHÔNG được tính vào Main Quest (bảo toàn gameplay cũ)
	var early_wolf_scene := preload("res://src/actors/enemy/enemy.tscn")
	var early_wolf: Enemy = early_wolf_scene.instantiate()
	early_wolf.enemy_type_id = "corrupted_wolf"
	early_wolf.enemy_id = "enemy_forest_early"
	world_flow.add_child(early_wolf)
	early_wolf.enemy_defeated.connect(journal_flow.register_enemy_kill)
	early_wolf.enemy_defeated.emit(early_wolf)
	early_wolf.queue_free()
	await process_frame

	# 10.3: Nhận nhiệm vụ qua QuestActionService
	var act_start_res := QuestActionService.execute(str(interact_offer.get("action")), world_flow)
	if not act_start_res.get("success", false):
		_fail("Test 10: Nhận quest_noctis_purify qua QuestActionService thất bại!")
		world_flow.queue_free()
		return
	if journal_flow.get_quest_state("quest_noctis_purify") != QuestDefinition.State.ACTIVE:
		_fail("Test 10: Nhiệm vụ phải ở trạng thái ACTIVE sau khi nhận!")
		world_flow.queue_free()
		return
	if journal_flow.get_quest_progress("quest_noctis_purify") != 0:
		_fail("Test 10: Quái diệt trước khi nhận quest tuyệt đối không được tính vào Main Quest! Nhận: " + str(journal_flow.get_quest_progress("quest_noctis_purify")))
		world_flow.queue_free()
		return
	if gate_flow.is_open:
		_fail("Test 10: Cổng Ma Pháp phải đóng khi mới nhận nhiệm vụ!")
		world_flow.queue_free()
		return

	# 10.4: Tiêu diệt 3 quái sói thật qua pipeline signal thực tế và kiểm tra HUD cập nhật từng mốc
	var game_ui_flow := world_flow.get_node_or_null("GameUI") as GameUI
	if game_ui_flow == null:
		_fail("Test 10: GameUI không tồn tại trong world_flow!")
		world_flow.queue_free()
		return
	if game_ui_flow.quest_progress_label == null:
		_fail("Test 10: quest_progress_label trong GameUI không tồn tại!")
		world_flow.queue_free()
		return

	var scene_wolves := [
		world_flow.get_node_or_null("CorruptedEnemy1") as Enemy,
		world_flow.get_node_or_null("CorruptedEnemy2") as Enemy,
		world_flow.get_node_or_null("CorruptedEnemy3") as Enemy
	]

	for w_idx in [1, 2, 3]:
		var wolf_enemy: Enemy = scene_wolves[w_idx - 1]
		if wolf_enemy == null:
			_fail("Test 10: CorruptedEnemy%d không tồn tại trong scene!" % w_idx)
			world_flow.queue_free()
			return

		# Phát tín hiệu enemy_defeated từ chính đối tượng quái qua signal pipeline thực tế
		wolf_enemy.enemy_defeated.emit(wolf_enemy)
		await process_frame

		if journal_flow.get_quest_progress("quest_noctis_purify") != w_idx:
			_fail("Test 10: Tiến độ sau khi diệt quái %d phải bằng %d! Nhận: %d" % [w_idx, w_idx, journal_flow.get_quest_progress("quest_noctis_purify")])
			world_flow.queue_free()
			return

		# Kiểm tra HUD nhiệm vụ hiển thị chuẩn xác từng mốc (bắt buộc node tồn tại, FAIL nếu sai)
		if w_idx == 1:
			if game_ui_flow.quest_progress_label.text != "Tiêu diệt sinh vật: 1/3":
				_fail("Test 10: HUD hiển thị sai ở mốc 1/3! Nhận: " + game_ui_flow.quest_progress_label.text)
				world_flow.queue_free()
				return
		elif w_idx == 2:
			if game_ui_flow.quest_progress_label.text != "Tiêu diệt sinh vật: 2/3":
				_fail("Test 10: HUD hiển thị sai ở mốc 2/3! Nhận: " + game_ui_flow.quest_progress_label.text)
				world_flow.queue_free()
				return
		elif w_idx == 3:
			if game_ui_flow.quest_progress_label.text != "Tiến độ: 3/3 (Về gặp Eiran nhận thưởng!)":
				_fail("Test 10: HUD hiển thị sai ở mốc 3/3! Nhận: " + game_ui_flow.quest_progress_label.text)
				world_flow.queue_free()
				return

	if journal_flow.get_quest_state("quest_noctis_purify") != QuestDefinition.State.READY_TO_TURN_IN:
		_fail("Test 10: Nhiệm vụ phải đạt READY_TO_TURN_IN sau khi đủ 3 quái!")
		world_flow.queue_free()
		return
	if gate_flow.is_open:
		_fail("Test 10: Cổng Ma Pháp phải giữ khóa khi chưa trả nhiệm vụ!")
		world_flow.queue_free()
		return

	# 10.5: Tương tác với Eiran khi READY_TO_TURN_IN -> kiểm tra lời thoại gốc chính xác
	var interact_ready := eiran_flow._get_catalog_quest_interaction(player_flow)
	var ready_lines: Array = interact_ready.get("lines", [])
	if ready_lines.is_empty() or not ready_lines[0].begins_with("Con đã trở về an toàn rồi! Mầm và Lumi"):
		_fail("Test 10: Lời thoại trả nhiệm vụ của Eiran không khớp bản gốc! Nhận: " + str(ready_lines))
		world_flow.queue_free()
		return
	if interact_ready.get("action") != "complete_quest:quest_noctis_purify":
		_fail("Test 10: Action trả nhiệm vụ phải là complete_quest:quest_noctis_purify, nhận: " + str(interact_ready.get("action")))
		world_flow.queue_free()
		return

	# Giả lập thương tích để kiểm tra hồi máu / mana
	player_flow.health_component.current_health = 10.0
	player_flow.health_component.current_mana = 5.0
	var gold_before: int = player_flow.wallet_component.gold
	var exp_before: int = player_flow.progression_component.current_exp

	# 10.6: Trả nhiệm vụ qua QuestActionService
	var act_complete_res := QuestActionService.execute(str(interact_ready.get("action")), world_flow)
	if not act_complete_res.get("success", false):
		_fail("Test 10: Trả quest_noctis_purify qua QuestActionService thất bại!")
		world_flow.queue_free()
		return

	# Kiểm tra phần thưởng: +50 Vàng, +50 EXP, 100% HP & MP
	if player_flow.wallet_component.gold != gold_before + 50:
		_fail("Test 10: Trả nhiệm vụ phải cộng đúng 50 Vàng! Trước: %d, Sau: %d" % [gold_before, player_flow.wallet_component.gold])
		world_flow.queue_free()
		return
	if player_flow.progression_component.current_exp != exp_before + 50:
		_fail("Test 10: Trả nhiệm vụ phải cộng đúng 50 EXP!")
		world_flow.queue_free()
		return
	if not is_equal_approx(player_flow.health_component.current_health, player_flow.health_component.max_health):
		_fail("Test 10: Trả nhiệm vụ phải hồi 100% HP!")
		world_flow.queue_free()
		return
	if not is_equal_approx(player_flow.health_component.current_mana, player_flow.health_component.max_mana):
		_fail("Test 10: Trả nhiệm vụ phải hồi 100% MP!")
		world_flow.queue_free()
		return

	# 10.7: Cổng Ma Pháp phải TỰ ĐỘNG MỞ sau khi hoàn thành nhiệm vụ
	if not gate_flow.is_open:
		_fail("Test 10: Cổng Ma Pháp PHẢI MỞ sau khi trả nhiệm vụ thanh tẩy cho Eiran!")
		world_flow.queue_free()
		return

	# 10.8: Thử trả lại một lần nữa -> Bắt buộc bị từ chối
	var double_turn_in := QuestActionService.execute(str(interact_ready.get("action")), world_flow)
	if double_turn_in.get("success", false):
		_fail("Test 10: Không được phép trả nhiệm vụ lần thứ 2!")
		world_flow.queue_free()
		return
	if player_flow.wallet_component.gold != gold_before + 50:
		_fail("Test 10: Vàng bị tăng thêm sau khi cố trả lại nhiệm vụ!")
		world_flow.queue_free()
		return

	world_flow.queue_free()
	await process_frame
	print("[PASS] Test 10: Gameplay Luồng Eiran -> Diệt Sói -> Trả Thưởng (+50 Vàng/EXP, Hồi Full HP/MP) -> Mở Cổng Ma Pháp hoàn tất 100%.")

	print("ALL_STAGE_2_STEP_4A_TESTS_PASS_SUCCESSFULLY")
	quit(0)

func _fail(msg: String) -> void:
	push_error("LỖI TEST GIAI ĐOẠN 2 BƯỚC 3: " + msg)
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	quit(1)

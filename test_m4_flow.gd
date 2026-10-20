extends SceneTree

# test_m4_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M4: First Boss Encounter (Lunareth).
# 1. Boss not active before completing Elyra quest.
# 2. Magic Gate physically blocks player.
# 3. Completing quest unlocks gate.
# 4. Boss activates when entering arena (boundary locks).
# 5. Boss HP reduces from J (melee) and K (spell).
# 6. Telegraph appears before attacks (Charge >= 0.6s, Shockwave >= 0.8s).
# 7. No unintended multi-hit in single attack.
# 8. Phase 2 activates at HP <= 160 threshold.
# 9. Phase 2 activates only once.
# 10. Player death & Retry resets Boss accurately without duplicates.
# 11. Boss purified grants exactly 100 Gold + eclipse_fragment.
# 12. Save/Continue preserves Boss state, no reward duplication.
# 13. Full inventory drops reward as pickup on ground.
# 14. Old M3.2 save files (v1.0.0) load with backward compatibility.
# 15. Regression check for core M0-M3.2 features.

const BossLunarethScript = preload("res://src/boss/boss_lunareth.gd")
const MagicGateScript = preload("res://src/world/magic_gate.gd")

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m4_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M4] BOSS ENCOUNTER TEST SUITE STARTING")
	print("==================================================")
	call_deferred("_run_suite")

func _assert(condition: bool, test_name: String, details: String = "") -> void:
	tests_run += 1
	if condition:
		print("  [PASS] %s" % test_name)
	else:
		failures += 1
		print("  [FAIL] %s - Details: %s" % [test_name, details])

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _run_suite() -> void:
	ItemDatabase.initialize()

	# GHI NHẬN CHỈ ĐỌC TRẠNG THÁI FILE SAVE THẬT - TUYỆT ĐỐI KHÔNG GHI/XÓA/SỬA
	real_file_existed_at_start = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		real_file_hash_at_start = FileAccess.get_md5(REAL_SAVE_PATH)

	# Định tuyến sang file test M4 riêng biệt
	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

	var world_scene: PackedScene = load("res://src/world/noctis_forest.tscn")
	if not world_scene:
		print("FATAL: Could not load noctis_forest.tscn")
		quit(1)
		return

	var world: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world)
	current_scene = world
	await _wait_seconds(0.3)

	var player: Player = world.player
	var quest_mgr: QuestManager = world.quest_manager
	var boss: CharacterBody2D = world.boss_lunareth
	var gate: StaticBody2D = world.magic_gate
	var barrier: StaticBody2D = world.arena_barrier
	var ui: GameUI = world.game_ui

	# -------------------------------------------------------------
	# TEST 1: Boss không kích hoạt trước khi hoàn thành nhiệm vụ Elyra
	# -------------------------------------------------------------
	print("\n--- TEST 1: Boss không kích hoạt trước khi hoàn thành nhiệm vụ Elyra ---")
	_assert(quest_mgr.current_quest.current_state != QuestData.State.COMPLETED, "Nhiệm vụ Elyra ban đầu chưa hoàn thành")
	_assert(boss != null and boss.current_state == BossLunarethScript.State.DORMANT, "Boss Lunareth ban đầu ở trạng thái DORMANT (chưa kích hoạt)")
	_assert(world.boss_battle_started == false, "Trận chiến Boss chưa bắt đầu")

	# -------------------------------------------------------------
	# TEST 2: Cổng khóa thực sự chặn Player
	# -------------------------------------------------------------
	print("\n--- TEST 2: Cổng khóa thực sự chặn Player (Physics & Gate Locked) ---")
	_assert(gate != null and gate.is_open == false, "Cổng Ma Pháp đang ở trạng thái KHÓA")
	var gate_col: CollisionShape2D = gate.get_node_or_null("CollisionShape2D")
	_assert(gate_col != null and gate_col.disabled == false, "Va chạm vật lý của Cổng Ma Pháp đang BẬT (chặn hoàn toàn)")

	# -------------------------------------------------------------
	# TEST 3: Hoàn thành nhiệm vụ mở cổng
	# -------------------------------------------------------------
	print("\n--- TEST 3: Hoàn thành nhiệm vụ Elyra mở khóa Cổng Ma Pháp ---")
	quest_mgr.current_quest.current_state = QuestData.State.COMPLETED
	gate.update_quest_status(quest_mgr.current_quest)
	_assert(gate.is_open == true, "Cổng Ma Pháp đã chuyển sang trạng thái MỞ sau khi hoàn thành nhiệm vụ")
	_assert(gate_col.disabled == true, "Va chạm vật lý của Cổng Ma Pháp đã TẮT (cho phép đi qua)")

	# -------------------------------------------------------------
	# TEST 4: Boss kích hoạt khi Player vào đấu trường & Rào chắn kích hoạt
	# -------------------------------------------------------------
	print("\n--- TEST 4: Boss kích hoạt khi Player vào đấu trường (Arena Boundary Locks) ---")
	# Giả lập Player bước qua vạch kích hoạt đấu trường
	player.global_position = Vector2(4450.0, 630.0)
	world._on_arena_trigger_entered(player)

	_assert(world.boss_battle_started == true, "Cờ boss_battle_started được bật")
	_assert(boss.current_state == BossLunarethScript.State.INTRO or boss.current_state == BossLunarethScript.State.APPROACH, "Boss chuyển sang trạng thái INTRO/APPROACH")
	_assert(barrier.visible == true, "Rào chắn đấu trường (Arena Barrier) đã hiển thị")
	var barrier_col: CollisionShape2D = barrier.get_node_or_null("CollisionShape2D")
	_assert(barrier_col != null and barrier_col.disabled == false, "Rào chắn đấu trường đã BẬT va chạm (khóa chặt người chơi trong đấu trường)")
	_assert(ui.boss_hud.visible == true, "HUD Boss hiển thị trên màn hình")

	# -------------------------------------------------------------
	# TEST 5: HP Boss giảm đúng khi nhận sát thương từ J/K
	# -------------------------------------------------------------
	print("\n--- TEST 5: HP Boss giảm đúng khi nhận sát thương từ J (Melee) & K (Magic) ---")
	var initial_hp: float = boss.health_component.current_health
	_assert(initial_hp == 320.0, "HP ban đầu của Boss là 320.0")

	# Giả lập đòn chém cận chiến J (sát thương cơ bản 25.0)
	var melee_dmg := DamageInfo.new(25.0, player, Vector2.RIGHT, 100.0)
	boss.hurtbox.apply_damage(melee_dmg)
	_assert(boss.health_component.current_health == 295.0, "HP Boss giảm chính xác còn 295.0 (-25) sau đòn chém thường J")

	# Chờ hết thời gian miễn nhiễm đòn ngắn
	await _wait_seconds(0.2)

	# Giả lập đòn bắn ma pháp K (sát thương 30.0)
	var spell_dmg := DamageInfo.new(30.0, player, Vector2.RIGHT, 150.0)
	boss.hurtbox.apply_damage(spell_dmg)
	_assert(boss.health_component.current_health == 265.0, "HP Boss giảm chính xác còn 265.0 (-30) sau đòn ma pháp K")

	# -------------------------------------------------------------
	# TEST 6: Telegraph xuất hiện trước khi đòn đánh gây sát thương
	# -------------------------------------------------------------
	print("\n--- TEST 6: Telegraph xuất hiện trước đòn đánh (Charge >= 0.6s, Shockwave >= 0.8s) ---")
	# Kiểm tra Telegraph đòn 1: Nguyệt Giác Xung Kích
	boss.current_attack = BossLunarethScript.AttackType.HORN_CHARGE
	boss._change_state(BossLunarethScript.State.TELEGRAPH)
	_assert(boss._state_timer >= 0.6, "Thời gian cảnh báo đòn Húc đạt tối thiểu 0.6s (thực tế: %.2fs)" % boss._state_timer)
	_assert(boss.charge_hitbox.monitoring == false, "Hitbox gây sát thương TẮT trong thời gian Telegraph (chưa gây sát thương)")
	_assert(boss.boss_visual.telegraph_charge_rect.visible == true, "Vùng nguy hiểm màu đỏ hiển thị rõ ràng trên mặt đất")

	# Kiểm tra Telegraph đòn 2: Hắc Nguyệt Chấn Ba
	boss.current_attack = BossLunarethScript.AttackType.MOON_SHOCKWAVE
	boss._change_state(BossLunarethScript.State.TELEGRAPH)
	_assert(boss._state_timer >= 0.8, "Thời gian cảnh báo đòn Chấn Ba đạt tối thiểu 0.8s (thực tế: %.2fs)" % boss._state_timer)
	_assert(boss.boss_visual.telegraph_shockwave_ring.visible == true, "Vòng ma pháp cảnh báo dưới chân hiển thị")

	# -------------------------------------------------------------
	# TEST 7: Một đòn không gây trùng sát thương ngoài thiết kế
	# -------------------------------------------------------------
	print("\n--- TEST 7: Một đòn không gây trùng sát thương ngoài thiết kế ---")
	boss._change_state(BossLunarethScript.State.ATTACK)
	boss.charge_hitbox.reset_hits()
	# Giả lập va chạm với Player Hurtbox 2 lần liên tiếp trong cùng một đòn
	boss.charge_hitbox._on_area_entered(player.hurtbox)
	var hp_after_hit1: float = player.health_component.current_health
	boss.charge_hitbox._on_area_entered(player.hurtbox) # Lần thứ 2
	var hp_after_hit2: float = player.health_component.current_health
	_assert(hp_after_hit1 == hp_after_hit2, "Cơ chế chống đòn trùng: Player không bị mất máu lần 2 trong cùng 1 lượt húc")

	# -------------------------------------------------------------
	# TEST 8: Giai đoạn 2 (Phase 2) kích hoạt đúng tại ngưỡng HP <= 160
	# -------------------------------------------------------------
	print("\n--- TEST 8: Giai đoạn 2 kích hoạt chính xác tại ngưỡng HP <= 160 (50% HP) ---")
	_assert(boss.is_phase_2 == false, "Trước khi giảm HP, Boss đang ở Phase 1")
	# Gây sát thương đưa HP về 160.0
	boss.health_component.current_health = 160.0
	boss.health_component.emit_signal("health_changed", 160.0, 320.0)

	_assert(boss.is_phase_2 == true, "Boss kích hoạt Phase 2 thành công")
	_assert(boss.current_state == BossLunarethScript.State.PHASE_TRANSITION, "Boss chuyển sang trạng thái PHASE_TRANSITION")
	_assert(boss.boss_visual.is_phase_2 == true, "Visual chuyển sang tông màu tím Hắc Nguyệt rực rỡ")
	_assert(boss.recovery_time_p2 < boss.recovery_time_p1, "Thời gian hồi đòn Phase 2 giảm (1.4s -> 1.1s, giảm ~21%)")

	# -------------------------------------------------------------
	# TEST 9: Phase 2 chỉ kích hoạt đúng một lần duy nhất
	# -------------------------------------------------------------
	print("\n--- TEST 9: Phase 2 chỉ kích hoạt đúng một lần duy nhất ---")
	boss._change_state(BossLunarethScript.State.RECOVERY)
	# Tiếp tục giảm HP xuống 120.0
	boss.health_component.current_health = 120.0
	boss.health_component.emit_signal("health_changed", 120.0, 320.0)
	_assert(boss.current_state == BossLunarethScript.State.RECOVERY, "Không bị kích hoạt lại PHASE_TRANSITION khi HP tiếp tục giảm")

	# -------------------------------------------------------------
	# TEST 10: Player tử trận và Retry -> Reset Boss chính xác
	# -------------------------------------------------------------
	print("\n--- TEST 10: Player tử trận và Retry -> Reset Boss chính xác (Không tạo duplicate) ---")
	# Giả lập Player chết
	player.health_component.current_health = 0.0
	player.health_component.emit_signal("died")

	# Gọi hàm Retry
	world._on_retry_requested()

	_assert(player.global_position == world.arena_checkpoint, "Player được đưa về checkpoint ngoài cổng đấu trường (4120, 630)")
	_assert(player.health_component.current_health == player.health_component.max_health, "HP Player được hồi đầy")
	_assert(boss.health_component.current_health == 320.0, "HP Boss được reset đầy đủ 320/320")
	_assert(boss.is_phase_2 == false, "Boss trở về Phase 1")
	_assert(boss.current_state == BossLunarethScript.State.DORMANT, "Boss trở về trạng thái DORMANT")
	_assert(barrier_col.disabled == true, "Rào chắn đấu trường được mở khóa an toàn sau khi Retry")
	var boss_count: int = 0
	for child in world.get_children():
		if child is BossLunarethScript:
			boss_count += 1
	_assert(boss_count == 1, "Chỉ duy nhất 1 thực thể Boss tồn tại (không sinh bản sao)")

	# -------------------------------------------------------------
	# TEST 11: Boss bị thanh tẩy -> Nhận đúng 100 Vàng + Mảnh Nguyệt Thực
	# -------------------------------------------------------------
	print("\n--- TEST 11: Boss bị thanh tẩy -> Nhận đúng 100 Vàng + Mảnh Nguyệt Thực (eclipse_fragment) ---")
	var gold_before: int = quest_mgr.gold
	player.inventory_component._initialize_slots()
	_assert(player.inventory_component.has_item("eclipse_fragment") == false, "Túi đồ ban đầu chưa có Mảnh Nguyệt Thực")

	# Kích hoạt lại Boss và tiêu diệt
	world.start_boss_battle()
	boss.health_component.current_health = 0.0
	boss.health_component.emit_signal("died")

	_assert(boss.current_state == BossLunarethScript.State.DEFEATED, "Boss chuyển sang trạng thái DEFEATED")
	_assert(boss.charge_hitbox.monitoring == false, "Hitbox tấn công của Boss bị tắt hoàn toàn ngay khi chết")
	_assert(boss.hurtbox.monitoring == false, "Hurtbox nhận đòn của Boss bị tắt hoàn toàn")
	_assert(quest_mgr.gold == gold_before + 100, "Nhận chính xác 100 Vàng thưởng (%d -> %d)" % [gold_before, quest_mgr.gold])
	_assert(player.inventory_component.has_item("eclipse_fragment") == true, "Player nhận được Mảnh Nguyệt Thực vào túi đồ")
	_assert(ui.victory_panel.visible == true, "Màn hình Victory 'THANH TẨY THÀNH CÔNG' hiển thị")
	_assert(barrier_col.disabled == true, "Rào chắn đấu trường mở khóa cho phép di chuyển tự do")

	# -------------------------------------------------------------
	# TEST 12: Save/Continue giữ trạng thái Boss & Không nhân đôi phần thưởng
	# -------------------------------------------------------------
	print("\n--- TEST 12: Save/Continue giữ trạng thái Boss & Không nhân đôi phần thưởng ---")
	var saved_gold: int = quest_mgr.gold
	SaveManager.save_game(world)

	world.queue_free()
	await process_frame

	var world2: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world2)
	current_scene = world2
	await _wait_seconds(0.2)

	SaveManager.load_game(world2)

	var boss2: CharacterBody2D = world2.boss_lunareth
	_assert(world2.boss_defeated == true, "Trạng thái Boss đã thanh tẩy được lưu và nạp thành công")
	_assert(boss2.current_state == BossLunarethScript.State.DEFEATED, "Boss trong World mới ở trạng thái DEFEATED (không hồi sinh lại)")
	_assert(world2.quest_manager.gold == saved_gold, "Số Vàng giữ nguyên đúng %d G" % saved_gold)
	_assert(world2.player.inventory_component.get_item_count("eclipse_fragment") == 1, "Mảnh Nguyệt Thực giữ đúng 1 mảnh (không bị nhân đôi)")

	# Thử gọi lại hàm trả thưởng xem có bị phát trùng không
	world2.grant_boss_reward()
	_assert(world2.quest_manager.gold == saved_gold, "Cơ chế chống nhận thưởng lặp: Vàng không bị tăng lần 2")
	_assert(world2.player.inventory_component.get_item_count("eclipse_fragment") == 1, "Vật phẩm không bị trao lần 2")

	# -------------------------------------------------------------
	# TEST 13: Túi đồ đầy -> Vật phẩm thưởng rơi thành Pickup không bị mất
	# -------------------------------------------------------------
	print("\n--- TEST 13: Túi đồ đầy -> Phần thưởng rơi thành Pickup có thể nhặt, không bị mất ---")
	# Tạo World mới chưa nhận thưởng
	world2.queue_free()
	await process_frame

	var world3: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world3)
	current_scene = world3
	await _wait_seconds(0.2)

	# Làm đầy 16 ô túi đồ
	for i in range(16):
		world3.player.inventory_component.slots[i] = {"item_id": "health_potion", "amount": 20}

	world3.boss_reward_claimed = false
	world3.grant_boss_reward()

	var ground_reward_pickup: ItemPickup = null
	for child in world3.get_children():
		if child is ItemPickup and child.item_id == "eclipse_fragment":
			ground_reward_pickup = child
			break

	_assert(ground_reward_pickup != null, "Mảnh Nguyệt Thực rơi thành công trên mặt đất khi túi đồ đầy")
	_assert(ground_reward_pickup.pickup_id == "drop_boss_eclipse_fragment", "Pickup có định danh ổn định để bảo toàn lưu/tải")

	# -------------------------------------------------------------
	# TEST 14: Tương thích ngược với file save M3.2 cũ (Schema v1.0.0)
	# -------------------------------------------------------------
	print("\n--- TEST 14: Tương thích ngược với file save M3.2 cũ (Schema v1.0.0 không có trường boss) ---")
	var m3_old_save_content := "{\"save_version\":\"1.0.0\",\"player\":{\"position_x\":200.0,\"position_y\":630.0,\"current_health\":100.0,\"current_mana\":60.0},\"gold\":50,\"inventory\":[],\"equipment\":{},\"quest\":{\"state\":3,\"current_amount\":3}}"
	var test_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	test_file.store_string(m3_old_save_content)
	test_file.close()

	_assert(SaveManager.has_save() == true, "has_save() chấp nhận bản lưu schema cũ v1.0.0")
	var load_old_res := SaveManager.load_game(world3)
	_assert(load_old_res == true, "load_game() nạp thành công bản lưu v1.0.0 mà không bị crash")
	_assert(world3.boss_defeated == false, "Mặc định an toàn: Boss chưa thanh tẩy khi nạp bản lưu cũ")

	# -------------------------------------------------------------
	# TEST 15: Kiểm tra hồi quy toàn diện M0, M1, M2.1, M3
	# -------------------------------------------------------------
	print("\n--- TEST 15: Kiểm tra hồi quy các tính năng cốt lõi M0 - M3.2 ---")
	_assert(world3.npc_elyra.collision_layer == 0, "M2.1: NPC Elyra collision_layer = 0 (xuyên người)")
	_assert(world3.player.movement_data.max_jumps == 2, "M0: Double Jump nguyên vẹn")
	_assert(world3.pause_controller != null, "M0: PauseController hoạt động")
	world3.pause_controller.pause()
	_assert(world3.get_tree().paused == true, "Pause thành công")
	world3.pause_controller.resume()
	_assert(world3.get_tree().paused == false, "Resume thành công")

	_assert(world3.player.melee_hitbox.damage >= 25.0, "M1: Melee Hitbox nguyên vẹn")
	_assert(world3.player.combat_component != null, "M1: Combat Component nguyên vẹn")
	_assert(world3.player.inventory_component.max_slots == 16, "M3: Inventory 16 ô nguyên vẹn")

	# -------------------------------------------------------------
	# KIỂM TRA CÁCH LY FILE SAVE THẬT 100%
	# -------------------------------------------------------------
	print("\n--- KIỂM TRA AN TOÀN DỮ LIỆU: File save thật không bị ảnh hưởng ---")
	var real_file_existed_at_end := FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		_assert(real_file_existed_at_end == true, "File save thật vẫn tồn tại nguyên vẹn")
		var real_hash_at_end := FileAccess.get_md5(REAL_SAVE_PATH)
		_assert(real_hash_at_end == real_file_hash_at_start, "Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI")
	else:
		_assert(real_file_existed_at_end == false, "File save thật không tồn tại từ đầu và TUYỆT ĐỐI KHÔNG BỊ TẠO GIẢ ĐỊNH")

	# Dọn dẹp DUY NHẤT file test M4
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	print("\n==================================================")
	print(" [NOCTELYRA M4] KẾT QUẢ KIỂM THỬ TỔNG HỢP:")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL 15 M4 BOSS TEST SCENARIOS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

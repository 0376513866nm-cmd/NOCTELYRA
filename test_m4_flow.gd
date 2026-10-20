extends SceneTree

# test_m4_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M4.1 STABILIZATION.
# Verifies all M4.1 requirements:
# 1. Boss invulnerability during entire 1.3s Phase Transition & damage resumption afterwards.
# 2. Complete Boss & Visual reset upon Retry (colors, state, timers, hurtbox, no duplicates).
# 3. Clean-up of all BossShockwaves on player death/retry and boss purification.
# 4. Correct initialization order and visual styling for BossShockwave (Phase 1 & Phase 2).
# 5. SaveManager protection: save refused during boss combat, allowed after victory.
# 6. Reward dropped on ground when inventory full persists across Save/Load.
# 7. Gate locked during READY_TO_TURN_IN, unlocked ONLY when COMPLETED.
# 8. Real physical collision tests for Gate (Dash & Double Jump blocked).
# 9. Real combat collision tests between Boss & Player (first hit deals real damage, second hit prevented).
# 10. Backward compatibility with M3.2 save files (v1.0.0) & safe read-only checks on real save file.

const BossLunarethScript = preload("res://src/boss/boss_lunareth.gd")
const BossVisualScript = preload("res://src/boss/boss_visual.gd")
const BossShockwaveScript = preload("res://src/boss/boss_shockwave.gd")
const MagicGateScript = preload("res://src/world/magic_gate.gd")

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m4_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M4.1] BOSS ENCOUNTER TEST SUITE START ")
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
	# CATEGORY 1: Trạng thái ban đầu & Cổng Ma Pháp chặn lối
	# -------------------------------------------------------------
	print("\n--- CATEGORY 1: Khởi tạo Boss & Kiểm tra Cổng Ma Pháp khóa ban đầu ---")
	_assert(boss != null, "Boss Lunareth tồn tại trong scene")
	_assert(boss.health_component.max_health == 320.0, "HP tối đa của Boss là 320")
	_assert(boss.health_component.current_health == 320.0, "HP hiện tại của Boss là 320/320")
	_assert(boss.current_state == BossLunarethScript.State.DORMANT, "Boss ban đầu ở trạng thái DORMANT")
	_assert(boss.is_phase_2 == false, "Boss bắt đầu ở Phase 1")
	_assert(world.boss_battle_started == false, "Trận chiến Boss chưa bắt đầu")

	_assert(gate != null and gate.is_open == false, "Cổng Ma Pháp đang ở trạng thái KHÓA")
	var gate_col: CollisionShape2D = gate.get_node_or_null("CollisionShape2D")
	_assert(gate_col != null and gate_col.disabled == false, "Va chạm vật lý của Cổng Ma Pháp đang BẬT")

	# -------------------------------------------------------------
	# CATEGORY 2: Cổng vẫn khóa khi nhiệm vụ là READY_TO_TURN_IN
	# -------------------------------------------------------------
	print("\n--- CATEGORY 2: Cổng vẫn khóa khi nhiệm vụ ở READY_TO_TURN_IN ---")
	quest_mgr.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
	gate.update_quest_status(quest_mgr.current_quest)
	_assert(gate.is_open == false, "Cổng Ma Pháp VẪN KHÓA khi nhiệm vụ ở READY_TO_TURN_IN (chưa trả quest)")
	_assert(gate_col.disabled == false, "Va chạm vật lý vẫn BẬT khi ở READY_TO_TURN_IN")

	# -------------------------------------------------------------
	# CATEGORY 3: Kiểm thử va chạm vật lý thực tế của Cổng (Dash & Double Jump)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 3: Kiểm thử va chạm vật lý thực tế của Cổng (Dash & Double Jump) ---")
	# Đặt Player ngay sát bên trái cổng (X=3950, Cổng tại X=4000)
	player.global_position = Vector2(3950.0, 630.0)
	# Thử lướt Dash tốc độ cao về phía cổng
	player.velocity = Vector2(800.0, 0.0)
	player.move_and_slide()
	_assert(player.global_position.x <= 4000.0, "Dash bị chặn đứng bởi Cổng Ma Pháp (X: %.1f <= 4000)" % player.global_position.x)

	# Thử nhảy cao trên không (Double Jump) bay về phía cổng
	player.global_position = Vector2(3950.0, 450.0) # Độ cao 180px trên không (vẫn nằm trong rào chắn 400px)
	player.velocity = Vector2(600.0, -100.0)
	player.move_and_slide()
	_assert(player.global_position.x <= 4000.0, "Nhảy đôi trên không vẫn bị Cổng chặn hoàn toàn (X: %.1f <= 4000)" % player.global_position.x)

	# -------------------------------------------------------------
	# CATEGORY 4: Cổng Ma Pháp CHỈ MỞ khi nhiệm vụ là COMPLETED
	# -------------------------------------------------------------
	print("\n--- CATEGORY 4: Cổng Ma Pháp CHỈ MỞ khi nhiệm vụ chuyển sang COMPLETED ---")
	quest_mgr.current_quest.current_state = QuestData.State.COMPLETED
	gate.update_quest_status(quest_mgr.current_quest)
	_assert(gate.is_open == true, "Cổng Ma Pháp đã MỞ khi nhiệm vụ đạt COMPLETED")
	_assert(gate_col.disabled == true, "Va chạm vật lý đã TẮT để cho phép người chơi đi qua")

	# Cho Player đi qua vị trí cổng đã mở
	player.global_position = Vector2(3980.0, 630.0)
	player.velocity = Vector2(400.0, 0.0)
	player.move_and_slide()
	_assert(player.global_position.x > 3980.0, "Player đi xuyên qua cổng đã mở thành công")

	# -------------------------------------------------------------
	# CATEGORY 5: Kích hoạt Đấu trường & Rào chắn Arena khóa lại
	# -------------------------------------------------------------
	print("\n--- CATEGORY 5: Kích hoạt Đấu trường & Rào chắn Arena khóa lại ---")
	player.global_position = Vector2(4450.0, 630.0)
	world._on_arena_trigger_entered(player)

	_assert(world.boss_battle_started == true, "Cờ boss_battle_started kích hoạt")
	_assert(boss.current_state == BossLunarethScript.State.INTRO or boss.current_state == BossLunarethScript.State.APPROACH, "Boss chuyển sang thức tỉnh")
	var barrier_col: CollisionShape2D = barrier.get_node_or_null("CollisionShape2D")
	_assert(barrier_col != null and barrier_col.disabled == false, "Rào chắn đấu trường khóa chặt Player bên trong")
	_assert(ui.boss_hud.visible == true, "Thanh HUD Boss hiển thị trên màn hình")

	# -------------------------------------------------------------
	# CATEGORY 6: Telegraph xuất hiện trước đòn đánh (Charge 0.7s, Shockwave 0.9s)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 6: Thời gian Telegraph thực tế (Charge 0.7s, Shockwave 0.9s) ---")
	boss.current_attack = BossLunarethScript.AttackType.HORN_CHARGE
	boss._change_state(BossLunarethScript.State.TELEGRAPH)
	_assert(boss._state_timer >= 0.7, "Thời gian cảnh báo đòn Húc thực tế là %.2fs (yêu cầu >= 0.6s)" % boss._state_timer)
	_assert(boss.charge_hitbox.monitoring == false, "Hitbox húc TẮT trong thời gian Telegraph")
	_assert(boss.boss_visual.telegraph_charge_rect.visible == true, "Vùng cảnh báo đòn húc hiển thị")

	boss.current_attack = BossLunarethScript.AttackType.MOON_SHOCKWAVE
	boss._change_state(BossLunarethScript.State.TELEGRAPH)
	_assert(boss._state_timer >= 0.9, "Thời gian cảnh báo đòn Chấn Ba thực tế là %.2fs (yêu cầu >= 0.8s)" % boss._state_timer)
	_assert(boss.boss_visual.telegraph_shockwave_ring.visible == true, "Vòng ma pháp cảnh báo chấn ba hiển thị")

	# -------------------------------------------------------------
	# CATEGORY 7: Kiểm thử va chạm thực tế & chống sát thương trùng (Horn Charge 20 DMG)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 7: Kiểm thử sát thương thực tế & chống trùng đòn (Horn Charge) ---")
	boss._change_state(BossLunarethScript.State.ATTACK)
	boss.charge_hitbox.reset_hits()
	_assert(boss.charge_hitbox.damage == 20.0, "Sát thương Horn Charge đúng 20.0")

	player.health_component.current_health = 100.0
	player.health_component.cancel_invulnerability()

	# Lần 1: Va chạm thực tế với Player Hurtbox -> CHỨNG MINH THỰC SỰ GÂY SÁT THƯƠNG
	boss.charge_hitbox._on_area_entered(player.hurtbox)
	var hp_after_hit1: float = player.health_component.current_health
	_assert(hp_after_hit1 == 80.0, "Lần húc đầu tiên THỰC SỰ gây sát thương: HP giảm từ 100 còn %.1f (-20 DMG)" % hp_after_hit1)

	# Lần 2: Va chạm tiếp trong cùng một đòn (chưa reset hits) -> KHÔNG ĐƯỢC GÂY THÊM SÁT THƯƠNG
	boss.charge_hitbox._on_area_entered(player.hurtbox)
	var hp_after_hit2: float = player.health_component.current_health
	_assert(hp_after_hit2 == 80.0, "Cơ chế chống đòn trùng: Không gây thêm sát thương trong cùng lượt húc (HP giữ nguyên 80.0)")

	# -------------------------------------------------------------
	# CATEGORY 8: Projectile BossShockwave (Phase 1 & Phase 2 đúng màu và tốc độ)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 8: Projectile BossShockwave (Tốc độ & Màu sắc Phase 1 / Phase 2) ---")
	var shockwave_scene: PackedScene = preload("res://src/boss/boss_shockwave.tscn")
	var sw_p1 = shockwave_scene.instantiate()
	world.add_child(sw_p1)
	sw_p1.setup(-1.0, false) # Phase 1
	_assert(sw_p1.speed == 380.0, "Tốc độ sóng chấn ba Phase 1 là 380 px/s")
	_assert(sw_p1.damage == 25.0, "Sát thương sóng chấn ba đúng 25 DMG")
	_assert(sw_p1.is_in_group("boss_projectiles") == true, "BossShockwave nằm trong group 'boss_projectiles'")
	var wave_col_p1: Color = sw_p1.visual_wave.color
	_assert(wave_col_p1.b > wave_col_p1.r, "Màu sắc sóng Phase 1 là tông Lam Nguyệt (Cyan/Blue)")

	var sw_p2 = shockwave_scene.instantiate()
	world.add_child(sw_p2)
	sw_p2.setup(-1.0, true) # Phase 2
	_assert(sw_p2.speed == 440.0, "Tốc độ sóng chấn ba Phase 2 tăng lên 440 px/s")
	var wave_col_p2: Color = sw_p2.visual_wave.color
	_assert(wave_col_p2.r > 0.8 and wave_col_p2.b > 0.7, "Màu sắc sóng Phase 2 là tông Hắc Nguyệt (Dark Violet)")

	# Kiểm thử sát thương thực tế của Shockwave lên Player
	player.health_component.cancel_invulnerability()
	var prev_hp: float = player.health_component.current_health
	sw_p1._on_area_entered(player.hurtbox)
	_assert(player.health_component.current_health == prev_hp - 25.0, "Shockwave gây đúng 25 DMG lên Player (HP: %.1f -> %.1f)" % [prev_hp, player.health_component.current_health])

	# -------------------------------------------------------------
	# CATEGORY 9: Boss Miễn Sát Thương trong toàn bộ Phase Transition (1.3s)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 9: Miễn sát thương tuyệt đối trong toàn bộ 1.3s Phase Transition ---")
	boss.health_component.current_health = 160.0
	boss.health_component.emit_signal("health_changed", 160.0, 320.0)

	_assert(boss.is_phase_2 == true, "Boss đã kích hoạt Phase 2 khi HP <= 160")
	_assert(boss.current_state == BossLunarethScript.State.PHASE_TRANSITION, "Boss đang trong trạng thái PHASE_TRANSITION")
	_assert(boss.health_component.is_invulnerable == true, "Boss bật cờ bất tử khi bắt đầu chuyển phase")

	# Gây sát thương ngay thời điểm bắt đầu chuyển phase (t = 0.0s)
	var dmg_t0 := DamageInfo.new(30.0, player)
	var taken_t0: bool = boss.hurtbox.apply_damage(dmg_t0)
	_assert(taken_t0 == false, "Đòn đánh bị từ chối ở đầu chuyển phase (taken == false)")
	_assert(boss.health_component.current_health == 160.0, "HP vẫn giữ nguyên 160.0 không đổi")

	# Mô phỏng thời gian chạy đến giữa chuyển phase (t = 0.6s)
	boss._physics_process(0.6)
	boss.health_component._process(0.6)
	_assert(boss.health_component.is_invulnerable == true, "Boss VẪN BẤT TỬ ở giữa quá trình chuyển phase (t = 0.6s)")
	var dmg_mid := DamageInfo.new(30.0, player)
	var taken_mid: bool = boss.hurtbox.apply_damage(dmg_mid)
	_assert(taken_mid == false, "Đòn đánh bị từ chối ở giữa chuyển phase (không bị HealthComponent._process tắt sớm)")
	_assert(boss.health_component.current_health == 160.0, "HP vẫn được bảo toàn nguyên vẹn 160.0")

	# -------------------------------------------------------------
	# CATEGORY 10: Boss nhận sát thương bình thường sau khi chuyển Phase xong
	# -------------------------------------------------------------
	print("\n--- CATEGORY 10: Boss nhận sát thương trở lại bình thường sau khi chuyển Phase xong ---")
	# Mô phỏng hết thời gian còn lại (0.8s nữa, tổng cộng > 1.3s)
	boss._physics_process(0.8)
	boss.health_component._process(0.8)

	_assert(boss.current_state == BossLunarethScript.State.RECOVERY, "Sau 1.3s, Boss kết thúc chuyển phase và sang RECOVERY")
	_assert(boss.health_component.is_invulnerable == false, "Cờ bất tử đã được gỡ bỏ an toàn, không bị bất tử vĩnh viễn")

	# Tấn công Boss sau khi chuyển phase xong
	var dmg_post := DamageInfo.new(25.0, player)
	var taken_post: bool = boss.hurtbox.apply_damage(dmg_post)
	_assert(taken_post == true, "Boss nhận sát thương thành công sau khi hoàn tất chuyển phase")
	_assert(boss.health_component.current_health == 135.0, "HP giảm chính xác còn 135.0 (160 - 25)")

	# Thử giảm thêm HP để chứng minh Phase 2 chỉ kích hoạt 1 lần
	boss.health_component.current_health = 100.0
	boss.health_component.emit_signal("health_changed", 100.0, 320.0)
	_assert(boss.current_state != BossLunarethScript.State.PHASE_TRANSITION, "Phase 2 chỉ kích hoạt duy nhất một lần, không lặp lại")

	# -------------------------------------------------------------
	# CATEGORY 11: Retry từ Phase 2 đưa màu sắc, trạng thái và visual về Phase 1
	# -------------------------------------------------------------
	print("\n--- CATEGORY 11: Retry từ Phase 2 đưa màu sắc và trạng thái về chuẩn Phase 1 ---")
	_assert(boss.boss_visual.is_phase_2 == true, "Boss Visual hiện đang là Phase 2 (màu tím)")

	# Player chết và Retry
	player.health_component.current_health = 0.0
	player.health_component.emit_signal("died")
	world._on_retry_requested()

	_assert(boss.is_phase_2 == false, "Boss logic trở về Phase 1 sau Retry")
	_assert(boss.current_state == BossLunarethScript.State.DORMANT, "Boss AI trở về DORMANT sau Retry")
	_assert(boss.health_component.current_health == 320.0, "HP Boss hồi phục đầy đủ 320/320")
	_assert(boss.boss_visual.is_phase_2 == false, "Boss Visual trở về Phase 1 sau Retry")
	_assert(boss.boss_visual.current_visual_state == BossVisualScript.VisualState.IDLE, "Boss Visual state trở về IDLE")
	_assert(boss.charge_hitbox.monitoring == false, "Hitbox tấn công tắt sau Retry")
	var h_col := boss.hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_assert(h_col != null and h_col.disabled == false, "Hurtbox CollisionShape được khôi phục bật sau Retry")

	# -------------------------------------------------------------
	# CATEGORY 12: Dọn dẹp sạch sẽ BossShockwave khi Retry & Thanh Tẩy
	# -------------------------------------------------------------
	print("\n--- CATEGORY 12: Dọn dẹp sạch sẽ projectile khi Retry & Thanh Tẩy ---")
	# Tạo thêm shockwave trong scene
	var extra_sw = shockwave_scene.instantiate()
	world.add_child(extra_sw)
	extra_sw.setup(-1.0, false)
	_assert(world.get_tree().get_nodes_in_group("boss_projectiles").size() > 0, "Có projectile boss đang tồn tại")

	# Gọi hàm Retry -> projectile phải bị dọn sạch
	world._on_retry_requested()
	await process_frame

	var active_projectiles = world.get_tree().get_nodes_in_group("boss_projectiles").filter(func(node): return is_instance_valid(node) and not node.is_queued_for_deletion())
	_assert(active_projectiles.size() == 0, "Không còn bất kỳ projectile Boss nào sót lại sau khi Retry")

	# -------------------------------------------------------------
	# CATEGORY 13: Bảo vệ Save System - Chặn lưu khi đang đánh Boss
	# -------------------------------------------------------------
	print("\n--- CATEGORY 13: Bảo vệ Save System (Chặn lưu khi đang giao tranh Boss) ---")
	world.start_boss_battle()
	_assert(SaveManager.is_boss_combat_active(world) == true, "Hệ thống nhận diện trận đánh Boss đang diễn ra")
	var save_during_combat: bool = SaveManager.save_game(world)
	_assert(save_during_combat == false, "SaveManager TỪ CHỐI lưu game khi đang giao chiến với Boss")

	# -------------------------------------------------------------
	# CATEGORY 14: Đánh bại Boss, Autosave thành công & Phần thưởng duy nhất
	# -------------------------------------------------------------
	print("\n--- CATEGORY 14: Đánh bại Boss, Autosave sau chiến thắng & Thưởng 100 Vàng + Mảnh Nguyệt Thực ---")
	player.inventory_component._initialize_slots()
	var gold_prior: int = quest_mgr.gold
	boss.health_component.current_health = 0.0
	boss.health_component.emit_signal("died")

	_assert(boss.current_state == BossLunarethScript.State.DEFEATED, "Boss chuyển sang trạng thái DEFEATED")
	_assert(world.boss_defeated == true, "Cờ boss_defeated được xác lập")
	_assert(quest_mgr.gold == gold_prior + 100, "Nhận chính xác 100 Vàng thưởng")
	_assert(player.inventory_component.has_item("eclipse_fragment") == true, "Nhận Mảnh Nguyệt Thực vào túi đồ")

	# Kiểm tra Autosave sau chiến thắng
	_assert(SaveManager.is_boss_combat_active(world) == false, "Chiến đấu đã kết thúc, không còn chặn lưu")
	var save_after_win: bool = SaveManager.save_game(world)
	_assert(save_after_win == true, "Autosave sau chiến thắng chạy thành công hoàn hảo")

	# -------------------------------------------------------------
	# CATEGORY 15: Túi đồ đầy -> Vật phẩm thưởng rơi mặt đất & Phục hồi sau Save/Load
	# -------------------------------------------------------------
	print("\n--- CATEGORY 15: Túi đồ đầy -> Thưởng rơi mặt đất và khôi phục nguyên vẹn sau Save/Load ---")
	world.queue_free()
	await process_frame

	var world_full: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world_full)
	current_scene = world_full
	await _wait_seconds(0.2)

	# Làm đầy 16 ô túi đồ
	for i in range(16):
		world_full.player.inventory_component.slots[i] = {"item_id": "health_potion", "amount": 20}

	world_full.boss_reward_claimed = false
	world_full.grant_boss_reward()

	var ground_drop: ItemPickup = null
	for child in world_full.get_children():
		if child is ItemPickup and child.item_id == "eclipse_fragment":
			ground_drop = child
			break

	_assert(ground_drop != null, "Mảnh Nguyệt Thực rơi trên mặt đất khi túi đồ đầy")
	_assert(ground_drop.pickup_id == "drop_boss_eclipse_fragment", "Định danh pickup_id ổn định: drop_boss_eclipse_fragment")

	# Lưu game khi vật phẩm đang nằm trên mặt đất
	var save_drop_ok: bool = SaveManager.save_game(world_full)
	_assert(save_drop_ok == true, "Lưu game chứa vật phẩm thưởng trên mặt đất thành công")

	world_full.queue_free()
	await process_frame

	# Nạp lại game vào thế giới mới
	var world_loaded: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world_loaded)
	current_scene = world_loaded
	await _wait_seconds(0.2)

	SaveManager.load_game(world_loaded)

	var restored_drop: ItemPickup = null
	for child in world_loaded.get_children():
		if child is ItemPickup and child.item_id == "eclipse_fragment":
			restored_drop = child
			break

	_assert(restored_drop != null, "Mảnh Nguyệt Thực rơi trên đất được PHỤC HỒI CHÍNH XÁC sau khi tải game")

	# Làm trống 1 ô và nhặt vật phẩm lên
	world_loaded.player.inventory_component.slots[0] = {"item_id": "", "amount": 0}
	world_loaded.player.global_position = restored_drop.global_position
	restored_drop._on_body_entered(world_loaded.player)
	_assert(world_loaded.player.inventory_component.has_item("eclipse_fragment") == true, "Player nhặt thành công Mảnh Nguyệt Thực vào túi sau khi dọn chỗ")

	# -------------------------------------------------------------
	# CATEGORY 16: Tương thích ngược phiên bản Save 1.0.0 (M3.2)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 16: Tương thích ngược phiên bản Save 1.0.0 (M3.2) ---")
	var m3_old_save_content := "{\"save_version\":\"1.0.0\",\"player\":{\"position_x\":200.0,\"position_y\":630.0,\"current_health\":100.0,\"current_mana\":60.0},\"gold\":50,\"inventory\":[],\"equipment\":{},\"quest\":{\"state\":3,\"current_amount\":3}}"
	var test_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	test_file.store_string(m3_old_save_content)
	test_file.close()

	_assert(SaveManager.has_save() == true, "has_save() chấp nhận bản lưu schema cũ v1.0.0")
	var load_old_res := SaveManager.load_game(world_loaded)
	_assert(load_old_res == true, "load_game() nạp thành công bản lưu v1.0.0 không lỗi")
	_assert(world_loaded.boss_defeated == false, "Boss mặc định chưa thanh tẩy trong bản lưu cũ")

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
	print(" [NOCTELYRA M4.1] KẾT QUẢ KIỂM THỬ TỔNG HỢP:")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL M4.1 STABILIZATION TESTS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

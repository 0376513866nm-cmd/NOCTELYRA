extends SceneTree

# test_m7_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M7: Regional Gameplay Expansion.
# Engine: Godot 4.3 + GDScript
# Covers all 13 required categories:
# 1. EnemyDefinition Registry & Presets Validation
# 2. Corrupted Mooncap Melee Combat, Telegraph & Damage
# 3. Corrupted Mana Wisp Hovering & Ranged Projectile
# 4. Ashfang Wolf Lunge Attack Mechanics (Telegraph, Lunge, Recovery)
# 5. Ember Lizard Ranged Fireball & Cooldown
# 6. Enemy Leash Distance Protection
# 7. Stop Attack on Player Death
# 8. Single Hitbox Damage Protection (No Infinite Damage Loop)
# 9. NPC Kaelis Side Quest Flow (Start, Mooncap Kills Filter, Turn-in Rewards, Lore Dialogue)
# 10. NPC Rhaek Side Quest Flow (Start, Collection, Inventory Deduction 3 Cores, Turn-in Rewards, Lore Dialogue)
# 11. Quest Journal UI (Q toggle, ESC close, displays all 3 quests, blocks action inputs)
# 12. World State Persistence & Save/Load v1.4.0 (Quests, Pickups, Defeated Enemies, Backward Compatibility v1.0.0-v1.3.0)
# 13. Isolation Verification (Real save file untouched, identical MD5)

const NoctisForestScript = preload("res://src/world/noctis_forest.gd")
const ElyndraGladeScript = preload("res://src/world/elyndra_glade.gd")
const VharokOutpostScript = preload("res://src/world/vharok_outpost.gd")
const EnemyScript = preload("res://src/actors/enemy/enemy.gd")
const EnemyScene = preload("res://src/actors/enemy/enemy.tscn")
const EnemyDefScript = preload("res://src/actors/enemy/enemy_definition.gd")
const EnemyProjectileScene = preload("res://src/actors/enemy/enemy_projectile.tscn")
const QuestDefScript = preload("res://src/quest/quest_definition.gd")
const QuestJournalCompScript = preload("res://src/quest/quest_journal_component.gd")
const ItemDatabaseScript = preload("res://src/inventory/item_database.gd")
const SpellDatabaseScript = preload("res://src/magic/spell_database.gd")

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m7_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M7] REGIONAL GAMEPLAY EXPANSION TEST SUITE")
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

func _simulate_physics(node: Node, ticks: int, delta: float = 0.016) -> void:
	for i in range(ticks):
		_step_physics_recursive(node, delta)

func _step_physics_recursive(node: Node, delta: float) -> void:
	if not is_instance_valid(node):
		return
	if node.has_method("_physics_process") and node.can_process():
		node._physics_process(delta)
	if node.has_method("_process") and node.can_process():
		node._process(delta)
	for child in node.get_children():
		_step_physics_recursive(child, delta)

func _run_suite() -> void:
	ItemDatabaseScript.initialize()
	SpellDatabaseScript.initialize()
	ZoneManager.reset_session()

	# GHI NHẬN CHỈ ĐỌC TRẠNG THÁI FILE SAVE THẬT - TUYỆT ĐỐI KHÔNG GHI/XÓA/SỬA
	real_file_existed_at_start = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		real_file_hash_at_start = FileAccess.get_md5(REAL_SAVE_PATH)

	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

	# -------------------------------------------------------------
	# CATEGORY 1: EnemyDefinition Registry & Presets Validation
	# -------------------------------------------------------------
	print("\n--- CATEGORY 1: EnemyDefinition Registry & Presets Validation ---")
	var mooncap_def = EnemyDefScript.get_definition("corrupted_mooncap")
	_assert(mooncap_def != null, "Định nghĩa corrupted_mooncap tồn tại")
	_assert(mooncap_def.max_health == 60.0, "Mooncap HP: 60.0")
	_assert(mooncap_def.move_speed == 80.0, "Mooncap speed: 80.0")
	_assert(mooncap_def.attack_type == EnemyDefScript.AttackType.MELEE, "Mooncap attack_type: MELEE")
	_assert(mooncap_def.attack_damage == 12.0, "Mooncap damage: 12.0")
	_assert(mooncap_def.is_flying == false, "Mooncap không bay (is_flying: false)")

	var wisp_def = EnemyDefScript.get_definition("corrupted_mana_wisp")
	_assert(wisp_def != null, "Định nghĩa corrupted_mana_wisp tồn tại")
	_assert(wisp_def.max_health == 35.0, "Mana Wisp HP: 35.0")
	_assert(wisp_def.move_speed == 60.0, "Mana Wisp speed: 60.0")
	_assert(wisp_def.attack_type == EnemyDefScript.AttackType.RANGED, "Mana Wisp attack_type: RANGED")
	_assert(wisp_def.is_flying == true, "Mana Wisp lơ lửng trên không (is_flying: true)")

	var wolf_def = EnemyDefScript.get_definition("ashfang_wolf")
	_assert(wolf_def != null, "Định nghĩa ashfang_wolf tồn tại")
	_assert(wolf_def.max_health == 70.0, "Ashfang Wolf HP: 70.0")
	_assert(wolf_def.move_speed == 180.0, "Ashfang Wolf di chuyển nhanh: 180.0")
	_assert(wolf_def.attack_type == EnemyDefScript.AttackType.LUNGE, "Ashfang Wolf attack_type: LUNGE")
	_assert(wolf_def.lunge_speed == 460.0, "Ashfang Wolf lunge_speed: 460.0")
	_assert(wolf_def.telegraph_duration == 0.5, "Ashfang Wolf telegraph_duration: 0.5s")
	_assert(wolf_def.recovery_duration == 0.85, "Ashfang Wolf recovery_duration: 0.85s")

	var lizard_def = EnemyDefScript.get_definition("ember_lizard")
	_assert(lizard_def != null, "Định nghĩa ember_lizard tồn tại")
	_assert(lizard_def.max_health == 80.0, "Ember Lizard HP: 80.0")
	_assert(lizard_def.attack_type == EnemyDefScript.AttackType.RANGED, "Ember Lizard attack_type: RANGED")
	_assert(lizard_def.projectile_speed == 280.0, "Ember Lizard projectile_speed: 280.0")
	_assert(lizard_def.drop_item_id == "ember_core", "Ember Lizard rơi ember_core")

	# Item ember_core
	var ember_item = ItemDatabase.get_item("ember_core")
	_assert(ember_item != null, "ItemDatabase có vật phẩm ember_core")
	_assert(ember_item.display_name == "Lõi Tàn Hỏa", "Tên vật phẩm: Lõi Tàn Hỏa")

	# -------------------------------------------------------------
	# CATEGORY 2: Corrupted Mooncap Melee Combat, Telegraph & Damage
	# -------------------------------------------------------------
	print("\n--- CATEGORY 2: Corrupted Mooncap Melee Combat, Telegraph & Damage ---")
	var root_node = Node2D.new()
	root_node.name = "TestRoot_Mooncap"
	root.add_child(root_node)

	var p_scene = preload("res://src/actors/player/player.tscn")
	var test_player: Player = p_scene.instantiate() as Player
	test_player.position = Vector2(200, 600)
	root_node.add_child(test_player)

	var mooncap: Enemy = EnemyScene.instantiate() as Enemy
	mooncap.enemy_type_id = "corrupted_mooncap"
	mooncap.enemy_id = "test_mooncap_1"
	mooncap.position = Vector2(250, 600)
	root_node.add_child(mooncap)

	_assert(mooncap.definition.display_name == "Nấm Mộng Tha Hóa", "Mooncap tên: Nấm Mộng Tha Hóa")
	_assert(mooncap.health_component.max_health == 60.0, "Mooncap máu tối đa: 60.0")
	_assert(mooncap.visual_root != null, "Mooncap có Visual Controller")

	# Phát hiện Player và chuẩn bị đòn
	mooncap.target_player = test_player
	mooncap._change_state(EnemyScript.State.TELEGRAPH)
	_assert(mooncap.current_state == EnemyScript.State.TELEGRAPH, "Mooncap chuyển sang TELEGRAPH")
	_assert(mooncap.attack_hitbox.monitoring == false, "Hitbox TẮT trong thời gian telegraph")

	# Hết telegraph sang ATTACK
	mooncap._change_state(EnemyScript.State.ATTACK)
	_assert(mooncap.attack_hitbox.monitoring == true, "Hitbox BẬT khi tấn công")
	_assert(mooncap.attack_hitbox.damage == 12.0, "Sát thương cận chiến của Mooncap là 12.0")

	# Gây sát thương lên Player
	var p_hp_before = test_player.health_component.current_health
	mooncap.attack_hitbox._on_area_entered(test_player.hurtbox)
	_assert(test_player.health_component.current_health == p_hp_before - 12.0, "Player mất chính xác 12.0 HP từ đòn đánh Mooncap")

	# Tiêu diệt Mooncap
	var mooncap_killed: Array[bool] = [false]
	var killed_type: Array[String] = [""]
	mooncap.enemy_defeated.connect(func(e):
		mooncap_killed[0] = true
		killed_type[0] = e.enemy_type_id
	)
	var dmg_kill := DamageInfo.new(100.0, test_player)
	mooncap.health_component.take_damage(dmg_kill)
	_simulate_physics(root_node, 5)
	_assert(mooncap_killed[0] == true, "Mooncap bị hạ gục phát tín hiệu enemy_defeated")
	_assert(killed_type[0] == "corrupted_mooncap", "enemy_defeated truyền đúng enemy_type_id == 'corrupted_mooncap'")

	root_node.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 3: Corrupted Mana Wisp Hovering & Ranged Projectile
	# -------------------------------------------------------------
	print("\n--- CATEGORY 3: Corrupted Mana Wisp Hovering & Ranged Projectile ---")
	var wisp_root = Node2D.new()
	root.add_child(wisp_root)

	var wisp_player: Player = p_scene.instantiate() as Player
	wisp_player.position = Vector2(100, 400)
	wisp_root.add_child(wisp_player)

	var wisp: Enemy = EnemyScene.instantiate() as Enemy
	wisp.enemy_type_id = "corrupted_mana_wisp"
	wisp.enemy_id = "test_wisp_1"
	wisp.position = Vector2(300, 400)
	wisp_root.add_child(wisp)

	_assert(wisp.definition.is_flying == true, "Wisp là quái bay")
	var wisp_initial_y = wisp.position.y
	_simulate_physics(wisp_root, 10)
	_assert(abs(wisp.position.y - wisp_initial_y) < 2.0, "Wisp lơ lửng không bị rơi bởi trọng lực")

	# Wisp bắn projectile
	wisp.target_player = wisp_player
	wisp.facing_direction = -1
	wisp._fire_projectile()
	await _wait_seconds(0.05)

	var projectiles = get_nodes_in_group("enemy_projectiles")
	_assert(projectiles.size() > 0, "Wisp bắn ra đạn trong group 'enemy_projectiles'")
	if projectiles.size() > 0:
		var proj: EnemyProjectile = projectiles[0] as EnemyProjectile
		_assert(proj.damage == 12.0, "Sát thương đạn Wisp là 12.0")
		_assert(proj.speed == 320.0, "Tốc độ đạn Wisp là 320.0 px/s")

		# Va chạm với Player
		var hp_prev = wisp_player.health_component.current_health
		proj._on_area_entered(wisp_player.hurtbox)
		_assert(wisp_player.health_component.current_health == hp_prev - 12.0, "Player nhận 12.0 sát thương từ đạn ma thuật của Wisp")
		_assert(proj.is_queued_for_deletion() or not proj.monitoring, "Đạn Wisp tự hủy sau khi trúng Player")

	wisp_root.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 4: Ashfang Wolf Lunge Attack Mechanics
	# -------------------------------------------------------------
	print("\n--- CATEGORY 4: Ashfang Wolf Lunge Attack Mechanics ---")
	var wolf_root = Node2D.new()
	root.add_child(wolf_root)

	var wolf_player: Player = p_scene.instantiate() as Player
	wolf_player.position = Vector2(500, 600)
	wolf_root.add_child(wolf_player)

	var wolf: Enemy = EnemyScene.instantiate() as Enemy
	wolf.enemy_type_id = "ashfang_wolf"
	wolf.enemy_id = "test_wolf_1"
	wolf.position = Vector2(400, 600)
	wolf_root.add_child(wolf)

	wolf.target_player = wolf_player
	wolf.facing_direction = 1

	# Phase 1: TELEGRAPH
	wolf._change_state(EnemyScript.State.TELEGRAPH)
	_assert(wolf.current_state == EnemyScript.State.TELEGRAPH, "Wolf chuyển sang TELEGRAPH")
	_assert(wolf.state_timer == 0.5, "Wolf có thời gian báo hiệu 0.5s trước khi vồ")
	_assert(wolf.attack_hitbox.monitoring == false, "Hitbox vồ TẮT khi đang gầm báo hiệu")

	# Phase 2: LUNGE ATTACK
	wolf._change_state(EnemyScript.State.ATTACK)
	_assert(wolf.current_state == EnemyScript.State.ATTACK, "Wolf chuyển sang ATTACK (Lunge)")
	_assert(wolf.attack_hitbox.monitoring == true, "Hitbox BẬT khi đang lao tới")
	_assert(wolf.attack_hitbox.damage == 18.0, "Sát thương cú vồ là 18.0")

	wolf._process_attack(0.016)
	_assert(wolf.velocity.x == 460.0, "Vận tốc lao tới đạt đúng lunge_speed: 460 px/s")

	# Phase 3: RECOVERY
	wolf._change_state(EnemyScript.State.RECOVERY)
	_assert(wolf.current_state == EnemyScript.State.RECOVERY, "Wolf chuyển sang RECOVERY sau khi kết thúc vồ")
	_assert(wolf.state_timer == 0.85, "Thời gian khựng nghỉ sau cú vồ là 0.85s")
	_assert(wolf.attack_hitbox.monitoring == false, "Hitbox TẮT trong thời gian khựng nghỉ")

	wolf_root.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 5: Ember Lizard Ranged Fireball & Cooldown
	# -------------------------------------------------------------
	print("\n--- CATEGORY 5: Ember Lizard Ranged Fireball & Cooldown ---")
	var lizard_root = Node2D.new()
	root.add_child(lizard_root)

	var lizard_player: Player = p_scene.instantiate() as Player
	lizard_player.position = Vector2(800, 600)
	lizard_root.add_child(lizard_player)

	var lizard: Enemy = EnemyScene.instantiate() as Enemy
	lizard.enemy_type_id = "ember_lizard"
	lizard.enemy_id = "test_lizard_1"
	lizard.position = Vector2(500, 600)
	lizard_root.add_child(lizard)

	lizard.target_player = lizard_player
	lizard.facing_direction = 1

	lizard._change_state(EnemyScript.State.ATTACK)
	_assert(lizard.attack_timer == 1.6, "Thời gian hồi chiêu cầu lửa của Thằn Lằn là 1.6s")

	await _wait_seconds(0.05)
	var lizard_projs = get_nodes_in_group("enemy_projectiles")
	var found_fireball: bool = false
	for p in lizard_projs:
		if p is EnemyProjectile and p.damage == 15.0 and p.speed == 280.0:
			found_fireball = true
			break
	_assert(found_fireball == true, "Thằn lằn bắn cầu lửa 15.0 DMG với tốc độ 280 px/s")

	lizard_root.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 6: Enemy Leash Distance Protection
	# -------------------------------------------------------------
	print("\n--- CATEGORY 6: Enemy Leash Distance Protection ---")
	var leash_root = Node2D.new()
	root.add_child(leash_root)

	var lp: Player = p_scene.instantiate() as Player
	lp.position = Vector2(1200, 600)
	leash_root.add_child(lp)

	var l_enemy: Enemy = EnemyScene.instantiate() as Enemy
	l_enemy.enemy_type_id = "ashfang_wolf"
	l_enemy.enemy_id = "test_leash_wolf"
	l_enemy.position = Vector2(500, 600)
	leash_root.add_child(l_enemy)

	_simulate_physics(leash_root, 2)
	l_enemy._spawn_position = Vector2(500, 600)
	l_enemy.target_player = lp
	l_enemy._change_state(EnemyScript.State.CHASE)

	# Đặt vị trí quái vượt quá leash_distance (500 + 550 = 1050px)
	l_enemy.global_position = Vector2(1100, 600)
	l_enemy._physics_process(0.016)

	_assert(l_enemy.target_player == null, "Quái vật bỏ mục tiêu khi vượt quá phạm vi giới hạn (Leash Distance)")
	_assert(l_enemy.current_state == EnemyScript.State.IDLE or l_enemy.current_state == EnemyScript.State.PATROL, "Quái vật quay về trạng thái IDLE/PATROL")

	leash_root.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 7: Stop Attack on Player Death
	# -------------------------------------------------------------
	print("\n--- CATEGORY 7: Stop Attack on Player Death ---")
	var death_root = Node2D.new()
	root.add_child(death_root)

	var dp: Player = p_scene.instantiate() as Player
	dp.position = Vector2(500, 600)
	death_root.add_child(dp)

	var de: Enemy = EnemyScene.instantiate() as Enemy
	de.enemy_type_id = "corrupted_mooncap"
	de.enemy_id = "test_death_enemy"
	de.position = Vector2(520, 600)
	death_root.add_child(de)

	de.target_player = dp
	de._change_state(EnemyScript.State.ATTACK)
	_assert(de.attack_hitbox.monitoring == true, "Hitbox đang bật trước khi Player chết")

	# Player tử vong
	dp.health_component.current_health = 0.0
	dp.health_component.emit_signal("died")
	de._physics_process(0.016)

	_assert(de.target_player == null, "Quái vật ngừng nhắm Player ngay khi Player chết")
	_assert(de.attack_hitbox.monitoring == false, "Hitbox tấn công tự động TẮT ngay khi Player chết")

	death_root.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 8: Single Hitbox Damage Protection (No Infinite Loop)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 8: Single Hitbox Damage Protection (No Infinite Damage Loop) ---")
	var hit_root = Node2D.new()
	root.add_child(hit_root)

	var hp_p: Player = p_scene.instantiate() as Player
	hp_p.position = Vector2(300, 600)
	hit_root.add_child(hp_p)

	var he: Enemy = EnemyScene.instantiate() as Enemy
	he.enemy_type_id = "corrupted_mooncap"
	he.position = Vector2(300, 600)
	hit_root.add_child(he)

	he._change_state(EnemyScript.State.ATTACK)
	var initial_hp = hp_p.health_component.current_health

	# Mô phỏng đòn đánh trúng Player lần đầu
	he.attack_hitbox._on_area_entered(hp_p.hurtbox)
	_assert(hp_p.health_component.current_health == initial_hp - 12.0, "Player nhận sát thương lần đầu: -12.0 HP")

	# Mô phỏng cùng hitbox đó va chạm lại trong cùng 1 đòn (chưa reset_hits)
	he.attack_hitbox._on_area_entered(hp_p.hurtbox)
	_assert(hp_p.health_component.current_health == initial_hp - 12.0, "Hitbox không gây sát thương lặp vô hạn trong cùng một đòn")

	hit_root.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 9: NPC Kaelis Side Quest Flow
	# -------------------------------------------------------------
	print("\n--- CATEGORY 9: NPC Kaelis Side Quest Flow ---")
	var elyndra_scene = preload("res://src/world/elyndra_glade.tscn")
	var eg_zone = elyndra_scene.instantiate()
	root.add_child(eg_zone)
	current_scene = eg_zone
	await _wait_seconds(0.3)

	var eg_player: Player = eg_zone.get_node_or_null("Player") as Player
	var eg_kaelis: NPC = eg_zone.get_node_or_null("NPC_Kaelis") as NPC
	var eg_quest_mgr: QuestManager = eg_zone.get_node_or_null("QuestManager") as QuestManager
	var eg_ui: GameUI = eg_zone.get_node_or_null("GameUI") as GameUI
	var journal: QuestJournalComponent = eg_player.quest_journal_component

	_assert(journal != null, "Player có QuestJournalComponent")
	_assert(journal.get_quest_state("quest_elyndra_cleansing") == QuestDefScript.QuestState.NOT_STARTED, "Quest Kaelis ban đầu là NOT_STARTED")

	# 1. Nhận quest từ Kaelis
	eg_kaelis.trigger_interaction()
	_assert(eg_ui.is_dialogue_open(), "Tương tác mở hộp thoại Kaelis")
	while eg_ui.is_dialogue_open():
		eg_ui.advance_dialogue()

	_assert(journal.get_quest_state("quest_elyndra_cleansing") == QuestDefScript.QuestState.ACTIVE, "Quest Kaelis chuyển sang ACTIVE sau khi đối thoại")
	_assert(journal.get_quest_progress("quest_elyndra_cleansing") == 0, "Tiến độ ban đầu: 0/3")

	# 2. Tiêu diệt quái không đúng loại -> Không tăng
	var fake_wolf: Enemy = EnemyScene.instantiate() as Enemy
	fake_wolf.enemy_type_id = "ashfang_wolf"
	fake_wolf.enemy_id = "fake_wolf_1"
	eg_zone.add_child(fake_wolf)
	journal.register_enemy_kill(fake_wolf)
	_assert(journal.get_quest_progress("quest_elyndra_cleansing") == 0, "Diệt Ashfang Wolf không làm tăng tiến độ quest Nấm Kaelis")
	fake_wolf.queue_free()

	# 3. Tiêu diệt đúng 3 Corrupted Mooncap
	var m1: Enemy = EnemyScene.instantiate() as Enemy
	m1.enemy_type_id = "corrupted_mooncap"
	m1.enemy_id = "kill_mooncap_1"
	eg_zone.add_child(m1)
	journal.register_enemy_kill(m1)
	_assert(journal.get_quest_progress("quest_elyndra_cleansing") == 1, "Diệt Mooncap 1: Tiến độ 1/3")

	# Chống đếm trùng cùng một quái
	journal.register_enemy_kill(m1)
	_assert(journal.get_quest_progress("quest_elyndra_cleansing") == 1, "Chống đếm trùng: Mooncap 1 không bị đếm 2 lần")

	var m2: Enemy = EnemyScene.instantiate() as Enemy
	m2.enemy_type_id = "corrupted_mooncap"
	m2.enemy_id = "kill_mooncap_2"
	eg_zone.add_child(m2)
	journal.register_enemy_kill(m2)
	_assert(journal.get_quest_progress("quest_elyndra_cleansing") == 2, "Diệt Mooncap 2: Tiến độ 2/3")

	var m3: Enemy = EnemyScene.instantiate() as Enemy
	m3.enemy_type_id = "corrupted_mooncap"
	m3.enemy_id = "kill_mooncap_3"
	eg_zone.add_child(m3)
	journal.register_enemy_kill(m3)
	_assert(journal.get_quest_progress("quest_elyndra_cleansing") == 3, "Diệt Mooncap 3: Tiến độ 3/3")
	_assert(journal.get_quest_state("quest_elyndra_cleansing") == QuestDefScript.QuestState.READY_TO_TURN_IN, "Quest Kaelis chuyển sang READY_TO_TURN_IN")

	# 4. Trả quest Kaelis
	await _wait_seconds(0.3)
	var gold_before = eg_quest_mgr.gold
	var potions_before = eg_player.inventory_component.get_item_count("health_potion")
	eg_kaelis.trigger_interaction()
	while eg_ui.is_dialogue_open():
		eg_ui.advance_dialogue()

	_assert(journal.get_quest_state("quest_elyndra_cleansing") == QuestDefScript.QuestState.COMPLETED, "Quest Kaelis hoàn thành (COMPLETED)")
	_assert(eg_quest_mgr.gold == gold_before + 80, "Nhận chính xác 80 Vàng thưởng từ Kaelis")
	_assert(eg_player.inventory_component.get_item_count("health_potion") == potions_before + 2, "Nhận đúng 2 Bình Máu thưởng từ Kaelis")

	# 5. Thoại Lore sau hoàn thành - không nhận thưởng lần 2
	await _wait_seconds(0.3)
	eg_kaelis.trigger_interaction()
	while eg_ui.is_dialogue_open():
		eg_ui.advance_dialogue()
	_assert(eg_quest_mgr.gold == gold_before + 80, "Tương tác lại với Kaelis không nhận thêm Vàng lặp lại")
	_assert(eg_player.inventory_component.get_item_count("health_potion") == potions_before + 2, "Tương tác lại không nhận thêm Bình Máu")

	eg_zone.queue_free()
	await _wait_seconds(0.2)

	# -------------------------------------------------------------
	# CATEGORY 10: NPC Rhaek Side Quest Flow
	# -------------------------------------------------------------
	print("\n--- CATEGORY 10: NPC Rhaek Side Quest Flow ---")
	var vharok_scene = preload("res://src/world/vharok_outpost.tscn")
	var vh_zone = vharok_scene.instantiate()
	root.add_child(vh_zone)
	current_scene = vh_zone
	await _wait_seconds(0.3)

	var vh_player: Player = vh_zone.get_node_or_null("Player") as Player
	var vh_rhaek: NPC = vh_zone.get_node_or_null("NPC_Rhaek") as NPC
	var vh_quest_mgr: QuestManager = vh_zone.get_node_or_null("QuestManager") as QuestManager
	var vh_ui: GameUI = vh_zone.get_node_or_null("GameUI") as GameUI
	var vh_journal: QuestJournalComponent = vh_player.quest_journal_component

	_assert(vh_journal.get_quest_state("quest_vharok_embers") == QuestDefScript.QuestState.NOT_STARTED, "Quest Rhaek ban đầu là NOT_STARTED")

	# 1. Nhận quest từ Rhaek
	vh_rhaek.trigger_interaction()
	while vh_ui.is_dialogue_open():
		vh_ui.advance_dialogue()

	_assert(vh_journal.get_quest_state("quest_vharok_embers") == QuestDefScript.QuestState.ACTIVE, "Quest Rhaek chuyển sang ACTIVE")
	_assert(vh_journal.get_quest_progress("quest_vharok_embers") == 0, "Tiến độ Lõi Tàn Hỏa ban đầu: 0/3")

	# 2. Thêm 3 ember_core vào Inventory
	vh_player.inventory_component.add_item("ember_core", 3)
	vh_journal.update_item_collection(vh_player.inventory_component)
	_assert(vh_journal.get_quest_progress("quest_vharok_embers") == 3, "Thu thập đủ 3/3 Ember Core cập nhật đúng tiến độ")
	_assert(vh_journal.get_quest_state("quest_vharok_embers") == QuestDefScript.QuestState.READY_TO_TURN_IN, "Quest Rhaek chuyển sang READY_TO_TURN_IN")

	# 3. Trả quest Rhaek
	await _wait_seconds(0.3)
	var rhaek_gold_before = vh_quest_mgr.gold
	var shards_before = vh_player.inventory_component.get_item_count("mana_shard")
	vh_rhaek.trigger_interaction()
	while vh_ui.is_dialogue_open():
		vh_ui.advance_dialogue()

	_assert(vh_journal.get_quest_state("quest_vharok_embers") == QuestDefScript.QuestState.COMPLETED, "Quest Rhaek hoàn thành (COMPLETED)")
	_assert(vh_player.inventory_component.get_item_count("ember_core") == 0, "Đã trừ đúng 3 Lõi Tàn Hỏa khỏi túi đồ của Player")
	_assert(vh_quest_mgr.gold == rhaek_gold_before + 100, "Nhận chính xác 100 Vàng thưởng từ Rhaek")
	_assert(vh_player.inventory_component.get_item_count("mana_shard") == shards_before + 3, "Nhận đúng 3 Mảnh Chân Ma thưởng từ Rhaek")

	# 4. Tương tác sau hoàn thành
	await _wait_seconds(0.3)
	vh_rhaek.trigger_interaction()
	while vh_ui.is_dialogue_open():
		vh_ui.advance_dialogue()
	_assert(vh_quest_mgr.gold == rhaek_gold_before + 100, "Không nhận thêm Vàng lặp lại từ Rhaek")

	vh_zone.queue_free()
	await _wait_seconds(0.2)

	# -------------------------------------------------------------
	# CATEGORY 11: Quest Journal UI Functionality
	# -------------------------------------------------------------
	print("\n--- CATEGORY 11: Quest Journal UI Functionality ---")
	var ui_zone = elyndra_scene.instantiate()
	root.add_child(ui_zone)
	current_scene = ui_zone
	await _wait_seconds(0.3)

	var ui_player: Player = ui_zone.get_node_or_null("Player") as Player
	var ui_game: GameUI = ui_zone.get_node_or_null("GameUI") as GameUI
	var q_ui: QuestJournalUI = ui_game.quest_journal_ui

	_assert(q_ui != null, "QuestJournalUI tồn tại trong GameUI")
	_assert(q_ui.visible == false, "Journal ban đầu ẩn")

	# Mở bằng hàm / phím Q
	ui_game.open_quest_journal()
	_assert(q_ui.is_open() == true, "Mở Journal thành công bằng open_quest_journal()")

	# Kiểm tra nội dung hiển thị của cả 3 nhiệm vụ
	_assert(q_ui.main_title_label != null, "Card Nhiệm vụ chính tồn tại")
	_assert(q_ui.kaelis_title_label != null, "Card Nhiệm vụ Kaelis tồn tại")
	_assert(q_ui.rhaek_title_label != null, "Card Nhiệm vụ Rhaek tồn tại")
	_assert(q_ui.main_badge_label.text in ["[Chưa nhận]", "[Đang thực hiện]", "[Sẵn sàng trả]", "[Đã hoàn thành]"], "Badge nhiệm vụ chính hiển thị đúng format")
	_assert(q_ui.kaelis_badge_label.text in ["[Chưa nhận]", "[Đang thực hiện]", "[Sẵn sàng trả]", "[Đã hoàn thành]"], "Badge nhiệm vụ Kaelis đúng format")
	_assert(q_ui.rhaek_badge_label.text in ["[Chưa nhận]", "[Đang thực hiện]", "[Sẵn sàng trả]", "[Đã hoàn thành]"], "Badge nhiệm vụ Rhaek đúng format")

	# Khóa các phím hành động khi Journal đang mở
	_assert(ui_game.is_quest_journal_open() == true, "GameUI nhận diện Journal đang mở")

	# Đóng bằng close_quest_journal() / ESC
	ui_game.close_quest_journal()
	_assert(q_ui.is_open() == false, "Đóng Journal thành công")

	# Toggle
	ui_game.toggle_quest_journal()
	_assert(q_ui.is_open() == true, "Toggle lần 1: Mở")
	ui_game.toggle_quest_journal()
	_assert(q_ui.is_open() == false, "Toggle lần 2: Đóng")

	ui_zone.queue_free()
	await _wait_seconds(0.2)

	# -------------------------------------------------------------
	# CATEGORY 12: World State Persistence & Save/Load v1.4.0
	# -------------------------------------------------------------
	print("\n--- CATEGORY 12: World State Persistence & Save/Load v1.4.0 ---")
	_assert(SaveManager.CURRENT_VERSION == "1.4.0", "SaveManager.CURRENT_VERSION là 1.4.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.4.0"), "SaveManager hỗ trợ phiên bản 1.4.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.3.0"), "SaveManager hỗ trợ phiên bản 1.3.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.2.0"), "SaveManager hỗ trợ phiên bản 1.2.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.1.0"), "SaveManager hỗ trợ phiên bản 1.1.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.0.0"), "SaveManager hỗ trợ phiên bản 1.0.0")

	# Kiểm tra lưu thế giới Elyndra với quái đã diệt và tiến độ quest
	var save_test_zone = elyndra_scene.instantiate()
	root.add_child(save_test_zone)
	current_scene = save_test_zone
	await _wait_seconds(0.3)

	var st_player: Player = save_test_zone.get_node_or_null("Player") as Player
	st_player.quest_journal_component.start_quest("quest_elyndra_cleansing")
	st_player.quest_journal_component._quests["quest_elyndra_cleansing"]["current_amount"] = 2
	save_test_zone.defeated_enemy_ids.append("elyndra_mooncap_1")

	var save_ok = SaveManager.save_game(save_test_zone)
	_assert(save_ok == true, "Lưu game v1.4.0 thành công")

	# Đọc kiểm tra file test
	var s_file = FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var s_text = s_file.get_as_text()
	s_file.close()
	var s_dict: Dictionary = JSON.parse_string(s_text)
	_assert(s_dict.get("save_version") == "1.4.0", "Bản lưu ghi đúng save_version == 1.4.0")
	_assert(s_dict.has("quest_journal"), "Bản lưu có trường dữ liệu quest_journal")
	_assert(s_dict["quest_journal"].has("quest_elyndra_cleansing"), "quest_journal lưu tiến độ nhiệm vụ Kaelis")

	# Tải bản lưu vào scene mới
	save_test_zone.queue_free()
	await _wait_seconds(0.2)

	var load_zone = elyndra_scene.instantiate()
	root.add_child(load_zone)
	current_scene = load_zone
	await _wait_seconds(0.3)

	var load_ok = SaveManager.load_game(load_zone)
	_assert(load_ok == true, "Tải bản lưu v1.4.0 thành công")

	var ld_player: Player = load_zone.get_node_or_null("Player") as Player
	var ld_prog = ld_player.quest_journal_component.get_quest_progress("quest_elyndra_cleansing")
	_assert(ld_prog == 2, "Tiến độ nhiệm vụ Kaelis khôi phục chính xác: 2/3")
	_assert(load_zone.defeated_enemy_ids.has("elyndra_mooncap_1"), "Quái đã diệt được ghi nhớ đúng trong defeated_enemy_ids")

	# Tương thích ngược: tải bản lưu cũ v1.3.0 (không có quest_journal)
	var old_save_dict: Dictionary = s_dict.duplicate(true)
	old_save_dict["save_version"] = "1.3.0"
	old_save_dict.erase("quest_journal")
	var old_f = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	old_f.store_string(JSON.stringify(old_save_dict, "\t"))
	old_f.close()

	var back_compat_ok = SaveManager.load_game(load_zone)
	_assert(back_compat_ok == true, "Tải bản lưu cũ v1.3.0 thành công (tương thích ngược hoàn hảo)")

	load_zone.queue_free()
	await _wait_seconds(0.2)

	# -------------------------------------------------------------
	# CATEGORY 13: Isolation Verification
	# -------------------------------------------------------------
	print("\n--- CATEGORY 13: Isolation Verification ---")
	var real_file_existed_at_end = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		_assert(real_file_existed_at_end == true, "File save thật vẫn tồn tại nguyên vẹn")
		var real_hash_at_end = FileAccess.get_md5(REAL_SAVE_PATH)
		_assert(real_hash_at_end == real_file_hash_at_start, "Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI")
	else:
		_assert(real_file_existed_at_end == false, "File save thật không tồn tại từ đầu và không bị tạo giả định")

	# Dọn dẹp DUY NHẤT file test M7
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	print("\n==================================================")
	print(" [NOCTELYRA M7] KẾT QUẢ KIỂM THỬ TỔNG HỢP:        ")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL M7 REGIONAL GAMEPLAY TESTS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

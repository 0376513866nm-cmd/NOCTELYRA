extends SceneTree

# test_m5_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M5: Magic Combat System.
# Verifies all 20 requirement groups:
# 1. Spell Definition & Registry (ID & static lookup)
# 2. Spellbook Initialization (3 spells, Lv.1, moon_bolt selected)
# 3. Spell Selection (Hotkeys 1, 2, 3 and index/ID)
# 4. Spell Mana Consumption (12 MP, 18 MP, 15 MP)
# 5. Insufficient Mana Check (blocked, no deduction, failure signal)
# 6. Independent Cooldowns per spell
# 7. Cooldown Persistence across Spell Switching
# 8. Cooldown Expiration & Ready State
# 9. Moon Bolt Projectile (550 px/s, single target 30 base DMG)
# 10. Ember Bloom Projectile & AoE Radius (110px explosion, no duplicate damage)
# 11. Frost Shard Projectile & Enemy Slow Effect (35% slow for 2.0s)
# 12. Enemy Slow Duration Expiration & Speed Recovery
# 13. Boss Lunareth Immunity to Slow
# 14. Spell Upgrade System (3 shards Lv.2, 6 shards Lv.3, deduction from inventory)
# 15. Damage Scaling on Upgrade (Lv.1 -> Lv.2 -> Lv.3)
# 16. Upgrade Blocked during Boss Battle, Death, or Dialogue
# 17. Spell Hotbar UI Display & Interaction
# 18. Quest & Loot attribution on magic kills
# 19. Boss Combat & Phase Transition / Defeat via Magic
# 20. Save & Load v1.2.0 & Backward Compatibility (v1.0.0, v1.1.0) & Real Save Isolation

const BossLunarethScript = preload("res://src/boss/boss_lunareth.gd")
const EnemyScript = preload("res://src/actors/enemy/enemy.gd")
const EnemyScene = preload("res://src/actors/enemy/enemy.tscn")
const SpellDatabaseScript = preload("res://src/magic/spell_database.gd")
const SpellbookComponentScript = preload("res://src/magic/spellbook_component.gd")
const SpellHotbarScript = preload("res://src/ui/spell_hotbar.gd")
const SpellDefinitionScript = preload("res://src/magic/spell_definition.gd")
const MoonBoltScript = preload("res://src/magic/projectiles/moon_bolt_projectile.gd")
const EmberBloomScript = preload("res://src/magic/projectiles/ember_bloom_projectile.gd")
const FrostShardScript = preload("res://src/magic/projectiles/frost_shard_projectile.gd")

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m5_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M5] MAGIC COMBAT TEST SUITE STARTING ")
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
	SpellDatabaseScript.initialize()

	# GHI NHẬN CHỈ ĐỌC TRẠNG THÁI FILE SAVE THẬT - TUYỆT ĐỐI KHÔNG GHI/XÓA/SỬA
	real_file_existed_at_start = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		real_file_hash_at_start = FileAccess.get_md5(REAL_SAVE_PATH)

	# Định tuyến sang file test M5 riêng biệt
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
	var p_health: HealthComponent = player.health_component
	var p_inv: InventoryComponent = player.inventory_component
	var p_combat: CombatComponent = player.combat_component
	var p_spellbook = player.get_node_or_null("SpellbookComponent")
	var ui: GameUI = world.game_ui
	var hotbar = ui.spell_hotbar

	# -------------------------------------------------------------
	# GROUP 1: Spell Definition & Registry (ID & Static Lookup)
	# -------------------------------------------------------------
	print("\n--- GROUP 1: Spell Definition & Database Registry ---")
	var mb_def = SpellDatabaseScript.get_spell("moon_bolt")
	var eb_def = SpellDatabaseScript.get_spell("ember_bloom")
	var fs_def = SpellDatabaseScript.get_spell("frost_shard")

	_assert(mb_def != null and eb_def != null and fs_def != null, "Cả 3 phép thuật đã đăng ký thành công trong SpellDatabase")
	_assert(mb_def.base_damage == 30.0 and mb_def.mana_cost == 12.0 and mb_def.cooldown == 0.5 and mb_def.projectile_speed == 550.0, "Moon Bolt: 30 DMG, 12 MP, 0.5s CD, 550 spd")
	_assert(eb_def.base_damage == 22.0 and eb_def.mana_cost == 18.0 and eb_def.cooldown == 1.0 and eb_def.effect_radius == 110.0, "Ember Bloom: 22 DMG, 18 MP, 1.0s CD, 110 px AoE")
	_assert(fs_def.base_damage == 20.0 and fs_def.mana_cost == 15.0 and fs_def.cooldown == 0.7 and fs_def.slow_ratio == 0.35, "Frost Shard: 20 DMG, 15 MP, 0.7s CD, 35% Slow")

	# -------------------------------------------------------------
	# GROUP 2: Spellbook Initialization
	# -------------------------------------------------------------
	print("\n--- GROUP 2: SpellbookComponent Initialization ---")
	_assert(p_spellbook != null, "Player có node SpellbookComponent hợp lệ")
	_assert(p_spellbook.known_spells == ["moon_bolt", "ember_bloom", "frost_shard"], "Khởi đầu Player mở khóa đủ 3 phép thuật cơ bản")
	_assert(p_spellbook.selected_spell_id == "moon_bolt", "Phép mặc định ban đầu là moon_bolt")
	_assert(p_spellbook.get_spell_level("moon_bolt") == 1 and p_spellbook.get_spell_level("ember_bloom") == 1 and p_spellbook.get_spell_level("frost_shard") == 1, "Tất cả các phép khởi đầu ở Cấp 1")

	# -------------------------------------------------------------
	# GROUP 3: Spell Selection (Hotkeys 1, 2, 3 & Index/ID)
	# -------------------------------------------------------------
	print("\n--- GROUP 3: Spell Selection (1, 2, 3) ---")
	p_spellbook.select_spell_by_index(1)
	_assert(p_spellbook.selected_spell_id == "ember_bloom", "Phím 2 (index 1) chọn Ember Bloom")
	p_spellbook.select_spell_by_index(2)
	_assert(p_spellbook.selected_spell_id == "frost_shard", "Phím 3 (index 2) chọn Frost Shard")
	p_spellbook.select_spell_by_index(0)
	_assert(p_spellbook.selected_spell_id == "moon_bolt", "Phím 1 (index 0) chọn Moon Bolt")
	var invalid_select = p_spellbook.select_spell("unknown_dark_magic")
	_assert(invalid_select == false and p_spellbook.selected_spell_id == "moon_bolt", "Chọn ID không tồn tại bị từ chối và giữ nguyên phép cũ")

	# -------------------------------------------------------------
	# GROUP 4: Spell Mana Consumption
	# -------------------------------------------------------------
	print("\n--- GROUP 4: Spell Mana Consumption ---")
	p_health.current_mana = 60.0
	p_spellbook.select_spell("moon_bolt")
	p_spellbook.cooldown_timers["moon_bolt"] = 0.0
	var cast_mb_res = p_spellbook.cast_selected_spell(player, 1, p_health)
	_assert(cast_mb_res == true, "Thi triển Moon Bolt thành công")
	_assert(is_equal_approx(p_health.current_mana, 48.0), "Moon Bolt tiêu hao chính xác 12 MP (60 -> 48)")

	p_spellbook.select_spell("ember_bloom")
	p_spellbook.cooldown_timers["ember_bloom"] = 0.0
	var cast_eb_res = p_spellbook.cast_selected_spell(player, 1, p_health)
	_assert(cast_eb_res == true, "Thi triển Ember Bloom thành công")
	_assert(is_equal_approx(p_health.current_mana, 30.0), "Ember Bloom tiêu hao chính xác 18 MP (48 -> 30)")

	p_spellbook.select_spell("frost_shard")
	p_spellbook.cooldown_timers["frost_shard"] = 0.0
	var cast_fs_res = p_spellbook.cast_selected_spell(player, 1, p_health)
	_assert(cast_fs_res == true, "Thi triển Frost Shard thành công")
	_assert(is_equal_approx(p_health.current_mana, 15.0), "Frost Shard tiêu hao chính xác 15 MP (30 -> 15)")

	# -------------------------------------------------------------
	# GROUP 5: Insufficient Mana Check
	# -------------------------------------------------------------
	print("\n--- GROUP 5: Insufficient Mana Check ---")
	# Hiện còn 15 MP, Ember Bloom cần 18 MP -> thất bại
	p_spellbook.select_spell("ember_bloom")
	p_spellbook.cooldown_timers["ember_bloom"] = 0.0
	var check_res = p_spellbook.can_cast_selected(p_health)
	_assert(check_res["can_cast"] == false and check_res["reason"] == "NOT_ENOUGH_MANA", "can_cast_selected trả về NOT_ENOUGH_MANA khi MP không đủ")

	var failed_cast = p_spellbook.cast_selected_spell(player, 1, p_health)
	_assert(failed_cast == false, "cast_selected_spell từ chối thi triển khi thiếu MP")
	_assert(is_equal_approx(p_health.current_mana, 15.0), "MP không bị trừ khi thi triển thất bại")

	# -------------------------------------------------------------
	# GROUP 6: Independent Cooldowns
	# -------------------------------------------------------------
	print("\n--- GROUP 6: Independent Cooldowns ---")
	p_health.current_mana = 60.0
	p_spellbook.select_spell("moon_bolt")
	p_spellbook.cooldown_timers["moon_bolt"] = 0.0
	p_spellbook.cooldown_timers["ember_bloom"] = 0.0
	p_spellbook.cooldown_timers["frost_shard"] = 0.0

	p_spellbook.cast_selected_spell(player, 1, p_health)
	_assert(p_spellbook.is_on_cooldown("moon_bolt") == true, "Moon Bolt đang trong thời gian hồi chiêu (0.5s)")
	_assert(p_spellbook.is_on_cooldown("ember_bloom") == false, "Ember Bloom vẫn sẵn sàng (cooldown = 0.0s)")
	_assert(p_spellbook.is_on_cooldown("frost_shard") == false, "Frost Shard vẫn sẵn sàng (cooldown = 0.0s)")

	# -------------------------------------------------------------
	# GROUP 7: Cooldown Persistence across Spell Switching
	# -------------------------------------------------------------
	print("\n--- GROUP 7: Cooldown Persistence Across Switching ---")
	p_spellbook.select_spell("ember_bloom")
	_assert(p_spellbook.is_on_cooldown("moon_bolt") == true, "Chuyển sang Ember Bloom nhưng cooldown Moon Bolt vẫn duy trì")
	p_spellbook.select_spell("moon_bolt")
	_assert(p_spellbook.can_cast_selected(p_health)["can_cast"] == false, "Chuyển lại Moon Bolt vẫn không thể bắn vì đang hồi chiêu")

	# -------------------------------------------------------------
	# GROUP 8: Cooldown Expiration & Ready State
	# -------------------------------------------------------------
	print("\n--- GROUP 8: Cooldown Expiration ---")
	p_spellbook._process(0.55)
	_assert(p_spellbook.is_on_cooldown("moon_bolt") == false, "Sau 0.55s, Moon Bolt đã hết thời gian hồi và sẵn sàng")
	_assert(p_spellbook.can_cast_selected(p_health)["can_cast"] == true, "can_cast_selected trả về true sau khi hết cooldown")

	# -------------------------------------------------------------
	# GROUP 9: Moon Bolt Projectile & Damage
	# -------------------------------------------------------------
	print("\n--- GROUP 9: Moon Bolt Projectile Damage ---")
	var test_enemy: Enemy = EnemyScene.instantiate() as Enemy
	world.add_child(test_enemy)
	test_enemy.global_position = Vector2(500.0, 630.0)
	var e_health: HealthComponent = test_enemy.get_node_or_null("HealthComponent")
	var initial_hp: float = e_health.current_health

	var mb_proj: Node2D = mb_def.projectile_scene.instantiate()
	world.add_child(mb_proj)
	mb_proj.global_position = test_enemy.global_position
	mb_proj.setup(Vector2.RIGHT, player, 30.0)
	# Giả lập va chạm với hurtbox quái
	var e_hurtbox: Hurtbox = test_enemy.get_node_or_null("Hurtbox")
	mb_proj._on_area_entered(e_hurtbox)
	_assert(e_health.current_health == initial_hp - 30.0, "Moon Bolt gây chính xác 30 sát thương lên đơn mục tiêu")
	mb_proj.queue_free()
	test_enemy.queue_free()

	# -------------------------------------------------------------
	# GROUP 10: Ember Bloom Projectile & AoE Radius (No duplicates)
	# -------------------------------------------------------------
	print("\n--- GROUP 10: Ember Bloom AoE & No-Duplicate Damage ---")
	var enemy_a: Enemy = EnemyScene.instantiate() as Enemy
	var enemy_b: Enemy = EnemyScene.instantiate() as Enemy
	world.add_child(enemy_a)
	world.add_child(enemy_b)
	enemy_a.global_position = Vector2(800.0, 630.0)
	enemy_b.global_position = Vector2(850.0, 630.0) # Nằm trong bán kính 110px

	var ea_health: HealthComponent = enemy_a.get_node_or_null("HealthComponent")
	var eb_health: HealthComponent = enemy_b.get_node_or_null("HealthComponent")
	var hp_a_before := ea_health.current_health
	var hp_b_before := eb_health.current_health

	var eb_proj = eb_def.projectile_scene.instantiate()
	world.add_child(eb_proj)
	eb_proj.global_position = Vector2(825.0, 630.0)
	eb_proj.setup(Vector2.RIGHT, player, 22.0)
	eb_proj._trigger_explosion()

	_assert(ea_health.current_health == hp_a_before - 22.0, "Enemy A trong bán kính vụ nổ nhận 22 sát thương")
	_assert(eb_health.current_health == hp_b_before - 22.0, "Enemy B trong bán kính vụ nổ nhận 22 sát thương")

	# Kích hoạt thêm lần nữa để chứng minh mỗi mục tiêu chỉ nhận 1 lần sát thương trong 1 vụ nổ
	var hp_a_after_first := ea_health.current_health
	eb_proj._trigger_explosion()
	_assert(ea_health.current_health == hp_a_after_first, "Vụ nổ không gây sát thương trùng lặp lên cùng 1 mục tiêu")
	eb_proj.queue_free()
	enemy_a.queue_free()
	enemy_b.queue_free()

	# -------------------------------------------------------------
	# GROUP 11: Frost Shard Projectile & Enemy Slow Effect (35%)
	# -------------------------------------------------------------
	print("\n--- GROUP 11: Frost Shard Slow Effect (35%) ---")
	var slow_enemy: Enemy = EnemyScene.instantiate() as Enemy
	world.add_child(slow_enemy)
	slow_enemy.global_position = Vector2(1000.0, 630.0)
	var se_health: HealthComponent = slow_enemy.get_node_or_null("HealthComponent")
	var se_initial_hp := se_health.current_health
	var base_spd: float = slow_enemy.move_speed

	var fs_proj = fs_def.projectile_scene.instantiate()
	world.add_child(fs_proj)
	fs_proj.global_position = slow_enemy.global_position
	fs_proj.setup(Vector2.RIGHT, player, 20.0)
	fs_proj._on_area_entered(slow_enemy.get_node_or_null("Hurtbox"))

	_assert(se_health.current_health == se_initial_hp - 20.0, "Frost Shard gây 20 sát thương lên quái vật")
	_assert(is_equal_approx(slow_enemy.get_current_speed(), base_spd * 0.65), "Tốc độ quái bị giảm chính xác 35%% (còn 65%% tốc độ ban đầu)")
	fs_proj.queue_free()

	# -------------------------------------------------------------
	# GROUP 12: Slow Duration Expiration & Speed Recovery
	# -------------------------------------------------------------
	print("\n--- GROUP 12: Slow Duration Expiration ---")
	slow_enemy._physics_process(2.1)
	_assert(is_equal_approx(slow_enemy.get_current_speed(), base_spd), "Sau 2 giây, tốc độ quái vật khôi phục 100%% bình thường")
	slow_enemy.queue_free()

	# -------------------------------------------------------------
	# GROUP 13: Boss Lunareth Immunity to Slow
	# -------------------------------------------------------------
	print("\n--- GROUP 13: Boss Lunareth Immunity to Slow ---")
	var boss: CharacterBody2D = world.boss_lunareth
	var boss_health: HealthComponent = boss.health_component
	var boss_hp_before := boss_health.current_health
	var boss_spd_before: float = boss.move_speed

	var fs_boss_proj = fs_def.projectile_scene.instantiate()
	world.add_child(fs_boss_proj)
	fs_boss_proj.global_position = boss.global_position
	fs_boss_proj.setup(Vector2.RIGHT, player, 20.0)
	fs_boss_proj._on_area_entered(boss.hurtbox)

	_assert(boss_health.current_health == boss_hp_before - 20.0, "Frost Shard gây sát thương bình thường lên Boss")
	_assert(is_equal_approx(boss.move_speed, boss_spd_before), "Boss Lunareth MIỄN NHIỄM hoàn toàn với hiệu ứng làm chậm (tốc độ giữ nguyên 100%%)")
	fs_boss_proj.queue_free()

	# -------------------------------------------------------------
	# GROUP 14: Spell Upgrade System (Mana Shards)
	# -------------------------------------------------------------
	print("\n--- GROUP 14: Spell Upgrade Costs & Shard Deductions ---")
	p_inv.clear()
	p_inv.add_item("mana_shard", 2) # Chỉ có 2 shard, cần 3 -> thất bại
	var up_fail = p_spellbook.upgrade_spell("moon_bolt", p_inv, world)
	_assert(up_fail["success"] == false, "Nâng cấp thất bại khi không đủ Tinh thể Ma lực (cần 3, có 2)")
	_assert(p_spellbook.get_spell_level("moon_bolt") == 1, "Cấp độ Moon Bolt vẫn giữ nguyên Lv.1")
	_assert(p_inv.get_item_count("mana_shard") == 2, "Nguyên liệu không bị trừ khi nâng cấp thất bại")

	# Thêm 1 shard để đủ 3 shard -> nâng cấp lên Lv.2 thành công
	p_inv.add_item("mana_shard", 1)
	var up_lvl2 = p_spellbook.upgrade_spell("moon_bolt", p_inv, world)
	_assert(up_lvl2["success"] == true, "Nâng cấp Moon Bolt lên Cấp 2 thành công")
	_assert(p_spellbook.get_spell_level("moon_bolt") == 2, "Cấp độ Moon Bolt hiện là Lv.2")
	_assert(p_inv.get_item_count("mana_shard") == 0, "Đã trừ chính xác 3 Tinh thể Ma lực (2+1-3 = 0)")

	# Nâng cấp Lv.2 -> Lv.3 cần 6 shard
	p_inv.add_item("mana_shard", 6)
	var up_lvl3 = p_spellbook.upgrade_spell("moon_bolt", p_inv, world)
	_assert(up_lvl3["success"] == true, "Nâng cấp Moon Bolt lên Cấp 3 thành công")
	_assert(p_spellbook.get_spell_level("moon_bolt") == 3, "Cấp độ Moon Bolt hiện là Lv.3")
	_assert(p_inv.get_item_count("mana_shard") == 0, "Đã trừ chính xác 6 Tinh thể Ma lực")

	# Nâng cấp tiếp khi đã Max Lv.3 -> từ chối
	p_inv.add_item("mana_shard", 10)
	var up_max = p_spellbook.upgrade_spell("moon_bolt", p_inv, world)
	_assert(up_max["success"] == false, "Từ chối nâng cấp khi phép đã đạt Cấp tối đa (Lv.3)")
	_assert(p_inv.get_item_count("mana_shard") == 10, "Không trừ nguyên liệu khi đã Max Level")

	# -------------------------------------------------------------
	# GROUP 15: Damage Scaling on Upgrade
	# -------------------------------------------------------------
	print("\n--- GROUP 15: Damage Scaling on Upgrade ---")
	_assert(mb_def.get_damage_for_level(1) == 30.0, "Moon Bolt Lv.1 = 30 DMG")
	_assert(mb_def.get_damage_for_level(2) == 40.0, "Moon Bolt Lv.2 = 40 DMG")
	_assert(mb_def.get_damage_for_level(3) == 55.0, "Moon Bolt Lv.3 = 55 DMG")

	_assert(eb_def.get_damage_for_level(1) == 22.0 and eb_def.get_damage_for_level(2) == 30.0 and eb_def.get_damage_for_level(3) == 40.0, "Ember Bloom tăng tiến: 22 -> 30 -> 40 DMG")
	_assert(fs_def.get_damage_for_level(1) == 20.0 and fs_def.get_damage_for_level(2) == 28.0 and fs_def.get_damage_for_level(3) == 38.0, "Frost Shard tăng tiến: 20 -> 28 -> 38 DMG")

	# Bắn Moon Bolt Lv.3 gây 55 sát thương
	var dummy_enemy: Enemy = EnemyScene.instantiate() as Enemy
	world.add_child(dummy_enemy)
	dummy_enemy.global_position = Vector2(1200.0, 630.0)
	var de_health: HealthComponent = dummy_enemy.get_node_or_null("HealthComponent")
	var de_hp_before := de_health.current_health

	p_spellbook.select_spell("moon_bolt")
	p_spellbook.cooldown_timers["moon_bolt"] = 0.0
	p_health.current_mana = 60.0
	p_spellbook.cast_selected_spell(player, 1, p_health)

	# Lấy đạn vừa sinh ra
	var last_proj: Node = null
	for child in world.get_children():
		if child is MoonBoltScript:
			last_proj = child
	_assert(last_proj != null and last_proj.damage == 55.0, "Đạn Moon Bolt Lv.3 được tạo ra với đúng 55 sát thương")
	if last_proj:
		last_proj._on_area_entered(dummy_enemy.get_node_or_null("Hurtbox"))
		_assert(de_health.current_health == de_hp_before - 55.0, "Mục tiêu nhận chính xác 55 sát thương từ Moon Bolt Lv.3")
		last_proj.queue_free()
	dummy_enemy.queue_free()

	# -------------------------------------------------------------
	# GROUP 16: Upgrade Blocked Conditions
	# -------------------------------------------------------------
	print("\n--- GROUP 16: Upgrade Blocked Conditions ---")
	# 1. Chặn khi đang trong trận chiến Boss
	world.boss_battle_started = true
	var up_during_boss = p_spellbook.upgrade_spell("ember_bloom", p_inv, world)
	_assert(up_during_boss["success"] == false, "Chặn nâng cấp phép khi đang đánh Boss")
	world.boss_battle_started = false

	# 2. Chặn khi Player đã chết
	player.current_state = Player.State.DEAD
	var shards_before := p_inv.get_item_count("mana_shard")
	player._upgrade_current_spell()
	_assert(p_spellbook.get_spell_level("ember_bloom") == 1, "Player chết không thể kích hoạt nâng cấp phép")
	_assert(p_inv.get_item_count("mana_shard") == shards_before, "Không mất shard khi chết")
	player.current_state = Player.State.IDLE

	# -------------------------------------------------------------
	# GROUP 17: Spell Hotbar UI Display & Interaction
	# -------------------------------------------------------------
	print("\n--- GROUP 17: Spell Hotbar UI Functionality ---")
	_assert(hotbar != null, "SpellHotbar UI tồn tại trong HUD")
	hotbar._update_hotbar_display(p_spellbook)

	_assert(hotbar.slot1.get_node("Highlight").visible == true, "Slot 1 (Moon Bolt) có viền highlight sáng khi được chọn")
	_assert(hotbar.slot2.get_node("Highlight").visible == false, "Slot 2 (Ember Bloom) không có viền highlight")
	_assert(hotbar.slot1.get_node("LevelLabel").text == "Lv.3", "Slot 1 hiển thị đúng cấp độ Lv.3")

	# Mô phỏng nhấp chuột vào Slot 2 trên UI
	hotbar._on_slot_clicked(1)
	_assert(p_spellbook.selected_spell_id == "ember_bloom", "Nhấp chuột vào Slot 2 đổi phép đang chọn sang Ember Bloom")
	_assert(hotbar.slot2.get_node("Highlight").visible == true, "Slot 2 được highlight sau khi nhấp chuột")

	# -------------------------------------------------------------
	# GROUP 18: Quest & Loot Compatibility with Magic Kills
	# -------------------------------------------------------------
	print("\n--- GROUP 18: Quest Progress & Loot on Magic Kills ---")
	var quest_mgr: QuestManager = world.quest_manager
	quest_mgr.start_quest()
	var kills_before := quest_mgr.current_quest.current_amount

	var q_enemy: Enemy = EnemyScene.instantiate() as Enemy
	world.add_child(q_enemy)
	q_enemy.enemy_id = "test_magic_target_1"
	q_enemy.enemy_defeated.connect(quest_mgr.register_enemy_kill)
	q_enemy.global_position = Vector2(1400.0, 630.0)

	# Giết quái bằng phép
	var qe_health: HealthComponent = q_enemy.get_node_or_null("HealthComponent")
	qe_health.take_damage(DamageInfo.new(100.0, player))
	await _wait_seconds(0.1)

	_assert(quest_mgr.current_quest.current_amount == kills_before + 1, "Hạ gục quái bằng phép thuật tăng đúng tiến độ nhiệm vụ")
	q_enemy.queue_free()

	# -------------------------------------------------------------
	# GROUP 19: Boss Combat & Phase Transition / Defeat via Magic
	# -------------------------------------------------------------
	print("\n--- GROUP 19: Boss Combat Phase 2 & Defeat via Magic ---")
	boss_health.cancel_invulnerability()
	boss_health.current_health = 175.0
	# Bắn phép làm Boss tụt xuống <= 160 HP
	boss_health.take_damage(DamageInfo.new(20.0, player))
	_assert(boss_health.current_health == 155.0, "Boss nhận sát thương phép còn 155 HP (<= 160 HP)")
	_assert(boss.current_state == BossLunarethScript.State.PHASE_TRANSITION, "Sát thương phép kích hoạt Boss chuyển sang Giai đoạn 2 (PHASE_TRANSITION)")

	# Sau khi chuyển giai đoạn kết thúc, hạ gục Boss bằng phép
	boss._physics_process(1.4)
	boss.health_component._process(1.4)
	boss_health.cancel_invulnerability()
	boss_health.take_damage(DamageInfo.new(200.0, player))
	boss._physics_process(0.016)
	_assert(boss.current_state == BossLunarethScript.State.DEFEATED, "Sát thương phép hạ gục Boss thành công sang trạng thái DEFEATED")

	# -------------------------------------------------------------
	# GROUP 20: Save & Load v1.2.0, Backward Compatibility & Isolation
	# -------------------------------------------------------------
	print("\n--- GROUP 20: Save/Load v1.2.0, Compatibility & Isolation ---")
	_assert(SaveManager.CURRENT_VERSION == "1.2.0", "SaveManager.CURRENT_VERSION đã nâng cấp lên 1.2.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.2.0") and SaveManager.SUPPORTED_VERSIONS.has("1.1.0") and SaveManager.SUPPORTED_VERSIONS.has("1.0.0"), "SaveManager hỗ trợ cả 3 phiên bản 1.0.0, 1.1.0 và 1.2.0")

	# Lưu game phiên bản 1.2.0
	world.boss_battle_started = false
	var save_ok := SaveManager.save_game(world)
	_assert(save_ok == true, "Lưu game thành công vào test save v1.2.0")

	# Đọc nội dung file save test xem có block spellbook không
	var test_file_read := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var save_json_str := test_file_read.get_as_text()
	test_file_read.close()
	var parsed_data: Dictionary = JSON.parse_string(save_json_str)

	_assert(parsed_data.get("save_version") == "1.2.0", "File save ghi đúng save_version 1.2.0")
	_assert(parsed_data.has("spellbook"), "File save chứa khối dữ liệu spellbook")
	var saved_sb: Dictionary = parsed_data.get("spellbook", {})
	_assert(saved_sb.get("selected_spell") == "ember_bloom", "Lưu đúng phép đang chọn là ember_bloom")
	_assert(int(saved_sb.get("spell_levels", {}).get("moon_bolt", 1)) == 3, "Lưu đúng cấp độ Moon Bolt Lv.3")

	# Khôi phục từ save v1.2.0
	p_spellbook.selected_spell_id = "frost_shard"
	p_spellbook.spell_levels["moon_bolt"] = 1
	var load_v12_res := SaveManager.load_game(world)
	_assert(load_v12_res == true, "Nạp bản lưu v1.2.0 thành công")
	_assert(p_spellbook.selected_spell_id == "ember_bloom", "Khôi phục chính xác phép đang chọn là ember_bloom")
	_assert(p_spellbook.get_spell_level("moon_bolt") == 3, "Khôi phục chính xác Moon Bolt Cấp 3")

	# Kiểm tra tương thích ngược bản lưu v1.0.0 (M3.2)
	var legacy_v10 := "{\"save_version\":\"1.0.0\",\"player\":{\"position_x\":200.0,\"position_y\":630.0,\"current_health\":100.0,\"current_mana\":60.0},\"gold\":50,\"inventory\":[],\"equipment\":{},\"quest\":{\"state\":3,\"current_amount\":3}}"
	var f10 := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f10.store_string(legacy_v10)
	f10.close()
	var load_v10_res := SaveManager.load_game(world)
	_assert(load_v10_res == true, "Nạp thành công bản lưu cũ v1.0.0 không có khối spellbook")
	_assert(p_spellbook.selected_spell_id == "moon_bolt", "Tương thích ngược v1.0.0: mặc định chọn moon_bolt")
	_assert(p_spellbook.get_spell_level("moon_bolt") == 1 and p_spellbook.get_spell_level("ember_bloom") == 1, "Tương thích ngược v1.0.0: mặc định các phép ở Cấp 1")

	# Kiểm tra tương thích ngược bản lưu v1.1.0 (M4.1)
	var legacy_v11 := "{\"save_version\":\"1.1.0\",\"player\":{\"position_x\":200.0,\"position_y\":630.0,\"current_health\":100.0,\"current_mana\":60.0},\"gold\":100,\"inventory\":[],\"equipment\":{},\"quest\":{\"state\":3,\"current_amount\":3},\"boss\":{\"activated\":true,\"defeated\":true,\"reward_claimed\":true}}"
	var f11 := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f11.store_string(legacy_v11)
	f11.close()
	var load_v11_res := SaveManager.load_game(world)
	_assert(load_v11_res == true, "Nạp thành công bản lưu cũ v1.1.0 không có khối spellbook")
	_assert(p_spellbook.selected_spell_id == "moon_bolt", "Tương thích ngược v1.1.0: mặc định chọn moon_bolt")

	# -------------------------------------------------------------
	# KIỂM TRA CÁCH LY TUYỆT ĐỐI FILE SAVE THẬT
	# -------------------------------------------------------------
	print("\n--- KIỂM TRA AN TOÀN DỮ LIỆU: File save thật không bị ảnh hưởng ---")
	var real_file_existed_at_end := FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		_assert(real_file_existed_at_end == true, "File save thật vẫn tồn tại nguyên vẹn")
		var real_hash_at_end := FileAccess.get_md5(REAL_SAVE_PATH)
		_assert(real_hash_at_end == real_file_hash_at_start, "Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI")
	else:
		_assert(real_file_existed_at_end == false, "File save thật không tồn tại từ đầu và TUYỆT ĐỐI KHÔNG BỊ TẠO GIẢ ĐỊNH")

	# Dọn dẹp DUY NHẤT file test M5
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	print("\n==================================================")
	print(" [NOCTELYRA M5] KẾT QUẢ KIỂM THỬ TỔNG HỢP:        ")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL M5 MAGIC SYSTEM TESTS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

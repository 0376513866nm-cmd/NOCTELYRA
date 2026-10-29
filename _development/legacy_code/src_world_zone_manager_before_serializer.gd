class_name ZoneManager
extends RefCounted

## Trình điều phối Quản lý Khu vực & Dịch chuyển Thế giới (Milestone M6)
## Quản lý trạng thái chuyển scene, bảo toàn dữ liệu Player (HP/MP/Inv/Spellbook/Gold/Quest)
## và lưu trữ trạng thái cục bộ của từng vùng đất (pickups, quái đã diệt, boss).

static var current_zone_id: String = "noctis_forest"
static var current_spawn_id: String = "spawn_default"
static var initial_race_id: String = "human"
static var is_transitioning: bool = false
static var is_zone_traveling: bool = false
static var travel_cooldown: float = 0.0

static var session_player_data: Dictionary = {}
static var zone_states: Dictionary = {
	"noctis_forest": {},
	"elyndra_glade": {},
	"vharok_outpost": {}
}

static func is_cooling_down() -> bool:
	return travel_cooldown > 0.0

static func update_cooldown(delta: float) -> void:
	if travel_cooldown > 0.0:
		travel_cooldown = max(0.0, travel_cooldown - delta)

static func get_current_zone_id(world: Node = null) -> String:
	if world and "zone_id" in world and not str(world.get("zone_id")).is_empty():
		return str(world.get("zone_id"))
	return current_zone_id

static func get_zone_scene_path(zone_id: String) -> String:
	return ZoneDefinition.get_zone_scene_path(zone_id)

static func get_zone_display_name(zone_id: String) -> String:
	return ZoneDefinition.get_zone_display_name(zone_id)

static func reset_session() -> void:
	current_zone_id = "noctis_forest"
	current_spawn_id = "spawn_default"
	initial_race_id = "human"
	is_transitioning = false
	is_zone_traveling = false
	travel_cooldown = 0.0
	session_player_data.clear()
	zone_states = {
		"noctis_forest": {},
		"elyndra_glade": {},
		"vharok_outpost": {}
	}

static func extract_player_state(world: Node) -> Dictionary:
	if world == null:
		return {}

	var player: Player = world.get_node_or_null("Player") as Player
	var quest_mgr: QuestManager = world.get_node_or_null("QuestManager") as QuestManager
	if player == null:
		return {}

	var p_health := player.health_component
	var p_inv := player.inventory_component
	var p_eq := player.equipment_component
	var p_sb := player.spellbook_component
	var p_journal := player.quest_journal_component
	var p_stats := player.player_stats_component
	var p_prog := player.progression_component

	return {
		"race_id": p_stats.race_id if p_stats else "human",
		"level": p_prog.level if p_prog else 1,
		"current_exp": p_prog.current_exp if p_prog else 0,
		"claimed_exp_sources": p_prog.claimed_exp_sources.duplicate() if p_prog else [],
		"current_health": p_health.current_health if p_health else 100.0,
		"current_mana": p_health.current_mana if p_health else 60.0,
		"max_health": p_health.max_health if p_health else 100.0,
		"max_mana": p_health.max_mana if p_health else 60.0,
		"gold": quest_mgr.gold if quest_mgr else 0,
		"inventory": p_inv.to_dict() if p_inv else [],
		"equipment": p_eq.to_dict() if p_eq else {},
		"spellbook": p_sb.to_dict() if p_sb else {},
		"quest_journal": p_journal.to_dict() if p_journal else {},
		"quest": {
			"state": int(quest_mgr.current_quest.current_state) if quest_mgr and quest_mgr.current_quest else 0,
			"current_amount": int(quest_mgr.current_quest.current_amount) if quest_mgr and quest_mgr.current_quest else 0
		},
		"killed_enemy_ids": quest_mgr._killed_enemy_ids.duplicate() if quest_mgr else []
	}

static func apply_player_state(world: Node, data: Dictionary) -> void:
	if world == null or data.is_empty():
		return

	var player: Player = world.get_node_or_null("Player") as Player
	var quest_mgr: QuestManager = world.get_node_or_null("QuestManager") as QuestManager
	var ui: GameUI = world.get_node_or_null("GameUI") as GameUI
	if player == null:
		return

	# 0. Khôi phục Chủng tộc & Cấp độ / EXP TRƯỚC TIÊN (M8)
	var p_stats := player.player_stats_component
	var p_prog := player.progression_component

	if p_stats and data.has("race_id"):
		p_stats.set_race(str(data["race_id"]))

	if p_prog:
		p_prog.from_dict({
			"level": int(data.get("level", 1)),
			"current_exp": int(data.get("current_exp", 0)),
			"claimed_exp_sources": data.get("claimed_exp_sources", [])
		})

	# 1. Nạp Trang bị & Túi đồ
	var p_eq := player.equipment_component
	if p_eq and data.has("equipment") and (data["equipment"] is Dictionary):
		p_eq.load_from_dict(data["equipment"])

	var p_inv := player.inventory_component
	if p_inv and data.has("inventory") and (data["inventory"] is Array):
		p_inv.load_from_dict(data["inventory"])

	# Tính lại Max Stats thống nhất sau khi nạp Race, Level và Gear
	if p_stats:
		p_stats.recalculate_stats(false)

	# 2. Nạp Sách Phép
	var p_sb := player.spellbook_component
	if p_sb and data.has("spellbook") and (data["spellbook"] is Dictionary):
		p_sb.from_dict(data["spellbook"])

	# 2b. Nạp Sổ Nhiệm Vụ (M7)
	var p_journal := player.quest_journal_component
	if p_journal and data.has("quest_journal") and (data["quest_journal"] is Dictionary):
		p_journal.from_dict(data["quest_journal"])

	# 3. Nạp Máu và Mana hiện tại (GIỮ NGUYÊN CHÍNH XÁC, không tự hồi đầy!)
	var p_health := player.health_component
	if p_health:
		if data.has("current_health"):
			p_health.current_health = clamp(float(data["current_health"]), 0.0, p_health.max_health)
		if data.has("current_mana"):
			p_health.current_mana = clamp(float(data["current_mana"]), 0.0, p_health.max_mana)
		p_health.emit_signal("health_changed", p_health.current_health, p_health.max_health)
		p_health.emit_signal("mana_changed", p_health.current_mana, p_health.max_mana)

	# 4. Nạp Vàng và Nhiệm vụ
	if quest_mgr:
		if data.has("gold"):
			quest_mgr.gold = max(0, int(data["gold"]))
			quest_mgr.emit_signal("gold_changed", quest_mgr.gold)
		if data.has("quest") and (data["quest"] is Dictionary):
			var q_data: Dictionary = data["quest"]
			if quest_mgr.current_quest:
				quest_mgr.current_quest.current_state = int(q_data.get("state", 0)) as QuestData.State
				quest_mgr.current_quest.current_amount = int(q_data.get("current_amount", 0))
		if data.has("killed_enemy_ids") and (data["killed_enemy_ids"] is Array):
			quest_mgr._killed_enemy_ids = data["killed_enemy_ids"].duplicate()

	# 5. Cập nhật HUD UI
	if ui:
		if p_health:
			ui.update_player_hp(p_health.current_health, p_health.max_health)
			ui.update_player_mp(p_health.current_mana, p_health.max_mana)
		if quest_mgr:
			ui.update_gold(quest_mgr.gold)
			if quest_mgr.current_quest:
				ui.update_quest_info(quest_mgr.current_quest)
		if p_sb and ui.spell_hotbar:
			ui.spell_hotbar.set_spellbook(p_sb)
		if player and ui.inventory_ui:
			ui.inventory_ui.setup_player(player)

static func save_zone_state(zone_id: String, world: Node) -> void:
	if world == null or zone_id.is_empty():
		return

	var state: Dictionary = {
		"collected_pickup_ids": world.get("collected_pickup_ids").duplicate() if "collected_pickup_ids" in world else [],
		"defeated_enemy_ids": world.get("defeated_enemy_ids").duplicate() if "defeated_enemy_ids" in world else [],
		"dropped_pickups": world.get_dropped_pickups_data() if world.has_method("get_dropped_pickups_data") else []
	}

	if zone_id == "noctis_forest":
		state["boss"] = {
			"activated": world.get("boss_battle_started") if "boss_battle_started" in world else false,
			"defeated": world.get("boss_defeated") if "boss_defeated" in world else false,
			"reward_claimed": world.get("boss_reward_claimed") if "boss_reward_claimed" in world else false
		}

	zone_states[zone_id] = state

static func restore_zone_state(zone_id: String, world: Node) -> void:
	if world == null or not zone_states.has(zone_id):
		return

	var state: Dictionary = zone_states[zone_id]
	if state.is_empty():
		return

	var collected: Array = state.get("collected_pickup_ids", [])
	var dropped: Array = state.get("dropped_pickups", [])
	var defeated: Array = state.get("defeated_enemy_ids", [])

	if world.has_method("restore_world_state"):
		world.restore_world_state(collected, dropped, defeated)

	if zone_id == "noctis_forest" and world.has_method("restore_boss_state"):
		var b_dict: Dictionary = state.get("boss", {})
		var b_act: bool = bool(b_dict.get("activated", false))
		var b_def: bool = bool(b_dict.get("defeated", false))
		var b_rew: bool = bool(b_dict.get("reward_claimed", false))
		world.restore_boss_state(b_act, b_def, b_rew)

static func travel_to_zone(target_zone_id: String, target_spawn_id: String, current_world: Node) -> bool:
	if is_transitioning:
		return false
	if not ZoneDefinition.is_valid_zone(target_zone_id):
		push_error("ZoneManager: target_zone_id không hợp lệ: " + target_zone_id)
		return false

	var player: Player = null
	if current_world:
		player = current_world.get_node_or_null("Player") as Player
	if player and player.health_component and not player.health_component.is_alive():
		return false
	if current_world == null or not current_world.is_inside_tree():
		return false
	var tree := current_world.get_tree()
	var scene_path := get_zone_scene_path(target_zone_id)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return false

	# 1. Lưu trạng thái thế giới hiện tại và trích xuất dữ liệu Player
	var cur_id := get_current_zone_id(current_world)
	save_zone_state(cur_id, current_world)
	session_player_data = extract_player_state(current_world)

	# 2. Thiết lập cờ trạng thái
	is_transitioning = true
	is_zone_traveling = true
	current_zone_id = target_zone_id
	current_spawn_id = target_spawn_id if not target_spawn_id.is_empty() else ZoneDefinition.get_default_spawn(target_zone_id)

	# Input callbacks (including touch controls) must finish before their scene is freed.
	var change_scene := func() -> void:
		var error := tree.change_scene_to_packed(packed)
		if error != OK:
			is_transitioning = false
			is_zone_traveling = false
			current_zone_id = cur_id
			push_error("Zone travel failed: " + error_string(error))
	change_scene.call_deferred()
	return true

static func on_zone_entered(world: Node, restore_state: bool = true) -> void:
	if world == null:
		return

	var z_id := get_current_zone_id(world)
	current_zone_id = z_id

	# 1. Nếu đang trong tiến trình dịch chuyển giữa các khu vực: Áp dụng dữ liệu bảo toàn
	if is_zone_traveling:
		apply_player_state(world, session_player_data)
		restore_zone_state(z_id, world)

		# Đặt Player vào đúng vị trí ZoneSpawnPoint
		_place_player_at_spawn(world, current_spawn_id)

		is_zone_traveling = false
		is_transitioning = false
		travel_cooldown = 1.5 # Grace cooldown chống ping-pong lặp tức thì
	else:
		# Vào khu vực thông thường: phục hồi trạng thái khu vực nếu có sẵn trong bộ nhớ
		if restore_state and zone_states.has(z_id) and not zone_states[z_id].is_empty():
			restore_zone_state(z_id, world)

	# 2. Cập nhật UI thông tin khu vực
	var ui: GameUI = world.get_node_or_null("GameUI") as GameUI
	if ui:
		if ui.has_method("set_current_zone"):
			ui.set_current_zone(z_id)
		if ui.has_method("show_zone_banner"):
			ui.show_zone_banner(get_zone_display_name(z_id))

static func _place_player_at_spawn(world: Node, spawn_id: String) -> void:
	var player: Player = world.get_node_or_null("Player") as Player
	if player == null:
		return

	var target_pos := Vector2.ZERO
	var facing := 1
	var found := false

	# Tìm kiếm node ZoneSpawnPoint có spawn_point_id khớp
	var spawn_points = world.get_tree().get_nodes_in_group(GameGroups.ZONE_SPAWN_POINTS)
	for sp in spawn_points:
		if sp is ZoneSpawnPoint and sp.spawn_point_id == spawn_id:
			target_pos = sp.global_position
			facing = sp.facing_direction
			found = true
			break

	# Nếu không tìm thấy spawn cụ thể, tìm spawn_default
	if not found:
		for sp in spawn_points:
			if sp is ZoneSpawnPoint and sp.spawn_point_id == "spawn_default":
				target_pos = sp.global_position
				facing = sp.facing_direction
				found = true
				break

	if found:
		player.global_position = target_pos
		player.reset_physics_interpolation()
		player.spawn_position = target_pos
		player.facing_direction = facing
		if player.sprite_root:
			player.sprite_root.scale.x = float(facing)

		# Cập nhật camera ngay lập tức tới vị trí spawn mới (chống trượt hoặc nhìn ngoài biên)
		var cam: Camera2D = world.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.global_position = target_pos
			cam.reset_smoothing()

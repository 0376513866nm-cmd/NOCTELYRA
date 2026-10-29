class_name SaveManager
extends RefCounted

## Save schema 2.0: Player dùng chung schema với zone travel thông qua
## PlayerStateSerializer. Vẫn đọc được toàn bộ save 1.0–1.5.

const DEFAULT_SAVE_PATH := "user://noctelyra_slot1.json"
const CURRENT_VERSION := "2.0.0"
const SUPPORTED_VERSIONS: Array[String] = [
	"1.0.0", "1.1.0", "1.2.0", "1.3.0", "1.4.0", "1.5.0", CURRENT_VERSION
]

static var custom_save_path := ""
static var should_load_on_start := false
static var simulate_tmp_write_error := false
static var simulate_backup_error := false
static var simulate_replace_error := false

static func get_save_path() -> String:
	return custom_save_path if not custom_save_path.is_empty() else DEFAULT_SAVE_PATH

static func get_tmp_path() -> String:
	return get_save_path() + ".tmp"

static func get_bak_path() -> String:
	return get_save_path() + ".bak"

static func has_save() -> bool:
	return not _read_save_data().is_empty()

static func delete_save() -> bool:
	var success := true
	for path in [get_save_path(), get_tmp_path(), get_bak_path()]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			success = false
	return success

static func is_boss_combat_active(world: Node) -> bool:
	if world == null:
		return false
	if "boss_battle_started" in world and bool(world.get("boss_battle_started")):
		return true
	var boss = world.get_node_or_null("BossLunareth")
	if boss and is_instance_valid(boss) and "current_state" in boss:
		var state := int(boss.get("current_state"))
		return state != 0 and state != 7
	return false

static func save_game(world: Node) -> bool:
	if world == null or ZoneManager.is_transitioning or is_boss_combat_active(world):
		return false
	var player := world.get_node_or_null("Player") as Player
	if player == null:
		return false

	var zone_id := ZoneManager.get_current_zone_id(world)
	ZoneManager.save_zone_state(zone_id, world)
	var player_state := PlayerStateSerializer.capture(world)
	if player_state.is_empty():
		return false

	var save_data := {
		"save_version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"current_zone_id": zone_id,
		"player_position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		},
		"player_state": player_state,
		"zone_states": ZoneManager.zone_states.duplicate(true)
	}
	if not _write_atomic(JSON.stringify(save_data, "\t")):
		return false
	var ui := world.get_node_or_null("GameUI") as GameUI
	if ui:
		ui.show_notification("Đã lưu tiến trình game thành công!")
	return true

static func load_game(world: Node) -> bool:
	if world == null:
		return false
	var data := _read_save_data()
	if data.is_empty():
		return false
	var player := world.get_node_or_null("Player") as Player
	var quest_manager := world.get_node_or_null("QuestManager") as QuestManager
	if player == null:
		return false

	var zone_id := str(data.get("current_zone_id", ZoneDefinition.ZONE_NOCTIS_FOREST))
	if not ZoneDefinition.is_valid_zone(zone_id):
		zone_id = ZoneDefinition.ZONE_NOCTIS_FOREST
	ZoneManager.current_zone_id = zone_id
	_load_zone_states(data)

	var player_state := _extract_player_state(data)
	if not PlayerStateSerializer.apply(world, player_state):
		return false
	_restore_player_position(player, data)
	ZoneManager.restore_zone_state(zone_id, world)

	var zone_state: Dictionary = ZoneManager.zone_states.get(zone_id, {})
	if quest_manager:
		for defeated_id in zone_state.get("defeated_enemy_ids", []):
			var stable_id := str(defeated_id)
			if not stable_id in quest_manager._killed_enemy_ids:
				quest_manager._killed_enemy_ids.append(stable_id)

	var gate := world.get_node_or_null("MagicGate") as MagicGate
	if gate:
		gate.update_quest_status()

	var ui := world.get_node_or_null("GameUI") as GameUI
	if ui:
		ui.update_quest_info()
		var current_gold: int = 0
		if player and player.wallet_component:
			current_gold = player.wallet_component.gold
		elif quest_manager:
			current_gold = quest_manager.gold
		ui.update_gold(current_gold)
		ui.set_current_zone(zone_id)
		ui.update_quest_journal_ui()
		ui.show_notification("Đã tải bản lưu thành công!")
	return true

static func get_save_zone_id() -> String:
	var data := _read_save_data()
	var zone_id := str(data.get("current_zone_id", ZoneDefinition.ZONE_NOCTIS_FOREST))
	return zone_id if ZoneDefinition.is_valid_zone(zone_id) else ZoneDefinition.ZONE_NOCTIS_FOREST

static func get_save_zone_scene_path() -> String:
	return ZoneDefinition.get_zone_scene_path(get_save_zone_id())

static func _read_save_data() -> Dictionary:
	var path := get_save_path()
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		return {}
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	var data: Dictionary = json.data
	var version := str(data.get("save_version", ""))
	if not version in SUPPORTED_VERSIONS:
		return {}
	if version == CURRENT_VERSION and not (data.get("player_state", null) is Dictionary):
		return {}
	if version != CURRENT_VERSION and not (data.get("player", null) is Dictionary):
		return {}
	return data

static func _extract_player_state(data: Dictionary) -> Dictionary:
	if data.get("player_state", null) is Dictionary:
		return (data["player_state"] as Dictionary).duplicate(true)

	var legacy_player: Dictionary = data.get("player", {})
	var progression: Dictionary = data.get("progression", legacy_player.get("progression", {}))
	var zone_id := str(data.get("current_zone_id", ZoneDefinition.ZONE_NOCTIS_FOREST))
	var zone_state: Dictionary = {}
	if data.get("zone_states", null) is Dictionary:
		zone_state = data["zone_states"].get(zone_id, {})
	return {
		"race_id": progression.get("race_id", legacy_player.get("race_id", "human")),
		"level": progression.get("level", 1),
		"current_exp": progression.get("current_exp", 0),
		"claimed_exp_sources": progression.get("claimed_exp_sources", []),
		"current_health": legacy_player.get("current_health", 100.0),
		"current_mana": legacy_player.get("current_mana", 60.0),
		"gold": data.get("gold", 0),
		"inventory": data.get("inventory", []),
		"equipment": data.get("equipment", {}),
		"spellbook": data.get("spellbook", {}),
		"quest_journal": data.get("quest_journal", {}),
		"legacy_quest": data.get("quest", {}),
		"killed_enemy_ids": zone_state.get("defeated_enemy_ids", data.get("defeated_enemy_ids", []))
	}

static func _load_zone_states(data: Dictionary) -> void:
	if data.get("zone_states", null) is Dictionary:
		ZoneManager.zone_states = (data["zone_states"] as Dictionary).duplicate(true)
		return
	var legacy_state := {
		"collected_pickup_ids": data.get("collected_pickup_ids", []),
		"dropped_pickups": data.get("dropped_pickups", []),
		"defeated_enemy_ids": data.get("defeated_enemy_ids", [])
	}
	if data.get("boss", null) is Dictionary:
		legacy_state["boss"] = data["boss"]
	ZoneManager.zone_states = {ZoneDefinition.ZONE_NOCTIS_FOREST: legacy_state}

static func _restore_player_position(player: Player, data: Dictionary) -> void:
	var position_data: Dictionary
	if data.get("player_position", null) is Dictionary:
		position_data = data["player_position"]
	else:
		position_data = data.get("player", {})
	var raw_x = position_data.get("x", position_data.get("position_x", player.global_position.x))
	var raw_y = position_data.get("y", position_data.get("position_y", player.global_position.y))
	var x := float(raw_x) if typeof(raw_x) in [TYPE_FLOAT, TYPE_INT] else player.global_position.x
	var y := float(raw_y) if typeof(raw_y) in [TYPE_FLOAT, TYPE_INT] else player.global_position.y
	if not is_finite(x):
		x = 180.0
	if not is_finite(y):
		y = 630.0
	player.global_position = Vector2(clamp(x, 50.0, 6200.0), clamp(y, 100.0, 700.0))
	player.reset_physics_interpolation()

static func _write_atomic(json_text: String) -> bool:
	var save_path := get_save_path()
	var tmp_path := get_tmp_path()
	var backup_path := get_bak_path()
	if simulate_tmp_write_error:
		return false
	var tmp := FileAccess.open(tmp_path, FileAccess.WRITE)
	if tmp == null:
		return false
	tmp.store_string(json_text)
	tmp.flush()
	tmp.close()
	var verify := FileAccess.open(tmp_path, FileAccess.READ)
	if verify == null:
		return false
	var parsed := JSON.new()
	var valid := parsed.parse(verify.get_as_text()) == OK and parsed.data is Dictionary
	verify.close()
	if not valid:
		DirAccess.remove_absolute(tmp_path)
		return false

	var had_previous := FileAccess.file_exists(save_path)
	if had_previous:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		if simulate_backup_error or DirAccess.copy_absolute(save_path, backup_path) != OK:
			DirAccess.remove_absolute(tmp_path)
			return false
		if DirAccess.remove_absolute(save_path) != OK:
			DirAccess.remove_absolute(tmp_path)
			return false

	var replace_error := ERR_CANT_CREATE if simulate_replace_error else DirAccess.rename_absolute(tmp_path, save_path)
	if replace_error != OK:
		if had_previous and FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(backup_path, save_path)
		if FileAccess.file_exists(tmp_path):
			DirAccess.remove_absolute(tmp_path)
		return false
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	return true

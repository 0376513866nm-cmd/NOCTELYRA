class_name ZoneManager
extends RefCounted

## Điều phối chuyển vùng. Serialization của Player được giao cho
## PlayerStateSerializer để save/load và zone travel dùng chung một schema.

static var current_zone_id := ZoneDefinition.ZONE_NOCTIS_FOREST
static var current_spawn_id := "spawn_default"
static var initial_race_id := "human"
static var is_transitioning := false
static var is_zone_traveling := false
static var travel_cooldown := 0.0
static var session_player_data: Dictionary = {}
static var zone_states: Dictionary = {}

static func is_cooling_down() -> bool:
	return travel_cooldown > 0.0

static func update_cooldown(delta: float) -> void:
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
	current_zone_id = ZoneDefinition.ZONE_NOCTIS_FOREST
	current_spawn_id = "spawn_default"
	initial_race_id = "human"
	is_transitioning = false
	is_zone_traveling = false
	travel_cooldown = 0.0
	session_player_data.clear()
	zone_states.clear()
	_ensure_zone_states()

static func _ensure_zone_states() -> void:
	for definition in ContentRegistry.catalog().zones:
		if definition and not zone_states.has(definition.zone_id):
			zone_states[definition.zone_id] = {}

static func extract_player_state(world: Node) -> Dictionary:
	return PlayerStateSerializer.capture(world)

static func apply_player_state(world: Node, data: Dictionary) -> void:
	PlayerStateSerializer.apply(world, data)

static func save_zone_state(zone_id: String, world: Node) -> void:
	if world == null or zone_id.is_empty():
		return
	_ensure_zone_states()
	var state: Dictionary = {
		"collected_pickup_ids": world.get("collected_pickup_ids").duplicate() if "collected_pickup_ids" in world else [],
		"defeated_enemy_ids": world.get("defeated_enemy_ids").duplicate() if "defeated_enemy_ids" in world else [],
		"dropped_pickups": world.get_dropped_pickups_data() if world.has_method("get_dropped_pickups_data") else []
	}
	if zone_id == ZoneDefinition.ZONE_NOCTIS_FOREST:
		state["boss"] = {
			"activated": world.get("boss_battle_started") if "boss_battle_started" in world else false,
			"defeated": world.get("boss_defeated") if "boss_defeated" in world else false,
			"reward_claimed": world.get("boss_reward_claimed") if "boss_reward_claimed" in world else false
		}
	zone_states[zone_id] = state

static func restore_zone_state(zone_id: String, world: Node) -> void:
	if world == null:
		return
	_ensure_zone_states()
	var state: Dictionary = zone_states.get(zone_id, {})
	if state.is_empty():
		return
	if world.has_method("restore_world_state"):
		world.restore_world_state(
			state.get("collected_pickup_ids", []),
			state.get("dropped_pickups", []),
			state.get("defeated_enemy_ids", [])
		)
	if zone_id == ZoneDefinition.ZONE_NOCTIS_FOREST and world.has_method("restore_boss_state"):
		var boss: Dictionary = state.get("boss", {})
		world.restore_boss_state(
			bool(boss.get("activated", false)),
			bool(boss.get("defeated", false)),
			bool(boss.get("reward_claimed", false))
		)

static func travel_to_zone(target_zone_id: String, target_spawn_id: String, current_world: Node) -> bool:
	if is_transitioning or not ZoneDefinition.is_valid_zone(target_zone_id):
		return false
	if current_world == null or not current_world.is_inside_tree():
		return false
	var player := current_world.get_node_or_null("Player") as Player
	if player and player.health_component and not player.health_component.is_alive():
		return false
	var scene := load(get_zone_scene_path(target_zone_id)) as PackedScene
	if scene == null:
		return false

	var previous_zone := get_current_zone_id(current_world)
	save_zone_state(previous_zone, current_world)
	session_player_data = extract_player_state(current_world)
	is_transitioning = true
	is_zone_traveling = true
	current_zone_id = target_zone_id
	current_spawn_id = target_spawn_id if not target_spawn_id.is_empty() else ZoneDefinition.get_default_spawn(target_zone_id)
	var tree := current_world.get_tree()
	var change_scene := func() -> void:
		var error := tree.change_scene_to_packed(scene)
		if error != OK:
			is_transitioning = false
			is_zone_traveling = false
			current_zone_id = previous_zone
			push_error("Zone travel failed: " + error_string(error))
	change_scene.call_deferred()
	return true

static func on_zone_entered(world: Node, restore_state: bool = true) -> void:
	if world == null:
		return
	_ensure_zone_states()
	var zone_id := get_current_zone_id(world)
	current_zone_id = zone_id
	if is_zone_traveling:
		apply_player_state(world, session_player_data)
		restore_zone_state(zone_id, world)
		_place_player_at_spawn(world, current_spawn_id)
		is_zone_traveling = false
		is_transitioning = false
		travel_cooldown = 1.5
	elif restore_state:
		restore_zone_state(zone_id, world)

	var ui := world.get_node_or_null("GameUI") as GameUI
	if ui:
		ui.set_current_zone(zone_id)
		ui.show_zone_banner(get_zone_display_name(zone_id))

static func _place_player_at_spawn(world: Node, spawn_id: String) -> void:
	var player := world.get_node_or_null("Player") as Player
	if player == null:
		return
	var target_position := Vector2.ZERO
	var facing := 1
	var found := false
	var spawn_points = world.get_tree().get_nodes_in_group(GameGroups.ZONE_SPAWN_POINTS)
	for spawn in spawn_points:
		if spawn is ZoneSpawnPoint and spawn.spawn_point_id == spawn_id:
			target_position = spawn.global_position
			facing = spawn.facing_direction
			found = true
			break
	if not found:
		for spawn in spawn_points:
			if spawn is ZoneSpawnPoint and spawn.spawn_point_id == "spawn_default":
				target_position = spawn.global_position
				facing = spawn.facing_direction
				found = true
				break
	if not found:
		return
	player.global_position = target_position
	player.reset_physics_interpolation()
	player.spawn_position = target_position
	player.facing_direction = facing
	if player.sprite_root:
		player.sprite_root.scale.x = float(facing)
	var camera := world.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.global_position = target_position
		camera.reset_smoothing()

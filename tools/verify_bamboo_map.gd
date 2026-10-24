extends SceneTree
## Integration checks use real physics queries and instantiated gameplay scenes.

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_verify")


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		_failures += 1


func _verify() -> void:
	var packed := load("res://src/world/noctis_forest.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var world := packed.instantiate() as Node2D
	root.add_child(world)
	current_scene = world
	for i in range(12):
		await physics_frame
	var terrain := world.get_node("Geometry/NoctisTerrain") as StaticBody2D
	var space := world.get_world_2d().direct_space_state
	var surfaces_ok := true
	var worst_error: float = 0.0
	for x in range(5, 6296, 17):
		var query := PhysicsRayQueryParameters2D.create(Vector2(x, 100), Vector2(x, 850), 1)
		# The quest gate is an intentional wall, not part of the soil contour.
		query.exclude = [world.get_node("MagicGate").get_rid(), world.get_node("Geometry/ArenaBarrier").get_rid()]
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty() or hit.collider != terrain:
			surfaces_ok = false
		else:
			var error: float = absf(hit.position.y - terrain.surface_y_at(float(x)))
			worst_error = maxf(worst_error, error)
			if error > 0.15:
				surfaces_ok = false
	_check(surfaces_ok, "371 surface samples hit the visible terrain; worst error = %.4f px" % worst_error)
	var geometry := world.get_node("Geometry")
	_check(geometry.get_child_count() == 4, "Only the new ground, two boundary walls and arena gate remain")
	var player := world.get_node("Player") as CharacterBody2D
	_check(player.is_on_floor() and absf(player.position.y - 632.0) < 2.0, "Player starts grounded at the home clearing")
	var cottage := world.get_node("MoonlightCottage")
	_check(cottage.get_node_or_null("SanctuaryArea") != null, "Healing area retained in bamboo cottage")
	var hp = player.health_component
	hp.current_health = 50
	cottage._player_inside = player
	cottage._process(1.0)
	_check(hp.current_health > 50, "Home still heals player")
	var npc := world.get_node("NPC_Elyra")
	_check(npc.npc_name == "Eiran" and npc.has_method("trigger_interaction"), "Eiran dialogue and quest interaction preserved")
	var cycle := world.get_node("DayNightCycle")
	cycle.set_time_phase("night")
	await process_frame
	var lamp := world.get_node("BambooGrove/StoneLantern1070/LanternLight") as PointLight2D
	_check(lamp.energy > 0.5, "Stone lanterns illuminate at night")
	cycle.set_time_phase("day")
	await process_frame
	_check(lamp.energy < 0.05, "Stone lanterns dim in daylight")
	var pickup := world.get_node_or_null("ForestPickup_Shard2")
	_check(pickup != null and not pickup.get_node("Label").visible, "Ground loot labels do not cover scenery")
	var icon := pickup.get_node("IconSprite") as Sprite2D
	_check(maxf(icon.texture.get_width() * icon.scale.x, icon.texture.get_height() * icon.scale.y) <= 22.1, "Loot visual size bounded to 22 px")
	print("BAMBOO MAP: ", "PASS" if _failures == 0 else "FAIL", " (", _failures, " failures)")
	quit(0 if _failures == 0 else 1)

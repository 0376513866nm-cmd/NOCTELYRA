extends SceneTree

func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	SaveManager.custom_save_path = "res://artifacts/game_bugfix_review/save_snapshot.json"
	ZoneManager.reset_session()
	SaveManager.should_load_on_start = true
	print("PROBE: Continue snapshot")
	change_scene_to_file(SaveManager.get_save_zone_scene_path())
	for i in range(12):
		await process_frame
	var world := current_scene
	print("PROBE: Continue loaded ", world.name)
	for target in ["elyndra_glade", "vharok_outpost", "elyndra_glade", "noctis_forest"]:
		print("PROBE: travel to ", target)
		ZoneManager.travel_cooldown = 0.0
		if not ZoneManager.travel_to_zone(target, "spawn_default", current_scene):
			quit(1)
			return
		for i in range(12):
			await process_frame
		print("PROBE: entered ", current_scene.name, " transitioning=", ZoneManager.is_transitioning)
	print("PROBE: complete")
	quit()

extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1440, 720)
	var scene: Node2D = load("res://src/world/noctis_forest.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var player: Player = scene.get_node("Player")
	player.get_node("RemoteTransform2D").update_position = false
	var camera: Camera2D = scene.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.position = Vector2(885, 535)
	camera.zoom = Vector2(1.6, 1.6)
	camera.reset_smoothing()
	scene.get_node("GameUI").visible = false
	var cycle: DayNightCycle = scene.get_node("DayNightCycle")
	cycle.set_time_phase("day")
	cycle.is_paused = true
	player.position = Vector2(740, 632)
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	for i in range(30):
		await physics_frame
		await process_frame
	DirAccess.make_dir_recursive_absolute("res://artifacts/low_hop/game_frames")
	Input.action_press("move_right")
	var rows: Array = []
	for tick in range(180):
		if tick == 80:
			Input.action_release("move_right")
			Input.action_press("move_left")
		if tick == 160:
			Input.action_release("move_left")
		await physics_frame
		await process_frame
		rows.append({"tick":tick,"x":player.position.x,"y":player.position.y,"state":player._get_state_name(player.current_state),"animation":player.anim_player.assigned_animation,"frame":player.hop_sprite.frame})
		if tick % 2 == 0:
			RenderingServer.force_draw()
			var picture := root.get_texture().get_image()
			picture.resize(960, 480, Image.INTERPOLATE_LANCZOS)
			picture.save_png("res://artifacts/low_hop/game_frames/frame_%03d.png" % (tick / 2))
	var report := FileAccess.open("res://artifacts/low_hop/map_capture.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(rows, "\t"))
	Input.action_release("move_right")
	Input.action_release("move_left")
	quit()

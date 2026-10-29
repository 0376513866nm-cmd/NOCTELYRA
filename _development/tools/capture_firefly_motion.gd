extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var world := (load("res://src/world/noctis_forest.tscn") as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	root.size = Vector2i(1280, 720)
	world.get_node("DayNightCycle").set_time_phase("night")
	world.get_node("DayNightCycle").is_paused = true
	await create_timer(0.3).timeout
	world.get_node("Player/RemoteTransform2D").update_position = false
	var camera := world.get_node("Camera2D") as Camera2D
	camera.position = Vector2(850, 500)
	camera.zoom = Vector2.ONE
	camera.reset_smoothing()
	await create_timer(0.2).timeout
	var flies = world.get_node("BambooGrove/Fireflies")
	var before: float = flies._flight_time
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://artifacts/fireflies_motion_before.png")
	await create_timer(1.5).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://artifacts/fireflies_motion_after.png")
	var after: float = flies._flight_material.get_shader_parameter("flight_time")
	print("Flight animation advanced: ", after - before, " seconds; insects: ", flies.emission_points.size())
	quit(0 if after - before > 1.4 else 1)

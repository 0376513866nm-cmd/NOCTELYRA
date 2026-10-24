extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var packed := load("res://src/world/noctis_forest.tscn") as PackedScene
	if packed == null:
		push_error("Could not load Noctis Forest")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	root.size = Vector2i(1280, 720)
	var cycle = scene.get_node("DayNightCycle")
	cycle.set_time_phase("day")
	cycle.is_paused = true
	var camera := scene.get_node_or_null("Camera2D") as Camera2D
	camera.zoom = Vector2.ONE
	for i in range(8):
		await process_frame
	scene.get_node("GameUI/ZoneBanner").visible = false
	_save_view("res://artifacts/noctis_map_preview.png")

	var remote := scene.get_node_or_null("Player/RemoteTransform2D") as RemoteTransform2D
	if remote:
		remote.update_position = false
	for shot in [[Vector2(3000, 600), "res://artifacts/noctis_map_forest.png"], [Vector2(5200, 600), "res://artifacts/noctis_map_arena.png"]]:
		camera.position = shot[0]
		camera.reset_smoothing()
		for i in range(3):
			await process_frame
		_save_view(shot[1])
	camera.position = Vector2(900, 450)
	camera.zoom = Vector2(0.6, 0.6)
	camera.reset_smoothing()
	for i in range(4):
		await process_frame
	_save_view("res://artifacts/bamboo_map_zoom_out.png")
	camera.position = Vector2(350, 520)
	camera.zoom = Vector2(2, 2)
	camera.reset_smoothing()
	for i in range(4):
		await process_frame
	_save_view("res://artifacts/bamboo_map_zoom_in.png")
	cycle.set_time_phase("night")
	camera.position = Vector2(850, 500)
	camera.zoom = Vector2.ONE
	camera.reset_smoothing()
	for i in range(4):
		await process_frame
	_save_view("res://artifacts/bamboo_map_night.png")
	quit()


func _save_view(path: String) -> void:
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save preview: %s" % error_string(error))
	else:
		print("Saved preview to ", ProjectSettings.globalize_path(path))


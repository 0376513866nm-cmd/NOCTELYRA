extends SceneTree
## Rendered, uncapped benchmark. Run in a foreground window, never --headless.

var world: Node
var camera: Camera2D
var report: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("FPS benchmark requires a rendered window, not --headless.")
		quit(1)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1440, 720)
	world = load("res://src/world/noctis_forest.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await RenderingServer.frame_post_draw
	if not _validate_art(world):
		push_error("Artwork failed to build. Refusing to report FPS for an incomplete scene.")
		quit(1)
		return
	world.get_node("Player/RemoteTransform2D").update_position = false
	camera = world.get_node("Camera2D")
	world.get_node("DayNightCycle").is_paused = true
	var cases := [
		["home_day", 400.0, 1.0, "day", "full"],
		["forest_day", 3000.0, 1.0, "day", "full"],
		["wide_night", 900.0, 0.6, "night", "full"],
		["home_no_lights", 400.0, 1.0, "day", "no_lights"],
		["home_no_backdrop", 400.0, 1.0, "day", "no_backdrop"],
		["home_no_grove", 400.0, 1.0, "day", "no_grove"],
	]
	for entry in cases:
		await _measure(entry)
	var suffix: String = "latest"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		suffix = args[0].validate_filename()
	var path := "res://artifacts/bamboo_fps_%s.json" % suffix
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write benchmark report.")
		quit(1)
		return
	file.store_string(JSON.stringify({"renderer": RenderingServer.get_video_adapter_name(), "arguments": OS.get_cmdline_args(), "resolution": "1440x720", "vsync": false, "samples": report}, "\t"))
	print("REPORT ", ProjectSettings.globalize_path(path))
	quit()

func _measure(entry: Array) -> void:
	var grove := world.get_node("BambooGrove")
	grove.visible = entry[4] != "no_grove"
	grove.get_node("ParallaxBackground").visible = entry[4] not in ["no_backdrop", "no_grove"]
	world.get_node("DayNightCycle").set_time_phase(entry[3])
	_set_lights(world, entry[4] != "no_lights")
	camera.zoom = Vector2.ONE * float(entry[2])
	camera.position = Vector2(float(entry[1]), 500)
	camera.reset_smoothing()
	var started := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started < 1500000:
		await process_frame
	var durations: Array[float] = []
	var calls := 0.0
	var primitives := 0.0
	var cpu := 0.0
	started = Time.get_ticks_usec()
	var last := started
	while Time.get_ticks_usec() - started < 3500000:
		# Exercise scrolling as well as the stationary render path.
		camera.position.x = float(entry[1]) + sin(float(Time.get_ticks_usec() - started) / 1000000.0) * 90.0
		await process_frame
		var now := Time.get_ticks_usec()
		durations.append(float(now - last) / 1000.0)
		last = now
		calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		cpu += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var count := durations.size()
	var total := 0.0
	for duration in durations:
		total += duration
	durations.sort()
	var result := {"case": entry[0], "fps": snappedf(float(count) * 1000.0 / total, 0.1), "mean_ms": snappedf(total / count, 0.01), "p95_ms": snappedf(durations[int(count * 0.95)], 0.01), "p99_ms": snappedf(durations[mini(int(count * 0.99), count - 1)], 0.01), "draw_calls": roundi(calls / count), "primitives": roundi(primitives / count), "process_ms": snappedf(cpu / count, 0.01), "frames": count}
	report.append(result)
	print(JSON.stringify(result))

func _set_lights(node: Node, enabled: bool) -> void:
	if node is Light2D:
		node.enabled = enabled
	for child in node.get_children():
		_set_lights(child, enabled)

func _validate_art(node: Node) -> bool:
	if node is CanvasItem and node.is_visible_in_tree() and node.get_script() != null:
		var source: String = node.get_script().resource_path.get_file()
		if source in ["bamboo_forest_layer.gd", "bamboo_prop.gd", "noctis_terrain.gd"]:
			var batch = node.get("_batch")
			if batch == null or batch.get("_mesh") == null:
				print("Missing artwork: ", node.get_path())
				return false
	for child in node.get_children():
		if not _validate_art(child):
			return false
	return true

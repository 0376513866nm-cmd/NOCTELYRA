extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1

func settle() -> void:
	for i in range(8):
		await physics_frame
		await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/game_bugfix_review"))
	SettingsManager.custom_settings_path = "res://artifacts/game_bugfix_review/zoom_settings.json"
	var file := FileAccess.open(SettingsManager.get_settings_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify({"camera_zoom":1.0, "is_fullscreen":false, "hybrid_controls_enabled":false}))
	file.close()
	SaveManager.custom_save_path = "res://artifacts/game_bugfix_review/zoom_slot.json"
	ZoneManager.reset_session()
	change_scene_to_file("res://src/world/noctis_forest.tscn")
	await settle()
	current_scene.game_ui._on_zoom_slider_changed(1.4)
	check(current_scene.get_node("Camera2D").zoom.is_equal_approx(Vector2(1.4, 1.4)), "Sidebar slider updates the active camera")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SettingsManager.get_settings_path()))
	check(is_equal_approx(float(saved.camera_zoom), 1.4), "Zoom is saved immediately without requiring the pause-settings close button")
	# A later live adjustment must survive map entry even if disk holds an older value.
	SettingsManager.camera_zoom = 1.7
	for zone in ["elyndra_glade", "vharok_outpost", "noctis_forest"]:
		ZoneManager.travel_cooldown = 0
		check(ZoneManager.travel_to_zone(zone, "spawn_default", current_scene), "Travel accepted: " + zone)
		await settle()
		check(is_equal_approx(SettingsManager.camera_zoom, 1.7), "Map UI does not reload stale zoom: " + zone)
		check(current_scene.get_node("Camera2D").zoom.is_equal_approx(Vector2(1.7, 1.7)), "New map camera retains 170%: " + zone)
		check(is_equal_approx(current_scene.game_ui.sidebar_zoom_slider.value, 1.7), "Sidebar slider stays synchronized: " + zone)
	SettingsManager.zoom_out()
	check(is_equal_approx(SettingsManager.camera_zoom, 1.6), "Zoom shortcut changes live setting")
	SettingsManager.camera_zoom = 1.0
	SettingsManager.load_settings(true)
	check(is_equal_approx(SettingsManager.camera_zoom, 1.6), "Restart-style reload restores last saved zoom")
	current_scene.game_ui._on_zoom_reset_pressed()
	check(current_scene.get_node("Camera2D").zoom == Vector2.ONE, "Reset zoom still works")
	print("ZOOM REGRESSIONS: ", failures, " failures")
	quit(0 if failures == 0 else 1)

class_name SettingsManager
extends RefCounted

const SETTINGS_FILE_PATH := "user://settings.json"

static var camera_zoom: float = 1.0:
	set(val):
		camera_zoom = clamp(val, 0.6, 2.0)
		apply_camera_zoom()

static var is_fullscreen: bool = false
static var hybrid_controls_enabled: bool = false

static func apply_camera_zoom(world: Node = null) -> void:
	var target := world
	if target == null and Engine.get_main_loop() is SceneTree:
		target = (Engine.get_main_loop() as SceneTree).current_scene
	if target:
		var cam: Camera2D = target.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.zoom = Vector2(camera_zoom, camera_zoom)

static func zoom_in(step: float = 0.1) -> float:
	camera_zoom = clamp(camera_zoom + step, 0.6, 2.0)
	return camera_zoom

static func zoom_out(step: float = 0.1) -> float:
	camera_zoom = clamp(camera_zoom - step, 0.6, 2.0)
	return camera_zoom

static func set_zoom(val: float) -> float:
	camera_zoom = clamp(val, 0.6, 2.0)
	return camera_zoom

static func set_fullscreen(enabled: bool) -> void:
	is_fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

static func toggle_fullscreen() -> bool:
	set_fullscreen(not is_fullscreen)
	return is_fullscreen

static func save_settings() -> void:
	var data := {
		"camera_zoom": camera_zoom,
		"is_fullscreen": is_fullscreen,
		"hybrid_controls_enabled": hybrid_controls_enabled
	}
	var f := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

static func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		return
	var f := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		if d.has("camera_zoom"):
			camera_zoom = clamp(float(d["camera_zoom"]), 0.6, 2.0)
		if d.has("is_fullscreen"):
			is_fullscreen = bool(d["is_fullscreen"])
			set_fullscreen(is_fullscreen)
		if d.has("hybrid_controls_enabled"):
			hybrid_controls_enabled = bool(d["hybrid_controls_enabled"])

class_name SettingsManager
extends RefCounted

const SETTINGS_FILE_PATH := "user://settings.json"
static var custom_settings_path: String = ""
static var _settings_loaded: bool = false

static func get_settings_path() -> String:
	return custom_settings_path if not custom_settings_path.is_empty() else SETTINGS_FILE_PATH

static var camera_zoom: float = 1.0:
	set(val):
		camera_zoom = clamp(val, 0.6, 2.0)
		apply_camera_zoom()

static var is_fullscreen: bool = false
static var hybrid_controls_enabled: bool = false
static var show_fps: bool = false

static func apply_camera_zoom(world: Node = null) -> void:
	var target := world
	if target == null and Engine.get_main_loop() is SceneTree:
		target = (Engine.get_main_loop() as SceneTree).current_scene
	if target:
		var cam: Camera2D = target.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.zoom = Vector2(camera_zoom, camera_zoom)

static func zoom_in(step: float = 0.1) -> float:
	return set_zoom(camera_zoom + step)

static func zoom_out(step: float = 0.1) -> float:
	return set_zoom(camera_zoom - step)

static func set_zoom(val: float) -> float:
	var next_zoom := clampf(val, 0.6, 2.0)
	if not is_equal_approx(next_zoom, camera_zoom):
		camera_zoom = next_zoom
		save_settings()
	return camera_zoom

static func set_fullscreen(enabled: bool) -> void:
	is_fullscreen = enabled
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	# Loading a new area's UI must not recreate an unchanged window/swapchain.
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)

static func toggle_fullscreen() -> bool:
	set_fullscreen(not is_fullscreen)
	return is_fullscreen

static func toggle_show_fps() -> bool:
	show_fps = not show_fps
	save_settings()
	return show_fps

static func save_settings() -> void:
	var data := {
		"camera_zoom": camera_zoom,
		"is_fullscreen": is_fullscreen,
		"hybrid_controls_enabled": hybrid_controls_enabled,
		"show_fps": show_fps
	}
	var f := FileAccess.open(get_settings_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

static func load_settings(force_reload: bool = false) -> void:
	# New area UIs share the live settings; don't overwrite them with an old disk value.
	if _settings_loaded and not force_reload:
		return
	_settings_loaded = true
	if not FileAccess.file_exists(get_settings_path()):
		return
	var f := FileAccess.open(get_settings_path(), FileAccess.READ)
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
		if d.has("show_fps"):
			show_fps = bool(d["show_fps"])

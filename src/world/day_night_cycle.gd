class_name DayNightCycle
extends Node2D

## Hệ thống Chu kỳ Ngày / Đêm & Ánh sáng Động (Dynamic Day/Night Cycle) cho NOCTELYRA
## Điều khiển ánh sáng thế giới (CanvasModulate), bầu trời sáng rực rỡ ban ngày và lung linh ban đêm,
## quỹ đạo Mặt Trời & Mặt Trăng, bầu trời sao, và đồi núi viễn cảnh.

signal time_updated(hour: float, time_str: String, phase: String, icon: String)
signal phase_changed(new_phase: String)

@export var day_duration: float = 180.0 ## Thời gian 1 vòng 24h thực tế (giây), mặc định 3 phút
@export var current_hour: float = 11.5 ## Khởi đầu lúc 11:30 trưa (Ban ngày rực rỡ theo yêu cầu)
@export var time_scale: float = 1.0
@export var is_paused: bool = false

# Node references
@export var canvas_modulate: CanvasModulate
@export var sky_day_tex: TextureRect
@export var sky_night_tex: TextureRect
@export var sun_node: Node2D
@export var moon_node: Node2D
@export var stars_node: Node2D
@export var clouds_node: Node2D
@export var hills_node: CanvasItem
@export var mountains_node: CanvasItem

var _last_phase: String = ""

# Màu sắc ánh sáng thế giới (CanvasModulate) cho từng mốc thời gian
const AMBIENT_NIGHT: Color = Color(0.35, 0.38, 0.55, 1.0) # Đêm huyền bí (chàm sapphire)
const AMBIENT_DAWN: Color  = Color(0.92, 0.82, 0.74, 1.0) # Bình minh (hồng đào - hổ phách)
const AMBIENT_DAY: Color   = Color(1.00, 1.00, 1.00, 1.0) # Ban ngày (ánh nắng tươi sáng rực rỡ 100%)
const AMBIENT_DUSK: Color  = Color(0.95, 0.65, 0.48, 1.0) # Hoàng hôn (cam rực - tím tía)

func _ready() -> void:
	add_to_group("day_night_cycle")
	_find_node_references()
	_update_lighting(0.0)

func _find_node_references() -> void:
	if canvas_modulate == null:
		canvas_modulate = get_tree().current_scene.find_child("WorldCanvasModulate", true, false) as CanvasModulate
	if sky_day_tex == null:
		sky_day_tex = get_tree().current_scene.find_child("SkyDayTex", true, false) as TextureRect
	if sky_night_tex == null:
		sky_night_tex = get_tree().current_scene.find_child("SkyNightTex", true, false) as TextureRect
	if sun_node == null:
		sun_node = get_tree().current_scene.find_child("Sun", true, false) as Node2D
	if moon_node == null:
		moon_node = get_tree().current_scene.find_child("Moon", true, false) as Node2D
	if stars_node == null:
		stars_node = get_tree().current_scene.find_child("Starfield", true, false) as Node2D
	if clouds_node == null:
		clouds_node = get_tree().current_scene.find_child("LayerClouds", true, false) as Node2D
	if hills_node == null:
		hills_node = get_tree().current_scene.find_child("HillsTex", true, false) as CanvasItem
	if mountains_node == null:
		mountains_node = get_tree().current_scene.find_child("MountainsTex", true, false) as CanvasItem

func _process(delta: float) -> void:
	if not is_paused:
		var hours_per_sec: float = 24.0 / maxf(1.0, day_duration)
		current_hour += hours_per_sec * delta * time_scale
		if current_hour >= 24.0:
			current_hour -= 24.0
		elif current_hour < 0.0:
			current_hour += 24.0

	_update_lighting(delta)

func _update_lighting(delta: float) -> void:
	var cur_phase: String = get_current_phase()
	if cur_phase != _last_phase:
		_last_phase = cur_phase
		phase_changed.emit(cur_phase)

	var ambient_col: Color = get_ambient_color()
	if canvas_modulate:
		canvas_modulate.color = ambient_col

	# Hòa trộn 2 lớp bầu trời Day/Night
	var day_blend: float = get_day_blend()
	if sky_day_tex:
		sky_day_tex.modulate.a = day_blend
		sky_day_tex.modulate.r = ambient_col.r
		sky_day_tex.modulate.g = ambient_col.g
		sky_day_tex.modulate.b = ambient_col.b
	if sky_night_tex:
		sky_night_tex.modulate.a = 1.0 - day_blend

	# Cập nhật đồi núi viễn cảnh (ban ngày xanh mướt, ban đêm chuyển lam tím)
	var hill_col: Color = Color(0.35, 0.40, 0.55, 1.0).lerp(Color(1.0, 1.0, 1.0, 1.0), day_blend)
	if hills_node:
		hills_node.modulate = hill_col
	if mountains_node:
		mountains_node.modulate = hill_col

	# Cập nhật vị trí và độ rực của Mặt Trời
	if sun_node:
		var sun_alpha: float = get_sun_visibility()
		sun_node.modulate.a = sun_alpha
		if sun_alpha > 0.01:
			var sun_t: float = (current_hour - 5.0) / 14.0 # 0.0 tại 05:00, 1.0 tại 19:00
			var sun_x: float = lerpf(200.0, 1720.0, clampf(sun_t, 0.0, 1.0))
			var sun_y: float = 340.0 - sin(clampf(sun_t, 0.0, 1.0) * PI) * 260.0
			sun_node.position = Vector2(sun_x, sun_y)

	# Cập nhật vị trí và độ mờ của Mặt Trăng
	if moon_node:
		var moon_alpha: float = get_moon_visibility()
		moon_node.modulate.a = moon_alpha
		if moon_alpha > 0.01:
			var moon_t: float = 0.0
			if current_hour >= 18.0:
				moon_t = (current_hour - 18.0) / 12.0
			else:
				moon_t = (current_hour + 6.0) / 12.0
			var moon_x: float = lerpf(1720.0, 200.0, clampf(moon_t, 0.0, 1.0))
			var moon_y: float = 340.0 - sin(clampf(moon_t, 0.0, 1.0) * PI) * 240.0
			moon_node.position = Vector2(moon_x, moon_y)

	# Cập nhật độ sáng các vì sao (chỉ hiện ban đêm)
	if stars_node:
		var star_alpha: float = get_stars_visibility()
		stars_node.modulate.a = star_alpha

	# Cập nhật các nguồn sáng thế giới (PointLight2D trong map)
	# Ban ngày dịu nhẹ hoàn toàn (0.0) để không gây cháy sáng chói lóa lên vật thể & nhân vật
	var night_factor: float = get_night_intensity()
	var lights := get_tree().get_nodes_in_group("day_night_lights")
	for l in lights:
		if l is Light2D:
			l.energy = lerpf(0.0, 0.65, night_factor)

	# Emit thông tin thời gian ra UI
	time_updated.emit(current_hour, get_time_string(), cur_phase, get_phase_icon())

## Độ hòa trộn bầu trời ban ngày (1.0 = Ban ngày xanh trong, 0.0 = Đêm đen)
func get_day_blend() -> float:
	var h: float = current_hour
	if h >= 7.5 and h < 16.5:
		return 1.0
	elif h >= 5.0 and h < 7.5:
		return (h - 5.0) / 2.5
	elif h >= 16.5 and h < 19.5:
		return 1.0 - (h - 16.5) / 3.0
	return 0.0

func get_current_phase() -> String:
	if current_hour >= 5.0 and current_hour < 8.0:
		return "dawn"
	elif current_hour >= 8.0 and current_hour < 17.0:
		return "day"
	elif current_hour >= 17.0 and current_hour < 20.0:
		return "dusk"
	else:
		return "night"

func get_phase_name() -> String:
	match get_current_phase():
		"dawn": return "Bình Minh"
		"day":  return "Ban Ngày"
		"dusk": return "Hoàng Hôn"
		_:      return "Đêm Huyền Bí"

func get_phase_icon() -> String:
	match get_current_phase():
		"dawn": return "🌅"
		"day":  return "☀️"
		"dusk": return "🌇"
		_:      return "🌙"

func get_time_string() -> String:
	var h: int = int(current_hour) % 24
	var m: int = int((current_hour - float(h)) * 60.0)
	return "%02d:%02d" % [h, m]

func set_time_phase(phase: String) -> void:
	match phase.to_lower():
		"dawn":  current_hour = 6.5
		"day":   current_hour = 12.0
		"dusk":  current_hour = 18.0
		"night": current_hour = 22.0
	_update_lighting(0.0)

func toggle_time_phase() -> String:
	var cur: String = get_current_phase()
	match cur:
		"dawn":  set_time_phase("day")
		"day":   set_time_phase("dusk")
		"dusk":  set_time_phase("night")
		_:       set_time_phase("dawn")
	return get_current_phase()

func get_ambient_color() -> Color:
	var h: float = current_hour
	if h < 4.0:
		return AMBIENT_NIGHT
	elif h < 6.5:
		var t: float = (h - 4.0) / 2.5
		return AMBIENT_NIGHT.lerp(AMBIENT_DAWN, t)
	elif h < 8.0:
		var t: float = (h - 6.5) / 1.5
		return AMBIENT_DAWN.lerp(AMBIENT_DAY, t)
	elif h < 16.5:
		return AMBIENT_DAY
	elif h < 19.0:
		var t: float = (h - 16.5) / 2.5
		return AMBIENT_DAY.lerp(AMBIENT_DUSK, t)
	elif h < 21.0:
		var t: float = (h - 19.0) / 2.0
		return AMBIENT_DUSK.lerp(AMBIENT_NIGHT, t)
	else:
		return AMBIENT_NIGHT

func get_sun_visibility() -> float:
	if current_hour >= 5.0 and current_hour < 6.5:
		return (current_hour - 5.0) / 1.5
	elif current_hour >= 6.5 and current_hour < 17.5:
		return 1.0
	elif current_hour >= 17.5 and current_hour < 19.0:
		return 1.0 - (current_hour - 17.5) / 1.5
	return 0.0

func get_moon_visibility() -> float:
	if current_hour >= 18.0 and current_hour < 19.5:
		return (current_hour - 18.0) / 1.5
	elif current_hour >= 19.5 or current_hour < 5.0:
		return 1.0
	elif current_hour >= 5.0 and current_hour < 6.5:
		return 1.0 - (current_hour - 5.0) / 1.5
	return 0.0

func get_stars_visibility() -> float:
	if current_hour >= 19.0 and current_hour < 21.0:
		return (current_hour - 19.0) / 2.0
	elif current_hour >= 21.0 or current_hour < 4.5:
		return 1.0
	elif current_hour >= 4.5 and current_hour < 6.5:
		return 1.0 - (current_hour - 4.5) / 2.0
	return 0.0

func get_night_intensity() -> float:
	if current_hour >= 20.0 or current_hour < 5.0:
		return 1.0
	elif current_hour >= 5.0 and current_hour < 7.5:
		return 1.0 - (current_hour - 5.0) / 2.5
	elif current_hour >= 17.5 and current_hour < 20.0:
		return (current_hour - 17.5) / 2.5
	return 0.0

@tool
extends Node2D
## Code-native CanvasItem artwork. Separate layers can be moved in the 2D editor.

@export_enum("Bamboo", "Forest floor", "Canopy", "Drifting leaves") var layer_kind: int = 0:
	set(value):
		layer_kind = value
		queue_redraw()
@export var random_seed: int = 2410:
	set(value):
		random_seed = value
		queue_redraw()
@export var extent: float = 9000.0
@export var spacing: float = 85.0
@export var stalk_width: float = 14.0
@export var base_y: float = 620.0
@export var tint: Color = Color("#35644d")
@export var leaf_tint: Color = Color("#39714e")
@export var animate_wind: bool = false

var _clock: float = 0.0
var _tick: float = 0.0
var _rng := RandomNumberGenerator.new()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not (animate_wind or layer_kind == 3):
		return
	_clock += delta
	_tick += delta
	if _tick > 0.05:
		_tick = 0.0
		queue_redraw()


var _batch = preload("res://src/world/canvas_shape_batch.gd").new()


func _draw() -> void:
	_batch.clear()
	_rng.seed = random_seed
	match layer_kind:
		0: _draw_bamboo_forest()
		1: _draw_forest_floor()
		2: _draw_canopy()
		3: _draw_drifting_leaves()

	_batch.submit(self)


func _draw_bamboo_forest() -> void:
	# Extend the culms behind the shared forest floor instead of covering their
	# roots with opaque banks on every parallax plane (which looked like walls).
	var x: float = -1400.0
	while x < extent:
		x += _rng.randf_range(spacing * 0.55, spacing * 1.65)
		var origin := Vector2(x, base_y + _rng.randf_range(-24.0, 24.0))
		var height: float = _rng.randf_range(670.0, 1150.0)
		var width: float = stalk_width * _rng.randf_range(0.55, 1.3)
		var lean: float = _rng.randf_range(-0.065, 0.065)
		if animate_wind:
			lean += sin(_clock * 0.7 + x * 0.008) * 0.004
		_batch.set_transform(origin, lean)
		var col: Color = tint.lightened(_rng.randf_range(-0.06, 0.06))
		_batch.rect(Rect2(-width * 0.5, -1, width, 1201), col)
		_batch.style_box(_capsule_style(col, width * 0.4), Rect2(-width * 0.5, -height, width, height))
		_batch.rect(Rect2(-width * 0.22, -height + 6.0, maxf(1.0, width * 0.18), height + 1194.0), col.lightened(0.18))
		var joint: float = 32.0
		while joint < height:
			_batch.line(Vector2(-width * 0.58, -joint), Vector2(width * 0.58, -joint), col.darkened(0.24), maxf(1.0, width * 0.12), true)
			_batch.line(Vector2(-width * 0.48, -joint - 2.0), Vector2(width * 0.48, -joint - 2.0), col.lightened(0.27), 1.3, true)
			if joint > 170.0 and _rng.randf() < 0.33:
				var side: float = -1.0 if _rng.randf() < 0.5 else 1.0
				var tip := Vector2(side * _rng.randf_range(40.0, 85.0), -joint - _rng.randf_range(20.0, 48.0))
				_batch.line(Vector2(0, -joint), tip, col.darkened(0.12), 2.0, true)
				_leaf_fan(tip, side, leaf_tint, _rng.randf_range(0.65, 1.1))
			joint += _rng.randf_range(63.0, 100.0)
		_batch.set_transform(Vector2.ZERO)


func _capsule_style(col: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = col
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	return style


func _leaf_fan(origin: Vector2, side: float, color: Color, size: float) -> void:
	var twig := Vector2(side * 59.0, -18.0) * size
	_batch.line(origin, origin + twig, color.darkened(0.08), maxf(0.7, size), true)
	for i in range(8):
		var at: Vector2 = origin + twig * (0.16 + float(i) * 0.105)
		var upward: bool = i % 2 == 0
		var direction := Vector2(side * (0.7 if upward else 1.0), -0.85 if upward else 0.65).normalized()
		var length: float = (24.0 + sin(float(i) * 1.9) * 7.0) * size
		var normal := direction.orthogonal() * 2.5 * size
		var mid: Vector2 = at + direction * length * 0.5
		_batch.polygon(PackedVector2Array([at, mid + normal, at + direction * length, mid - normal * 0.7]), color.lightened(float(i % 3) * 0.035))


func _draw_forest_floor() -> void:
	# A soft forest floor merges into the trail, without stacked horizontal slabs.
	var depths := PackedFloat32Array([460, 510, 550, 590, 640, 1300])
	var opacities := PackedFloat32Array([0, 0.04, 0.18, 0.48, 1, 1])
	var ground_color := Color("#738055")
	for band in range(depths.size() - 1):
		for i in range(-14, 94):
			var x: float = float(i) * 110.0
			var nx: float = x + 110.0
			var y: float = sin(x * 0.006) * 9.0 + sin(x * 0.017) * 4.0
			var ny: float = sin(nx * 0.006) * 9.0 + sin(nx * 0.017) * 4.0
			_batch.gradient_quad(Vector2(x, depths[band] + y), Vector2(nx, depths[band] + ny), Vector2(nx, depths[band + 1] + ny), Vector2(x, depths[band + 1] + y), Color(ground_color, opacities[band]), Color(ground_color, opacities[band + 1]))
	for i in range(190):
		var at := Vector2(_rng.randf_range(-1300, extent), _rng.randf_range(565, 650))
		_batch.set_transform(at, 0, Vector2(_rng.randf_range(1.5, 3.0), 0.28))
		_batch.circle(Vector2.ZERO, _rng.randf_range(5, 17), Color(0.19, 0.34, 0.22, 0.13))
		_batch.set_transform(Vector2.ZERO)
	for ray in range(10):
		var x: float = float(ray) * 830.0 - 200.0
		_batch.polygon(PackedVector2Array([Vector2(x, -550), Vector2(x + 42, -550), Vector2(x + 430, 650), Vector2(x + 190, 650)]), Color(1.0, 0.91, 0.61, 0.042))


func _draw_canopy() -> void:
	for i in range(-7, 92):
		var x: float = float(i) * 110.0 + _rng.randf_range(-30.0, 30.0)
		var y: float = -110.0 + _rng.randf_range(-90, 70)
		for cluster in range(5):
			var at := Vector2(x + float(cluster) * 29.0, y + sin(float(cluster)) * 40.0)
			_leaf_fan(at, -1.0 if cluster % 2 == 0 else 1.0, leaf_tint, 2.9)


func _draw_drifting_leaves() -> void:
	for i in range(72):
		var offset: float = float(i) * 1.731
		var x: float = fposmod(float(i) * 127.0 + _clock * 14.0, 7000.0) - 300.0
		var y: float = fposmod(offset * 119.0 + _clock * (18.0 + float(i % 7)), 1050.0) - 420.0
		x += sin(_clock * 0.8 + offset) * 25.0
		_batch.set_transform(Vector2(x, y), sin(_clock + offset) * 1.0 + offset, Vector2(1, 0.45 + absf(sin(_clock + offset)) * 0.55))
		_batch.polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-1, -2), Vector2(7, 0), Vector2(-1, 2)]), Color("#b4c37b") if i % 3 else Color("#dfca80"))
		_batch.set_transform(Vector2.ZERO)

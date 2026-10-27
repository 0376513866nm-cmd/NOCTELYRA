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
@export_range(1, 150, 1) var falling_leaf_count: int = 64
@export_range(0.2, 2.0, 0.05) var leaf_motion_scale: float = 1.0
@export_range(0.3, 2.0, 0.05) var falling_leaf_size: float = 1.0
@export_range(0.1, 1.0, 0.05) var falling_leaf_opacity: float = 0.85

var _clock: float = 0.0
var _tick: float = 0.0
var _rng := RandomNumberGenerator.new()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not (animate_wind or layer_kind == 3):
		return
	_clock += delta
	if layer_kind == 3:
		queue_redraw()
		return
	_tick += delta
	if _tick > 0.05:
		_tick = 0.0
		queue_redraw()


var _batch = preload("res://src/world/canvas_shape_batch.gd").new()
var _texture_batch = preload("res://src/world/bamboo_atlas_brush.gd").new()


func _draw() -> void:
	_batch.clear()
	_texture_batch.clear()
	_rng.seed = random_seed
	match layer_kind:
		0: _draw_bamboo_forest()
		1: _draw_forest_floor()
		2: _draw_canopy()
		3: _draw_drifting_leaves()

	_batch.submit(self)
	_texture_batch.submit(self)


func _draw_bamboo_forest() -> void:
	# The same PNG pieces are assembled into many silhouettes on each depth plane.
	var x: float = -1400.0
	var alpha: float = clampf((stalk_width - 4.0) / 17.0, 0.22, 0.92)
	while x < extent:
		x += _rng.randf_range(spacing * 0.7, spacing * 1.55)
		var origin := Vector2(x, base_y + _rng.randf_range(-24.0, 24.0))
		var height: float = _rng.randf_range(670.0, 1150.0)
		var width: float = stalk_width * _rng.randf_range(0.65, 1.25)
		var lean: float = _rng.randf_range(-0.075, 0.075)
		var color := Color(0.87, 0.95, 0.84, alpha)
		_texture_batch.culm(origin, height, width, lean, _rng, color, 1200.0)


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
	for i in range(-7, 65):
		var x: float = float(i) * 160.0 + _rng.randf_range(-35, 35)
		var at := Vector2(x, -105.0 + _rng.randf_range(-45, 35))
		_texture_batch.foliage(at, -1, 1.1, -0.25, _rng, Color(0.50, 0.67, 0.48, 0.92))
		_texture_batch.foliage(at + Vector2(75, 10), 1, 1.0, 0.3, _rng, Color(0.57, 0.71, 0.48, 0.92))


func _draw_drifting_leaves() -> void:
	var terrain: Node2D = null
	if get_parent() and get_parent().get_parent():
		terrain = get_parent().get_parent().get_node_or_null("Geometry/NoctisTerrain") as Node2D
	for i in range(falling_leaf_count):
		var offset: float = float(i) * 1.731
		var time := _clock * leaf_motion_scale
		var x := fposmod(float(i) * 643.71 + float(random_seed % 101) * 19.0 + time * (10.0 + float(i % 5) * 2.0), 6800.0) - 150.0
		x += sin(time * 0.85 + offset) * 24.0 + sin(time * 0.39 + offset * 2.0) * 12.0
		var floor_y := 620.0
		if terrain and terrain.has_method("surface_y_at"):
			var terrain_x: float = terrain.to_local(to_global(Vector2(x, 0))).x
			floor_y = to_local(terrain.to_global(Vector2(terrain_x, terrain.surface_y_at(terrain_x)))).y
		var y := fposmod(offset * 119.0 + time * (24.0 + float(i % 7) * 3.0), floor_y + 220.0) - 220.0
		var alpha := smoothstep(-180.0, -80.0, y) * (1.0 - smoothstep(floor_y - 48.0, floor_y - 5.0, y)) * falling_leaf_opacity
		var size := falling_leaf_size * (0.75 + float(i % 4) * 0.14)
		var tilt := sin(time * 1.4 + offset) * 0.7 + offset
		var flip := 0.25 + absf(sin(time * 1.8 + offset)) * 0.75
		_batch.set_transform(Vector2(x, y), tilt, Vector2(size, size * flip))
		var color := Color("#8da56b") if i % 4 else Color("#c1b578")
		color.a = alpha
		_batch.polygon(PackedVector2Array([Vector2(-7, 0), Vector2(-2, -1.6), Vector2(2, -1.0), Vector2(8, 0), Vector2(1, 1.7), Vector2(-3, 1.0)]), color)
		_batch.set_transform(Vector2.ZERO)

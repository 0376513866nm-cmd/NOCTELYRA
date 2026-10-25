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
	for i in range(72):
		var offset: float = float(i) * 1.731
		var x: float = fposmod(float(i) * 127.0 + _clock * 14.0, 7000.0) - 300.0
		var y: float = fposmod(offset * 119.0 + _clock * (18.0 + float(i % 7)), 1050.0) - 420.0
		x += sin(_clock * 0.8 + offset) * 25.0
		_batch.set_transform(Vector2(x, y), sin(_clock + offset) * 1.0 + offset, Vector2(1, 0.45 + absf(sin(_clock + offset)) * 0.55))
		_batch.polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-1, -2), Vector2(7, 0), Vector2(-1, 2)]), Color("#b4c37b") if i % 3 else Color("#dfca80"))
		_batch.set_transform(Vector2.ZERO)

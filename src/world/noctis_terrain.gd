@tool
extends StaticBody2D

## A single source of truth for the visible ground and its collision.
## Keeping both generated from SURFACE prevents art/collision mismatches.

const BOTTOM_Y := 1600.0
var surface := PackedVector2Array([
	Vector2(-120.0, 632.0),
	Vector2(0.0, 632.0),
	Vector2(820.0, 632.0),
	Vector2(842.0, 612.0),
	Vector2(1450.0, 612.0),
	Vector2(1472.0, 592.0),
	Vector2(1950.0, 592.0),
	Vector2(1972.0, 620.0),
	Vector2(2580.0, 620.0),
	Vector2(2602.0, 600.0),
	Vector2(3300.0, 600.0),
	Vector2(3322.0, 624.0),
	Vector2(4140.0, 624.0),
	Vector2(4162.0, 606.0),
	Vector2(4860.0, 606.0),
	Vector2(4882.0, 590.0),
	Vector2(5520.0, 590.0),
	Vector2(5542.0, 620.0),
	Vector2(6460.0, 620.0)
])

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build_collision()
	queue_redraw()


func _build_collision() -> void:
	var old := get_node_or_null("CollisionPolygon2D")
	if old:
		old.free()
	var shape := CollisionPolygon2D.new()
	shape.name = "CollisionPolygon2D"
	var polygon := PackedVector2Array(surface)
	polygon.append(Vector2(surface[-1].x, BOTTOM_Y))
	polygon.append(Vector2(surface[0].x, BOTTOM_Y))
	shape.polygon = polygon
	add_child(shape)


func surface_y_at(world_x: float) -> float:
	if world_x <= surface[0].x:
		return surface[0].y
	for i in range(surface.size() - 1):
		var a := surface[i]
		var b := surface[i + 1]
		if world_x <= b.x:
			return lerpf(a.y, b.y, inverse_lerp(a.x, b.x, world_x))
	return surface[-1].y


var _batch = preload("res://src/world/canvas_shape_batch.gd").new()


func _draw() -> void:
	_batch.clear()
	var earth := PackedVector2Array(surface)
	earth.append(Vector2(surface[-1].x, BOTTOM_Y))
	earth.append(Vector2(surface[0].x, BOTTOM_Y))
	_batch.polygon(earth, Color("#514a36"))
	# Shallow soil strata follow the same contour as physics, including each step.
	_band(0.0, 10.0, Color("#b3a277"))
	_band(10.0, 18.0, Color("#8c8854"))
	_band(18.0, 30.0, Color("#646b40"))
	_band(30.0, 70.0, Color("#6e6043"))
	_band(70.0, 145.0, Color("#5d533b"))
	_batch.polyline(surface, Color("#d1bc8c"), 2.0, true)
	_rng.seed = 241024
	for i in range(360):
		var x: float = _rng.randf_range(-100, 6450)
		var y: float = surface_y_at(x) + _rng.randf_range(35, 260)
		var width: float = _rng.randf_range(3, 13)
		var points := PackedVector2Array([Vector2(x-width,y), Vector2(x-width*0.6,y-4), Vector2(x+width*0.5,y-5), Vector2(x+width,y+1), Vector2(x+width*0.3,y+4), Vector2(x-width*0.8,y+3)])
		_batch.polygon(points, Color("#827758") if i % 3 else Color("#454a35"))
	# Fallen bamboo leaves lie on the trail, not in a straight grass fence.
	for i in range(330):
		var x: float = _rng.randf_range(-100, 6450)
		var y: float = surface_y_at(x) + _rng.randf_range(2, 7)
		var length: float = _rng.randf_range(3, 8)
		_batch.line(Vector2(x, y), Vector2(x+length, y-1.3), Color("#ded09b") if i % 3 else Color("#9ca563"), 1.2, true)
	# Sparse moss tufts originate exactly on the walkable contour.
	for i in range(95):
		var x: float = _rng.randf_range(-100, 6440)
		if x > 100 and x < 610:
			continue
		for blade in range(4):
			var bx: float = x + _rng.randf_range(-7, 7)
			var y: float = surface_y_at(bx)
			_batch.line(Vector2(bx, y), Vector2(bx+_rng.randf_range(-6,6),y-_rng.randf_range(4,10)), Color("#6d8c48"), 1.6, true)

	_batch.submit(self)


func _band(from_depth: float, to_depth: float, col: Color) -> void:
	var points := PackedVector2Array()
	for point in surface:
		points.append(point + Vector2(0, from_depth))
	for i in range(surface.size()-1, -1, -1):
		points.append(surface[i] + Vector2(0, to_depth))
	_batch.polygon(points, col)


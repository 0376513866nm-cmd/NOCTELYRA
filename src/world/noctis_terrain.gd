@tool
extends StaticBody2D

## A single source of truth for the visible ground and its collision.
## Keeping both generated from SURFACE prevents art/collision mismatches.

const BOTTOM_Y := 1600.0
const MOSS_EDGE := preload("res://assets/asset/Mossy Grass Terrain Strip.png")

class MossCanvas:
	extends Node2D
	func _draw() -> void:
		get_parent()._draw_moss_edge(self)

var _moss_canvas: Node2D
var surface := PackedVector2Array([
	Vector2(-120.0, 632.0),
	Vector2(0.0, 632.0),
	Vector2(820.0, 632.0),
	Vector2(820.0, 612.0),
	Vector2(1450.0, 612.0),
	Vector2(1450.0, 592.0),
	Vector2(1950.0, 592.0),
	Vector2(1950.0, 620.0),
	Vector2(2580.0, 620.0),
	Vector2(2580.0, 600.0),
	Vector2(3300.0, 600.0),
	Vector2(3300.0, 624.0),
	Vector2(4140.0, 624.0),
	Vector2(4140.0, 606.0),
	Vector2(4860.0, 606.0),
	Vector2(4860.0, 590.0),
	Vector2(5520.0, 590.0),
	Vector2(5520.0, 620.0),
	Vector2(6460.0, 620.0)
])

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_moss_canvas = MossCanvas.new()
	_moss_canvas.name = "MossPalette"
	# Terrain is at -2; lift only the moss to -1 so it covers lantern bases.
	# Geometry follows the grove in scene order, so equal-Z moss draws last.
	_moss_canvas.z_index = 1
	add_child(_moss_canvas)
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
	# At a vertical step, a downward ray first meets the higher endpoint.
	# Check these corners before the preceding horizontal span claims its end.
	for i in range(surface.size() - 1):
		if is_equal_approx(surface[i].x, surface[i + 1].x) and is_equal_approx(world_x, surface[i].x):
			return minf(surface[i].y, surface[i + 1].y)
	for i in range(surface.size() - 1):
		var a := surface[i]
		var b := surface[i + 1]
		if world_x <= b.x:
			if is_equal_approx(a.x, b.x):
				return minf(a.y, b.y)
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
	if is_instance_valid(_moss_canvas):
		_moss_canvas.queue_redraw()


func _draw_moss_edge(target: CanvasItem) -> void:
	# Original transparent artwork, kept at one scale and clipped separately to
	# each horizontal physics segment. Never stretch a strip over a vertical step.
	var factor := 0.085
	var anchor_y := 360.0
	_rng.seed = 251025
	for i in range(surface.size() - 1):
		var a := surface[i]
		var b := surface[i + 1]
		if not is_equal_approx(a.y, b.y) or b.x - a.x < 32.0:
			continue
		var cursor: float = maxf(a.x + 8.0, 0.0)
		while cursor < b.x - 12.0:
			# Keep the doorstep and initial player/fox clearing open.
			if cursor < 430.0 and cursor + 180.0 > 125.0:
				cursor = 440.0
				continue
			var width := minf(_rng.randf_range(125.0, 180.0), b.x - cursor - 8.0)
			if width < 24.0:
				break
			var source := Rect2(0, 0, width / factor, float(MOSS_EDGE.get_height()))
			var destination := Rect2(cursor, a.y - anchor_y * factor, width, MOSS_EDGE.get_height() * factor)
			target.draw_texture_rect_region(MOSS_EDGE, destination, source, Color(0.88, 0.94, 0.80))
			cursor += width + _rng.randf_range(45.0, 95.0)


func _band(from_depth: float, to_depth: float, col: Color) -> void:
	var points := PackedVector2Array()
	for point in surface:
		points.append(point + Vector2(0, from_depth))
	for i in range(surface.size()-1, -1, -1):
		points.append(surface[i] + Vector2(0, to_depth))
	_batch.polygon(points, col)


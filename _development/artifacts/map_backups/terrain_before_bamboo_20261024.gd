@tool
extends StaticBody2D

## A single source of truth for the visible ground and its collision.
## Keeping both generated from SURFACE prevents art/collision mismatches.

const BOTTOM_Y := 900.0
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


func _draw() -> void:
	# Two non-colliding terraced meadow layers keep the playable ledge grounded
	# inside a broad valley instead of reading as the lip of an abyss.
	_draw_depth_layer(PackedVector2Array([
		Vector2(-200.0, 566.0), Vector2(620.0, 566.0), Vector2(642.0, 548.0),
		Vector2(1420.0, 548.0), Vector2(1442.0, 574.0), Vector2(2300.0, 574.0),
		Vector2(2322.0, 552.0), Vector2(3260.0, 552.0), Vector2(3282.0, 570.0),
		Vector2(4180.0, 570.0), Vector2(4202.0, 546.0), Vector2(5100.0, 546.0),
		Vector2(5122.0, 568.0), Vector2(6600.0, 568.0)
	]), Color("#3f5144"), Color("#66945a"), 10.0)
	_draw_depth_layer(PackedVector2Array([
		Vector2(-200.0, 600.0), Vector2(470.0, 600.0), Vector2(492.0, 582.0),
		Vector2(1120.0, 582.0), Vector2(1142.0, 606.0), Vector2(1880.0, 606.0),
		Vector2(1902.0, 586.0), Vector2(2860.0, 586.0), Vector2(2882.0, 606.0),
		Vector2(3800.0, 606.0), Vector2(3822.0, 584.0), Vector2(4740.0, 584.0),
		Vector2(4762.0, 602.0), Vector2(5700.0, 602.0), Vector2(5722.0, 584.0),
		Vector2(6600.0, 584.0)
	]), Color("#584737"), Color("#78ad50"), 12.0)

	var earth := PackedVector2Array(surface)
	earth.append(Vector2(surface[-1].x, BOTTOM_Y))
	earth.append(Vector2(surface[0].x, BOTTOM_Y))
	draw_colored_polygon(earth, Color("#49372e"))
	var deep_soil := PackedVector2Array([
		Vector2(surface[0].x, 755.0),
		Vector2(surface[-1].x, 755.0),
		Vector2(surface[-1].x, BOTTOM_Y),
		Vector2(surface[0].x, BOTTOM_Y),
	])
	draw_colored_polygon(deep_soil, Color("#352d2a"))

	# Warm soil bands make the ground read as one solid hillside instead of a slab.
	var turf_strip := PackedVector2Array(surface)
	for i in range(surface.size() - 1, -1, -1):
		turf_strip.append(surface[i] + Vector2(0.0, 22.0))
	draw_colored_polygon(turf_strip, Color("#326c3c"))
	draw_polyline(surface, Color("#66ad4c"), 9.0, true)
	draw_polyline(surface, Color("#9bd35b"), 2.5, true)

	_rng.seed = 0x4E4F4354
	# Grass follows the actual contour; it is intentionally clustered, never a ruler-straight row.
	var x := -90.0
	while x < 6440.0:
		x += _rng.randf_range(62.0, 138.0)
		var blade_count := _rng.randi_range(2, 6)
		for blade in range(blade_count):
			var blade_x := x + _rng.randf_range(-12.0, 12.0)
			var y := surface_y_at(blade_x) - 4.0
			var height := _rng.randf_range(5.0, 15.0)
			var tint := Color("#78bd51").lerp(Color("#c6df68"), _rng.randf_range(0.0, 0.45))
			draw_line(Vector2(blade_x, y), Vector2(blade_x + _rng.randf_range(-5.0, 5.0), y - height), tint, 1.7, true)
		if _rng.randf() < 0.22:
			var flower_y := surface_y_at(x) - _rng.randf_range(12.0, 18.0)
			var flower: Color = [Color("#ffd06b"), Color("#ff91c8"), Color("#b997ff")][_rng.randi_range(0, 2)]
			draw_circle(Vector2(x, flower_y), 2.5, flower)

	# Embedded stones and roots are below the contour, so none appear to float.
	for i in range(145):
		var sx := _rng.randf_range(-50.0, 6400.0)
		var sy := surface_y_at(sx) + _rng.randf_range(30.0, 235.0)
		var radius := _rng.randf_range(2.5, 9.0)
		var stone_color := Color("#777066").lerp(Color("#4d4945"), _rng.randf())
		draw_circle(Vector2(sx, sy), radius, stone_color)

	for i in range(34):
		var root_x := _rng.randf_range(0.0, 6400.0)
		var root_y := surface_y_at(root_x) + _rng.randf_range(34.0, 105.0)
		draw_line(Vector2(root_x, root_y), Vector2(root_x + _rng.randf_range(-20.0, 22.0), root_y + _rng.randf_range(10.0, 28.0)), Color("#6d4a30"), 2.0, true)


func _draw_depth_layer(top: PackedVector2Array, fill: Color, edge: Color, edge_width: float) -> void:
	var polygon := PackedVector2Array(top)
	polygon.append(Vector2(top[-1].x, BOTTOM_Y))
	polygon.append(Vector2(top[0].x, BOTTOM_Y))
	draw_colored_polygon(polygon, fill)
	draw_polyline(top, edge, edge_width, true)
	var layer_rng := RandomNumberGenerator.new()
	layer_rng.seed = int(fill.r * 1000.0 + fill.g * 10000.0 + fill.b * 100000.0)
	var detail_x := top[0].x + layer_rng.randf_range(45.0, 90.0)
	while detail_x < top[-1].x:
		var top_y := _polyline_y_at(top, detail_x)
		var stone_y := top_y + layer_rng.randf_range(13.0, 27.0)
		var stone_radius := layer_rng.randf_range(2.5, 6.0)
		draw_circle(Vector2(detail_x, stone_y), stone_radius, fill.lightened(layer_rng.randf_range(0.08, 0.2)))
		detail_x += layer_rng.randf_range(72.0, 155.0)


func _polyline_y_at(points: PackedVector2Array, x: float) -> float:
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, inverse_lerp(a.x, b.x, x))
	return points[-1].y


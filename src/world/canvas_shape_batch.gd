@tool
extends RefCounted
## Keeps editable canvas artwork as colored triangles in one retained draw call.
## No raster cache, extra viewport, or per-frame rebuild for static scenery.

var _vertices := PackedVector2Array()
var _colors := PackedColorArray()
var _indices := PackedInt32Array()
var _transform := Transform2D.IDENTITY
var _mesh: ArrayMesh

func clear() -> void:
	_vertices.clear()
	_colors.clear()
	_indices.clear()
	_transform = Transform2D.IDENTITY

func set_transform(offset: Vector2, angle: float = 0.0, scale: Vector2 = Vector2.ONE) -> void:
	_transform = Transform2D(angle, scale, 0.0, offset)

func polygon(points: PackedVector2Array, color: Color) -> void:
	var triangles := Geometry2D.triangulate_polygon(points)
	if triangles.is_empty():
		return
	var base := _vertices.size()
	for point in points:
		_vertices.append(_transform * point)
		_colors.append(color)
	for index in triangles:
		_indices.append(base + index)

func rect(box: Rect2, color: Color) -> void:
	polygon(PackedVector2Array([box.position, box.position + Vector2(box.size.x, 0), box.end, box.position + Vector2(0, box.size.y)]), color)

func gradient_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, top: Color, bottom: Color) -> void:
	var base := _vertices.size()
	for point in [a, b, c, d]:
		_vertices.append(_transform * point)
	_colors.append_array(PackedColorArray([top, top, bottom, bottom]))
	_indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))

func circle(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		points.append(center + Vector2.from_angle(float(i) * TAU / 24.0) * radius)
	polygon(points, color)

func line(from: Vector2, to: Vector2, color: Color, width: float = 1.0, antialias: bool = false) -> void:
	var normal := (to - from).normalized().orthogonal()
	var half: float = width * 0.5
	polygon(PackedVector2Array([from + normal * half, to + normal * half, to - normal * half, from - normal * half]), color)
	if antialias:
		# Transparent fringes preserve the soft edges of the original canvas lines.
		for side in [-1.0, 1.0]:
			var inner: Vector2 = normal * half * side
			var outer: Vector2 = normal * (half + 0.65) * side
			var base := _vertices.size()
			for point in [from + inner, to + inner, to + outer, from + outer]:
				_vertices.append(_transform * point)
			_colors.append_array(PackedColorArray([color, color, Color(color, 0), Color(color, 0)]))
			_indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))

func polyline(points: PackedVector2Array, color: Color, width: float = 1.0, antialias: bool = false) -> void:
	for i in range(points.size() - 1):
		line(points[i], points[i + 1], color, width, antialias)

func style_box(style: StyleBoxFlat, box: Rect2) -> void:
	var radius := minf(float(style.corner_radius_top_left), box.size.x * 0.5)
	var points := PackedVector2Array([box.position + Vector2(0, radius), box.position + Vector2(radius * 0.3, radius * 0.3), box.position + Vector2(radius, 0), box.position + Vector2(box.size.x - radius, 0), box.position + Vector2(box.size.x - radius * 0.3, radius * 0.3), box.position + Vector2(box.size.x, radius), box.end, box.position + Vector2(0, box.size.y)])
	polygon(points, style.bg_color)

func submit(target: CanvasItem) -> void:
	if _indices.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	target.draw_mesh(_mesh, null)

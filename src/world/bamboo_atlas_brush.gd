@tool
extends RefCounted
## Supplied PNG parts, assembled into two retained meshes per depth layer.
const TEXTURES := [preload("res://assets/environment/ink_bamboo/culm_source.png"), preload("res://assets/environment/ink_bamboo/branch_source.png")]
const STEMS := [Rect2(500, 180, 88, 260), Rect2(500, 440, 88, 260), Rect2(500, 700, 88, 260)]
const LEAVES := [Rect2(12, 165, 396, 540), Rect2(18, 170, 250, 210), Rect2(30, 376, 350, 290)]
const LEAF_PIVOTS := [Vector2(0.97222, 0.995), Vector2(0.624, 0.995), Vector2(0.985714, 0.995)]
const LEAF_LENGTHS := [185.0, 110.0, 140.0]

class TextureBatch:
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var mesh: ArrayMesh

var _batches := [TextureBatch.new(), TextureBatch.new()]
var _mesh: ArrayMesh

func clear() -> void:
	for batch in _batches:
		batch.vertices.clear()
		batch.colors.clear()
		batch.uvs.clear()
		batch.indices.clear()

func stamp(region: Rect2, at: Vector2, size: Vector2, angle: float, color: Color, pivot: Vector2 = Vector2(0.5, 1), mirror: bool = false, texture_slot: int = 0, bottom_alpha: float = -1.0) -> void:
	var batch: TextureBatch = _batches[texture_slot]
	var base := batch.vertices.size()
	var anchor := Vector2(1.0 - pivot.x, pivot.y) if mirror else pivot
	var local := Rect2(-anchor * size, size)
	var transform := Transform2D(angle, at)
	var corners := [local.position, local.position + Vector2(size.x, 0), local.end, local.position + Vector2(0, size.y)]
	for i in range(4):
		var point: Vector2 = corners[i]
		batch.vertices.append(transform * point)
		var vertex_color := color
		if i >= 2 and bottom_alpha >= 0.0:
			vertex_color.a = bottom_alpha
		batch.colors.append(vertex_color)
	var uv0: Vector2 = region.position / TEXTURES[texture_slot].get_size()
	var uv1: Vector2 = region.end / TEXTURES[texture_slot].get_size()
	if mirror:
		var swap := uv0.x
		uv0.x = uv1.x
		uv1.x = swap
	batch.uvs.append_array(PackedVector2Array([uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)]))
	batch.indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))

func foliage(at: Vector2, side: float, scale: float, angle: float, rng: RandomNumberGenerator, color: Color) -> void:
	var index := rng.randi_range(0, 2)
	var region: Rect2 = LEAVES[index]
	var size: Vector2 = region.size * (LEAF_LENGTHS[index] * scale / maxf(region.size.x, region.size.y))
	stamp(region, at, size, angle + side * 0.25, color, LEAF_PIVOTS[index], side > 0, 1)

func culm(at: Vector2, height: float, width: float, angle: float, rng: RandomNumberGenerator, color: Color = Color.WHITE, extend_below: float = 0.0) -> void:
	var source: Rect2 = STEMS[rng.randi_range(0, 2)]
	var segment_height: float = source.size.y * width / source.size.x * rng.randf_range(1.0, 1.2)
	var overlap := segment_height * 0.10
	var stride := segment_height - overlap
	var segments: Array[Vector2] = []
	var y := -height
	while y < extend_below:
		var length := minf(segment_height, extend_below - y)
		segments.append(Vector2(y, length))
		if y + length >= extend_below:
			break
		y += stride
	# Lower sections first: the upper section overlays the joint with 30% opacity.
	for i in range(segments.size() - 1, -1, -1):
		y = segments[i].x
		var length := segments[i].y
		var blend_length := overlap if i < segments.size() - 1 else 0.0
		var body_length := length - blend_length
		var source_scale := source.size.y / segment_height
		var part := Rect2(source.position, Vector2(source.size.x, body_length * source_scale))
		stamp(part, at + Vector2(0, y).rotated(angle), Vector2(width, body_length), angle, color, Vector2(0.5, 0))
		if blend_length > 0.0:
			var blend_region := Rect2(source.position + Vector2(0, body_length * source_scale), Vector2(source.size.x, blend_length * source_scale))
			var blend_color := color
			blend_color.a *= 0.30
			stamp(blend_region, at + Vector2(0, y + body_length).rotated(angle), Vector2(width, blend_length), angle, blend_color, Vector2(0.5, 0), false, 0, 0.0)
	var branch_y := -height + segment_height * 0.9
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	while branch_y < -height * 0.20:
		var root: Vector2 = at + Vector2(side * width * 0.43, branch_y).rotated(angle)
		var scale: float = clampf(width / 21.0, 0.45, 1.1) * rng.randf_range(0.85, 1.15)
		foliage(root, side, scale, angle + rng.randf_range(-0.16, 0.16), rng, color)
		if rng.randf() < 0.45:
			var opposite_root := at + Vector2(-side * width * 0.43, branch_y).rotated(angle)
			foliage(opposite_root, -side, scale * rng.randf_range(0.65, 0.85), angle, rng, color)
		side = -side
		branch_y += stride * (rng.randi_range(2, 3) if height > 400 else 2)

func submit(target: CanvasItem) -> void:
	for slot in range(_batches.size()):
		var batch: TextureBatch = _batches[slot]
		if batch.indices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = batch.vertices
		arrays[Mesh.ARRAY_COLOR] = batch.colors
		arrays[Mesh.ARRAY_TEX_UV] = batch.uvs
		arrays[Mesh.ARRAY_INDEX] = batch.indices
		batch.mesh = ArrayMesh.new()
		batch.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
		_mesh = batch.mesh
		target.draw_mesh(batch.mesh, TEXTURES[slot])

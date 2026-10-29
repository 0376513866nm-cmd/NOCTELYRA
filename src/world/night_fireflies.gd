extends Node2D
## One retained mesh; each insect follows its own continuous shader trajectory.
@export var texture: Texture2D
var emission_points := PackedVector2Array()
var emitting := false
var _mesh: ArrayMesh
var _flight_material: ShaderMaterial
var _flight_time := 0.0
var _cycle: Node
var _active := false

func _ready() -> void:
	_cycle = get_tree().get_first_node_in_group(GameGroups.DAY_NIGHT_CYCLE)
	_build_low_swarms()
	_build_mesh()
	_update_night()

func _build_mesh() -> void:
	_flight_material = ShaderMaterial.new()
	_flight_material.shader = preload("res://src/world/firefly_flight.gdshader")
	material = _flight_material
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 261025
	for point in emission_points:
		var seed_color := Color(rng.randf(), rng.randf(), rng.randf(), 1.0)
		var half_size := rng.randf_range(4.0, 6.5)
		var base := vertices.size()
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			vertices.append(point + corner * half_size)
			uvs.append((corner + Vector2.ONE) * 0.5)
			colors.append(seed_color)
		indices.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_mesh = ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	queue_redraw()

func _draw() -> void:
	if _mesh and texture:
		draw_mesh(_mesh, texture)

func _build_low_swarms() -> void:
	var terrain := get_parent().get_parent().get_node_or_null("Geometry/NoctisTerrain")
	if terrain == null:
		return
	# Match the actual moss patches, then keep a swarm on every second patch.
	var moss_rng := RandomNumberGenerator.new()
	moss_rng.seed = 251025
	var fly_rng := RandomNumberGenerator.new()
	fly_rng.seed = 251026
	var points := PackedVector2Array()
	var patch_index := 0
	var surface: PackedVector2Array = terrain.surface
	for i in range(surface.size() - 1):
		var a := surface[i]
		var b := surface[i + 1]
		if not is_equal_approx(a.y, b.y) or b.x - a.x < 32.0:
			continue
		var cursor := maxf(a.x + 8.0, 0.0)
		while cursor < b.x - 12.0:
			if cursor < 430.0 and cursor + 180.0 > 125.0:
				cursor = 440.0
				continue
			var width := minf(moss_rng.randf_range(125.0, 180.0), b.x - cursor - 8.0)
			if width < 24.0:
				break
			if patch_index % 2 == 0:
				for insect in range(12):
					var at := Vector2(cursor + width * 0.5 + fly_rng.randf_range(-width * 0.25, width * 0.25), a.y - fly_rng.randf_range(40.0, 56.0))
					points.append(to_local(terrain.to_global(at)))
			patch_index += 1
			cursor += width + moss_rng.randf_range(45.0, 95.0)
	emission_points = points

func _process(delta: float) -> void:
	if not is_instance_valid(_cycle):
		_cycle = get_tree().get_first_node_in_group(GameGroups.DAY_NIGHT_CYCLE)
	_update_night()
	if _active:
		_flight_time += delta
		_flight_material.set_shader_parameter("flight_time", _flight_time)

func _update_night() -> void:
	var night: float = _cycle.get_night_intensity() if is_instance_valid(_cycle) else 0.0
	var strength := smoothstep(0.15, 0.95, night)
	var active := strength > 0.001
	if active != _active:
		_active = active
		emitting = active
	visible = active
	modulate.a = strength

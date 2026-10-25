@tool
extends Node2D
## Editable, texture-free props drawn with Godot's 2D canvas primitives.

@export_enum("Cottage", "Fence", "Stone lantern", "Mossy rocks", "Fern patch", "Tea bench", "Bamboo clump", "Trail sign") var kind: int = 3:
	set(value):
		kind = value
		_update_bamboo_material()
		queue_redraw()
@export var variant: int = 0:
	set(value):
		variant = value
		queue_redraw()

var _wind_time: float = 0.0
var _rest_rotation: float = 0.0

@export_range(40.0, 800.0, 10.0) var fence_width: float = 160.0:
	set(value):
		fence_width = value
		queue_redraw()


func _ready() -> void:
	_update_bamboo_material()
	_rest_rotation = rotation
	if kind == 2 and not Engine.is_editor_hint():
		var light := PointLight2D.new()
		light.name = "LanternLight"
		light.texture = preload("res://src/world/soft_lantern_light.tres")
		light.position = Vector2(0.0, -46.5)
		light.color = Color("#ffd58d")
		light.energy = 0.2
		light.texture_scale = 4.2
		light.add_to_group("day_night_lights")
		add_child(light)


func _process(delta: float) -> void:
	if kind == 6 and not Engine.is_editor_hint():
		_wind_time += delta
		rotation = _rest_rotation + sin(_wind_time * 0.8 + float(variant)) * 0.006


const _LANTERN_TEX: Texture2D = preload("res://assets/asset/ChatGPT Image Oct 25, 2026, 09_46_53 AM.png")
const _BAMBOO_MATERIAL: ShaderMaterial = preload("res://src/world/foreground_bamboo.tres")

func _update_bamboo_material() -> void:
	if kind == 6:
		material = _BAMBOO_MATERIAL
	elif material == _BAMBOO_MATERIAL:
		material = null

var _batch = preload("res://src/world/canvas_shape_batch.gd").new()
var _texture_batch = preload("res://src/world/bamboo_atlas_brush.gd").new()


func _draw() -> void:
	_batch.clear()
	_texture_batch.clear()
	match kind:
		0: _cottage()
		1: _fence()
		2: _lantern()
		3: _rocks()
		4: _ferns()
		5: _bench()
		6: _bamboo()
		7: _sign()

	_batch.submit(self)
	_texture_batch.submit(self)


func _poly(points: Array, color: String) -> void:
	_batch.polygon(PackedVector2Array(points), Color(color))


func _oval(at: Vector2, radius: float, color: Color, flatten: float = 0.3) -> void:
	_batch.set_transform(at, 0, Vector2(1, flatten))
	_batch.circle(Vector2.ZERO, radius, color)
	_batch.set_transform(Vector2.ZERO)


func _cottage() -> void:
	_oval(Vector2(0, -1), 173, Color(0.12, 0.21, 0.15, 0.2))
	# Stone footing directly on the shared ground baseline.
	_poly([Vector2(-149, 0), Vector2(-144, -23), Vector2(149, -23), Vector2(154, 0)], "#626c60")
	for x in range(-140, 145, 32):
		_batch.line(Vector2(x, -20), Vector2(x + 3, -2), Color("#8e9681"), 1.5, true)
	_batch.rect(Rect2(-135, -167, 269, 145), Color("#d0bb8c"))
	_poly([Vector2(-134, -167), Vector2(-4, -224), Vector2(135, -167)], "#d9c695")
	for x in range(-128, 134, 14):
		_batch.line(Vector2(x, -160), Vector2(x, -25), Color(0.43, 0.40, 0.25, 0.15), 1.0, true)
	for x in [-135, -28, 134]:
		_batch.rect(Rect2(x - 4, -166, 8, 145), Color("#66573c"))
	_batch.rect(Rect2(-136, -38, 270, 9), Color("#827044"))
	# Rounded layered green thatch roof, with distinct eaves and ridge.
	_poly([Vector2(-176, -150), Vector2(-142, -177), Vector2(-13, -243), Vector2(19, -240), Vector2(139, -177), Vector2(174, -150), Vector2(149, -140), Vector2(-148, -140)], "#344e3c")
	_poly([Vector2(-164, -155), Vector2(-12, -234), Vector2(15, -232), Vector2(161, -155), Vector2(148, -149), Vector2(-148, -149)], "#668052")
	_poly([Vector2(-155, -155), Vector2(-8, -225), Vector2(16, -224), Vector2(91, -183), Vector2(10, -207), Vector2(-114, -155)], "#89a267")
	for row in range(4):
		var y: float = -158.0 - float(row) * 14.0
		var half: float = 144.0 - float(row) * 28.0
		_batch.line(Vector2(-half, y), Vector2(half, y), Color(0.15, 0.28, 0.18, 0.25), 2, true)
	_batch.line(Vector2(-14, -242), Vector2(20, -240), Color("#b1bd78"), 6, true)
	# Door, glowing paper window, veranda and handmade details.
	_batch.rect(Rect2(-18, -119, 65, 97), Color("#554937"))
	_batch.rect(Rect2(-11, -112, 51, 90), Color("#8e7047"))
	for x in [-1, 12, 25]:
		_batch.line(Vector2(x, -109), Vector2(x, -23), Color("#a18756"), 1.5, true)
	_batch.circle(Vector2(30, -65), 2.5, Color("#e3c274"))
	_batch.rect(Rect2(-104, -123, 62, 65), Color("#675638"))
	_batch.rect(Rect2(-99, -118, 52, 55), Color("#efcc85"))
	for x in [-82, -64]:
		_batch.line(Vector2(x, -118), Vector2(x, -63), Color("#82693e"), 3.0, true)
	_batch.line(Vector2(-100, -91), Vector2(-46, -91), Color("#82693e"), 3.0, true)
	_poly([Vector2(-24, -119), Vector2(48, -119), Vector2(65, -109), Vector2(-35, -109)], "#56724c")
	_batch.rect(Rect2(-45, -18, 116, 9), Color("#b0a076"))
	_batch.rect(Rect2(-30, -8, 88, 8), Color("#8e8666"))
	_fence_at(Vector2(67, -20), 59.0)
	# Chimney and earthen pots, all in the same canvas style.
	_batch.rect(Rect2(93, -224, 24, 51), Color("#7e8372"))
	_batch.rect(Rect2(88, -227, 34, 8), Color("#b5b89c"))
	_pot(Vector2(-119, -25), 14.0)
	_pot(Vector2(119, -25), 12.0)
	_leaf_cluster(Vector2(-119, -51), Color("#62854c"), 16.0)
	_batch.line(Vector2(113, -144), Vector2(113, -127), Color("#605c3c"), 1.5, true)
	_oval(Vector2(113, -117), 10.0, Color("#edbe73"), 1.2)
	_batch.line(Vector2(102, -126), Vector2(124, -126), Color("#745b37"), 3.0, true)
	_batch.line(Vector2(102, -107), Vector2(124, -107), Color("#745b37"), 3.0, true)
	# Stacked cut bamboo by the wall.
	for i in range(5):
		_batch.circle(Vector2(78 + i % 3 * 13, -31 - i / 3 * 12), 7, Color("#c0b37d"))
		_batch.circle(Vector2(78 + i % 3 * 13, -31 - i / 3 * 12), 4, Color("#716f45"))


func _fence() -> void:
	_fence_at(Vector2(-fence_width * 0.5, 0), fence_width)


func _fence_at(at: Vector2, width: float) -> void:
	for y in [-33.0, -16.0]:
		_batch.line(at + Vector2(0, y), at + Vector2(width, y + 2), Color("#9c925e"), 5, true)
		_batch.line(at + Vector2(0, y - 1.5), at + Vector2(width, y + 0.5), Color("#c0b77e"), 1, true)
	var posts: int = maxi(2, int(width / 40.0) + 1)
	for i in range(posts):
		var x: float = width * float(i) / float(posts - 1)
		_batch.line(at + Vector2(x, 0), at + Vector2(x - 2, -47 - i % 2 * 4), Color("#7f8050"), 7, true)
		for joint in [-12.0, -37.0]:
			_batch.line(at + Vector2(x - 4, joint), at + Vector2(x + 3, joint), Color("#d1c386"), 2, true)


func _lantern() -> void:
	# Contact shadow underneath the mossy stone base
	_oval(Vector2(0, 0), 24.0, Color(0.12, 0.19, 0.13, 0.28), 0.35)
	_batch.submit(self)
	_batch.clear()

	if _LANTERN_TEX:
		var scale_factor: float = 0.05
		var w: float = _LANTERN_TEX.get_width() * scale_factor
		var h: float = _LANTERN_TEX.get_height() * scale_factor
		var base_x: float = 512.0 * scale_factor
		var base_y: float = 1450.0 * scale_factor
		if variant == 1:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect(_LANTERN_TEX, Rect2(-base_x, -base_y, w, h), false, Color(0.64, 0.68, 0.65))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect(_LANTERN_TEX, Rect2(-base_x, -base_y, w, h), false, Color(0.64, 0.68, 0.65))


func _rocks() -> void:
	_oval(Vector2(0, -1), 40, Color(0.14, 0.20, 0.14, 0.17))
	_poly([Vector2(-37, 0), Vector2(-40, -15), Vector2(-24, -38), Vector2(2, -48), Vector2(29, -33), Vector2(42, -12), Vector2(37, 0)], "#707c70")
	_poly([Vector2(-24, -38), Vector2(2, -48), Vector2(29, -33), Vector2(13, -19), Vector2(-8, -22)], "#98a08a")
	_poly([Vector2(13, -19), Vector2(29, -33), Vector2(42, -12), Vector2(37, 0), Vector2(11, -1)], "#586b61")
	_poly([Vector2(-39, -13), Vector2(-25, -34), Vector2(-4, -40), Vector2(4, -34), Vector2(-11, -27), Vector2(-27, -20)], "#7c965c")
	_batch.line(Vector2(-17, -25), Vector2(-8, -9), Color("#5b695e"), 1.3, true)
	_leaf_cluster(Vector2(24, -2), Color("#547746"), 12)


func _ferns() -> void:
	for i in range(7):
		var angle: float = -PI + 0.3 + float(i) * 0.42
		var length: float = 24.0 + sin(float(i) * 1.7) * 9.0
		var tip := Vector2(cos(angle), sin(angle)) * length
		_batch.line(Vector2.ZERO, tip, Color("#90a965"), 1.2, true)
		for j in range(1, 6):
			var at: Vector2 = tip * float(j) / 6.0
			var cross: Vector2 = tip.normalized().orthogonal() * (7.0 - j * 0.7)
			var next: Vector2 = at + tip.normalized() * 7.0
			_batch.polygon(PackedVector2Array([at, at + cross, next, at - cross]), Color("#426d45") if i % 2 else Color("#698a4d"))


func _bench() -> void:
	_oval(Vector2(0, 0), 50, Color(0.12, 0.19, 0.13, 0.18))
	for x in [-35, 28]:
		_batch.rect(Rect2(x, -21, 8, 21), Color("#766449"))
	_batch.rect(Rect2(-47, -27, 94, 9), Color("#ad986d"))
	_batch.line(Vector2(-44, -26), Vector2(44, -26), Color("#d1ba84"), 2, true)
	_pot(Vector2(17, -28), 8)
	_batch.rect(Rect2(-15, -34, 9, 6), Color("#d8cca2"))


func _bamboo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7100 + variant * 139
	var count: int = 4 + variant % 4
	for i in range(count):
		var x: float = (float(i) - float(count - 1) * 0.5) * rng.randf_range(13, 19)
		var height: float = rng.randf_range(190, 295)
		var lean: float = x * 0.0018 + rng.randf_range(-0.04, 0.04)
		_texture_batch.culm(Vector2(x, 0), height, rng.randf_range(9, 13), lean, rng)
	_ferns()


func _sign() -> void:
	_batch.rect(Rect2(-4, -54, 8, 54), Color("#827450"))
	_poly([Vector2(-30, -64), Vector2(20, -64), Vector2(34, -53), Vector2(20, -43), Vector2(-30, -43)], "#b9a373")
	_batch.line(Vector2(-14, -53), Vector2(15, -53), Color("#6c6c48"), 2, true)
	_batch.line(Vector2(10, -58), Vector2(16, -53), Color("#6c6c48"), 2, true)
	_batch.line(Vector2(10, -48), Vector2(16, -53), Color("#6c6c48"), 2, true)


func _pot(at: Vector2, size: float) -> void:
	_batch.polygon(PackedVector2Array([at + Vector2(-size * 0.75, 0), at + Vector2(-size, -size * 1.5), at + Vector2(size, -size * 1.5), at + Vector2(size * 0.75, 0)]), Color("#a37953"))
	_batch.line(at + Vector2(-size, -size * 1.5), at + Vector2(size, -size * 1.5), Color("#c49d6d"), 3, true)


func _leaf_cluster(at: Vector2, color: Color, length: float) -> void:
	for i in range(9):
		var angle: float = -PI + float(i) * PI / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		var tip: Vector2 = at + dir * length
		var mid: Vector2 = at + dir * length * 0.45
		var side: Vector2 = dir.orthogonal() * length * 0.12
		_batch.polygon(PackedVector2Array([at, mid + side, tip, mid - side]), color.lightened(float(i % 3) * 0.04))

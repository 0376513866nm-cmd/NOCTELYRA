class_name BossShockwave
extends Area2D

## Sóng ma lực Hắc Nguyệt Chấn Ba của Boss Lunareth (M4)
## Lan truyền trên mặt đất, gây 25 sát thương, có thể nhảy qua để né.

@export var speed: float = 380.0
@export var damage: float = 25.0
@export var knockback_force: float = 240.0
@export var direction: float = -1.0
@export var max_lifetime: float = 2.8

var is_phase_2: bool = false
var _time_alive: float = 0.0
var _hit_nodes: Array[Node] = []

@onready var visual_wave: ColorRect = $VisualWave
@onready var core_glow: ColorRect = $VisualWave/CoreGlow

func _ready() -> void:
	add_to_group(GameGroups.BOSS_PROJECTILES)
	collision_layer = 0
	collision_mask = 2 # Player Hurtbox nằm trên Layer 2
	area_entered.connect(_on_area_entered)
	_apply_visuals()

func setup(p_direction: float, p_is_phase_2: bool = false) -> void:
	direction = sign(p_direction)
	if direction == 0.0:
		direction = -1.0
	is_phase_2 = p_is_phase_2
	speed = 440.0 if is_phase_2 else 380.0
	_apply_visuals()

func _apply_visuals() -> void:
	var wave_node: ColorRect = visual_wave if visual_wave else get_node_or_null("VisualWave") as ColorRect
	var glow_node: ColorRect = core_glow if core_glow else get_node_or_null("VisualWave/CoreGlow") as ColorRect

	if wave_node:
		if is_phase_2:
			wave_node.color = Color(0.95, 0.15, 0.85, 0.9)
		else:
			wave_node.color = Color(0.3, 0.75, 1.0, 0.9)

	if glow_node:
		if is_phase_2:
			glow_node.color = Color(1.0, 0.7, 1.0, 1.0)
		else:
			glow_node.color = Color(0.8, 0.95, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	position.x += direction * speed * delta

	# Hiệu ứng gợn sóng nhấp nhô
	var wave_node: ColorRect = visual_wave if visual_wave else get_node_or_null("VisualWave") as ColorRect
	if wave_node:
		wave_node.scale.y = 1.0 + sin(_time_alive * 25.0) * 0.15

	if _time_alive >= max_lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.owner_node in _hit_nodes:
			return # Đã trúng rồi, không gây sát thương trùng

		var knock_dir := Vector2(direction, -0.3).normalized()
		var dmg_info := DamageInfo.new(damage, self, knock_dir, knockback_force)
		var success := hurtbox.apply_damage(dmg_info)
		if success:
			_hit_nodes.append(hurtbox.owner_node)
			# Biến mất sau khi đâm trúng
			queue_free()

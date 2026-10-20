class_name EnemyProjectile
extends Area2D

## Đạn ma pháp của quái vật (Enemy Projectile) cho NOCTELYRA (Milestone M7)
## Hỗ trợ đạn ma pháp của Linh Hồn Tinh Mạch và cầu lửa của Hỏa Tích Hắc Nham.

@export var speed: float = 300.0
@export var damage: float = 12.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var source_enemy: Node = null
var _time_alive: float = 0.0

@onready var visual_core: ColorRect = $VisualCore
@onready var visual_glow: ColorRect = $VisualGlow

func _ready() -> void:
	add_to_group("enemy_projectiles")
	collision_layer = 0
	collision_mask = 2 # Player Hurtbox nằm ở Layer 2
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, dmg: float, spd: float, col: Color, src: Node = null) -> void:
	direction = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	damage = dmg
	speed = spd
	source_enemy = src

	if visual_core:
		visual_core.color = col.lightened(0.3)
	if visual_glow:
		visual_glow.color = Color(col.r, col.g, col.b, 0.45)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox and is_instance_valid(area):
		var dinfo := DamageInfo.new(damage, source_enemy)
		dinfo.knockback_dir = direction
		dinfo.knockback_force = 120.0
		area.apply_damage(dinfo)
		queue_free()

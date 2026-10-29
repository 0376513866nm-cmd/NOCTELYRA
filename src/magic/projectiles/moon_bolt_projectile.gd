class_name MoonBoltProjectile
extends Area2D

## Projectile Nguyệt Quang Đạn (M5 - moon_bolt)
## Sát thương đơn mục tiêu, bay thẳng tốc độ 550 px/s, tan biến khi trúng địch hoặc vật cản.

@export var speed: float = 550.0
@export var damage_amount: float = 30.0
@export var lifetime: float = 2.5
@export var knockback_force: float = 250.0

var damage: float:
	get:
		return damage_amount

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null
var _timer: float = 0.0

func setup(p_direction: Vector2, p_shooter: Node, p_damage: float = 30.0) -> void:
	direction = p_direction.normalized()
	shooter = p_shooter
	damage_amount = p_damage
	rotation = direction.angle()

func _ready() -> void:
	add_to_group(GameGroups.PLAYER_PROJECTILES)
	collision_layer = 8
	collision_mask = 5 # Hurtbox kẻ địch/Boss (Layer 4) & Địa hình StaticBody2D (Layer 1)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.owner_node == shooter:
			return
		var dmg_info := DamageInfo.new(damage_amount, shooter, direction, knockback_force)
		hurtbox.apply_damage(dmg_info)
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body is TileMap or body is StaticBody2D:
		queue_free()

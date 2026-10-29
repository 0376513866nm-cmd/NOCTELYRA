class_name FrostShardProjectile
extends Area2D

## Projectile Hàn Tinh Tiễn (M5 - frost_shard)
## Tốc độ 650 px/s. Sát thương 20, làm chậm 35% tốc độ quái thường trong 2 giây.
## Boss Lunareth miễn nhiễm hiệu ứng làm chậm.

@export var speed: float = 650.0
@export var damage_amount: float = 20.0
@export var slow_ratio: float = 0.35
@export var slow_duration: float = 2.0
@export var lifetime: float = 2.2
@export var knockback_force: float = 200.0

var damage: float:
	get:
		return damage_amount

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null
var _timer: float = 0.0

func setup(p_direction: Vector2, p_shooter: Node, p_damage: float = 20.0) -> void:
	direction = p_direction.normalized()
	shooter = p_shooter
	damage_amount = p_damage
	rotation = direction.angle()

func _ready() -> void:
	add_to_group(GameGroups.PLAYER_PROJECTILES)
	collision_layer = 16
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
		var taken := hurtbox.apply_damage(dmg_info)
		if taken:
			# Áp dụng hiệu ứng làm chậm nếu mục tiêu là quái thường có phương thức apply_slow
			var target = hurtbox.owner_node
			if target and target.has_method("apply_slow"):
				target.apply_slow(slow_ratio, slow_duration)

		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body is TileMap or body is StaticBody2D:
		queue_free()

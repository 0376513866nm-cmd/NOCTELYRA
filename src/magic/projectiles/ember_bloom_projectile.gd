class_name EmberBloomProjectile
extends Area2D

## Projectile Tinh Hỏa Bùng Nổ (M5 - ember_bloom)
## Tốc độ 380 px/s. Khi chạm kẻ địch hoặc địa hình, phát nổ diện rộng bán kính 110 px.
## Mỗi mục tiêu trong vùng nổ chỉ nhận sát thương đúng một lần.

@export var speed: float = 380.0
@export var damage_amount: float = 22.0
@export var explosion_radius: float = 110.0
@export var lifetime: float = 2.8
@export var knockback_force: float = 280.0

var damage: float:
	get:
		return damage_amount

var direction: Vector2 = Vector2.RIGHT
var shooter: Node = null
var _timer: float = 0.0
var _exploded: bool = false
var _explosion_decay: float = 0.25

@onready var visual_core: ColorRect = $VisualCore
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_shape: CollisionShape2D = $ExplosionArea/CollisionShape2D
@onready var visual_explosion: ColorRect = $ExplosionArea/VisualExplosion

func setup(p_direction: Vector2, p_shooter: Node, p_damage: float = 22.0) -> void:
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

	if explosion_area:
		explosion_area.monitoring = false
		explosion_area.visible = false

func _physics_process(delta: float) -> void:
	if _exploded:
		_explosion_decay -= delta
		if _explosion_decay <= 0.0:
			queue_free()
		return

	global_position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		trigger_explosion()

func _on_area_entered(area: Area2D) -> void:
	if _exploded:
		return
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.owner_node == shooter:
			return
		trigger_explosion()

func _on_body_entered(body: Node) -> void:
	if _exploded or body == shooter:
		return
	if body is TileMap or body is StaticBody2D:
		trigger_explosion()

func _trigger_explosion() -> void:
	trigger_explosion()

func trigger_explosion() -> void:
	if _exploded:
		return
	_exploded = true

	# Ẩn đạn bay
	if visual_core:
		visual_core.visible = false
	var direct_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if direct_col:
		direct_col.disabled = true

	# Kích hoạt vùng nổ bán kính 110 px
	if explosion_area and explosion_shape:
		explosion_area.set_deferred("monitoring", true)
		explosion_area.visible = true

	# Quét và áp dụng sát thương ngay lập tức cho tất cả mục tiêu trong vùng nổ
	var hit_targets: Array[Node] = []
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsShapeQueryParameters2D.new()
	if explosion_shape and explosion_shape.shape:
		params.shape_rid = explosion_shape.shape.get_rid()
	else:
		var query_shape := CircleShape2D.new()
		query_shape.radius = explosion_radius
		params.shape = query_shape
	params.transform = Transform2D(0.0, global_position)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 4 # Chỉ quét Layer 4 (Hurtbox kẻ địch & Boss)

	var results := space_state.intersect_shape(params, 32)
	for res in results:
		var collider = res.get("collider")
		if collider is Hurtbox:
			var hb := collider as Hurtbox
			if hb.owner_node != shooter and not (hb.owner_node in hit_targets):
				hit_targets.append(hb.owner_node)
				var hit_dir := (hb.global_position - global_position).normalized()
				if hit_dir == Vector2.ZERO:
					hit_dir = direction
				var dmg_info := DamageInfo.new(damage_amount, shooter, hit_dir, knockback_force)
				hb.apply_damage(dmg_info)

	# Quét trực tiếp kẻ địch và boss trong bán kính nổ (đảm bảo phản hồi tức thì kể cả giữa physics frames)
	if get_tree():
		var potential_targets: Array[Node] = []
		potential_targets.append_array(get_tree().get_nodes_in_group(GameGroups.ENEMIES))
		potential_targets.append_array(get_tree().get_nodes_in_group(GameGroups.BOSSES))
		var cur_scene := get_tree().current_scene
		if cur_scene:
			for ch in cur_scene.get_children():
				if (ch is Enemy or ch.name == "BossLunareth") and not potential_targets.has(ch):
					potential_targets.append(ch)

		for t in potential_targets:
			if t is Node2D and not (t in hit_targets) and t != shooter:
				var hb := t.get_node_or_null("Hurtbox") as Hurtbox
				if hb:
					var target_pos := hb.global_position
					var dist := global_position.distance_to(target_pos)
					if dist <= explosion_radius:
						hit_targets.append(t)
						var hit_dir := (target_pos - global_position).normalized()
						if hit_dir == Vector2.ZERO:
							hit_dir = direction
						var dmg_info := DamageInfo.new(damage_amount, shooter, hit_dir, knockback_force)
						hb.apply_damage(dmg_info)

	# Hiệu ứng nổ sẽ tự tan biến sau _explosion_decay trong _physics_process

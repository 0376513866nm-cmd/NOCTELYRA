class_name Enemy
extends CharacterBody2D

## Hệ thống Kẻ Địch Đa Dạng (Modular Enemy System) cho NOCTELYRA (Milestone M7)
## Hỗ trợ 4 chủng loại quái mới (Mooncap, Mana Wisp, Ashfang Wolf, Ember Lizard)
## và 3 kiểu tấn công (MELEE, LUNGE, RANGED), có báo trước (TELEGRAPH), hồi phục (RECOVERY),
## tuần tra, giới hạn truy đuổi (leash), và ngừng tấn công khi Player tử vong.

signal state_changed(new_state_name: String)
signal enemy_defeated(enemy_node: Node)
signal enemy_respawned(enemy_node: Node)

enum State {
	IDLE,
	PATROL,
	CHASE,
	TELEGRAPH,
	ATTACK,
	RECOVERY,
	HURT,
	DEAD
}

@export var enemy_id: String = ""
@export var enemy_type_id: String = "corrupted_wolf"
@export var definition: EnemyDefinition = null
@export var loot_table: LootTable = null
@export var can_respawn: bool = true
@export_range(1.0, 300.0, 1.0) var respawn_delay: float = 20.0

# Thuộc tính cơ bản (được nạp / ghi đè từ definition)
@export var move_speed: float = 120.0
@export var detection_range: float = 380.0
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.2
@export var gravity: float = 1100.0
@export_range(8.0, 64.0, 1.0) var auto_hop_max_height: float = 48.0
@export_range(1.0, 2.0, 0.1) var blocked_return_delay: float = 1.5

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var visual_root: Node2D = $VisualRoot
@onready var hp_bar: ProgressBar = $VisualRoot/HPBar

var current_state: State = State.IDLE
var target_player: Player = null
var facing_direction: int = -1
var attack_timer: float = 0.0
var state_timer: float = 0.0
var _has_reported_death: bool = false
var _respawn_timer: float = 0.0
var _initial_collision_layer: int
var _reward_life_id: String = ""
var _hop_cooldown: float = 0.0
var _blocked_time: float = 0.0
var _aggro_retry_timer: float = 0.0

var _spawn_position: Vector2 = Vector2.ZERO
var _patrol_target_x: float = 0.0
var _patrol_wait_timer: float = 0.0
var _is_returning: bool = false

var _base_move_speed: float = 120.0
var _is_slowed: bool = false
var _slow_timer: float = 0.0
var _slow_ratio: float = 0.0

# Scene đạn quái mặc định
const EnemyProjectileScene = preload("res://src/actors/enemy/enemy_projectile.tscn")

func _ready() -> void:
	_initial_collision_layer = collision_layer
	_spawn_position = global_position
	_patrol_target_x = global_position.x

	# 1. Khởi tạo EnemyDefinition nếu chưa cấu hình
	if definition == null:
		definition = EnemyDefinition.create_default(enemy_type_id)

	# 2. Áp dụng thông số từ Definition
	_apply_definition()

	# 3. Kết nối linh kiện chiến đấu
	if attack_hitbox:
		attack_hitbox.set_deferred("monitoring", false)
		attack_hitbox.visible = false
		attack_hitbox.damage = definition.attack_damage if definition else 15.0

	if health_component:
		if definition:
			health_component.max_health = definition.max_health
			health_component.current_health = definition.max_health
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		if hp_bar:
			hp_bar.max_value = health_component.max_health
			hp_bar.value = health_component.current_health

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	# 4. Áp dụng phong cách hiển thị hình ảnh
	if visual_root and visual_root.has_method("apply_type_style"):
		visual_root.apply_type_style(enemy_type_id)

	_change_state(State.IDLE)

func _apply_definition() -> void:
	if definition == null:
		return
	enemy_type_id = definition.enemy_type_id
	move_speed = definition.move_speed
	_base_move_speed = definition.move_speed
	detection_range = definition.detection_range
	attack_range = definition.attack_range
	attack_cooldown = definition.attack_cooldown

func _physics_process(delta: float) -> void:
	# Keep the spawn and signal connections alive while a regular monster respawns.
	if current_state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		state_timer -= delta
		if visual_root:
			visual_root.modulate.a = max(0.0, state_timer / 1.0)
		if state_timer <= 0.0:
			visible = false
			if not can_respawn:
				queue_free()
		_respawn_timer -= delta
		if can_respawn and _respawn_timer <= 0.0:
			respawn()
			return
		move_and_slide()
		return

	if attack_timer > 0.0:
		attack_timer -= delta
	_hop_cooldown = maxf(0.0, _hop_cooldown - delta)
	_aggro_retry_timer = maxf(0.0, _aggro_retry_timer - delta)

	# Cập nhật hiệu ứng làm chậm (Frost Shard)
	if _is_slowed:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_is_slowed = false
			move_speed = _base_move_speed
			if visual_root and current_state != State.DEAD:
				visual_root.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Trọng lực (chỉ áp dụng với sinh vật không bay)
	var is_flying: bool = definition.is_flying if definition else false
	if not is_flying:
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		velocity.y = move_toward(velocity.y, 0.0, 400.0 * delta)

	# Kiểm tra người chơi: Ngừng tấn công ngay lập tức khi Player tử vong
	if target_player and is_instance_valid(target_player):
		var p_health: HealthComponent = target_player.get_node_or_null("HealthComponent")
		if p_health and not p_health.is_alive():
			target_player = null
			_is_returning = false
			if attack_hitbox:
				attack_hitbox.set_deferred("monitoring", false)
				attack_hitbox.visible = false
			_change_state(State.IDLE)

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			var dist_to_spawn: float = abs(global_position.x - _spawn_position.x)
			var max_leash: float = definition.leash_distance if definition else 500.0
			if dist_to_spawn > max_leash:
				# Vượt quá phạm vi giới hạn -> Rút lui về điểm xuất phát
				_is_returning = true
				_patrol_target_x = _spawn_position.x
				_change_state(State.PATROL)
			else:
				_find_target()
				if target_player and _is_target_in_range(detection_range) and not _is_returning:
					_change_state(State.CHASE)
				else:
					_patrol_wait_timer -= delta
					if _patrol_wait_timer <= 0.0:
						_start_patrol_step()

		State.PATROL:
			var dist_to_spawn: float = abs(global_position.x - _spawn_position.x)
			var max_leash: float = definition.leash_distance if definition else 500.0

			if _is_returning:
				var dist_to_pt := _patrol_target_x - global_position.x
				if abs(dist_to_pt) <= 12.0:
					_is_returning = false
					_change_state(State.IDLE)
				else:
					var pdir: float = sign(dist_to_pt)
					_set_facing(int(pdir))
					velocity.x = pdir * (move_speed * 0.7)
			else:
				_find_target()
				if target_player and _is_target_in_range(detection_range) and dist_to_spawn < max_leash:
					_change_state(State.CHASE)
				else:
					var dist_to_pt := _patrol_target_x - global_position.x
					if abs(dist_to_pt) <= 8.0:
						_change_state(State.IDLE)
					else:
						var pdir: float = sign(dist_to_pt)
						_set_facing(int(pdir))
						velocity.x = pdir * (move_speed * 0.6)

		State.CHASE:
			if target_player == null or not is_instance_valid(target_player):
				_change_state(State.IDLE)
				return

			var dist_to_player: float = global_position.distance_to(target_player.global_position)
			var dist_to_spawn: float = abs(global_position.x - _spawn_position.x)
			var max_leash: float = definition.leash_distance if definition else 500.0

			# Chống truy đuổi vô hạn ra khỏi khu vực hoạt động (Leash protection)
			if dist_to_spawn > max_leash or dist_to_player > detection_range * 1.5:
				target_player = null
				_is_returning = true
				_patrol_target_x = _spawn_position.x
				_change_state(State.PATROL)
			elif dist_to_player <= attack_range and _has_clear_attack_path():
				velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
				var dx: float = target_player.global_position.x - global_position.x
				if abs(dx) > 12.0:
					_set_facing(int(sign(dx)))
				if visual_root and attack_timer > 0.0:
					visual_root.set_visual_state("idle")
				if attack_timer <= 0.0:
					_change_state(State.TELEGRAPH)
			else:
				var dx: float = target_player.global_position.x - global_position.x
				if abs(dx) > 12.0:
					var dir: float = sign(dx)
					_set_facing(int(dir))
					velocity.x = dir * move_speed
					if visual_root:
						visual_root.set_visual_state("move")
				else:
					velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
					if visual_root:
						visual_root.set_visual_state("idle")

		State.TELEGRAPH:
			# Dừng lại để báo trước đòn đánh (cho Player cơ hội phản ứng né/chắn)
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_change_state(State.ATTACK)

		State.ATTACK:
			_process_attack(delta)

		State.RECOVERY:
			# Nghỉ hồi phục sau đòn đánh (Player có thể phản công an toàn)
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				if target_player and _is_target_in_range(detection_range):
					_change_state(State.CHASE)
				else:
					_change_state(State.IDLE)

		State.HURT:
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_timer <= 0.0:
				if target_player:
					_change_state(State.CHASE)
				else:
					_change_state(State.IDLE)

	var navigating := current_state in [State.CHASE, State.PATROL] and not is_flying
	var intended_speed := velocity.x
	var before_move := global_position
	if navigating:
		_try_low_hop()
	move_and_slide()
	if navigating and is_on_floor() and absf(intended_speed) > 5.0:
		var progress := absf(global_position.x - before_move.x)
		if is_on_wall() and progress < absf(intended_speed) * delta * 0.25:
			_blocked_time += delta
			if _blocked_time >= blocked_return_delay:
				_abandon_blocked_path(signf(intended_speed))
		else:
			_blocked_time = 0.0
	else:
		_blocked_time = 0.0

func _has_clear_attack_path() -> bool:
	if definition and definition.is_flying:
		return true
	if not is_instance_valid(target_player):
		return false
	# A ground creature must not repeatedly lunge/shoot into a ledge between it and the target.
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -30), target_player.global_position + Vector2(0, -42), collision_mask, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _try_low_hop() -> bool:
	if not is_on_floor() or _hop_cooldown > 0.0 or absf(velocity.x) < 5.0:
		return false
	var dir := signf(velocity.x)
	var shape_node := get_node("CollisionShape2D") as CollisionShape2D
	var half_width := shape_node.shape.get_rect().size.x * absf(global_scale.x) * 0.5
	var reach := half_width + maxf(12.0, absf(velocity.x) * 0.14)
	var space := get_world_2d().direct_space_state
	var wall_query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -4), global_position + Vector2(dir * reach, -4), collision_mask, [get_rid()])
	var wall := space.intersect_ray(wall_query)
	if wall.is_empty() or absf(wall.normal.x) < 0.6:
		return false
	var landing_x: float = wall.position.x + dir * (half_width + 4.0)
	var top_query := PhysicsRayQueryParameters2D.create(Vector2(landing_x, global_position.y - auto_hop_max_height - 4.0), Vector2(landing_x, global_position.y - 2.0), collision_mask, [get_rid()])
	var top := space.intersect_ray(top_query)
	if top.is_empty():
		return false
	var rise: float = global_position.y - top.position.y
	if rise < 4.0 or rise > auto_hop_max_height:
		return false
	var lift := Vector2(0, -rise - 10.0)
	if test_move(global_transform, lift):
		return false
	if test_move(global_transform.translated(lift), Vector2(landing_x - global_position.x, 0)):
		return false
	velocity.y = -sqrt(2.0 * gravity * (rise + 14.0))
	_hop_cooldown = 0.45
	return true

func _abandon_blocked_path(direction: float) -> void:
	_blocked_time = 0.0
	target_player = null
	_aggro_retry_timer = 5.0
	if _is_returning:
		# If the return route is also inaccessible, back away on the reachable side.
		_is_returning = false
		_patrol_target_x = global_position.x - direction * 90.0
	else:
		_is_returning = true
		_patrol_target_x = _spawn_position.x
	_change_state(State.PATROL)
	var retreat := signf(_patrol_target_x - global_position.x)
	_set_facing(int(retreat))
	velocity.x = retreat * move_speed * 0.7

func _start_patrol_step() -> void:
	_patrol_wait_timer = randf_range(2.0, 4.0)
	var radius: float = definition.patrol_radius if definition else 150.0
	var offset: float = randf_range(-radius, radius)
	_patrol_target_x = _spawn_position.x + offset
	_change_state(State.PATROL)

func _process_attack(delta: float) -> void:
	var at_type: int = definition.attack_type if definition else EnemyDefinition.AttackType.MELEE
	match at_type:
		EnemyDefinition.AttackType.MELEE:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_change_state(State.RECOVERY)

		EnemyDefinition.AttackType.LUNGE:
			# Đòn lao tới (Ashfang Wolf)
			var l_speed: float = definition.lunge_speed if definition else 450.0
			velocity.x = float(facing_direction) * l_speed
			state_timer -= delta
			if state_timer <= 0.0:
				_change_state(State.RECOVERY)

		EnemyDefinition.AttackType.RANGED:
			# Đòn bắn tầm xa đã phóng đạn ở đầu state ATTACK
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_change_state(State.RECOVERY)

func _change_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return

	current_state = new_state
	var sname := _get_state_name(current_state)
	emit_signal("state_changed", sname)

	# Cập nhật visual state tương ứng
	if visual_root and visual_root.has_method("set_visual_state"):
		match current_state:
			State.IDLE: visual_root.set_visual_state("idle")
			State.PATROL, State.CHASE: visual_root.set_visual_state("move")
			State.TELEGRAPH: visual_root.set_visual_state("telegraph")
			State.ATTACK: visual_root.set_visual_state("attack")
			State.RECOVERY: visual_root.set_visual_state("idle")
			State.HURT: visual_root.set_visual_state("hit")
			State.DEAD: visual_root.set_visual_state("death")

	match current_state:
		State.IDLE:
			pass

		State.PATROL:
			pass

		State.CHASE:
			pass

		State.TELEGRAPH:
			state_timer = definition.telegraph_duration if definition else 0.4
			if attack_hitbox:
				attack_hitbox.set_deferred("monitoring", false)
				attack_hitbox.visible = false

		State.ATTACK:
			attack_timer = definition.attack_cooldown if definition else 1.2
			var at_type: int = definition.attack_type if definition else EnemyDefinition.AttackType.MELEE

			if at_type == EnemyDefinition.AttackType.RANGED:
				state_timer = 0.15
				_fire_projectile()
			else:
				state_timer = definition.attack_duration if definition else 0.65
				if attack_hitbox:
					attack_hitbox.damage = definition.attack_damage if definition else 15.0
					attack_hitbox.reset_hits() # Đảm bảo không gây sát thương lặp vô hạn trong 1 đòn
					attack_hitbox.set_deferred("monitoring", true)
					attack_hitbox.visible = true
					attack_hitbox.position.x = abs(attack_hitbox.position.x) * float(facing_direction)

		State.RECOVERY:
			state_timer = definition.recovery_duration if definition else 0.6
			if attack_hitbox:
				attack_hitbox.set_deferred("monitoring", false)
				attack_hitbox.visible = false

		State.HURT:
			state_timer = 0.25
			if attack_hitbox:
				attack_hitbox.set_deferred("monitoring", false)
				attack_hitbox.visible = false

		State.DEAD:
			state_timer = 1.0
			_respawn_timer = respawn_delay
			if attack_hitbox:
				attack_hitbox.set_deferred("monitoring", false)
				attack_hitbox.visible = false
			if hurtbox:
				hurtbox.set_deferred("monitoring", false)
				hurtbox.set_deferred("monitorable", false)
			set_deferred("collision_layer", 0)
			_notify_kill_once()

func restore_defeated_state() -> void:
	if not can_respawn:
		queue_free()
		return
	# A saved death starts a cooldown, without reporting another kill or dropping loot.
	current_state = State.DEAD
	_has_reported_death = true
	state_timer = 0.0
	_respawn_timer = respawn_delay
	visible = false
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	attack_hitbox.set_deferred("monitoring", false)
	attack_hitbox.visible = false
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)

func respawn() -> void:
	global_position = _spawn_position
	reset_physics_interpolation()
	velocity = Vector2.ZERO
	target_player = null
	_is_returning = false
	_is_slowed = false
	_slow_timer = 0.0
	_hop_cooldown = 0.0
	_blocked_time = 0.0
	_aggro_retry_timer = 0.0
	move_speed = _base_move_speed
	attack_timer = 0.0
	_patrol_target_x = _spawn_position.x
	_patrol_wait_timer = 1.0
	_has_reported_death = false
	_reward_life_id = str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())
	set_deferred("collision_layer", _initial_collision_layer)
	hurtbox.set_deferred("monitoring", true)
	hurtbox.set_deferred("monitorable", true)
	health_component.current_health = health_component.max_health
	health_component.cancel_invulnerability()
	health_component.health_changed.emit(health_component.current_health, health_component.max_health)
	visual_root.modulate = Color.WHITE
	visible = true
	# _change_state intentionally rejects transitions out of DEAD during combat.
	current_state = State.IDLE
	_change_state(State.IDLE)
	enemy_respawned.emit(self)

func get_exp_source_id() -> String:
	var stable_id := enemy_id if not enemy_id.is_empty() else str(get_instance_id())
	return "enemy:" + stable_id + (":life:" + _reward_life_id if not _reward_life_id.is_empty() else "")

func _fire_projectile() -> void:
	var spawn_parent = get_parent()
	if spawn_parent == null:
		return

	var proj := EnemyProjectileScene.instantiate() as EnemyProjectile
	if proj == null:
		return

	spawn_parent.add_child(proj)
	proj.global_position = global_position + Vector2(float(facing_direction) * 20.0, -20.0)

	var target_dir := Vector2(float(facing_direction), 0.0)
	if target_player and is_instance_valid(target_player):
		target_dir = (target_player.global_position - proj.global_position).normalized()

	var spd: float = definition.projectile_speed if definition else 300.0
	var dmg: float = definition.projectile_damage if definition else 12.0
	var col: Color = definition.projectile_color if definition else Color(0.8, 0.3, 1.0)
	proj.setup(target_dir, dmg, spd, col, self)

func _notify_kill_once() -> void:
	if not _has_reported_death:
		_has_reported_death = true
		emit_signal("enemy_defeated", self)
		_spawn_loot()

func _spawn_loot() -> void:
	var spawn_parent = get_parent()
	if spawn_parent:
		if loot_table:
			loot_table.spawn_loot(global_position, spawn_parent)
		else:
			var drop_id: String = "mana_shard"
			if definition and not definition.drop_item_id.is_empty():
				drop_id = definition.drop_item_id
			var pickup_scene: PackedScene = load("res://src/loot/item_pickup.tscn")
			if pickup_scene:
				var pickup := pickup_scene.instantiate() as ItemPickup
				if pickup:
					pickup.item_id = drop_id
					pickup.amount = 1
					pickup.is_dynamic = true
					pickup.pickup_id = "drop_en_" + str(Time.get_ticks_usec()) + "_" + str(randi() % 100000)
					pickup.global_position = global_position
					spawn_parent.add_child.call_deferred(pickup)

func _find_target() -> void:
	if _is_returning or _aggro_retry_timer > 0.0:
		return
	if target_player and is_instance_valid(target_player):
		return
	var players := get_tree().get_nodes_in_group("players") if get_tree() else []
	for p in players:
		var p_health: HealthComponent = p.get_node_or_null("HealthComponent")
		if p_health and p_health.is_alive():
			target_player = p as Player
			break

func _is_target_in_range(range_val: float) -> bool:
	if target_player and is_instance_valid(target_player):
		var p_health: HealthComponent = target_player.get_node_or_null("HealthComponent")
		if p_health and p_health.is_alive():
			return global_position.distance_to(target_player.global_position) <= range_val
	return false

func _set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	facing_direction = dir
	if visual_root:
		visual_root.scale.x = float(-facing_direction)

func _on_health_changed(cur: float, _max_v: float) -> void:
	if hp_bar:
		hp_bar.value = cur

func _on_hit_received(dmg: DamageInfo) -> void:
	if current_state == State.DEAD:
		return
	_is_returning = false
	velocity.x = dmg.knockback_dir.x * dmg.knockback_force
	velocity.y = -120.0
	_change_state(State.HURT)

func _on_died() -> void:
	_change_state(State.DEAD)

func get_current_speed() -> float:
	return move_speed

func apply_slow(ratio: float, duration: float) -> void:
	if current_state == State.DEAD:
		return
	if not _is_slowed:
		_base_move_speed = move_speed
		_is_slowed = true
	_slow_ratio = ratio
	_slow_timer = duration
	move_speed = _base_move_speed * (1.0 - _slow_ratio)
	if visual_root:
		visual_root.modulate = Color(0.6, 0.85, 1.0, 1.0)

func _get_state_name(st: State) -> String:
	match st:
		State.IDLE: return "IDLE"
		State.PATROL: return "PATROL"
		State.CHASE: return "CHASE"
		State.TELEGRAPH: return "TELEGRAPH"
		State.ATTACK: return "ATTACK"
		State.RECOVERY: return "RECOVERY"
		State.HURT: return "HURT"
		State.DEAD: return "DEAD"
		_: return "UNKNOWN"

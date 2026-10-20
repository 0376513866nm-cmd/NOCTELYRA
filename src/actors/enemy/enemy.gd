class_name Enemy
extends CharacterBody2D

signal state_changed(new_state_name: String)
signal enemy_defeated(enemy_node: Node)

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

@export var move_speed: float = 120.0
@export var detection_range: float = 380.0
@export var attack_range: float = 55.0
@export var attack_cooldown: float = 1.2
@export var gravity: float = 1100.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var visual_root: Node2D = $VisualRoot
@onready var body_rect: ColorRect = $VisualRoot/BodyRect
@onready var eye_rect: ColorRect = $VisualRoot/EyeRect
@onready var hp_bar: ProgressBar = $VisualRoot/HPBar

var current_state: State = State.IDLE
var target_player: Player = null
var facing_direction: int = -1
var attack_timer: float = 0.0
var state_timer: float = 0.0
var _has_reported_death: bool = false

func _ready() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.visible = false

	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
		if hp_bar:
			hp_bar.max_value = health_component.max_health
			hp_bar.value = health_component.current_health

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	_change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	# Nếu đã DEAD thì không bao giờ chạy bất kỳ logic AI hay rơi nào khác
	if current_state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		state_timer -= delta
		if visual_root:
			visual_root.modulate.a = max(0.0, state_timer / 1.0)
		if state_timer <= 0.0:
			queue_free()
		move_and_slide()
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	# Kiểm tra mục tiêu Player còn sống hay không
	if target_player and is_instance_valid(target_player):
		var p_health: HealthComponent = target_player.get_node_or_null("HealthComponent")
		if p_health and not p_health.is_alive():
			target_player = null # Bỏ mục tiêu nếu player đã chết
			if current_state == State.CHASE or current_state == State.ATTACK:
				_change_state(State.IDLE)

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_find_target()
			if target_player and _is_target_in_range(detection_range):
				_change_state(State.CHASE)

		State.CHASE:
			if target_player == null or not is_instance_valid(target_player):
				_change_state(State.IDLE)
				return

			var dist := global_position.distance_to(target_player.global_position)
			if dist > detection_range * 1.4:
				_change_state(State.IDLE)
			elif dist <= attack_range:
				if attack_timer <= 0.0:
					_change_state(State.ATTACK)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			else:
				var dir: float = sign(target_player.global_position.x - global_position.x)
				if dir != 0.0:
					_set_facing(int(dir))
					velocity.x = dir * move_speed

		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_finish_attack()

		State.HURT:
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if state_timer <= 0.0:
				if target_player:
					_change_state(State.CHASE)
				else:
					_change_state(State.IDLE)

	move_and_slide()

func _change_state(new_state: State) -> void:
	# Bảo đảm: Một khi đã DEAD thì KHÔNG THỂ bị ghi đè bởi bất kỳ state nào khác
	if current_state == State.DEAD:
		return

	current_state = new_state
	var sname := _get_state_name(current_state)
	emit_signal("state_changed", sname)

	match current_state:
		State.IDLE:
			if body_rect:
				body_rect.color = Color(0.8, 0.2, 0.2)
		State.CHASE:
			if body_rect:
				body_rect.color = Color(0.9, 0.35, 0.1)
		State.ATTACK:
			state_timer = 0.35
			attack_timer = attack_cooldown
			if body_rect:
				body_rect.color = Color(1.0, 0.8, 0.1)
			if attack_hitbox:
				attack_hitbox.reset_hits()
				attack_hitbox.monitoring = true
				attack_hitbox.visible = true
				attack_hitbox.position.x = abs(attack_hitbox.position.x) * float(facing_direction)
		State.HURT:
			state_timer = 0.25
			if body_rect:
				body_rect.color = Color(1.0, 1.0, 1.0)
			if attack_hitbox:
				attack_hitbox.monitoring = false
				attack_hitbox.visible = false
		State.DEAD:
			state_timer = 1.0
			if attack_hitbox:
				attack_hitbox.monitoring = false
				attack_hitbox.visible = false
			if hurtbox:
				hurtbox.set_deferred("monitoring", false)
				hurtbox.set_deferred("monitorable", false)
			collision_layer = 0
			_notify_kill_once()

func _notify_kill_once() -> void:
	if not _has_reported_death:
		_has_reported_death = true
		emit_signal("enemy_defeated", self)
		var quest_mgr: QuestManager = _get_quest_manager()
		if quest_mgr:
			quest_mgr.register_enemy_kill(self)

func _get_quest_manager() -> QuestManager:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		var mgr = cur_scene.get_node_or_null("QuestManager") as QuestManager
		if mgr:
			return mgr
	var p = get_parent()
	if p:
		var mgr = p.get_node_or_null("QuestManager") as QuestManager
		if mgr:
			return mgr
	return null

func _finish_attack() -> void:
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.visible = false
	if target_player:
		_change_state(State.CHASE)
	else:
		_change_state(State.IDLE)

func _find_target() -> void:
	if target_player and is_instance_valid(target_player):
		return
	var players := get_tree().get_nodes_in_group("players")
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

func _on_health_changed(cur: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.value = cur

func _on_hit_received(dmg: DamageInfo) -> void:
	if current_state == State.DEAD:
		return
	velocity.x = dmg.knockback_dir.x * dmg.knockback_force
	velocity.y = -120.0
	_change_state(State.HURT)

func _on_died() -> void:
	_change_state(State.DEAD)

func _get_state_name(st: State) -> String:
	match st:
		State.IDLE: return "IDLE"
		State.CHASE: return "CHASE"
		State.ATTACK: return "ATTACK"
		State.HURT: return "HURT"
		State.DEAD: return "DEAD"
		_: return "UNKNOWN"

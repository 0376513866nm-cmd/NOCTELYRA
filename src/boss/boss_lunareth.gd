class_name BossLunareth
extends CharacterBody2D

## Boss Lunareth — Linh Lộc Nguyệt Thực (M4)
## Linh thú bảo vệ Rừng Noctis bị ma lực hắc nguyệt tha hóa, cần được thanh tẩy.
## Quản lý State Machine FSM, hai đòn đánh, chuyển giai đoạn Phase 2, và cơ chế hồi sinh/reset.

const BossVisualScript = preload("res://src/boss/boss_visual.gd")

signal boss_state_changed(new_state_name: String)
signal boss_phase_changed(new_phase: int)
signal boss_health_changed(current: float, max_val: float)
signal boss_telegraph_started(skill_name: String, duration: float)
signal boss_defeated()

enum State {
	DORMANT,           # Chưa kích hoạt
	INTRO,             # Thức tỉnh / Thị uy khi Player bước vào đấu trường
	APPROACH,          # Tiếp cận Player
	TELEGRAPH,         # Cảnh báo trước đòn đánh (ít nhất 0.6s - 0.8s)
	ATTACK,            # Thi triển đòn đánh (Húc hoặc Sóng xung kích)
	RECOVERY,          # Thời gian nghỉ / Cơ hội phản công cho Player
	PHASE_TRANSITION,  # Chuyển đổi sang Giai đoạn 2 (khi HP <= 160)
	DEFEATED           # Đã thanh tẩy thành công
}

enum AttackType {
	HORN_CHARGE,       # Đòn 1: Nguyệt Giác Xung Kích (20 DMG, telegraph 0.7s)
	MOON_SHOCKWAVE     # Đòn 2: Hắc Nguyệt Chấn Ba (25 DMG, telegraph 0.9s)
}

@export var max_hp: float = 320.0
@export var move_speed_p1: float = 160.0
@export var move_speed_p2: float = 195.0
@export var charge_speed_p1: float = 550.0
@export var charge_speed_p2: float = 620.0
@export var recovery_time_p1: float = 1.4
@export var recovery_time_p2: float = 1.1 # Giảm ~21% thời gian nghỉ ở Phase 2
@export var gravity: float = 1100.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var charge_hitbox: Hitbox = $ChargeHitbox
@onready var boss_visual: Node2D = $BossVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_state: State = State.DORMANT
var current_attack: AttackType = AttackType.HORN_CHARGE
var is_phase_2: bool = false
var facing_direction: int = -1
var target_player: Player = null

var _state_timer: float = 0.0
var _charge_timer: float = 0.0
var _phase_2_triggered: bool = false
var _is_defeated: bool = false
var _attack_alternate: bool = false
var _initial_spawn_position: Vector2 = Vector2.ZERO

var shockwave_scene: PackedScene = preload("res://src/boss/boss_shockwave.tscn")

func _ready() -> void:
	_initial_spawn_position = global_position
	if charge_hitbox:
		charge_hitbox.monitoring = false
		charge_hitbox.visible = false
		charge_hitbox.damage = 20.0
		charge_hitbox.owner_node = self

	if health_component:
		health_component.max_health = max_hp
		health_component.current_health = max_hp
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	_change_state(State.DORMANT)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Kiểm tra người chơi
	if target_player == null or not is_instance_valid(target_player):
		_find_player()

	match current_state:
		State.DORMANT:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			move_and_slide()

		State.INTRO:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_change_state(State.APPROACH)
			move_and_slide()

		State.APPROACH:
			_process_approach(delta)

		State.TELEGRAPH:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_change_state(State.ATTACK)
			move_and_slide()

		State.ATTACK:
			_process_attack(delta)

		State.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_state_timer -= delta
			# Boss không tấn công khi Player đã chết
			if _is_player_dead():
				_state_timer = max(_state_timer, 0.5)
			elif _state_timer <= 0.0:
				_change_state(State.APPROACH)
			move_and_slide()

		State.PHASE_TRANSITION:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_change_state(State.RECOVERY)
			move_and_slide()

		State.DEFEATED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			move_and_slide()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0 and players[0] is Player:
		target_player = players[0] as Player

func _is_player_dead() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return true
	var p_health: HealthComponent = target_player.get_node_or_null("HealthComponent")
	return p_health == null or not p_health.is_alive()

func _update_facing() -> void:
	if target_player and is_instance_valid(target_player):
		var dx: float = target_player.global_position.x - global_position.x
		if abs(dx) > 15.0:
			facing_direction = 1 if dx > 0 else -1
			if boss_visual and boss_visual.has_method("set_facing"):
				boss_visual.set_facing(facing_direction)
			if charge_hitbox:
				charge_hitbox.position.x = 40.0 * facing_direction

func _process_approach(delta: float) -> void:
	if _is_player_dead():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	_update_facing()
	var spd: float = move_speed_p2 if is_phase_2 else move_speed_p1
	velocity.x = facing_direction * spd

	var dist: float = abs(target_player.global_position.x - global_position.x)
	_state_timer -= delta

	# Quyết định tấn công nếu đã tiếp cận đủ gần hoặc timer tiếp cận hết hạn (~2.0s)
	if dist <= 320.0 or _state_timer <= 0.0:
		_decide_next_attack(dist)
		_change_state(State.TELEGRAPH)

	move_and_slide()

func _decide_next_attack(dist: float) -> void:
	# Luân phiên đòn đánh để tạo nhịp điệu chiến đấu công bằng
	_attack_alternate = not _attack_alternate
	if dist > 380.0:
		# Khoảng cách xa: Ưu tiên Nguyệt Giác Xung Kích
		current_attack = AttackType.HORN_CHARGE
	elif dist < 180.0:
		# Khoảng cách gần: Ưu tiên Hắc Nguyệt Chấn Ba
		current_attack = AttackType.MOON_SHOCKWAVE
	else:
		current_attack = AttackType.HORN_CHARGE if _attack_alternate else AttackType.MOON_SHOCKWAVE

func _process_attack(delta: float) -> void:
	match current_attack:
		AttackType.HORN_CHARGE:
			var charge_spd: float = charge_speed_p2 if is_phase_2 else charge_speed_p1
			velocity.x = facing_direction * charge_spd
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_finish_attack()
			move_and_slide()
		AttackType.MOON_SHOCKWAVE:
			# Đòn chấn ba đã spawn khi vào state ATTACK
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_finish_attack()
			move_and_slide()

func _finish_attack() -> void:
	if charge_hitbox:
		charge_hitbox.monitoring = false
		charge_hitbox.visible = false
	_change_state(State.RECOVERY)

func _change_state(new_state: State) -> void:
	current_state = new_state
	var state_name: String = _get_state_name(current_state)
	emit_signal("boss_state_changed", state_name)

	match current_state:
		State.DORMANT:
			if boss_visual and boss_visual.has_method("set_state"):
				boss_visual.set_state(BossVisualScript.VisualState.IDLE)
			if hurtbox:
				hurtbox.set_deferred("monitoring", false)
				hurtbox.set_deferred("monitorable", false)

		State.INTRO:
			_state_timer = 1.2
			if boss_visual and boss_visual.has_method("set_state"):
				boss_visual.set_state(BossVisualScript.VisualState.IDLE)
			if hurtbox:
				hurtbox.set_deferred("monitoring", true)
				hurtbox.set_deferred("monitorable", true)

		State.APPROACH:
			_state_timer = 2.2
			if boss_visual and boss_visual.has_method("set_state"):
				boss_visual.set_state(BossVisualScript.VisualState.MOVE)

		State.TELEGRAPH:
			_update_facing()
			if current_attack == AttackType.HORN_CHARGE:
				_state_timer = 0.7 # Đạt chuẩn tối thiểu 0.6s
				if boss_visual and boss_visual.has_method("set_state"):
					boss_visual.set_state(BossVisualScript.VisualState.TELEGRAPH_CHARGE)
				emit_signal("boss_telegraph_started", "Nguyệt Giác Xung Kích", _state_timer)
			else:
				_state_timer = 0.9 # Đạt chuẩn tối thiểu 0.8s
				if boss_visual and boss_visual.has_method("set_state"):
					boss_visual.set_state(BossVisualScript.VisualState.TELEGRAPH_SHOCKWAVE)
				emit_signal("boss_telegraph_started", "Hắc Nguyệt Chấn Ba", _state_timer)

		State.ATTACK:
			if current_attack == AttackType.HORN_CHARGE:
				_charge_timer = 0.45
				if charge_hitbox:
					charge_hitbox.reset_hits()
					charge_hitbox.damage = 20.0
					charge_hitbox.monitoring = true
					charge_hitbox.visible = true
				if boss_visual and boss_visual.has_method("set_state"):
					boss_visual.set_state(BossVisualScript.VisualState.ATTACK_CHARGE)
			else:
				_state_timer = 0.35
				_spawn_shockwaves()
				if boss_visual and boss_visual.has_method("set_state"):
					boss_visual.set_state(BossVisualScript.VisualState.ATTACK_STOMP)

		State.RECOVERY:
			_state_timer = recovery_time_p2 if is_phase_2 else recovery_time_p1
			if boss_visual and boss_visual.has_method("set_state"):
				boss_visual.set_state(BossVisualScript.VisualState.RECOVERY)

		State.PHASE_TRANSITION:
			_state_timer = 1.3
			is_phase_2 = true
			if health_component:
				health_component.is_invulnerable = true
			if boss_visual and boss_visual.has_method("set_state"):
				boss_visual.set_state(BossVisualScript.VisualState.PHASE_TRANSITION)
			emit_signal("boss_phase_changed", 2)

		State.DEFEATED:
			_is_defeated = true
			velocity = Vector2.ZERO
			if charge_hitbox:
				charge_hitbox.monitoring = false
				charge_hitbox.visible = false
			if hurtbox:
				hurtbox.monitoring = false
				hurtbox.monitorable = false
				var h_col := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if h_col:
					h_col.disabled = true
			if health_component:
				health_component.is_invulnerable = true
			if boss_visual and boss_visual.has_method("set_state"):
				boss_visual.set_state(BossVisualScript.VisualState.DEFEATED)
			emit_signal("boss_defeated")

func _spawn_shockwaves() -> void:
	if shockwave_scene == null:
		return
	var wave_dir: float = float(facing_direction)
	var sw = shockwave_scene.instantiate()
	if sw is Node2D:
		sw.global_position = Vector2(global_position.x + wave_dir * 30.0, global_position.y)
		if sw.has_method("setup"):
			sw.setup(wave_dir, is_phase_2)
		get_parent().add_child(sw)

func _on_hit_received(damage_info: DamageInfo) -> void:
	if current_state == State.DORMANT or current_state == State.DEFEATED or current_state == State.PHASE_TRANSITION:
		return
	if boss_visual and boss_visual.has_method("flash_hit"):
		boss_visual.flash_hit()

func _on_health_changed(cur: float, max_v: float) -> void:
	emit_signal("boss_health_changed", cur, max_v)

	# Kích hoạt Phase 2 khi HP <= 50% (<= 160) - Chỉ kích hoạt duy nhất một lần
	if not _phase_2_triggered and cur <= (max_v * 0.5) and cur > 0.0:
		_phase_2_triggered = true
		_change_state(State.PHASE_TRANSITION)

func _on_died() -> void:
	if not _is_defeated:
		_change_state(State.DEFEATED)

func activate_boss() -> void:
	if current_state == State.DORMANT and not _is_defeated:
		_change_state(State.INTRO)

func reset_boss() -> void:
	global_position = _initial_spawn_position
	velocity = Vector2.ZERO
	_phase_2_triggered = false
	_is_defeated = false
	is_phase_2 = false

	if health_component:
		health_component.current_health = max_hp
		health_component.is_invulnerable = false
		emit_signal("boss_health_changed", max_hp, max_hp)

	if charge_hitbox:
		charge_hitbox.monitoring = false
		charge_hitbox.visible = false
		charge_hitbox.reset_hits()

	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)

	emit_signal("boss_phase_changed", 1)
	_change_state(State.DORMANT)

func purify_boss() -> void:
	_is_defeated = true
	_phase_2_triggered = true
	if health_component:
		health_component.current_health = 0.0
	_change_state(State.DEFEATED)

func _get_state_name(st: State) -> String:
	match st:
		State.DORMANT: return "DORMANT"
		State.INTRO: return "INTRO"
		State.APPROACH: return "APPROACH"
		State.TELEGRAPH: return "TELEGRAPH"
		State.ATTACK: return "ATTACK"
		State.RECOVERY: return "RECOVERY"
		State.PHASE_TRANSITION: return "PHASE_TRANSITION"
		State.DEFEATED: return "DEFEATED"
		_: return "UNKNOWN"

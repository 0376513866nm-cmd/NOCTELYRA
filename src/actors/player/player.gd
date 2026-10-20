class_name Player
extends CharacterBody2D

signal state_changed(new_state_name: String)
signal player_died()
signal player_respawned()

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH,
	DEAD
}

@export var movement_data: PlayerMovementData

@onready var sprite_root: Node2D = $SpriteRoot
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var melee_hitbox: Hitbox = $MeleeHitbox

var current_state: State = State.IDLE
var facing_direction: int = 1
var jumps_left: int = 2
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 1
var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	spawn_position = global_position
	if movement_data == null:
		movement_data = PlayerMovementData.new()
	_change_state(State.IDLE)

	if health_component:
		health_component.invulnerability_started.connect(_on_invuln_started)
		health_component.invulnerability_ended.connect(_on_invuln_ended)
		health_component.died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	# Khi chết: Vô hiệu hóa toàn bộ di chuyển, rơi và input
	if current_state == State.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if not is_on_floor():
			velocity.y += movement_data.gravity * delta
		move_and_slide()
		return

	# Luôn giảm thời gian hồi chiêu Dash độc lập
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Kiểm tra nếu đang mở hội thoại NPC hoặc vừa đóng (grace cooldown) thì tạm ngừng nhận input
	var ui: GameUI = _get_game_ui()
	if ui and (ui.is_dialogue_open() or ui.is_dialogue_cooling_down()):
		velocity.x = move_toward(velocity.x, 0.0, movement_data.friction * delta)
		move_and_slide()
		return

	# Xử lý input tấn công & ma pháp (J & K)
	_handle_combat_inputs()

	match current_state:
		State.DASH:
			# Trong lúc DASH: Giữ nguyên vận tốc lướt và không bị ghi đè bởi state khác
			dash_timer -= delta
			velocity.x = dash_direction * movement_data.dash_speed
			velocity.y = 0.0
			if dash_timer <= 0.0:
				if is_on_floor():
					var dir := _get_input_direction()
					if dir != 0.0:
						_change_state(State.RUN)
					else:
						_change_state(State.IDLE)
				else:
					_change_state(State.FALL)

		State.JUMP:
			# Ưu tiên Dash trên không hoặc Nhảy đôi
			if _check_dash():
				pass
			elif _check_double_jump():
				pass
			else:
				_apply_gravity(delta)
				_process_air_movement(delta)
				if velocity.y >= 0.0:
					_change_state(State.FALL)
				elif is_on_floor():
					_restore_jumps()
					if abs(velocity.x) > 10.0:
						_change_state(State.RUN)
					else:
						_change_state(State.IDLE)

		State.FALL:
			# Có thể Dash hoặc Nhảy đôi giữa lúc rơi
			if _check_dash():
				pass
			elif _check_double_jump():
				pass
			else:
				_apply_gravity(delta)
				_process_air_movement(delta)
				if is_on_floor():
					_restore_jumps()
					var dir := _get_input_direction()
					if dir != 0.0 or abs(velocity.x) > 10.0:
						_change_state(State.RUN)
					else:
						_change_state(State.IDLE)

		State.IDLE:
			_restore_jumps()
			if _check_dash():
				pass
			elif _check_jump():
				pass
			elif not is_on_floor():
				_change_state(State.FALL)
			else:
				_process_ground_movement(delta)
				if abs(velocity.x) > 10.0:
					_change_state(State.RUN)

		State.RUN:
			_restore_jumps()
			if _check_dash():
				pass
			elif _check_jump():
				pass
			elif not is_on_floor():
				_change_state(State.FALL)
			else:
				_process_ground_movement(delta)
				if abs(velocity.x) <= 10.0 and _get_input_direction() == 0.0:
					_change_state(State.IDLE)

	move_and_slide()

	# Khôi phục số lần nhảy khi đang chạm đất
	if is_on_floor() and current_state != State.JUMP and current_state != State.DEAD:
		_restore_jumps()

func _handle_combat_inputs() -> void:
	if combat_component == null:
		return
	if Input.is_action_just_pressed("attack"):
		combat_component.perform_attack(facing_direction)
	elif Input.is_action_just_pressed("cast_spell"):
		combat_component.cast_spell(self, facing_direction, health_component)

func _on_invuln_started() -> void:
	if sprite_root and current_state != State.DEAD:
		sprite_root.modulate = Color(1.0, 0.4, 0.4, 0.7)

func _on_invuln_ended() -> void:
	if sprite_root and current_state != State.DEAD:
		sprite_root.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_player_died() -> void:
	_change_state(State.DEAD)
	velocity = Vector2.ZERO
	# Tắt hitbox tấn công
	if melee_hitbox:
		melee_hitbox.monitoring = false
		melee_hitbox.visible = false
	if combat_component:
		combat_component.end_attack()
	# Tắt nhận đòn
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	# Hiệu ứng mờ dần
	if sprite_root:
		sprite_root.modulate = Color(0.6, 0.2, 0.2, 0.6)

	emit_signal("player_died")

	var ui := _get_game_ui()
	if ui:
		ui.show_game_over()

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	if health_component:
		health_component.current_health = health_component.max_health
		health_component.current_mana = health_component.max_mana
		health_component.is_invulnerable = false
		health_component.emit_signal("health_changed", health_component.current_health, health_component.max_health)
		health_component.emit_signal("mana_changed", health_component.current_mana, health_component.max_mana)
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	if sprite_root:
		sprite_root.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	_restore_jumps()
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	_change_state(State.IDLE)
	emit_signal("player_respawned")

func _restore_jumps() -> void:
	jumps_left = movement_data.max_jumps

func _change_state(new_state: State) -> void:
	current_state = new_state
	var state_name := _get_state_name(current_state)
	emit_signal("state_changed", state_name)

	var has_player := (anim_player != null)

	match current_state:
		State.IDLE:
			if has_player and anim_player.has_animation("idle"):
				anim_player.play("idle")
		State.RUN:
			if has_player and anim_player.has_animation("run"):
				anim_player.play("run")
		State.JUMP:
			if has_player and anim_player.has_animation("jump"):
				anim_player.play("jump")
			else:
				_play_fallback_air_visual()
		State.FALL:
			if has_player and anim_player.has_animation("fall"):
				anim_player.play("fall")
			else:
				_play_fallback_air_visual()
		State.DASH:
			if has_player and anim_player.has_animation("dash"):
				anim_player.play("dash")
			else:
				_play_fallback_dash_visual()
			dash_timer = movement_data.dash_duration
			dash_cooldown_timer = movement_data.dash_cooldown
			
			var move_dir := int(sign(_get_input_direction()))
			if move_dir != 0:
				dash_direction = move_dir
				_set_facing(dash_direction)
			else:
				dash_direction = facing_direction
		State.DEAD:
			if anim_player:
				anim_player.pause()

func _play_fallback_air_visual() -> void:
	if anim_player and anim_player.has_animation("run"):
		anim_player.play("run")
		anim_player.seek(0.12, true)
		anim_player.pause()

func _play_fallback_dash_visual() -> void:
	if anim_player and anim_player.has_animation("run"):
		anim_player.play("run")
		anim_player.seek(0.48, true)
		anim_player.pause()

func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")

func _process_ground_movement(delta: float) -> void:
	var direction := _get_input_direction()
	if direction != 0.0:
		_set_facing(int(sign(direction)))
		velocity.x = move_toward(velocity.x, direction * movement_data.move_speed, movement_data.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, movement_data.friction * delta)

func _process_air_movement(delta: float) -> void:
	var direction := _get_input_direction()
	if direction != 0.0:
		_set_facing(int(sign(direction)))
		velocity.x = move_toward(velocity.x, direction * movement_data.move_speed, movement_data.air_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, movement_data.air_friction * delta)

func _apply_gravity(delta: float) -> void:
	velocity.y += movement_data.gravity * delta

func _check_jump() -> bool:
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or jumps_left == movement_data.max_jumps:
			velocity.y = movement_data.jump_velocity
			jumps_left = movement_data.max_jumps - 1
			_change_state(State.JUMP)
			return true
	return false

func _check_double_jump() -> bool:
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = movement_data.double_jump_velocity
		jumps_left -= 1
		_change_state(State.JUMP)
		return true
	return false

func _check_dash() -> bool:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		_change_state(State.DASH)
		return true
	return false

func _set_facing(dir: int) -> void:
	if dir == 0 or dir == facing_direction:
		return
	facing_direction = dir
	if sprite_root:
		sprite_root.scale.x = float(facing_direction)

func _get_game_ui() -> GameUI:
	var scene = get_tree().current_scene
	if scene:
		return scene.get_node_or_null("GameUI") as GameUI
	return null

func _get_state_name(state: State) -> String:
	match state:
		State.IDLE: return "IDLE"
		State.RUN: return "RUN"
		State.JUMP: return "JUMP"
		State.FALL: return "FALL"
		State.DASH: return "DASH"
		State.DEAD: return "DEAD"
		_: return "UNKNOWN"

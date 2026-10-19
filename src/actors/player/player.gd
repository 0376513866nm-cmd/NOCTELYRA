class_name Player
extends CharacterBody2D

signal state_changed(new_state_name: String)

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH
}

@export var movement_data: PlayerMovementData

@onready var sprite_root: Node2D = $SpriteRoot
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_state: State = State.IDLE
var facing_direction: int = 1
var jumps_left: int = 2
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 1

func _ready() -> void:
	if movement_data == null:
		movement_data = PlayerMovementData.new()
	_change_state(State.IDLE)

func _physics_process(delta: float) -> void:
	# Luôn giảm thời gian hồi chiêu Dash độc lập
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

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
	if is_on_floor() and current_state != State.JUMP:
		_restore_jumps()

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

func _get_state_name(state: State) -> String:
	match state:
		State.IDLE: return "IDLE"
		State.RUN: return "RUN"
		State.JUMP: return "JUMP"
		State.FALL: return "FALL"
		State.DASH: return "DASH"
		_: return "UNKNOWN"

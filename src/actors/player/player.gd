class_name Player
extends CharacterBody2D

signal state_changed(new_state_name: String)
signal player_died()
signal player_respawned()
signal notification_posted(message: String)

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	LAND,
	DASH,
	DEAD,
	AUTO_HOP
}

@export var movement_data: PlayerMovementData

@onready var sprite_root: Node2D = $SpriteRoot
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var combat_component: CombatComponent = $CombatComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var melee_hitbox: Hitbox = $MeleeHitbox
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var equipment_component: EquipmentComponent = $EquipmentComponent
@onready var spellbook_component: SpellbookComponent = $SpellbookComponent
@onready var quest_journal_component: QuestJournalComponent = $QuestJournalComponent
@onready var progression_component: PlayerProgressionComponent = $PlayerProgressionComponent
@onready var player_stats_component: PlayerStatsComponent = $PlayerStatsComponent
@onready var ground_shadow: Polygon2D = get_node_or_null("GroundShadow")
@onready var hop_sprite: Sprite2D = get_node_or_null("SpriteRoot/HopSprite") as Sprite2D
var _shadow_ray: RayCast2D = null

var current_state: State = State.IDLE
var facing_direction: int = 1
var jumps_left: int = 2
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 1
var spawn_position: Vector2 = Vector2.ZERO
var cast_anim_timer: float = 0.0
var attack_anim_timer: float = 0.0
var hurt_recoil_timer: float = 0.0
var land_timer: float = 0.0
var auto_step_cooldown: float = 0.0
var _low_drop_active: bool = false

## Quản lý Khóa Input Độc lập theo Lý do (Reason-based Input Locking)
var input_locks: Dictionary = {}

func set_input_blocked(reason: String, blocked: bool) -> void:
	if blocked:
		input_locks[reason] = true
	else:
		input_locks.erase(reason)

func is_input_blocked() -> bool:
	return not input_locks.is_empty()

func get_active_input_locks() -> Array:
	return input_locks.keys()

func clear_all_input_locks() -> void:
	input_locks.clear()

var race_id: String:
	get:
		if player_stats_component:
			return player_stats_component.race_id
		return "human"
	set(val):
		_ensure_m8_components()
		if player_stats_component:
			player_stats_component.set_race(val)
		apply_race_visual(val)

var hurtbox_collision: CollisionShape2D:
	get:
		if hurtbox:
			return hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		return null

var _movement_data_isolated: bool = false

func _enter_tree() -> void:
	add_to_group(GameGroups.PLAYERS)
	_ensure_isolated_movement_data()

func _ensure_isolated_movement_data() -> void:
	if _movement_data_isolated:
		return
	if movement_data != null:
		movement_data = movement_data.duplicate()
	else:
		movement_data = PlayerMovementData.new()
	_movement_data_isolated = true

func get_race_base_modulate() -> Color:
	# Tạm thời để màu sắc cả 3 tộc nguyên bản đồng nhất không đổi màu
	return Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	clear_all_input_locks()
	_ensure_isolated_movement_data()
	spawn_position = global_position
	floor_snap_length = 4.0
	_ensure_m8_components()
	_change_state(State.IDLE)

	if health_component:
		health_component.invulnerability_started.connect(_on_invuln_started)
		health_component.invulnerability_ended.connect(_on_invuln_ended)
		health_component.died.connect(_on_player_died)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	if combat_component:
		combat_component.attack_started.connect(_on_attack_started)
		combat_component.spell_cast.connect(_on_spell_cast)

func _ensure_m8_components() -> void:
	if progression_component == null:
		progression_component = get_node_or_null("PlayerProgressionComponent") as PlayerProgressionComponent
		if progression_component == null:
			progression_component = PlayerProgressionComponent.new()
			progression_component.name = "PlayerProgressionComponent"
			add_child(progression_component)

	if player_stats_component == null:
		player_stats_component = get_node_or_null("PlayerStatsComponent") as PlayerStatsComponent
		if player_stats_component == null:
			player_stats_component = PlayerStatsComponent.new()
			player_stats_component.name = "PlayerStatsComponent"
			player_stats_component.player = self
			add_child(player_stats_component)

func apply_race_visual(r_id: String) -> void:
	if sprite_root == null:
		return
	# Ngoại hình cả 3 tộc tạm thời để nguyên bản giống nhau, không đổi màu sắc
	sprite_root.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var visual_badge := sprite_root.get_node_or_null("RaceVisualBadge") as Node2D
	if visual_badge == null:
		visual_badge = Node2D.new()
		visual_badge.name = "RaceVisualBadge"
		sprite_root.add_child(visual_badge)

	for c in visual_badge.get_children():
		c.queue_free()

	# Ẩn hoàn toàn để không vẽ thêm nét thừa đè lên nhân vật
	visual_badge.visible = false

	match r_id:
		"elf":
			var ear_left := Polygon2D.new()
			ear_left.polygon = PackedVector2Array([Vector2(-6, -98), Vector2(-15, -105), Vector2(-6, -101)])
			ear_left.color = Color(0.4, 0.95, 0.7, 0.9)
			visual_badge.add_child(ear_left)

			var ear_right := Polygon2D.new()
			ear_right.polygon = PackedVector2Array([Vector2(6, -98), Vector2(15, -105), Vector2(6, -101)])
			ear_right.color = Color(0.4, 0.95, 0.7, 0.9)
			visual_badge.add_child(ear_right)

			var aura := Line2D.new()
			aura.width = 2.0
			aura.default_color = Color(0.3, 1.0, 0.7, 0.5)
			visual_badge.add_child(aura)

		"demon_beast":
			var horn_left := Polygon2D.new()
			horn_left.polygon = PackedVector2Array([Vector2(-6, -106), Vector2(-12, -118), Vector2(-3, -110)])
			horn_left.color = Color(0.85, 0.2, 0.35, 0.95)
			visual_badge.add_child(horn_left)

			var horn_right := Polygon2D.new()
			horn_right.polygon = PackedVector2Array([Vector2(6, -106), Vector2(12, -118), Vector2(3, -110)])
			horn_right.color = Color(0.85, 0.2, 0.35, 0.95)
			visual_badge.add_child(horn_right)

			var tail := Line2D.new()
			tail.width = 3.0
			tail.default_color = Color(0.8, 0.25, 0.4, 0.9)
			visual_badge.add_child(tail)

		_: # "human"
			var scarf := Line2D.new()
			scarf.name = "ScarfBadge"
			scarf.width = 3.0
			scarf.default_color = Color(0.3, 0.6, 1.0, 0.8)
			scarf.points = PackedVector2Array([Vector2(-8, -86), Vector2(0, -84), Vector2(8, -86), Vector2(10, -74)])
			visual_badge.add_child(scarf)

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

	if auto_step_cooldown > 0.0:
		auto_step_cooldown -= delta

	if hurt_recoil_timer > 0.0:
		hurt_recoil_timer -= delta

	# Giảm thời gian hoạt ảnh đánh thường nếu đang phát
	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0.0:
			attack_anim_timer = 0.0
			if cast_anim_timer <= 0.0:
				_refresh_current_animation()

	# Giảm thời gian hoạt ảnh cast bắn đạn nếu đang phát
	if cast_anim_timer > 0.0:
		cast_anim_timer -= delta
		if cast_anim_timer <= 0.0:
			cast_anim_timer = 0.0
			if attack_anim_timer <= 0.0:
				_refresh_current_animation()

	# Kiểm tra nếu đang bị khóa input (UI mở, đối thoại, cooldown thao tác...)
	if is_input_blocked():
		velocity.x = move_toward(velocity.x, 0.0, movement_data.friction * delta)
		if not is_on_floor():
			velocity.y += movement_data.gravity * delta
		if is_on_floor():
			if current_state != State.IDLE and current_state != State.AUTO_HOP:
				_change_state(State.IDLE)
		else:
			if current_state != State.FALL and current_state != State.AUTO_HOP:
				_change_state(State.FALL)
		move_and_slide()
		_update_ground_shadow()
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
					_change_state(State.LAND)

		State.LAND:
			_restore_jumps()
			land_timer -= delta
			if _check_dash():
				pass
			elif _check_jump():
				pass
			elif not is_on_floor():
				_change_state(State.FALL)
			else:
				_process_ground_movement(delta)
				var dir := _get_input_direction()
				if land_timer <= 0.0:
					if dir != 0.0 or abs(velocity.x) > 10.0:
						_change_state(State.RUN)
					else:
						_change_state(State.IDLE)
				elif dir != 0.0 and land_timer <= 0.12:
					_change_state(State.RUN)

		State.IDLE:
			_restore_jumps()
			if _check_dash():
				pass
			elif _check_jump():
				pass
			elif not is_on_floor():
				_change_state(State.FALL)
			elif _check_auto_step(delta):
				pass
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
			elif _check_auto_step(delta):
				pass
			else:
				_process_ground_movement(delta)
				if abs(velocity.x) <= 10.0 and _get_input_direction() == 0.0:
					_change_state(State.IDLE)

		State.AUTO_HOP:
			# Short ledges keep the run cycle while physics clears the step.
			_apply_gravity(delta)
			_process_air_movement(delta)
			if _check_dash():
				pass
			elif _check_jump():
				pass
			elif is_on_floor() and velocity.y >= 0.0:
				_restore_jumps()
				var dir := _get_input_direction()
				if dir != 0.0 or abs(velocity.x) > 10.0:
					_change_state(State.RUN)
				else:
					_change_state(State.IDLE)

	move_and_slide()
	_sync_low_step_animation()
	_update_ground_shadow()

	# Khôi phục số lần nhảy khi đang chạm đất
	if is_on_floor() and current_state != State.JUMP and current_state != State.DEAD:
		_restore_jumps()

func _update_ground_shadow() -> void:
	if ground_shadow == null:
		return
	if is_on_floor():
		ground_shadow.position.y = 0.0
		ground_shadow.scale = Vector2.ONE
		ground_shadow.modulate.a = 0.45
	else:
		if _shadow_ray == null:
			_shadow_ray = RayCast2D.new()
			_shadow_ray.target_position = Vector2(0, 360)
			_shadow_ray.collision_mask = 1
			add_child(_shadow_ray)
		_shadow_ray.force_raycast_update()
		if _shadow_ray.is_colliding():
			var hit_y: float = _shadow_ray.get_collision_point().y - global_position.y
			ground_shadow.position.y = hit_y
			var dist: float = maxf(0.0, hit_y)
			var factor: float = clampf(1.0 - (dist / 280.0), 0.35, 1.0)
			ground_shadow.scale = Vector2(factor, factor * 0.8)
			ground_shadow.modulate.a = 0.45 * factor
		else:
			ground_shadow.modulate.a = 0.0

func _handle_combat_inputs() -> void:
	if combat_component == null:
		return

	# Phím 1, 2, 3: Chọn phép thuật, phím U: Nâng cấp phép
	var sb := spellbook_component
	if sb == null:
		sb = get_node_or_null("SpellbookComponent") as SpellbookComponent
	if sb:
		if Input.is_action_just_pressed("spell_1"):
			sb.select_spell_by_index(0)
		elif Input.is_action_just_pressed("spell_2"):
			sb.select_spell_by_index(1)
		elif Input.is_action_just_pressed("spell_3"):
			sb.select_spell_by_index(2)
		elif Input.is_action_just_pressed("spell_upgrade"):
			_upgrade_current_spell()

	if Input.is_action_just_pressed("attack"):
		combat_component.perform_attack(facing_direction)
	elif Input.is_action_just_pressed("cast_spell"):
		combat_component.cast_spell(self, facing_direction, health_component)

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.DEAD:
		return
	if is_input_blocked():
		return
	if event is InputEventMouseButton and event.pressed:
		var sb := spellbook_component
		if sb == null:
			sb = get_node_or_null("SpellbookComponent") as SpellbookComponent
		if sb:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				sb.cycle_prev_spell()
				if get_viewport():
					get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				sb.cycle_next_spell()
				if get_viewport():
					get_viewport().set_input_as_handled()

func _upgrade_current_spell() -> void:
	var sb := spellbook_component
	if sb == null:
		sb = get_node_or_null("SpellbookComponent") as SpellbookComponent
	var inv := inventory_component
	if inv == null:
		inv = get_node_or_null("InventoryComponent") as InventoryComponent
	if sb == null or inv == null:
		return
	if current_state == State.DEAD:
		return
	if get_tree().paused:
		return
	if is_input_blocked():
		return
	var world := get_tree().current_scene
	var res := sb.upgrade_spell(sb.selected_spell_id, inv, world)
	if res.has("message"):
		_notify_ui(str(res["message"]))

func _notify_ui(msg: String) -> void:
	emit_signal("notification_posted", msg)

func _on_invuln_started() -> void:
	if sprite_root and current_state != State.DEAD:
		sprite_root.modulate = Color(1.0, 0.4, 0.4, 0.7)

func _on_invuln_ended() -> void:
	if sprite_root and current_state != State.DEAD:
		sprite_root.modulate = get_race_base_modulate()

func _on_hit_received(dmg: DamageInfo) -> void:
	if current_state == State.DEAD:
		return
	var force: float = dmg.knockback_force if dmg.knockback_force > 0.0 else 240.0
	var k_dir_x: float = signf(dmg.knockback_dir.x)
	if is_zero_approx(k_dir_x):
		k_dir_x = -float(facing_direction)
	velocity.x = k_dir_x * maxf(force, 240.0)
	velocity.y = -150.0
	hurt_recoil_timer = 0.22

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

	# Dọn dẹp các projectile của Player đang bay để không gây tác động sau khi chết
	if get_tree():
		for p in get_tree().get_nodes_in_group(GameGroups.PLAYER_PROJECTILES):
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()

	attack_anim_timer = 0.0
	cast_anim_timer = 0.0
	emit_signal("player_died")

func respawn() -> void:
	clear_all_input_locks()
	global_position = spawn_position
	reset_physics_interpolation()
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
		sprite_root.modulate = get_race_base_modulate()

	if get_tree():
		for p in get_tree().get_nodes_in_group(GameGroups.PLAYER_PROJECTILES):
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()

	_restore_jumps()
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	attack_anim_timer = 0.0
	cast_anim_timer = 0.0
	_change_state(State.IDLE)
	emit_signal("player_respawned")

func _restore_jumps() -> void:
	jumps_left = movement_data.max_jumps

func _change_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.AUTO_HOP:
		_low_drop_active = true
	elif new_state not in [State.FALL, State.LAND]:
		_low_drop_active = false
	if new_state == State.LAND:
		var is_moving: bool = _get_input_direction() != 0.0 or abs(velocity.x) > 30.0
		if _low_drop_active:
			land_timer = 0.06 if is_moving else 0.10
		elif is_moving:
			land_timer = 0.08
		else:
			land_timer = 0.25
	var state_name := _get_state_name(current_state)
	emit_signal("state_changed", state_name)

	if new_state == State.DEAD:
		attack_anim_timer = 0.0
		cast_anim_timer = 0.0
		if anim_player:
			anim_player.pause()
		return

	if new_state == State.DASH:
		attack_anim_timer = 0.0
		cast_anim_timer = 0.0
		dash_timer = movement_data.dash_duration
		dash_cooldown_timer = movement_data.dash_cooldown
		
		var move_dir := int(sign(_get_input_direction()))
		if move_dir != 0:
			dash_direction = move_dir
			_set_facing(dash_direction)
		else:
			dash_direction = facing_direction

		if anim_player and anim_player.has_animation("dash"):
			anim_player.play("dash")
		else:
			_play_fallback_dash_visual()
		return

	if attack_anim_timer > 0.0 or cast_anim_timer > 0.0:
		return

	_refresh_current_animation()

func _refresh_current_animation() -> void:
	var has_player := (anim_player != null)
	if not has_player:
		return

	match current_state:
		State.IDLE:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("idle"):
				anim_player.play("idle")
				anim_player.advance(0.0)
		State.RUN:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("run"):
				anim_player.play("run")
				anim_player.advance(0.0)
		State.JUMP:
			anim_player.speed_scale = 1.0
			if jumps_left == 0 and anim_player.has_animation("double_jump"):
				anim_player.play("double_jump")
				anim_player.advance(0.0)
			elif anim_player.has_animation("jump"):
				anim_player.play("jump")
				anim_player.advance(0.0)
			else:
				_play_fallback_air_visual()
		State.FALL:
			anim_player.speed_scale = 1.0
			# Nếu rơi tự do từ bậc/thềm thấp (chưa bấm nhảy và mặt đất bên dưới <= 70px)
			if jumps_left == movement_data.max_jumps and _is_near_ground(70.0):
				_low_drop_active = true
				_play_low_step_animation()
			elif jumps_left == movement_data.max_jumps - 1 and anim_player.has_animation("jump_fall"):
				_low_drop_active = false
				anim_player.play("jump_fall")
				anim_player.advance(0.0)
			elif anim_player.has_animation("fall"):
				_low_drop_active = false
				anim_player.play("fall")
				anim_player.advance(0.0)
			else:
				_play_fallback_air_visual()
		State.LAND:
			if _low_drop_active:
				_play_low_step_animation()
				return
			var is_moving: bool = _get_input_direction() != 0.0 or abs(velocity.x) > 30.0
			if is_moving:
				anim_player.speed_scale = 3.0
			else:
				anim_player.speed_scale = 1.0
			if anim_player.has_animation("land"):
				anim_player.play("land")
				anim_player.advance(0.0)
			else:
				_play_fallback_air_visual()
		State.AUTO_HOP:
			_play_low_step_animation()
		State.DASH:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("dash"):
				anim_player.play("dash")
			else:
				_play_fallback_dash_visual()
		State.DEAD:
			anim_player.pause()

func _on_attack_started() -> void:
	play_attack_animation()

func play_attack_animation() -> void:
	if current_state == State.DEAD:
		return
	attack_anim_timer = 0.25
	cast_anim_timer = 0.0
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
		anim_player.advance(0.0)

func _on_spell_cast() -> void:
	play_cast_animation()

func play_cast_animation() -> void:
	if current_state == State.DEAD:
		return
	cast_anim_timer = 0.36
	if anim_player and anim_player.has_animation("cast"):
		anim_player.play("cast")
		anim_player.advance(0.0)

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

func _ground_distance(max_dist: float = 256.0) -> float:
	var space_state := get_world_2d().direct_space_state
	if not space_state:
		return -1.0
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, max_dist), collision_mask)
	query.exclude = [get_rid()]
	var hit := space_state.intersect_ray(query)
	return maxf(0.0, hit.position.y - global_position.y) if not hit.is_empty() else -1.0

func _is_near_ground(max_dist: float = 70.0) -> bool:
	return _ground_distance(max_dist) >= 0.0

func _play_low_step_animation() -> void:
	# Keep the current run cycle across a short ledge instead of switching bodies.
	var animation: StringName = &"run" if _get_input_direction() != 0.0 or absf(velocity.x) > 10.0 else &"idle"
	if not anim_player.has_animation(animation):
		return
	anim_player.speed_scale = 1.0
	if anim_player.assigned_animation != animation or not anim_player.is_playing():
		anim_player.play(animation)
		anim_player.advance(0.0)

func _sync_low_step_animation() -> void:
	if anim_player == null or attack_anim_timer > 0.0 or cast_anim_timer > 0.0:
		return
	if current_state == State.AUTO_HOP or (_low_drop_active and current_state in [State.FALL, State.LAND]):
		_play_low_step_animation()

func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")

func _process_ground_movement(delta: float) -> void:
	if hurt_recoil_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, movement_data.friction * delta)
		return
	var direction := _get_input_direction()
	if direction != 0.0:
		_set_facing(int(sign(direction)))
		velocity.x = move_toward(velocity.x, direction * movement_data.move_speed, movement_data.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, movement_data.friction * delta)

func _process_air_movement(delta: float) -> void:
	if hurt_recoil_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, movement_data.air_friction * delta)
		return
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
		if anim_player and anim_player.has_animation("double_jump"):
			anim_player.play("double_jump")
			anim_player.advance(0.0)
		return true
	return false

func _check_dash() -> bool:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		_change_state(State.DASH)
		return true
	return false

func _check_auto_step(delta: float) -> bool:
	if movement_data == null or not movement_data.auto_step_enabled:
		return false
	if auto_step_cooldown > 0.0:
		return false

	var dir := _get_input_direction()
	if is_zero_approx(dir):
		dir = signf(velocity.x)
	if is_zero_approx(dir):
		return false

	var face_sign := signf(dir)
	var space_state := get_world_2d().direct_space_state
	if not space_state:
		return false

	# See the ledge before the capsule reaches it, including at higher run speeds.
	var body_radius := 16.0
	if collision_shape.shape is CapsuleShape2D:
		body_radius = collision_shape.shape.radius * absf(collision_shape.scale.x)
	var scan_distance := maxf(movement_data.auto_step_lookahead, body_radius + movement_data.move_speed * 0.4)
	var foot_start := global_position + Vector2(0, -6.0)
	var foot_end := foot_start + Vector2(face_sign * scan_distance, 0)
	var foot_query := PhysicsRayQueryParameters2D.create(foot_start, foot_end, collision_mask)
	foot_query.exclude = [get_rid()]
	var foot_hit := space_state.intersect_ray(foot_query)

	if foot_hit.is_empty():
		return false

	var edge_distance: float = absf(foot_hit.position.x - global_position.x)
	var probe_distance: float = edge_distance + 4.0
	var probe_height: float = movement_data.auto_step_max_height + 8.0
	# Limit the upper ray to this ledge, so a farther wall does not hide a low step.
	var high_start := global_position + Vector2(0, -probe_height)
	var high_end := high_start + Vector2(face_sign * probe_distance, 0)
	var high_query := PhysicsRayQueryParameters2D.create(high_start, high_end, collision_mask)
	high_query.exclude = [get_rid()]
	var high_hit := space_state.intersect_ray(high_query)

	if not high_hit.is_empty():
		return false # Vật cản quá cao, người chơi phải chủ động bấm Space nhảy!

	var down_start := global_position + Vector2(face_sign * probe_distance, -probe_height)
	var down_end := down_start + Vector2(0, probe_height + 6.0)
	var down_query := PhysicsRayQueryParameters2D.create(down_start, down_end, collision_mask)
	down_query.exclude = [get_rid()]
	var down_hit := space_state.intersect_ray(down_query)

	if down_hit.is_empty():
		return false

	var ledge_top_y: float = down_hit.position.y
	var step_height: float = global_position.y - ledge_top_y

	if step_height >= movement_data.auto_step_min_height and step_height <= movement_data.auto_step_max_height:
		var gravity := maxf(movement_data.gravity, 1.0)
		var launch_speed := minf(absf(movement_data.auto_step_jump_velocity), sqrt(2.0 * gravity * (step_height + 14.0)))
		var clear_height: float = step_height + 4.0
		var discriminant := launch_speed * launch_speed - 2.0 * gravity * clear_height
		if discriminant <= 0.0:
			return false
		if edge_distance > movement_data.auto_step_takeoff_distance:
			return false
		velocity.y = -launch_speed
		velocity.x = face_sign * movement_data.move_speed
		auto_step_cooldown = 0.45
		_change_state(State.AUTO_HOP)
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
		State.LAND: return "LAND"
		State.DASH: return "DASH"
		State.DEAD: return "DEAD"
		State.AUTO_HOP: return "AUTO_HOP"
		_: return "UNKNOWN"

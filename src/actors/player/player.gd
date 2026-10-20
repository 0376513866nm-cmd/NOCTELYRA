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
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var equipment_component: EquipmentComponent = $EquipmentComponent
@onready var spellbook_component: SpellbookComponent = $SpellbookComponent
@onready var quest_journal_component: QuestJournalComponent = $QuestJournalComponent
@onready var progression_component: PlayerProgressionComponent = $PlayerProgressionComponent
@onready var player_stats_component: PlayerStatsComponent = $PlayerStatsComponent

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
	_ensure_isolated_movement_data()
	spawn_position = global_position
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

	# Kiểm tra nếu đang mở hội thoại NPC, vừa đóng, đang mở túi đồ, sổ nhiệm vụ hoặc thông tin nhân vật thì tạm ngừng nhận input
	var ui: GameUI = _get_game_ui()
	if ui and (ui.is_dialogue_open() or ui.is_dialogue_cooling_down() or (ui.has_method("is_ui_cooling_down") and ui.is_ui_cooling_down()) or ui.is_inventory_open() or ui.is_quest_journal_open() or (ui.has_method("is_character_sheet_open") and ui.is_character_sheet_open())):
		velocity.x = move_toward(velocity.x, 0.0, movement_data.friction * delta)
		if not is_on_floor():
			velocity.y += movement_data.gravity * delta
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
	var ui := _get_game_ui()
	if ui and (ui.is_dialogue_open() or ui.is_dialogue_cooling_down() or ui.is_inventory_open() or ui.is_quest_journal_open() or (ui.has_method("is_character_sheet_open") and ui.is_character_sheet_open())):
		return
	var world := get_tree().current_scene
	var res := sb.upgrade_spell(sb.selected_spell_id, inv, world)
	if ui and res.has("message"):
		ui.show_notification(res["message"])

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
		for p in get_tree().get_nodes_in_group("player_projectiles"):
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()

	attack_anim_timer = 0.0
	cast_anim_timer = 0.0
	emit_signal("player_died")

	var ui := _get_game_ui()
	if ui:
		ui.show_game_over()

func respawn() -> void:
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
		for p in get_tree().get_nodes_in_group("player_projectiles"):
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
			if anim_player.has_animation("jump"):
				anim_player.play("jump")
			else:
				_play_fallback_air_visual()
		State.FALL:
			anim_player.speed_scale = 1.0
			if anim_player.has_animation("fall"):
				anim_player.play("fall")
			else:
				_play_fallback_air_visual()
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

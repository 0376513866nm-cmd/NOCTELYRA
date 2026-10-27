extends SceneTree

var failures := 0
const EnemyScene := preload("res://src/actors/enemy/enemy.tscn")
const PlayerScene := preload("res://src/actors/player/player.tscn")

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1

func tick() -> void:
	await physics_frame
	await process_frame

func ground(parent: Node, at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collider.shape = rectangle
	body.add_child(collider)
	parent.add_child(body)

func navigation_case(rise: float, side: float, expect_hop: bool, ceiling: bool = false, flying: bool = false, enemy_type: String = "corrupted_wolf") -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	current_scene = arena
	ground(arena, Vector2(-150 * side, 350), Vector2(300, 100))
	ground(arena, Vector2(150 * side, 350 - rise * 0.5), Vector2(300, 100 + rise))
	if ceiling:
		ground(arena, Vector2(-30 * side, 220), Vector2(200, 10))
	var player := PlayerScene.instantiate() as Player
	player.position = Vector2((55 if enemy_type == "ashfang_wolf" else 160) * side, 300 - rise)
	arena.add_child(player)
	player.set_physics_process(false)
	player.health_component.set_invulnerable_duration(100)
	var enemy := EnemyScene.instantiate() as Enemy
	enemy.position = Vector2(-110 * side, 300)
	enemy.definition = EnemyDefinition.create_default(enemy_type)
	enemy.definition.is_flying = flying
	enemy.definition.detection_range = 1000
	enemy.definition.leash_distance = 1000
	enemy.definition.patrol_radius = 0
	if enemy_type != "ashfang_wolf":
		enemy.definition.attack_range = 25
	arena.add_child(enemy)
	enemy.target_player = player
	enemy._change_state(Enemy.State.CHASE)
	var min_y := enemy.global_position.y
	var furthest := enemy.global_position.x * side
	var first_blocked := -1.0
	var retreated_at := -1.0
	for frame in range(230 if not expect_hop else 145):
		await tick()
		var elapsed := (frame + 1) / 60.0
		min_y = minf(min_y, enemy.global_position.y)
		furthest = maxf(furthest, enemy.global_position.x * side)
		if enemy._blocked_time > 0.0 and first_blocked < 0.0:
			first_blocked = elapsed
		if enemy._aggro_retry_timer > 0.0 and retreated_at < 0.0:
			retreated_at = elapsed
	if expect_hop:
		check(furthest > 60 and min_y < 300 - rise, "Ground monster crosses %d px step, direction %d (x=%.1f, apex=%.1f)" % [rise, side, furthest, min_y])
	elif flying:
		check(enemy._aggro_retry_timer == 0.0 and enemy._hop_cooldown == 0.0, "Flying creature is excluded from ground hop/retreat logic")
	else:
		check(retreated_at > 0.0 and retreated_at - first_blocked >= 1.4 and retreated_at - first_blocked <= 1.7, "Blocked monster gives up after 1.5s (%s, delta=%.2f)" % ["ceiling" if ceiling else "high ledge", retreated_at - first_blocked])
		check(enemy.global_position.x * side < -60 and enemy.target_player == null, "Blocked monster backs away instead of instantly reacquiring player")
		check(min_y > 298, "Does not jump into a high wall or low ceiling")
	arena.queue_free()
	await tick()

func key_event(code: Key, physical: bool, pressed: bool) -> void:
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = code
	else:
		event.keycode = code
	event.shift_pressed = code == KEY_SHIFT and pressed
	event.pressed = pressed
	Input.parse_input_event(event)

func _run() -> void:
	SaveManager.custom_save_path = "res://artifacts/game_bugfix_review/navigation_slot.json"
	ZoneManager.reset_session()
	for rise in [20.0, 40.0, 48.0]:
		await navigation_case(rise, 1, true)
	await navigation_case(28, -1, true)
	await navigation_case(80, 1, false)
	await navigation_case(20, 1, false, true)
	await navigation_case(80, 1, false, false, true)
	await navigation_case(80, 1, false, false, false, "ashfang_wolf")
	change_scene_to_file("res://src/world/noctis_forest.tscn")
	for i in range(10):
		await tick()
	var world := current_scene as NoctisForest
	var player := world.player
	var ui := world.game_ui
	var spell := player.spellbook_component.selected_spell_id
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = Vector2(1200, 400)
	ui.open_sidebar(3)
	player._unhandled_input(wheel)
	check(player.spellbook_component.selected_spell_id == spell, "Sidebar scrolling does not switch spells")
	ui.close_sidebar()
	player._unhandled_input(wheel)
	check(player.spellbook_component.selected_spell_id != spell, "World mouse wheel still switches spells")
	for code in [KEY_SHIFT, KEY_X]:
		player.dash_cooldown_timer = 0.0
		player.hurt_recoil_timer = 0.0
		player._change_state(Player.State.IDLE)
		key_event(code, code == KEY_X, true)
		await tick()
		check(player.current_state == Player.State.DASH, "Keyboard shortcut activates dash: " + OS.get_keycode_string(code))
		key_event(code, code == KEY_X, false)
		for i in range(15):
			await tick()
	print("NAVIGATION / INPUT REGRESSIONS: ", failures, " failures")
	quit(0 if failures == 0 else 1)

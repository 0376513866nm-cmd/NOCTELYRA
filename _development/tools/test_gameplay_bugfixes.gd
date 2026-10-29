extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	print(("PASS " if ok else "FAIL ") + description)
	if not ok:
		failures += 1

func settle(count: int = 6) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func pointer(pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = pos
	event.global_position = pos
	event.pressed = pressed
	root.push_input(event)

func _run() -> void:
	root.size = Vector2i(1440, 720)
	# Keep all tests isolated from the real save; add a drop to expose double restoration.
	var fixture := {
		"save_version": SaveManager.CURRENT_VERSION,
		"current_zone_id": "noctis_forest",
		"player": {"race_id":"human", "position_x":180.0, "position_y":632.0, "current_health":75.0, "current_mana":60.0},
		"progression": {"race_id":"human", "level":3, "current_exp":100, "claimed_exp_sources":["enemy:enemy_forest_1"]},
		"gold":150,
		"inventory":[],
		"equipment":{"weapon":"moonsteel_sword", "accessory":"moon_amulet"},
		"quest":{"state":3,"current_amount":3},
		"zone_states":{"noctis_forest":{
			"boss":{"activated":false,"defeated":true,"reward_claimed":true},
			"defeated_enemy_ids":["enemy_forest_1","enemy_forest_2","enemy_forest_3"],
			"collected_pickup_ids":[],
			"dropped_pickups":[{"pickup_id":"regression_drop", "item_id":"mana_shard", "amount":1, "x":900.0, "y":600.0}]
		}}
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/game_bugfix_review"))
	SaveManager.custom_save_path = "res://artifacts/game_bugfix_review/test_slot.json"
	var file := FileAccess.open(SaveManager.custom_save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()
	ZoneManager.reset_session()
	change_scene_to_file("res://src/ui/main_menu.tscn")
	await settle()
	ZoneManager.is_transitioning = true
	ZoneManager.session_player_data = {"gold":99999}
	paused = true
	current_scene._on_continue_pressed()
	await settle()
	check(current_scene is NoctisForest and not paused and not ZoneManager.is_transitioning, "Continue clears stale transition and pause state")
	var world := current_scene as NoctisForest
	check(world.quest_manager.gold == int(fixture.gold), "Continue preserves actual saved gold")
	var drops := 0
	for drop in get_nodes_in_group("dynamic_pickups"):
		if drop.pickup_id == "regression_drop":
			drops += 1
	check(drops == 1, "Continue restores each saved drop exactly once")
	var enemy := world.get_node("CorruptedEnemy1") as Enemy
	check(is_instance_valid(enemy) and not enemy.visible and enemy.current_state == Enemy.State.DEAD, "Saved dead monster keeps its spawn for respawning")
	var old_kills := world.player.quest_journal_component.to_dict().duplicate(true)
	enemy._respawn_timer = 0.01
	await settle()
	check(enemy.visible and enemy.current_state != Enemy.State.DEAD and enemy.health_component.is_alive() and enemy.collision_layer != 0, "Monster respawns with active AI, health and collision restored")
	check(not enemy.enemy_id in world.defeated_enemy_ids, "Respawn removes stale defeated ID from future saves")
	check(world.player.quest_journal_component.to_dict() == old_kills, "Respawn itself does not grant quest kills")
	var reward_count: int = world.player.progression_component.claimed_exp_sources.size()
	enemy.health_component.current_health = 0.0
	enemy._on_died()
	enemy._on_died()
	check(world.player.progression_component.claimed_exp_sources.size() == reward_count + 1, "New monster life grants EXP once, duplicate death grants none")
	enemy._respawn_timer = 0.01
	await settle()
	check(enemy.visible and enemy.health_component.current_health == enemy.health_component.max_health, "Second respawn works and restores full HP")

	var ui := world.game_ui
	ui.set_touch_controls_visible(true)
	await settle()
	check(not ui.settings_gear_btn.visible and not ui.sidebar_toggle_btn.visible, "Hybrid mode has one menu entry and no duplicate gear")
	ui.open_sidebar()
	await settle()
	var close_position := ui.sidebar_close_btn.get_global_rect().get_center()
	ui.close_sidebar()
	await settle()
	var tc := ui.touch_controls
	var menu_position: Vector2 = tc.btn_menu.center
	check(menu_position.distance_to(close_position) < 46.0, "Regression click hits the overlapping menu/close area")
	pointer(menu_position, true)
	var emulated := InputEventScreenTouch.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.position = menu_position
	emulated.pressed = true
	root.push_input(emulated)
	pointer(menu_position, false)
	await settle()
	check(ui.is_sidebar_open(), "One mouse click opens sidebar and does not click through to X")
	close_position = ui.sidebar_close_btn.get_global_rect().get_center()
	pointer(close_position, true)
	pointer(close_position, false)
	await settle()
	check(not ui.is_sidebar_open() and tc.visible, "Separate X click closes sidebar and restores touch controls")
	Input.action_press("move_right")
	tc._joystick_touch_id = 3
	ui.open_sidebar()
	await settle()
	check(not Input.is_action_pressed("move_right") and tc._joystick_touch_id == -1, "Opening sidebar releases held movement instead of leaving it stuck")
	ui.open_sidebar(3)
	ui.close_sidebar()
	check(tc.visible, "Repeated open does not lose touch control visibility")
	ui.set_touch_controls_visible(false)
	check(ui.sidebar_toggle_btn.visible and not ui.settings_gear_btn.visible, "Desktop mode has one visible menu entry")
	ui.set_touch_controls_visible(true)

	# Exercise the actual interaction-button callback, not just a scene change API.
	var portal: ZonePortal
	for candidate in get_nodes_in_group("zone_portals"):
		if candidate.target_zone_id == "elyndra_glade":
			portal = candidate
	world.player.global_position = portal.global_position
	await settle()
	portal._player_in_range = true
	ZoneManager.travel_cooldown = 0.0
	tc.is_interact_visible = true
	tc._handle_touch_event(0, tc.btn_interact.center, true)
	check(ZoneManager.is_transitioning and is_instance_valid(tc) and current_scene == world, "Portal defers scene disposal until interaction callback returns")
	check(not ZoneManager.travel_to_zone("elyndra_glade", "spawn_default", world), "Duplicate portal press is rejected during transition")
	await settle(12)
	check(current_scene is ElyndraGlade and not ZoneManager.is_transitioning, "Portal enters Elyndra successfully")
	check(current_scene.player.health_component.is_alive() and current_scene.quest_manager.gold == int(fixture.gold), "Travel preserves health and gold")
	for target in ["vharok_outpost", "elyndra_glade", "noctis_forest"]:
		ZoneManager.travel_cooldown = 0.0
		check(ZoneManager.travel_to_zone(target, "spawn_default", current_scene), "Travel accepted: " + target)
		await settle(12)
		check(ZoneManager.get_current_zone_id(current_scene) == target and not ZoneManager.is_transitioning, "Travel completed: " + target)
	check(current_scene.boss_defeated and current_scene.boss_reward_claimed, "Return trip preserves defeated boss without granting reward again")
	check(SaveManager.save_game(current_scene), "Saving after return succeeds in isolated slot")
	change_scene_to_file("res://src/ui/main_menu.tscn")
	await settle()
	current_scene._on_continue_pressed()
	await settle(12)
	check(current_scene is NoctisForest and current_scene.player.health_component.is_alive(), "Continue after multiple trips succeeds")
	print("GAMEPLAY REGRESSIONS: ", failures, " failures")
	quit(0 if failures == 0 else 1)

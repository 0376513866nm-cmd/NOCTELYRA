extends SceneTree
## Real movement across ledges: verify the poses follow the physics trajectory.
var failures := 0
var cases: Array = []
var packed := preload("res://src/actors/player/player.tscn")

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1

func _block(world: Node2D, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	world.add_child(body)

func _run() -> void:
	var probe: Player = packed.instantiate()
	root.add_child(probe)
	probe.set_physics_process(false)
	_check(probe.anim_player.has_animation("run"), "run cycle available for short ledges")
	probe.queue_free()
	await process_frame
	for height in [20.0, 40.0, 48.0]:
		await _ledge_case(height, false)
		await _ledge_case(height, false, -1.0)
	for height in [20.0, 40.0, 70.0]:
		await _ledge_case(height, true)
	await _ledge_case(120.0, false)
	Input.action_release("move_right")
	var file := FileAccess.open("res://artifacts/low_hop/physics_test.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "cases": cases}, "\t"))
	print("LOW HOP PHYSICS: ", failures, " failures")
	quit(0 if failures == 0 else 1)

func _ledge_case(height: float, dropping: bool, direction: float = 1.0) -> void:
	var world := Node2D.new()
	root.add_child(world)
	_block(world, Vector2(500, 680), Vector2(2000, 100))
	_block(world, Vector2(400, 630-height*0.5), Vector2(200, height))
	var player: Player = packed.instantiate()
	player.position = Vector2(400 if dropping else (180 if direction > 0 else 620), 630-height if dropping else 630)
	world.add_child(player)
	for i in range(30):
		await physics_frame
		await process_frame
	var action := "move_right" if direction > 0 else "move_left"
	Input.action_press(action)
	var samples: Array = []
	var hopped := false
	var fell := false
	var soft_landed := false
	var reached_top := false
	var min_y := player.position.y
	var wrong_pose := false
	var double_body := false
	var previous_run_time := -1.0
	var continuous_run := true
	var takeoff_gap := -1.0
	var bumped_step := false
	for i in range(115):
		await physics_frame
		await process_frame
		min_y = minf(min_y, player.position.y)
		var state: String = player._get_state_name(player.current_state)
		var anim: String = player.anim_player.assigned_animation
		var frame: int = player.get_node("SpriteRoot/RunSprite").frame
		var run_time := player.anim_player.current_animation_position
		if anim == "run":
			if previous_run_time >= 0.0 and previous_run_time < player.anim_player.get_animation("run").length - 0.04:
				continuous_run = continuous_run and run_time >= previous_run_time
			previous_run_time = run_time
		else:
			previous_run_time = -1.0
		if player.current_state == Player.State.AUTO_HOP:
			if not hopped:
				var edge := 300.0 if direction > 0 else 500.0
				takeoff_gap = absf(edge - (player.position.x - player.velocity.x / 60.0))
			hopped = true
			bumped_step = bumped_step or player.is_on_wall() or absf(player.velocity.x) < player.movement_data.move_speed * 0.95
			wrong_pose = wrong_pose or anim != "run"
		if player.current_state == Player.State.FALL and not player.is_on_floor():
			fell = true
			wrong_pose = wrong_pose or anim != "run"
		if player.current_state == Player.State.LAND:
			soft_landed = true
			wrong_pose = wrong_pose or anim != "run"
		var visible := 0
		for sprite in player.sprite_root.get_children():
			if sprite is Sprite2D and sprite.visible:
				visible += 1
		double_body = double_body or visible != 1
		if player.is_on_floor() and player.position.x > 320 and player.position.x < 480 and absf(player.position.y-(630-height)) < 1.0:
			reached_top = true
		samples.append({"tick":i,"x":player.position.x,"y":player.position.y,"vy":player.velocity.y,"state":state,"animation":anim,"frame":frame})
	Input.action_release(action)
	var label := "%s %.0fpx %s" % ["drop" if dropping else "step", height, "right" if direction > 0 else "left"]
	if height > 48 and not dropping:
		_check(not hopped and player.position.x < 300, label + " requires a manual jump")
	elif dropping:
		_check(fell and soft_landed and not hopped, label + " uses freefall then a light landing")
	else:
		_check(hopped and reached_top, label + " is crossed automatically")
		_check(630-min_y <= 65 and 630-min_y >= height, label + " stays a genuinely low hop")
		_check(takeoff_gap >= 30.0 and takeoff_gap <= 35.1, label + " launches about 35px before the edge (%.1fpx)" % takeoff_gap)
		_check(not bumped_step, label + " clears the edge without hitting the side or losing speed")
	_check(not wrong_pose, label + " keeps run throughout the ledge")
	_check(continuous_run, label + " run clock continues without restarting")
	_check(not double_body, label + " only one body sprite is visible")
	cases.append({"case":label,"peak_above_base":630-min_y,"takeoff_gap":takeoff_gap,"bumped_step":bumped_step,"samples":samples})
	world.queue_free()
	await process_frame

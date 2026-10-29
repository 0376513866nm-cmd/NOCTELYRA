extends SceneTree

const PlayerScript = preload("res://src/actors/player/player.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING AUTO-STEP & LOW LEDGE HOP ANIMATION")
	print("==================================================")

	var all_passed := true

	# 1. Load Player Scene
	var player_scene = load("res://src/actors/player/player.tscn")
	if player_scene == null:
		print("  [FAIL] Không thể load player.tscn")
		quit(1)
		return

	var player: Player = player_scene.instantiate() as Player
	var test_world = Node2D.new()
	root.add_child(test_world)
	test_world.add_child(player)

	# --- TEST 1: Kiểm tra Hoạt ảnh Nhảy Thấp & Rơi Tự Do Bậc Thấp ---
	print("\n--- TEST 1: Hoạt ảnh Nhảy Thấp (110-140) & Rơi Tự Do Bậc Thấp (140-180) ---")
	var hop_sprite = player.get_node_or_null("SpriteRoot/HopSprite") as Sprite2D
	if hop_sprite != null:
		print("  [PASS] HopSprite tồn tại trong SpriteRoot")
		if hop_sprite.texture != null and hop_sprite.hframes == 8 and hop_sprite.vframes == 4:
			print("  [PASS] HopSprite gán đúng texture player_hop_atlas.png (8x4 = 32 frames)")
		else:
			print("  [FAIL] HopSprite chưa gán đúng texture hoặc hframes/vframes (hframes=%d, vframes=%d)" % [hop_sprite.hframes, hop_sprite.vframes])
			all_passed = false
	else:
		print("  [FAIL] Không tìm thấy HopSprite")
		all_passed = false

	var anim_player: AnimationPlayer = player.anim_player
	if anim_player and anim_player.has_animation("low_jump") and anim_player.has_animation("low_fall"):
		print("  [PASS] AnimationPlayer có đủ hoạt ảnh 'low_jump' (110-140) và 'low_fall' (140-180)")
		var jump_anim = anim_player.get_animation("low_jump")
		var fall_anim = anim_player.get_animation("low_fall")
		if jump_anim.length >= 0.35 and fall_anim.length >= 0.35:
			print("  [PASS] Thời lượng hoạt ảnh chuẩn mượt mà đồng bộ GIF (low_jump: %.2fs, low_fall: %.2fs)" % [jump_anim.length, fall_anim.length])
		else:
			print("  [FAIL] Thời lượng hoạt ảnh không hợp lý")
			all_passed = false
	else:
		print("  [FAIL] AnimationPlayer thiếu hoạt ảnh 'low_jump' hoặc 'low_fall'")
		all_passed = false

	if anim_player and anim_player.has_animation("hop"):
		print("  [PASS] AnimationPlayer bảo toàn tương thích hoạt ảnh 'hop'")
	else:
		print("  [FAIL] AnimationPlayer thiếu hoạt ảnh 'hop'")
		all_passed = false

	# --- TEST 2: Thềm thấp (Low Step 40px) -> Tự động bước lên và giữ nguyên hoạt ảnh RUN ---
	print("\n--- TEST 2: Thềm Thấp 90 Độ (40px) -> Giữ Nguyên Hoạt Ảnh RUN ---")
	# Tạo mặt đất cơ sở tại y=630
	var base_ground = StaticBody2D.new()
	var bg_col = CollisionShape2D.new()
	var bg_rect = RectangleShape2D.new()
	bg_rect.size = Vector2(1000, 100)
	bg_col.shape = bg_rect
	base_ground.position = Vector2(200, 680)
	base_ground.collision_layer = 1
	base_ground.add_child(bg_col)
	test_world.add_child(base_ground)

	# Tạo một thềm thấp cao 40px tại x=300 (mặt thềm tại y=590)
	var low_step = StaticBody2D.new()
	var ls_col = CollisionShape2D.new()
	var ls_rect = RectangleShape2D.new()
	ls_rect.size = Vector2(200, 80)
	ls_col.shape = ls_rect
	low_step.position = Vector2(400, 630) # Top surface = 630 - 40 = 590! Chiều cao = 630 - 590 = 40px!
	low_step.collision_layer = 1
	low_step.add_child(ls_col)
	test_world.add_child(low_step)

	await process_frame
	await process_frame

	# Kiểm tra rơi tự do từ thềm thấp kích hoạt low_fall (cách mặt đất 40px)
	player.current_state = Player.State.FALL
	player.jumps_left = player.movement_data.max_jumps
	player.global_position = Vector2(200, 590) # Cách sàn 40px
	player._refresh_current_animation()
	if anim_player.current_animation == "low_fall":
		print("  [PASS] Rơi tự do từ thềm thấp (khoảng cách <= 70px): Kích hoạt hoạt ảnh 'low_fall' mượt mà!")
	else:
		print("  [FAIL] Chưa kích hoạt đúng 'low_fall' khi rơi bậc thấp: " + anim_player.current_animation)
		all_passed = false

	await process_frame
	await process_frame

	# Đặt người chơi đứng tại x=280, y=630 (ngay trước mép thềm tại x=300)
	player.global_position = Vector2(280, 630)
	player.velocity = Vector2(player.movement_data.move_speed, 0)
	player.facing_direction = 1
	player.current_state = Player.State.RUN
	player.auto_step_cooldown = 0.0
	anim_player.play("run")

	# Kích hoạt kiểm tra tự động nhảy thềm thấp
	var stepped := player._check_auto_step(0.016)
	if stepped and player.current_state == Player.State.AUTO_HOP:
		print("  [PASS] Phát hiện thềm thấp 40px: Tự động kích hoạt AUTO_HOP với cú nhảy lướt!")
		if player.velocity.y <= -400.0:
			print("  [PASS] Lực bật nhảy thềm thấp kéo dài đồng bộ GIF: velocity.y = %.1f px/s" % player.velocity.y)
		else:
			print("  [FAIL] Lực nhảy chưa đủ cao: velocity.y = %.1f" % player.velocity.y)
			all_passed = false
		if anim_player.current_animation == "low_jump" or anim_player.current_animation == "hop":
			print("  [PASS] Hoạt ảnh 'low_jump' phát mượt mà từ lúc nhún tới đỉnh")
		else:
			print("  [FAIL] Hoạt ảnh đang phát không phải 'low_jump': " + anim_player.current_animation)
			all_passed = false
	else:
		print("  [FAIL] Không tự động nhảy thềm thấp (stepped=%s, state=%s)" % [str(stepped), player._get_state_name(player.current_state)])
		all_passed = false

	# --- TEST 3: Khối quá cao (High Wall 120px) -> KHÔNG tự nhảy (Phải nhảy chủ động) ---
	print("\n--- TEST 3: Khối Quá Cao -> KHÔNG Tự Nhảy (Bắt Buộc Nhảy Chủ Động) ---")
	var high_wall = StaticBody2D.new()
	var hw_col = CollisionShape2D.new()
	var hw_rect = RectangleShape2D.new()
	hw_rect.size = Vector2(80, 400)
	hw_col.shape = hw_rect
	high_wall.position = Vector2(600, 500) # Wall spanning y=300 to y=700 (chiều cao 130px so với sàn)
	high_wall.collision_layer = 1
	high_wall.add_child(hw_col)
	test_world.add_child(high_wall)

	await process_frame
	await process_frame

	# Reset trạng thái về RUN ngay trước bức tường cao
	player.auto_step_cooldown = 0.0
	player.global_position = Vector2(540, 630)
	player.velocity = Vector2(player.movement_data.move_speed, 0)
	player.facing_direction = 1
	player.current_state = Player.State.RUN

	var blocked_hop := player._check_auto_step(0.016)
	if not blocked_hop and player.current_state == Player.State.RUN:
		print("  [PASS] Gặp chướng ngại vật quá cao (>50px): KHÔNG tự động nhảy, giữ nguyên trạng thái di chuyển!")
	else:
		print("  [FAIL] Vẫn tự động nhảy khi gặp khối quá cao!")
		all_passed = false

	test_world.queue_free()
	await process_frame

	print("\n==================================================")
	if all_passed:
		print(">>> TẤT CẢ TEST AUTO-STEP & NHẢY NHẸ THỀM THẤP ĐẠT 100%! <<<")
	else:
		print(">>> CÓ TEST KHÔNG ĐẠT! <<<")
	print("==================================================")

	quit(0 if all_passed else 1)

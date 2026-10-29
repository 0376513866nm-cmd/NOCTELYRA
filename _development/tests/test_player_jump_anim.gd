extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING PLAYER JUMP & DOUBLE JUMP ANIMATIONS")
	print("==================================================")

	var p_scene = load("res://src/actors/player/player.tscn")
	_assert(p_scene != null, "Scene player.tscn load thành công")
	var player: Player = p_scene.instantiate() as Player
	_assert(player != null, "Player instantiate thành công")
	root.add_child(player)
	await process_frame

	var anim_p: AnimationPlayer = player.anim_player
	_assert(anim_p != null, "Player có AnimationPlayer và đã được khởi tạo")
	var jump_sprite := player.get_node("SpriteRoot/JumpSprite") as Sprite2D
	_assert(jump_sprite != null, "Player có JumpSprite")
	_assert(jump_sprite.texture.get_size() == Vector2(2048, 3400), "Atlas nhảy mới đã import đúng kích thước 2048x3400")
	_assert(jump_sprite.hframes == 8 and jump_sprite.vframes == 10, "JumpSprite chia đúng 80 ô 256x340")

	# 1. Animation JUMP (Lần Nhảy 1: Đủ 24 khung F30..F53)
	print("\n--- TEST 1: Animation Jump (Lần Nhảy 1: Đủ 24 khung F30..F53 lật hướng dương) ---")
	_assert(anim_p.has_animation("jump"), "Player có animation 'jump'")
	var a_jump = anim_p.get_animation("jump")
	_assert(is_equal_approx(a_jump.length, 0.4), "Thời lượng animation 'jump' là 0.4s")
	var track_jump_frame = a_jump.find_track(NodePath("SpriteRoot/JumpSprite:frame"), Animation.TYPE_VALUE)
	_assert(track_jump_frame != -1, "Animation 'jump' điều khiển frame của JumpSprite")
	_assert(a_jump.track_get_key_count(track_jump_frame) == 24, "Animation 'jump' có đủ 24 khung hình vươn người vút lên đỉnh (apex) siêu mượt")

	# 2. Animation DOUBLE JUMP (Jump 2)
	print("\n--- TEST 2: Animation Double Jump (Lần Nhảy 2 / Nhảy Đúp) ---")
	_assert(anim_p.has_animation("double_jump"), "Player có animation 'double_jump'")
	var a_dj = anim_p.get_animation("double_jump")
	_assert(is_equal_approx(a_dj.length, 0.35), "Thời lượng animation 'double_jump' là 0.35s")
	var track_dj_frame = a_dj.find_track(NodePath("SpriteRoot/JumpSprite:frame"), Animation.TYPE_VALUE)
	_assert(track_dj_frame != -1, "Animation 'double_jump' điều khiển frame của JumpSprite")
	_assert(a_dj.track_get_key_count(track_dj_frame) == 8, "Animation 'double_jump' có đủ 8 khung hình bung người trên không")

	# 3. Animation FALL (Rơi tự do)
	print("\n--- TEST 3: Animation Fall (Rơi Tự Do) ---")
	_assert(anim_p.has_animation("fall"), "Player có animation 'fall'")
	var a_fall = anim_p.get_animation("fall")
	_assert(is_equal_approx(a_fall.length, 0.4), "Thời lượng animation 'fall' là 0.4s")
	var track_fall_frame = a_fall.find_track(NodePath("SpriteRoot/JumpSprite:frame"), Animation.TYPE_VALUE)
	_assert(track_fall_frame != -1, "Animation 'fall' điều khiển frame của JumpSprite")
	_assert(a_fall.track_get_key_count(track_fall_frame) == 8, "Animation 'fall' có đủ 8 khung hình rơi tự do bồng bềnh thanh thoát")

	# 3b. Animation JUMP_FALL (Rơi sau Nhảy 1: chuỗi rơi đều 24 khung F54..Touchdown)
	print("\n--- TEST 3b: Animation Jump Fall (Rơi Sau Cú Nhảy 1: Đủ 24 khung cắt đều từ F54) ---")
	_assert(anim_p.has_animation("jump_fall"), "Player có animation 'jump_fall'")
	var a_jf = anim_p.get_animation("jump_fall")
	var track_jf_frame = a_jf.find_track(NodePath("SpriteRoot/JumpSprite:frame"), Animation.TYPE_VALUE)
	_assert(track_jf_frame != -1, "Animation 'jump_fall' điều khiển frame của JumpSprite")
	_assert(a_jf.track_get_key_count(track_jf_frame) == 24, "Animation 'jump_fall' có đủ 24 khung rơi của cú nhảy đơn")
	_assert(a_jf.track_get_key_value(track_jf_frame, 0) == 24, "Animation 'jump_fall' bắt đầu tại frame 24")

	# 3c. Animation LAND (tiếp đất 16 khung chuyển tiếp từ cúi người sang đứng thẳng)
	print("\n--- TEST 3c: Animation Land (16 khung mượt mà từ hãm xung đến từ từ đứng thẳng sang Idle) ---")
	_assert(anim_p.has_animation("land"), "Player có animation 'land'")
	var a_land = anim_p.get_animation("land")
	_assert(is_equal_approx(a_land.length, 0.25), "Thời lượng animation 'land' là 0.25s")
	var track_land_frame = a_land.find_track(NodePath("SpriteRoot/JumpSprite:frame"), Animation.TYPE_VALUE)
	_assert(track_land_frame != -1, "Animation 'land' điều khiển frame của JumpSprite")
	_assert(a_land.track_get_key_count(track_land_frame) == 16, "Animation 'land' có đủ 16 khung hình chuyển tiếp mượt mà từ cúi sang đứng thẳng")

	# 4. State Machine transitions
	print("\n--- TEST 4: Kích Hoạt Hoạt Ảnh Theo Trạng Thái ---")
	# Jump 1 -> Fall từ Jump 1: phát chuỗi rơi riêng (jump_fall)
	player.jumps_left = 1
	player._change_state(Player.State.JUMP)
	_assert(anim_p.current_animation == "jump", "Chuyển sang State.JUMP phát animation 'jump'")
	player._change_state(Player.State.FALL)
	_assert(anim_p.current_animation == "jump_fall", "Rơi sau Nhảy 1 (jumps_left == 1) phát animation 'jump_fall'")

	# Double Jump (jumps_left == 0) -> Fall từ Double Jump: dùng animation rơi thả lỏng 'fall'
	player.jumps_left = 0
	player._change_state(Player.State.JUMP)
	_assert(anim_p.current_animation == "double_jump", "Nhảy lần 2 (jumps_left == 0) phát animation 'double_jump'")
	player._change_state(Player.State.FALL)
	_assert(anim_p.current_animation == "fall", "Rơi sau Nhảy đúp (jumps_left == 0) phát animation 'fall'")

	# Rơi từ vách núi khi chưa nhảy (jumps_left == 2): dùng animation rơi thả lỏng 'fall'
	player.jumps_left = 2
	player._change_state(Player.State.FALL)
	_assert(anim_p.current_animation == "fall", "Rơi tự do khi chưa nhảy (jumps_left == 2) phát animation 'fall'")

	# Land on ground -> LAND, rồi state machine mới trở lại Idle/Run.
	player._change_state(Player.State.LAND)
	_assert(anim_p.current_animation == "land", "Tiếp đất phát animation 'land'")

	player.queue_free()
	print("\n==================================================")
	print(">>> TẤT CẢ TEST HOẠT ẢNH NHẢY 1 & NHẢY ĐÚP ĐẠT 100%! <<<")
	print("==================================================")
	quit(0)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] " + msg)
	else:
		printerr(" [FAIL] " + msg)
		quit(1)

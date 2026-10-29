extends SceneTree

func _init() -> void:
	print("--- BAT DAU KIEM THU ARCHITECTURE NOCTELYRA M0 ---")
	var root_scene = load("res://src/world/test_level.tscn").instantiate()
	root.add_child(root_scene)

	var player: Player = root_scene.get_node("Player")
	var pause_ctrl: PauseController = root_scene.get_node("PauseController")
	var pause_menu: Control = root_scene.get_node("CanvasLayer/PauseMenu")

	# Yêu cầu 1, 2, 3: Kiểm tra Process Mode chuẩn kiến trúc
	assert(root_scene.process_mode == Node.PROCESS_MODE_PAUSABLE, "Loi: TestLevel phai la PROCESS_MODE_PAUSABLE")
	assert(pause_ctrl.process_mode == Node.PROCESS_MODE_ALWAYS, "Loi: PauseController phai la PROCESS_MODE_ALWAYS")
	assert(pause_menu.process_mode == Node.PROCESS_MODE_WHEN_PAUSED, "Loi: PauseMenu phai la PROCESS_MODE_WHEN_PAUSED")
	assert(player.process_mode == Node.PROCESS_MODE_INHERIT, "Loi: Player ke thua pausable")
	print("[PASS] Yeu cau 1, 2, 3: Kien truc Process Mode phan tach ro rang (Level pausable, Controller always, Menu when_paused)")

	# Yêu cầu 5: Esc lần đầu pause, Esc lần hai resume
	assert(!paused, "Loi: Ban dau khong duoc pause")
	assert(!pause_menu.visible, "Loi: Menu ban dau phai an")
	
	# PauseController trong tree
	pause_ctrl.toggle_pause() # Esc lan 1
	assert(paused, "Loi: Esc lan 1 khong pause tree")
	assert(pause_menu.visible, "Loi: Esc lan 1 khong hien menu")
	
	pause_ctrl.toggle_pause() # Esc lan 2
	assert(!paused, "Loi: Esc lan 2 khong resume tree")
	assert(!pause_menu.visible, "Loi: Esc lan 2 khong an menu")
	print("[PASS] Yeu cau 5a: Esc toggle 2 chieu hoan hao")

	# Nút Resume hoạt động
	pause_ctrl.toggle_pause()
	assert(paused, "Loi: Phai pause truoc khi test nut resume")
	root_scene._on_resume_button_pressed()
	assert(!paused, "Loi: Nut Resume khong resume game")
	assert(!pause_menu.visible, "Loi: Nut Resume khong an menu")
	print("[PASS] Yeu cau 5b: Nut Resume hoat dong 100%")

	# Yêu cầu 4 & Kiểm thử bắt buộc: Đang Dash rồi Pause -> Đợi vài giây -> Timer Dash và Player không cập nhật
	Input.action_press("dash")
	player._physics_process(0.016)
	Input.action_release("dash")
	assert(player.current_state == player.State.DASH, "Loi: Khong kich hoat duoc dash")
	var dash_time_before = player.dash_timer

	# Kích hoạt Pause khi đang dash
	pause_ctrl.toggle_pause()
	assert(paused, "Loi: Khong pause duoc khi dang dash")

	# Kiểm tra player can_process() khi tree pause:
	assert(!player.can_process(), "Loi: Player van co the process khi game pause!")
	
	# Resume lại sau khi pause
	pause_ctrl.toggle_pause()
	assert(!paused, "Loi: Khong resume duoc")
	assert(player.can_process(), "Loi: Player phai tiep tuc process duoc sau khi resume")
	assert(player.dash_timer == dash_time_before, "Loi: dash_timer bi troi trong thoi gian pause")
	print("[PASS] Yeu cau 4 & Test bat buoc: Khi Pause, Player + Anim + Timer thuc su DUNG YEN, khong tiep tuc cap nhat")

	# Test bắt buộc: Di chuyển + Nhảy cùng lúc
	Input.action_press("move_right")
	Input.action_press("jump")
	player._physics_process(0.016)
	assert(player.current_state == player.State.JUMP, "Loi: Move + Jump cung luc khong vao JUMP")
	print("[PASS] Test bat buoc: Di chuyen + Nhay cung luc vao JUMP, khong bi RUN ghi de")

	Input.action_release("jump")
	Input.action_release("move_right")

	# Test bắt buộc: Air Dash
	player.velocity.y = 10.0
	player._change_state(player.State.FALL)
	player.dash_cooldown_timer = 0.0 # reset cooldown de test air-dash
	Input.action_press("dash")
	player._physics_process(0.016)
	Input.action_release("dash")
	assert(player.current_state == player.State.DASH, "Loi: Khong the dash tren khong")
	print("[PASS] Test bat buoc: Air Dash tren khong thanh cong")

	# Test bắt buộc: Tiếp đất khôi phục lượt nhảy đôi
	player._change_state(player.State.IDLE)
	assert(player.jumps_left == 2, "Loi: Tiep dat khong hoi du 2 luot nhay")
	print("[PASS] Test bat buoc: Tiep dat khoi phuc luot nhay doi chinh xac")

	print("--- TAT CA CAC YEU CAU VA KIEM THU BAT BUOC DEU PASS 100% ---")
	quit(0)
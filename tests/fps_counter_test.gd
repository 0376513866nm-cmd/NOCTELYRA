extends SceneTree

const SettingsManager = preload("res://src/ui/settings_manager.gd")
const SettingsUIController = preload("res://src/ui/controllers/settings_ui_controller.gd")

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("--- BẮT ĐẦU KIỂM THỬ TÍNH NĂNG ĐO FPS & CÀI ĐẶT ---")
	test_settings_manager_fps()
	test_settings_ui_controller_fps()
	await test_game_ui_fps_integration()
	print("ALL_FPS_COUNTER_TESTS_PASS_SUCCESSFULLY")
	quit(0)

func test_settings_manager_fps() -> void:
	var temp_path := "user://test_fps_settings.json"
	SettingsManager.custom_settings_path = temp_path

	SettingsManager.show_fps = false
	SettingsManager.save_settings()

	# Force reload
	SettingsManager.load_settings(true)
	assert(SettingsManager.show_fps == false, "show_fps should be false after save/load")

	# Toggle
	var toggled := SettingsManager.toggle_show_fps()
	assert(toggled == true, "toggle_show_fps should return true")
	assert(SettingsManager.show_fps == true, "show_fps should be true")

	# Force reload again to verify persistence
	SettingsManager.load_settings(true)
	assert(SettingsManager.show_fps == true, "show_fps should persist true in json")

	# Cleanup
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	SettingsManager.custom_settings_path = ""
	print("[PASS] Bài test 1: SettingsManager lưu, nạp và toggle show_fps chuẩn xác")

func test_settings_ui_controller_fps() -> void:
	var controller := SettingsUIController.new()
	var fps_btn := Button.new()
	var sb_fps_btn := Button.new()

	controller.setup(
		null, null, null, null, null,
		null, null, null,
		fps_btn, sb_fps_btn
	)

	SettingsManager.show_fps = false
	controller.update_ui()
	assert(fps_btn.text == "Hiển Thị FPS: TẮT", "Button text should be TẮT when false")
	assert(sb_fps_btn.text == "Hiển Thị FPS: TẮT", "Sidebar button text should be TẮT when false")

	controller.toggle_show_fps()
	assert(SettingsManager.show_fps == true, "show_fps should be true after toggle")
	assert(fps_btn.text == "Hiển Thị FPS: BẬT", "Button text should be BẬT when true")
	assert(sb_fps_btn.text == "Hiển Thị FPS: BẬT", "Sidebar button text should be BẬT when true")

	fps_btn.free()
	sb_fps_btn.free()
	print("[PASS] Bài test 2: SettingsUIController cập nhật giao diện nút FPS đồng bộ")

func test_game_ui_fps_integration() -> void:
	var game_ui_scene: PackedScene = load("res://src/ui/game_ui.tscn")
	assert(game_ui_scene != null, "game_ui.tscn must be loadable")
	var game_ui = game_ui_scene.instantiate()
	root.add_child(game_ui)
	await process_frame
	await process_frame

	var fps_panel = game_ui.get_node_or_null("HUD/FPSPanel")
	assert(fps_panel != null, "HUD/FPSPanel must exist in game_ui")
	var fps_label = game_ui.get_node_or_null("HUD/FPSPanel/FPSLabel")
	assert(fps_label != null, "HUD/FPSPanel/FPSLabel must exist in game_ui")

	var pause_fps_btn = game_ui.find_child("FPSBtn", true, false)
	assert(pause_fps_btn != null, "PauseMenu FPSBtn must exist")
	var sb_fps_btn = game_ui.find_child("SidebarFPSBtn", true, false)
	assert(sb_fps_btn != null, "Sidebar FPSBtn must exist")

	# Verify SettingsPanel is a ScrollContainer
	var settings_panel = game_ui.get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel")
	assert(settings_panel is ScrollContainer, "SettingsPanel must be a ScrollContainer to support scrolling")
	assert(settings_panel.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Vertical scroll must be enabled")

	# Verify Game Guide collapsible sub-section
	var guide_btn = game_ui.find_child("GuideToggleBtn", true, false)
	var guide_content = game_ui.find_child("GuideContent", true, false)
	assert(guide_btn != null, "GuideToggleBtn must exist in SettingsPanel")
	assert(guide_content != null, "GuideContent must exist in SettingsPanel")
	assert(guide_content.visible == false, "GuideContent should be collapsed by default for compact view")

	game_ui._on_guide_toggle_pressed()
	assert(guide_content.visible == true, "GuideContent should expand on toggle")
	game_ui._on_guide_toggle_pressed()
	assert(guide_content.visible == false, "GuideContent should collapse on toggle")

	# Verify Touch Drag Scrolling on settings_panel when content overflows
	game_ui.open_sidebar(3)
	game_ui._on_guide_toggle_pressed() # Expand guide so content overflows panel
	await process_frame
	await process_frame
	var panel_rect: Rect2 = settings_panel.get_global_rect()
	var touch_pt: Vector2 = panel_rect.position + Vector2(panel_rect.size.x * 0.5, panel_rect.size.y * 0.5)

	var t_down := InputEventScreenTouch.new()
	t_down.index = 0
	t_down.pressed = true
	t_down.position = touch_pt
	settings_panel._input(t_down)

	var t_drag := InputEventScreenDrag.new()
	t_drag.index = 0
	t_drag.position = touch_pt + Vector2(0, -60)
	t_drag.relative = Vector2(0, -60)
	settings_panel._input(t_drag)
	assert(settings_panel.scroll_vertical > 0, "settings_panel must scroll upon touch drag")

	var t_up := InputEventScreenTouch.new()
	t_up.index = 0
	t_up.pressed = false
	t_up.position = touch_pt + Vector2(0, -60)
	settings_panel._input(t_up)

	# Test toggling via game_ui method
	SettingsManager.show_fps = false
	game_ui._process(0.016)
	assert(fps_panel.visible == false, "FPS panel should be hidden when show_fps is false")

	game_ui._on_toggle_fps_pressed()
	assert(SettingsManager.show_fps == true, "show_fps should be true after pressing toggle")
	game_ui._process(0.016)
	assert(fps_panel.visible == true, "FPS panel should be visible when show_fps is true")

	# Turn off again
	game_ui._on_toggle_fps_pressed()
	assert(SettingsManager.show_fps == false, "show_fps should be false after pressing toggle again")
	game_ui._process(0.016)
	assert(fps_panel.visible == false, "FPS panel should be hidden when show_fps is false")

	game_ui.queue_free()
	await process_frame
	print("[PASS] Bài test 3: Tích hợp GameUI, HUD FPSPanel và Settings panel hoạt động hoàn hảo")

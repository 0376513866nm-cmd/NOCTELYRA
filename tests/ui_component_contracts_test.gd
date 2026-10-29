extends SceneTree

# UI Component Contracts & Decoupling Regression Test Suite
# Tests isolated contracts for BossHUD, WorldOverlayUI, EndScreenUI, PauseMenu, SidebarUI, and GameUI integration.

const BossHUDScene = preload("res://src/ui/boss_hud.tscn")
const WorldOverlayUIScene = preload("res://src/ui/world_overlay_ui.tscn")
const EndScreenUIScene = preload("res://src/ui/end_screen_ui.tscn")
const PauseMenuScene = preload("res://src/ui/pause_menu.tscn")
const SidebarUIScene = preload("res://src/ui/sidebar_ui.tscn")
const GameUIScene = preload("res://src/ui/game_ui.tscn")
const SettingsManager = preload("res://src/ui/settings_manager.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- BẮT ĐẦU KIỂM THỬ GIAO DIỆN CON VÀ CONTRACTS (COMMIT 8) ---")
	await _test_boss_hud()
	await _test_world_overlay_ui()
	await _test_end_screen_ui()
	await _test_pause_menu()
	await _test_sidebar_ui()
	await _test_game_ui_integration()
	print("ALL_UI_COMPONENT_CONTRACTS_PASS_SUCCESSFULLY")
	quit(0)

func _fail(msg: String) -> void:
	printerr("[FAIL] %s" % msg)
	quit(1)

func _test_boss_hud() -> void:
	var hud: Node = BossHUDScene.instantiate()
	root.add_child(hud)
	await process_frame

	if not hud.has_method("show_boss"):
		_fail("BossHUD thiếu method show_boss!")
		return
	if not hud.has_method("set_health"):
		_fail("BossHUD thiếu method set_health!")
		return
	if not hud.has_method("set_phase"):
		_fail("BossHUD thiếu method set_phase!")
		return
	if not hud.has_method("show_warning"):
		_fail("BossHUD thiếu method show_warning!")
		return
	if not hud.has_method("show_announcement"):
		_fail("BossHUD thiếu method show_announcement!")
		return

	hud.show_boss("Test Boss", 500.0)
	if not hud.boss_bar_panel.visible:
		_fail("BossHUD phải hiển thị khi show_boss!")
		return
	if hud.boss_name_label.text != "Test Boss":
		_fail("Boss name không đúng!")
		return
	if hud.boss_hp_bar.value != 500.0 or hud.boss_hp_bar.max_value != 500.0:
		_fail("Boss HP bar không cập nhật giá trị đúng!")
		return

	hud.set_health(250.0, 500.0)
	hud.set_phase(2)
	if hud.boss_hp_bar.value != 250.0:
		_fail("Boss HP bar không cập nhật khi set_health!")
		return
	if not "GIAI ĐOẠN 2" in hud.boss_phase_label.text:
		_fail("Boss phase label không đúng!")
		return

	hud.hide_boss()
	if hud.boss_bar_panel.visible:
		_fail("BossHUD phải ẩn khi hide_boss!")
		return

	hud.queue_free()
	await process_frame
	print("[PASS] 1. BossHUD contract & state management OK")

func _test_world_overlay_ui() -> void:
	var overlay: Node = WorldOverlayUIScene.instantiate()
	root.add_child(overlay)
	await process_frame

	if not overlay.has_method("show_notification"):
		_fail("WorldOverlayUI thiếu show_notification!")
		return
	if not overlay.has_method("show_zone_banner"):
		_fail("WorldOverlayUI thiếu show_zone_banner!")
		return
	if not overlay.has_method("set_zone_text"):
		_fail("WorldOverlayUI thiếu set_zone_text!")
		return

	overlay.show_notification("Thông báo test", 1.0)
	if not overlay.notification_label.visible or overlay.notification_label.text != "Thông báo test":
		_fail("Notification label không hiển thị đúng text!")
		return

	overlay.show_zone_banner("Rừng Noctis", "Vùng đất bóng tối")
	if not overlay.zone_banner.visible or overlay.zone_banner_title.text != "Rừng Noctis":
		_fail("Zone banner không hiển thị đúng!")
		return

	overlay.set_zone_text("Khu vực an toàn")
	if overlay.zone_label.text != "Khu vực an toàn":
		_fail("Zone label không cập nhật đúng!")
		return

	overlay.queue_free()
	await process_frame
	print("[PASS] 2. WorldOverlayUI contract & banner/notification OK")

func _test_end_screen_ui() -> void:
	var end_screen: Node = EndScreenUIScene.instantiate()
	root.add_child(end_screen)
	await process_frame

	var retry_flag := [false]
	var victory_flag := [false]
	end_screen.retry_requested.connect(func(): retry_flag[0] = true)
	end_screen.victory_dismissed.connect(func(): victory_flag[0] = true)

	end_screen.show_game_over()
	if not end_screen.game_over_panel.visible:
		_fail("GameOver panel phải hiển thị khi show_game_over!")
		return

	end_screen.retry_button.pressed.emit()
	if not retry_flag[0]:
		_fail("retry_button không phát tín hiệu retry_requested!")
		return

	end_screen.show_victory("Chiến Thắng!", "Bạn đã giải cứu thế giới")
	if not end_screen.victory_panel.visible or end_screen.victory_title.text != "Chiến Thắng!":
		_fail("Victory panel không hiển thị đúng!")
		return

	end_screen.victory_continue_btn.pressed.emit()
	if not victory_flag[0]:
		_fail("victory_continue_btn không phát tín hiệu victory_dismissed!")
		return
	if end_screen.victory_panel.visible:
		_fail("Victory panel phải đóng khi bấm continue!")
		return

	end_screen.queue_free()
	await process_frame
	print("[PASS] 3. EndScreenUI contract & retry/victory flow OK")

func _test_pause_menu() -> void:
	var pause_menu: Node = PauseMenuScene.instantiate()
	root.add_child(pause_menu)
	await process_frame

	var resume_flag := [false]
	var save_flag := [false]
	var quit_flag := [false]
	var settings_open_flag := [false]
	var settings_close_flag := [false]

	pause_menu.resume_requested.connect(func(): resume_flag[0] = true)
	pause_menu.save_requested.connect(func(): save_flag[0] = true)
	pause_menu.quit_requested.connect(func(): quit_flag[0] = true)
	pause_menu.settings_opened.connect(func(): settings_open_flag[0] = true)
	pause_menu.settings_closed.connect(func(): settings_close_flag[0] = true)

	pause_menu.open()
	if not pause_menu.pause_panel.visible:
		_fail("PausePanel phải hiển thị khi open()!")
		return

	pause_menu.resume_btn.pressed.emit()
	if not resume_flag[0]:
		_fail("resume_btn không phát resume_requested!")
		return

	pause_menu.save_btn.pressed.emit()
	if not save_flag[0]:
		_fail("save_btn không phát save_requested!")
		return

	pause_menu.quit_btn.pressed.emit()
	if not quit_flag[0]:
		_fail("quit_btn không phát quit_requested!")
		return

	pause_menu.open_settings()
	if not settings_open_flag[0] or not pause_menu.settings_panel.visible:
		_fail("open_settings không mở settings_panel hoặc không emit signal!")
		return

	pause_menu.close_settings()
	if not settings_close_flag[0] or pause_menu.settings_panel.visible:
		_fail("close_settings không đóng settings_panel hoặc không emit signal!")
		return

	pause_menu.close()
	if pause_menu.is_open():
		_fail("PauseMenu phải đóng khi close()!")
		return

	pause_menu.queue_free()
	await process_frame
	print("[PASS] 4. PauseMenu contract & signal routing OK")

func _test_sidebar_ui() -> void:
	var sidebar: Node = SidebarUIScene.instantiate()
	root.add_child(sidebar)
	await process_frame

	var closed_flag := [false]
	var tab_changed_idx := [-1]
	var char_sheet_flag := [false]
	var inv_flag := [false]
	var journal_flag := [false]
	var hybrid_flag := [false]

	sidebar.closed.connect(func(): closed_flag[0] = true)
	sidebar.tab_changed.connect(func(idx): tab_changed_idx[0] = idx)
	sidebar.character_sheet_requested.connect(func(): char_sheet_flag[0] = true)
	sidebar.inventory_requested.connect(func(): inv_flag[0] = true)
	sidebar.journal_requested.connect(func(): journal_flag[0] = true)
	sidebar.hybrid_controls_toggled.connect(func(): hybrid_flag[0] = true)

	sidebar.open(1)
	if not sidebar.visible or sidebar.current_tab != 1:
		_fail("open(1) phải mở sidebar và chuyển sang tab 1 (Quests)!")
		return

	sidebar.switch_tab(2)
	if sidebar.current_tab != 2 or tab_changed_idx[0] != 2:
		_fail("switch_tab(2) phải cập nhật current_tab và emit tab_changed!")
		return

	sidebar.open_sheet_btn.pressed.emit()
	if not char_sheet_flag[0]:
		_fail("open_sheet_btn không emit character_sheet_requested!")
		return

	sidebar.open_inv_btn.pressed.emit()
	if not inv_flag[0]:
		_fail("open_inv_btn không emit inventory_requested!")
		return

	sidebar.open_journal_btn.pressed.emit()
	if not journal_flag[0]:
		_fail("open_journal_btn không emit journal_requested!")
		return

	sidebar.sidebar_hybrid_controls_btn.pressed.emit()
	if not hybrid_flag[0]:
		_fail("sidebar_hybrid_controls_btn không emit hybrid_controls_toggled!")
		return

	sidebar.close_btn.pressed.emit()
	if not closed_flag[0] or sidebar.visible:
		_fail("close_btn không đóng sidebar hoặc không emit closed!")
		return

	sidebar.queue_free()
	await process_frame
	print("[PASS] 5. SidebarUI contract & tab/signal management OK")

func _test_game_ui_integration() -> void:
	var game_ui: Node = GameUIScene.instantiate()
	root.add_child(game_ui)
	await process_frame

	# Test that all extracted component properties are populated
	if game_ui.boss_hud_controller == null or game_ui.world_overlay_ui == null:
		_fail("GameUI không tìm thấy boss_hud_controller hoặc world_overlay_ui!")
		return
	if game_ui.end_screen_ui == null or game_ui.pause_menu_controller == null:
		_fail("GameUI không tìm thấy end_screen_ui hoặc pause_menu_controller!")
		return
	if game_ui.sidebar_ui == null:
		_fail("GameUI không tìm thấy sidebar_ui!")
		return

	# Test compatibility facades
	game_ui.show_notification("Tích hợp GameUI thành công")
	if not game_ui.notification_label.visible:
		_fail("game_ui.show_notification không hoạt động qua facade!")
		return

	game_ui.set_current_zone("noctis_forest")
	if not "Rừng" in game_ui.zone_label.text:
		_fail("game_ui.set_current_zone không hoạt động qua facade!")
		return

	game_ui.show_boss_hud()
	if not game_ui.boss_hud.visible:
		_fail("game_ui.show_boss_hud không hiển thị boss bar!")
		return
	game_ui.hide_boss_hud()
	if game_ui.boss_hud.visible:
		_fail("game_ui.hide_boss_hud không ẩn boss bar!")
		return

	# Test Pause & Sidebar open/close via GameUI
	game_ui.open_pause_menu()
	if not game_ui.is_pause_menu_open():
		_fail("open_pause_menu không mở pause menu!")
		return
	game_ui.close_pause_menu()
	if game_ui.is_pause_menu_open():
		_fail("close_pause_menu không đóng pause menu!")
		return

	game_ui.open_sidebar(0)
	if not game_ui.is_sidebar_open():
		_fail("open_sidebar không mở sidebar!")
		return
	game_ui.close_sidebar()
	if game_ui.is_sidebar_open():
		_fail("close_sidebar không đóng sidebar!")
		return

	game_ui.queue_free()
	await process_frame
	print("[PASS] 6. GameUI full integration & compatibility facade OK")

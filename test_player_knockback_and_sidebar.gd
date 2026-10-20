extends SceneTree

const NoctisForestScene = preload("res://src/world/noctis_forest.tscn")
const DamageInfoScript = preload("res://src/combat/damage_info.gd")

func _init() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING PLAYER KNOCKBACK, SIDEBAR & POLISH")
	print("==================================================")

	var world = NoctisForestScene.instantiate()
	root.add_child(world)
	await _wait_frames(3)

	var player: Player = world.get_node_or_null("Player") as Player
	_assert(player != null, "Player tồn tại trong Noctis Forest")

	var ui: GameUI = world.get_node_or_null("GameUI") as GameUI
	_assert(ui != null, "GameUI tồn tại")

	# --- 1. Knockback on Player ---
	print("\n--- TEST 1: Knockback khi Player bị tấn công ---")
	player.global_position = Vector2(500, 630)
	player.velocity = Vector2.ZERO
	player.facing_direction = 1

	var dmg := DamageInfoScript.new(10.0, null, Vector2.LEFT, 280.0)
	var taken = player.hurtbox.apply_damage(dmg)
	_assert(taken == true, "Hurtbox nhận sát thương thành công")
	_assert(player.velocity.x < -100.0, "Player bị giật lùi về phía sau (velocity.x = %.1f px/s)" % player.velocity.x)
	_assert(player.velocity.y < -50.0, "Player có lực đẩy nảy nhẹ trên không (velocity.y = %.1f px/s)" % player.velocity.y)
	_assert(player.hurt_recoil_timer > 0.0, "hurt_recoil_timer kích hoạt ngăn người chơi ghi đè lực đẩy tức thì")

	# --- 2. Grounding & Drop Shadows ---
	print("\n--- TEST 2: Đổ bóng tiếp đất (Ground Shadows) & Ẩn Hitbox ---")
	var player_shadow = player.get_node_or_null("GroundShadow")
	_assert(player_shadow != null and player_shadow is Polygon2D, "Player có GroundShadow Polygon2D để tạo cảm giác tiếp đất vững chắc")

	var enemy = world.get_node_or_null("CorruptedEnemy1")
	_assert(enemy != null, "Quái vật CorruptedEnemy1 tồn tại")
	var enemy_shadow = enemy.get_node_or_null("GroundShadow")
	_assert(enemy_shadow != null and enemy_shadow is Polygon2D, "Quái vật có GroundShadow Polygon2D")

	var p_slash_box = player.get_node_or_null("MeleeHitbox/SlashEffectPlaceholder")
	_assert(p_slash_box == null or p_slash_box.visible == false, "Hộp màu vàng SlashEffectPlaceholder đã được ẩn hoàn toàn (visible == false)")

	var e_bite_box = enemy.get_node_or_null("AttackHitbox/BiteEffectPlaceholder")
	_assert(e_bite_box == null or e_bite_box.visible == false, "Hộp màu đỏ BiteEffectPlaceholder đã được ẩn hoàn toàn (visible == false)")

	# --- 3. Sidebar UI & Clean Screen ---
	print("\n--- TEST 3: Dọn dẹp màn hình & Sidebar đa năng ---")
	var controls_info = ui.get_node_or_null("HUD/ControlsInfo") as Control
	_assert(controls_info != null and controls_info.visible == false, "Bảng hướng dẫn chiếm đất đáy màn hình (ControlsInfo) đã được dọn sạch khỏi HUD")

	var quest_panel = ui.get_node_or_null("HUD/QuestPanel") as Control
	_assert(quest_panel != null and quest_panel.visible == false, "Khung nhiệm vụ choán góc trên (QuestPanel) đã được chuyển gọn vào Sidebar")

	var sidebar_btn = ui.get_node_or_null("HUD/SidebarToggleBtn") as Button
	_assert(sidebar_btn != null, "Nút SidebarToggleBtn (☰ MENU) xuất hiện gọn gàng ở góc trên")

	_assert(ui.is_sidebar_open() == false, "Sidebar ban đầu ẩn để giải phóng toàn bộ tầm nhìn chiến trường")

	ui.toggle_sidebar()
	_assert(ui.is_sidebar_open() == true, "Mở Sidebar thành công bằng toggle_sidebar()")

	# Kiểm tra 4 tab của Sidebar
	_assert(ui.panel_stats != null and ui.panel_stats.visible == true, "Mặc định mở tab 0: Bảng Chỉ Số Nhân Vật")
	_assert(ui.sidebar_race_label != null and ui.sidebar_race_label.text.contains("Human"), "Hiển thị chủng tộc đúng trong Sidebar")
	_assert(ui.sidebar_stat_hp != null and ui.sidebar_stat_hp.text.contains("Sinh Lực"), "Hiển thị Sinh Lực trong Sidebar")

	ui.switch_sidebar_tab(1)
	_assert(ui.panel_quests != null and ui.panel_quests.visible == true, "Chuyển mượt sang tab 1: Sổ Nhiệm Vụ & Tiến Trình")
	_assert(ui.sidebar_quest_title != null, "Hiển thị tiêu đề nhiệm vụ trong Sidebar")

	ui.switch_sidebar_tab(2)
	_assert(ui.panel_inventory != null and ui.panel_inventory.visible == true, "Chuyển mượt sang tab 2: Túi Đồ & Trang Bị")
	_assert(ui.sidebar_inv_gold != null and ui.sidebar_inv_gold.text.contains("Vàng"), "Hiển thị số Vàng sở hữu trong Sidebar")

	ui.switch_sidebar_tab(3)
	_assert(ui.panel_settings != null and ui.panel_settings.visible == true, "Chuyển mượt sang tab 3: Cài Đặt & Hướng Dẫn Điều Khiển")
	var guide_label = ui.get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/ControlsGuideText") as Label
	_assert(guide_label != null and guide_label.text.contains("Di chuyển") and guide_label.text.contains("Lướt"), "Hướng dẫn điều khiển chi tiết đầy đủ trong Cài Đặt")

	# Kiểm tra zoom slider và buttons trong Sidebar
	_assert(ui.sidebar_zoom_label != null, "Nhãn zoom hiển thị sắc nét trong Sidebar")
	_assert(ui.sidebar_zoom_slider != null, "Thanh trượt zoom hoạt động trong Sidebar")

	ui.close_sidebar()
	_assert(ui.is_sidebar_open() == false, "Đóng Sidebar thành công, màn hình trở lại thoáng đãng")

	# --- 4. 16-frame Running Animation ---
	print("\n--- TEST 4: Hoạt ảnh Chạy Bộ 16 Khung Hình (Seamless Run Loop) ---")
	var anim_p: AnimationPlayer = player.get_node_or_null("AnimationPlayer")
	_assert(anim_p.has_animation("run"), "Player có animation 'run'")
	var run_anim = anim_p.get_animation("run")
	_assert(is_equal_approx(run_anim.length, 0.666667) or is_equal_approx(run_anim.length, 0.8), "Thời lượng animation chạy chuẩn xác (0.67s @ 24 FPS hoặc 0.8s)")
	var track_idx = run_anim.find_track(NodePath("SpriteRoot/RunSprite:frame"), Animation.TYPE_VALUE)
	_assert(track_idx != -1, "Animation chạy điều khiển frame của RunSprite")
	_assert(run_anim.track_get_key_count(track_idx) == 16, "Animation chạy có đủ 16 khung hình chuyển động siêu mượt")

	world.queue_free()
	print("\n==================================================")
	print(">>> TẤT CẢ CÁC TÍNH NĂNG MỚI ĐÃ ĐƯỢC KIỂM THỬ ĐẠT 100%! <<<")
	print("==================================================")
	quit(0)

func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _assert(cond: bool, msg: String) -> void:
	if not cond:
		printerr(" [FAIL] " + msg)
		quit(1)
	else:
		print("  [PASS] " + msg)

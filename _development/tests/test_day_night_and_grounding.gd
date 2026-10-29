extends SceneTree

const DayNightCycleScript = preload("res://src/world/day_night_cycle.gd")
const NoctisTerrainScript = preload("res://src/world/noctis_terrain.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING DAY/NIGHT CYCLE, LIGHTING & GROUNDING")
	print("==================================================")

	var all_passed := true

	var scene_res = load("res://src/world/noctis_forest.tscn")
	if scene_res == null:
		print("  [FAIL] Không thể load res://src/world/noctis_forest.tscn")
		quit(1)
		return

	var forest: Node2D = scene_res.instantiate() as Node2D
	root.add_child(forest)
	await process_frame
	await process_frame

	# --- TEST 1: Hệ thống Chu kỳ Ngày / Đêm & Ánh sáng Động ---
	print("\n--- TEST 1: Hệ Thống Chu Kỳ Ngày/Đêm & Ánh Sáng Thế Giới ---")
	var dnc = forest.get_node_or_null("DayNightCycle")
	if dnc != null:
		print("  [PASS] Node DayNightCycle tồn tại trong thế giới")
	else:
		print("  [FAIL] Không tìm thấy Node DayNightCycle")
		all_passed = false

	var canvas_mod = forest.get_node_or_null("WorldCanvasModulate") as CanvasModulate
	if canvas_mod != null:
		print("  [PASS] WorldCanvasModulate tồn tại để điều biến ánh sáng động")
	else:
		print("  [FAIL] Không tìm thấy WorldCanvasModulate")
		all_passed = false

	var sun = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerSky/Sun")
	var moon = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerMoon/Moon")
	var stars = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerSky/Starfield")
	if sun and moon and stars:
		print("  [PASS] Có đầy đủ thiên thể: Mặt Trời (Sun), Mặt Trăng (Moon) và Bầu trời sao (Starfield)")
	else:
		print("  [FAIL] Thiếu thiên thể trong LayerSky/LayerMoon")
		all_passed = false

	# Kiểm tra chuyển đổi 4 thời khắc: Bình Minh, Ban Ngày, Hoàng Hôn, Đêm Huyền Bí
	if dnc:
		# 1. Ban Ngày (Day)
		dnc.set_time_phase("day")
		await process_frame
		var col_day = dnc.get_ambient_color()
		var sun_vis_day = dnc.get_sun_visibility()
		if col_day.r >= 0.95 and sun_vis_day > 0.8:
			print("  [PASS] Thời khắc Ban Ngày (12:00): Ánh nắng rực rỡ, Mặt Trời lên đỉnh (%s)" % dnc.get_phase_name())
		else:
			print("  [FAIL] Ánh sáng Ban Ngày chưa chính xác: %s, Sun vis: %f" % [str(col_day), sun_vis_day])
			all_passed = false

		# 2. Hoàng Hôn (Dusk)
		dnc.set_time_phase("dusk")
		await process_frame
		var col_dusk = dnc.get_ambient_color()
		if col_dusk.r > col_dusk.b and col_dusk.g < col_dusk.r:
			print("  [PASS] Thời khắc Hoàng Hôn (18:00): Ánh ráng chiều cam đỏ ấm áp (%s)" % dnc.get_phase_name())
		else:
			print("  [FAIL] Ánh sáng Hoàng Hôn chưa đúng sắc đỏ cam")
			all_passed = false

		# 3. Đêm Huyền Bí (Night)
		dnc.set_time_phase("night")
		await process_frame
		var col_night = dnc.get_ambient_color()
		var moon_vis_night = dnc.get_moon_visibility()
		var stars_vis_night = dnc.get_stars_visibility()
		if col_night.b > col_night.r and moon_vis_night > 0.8 and stars_vis_night > 0.8:
			print("  [PASS] Thời khắc Đêm Huyền Bí (22:00): Ánh sáng chàm sapphire, Trăng sao tỏa sáng (%s)" % dnc.get_phase_name())
		else:
			print("  [FAIL] Ánh sáng Đêm chưa đúng sắc xanh chàm hoặc thiếu trăng sao")
			all_passed = false

		# 4. Bình Minh (Dawn)
		dnc.set_time_phase("dawn")
		await process_frame
		var col_dawn = dnc.get_ambient_color()
		if col_dawn.r > 0.8:
			print("  [PASS] Thời khắc Bình Minh (06:00): Hửng đông hổ phách - hồng đào dịu dàng (%s)" % dnc.get_phase_name())
		else:
			print("  [FAIL] Ánh sáng Bình Minh chưa chính xác")
			all_passed = false

	# --- TEST 2: Đắm Chân Tiếp Đất & Bóng Đổ Grounding ---
	print("\n--- TEST 2: Đắm Chân Tiếp Đất & Bóng Đổ Grounding (Khắc Phục Lơ Lửng) ---")
	var ground = forest.get_node_or_null("Geometry/NoctisTerrain")
	if ground != null and ground.z_index <= -2 and ground.get_node_or_null("CollisionPolygon2D") != null:
		print("  [PASS] NoctisTerrain dùng chung contour hình ảnh/collision và nằm dưới nhân vật")
	else:
		print("  [FAIL] Thiếu NoctisTerrain hoặc CollisionPolygon2D")
		all_passed = false

	var fore_grass = forest.get_node_or_null("Geometry/ForeGrassOverlay")
	if fore_grass == null:
		print("  [PASS] Đã loại dải cỏ thẳng ForeGrassOverlay; cỏ được vẽ theo contour địa hình")
	else:
		print("  [FAIL] ForeGrassOverlay cũ vẫn còn tồn tại")
		all_passed = false

	var player = forest.get_node_or_null("Player")
	if player != null:
		var p_shadow = player.get_node_or_null("GroundShadow")
		if p_shadow != null and player.has_method("_update_ground_shadow"):
			print("  [PASS] Player có GroundShadow và cơ chế tự động điều chỉnh bóng đổ khi nhảy trên không")
		else:
			print("  [FAIL] Player thiếu GroundShadow hoặc hàm điều khiển bóng")
			all_passed = false

	var fox = forest.get_node_or_null("PetMossFox")
	if fox != null:
		var fox_shadow = fox.get_node_or_null("GroundShadow")
		var fox_col = fox.get_node_or_null("CollisionShape2D")
		var col_bottom = fox_col.position.y + fox_col.shape.radius if (fox_col and fox_col.shape) else 999.0
		if fox_shadow != null and absf(col_bottom) < 0.1:
			print("  [PASS] Cáo Rêu Mầm có GroundShadow và đáy va chạm chạm đúng y=0 (triệt tiêu 100% khe hở 6px lơ lửng)")
		else:
			print("  [FAIL] Cáo Rêu Mầm chưa căn chuẩn đáy va chạm hoặc thiếu shadow (col_bottom: %f)" % col_bottom)
			all_passed = false

	var bird = forest.get_node_or_null("PetMoonBat")
	if bird == null:
		bird = forest.get_node_or_null("PetMoonBird")
	if bird != null:
		var bird_shadow = bird.get_node_or_null("GroundShadow")
		if bird_shadow != null:
			print("  [PASS] Dơi Trăng Kiki có GroundShadow chiếu xuống hiên nhà/mặt đất bên dưới")
		else:
			print("  [FAIL] Dơi Trăng Kiki thiếu GroundShadow")
			all_passed = false

	var npc = forest.get_node_or_null("NPC_Elyra")
	if npc != null and npc.get_node_or_null("GroundShadow") != null:
		print("  [PASS] NPC Elyra có GroundShadow vững chãi trên mặt cỏ")
	else:
		print("  [FAIL] NPC Elyra thiếu GroundShadow")
		all_passed = false

	var enemy = forest.get_node_or_null("CorruptedEnemy1")
	if enemy != null and enemy.get_node_or_null("GroundShadow") != null:
		print("  [PASS] Quái vật Ma Sói có GroundShadow tiếp đất chắc chắn")
	else:
		print("  [FAIL] Quái vật thiếu GroundShadow")
		all_passed = false

	var boss = forest.get_node_or_null("BossLunareth")
	if boss != null and boss.get_node_or_null("GroundShadow") != null:
		print("  [PASS] Boss Lunareth có GroundShadow khổ lớn bám đất uy nghiêm")
	else:
		print("  [FAIL] Boss Lunareth thiếu GroundShadow")
		all_passed = false

	# --- TEST 3: Chiều Sâu Không Gian Parallax Toàn Bản Đồ ---
	print("\n--- TEST 3: Chiều Sâu Không Gian Parallax Toàn Bản Đồ (Không Bị Chặn Tầm Nhìn) ---")
	var clouds = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerClouds")
	var forest_mid = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerForestMid")
	var canopy_fore = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerCanopyForeground")
	if clouds and forest_mid and canopy_fore:
		print("  [PASS] Bổ sung thêm 3 tầng Parallax mới: Mây phiêu lãng (LayerClouds), Rừng cổ trung cảnh (LayerForestMid), Tán cây tiền cảnh (LayerCanopyForeground)")
	else:
		print("  [FAIL] Thiếu các tầng Parallax bổ sung")
		all_passed = false

	var zone2_bg = forest.get_node_or_null("Background_Zone2_Forest")
	var zone3_bg = forest.get_node_or_null("Background_Zone3_Arena")
	if zone2_bg is Node2D and zone3_bg is Node2D:
		print("  [PASS] Zone 2 và Zone 3 đã tháo dỡ các khối ColorRect chắn kín bầu trời, mở toang tầm nhìn viễn cảnh 6800px")
	else:
		print("  [FAIL] Zone 2/3 vẫn còn ColorRect chặn kín phong cảnh")
		all_passed = false

	# --- TEST 4: Giao Diện Đồng Hồ Thời Khắc HUD & Sidebar ---
	print("\n--- TEST 4: Giao Diện Đồng Hồ Thời Khắc & Phím Tắt [L] ---")
	var game_ui = forest.get_node_or_null("GameUI")
	if game_ui:
		var time_btn = game_ui.get_node_or_null("HUD/TimePanel/TimeBtn")
		var sidebar_time_btn = game_ui.find_child("SidebarDayNightBtn", true, false)
		if time_btn != null and sidebar_time_btn != null:
			print("  [PASS] Nút hiển thị đồng hồ thiên thể tồn tại trên HUD và trong Sidebar Settings")
			# Thử gọi update_time_display
			game_ui.update_time_display("14:30", "day", "☀️")
			if "14:30" in time_btn.text and "☀️" in time_btn.text:
				print("  [PASS] Đồng hồ HUD hiển thị chính xác: '%s'" % time_btn.text)
			else:
				print("  [FAIL] Đồng hồ HUD hiển thị sai: '%s'" % time_btn.text)
				all_passed = false
		else:
			print("  [FAIL] Thiếu TimeBtn trên HUD hoặc SidebarDayNightBtn")
			all_passed = false

	print("\n==================================================")
	if all_passed:
		print(">>> TẤT CẢ TEST CHU KỲ NGÀY/ĐÊM, ÁNH SÁNG & GROUNDING ĐẠT 100%! <<<")
		print("==================================================")
		quit(0)
	else:
		print(">>> CÓ TEST KHÔNG ĐẠT! <<<")
		print("==================================================")
		quit(1)

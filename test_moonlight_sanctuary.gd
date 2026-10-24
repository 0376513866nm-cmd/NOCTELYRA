extends SceneTree

const DistantBirdsScript = preload("res://src/world/distant_birds.gd")
const MoonlightCottageScript = preload("res://src/world/moonlight_cottage.gd")
const PetMossFoxScript = preload("res://src/actors/pets/pet_moss_fox.gd")
const PetMoonBatScript = preload("res://src/actors/pets/pet_moon_bat.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print(" [NOCTELYRA] TESTING MOONLIGHT SANCTUARY, PETS & PARALLAX")
	print("==================================================")

	var all_passed := true

	var scene_res = load("res://src/world/noctis_forest.tscn")
	if scene_res == null:
		print("  [FAIL] Không thể load noctis_forest.tscn")
		quit(1)
		return

	var forest: Node2D = scene_res.instantiate() as Node2D
	root.add_child(forest)
	await process_frame
	await process_frame

	# --- TEST 1: Kiểm Tra Parallax Đa Tầng ---
	print("\n--- TEST 1: Parallax Đa Tầng & Đàn Chim Viễn Xứ ---")
	var parallax_bg = forest.get_node_or_null("BambooGrove/ParallaxBackground") as ParallaxBackground
	if parallax_bg != null:
		print("  [PASS] ParallaxBackground tồn tại thay thế cho Backdrop tĩnh cũ")
	else:
		print("  [FAIL] Không tìm thấy ParallaxBackground")
		all_passed = false

	var layer_sky = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerSky") as ParallaxLayer
	var layer_moon = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerMoon") as ParallaxLayer
	var layer_birds = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerBirds") as ParallaxLayer
	var layer_mountains = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerMountains") as ParallaxLayer
	var layer_forest_far = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerForestFar") as ParallaxLayer

	if layer_sky and layer_moon and layer_birds and layer_mountains and layer_forest_far:
		print("  [PASS] Có đủ 5 tầng Parallax (Bầu trời, Trăng sao & Tháp cổ, Đàn chim, Dãy núi, Tán rừng)")
	else:
		print("  [FAIL] Thiếu tầng Parallax")
		all_passed = false

	var birds = forest.get_node_or_null("BambooGrove/ParallaxBackground/LayerBirds/DistantBirds")
	if birds != null:
		print("  [PASS] Node DistantBirds tồn tại và sẵn sàng tạo hiệu ứng đàn chim đêm")
	else:
		print("  [FAIL] Không tìm thấy DistantBirds")
		all_passed = false

	# --- TEST 2: Ngôi Nhà Đèn Nguyệt & Vùng Hồi Phục (Sanctuary) ---
	print("\n--- TEST 2: Ngôi Nhà Đèn Nguyệt & Vùng Hồi Phục ---")
	var cottage = forest.get_node_or_null("MoonlightCottage")
	if cottage != null:
		print("  [PASS] MoonlightCottage tồn tại ở đầu map (x = %.0f)" % cottage.position.x)
	else:
		print("  [FAIL] Không tìm thấy MoonlightCottage")
		all_passed = false

	var player = forest.get_node_or_null("Player") as Player
	if player != null and cottage != null:
		# Giảm máu và mana để kiểm tra cơ chế hồi phục của nhà
		player.health_component.current_health = 50.0
		player.health_component.current_mana = 10.0
		# Cho chạy 1 giây
		cottage._player_inside = player
		cottage._process(1.0)
		if player.health_component.current_health > 50.0 and player.health_component.current_mana > 10.0:
			print("  [PASS] Vùng SanctuaryArea tự động hồi phục HP & MP cho Player (HP: %.1f, MP: %.1f)" % [player.health_component.current_health, player.health_component.current_mana])
		else:
			print("  [FAIL] Không hồi phục HP/MP trong vùng Sanctuary")
			all_passed = false

	# --- TEST 3: Thú Cưng Cáo Rêu - Mầm & Chim Trăng - Lumi ---
	print("\n--- TEST 3: Thú Cưng Linh Thú (Sẵn Sàng Cho AI LLM) ---")
	var fox = forest.get_node_or_null("PetMossFox")
	if fox != null:
		print("  [PASS] Thú cưng 'Cáo Rêu - Mầm' tồn tại ở sân nhà (x = %.0f)" % fox.position.x)
		fox.trigger_interaction()
		if fox.speech_bubble.visible and fox.speech_label.text.length() > 0:
			print("  [PASS] Tương tác [E] với Mầm thành công: " + fox.speech_label.text)
		else:
			print("  [FAIL] Tương tác với Mầm thất bại")
			all_passed = false
	else:
		print("  [FAIL] Không tìm thấy PetMossFox")
		all_passed = false

	var bat = forest.get_node_or_null("PetMoonBat")
	if bat == null:
		bat = forest.get_node_or_null("PetMoonBird")
	if bat != null:
		print("  [PASS] Thú cưng 'Dơi Trăng - Kiki' tồn tại ở hiên nhà (x = %.0f)" % bat.position.x)
		bat.trigger_interaction()
		if bat.speech_bubble.visible and bat.speech_label.text.length() > 0:
			print("  [PASS] Tương tác [E] với Kiki thành công: " + bat.speech_label.text)
		else:
			print("  [FAIL] Tương tác với Kiki thất bại")
			all_passed = false
	else:
		print("  [FAIL] Không tìm thấy PetMoonBat")
		all_passed = false

	# --- TEST 4: Khu Vườn Thảo Dược, Giếng Đá & Dọn Sạch Chữ Debug ---
	print("\n--- TEST 4: Khu Vườn, Giếng Nước & Làm Sạch Tầm Nhìn ---")
	var garden = forest.get_node_or_null("SanctuaryGarden")
	if garden != null:
		print("  [PASS] SanctuaryGarden tồn tại (Giếng đá, Ao phát quang, Bụi thảo dược, Hạt lá rơi, Đom đóm)")
	else:
		print("  [FAIL] Không tìm thấy SanctuaryGarden")
		all_passed = false

	var sign_board = forest.get_node_or_null("SignBoard")
	var border_marker = forest.get_node_or_null("BorderMarker")
	var arena_marker = forest.get_node_or_null("ArenaMarker")
	if sign_board == null and border_marker == null and arena_marker == null:
		print("  [PASS] Toàn bộ các nhãn chữ debug che phong cảnh đã được gỡ bỏ hoàn toàn")
	else:
		print("  [FAIL] Vẫn còn nhãn chữ debug che cảnh")
		all_passed = false

	forest.queue_free()
	await process_frame

	print("\n==================================================")
	if all_passed:
		print(">>> TẤT CẢ TEST TỔ ẤM ĐÈN NGUYỆT & PARALLAX ĐẠT 100%! <<<")
	else:
		print(">>> CÓ TEST THẤT BẠI! <<<")
	print("==================================================")

	quit(0 if all_passed else 1)

extends SceneTree

# test_m3_1_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M3.1:
# World Item State, Atomic Non-destructive Save, Test Data Isolation & Deep Validation.

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m3_1_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M3.1] INTEGRATION TEST SUITE STARTING ")
	print("==================================================")
	call_deferred("_run_suite")

func _assert(condition: bool, test_name: String, details: String = "") -> void:
	tests_run += 1
	if condition:
		print("  [PASS] %s" % test_name)
	else:
		failures += 1
		print("  [FAIL] %s - Details: %s" % [test_name, details])

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _run_suite() -> void:
	ItemDatabase.initialize()

	# Cấu hình đường dẫn test riêng biệt
	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

	# Chuẩn bị một file save thật giả định để kiểm tra tính cách ly (Test 9)
	var real_dummy_content := "{\"save_version\":\"1.0.0\",\"real_player_tag\":\"REAL_SAVE_DATA_DO_NOT_TOUCH\"}"
	var real_file := FileAccess.open(REAL_SAVE_PATH, FileAccess.WRITE)
	if real_file:
		real_file.store_string(real_dummy_content)
		real_file.close()

	var world_scene: PackedScene = load("res://src/world/noctis_forest.tscn")
	if not world_scene:
		print("FATAL: Could not load noctis_forest.tscn")
		quit(1)
		return

	var world: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world)
	current_scene = world

	await _wait_seconds(0.3)

	var player: Player = world.get_node_or_null("Player") as Player
	var ui: GameUI = world.get_node_or_null("GameUI") as GameUI
	var quest_mgr: QuestManager = world.get_node_or_null("QuestManager") as QuestManager
	var inv: InventoryComponent = player.inventory_component if player else null
	var eq: EquipmentComponent = player.equipment_component if player else null

	print("\n--- TEST 1: Nhặt vật phẩm đặt sẵn -> Save -> Tạo lại World -> Load -> Không xuất hiện lần 2 ---")
	inv._initialize_slots()
	var sword_pickup = world.get_node_or_null("TestPickup_Sword") as ItemPickup
	_assert(sword_pickup != null and not sword_pickup.pickup_id.is_empty(), "Vật phẩm Kiếm đặt sẵn có pickup_id ổn định ('%s')" % (sword_pickup.pickup_id if sword_pickup else ""))

	# Nhặt kiếm và trang bị
	sword_pickup._on_body_entered(player)
	_assert(inv.has_item("moonsteel_sword"), "Player đã nhặt được Kiếm Ánh Trăng")
	eq.equip("moonsteel_sword")
	_assert(player.melee_hitbox.damage == 35.0, "Đã trang bị Kiếm, sát thương đạt 35")
	_assert("pickup_village_sword_1" in world.collected_pickup_ids, "pickup_village_sword_1 đã được ghi vào collected_pickup_ids của world")

	# Lưu game
	var s1 := SaveManager.save_game(world)
	_assert(s1 == true, "Lưu game thành công vào test save")

	# Giải phóng world cũ và khởi tạo world hoàn toàn mới từ đĩa (giả lập thoát game và Continue)
	world.queue_free()
	await process_frame

	var world2: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world2)
	current_scene = world2
	await _wait_seconds(0.2)

	# Nạp lại bản lưu
	var l1 := SaveManager.load_game(world2)
	_assert(l1 == true, "Nạp lại bản lưu vào World mới thành công")
	var p2: Player = world2.get_node_or_null("Player") as Player
	_assert(p2.equipment_component.get_equipped("weapon") == "moonsteel_sword", "Player vẫn giữ nguyên trang bị Kiếm Ánh Trăng")
	_assert(p2.melee_hitbox.damage == 35.0, "Sát thương vẫn duy trì 35 sau khi tải")

	var check_sword_recreated = world2.get_node_or_null("TestPickup_Sword")
	_assert(check_sword_recreated == null or check_sword_recreated.is_queued_for_deletion(), "Kiếm đặt sẵn tại làng ĐÃ BỊ LOẠI BỎ, không xuất hiện lần hai!")

	print("\n--- TEST 2: Quái chết và rơi đồ -> Chưa nhặt -> Save -> Load -> Vật phẩm vẫn còn ---")
	# Tạo một dynamic pickup rơi ra từ quái tại tọa độ (2500, 630)
	var pickup_scene: PackedScene = load("res://src/loot/item_pickup.tscn")
	var dropped_shard := pickup_scene.instantiate() as ItemPickup
	dropped_shard.item_id = "mana_shard"
	dropped_shard.amount = 3
	dropped_shard.is_dynamic = true
	dropped_shard.pickup_id = "drop_test_shard_99"
	dropped_shard.global_position = Vector2(2500, 630)
	world2.add_child(dropped_shard)
	await process_frame

	var dropped_data := world2.get_dropped_pickups_data()
	_assert(dropped_data.size() >= 1, "Thế giới ghi nhận ít nhất 1 vật phẩm rơi động chưa nhặt (thực tế: %d)" % dropped_data.size())

	SaveManager.save_game(world2)

	# Giả lập thoát game và tải lại
	world2.queue_free()
	await process_frame

	var world3: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world3)
	current_scene = world3
	await _wait_seconds(0.2)

	SaveManager.load_game(world3)
	await process_frame

	var dyn_pickups_world3 = world3.get_tree().get_nodes_in_group("dynamic_pickups")
	var found_shard := false
	for p in dyn_pickups_world3:
		if p is ItemPickup and p.item_id == "mana_shard" and p.amount == 3:
			if abs(p.global_position.x - 2500) < 5.0:
				found_shard = true
				break
	_assert(found_shard == true, "Vật phẩm rơi từ quái chưa nhặt được khôi phục chính xác tại tọa độ (2500, 630)")

	print("\n--- TEST 3: Nhặt đồ rơi -> Save -> Load -> Không bị nhân bản ---")
	var p3: Player = world3.get_node_or_null("Player") as Player
	var inv3: InventoryComponent = p3.inventory_component
	var count_before := inv3.get_item_count("mana_shard")

	# Tìm và nhặt mảnh mana đó
	for p in world3.get_tree().get_nodes_in_group("dynamic_pickups"):
		if p is ItemPickup and p.item_id == "mana_shard" and p.amount == 3:
			p._on_body_entered(p3)
			break

	_assert(inv3.get_item_count("mana_shard") == count_before + 3, "Đã nhặt 3 mana_shard vào túi")

	# Lưu và tải lại
	SaveManager.save_game(world3)
	world3.queue_free()
	await process_frame

	var world4: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world4)
	current_scene = world4
	await _wait_seconds(0.2)

	SaveManager.load_game(world4)
	var p4: Player = world4.get_node_or_null("Player") as Player
	_assert(p4.inventory_component.get_item_count("mana_shard") == count_before + 3, "Túi đồ giữ đúng số lượng mana_shard")

	# Kiểm tra trên đất không còn mảnh mana_shard x3 đó nữa
	var duplicated_shard := false
	for p in world4.get_tree().get_nodes_in_group("dynamic_pickups"):
		if p is ItemPickup and p.item_id == "mana_shard" and p.amount == 3:
			duplicated_shard = true
	_assert(duplicated_shard == false, "Vật phẩm rơi đã nhặt KHÔNG bị nhân bản trên mặt đất sau khi Load!")

	print("\n--- TEST 4: Inventory đầy -> Vật phẩm không bị mất trên đất ---")
	var inv4 := p4.inventory_component
	for i in range(inv4.max_slots):
		inv4.slots[i].item_id = "health_potion"
		inv4.slots[i].amount = 20

	var test_amulet_drop := pickup_scene.instantiate() as ItemPickup
	test_amulet_drop.item_id = "moon_amulet"
	test_amulet_drop.amount = 1
	test_amulet_drop.is_dynamic = true
	test_amulet_drop.global_position = p4.global_position
	world4.add_child(test_amulet_drop)
	await process_frame

	test_amulet_drop._on_body_entered(p4)
	_assert(test_amulet_drop.is_picked_up == false, "Túi đầy 16/16: Pickup không bị nuốt mất")
	_assert(is_instance_valid(test_amulet_drop), "Vật phẩm vẫn nằm nguyên vẹn trên mặt đất")
	test_amulet_drop.queue_free()

	print("\n--- TEST 5: Save lỗi -> Giữ nguyên bản lưu trước đó (Atomic Safety) ---")
	# Tạo một bản lưu hợp lệ trước
	SaveManager.save_game(world4)
	var valid_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	_assert(not valid_text.is_empty(), "Đã có bản lưu hợp lệ hiện hữu")

	# Giả lập tình huống lỗi ghi: Lưu vào đối tượng null
	var fail_res := SaveManager.save_game(null)
	_assert(fail_res == false, "Hàm save_game trả về false khi gặp lỗi dữ liệu đầu vào")
	var current_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	_assert(current_text == valid_text, "Bản lưu hợp lệ trước đó vẫn nguyên vẹn 100%, không bị xóa hay ghi đè hỏng")

	print("\n--- TEST 6: JSON sai cấu trúc -> Continue không crash & Validate an toàn ---")
	# Ghi dữ liệu JSON hợp lệ về cú pháp nhưng sai kiểu dữ liệu và thiếu trường
	var corrupt_types_data = {
		"save_version": "1.0.0",
		"player": {
			"position_x": "INVALID_STRING_COORDINATE", # Sai kiểu
			"position_y": 99999999.0, # Tọa độ vượt biên
			"current_health": -50.0, # Máu âm
			"current_mana": 9999.0 # Mana tràn
		},
		"gold": -500, # Vàng âm
		"inventory": "THIS_SHOULD_BE_AN_ARRAY", # Sai kiểu
		"equipment": {
			"weapon": "NON_EXISTENT_SWORD_XYZ", # ID không tồn tại
			"accessory": "health_potion" # Sai loại trang bị
		},
		"quest": {
			"state": 99, # Trạng thái enum không hợp lệ
			"current_amount": -10
		}
	}
	var f_corrupt := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f_corrupt.store_string(JSON.stringify(corrupt_types_data))
	f_corrupt.close()

	var load_corrupt_res := SaveManager.load_game(world4)
	_assert(load_corrupt_res == true, "Hàm load_game xử lý an toàn không crash khi gặp kiểu dữ liệu sai")
	_assert(p4.health_component.current_health >= 0.0 and p4.health_component.current_health <= p4.health_component.max_health, "HP được clamp về khoảng an toàn (0 - 100)")
	_assert(p4.health_component.current_mana <= p4.health_component.max_mana, "MP được clamp không vượt quá Max MP")
	_assert(p4.global_position.x >= 50.0 and p4.global_position.x <= 4300.0, "Tọa độ Player được clamp trong giới hạn bản đồ hợp lệ")
	_assert(world4.quest_manager.gold >= 0, "Vàng được clamp >= 0, không bị âm")
	_assert(p4.equipment_component.get_equipped("weapon") == "", "Vũ khí không tồn tại tự động bị loại bỏ")
	_assert(p4.equipment_component.get_equipped("accessory") == "", "Trang bị sai loại tự động bị loại bỏ")

	print("\n--- TEST 7: Nhiệm vụ 2/3 -> Save -> Thoát World -> Continue -> Giữ đúng tiến độ ---")
	world4.quest_manager.current_quest.current_state = QuestData.State.ACTIVE
	world4.quest_manager.current_quest.current_amount = 2
	world4.quest_manager.gold = 30
	SaveManager.save_game(world4)

	world4.queue_free()
	await process_frame

	var world5: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world5)
	current_scene = world5
	await _wait_seconds(0.2)

	SaveManager.load_game(world5)
	_assert(world5.quest_manager.current_quest.current_state == QuestData.State.ACTIVE, "Nhiệm vụ vẫn ở trạng thái ACTIVE")
	_assert(world5.quest_manager.current_quest.current_amount == 2, "Tiến độ nhiệm vụ giữ chính xác 2/3")
	_assert(world5.quest_manager.gold == 30, "Số vàng giữ đúng 30 G")

	print("\n--- TEST 8: Quest COMPLETED -> Continue -> Không nhận lại 50 vàng ---")
	world5.quest_manager.current_quest.current_state = QuestData.State.READY_TO_TURN_IN
	world5.quest_manager.complete_quest(world5.player.health_component) # +50 G -> 80 G
	_assert(world5.quest_manager.current_quest.current_state == QuestData.State.COMPLETED, "Nhiệm vụ đã COMPLETED")
	_assert(world5.quest_manager.gold == 80, "Nhận thưởng 50 Vàng lần đầu (30 + 50 = 80 G)")
	SaveManager.save_game(world5)

	# Tải lại
	SaveManager.load_game(world5)
	_assert(world5.quest_manager.current_quest.current_state == QuestData.State.COMPLETED, "Nhiệm vụ phục hồi trạng thái COMPLETED")
	var try_complete_again := world5.quest_manager.complete_quest(world5.player.health_component)
	_assert(try_complete_again == false, "complete_quest từ chối trả thưởng lần 2")
	_assert(world5.quest_manager.gold == 80, "Vàng vẫn giữ nguyên đúng 80 G, không nhận thêm thưởng lặp lại")

	print("\n--- TEST 9: Cách ly dữ liệu kiểm thử -> File save thật không bị ảnh hưởng ---")
	_assert(FileAccess.file_exists(REAL_SAVE_PATH), "File save thật vẫn tồn tại")
	var real_content_after := FileAccess.get_file_as_string(REAL_SAVE_PATH)
	_assert(real_content_after == real_dummy_content, "Nội dung file save thật hoàn toàn KHÔNG BỊ THAY ĐỔI hay ghi đè trong suốt bài test!")

	# Dọn dẹp an toàn file test và file giả định
	SaveManager.delete_save()
	if FileAccess.file_exists(REAL_SAVE_PATH):
		DirAccess.remove_absolute(REAL_SAVE_PATH)
	SaveManager.custom_save_path = ""

	print("\n--- TEST 10: Kiểm tra hồi quy các chức năng cốt lõi M0-M2.1 ---")
	_assert(world5.npc_elyra.collision_layer == 0, "NPC Elyra collision_layer = 0 (Player xuyên người mượt mà)")
	_assert(world5.player.movement_data.max_jumps == 2, "Hệ thống nhảy đôi M0 hoạt động")
	_assert(world5.pause_controller != null, "PauseController hoạt động")
	world5.pause_controller.pause()
	_assert(world5.get_tree().paused == true, "Pause game thành công")
	world5.pause_controller.resume()
	_assert(world5.get_tree().paused == false, "Resume game thành công")

	print("\n==================================================")
	print(" [NOCTELYRA M3.1] KẾT QUẢ KIỂM THỬ TỔNG HỢP:")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL 10 M3.1 REQUIREMENT CATEGORIES PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

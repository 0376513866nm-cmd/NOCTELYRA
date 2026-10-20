extends SceneTree

# test_m3_flow.gd
# Automated integration test suite for NOCTELYRA Milestone M3:
# Inventory, Equipment & Save System.

var failures: int = 0
var tests_run: int = 0

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M3] INTEGRATION TEST SUITE STARTING   ")
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
	# Khởi tạo ItemDatabase
	ItemDatabase.initialize()

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

	_assert(player != null, "Player khởi tạo thành công")
	_assert(inv != null, "InventoryComponent gắn vào Player thành công")
	_assert(eq != null, "EquipmentComponent gắn vào Player thành công")
	_assert(ui != null and ui.inventory_ui != null, "InventoryUI tích hợp trong GameUI thành công")

	print("\n--- TEST 1: Thêm vật phẩm vào Inventory ---")
	inv._initialize_slots()
	var rem1 := inv.add_item("mana_shard", 5)
	_assert(rem1 == 0, "add_item thêm đủ 5 mana_shard (không thừa)")
	_assert(inv.get_item_count("mana_shard") == 5, "Tổng số lượng mana_shard trong túi là 5")
	_assert(inv.get_slot(0).item_id == "mana_shard" and inv.get_slot(0).amount == 5, "Ô số 0 lưu đúng ID và số lượng 5")

	print("\n--- TEST 2: Stack vật phẩm đúng số lượng ---")
	# Thêm 90 nữa vào ô 0 (đang có 5) -> thành 95
	inv.add_item("mana_shard", 90)
	_assert(inv.get_slot(0).amount == 95, "Ô 0 cộng dồn thành 95")
	# Thêm 10 nữa: Ô 0 đầy 99 (max_stack), 6 dư chuyển sang ô 1
	var rem2 := inv.add_item("mana_shard", 10)
	_assert(rem2 == 0, "Thêm 10 mana_shard thành công")
	_assert(inv.get_slot(0).amount == 99, "Ô 0 đạt giới hạn max_stack 99")
	_assert(inv.get_slot(1).item_id == "mana_shard" and inv.get_slot(1).amount == 6, "Ô 1 tự động nhận 6 phần tử tràn stack")
	_assert(inv.get_item_count("mana_shard") == 105, "Tổng số mana_shard trên 2 ô là 105")

	print("\n--- TEST 3: Inventory đầy thì không làm mất vật phẩm trên đất ---")
	# Lấp đầy 14 ô còn lại
	for i in range(2, inv.max_slots):
		inv.slots[i].item_id = "health_potion"
		inv.slots[i].amount = 20
	_assert(inv.can_add_item("moonsteel_sword", 1) == false, "Kiểm tra can_add_item trả về false khi túi đầy 16/16")

	# Sinh một ItemPickup dưới đất ngay vị trí Player
	var pickup_scene: PackedScene = load("res://src/loot/item_pickup.tscn")
	var pickup1 := pickup_scene.instantiate() as ItemPickup
	pickup1.item_id = "moonsteel_sword"
	pickup1.amount = 1
	pickup1.global_position = player.global_position
	world.add_child(pickup1)
	await process_frame

	# Player bước vào vùng nhặt
	pickup1._on_body_entered(player)
	_assert(pickup1.is_picked_up == false, "Pickup KHÔNG bị nhặt khi túi đồ đầy")
	_assert(is_instance_valid(pickup1), "Pickup vẫn tồn tại nguyên vẹn trên mặt đất, không bị mất")
	_assert(inv.has_item("moonsteel_sword") == false, "Túi đồ không có kiếm vì không nhặt được")

	print("\n--- TEST 4: Nhặt một Pickup không bị cộng hai lần ---")
	# Dọn trống 1 ô trong túi
	inv.slots[15].item_id = ""
	inv.slots[15].amount = 0
	_assert(inv.can_add_item("moonsteel_sword", 1) == true, "Đã có 1 ô trống, có thể nhặt kiếm")

	# Nhặt pickup1 lần 1
	pickup1._on_body_entered(player)
	_assert(pickup1.is_picked_up == true, "Pickup1 đã được nhặt thành công")
	_assert(inv.get_item_count("moonsteel_sword") == 1, "Túi đồ nhận đúng 1 kiếm")

	# Thử kích hoạt nhặt lại lần 2 trên cùng pickup
	pickup1._on_body_entered(player)
	_assert(inv.get_item_count("moonsteel_sword") == 1, "Cơ chế chống nhặt trùng: Không bị cộng lần thứ 2")
	if is_instance_valid(pickup1):
		pickup1.queue_free()

	print("\n--- TEST 5: Sử dụng bình máu hồi đúng 30 HP và giảm 1 bình ---")
	# Chuẩn bị ô bình máu
	inv._initialize_slots()
	inv.add_item("health_potion", 3)
	player.health_component.current_health = 40.0 # Hao hụt còn 40 HP
	_assert(player.health_component.current_health == 40.0, "HP ban đầu là 40/100")

	var used_success := inv.use_item_at(0, player)
	_assert(used_success == true, "Sử dụng bình máu thành công")
	_assert(player.health_component.current_health == 70.0, "HP hồi đúng 30 đơn vị (40 -> 70)")
	_assert(inv.get_item_count("health_potion") == 2, "Số lượng bình giảm từ 3 xuống 2")

	# Uống tiếp khi gần đầy máu (70 + 30 = 100 max)
	inv.use_item_at(0, player)
	_assert(player.health_component.current_health == 100.0, "HP hồi đầy 100 (không vượt Max HP)")

	# Thử sử dụng bình máu khi Player đã chết (State DEAD)
	player.health_component.current_health = 0.0
	var dead_use := inv.use_item_at(0, player)
	_assert(dead_use == false, "Không thể sử dụng bình máu khi Player đã chết (HP = 0)")
	_assert(inv.get_item_count("health_potion") == 1, "Bình máu không bị trừ khi dùng thất bại")
	player.respawn()

	print("\n--- TEST 6: Trang bị kiếm tăng sát thương từ 25 lên 35 ---")
	_assert(player.melee_hitbox.damage == 25.0, "Sát thương cơ bản ban đầu là 25")
	var prev_w := eq.equip("moonsteel_sword")
	_assert(prev_w == "", "Trước đó không có vũ khí")
	_assert(eq.get_equipped("weapon") == "moonsteel_sword", "Đã trang bị Kiếm Ánh Trăng")
	_assert(player.melee_hitbox.damage == 35.0, "Sát thương tăng chính xác lên 35 (25 + 10)")

	print("\n--- TEST 7: Tháo kiếm trả sát thương về 25 ---")
	var unequipped_w := eq.unequip("weapon")
	_assert(unequipped_w == "moonsteel_sword", "Tháo ra đúng Kiếm Ánh Trăng")
	_assert(eq.get_equipped("weapon") == "", "Ô vũ khí hiện đang trống")
	_assert(player.melee_hitbox.damage == 25.0, "Sát thương được hoàn trả chính xác về 25")

	print("\n--- TEST 8: Trang bị/tháo bùa thay đổi Max MP đúng 20 ---")
	var base_mp: float = player.health_component.max_mana
	_assert(base_mp == 60.0, "Max MP cơ bản ban đầu là 60")
	eq.equip("moon_amulet")
	_assert(eq.get_equipped("accessory") == "moon_amulet", "Đã trang bị Bùa Nguyệt Quang")
	_assert(player.health_component.max_mana == 80.0, "Max MP tăng chính xác lên 80 (60 + 20)")

	# Đầy mana 80 rồi tháo bùa
	player.health_component.current_mana = 80.0
	eq.unequip("accessory")
	_assert(eq.get_equipped("accessory") == "", "Ô phụ kiện hiện đang trống")
	_assert(player.health_component.max_mana == 60.0, "Max MP hoàn trả chính xác về 60")
	_assert(player.health_component.current_mana == 60.0, "Current MP tự động giới hạn về 60, không bị tràn")

	print("\n--- TEST 9: Không cộng dồn chỉ số khi equip/unequip lặp lại ---")
	eq.equip("moonsteel_sword")
	eq.equip("moonsteel_sword")
	eq.equip("moonsteel_sword")
	_assert(player.melee_hitbox.damage == 35.0, "Trang bị lặp lại 3 lần: Sát thương vẫn giữ nguyên 35, không bị cộng dồn")

	eq.equip("moon_amulet")
	eq.equip("moon_amulet")
	_assert(player.health_component.max_mana == 80.0, "Trang bị lặp lại bùa: Max MP vẫn giữ nguyên 80")

	eq.unequip("weapon")
	eq.unequip("accessory")
	_assert(player.melee_hitbox.damage == 25.0 and player.health_component.max_mana == 60.0, "Sau khi tháo, cả hai chỉ số trở lại đúng giá trị gốc ban đầu")

	print("\n--- TEST 10: Lưu Inventory và Equipment rồi tải lại đúng ---")
	inv._initialize_slots()
	inv.add_item("mana_shard", 18)
	inv.add_item("health_potion", 4)
	eq.equip("moonsteel_sword")
	eq.equip("moon_amulet")

	var save_res := SaveManager.save_game(world)
	_assert(save_res == true, "Lưu game thành công vào file save slot 1")

	# Xóa sạch dữ liệu trên RAM để kiểm tra tải
	inv._initialize_slots()
	eq.unequip("weapon")
	eq.unequip("accessory")
	_assert(inv.get_item_count("mana_shard") == 0, "RAM: Đã dọn sạch túi đồ")
	_assert(eq.get_equipped("weapon") == "", "RAM: Đã tháo sạch trang bị")

	var load_res := SaveManager.load_game(world)
	_assert(load_res == true, "Tải game từ file save thành công")
	_assert(inv.get_item_count("mana_shard") == 18, "Phục hồi đúng 18 mana_shard")
	_assert(inv.get_item_count("health_potion") == 4, "Phục hồi đúng 4 health_potion")
	_assert(eq.get_equipped("weapon") == "moonsteel_sword", "Phục hồi đúng trang bị Kiếm Ánh Trăng")
	_assert(eq.get_equipped("accessory") == "moon_amulet", "Phục hồi đúng trang bị Bùa Nguyệt Quang")
	_assert(player.melee_hitbox.damage == 35.0, "Chỉ số sát thương tính toán đúng 35 sau khi tải")
	_assert(player.health_component.max_mana == 80.0, "Chỉ số Max MP tính toán đúng 80 sau khi tải")

	print("\n--- TEST 11: Lưu và tải trạng thái nhiệm vụ 2/3 ---")
	quest_mgr.start_quest()
	quest_mgr.current_quest.current_amount = 2
	quest_mgr.gold = 75
	SaveManager.save_game(world)

	# Giả lập reset trên RAM
	quest_mgr.current_quest.current_state = QuestData.State.NOT_STARTED
	quest_mgr.current_quest.current_amount = 0
	quest_mgr.gold = 0

	SaveManager.load_game(world)
	_assert(quest_mgr.current_quest.current_state == QuestData.State.ACTIVE, "Phục hồi đúng trạng thái nhiệm vụ ACTIVE")
	_assert(quest_mgr.current_quest.current_amount == 2, "Phục hồi đúng tiến độ nhiệm vụ 2/3")
	_assert(quest_mgr.gold == 75, "Phục hồi đúng số Vàng 75 G")

	print("\n--- TEST 12: Quái đã chết trước khi save không bị phục hồi sai sau khi load ---")
	world.defeated_enemy_ids = ["enemy_forest_1"]
	var e1: Enemy = world.get_node_or_null("CorruptedEnemy1") as Enemy
	if e1:
		e1.queue_free()
		await process_frame

	SaveManager.save_game(world)
	SaveManager.load_game(world)

	var check_e1 = world.get_node_or_null("CorruptedEnemy1")
	_assert(check_e1 == null or check_e1.is_queued_for_deletion(), "Quái enemy_forest_1 đã chết trước khi save không xuất hiện lại")

	print("\n--- TEST 13: Phần thưởng nhiệm vụ không nhận được lần hai ---")
	quest_mgr.current_quest.current_state = QuestData.State.COMPLETED
	var gold_before := quest_mgr.gold
	var try_complete := quest_mgr.complete_quest(player.health_component)
	_assert(try_complete == false, "complete_quest trả về false khi quest đã COMPLETED")
	_assert(quest_mgr.gold == gold_before, "Vàng không bị cộng thêm lần 2")

	print("\n--- TEST 14: File save hỏng không làm game crash ---")
	# Ghi chuỗi JSON hỏng vào file save
	var bad_file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.WRITE)
	bad_file.store_string("CORRUPTED_JSON_DATA_!@#$%^&*()")
	bad_file.close()

	var bad_load_result := SaveManager.load_game(world)
	_assert(bad_load_result == false, "Hàm load_game trả về false khi file save hỏng JSON")
	_assert(player.is_inside_tree(), "Game không bị crash khi load file hỏng, Player vẫn an toàn trong tree")

	# Dọn file hỏng và lưu lại bản save chuẩn
	SaveManager.save_game(world)

	print("\n--- TEST 15: Kiểm tra hồi quy các tính năng M0/M1/M2 ---")
	var npc: NPC = world.get_node_or_null("NPC_Elyra") as NPC
	_assert(npc != null and npc.collision_layer == 0, "NPC Elyra collision_layer = 0 (xuyên người)")
	_assert(player.movement_data != null and player.movement_data.max_jumps == 2, "Hệ thống Double Jump M0 nguyên vẹn")

	# Pause / Resume
	world.get_tree().paused = false
	var pause_ctrl: PauseController = world.get_node_or_null("PauseController") as PauseController
	if pause_ctrl:
		pause_ctrl.pause()
		_assert(world.get_tree().paused == true, "PauseController pause game thành công")
		pause_ctrl.resume()
		_assert(world.get_tree().paused == false, "PauseController resume game thành công")

	# Mở/đóng Túi đồ bằng UI
	ui.open_inventory()
	_assert(ui.is_inventory_open() == true, "Mở InventoryUI thành công")
	ui.close_inventory()
	_assert(ui.is_inventory_open() == false, "Đóng InventoryUI thành công")

	print("\n==================================================")
	print(" [NOCTELYRA M3] KẾT QUẢ KIỂM THỬ TỔNG HỢP:")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL 15 M3 REQUIREMENT PHASES PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

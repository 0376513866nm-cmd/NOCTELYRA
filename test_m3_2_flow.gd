extends SceneTree

# test_m3_2_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M3.2 FINAL:
# 1. Zero-impact Isolation on real save user://noctelyra_slot1.json
# 2. Strict MP Restoration (with and without equipment, 75/80 and 45/60)
# 3. True Atomic Save & Rollback Safety (fault injection on tmp write, backup, and replace)
# 4. Deep Save File Validation (has_save rejecting malformed/unsupported, load_game safety)
# 5. Full regression check (M0, M1, M2.1, M3).

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m3_2_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M3.2] INTEGRATION TEST SUITE STARTING ")
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

	# ---------------------------------------------------------
	# PHẦN 1: GHI NHẬN CHỈ ĐỌC TRẠNG THÁI FILE SAVE THẬT BAN ĐẦU
	# ---------------------------------------------------------
	real_file_existed_at_start = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		real_file_hash_at_start = FileAccess.get_md5(REAL_SAVE_PATH)

	# Định tuyến đường dẫn lưu sang file test riêng biệt
	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

	var world_scene: PackedScene = load("res://src/world/noctis_forest.tscn")
	if not world_scene:
		print("FATAL: Could not load noctis_forest.tscn")
		quit(1)
		return

	var world: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world)
	current_scene = world
	await _wait_seconds(0.3)

	var player: Player = world.player
	var p_health: HealthComponent = player.health_component
	var p_eq: EquipmentComponent = player.equipment_component
	var p_inv: InventoryComponent = player.inventory_component

	# ---------------------------------------------------------
	# PHẦN 2: SỬA LỖI KHÔI PHỤC MP (CÓ VÀ KHÔNG CÓ TRANG BỊ)
	# ---------------------------------------------------------
	print("\n--- TEST 1: Khôi phục MP khi CÓ trang bị Bùa Nguyệt Quang (moon_amulet) ---")
	# Tạm tắt mana regen tự động để đo lường chính xác tuyệt đối
	p_health.mana_regen_rate = 0.0

	# Trang bị Bùa Nguyệt Quang: Max MP tăng từ 60 lên 80
	p_eq.equip("moon_amulet")
	_assert(p_health.max_mana == 80.0, "Đã trang bị Bùa Nguyệt Quang, Max MP đạt 80.0")

	# Đặt Current MP = 75.0 và lưu game
	p_health.current_mana = 75.0
	var s_mp1 := SaveManager.save_game(world)
	_assert(s_mp1 == true, "Lưu game với MP = 75.0 / 80.0 thành công")

	# Khởi tạo World hoàn toàn mới từ đĩa để kiểm tra Load
	world.queue_free()
	await process_frame

	var world_mp: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world_mp)
	current_scene = world_mp
	await _wait_seconds(0.2)

	var p_mp: Player = world_mp.player
	var h_mp: HealthComponent = p_mp.health_component
	h_mp.mana_regen_rate = 0.0

	# Nạp game: SaveManager phải khôi phục trang bị trước rồi mới khôi phục Current MP
	var l_mp1 := SaveManager.load_game(world_mp)
	_assert(l_mp1 == true, "Tải bản lưu thành công")
	_assert(p_mp.equipment_component.get_equipped("accessory") == "moon_amulet", "Trang bị Bùa Nguyệt Quang đã được khôi phục")
	_assert(h_mp.max_mana == 80.0, "Max MP được tính toán chính xác là 80.0")
	_assert(is_equal_approx(h_mp.current_mana, 75.0), "Current MP được áp dụng chính xác tuyệt đối là 75.0 / 80.0 (không bị clamp về 60)")

	print("\n--- TEST 2: Khôi phục MP khi KHÔNG có trang bị Bùa Nguyệt Quang ---")
	# Tháo Bùa Nguyệt Quang: Max MP trở lại 60.0
	p_mp.equipment_component.unequip("accessory")
	_assert(h_mp.max_mana == 60.0, "Đã tháo Bùa, Max MP trở lại 60.0")

	# Đặt Current MP = 45.0 và lưu game
	h_mp.current_mana = 45.0
	var s_mp2 := SaveManager.save_game(world_mp)
	_assert(s_mp2 == true, "Lưu game với MP = 45.0 / 60.0 thành công")

	# Khởi tạo World mới và Load
	world_mp.queue_free()
	await process_frame

	var world_no_acc: NoctisForest = world_scene.instantiate() as NoctisForest
	root.add_child(world_no_acc)
	current_scene = world_no_acc
	await _wait_seconds(0.2)

	var p_no_acc: Player = world_no_acc.player
	var h_no_acc: HealthComponent = p_no_acc.health_component
	h_no_acc.mana_regen_rate = 0.0

	var l_mp2 := SaveManager.load_game(world_no_acc)
	_assert(l_mp2 == true, "Tải bản lưu không có phụ kiện thành công")
	_assert(p_no_acc.equipment_component.get_equipped("accessory") == "", "Ô phụ kiện trống đúng thực tế")
	_assert(h_no_acc.max_mana == 60.0, "Max MP giữ đúng 60.0")
	_assert(is_equal_approx(h_no_acc.current_mana, 45.0), "Current MP được nạp chính xác 45.0 / 60.0")

	# ---------------------------------------------------------
	# PHẦN 3: KIỂM THỬ GHI FILE AN TOÀN THỰC CHẤT (ATOMIC & ROLLBACK)
	# ---------------------------------------------------------
	print("\n--- TEST 3: Kiểm thử Fault Injection - Lỗi ghi file tạm (.tmp) ---")
	# Tạo một bản lưu chuẩn làm căn cứ
	SaveManager.save_game(world_no_acc)
	var baseline_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	var baseline_md5 := FileAccess.get_md5(TEST_SAVE_PATH)
	_assert(not baseline_text.is_empty(), "Đã thiết lập bản lưu gốc chuẩn")

	# Bật mô phỏng lỗi ghi file tạm
	SaveManager.simulate_tmp_write_error = true
	var res_tmp_err := SaveManager.save_game(world_no_acc)
	_assert(res_tmp_err == false, "Hàm save_game từ chối và trả về false khi ghi file tạm lỗi")
	var text_after_tmp_err := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	_assert(text_after_tmp_err == baseline_text, "Bản lưu trước đó vẫn giữ nguyên vẹn nội dung")
	_assert(FileAccess.get_md5(TEST_SAVE_PATH) == baseline_md5, "MD5 checksum bản lưu trước đó không hề thay đổi")
	SaveManager.simulate_tmp_write_error = false

	print("\n--- TEST 4: Kiểm thử Fault Injection - Lỗi ở bước tạo Backup (.bak) ---")
	SaveManager.simulate_backup_error = true
	var res_bak_err := SaveManager.save_game(world_no_acc)
	_assert(res_bak_err == false, "Hàm save_game từ chối và trả về false khi tạo backup lỗi")
	_assert(FileAccess.get_file_as_string(TEST_SAVE_PATH) == baseline_text, "Bản lưu trước đó không bị ảnh hưởng khi backup thất bại")
	_assert(not FileAccess.file_exists(SaveManager.get_tmp_path()), "File tạm .tmp đã được dọn dẹp sạch sẽ")
	SaveManager.simulate_backup_error = false

	print("\n--- TEST 5: Kiểm thử Fault Injection - Lỗi khi Thay thế (Replace) & Phục hồi tự động ---")
	SaveManager.simulate_replace_error = true
	var res_rep_err := SaveManager.save_game(world_no_acc)
	_assert(res_rep_err == false, "Hàm save_game báo false khi quá trình thay thế file bị gián đoạn")
	_assert(FileAccess.file_exists(TEST_SAVE_PATH), "File save chính vẫn tồn tại sau cơ chế rollback")
	_assert(FileAccess.get_file_as_string(TEST_SAVE_PATH) == baseline_text, "Nội dung bản lưu cũ được phục hồi chính xác 100% từ backup")
	_assert(FileAccess.get_md5(TEST_SAVE_PATH) == baseline_md5, "MD5 checksum bản lưu khớp tuyệt đối sau phục hồi")
	_assert(not FileAccess.file_exists(SaveManager.get_bak_path()), "File .bak đã được hoàn tất dọn dẹp")
	_assert(not FileAccess.file_exists(SaveManager.get_tmp_path()), "File .tmp đã được dọn dẹp")

	# Kiểm tra tải lại bản lưu sau sự cố: Phải tải thành công bình thường
	SaveManager.simulate_replace_error = false
	var load_after_rollback := SaveManager.load_game(world_no_acc)
	_assert(load_after_rollback == true, "Tải lại bản lưu sau sự cố rollback thành công hoàn hảo")

	# ---------------------------------------------------------
	# PHẦN 4: THẨM ĐỊNH (VALIDATION) CHẶT CHẼ FILE SAVE
	# ---------------------------------------------------------
	print("\n--- TEST 6: has_save() từ chối JSON sai cú pháp hoặc hỏng ---")
	var bad_syntax_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	bad_syntax_file.store_string("THIS IS NOT A VALID JSON {[[[[")
	bad_syntax_file.close()
	_assert(SaveManager.has_save() == false, "has_save() từ chối file JSON sai cú pháp")
	_assert(SaveManager.load_game(world_no_acc) == false, "load_game() từ chối tải file JSON sai cú pháp")

	print("\n--- TEST 7: has_save() từ chối phiên bản không hỗ trợ (Unsupported Version) ---")
	var bad_ver_json := "{\"save_version\":\"99.0.0\",\"player\":{},\"quest\":{}}"
	var bad_ver_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	bad_ver_file.store_string(bad_ver_json)
	bad_ver_file.close()
	_assert(SaveManager.has_save() == false, "has_save() từ chối phiên bản không hỗ trợ ('99.0.0')")
	_assert(SaveManager.load_game(world_no_acc) == false, "load_game() từ chối tải phiên bản không hỗ trợ")

	print("\n--- TEST 8: has_save() từ chối JSON thiếu cấu trúc dữ liệu bắt buộc ---")
	var missing_root_json := "{\"save_version\":\"1.0.0\",\"some_other_data\":123}"
	var missing_root_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	missing_root_file.store_string(missing_root_json)
	missing_root_file.close()
	_assert(SaveManager.has_save() == false, "has_save() từ chối khi thiếu khối 'player' hoặc 'quest'")
	_assert(SaveManager.load_game(world_no_acc) == false, "load_game() từ chối khi cấu trúc không hợp lệ")

	print("\n--- TEST 9: load_game() an toàn khi thiếu trường con hoặc sai kiểu dữ liệu ---")
	var corrupt_inner_json := "{\"save_version\":\"1.0.0\",\"player\":{\"position_x\":\"CORRUPTED\",\"position_y\":99999.0,\"current_health\":-500.0,\"current_mana\":9999.0},\"gold\":-999,\"inventory\":\"NOT_AN_ARRAY\",\"equipment\":\"NOT_A_DICT\",\"quest\":{\"state\":\"INVALID\",\"current_amount\":\"INVALID\"}}"
	var corrupt_inner_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	corrupt_inner_file.store_string(corrupt_inner_json)
	corrupt_inner_file.close()

	_assert(SaveManager.has_save() == true, "has_save() chấp nhận vì có đủ khối dữ liệu gốc")
	var safe_load := SaveManager.load_game(world_no_acc)
	_assert(safe_load == true, "load_game() xử lý an toàn không crash khi gặp trường con sai kiểu")
	_assert(world_no_acc.player.health_component.current_health >= 0.0, "HP được clamp >= 0.0 an toàn")
	_assert(world_no_acc.player.health_component.current_mana <= world_no_acc.player.health_component.max_mana, "MP không vượt quá Max MP")
	_assert(world_no_acc.quest_manager.gold >= 0, "Vàng được clamp >= 0")
	_assert(world_no_acc.player.global_position.y <= 700.0, "Tọa độ được clamp trong giới hạn an toàn")

	print("\n--- TEST 10: load_game() từ chối khi World thiếu Player hoặc QuestManager ---")
	_assert(SaveManager.load_game(null) == false, "load_game(null) trả về false")
	var dummy_empty_node := Node.new()
	_assert(SaveManager.load_game(dummy_empty_node) == false, "load_game() trả về false khi node không có Player/QuestManager")
	dummy_empty_node.queue_free()

	# ---------------------------------------------------------
	# PHẦN 5: CÁCH LY TUYỆT ĐỐI KHÔNG CHẠM VÀO FILE SAVE THẬT
	# ---------------------------------------------------------
	print("\n--- TEST 11: Kiểm tra cách ly 100% đối với file save thật ---")
	var real_file_existed_at_end := FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		_assert(real_file_existed_at_end == true, "File save thật vẫn tồn tại nguyên vẹn")
		var real_hash_at_end := FileAccess.get_md5(REAL_SAVE_PATH)
		_assert(real_hash_at_end == real_file_hash_at_start, "Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI")
	else:
		_assert(real_file_existed_at_end == false, "File save thật không tồn tại từ đầu và TUYỆT ĐỐI KHÔNG BỊ TẠO GIẢ ĐỊNH")

	# Dọn dẹp DUY NHẤT file test
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	# ---------------------------------------------------------
	# PHẦN 6: KIỂM TRA HỒI QUY M0, M1, M2.1, M3
	# ---------------------------------------------------------
	print("\n--- TEST 12: Kiểm tra hồi quy toàn diện M0 -> M3 ---")
	_assert(world_no_acc.npc_elyra.collision_layer == 0, "M2.1: NPC Elyra collision_layer = 0 (xuyên người mượt mà)")
	_assert(world_no_acc.player.movement_data.max_jumps == 2, "M0: Hệ thống Double Jump nguyên vẹn")
	_assert(world_no_acc.pause_controller != null, "M0: PauseController tồn tại")

	world_no_acc.pause_controller.pause()
	_assert(world_no_acc.get_tree().paused == true, "M0: Pause game thành công")
	world_no_acc.pause_controller.resume()
	_assert(world_no_acc.get_tree().paused == false, "M0: Resume game thành công")

	_assert(world_no_acc.player.melee_hitbox != null, "M1: Melee Hitbox tồn tại")
	_assert(world_no_acc.player.combat_component != null, "M1: Combat Component tồn tại")
	_assert(world_no_acc.player.inventory_component.max_slots == 16, "M3: Inventory 16 ô tồn tại")

	print("\n==================================================")
	print(" [NOCTELYRA M3.2] KẾT QUẢ KIỂM THỬ TỔNG HỢP:")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL M3.2 TEST SCENARIOS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

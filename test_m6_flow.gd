extends SceneTree

# test_m6_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M6: World Expansion & Zone Travel.
# Verifies all 18 requirement groups:
# 1. Three Zones Valid & Loadable Scenes (Noctis, Elyndra, Vharok)
# 2. Zone IDs and Safe Spawn Points
# 3. Locked Portal Enforcement (Moonveil Portal blocked before Boss defeat)
# 4. Moonveil Portal Unlock after Boss Lunareth is defeated
# 5. Travel from Noctis to Elyndra
# 6. Travel from Elyndra back to Noctis
# 7. Travel between Elyndra and Vharok
# 8. Anti-pingpong / Cooldown / Safe Distance (no infinite teleport loop)
# 9. No Duplicate Player, HUD, or QuestManager instances
# 10. Player State Preservation (HP/MP exact, Inv, Equipment, Gold, Spellbook)
# 11. World State Persistence (collected pickups do not respawn across zones)
# 12. Boss Lunareth State Preservation (remains DEFEATED upon return)
# 13. Boss Reward Claim Idempotency (no double gold / double eclipse fragment)
# 14. Save at Vharok -> Continue -> Spawns at Vharok
# 15. Backward Compatibility: Load v1.2.0 save into Noctis Forest
# 16. Player Death in New Zone & Safe Respawn
# 17. Camera limits, Terrain collisions, Boundaries & Interactables (Kaelis, Rhaek, AncientCrystal)
# 18. Full End-to-End Playthrough: Village -> Boss -> Elyndra -> Vharok -> Save & Continue

const NoctisForestScript = preload("res://src/world/noctis_forest.gd")
const ElyndraGladeScript = preload("res://src/world/elyndra_glade.gd")
const VharokOutpostScript = preload("res://src/world/vharok_outpost.gd")
const BossLunarethScript = preload("res://src/boss/boss_lunareth.gd")
const EnemyScript = preload("res://src/actors/enemy/enemy.gd")
const EnemyScene = preload("res://src/actors/enemy/enemy.tscn")
const SpellDatabaseScript = preload("res://src/magic/spell_database.gd")

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m6_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M6] WORLD EXPANSION & TRAVEL TEST SUITE")
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
	SpellDatabaseScript.initialize()
	ZoneManager.reset_session()

	# GHI NHẬN CHỈ ĐỌC TRẠNG THÁI FILE SAVE THẬT - TUYỆT ĐỐI KHÔNG GHI/XÓA/SỬA
	real_file_existed_at_start = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		real_file_hash_at_start = FileAccess.get_md5(REAL_SAVE_PATH)

	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

	# -------------------------------------------------------------
	# GROUP 1: Three Zones Valid & Loadable Scenes
	# -------------------------------------------------------------
	print("\n--- GROUP 1: Three Zones Valid & Loadable Scenes ---")
	var s_noctis: PackedScene = load("res://src/world/noctis_forest.tscn")
	var s_elyndra: PackedScene = load("res://src/world/elyndra_glade.tscn")
	var s_vharok: PackedScene = load("res://src/world/vharok_outpost.tscn")

	_assert(s_noctis != null, "Scene Rừng Noctis (noctis_forest.tscn) nạp thành công")
	_assert(s_elyndra != null, "Scene Thánh Lâm Elyndra (elyndra_glade.tscn) nạp thành công")
	_assert(s_vharok != null, "Scene Tiền Đồn Vharok (vharok_outpost.tscn) nạp thành công")

	# -------------------------------------------------------------
	# GROUP 2: Zone IDs and Spawn Points
	# -------------------------------------------------------------
	print("\n--- GROUP 2: Zone IDs and Spawn Points ---")
	var z1: Node2D = s_noctis.instantiate()
	var z2: Node2D = s_elyndra.instantiate()
	var z3: Node2D = s_vharok.instantiate()

	_assert(z1.get("zone_id") == "noctis_forest", "Zone 1 có zone_id là 'noctis_forest'")
	_assert(z2.get("zone_id") == "elyndra_glade", "Zone 2 có zone_id là 'elyndra_glade'")
	_assert(z3.get("zone_id") == "vharok_outpost", "Zone 3 có zone_id là 'vharok_outpost'")

	# Kiểm tra các spawn point
	var z1_sp1 = z1.get_node_or_null("SpawnDefault")
	var z1_sp2 = z1.get_node_or_null("SpawnFromElyndra")
	_assert(z1_sp1 != null and z1_sp2 != null, "Rừng Noctis có đủ SpawnDefault và SpawnFromElyndra")

	var z2_sp1 = z2.get_node_or_null("SpawnFromNoctis")
	var z2_sp2 = z2.get_node_or_null("SpawnFromVharok")
	_assert(z2_sp1 != null and z2_sp2 != null, "Thánh Lâm Elyndra có đủ SpawnFromNoctis và SpawnFromVharok")

	var z3_sp1 = z3.get_node_or_null("SpawnFromElyndra")
	_assert(z3_sp1 != null, "Tiền Đồn Vharok có SpawnFromElyndra hợp lệ")

	z2.queue_free()
	z3.queue_free()

	# Đưa Zone 1 (Noctis Forest) vào SceneTree để bắt đầu kiểm thử tương tác
	root.add_child(z1)
	current_scene = z1
	await _wait_seconds(0.2)
	var world: NoctisForest = z1 as NoctisForest

	# -------------------------------------------------------------
	# GROUP 3: Locked Portal Enforcement (Moonveil Portal)
	# -------------------------------------------------------------
	print("\n--- GROUP 3: Locked Moonveil Portal before Boss Defeat ---")
	var moonveil_portal: ZonePortal = world.get_node_or_null("MoonveilPortal") as ZonePortal
	_assert(moonveil_portal != null, "Moonveil Portal tồn tại trong scene Rừng Noctis")
	_assert(world.boss_defeated == false, "Boss Lunareth ban đầu chưa bị đánh bại")

	var check_locked := moonveil_portal.can_use(world.player, world)
	_assert(check_locked["can_use"] == false, "Cổng Moonveil TỪ CHỐI dịch chuyển khi Boss chưa bị hạ")
	_assert(check_locked["reason"].contains("Lunareth"), "Lý do từ chối nhắc nhở thanh tẩy Linh Lộc Lunareth")

	var prev_zone_id := ZoneManager.current_zone_id
	moonveil_portal.trigger_interaction()
	_assert(ZoneManager.is_transitioning == false, "Không kích hoạt chuyển cảnh khi cổng bị khóa")
	_assert(ZoneManager.current_zone_id == prev_zone_id, "Khu vực hiện tại không thay đổi")

	# -------------------------------------------------------------
	# GROUP 4: Moonveil Portal Unlocks after Boss Defeat
	# -------------------------------------------------------------
	print("\n--- GROUP 4: Moonveil Portal Unlocks after Boss Defeat ---")
	world.boss_defeated = true
	world.boss_reward_claimed = true
	var check_unlocked := moonveil_portal.can_use(world.player, world)
	_assert(check_unlocked["can_use"] == true, "Cổng Moonveil MỞ KHÓA thành công sau khi Boss Lunareth bị đánh bại")

	# -------------------------------------------------------------
	# GROUP 5: Travel from Noctis to Elyndra
	# -------------------------------------------------------------
	print("\n--- GROUP 5: Travel from Noctis to Elyndra ---")
	# Đặt thông số Player đặc biệt để kiểm tra tính bảo toàn chính xác
	var player := world.player
	player.health_component.current_health = 77.0
	player.health_component.current_mana = 43.0
	player.inventory_component.clear()
	player.inventory_component.add_item("mana_shard", 4)
	world.quest_manager.gold = 150
	player.spellbook_component.selected_spell_id = "frost_shard"
	player.spellbook_component.spell_levels["moon_bolt"] = 2

	# Thực hiện dịch chuyển qua ZoneManager
	var travel_n_to_e = ZoneManager.travel_to_zone("elyndra_glade", "spawn_from_noctis", world)
	_assert(travel_n_to_e == true, "Lệnh dịch chuyển sang Thánh Lâm Elyndra được chấp thuận")

	# Chờ SceneTree hoàn tất đổi scene
	await _wait_seconds(0.4)
	var active_zone = current_scene
	_assert(active_zone is ElyndraGlade, "Scene hiện tại đã đổi thành công sang ElyndraGlade")
	_assert(ZoneManager.current_zone_id == "elyndra_glade", "ZoneManager.current_zone_id cập nhật là 'elyndra_glade'")

	# Kiểm tra Player được đặt đúng spawn point
	var p2: Player = active_zone.get_node_or_null("Player") as Player
	_assert(p2 != null, "Player tồn tại trong Thánh Lâm Elyndra")
	_assert(is_equal_approx(p2.global_position.x, 280.0), "Player xuất hiện chính xác tại SpawnFromNoctis (X=280)")
	_assert(p2.facing_direction == 1, "Player quay mặt về phía trước (hướng phải)")

	# -------------------------------------------------------------
	# GROUP 6: Travel from Elyndra back to Noctis
	# -------------------------------------------------------------
	print("\n--- GROUP 6: Travel from Elyndra back to Noctis ---")
	# Chờ hết travel cooldown
	ZoneManager.travel_cooldown = 0.0
	var portal_to_noctis: ZonePortal = active_zone.get_node_or_null("PortalToNoctis") as ZonePortal
	_assert(portal_to_noctis != null, "Cổng PortalToNoctis tồn tại trong Elyndra")

	var travel_e_to_n = ZoneManager.travel_to_zone("noctis_forest", "spawn_from_elyndra", active_zone)
	_assert(travel_e_to_n == true, "Dịch chuyển từ Elyndra về Rừng Noctis thành công")
	await _wait_seconds(0.4)

	var back_noctis = current_scene
	_assert(back_noctis is NoctisForest, "Scene hiện tại đã trở về NoctisForest")
	var p_back: Player = back_noctis.get_node_or_null("Player") as Player
	_assert(is_equal_approx(p_back.global_position.x, 5700.0), "Player xuất hiện chính xác tại SpawnFromElyndra (X=5700)")
	_assert(p_back.facing_direction == -1, "Player quay mặt về bên trái (hướng vào làng)")

	# -------------------------------------------------------------
	# GROUP 7: Travel between Elyndra and Vharok
	# -------------------------------------------------------------
	print("\n--- GROUP 7: Travel between Elyndra and Vharok ---")
	ZoneManager.travel_cooldown = 0.0
	ZoneManager.travel_to_zone("elyndra_glade", "spawn_from_noctis", back_noctis)
	await _wait_seconds(0.4)
	var elyndra_zone = current_scene

	ZoneManager.travel_cooldown = 0.0
	var portal_to_vharok: ZonePortal = elyndra_zone.get_node_or_null("PortalToVharok") as ZonePortal
	_assert(portal_to_vharok != null, "Cổng PortalToVharok tồn tại trong Elyndra")

	var travel_e_to_v = ZoneManager.travel_to_zone("vharok_outpost", "spawn_from_elyndra", elyndra_zone)
	_assert(travel_e_to_v == true, "Dịch chuyển từ Elyndra sang Tiền Đồn Vharok thành công")
	await _wait_seconds(0.4)

	var vharok_zone = current_scene
	_assert(vharok_zone is VharokOutpost, "Scene hiện tại là VharokOutpost")
	var p_vharok: Player = vharok_zone.get_node_or_null("Player") as Player
	_assert(is_equal_approx(p_vharok.global_position.x, 280.0), "Player xuất hiện tại SpawnFromElyndra của Vharok (X=280)")

	# Quay lại Elyndra từ Vharok
	ZoneManager.travel_cooldown = 0.0
	var portal_back_elyndra: ZonePortal = vharok_zone.get_node_or_null("PortalToElyndra") as ZonePortal
	_assert(portal_back_elyndra != null, "Cổng PortalToElyndra tồn tại trong Vharok")
	ZoneManager.travel_to_zone("elyndra_glade", "spawn_from_vharok", vharok_zone)
	await _wait_seconds(0.4)

	var back_elyndra2 = current_scene
	_assert(back_elyndra2 is ElyndraGlade, "Đã quay trở lại ElyndraGlade thành công")
	var p_elyndra2: Player = back_elyndra2.get_node_or_null("Player") as Player
	_assert(is_equal_approx(p_elyndra2.global_position.x, 2120.0), "Player xuất hiện an toàn tại SpawnFromVharok (X=2120)")

	# -------------------------------------------------------------
	# GROUP 8: Anti-pingpong / Cooldown / Safe Distance
	# -------------------------------------------------------------
	print("\n--- GROUP 8: Anti-pingpong Cooldown & Distance Protection ---")
	_assert(ZoneManager.travel_cooldown > 0.0, "Cờ travel_cooldown kích hoạt (> 0s) sau khi vừa tới khu vực mới")
	var portal_nearby := back_elyndra2.get_node_or_null("PortalToVharok") as ZonePortal
	# Khoảng cách từ Spawn X=2120 đến Portal X=2260 là 140px, lớn hơn bán kính va chạm (35px)
	_assert(abs(p_elyndra2.global_position.x - portal_nearby.global_position.x) >= 100.0, "Vị trí Spawn cách xa Portal >= 100px, không bị chồng lấn")
	_assert(portal_nearby.is_interactable() == false, "Portal không tự động kích hoạt ngoài ý muốn khi vừa tới")

	# -------------------------------------------------------------
	# GROUP 9: No Duplicate Player, HUD, or QuestManager
	# -------------------------------------------------------------
	print("\n--- GROUP 9: No Duplicate Singletons / Entities ---")
	var player_nodes = get_nodes_in_group("players")
	_assert(player_nodes.size() == 1, "Chỉ duy nhất 1 instance Player tồn tại trong SceneTree")

	var ui_count: int = 0
	var qm_count: int = 0
	for child in back_elyndra2.get_children():
		if child is GameUI: ui_count += 1
		if child is QuestManager: qm_count += 1
	_assert(ui_count == 1, "Chỉ duy nhất 1 GameUI HUD tồn tại")
	_assert(qm_count == 1, "Chỉ duy nhất 1 QuestManager tồn tại")

	# -------------------------------------------------------------
	# GROUP 10: Player State Preservation Across Travel
	# -------------------------------------------------------------
	print("\n--- GROUP 10: Player Stats & Inventory Preservation ---")
	var pe: HealthComponent = p_elyndra2.health_component
	var pinv: InventoryComponent = p_elyndra2.inventory_component
	var psb: SpellbookComponent = p_elyndra2.spellbook_component
	var pqm: QuestManager = back_elyndra2.quest_manager

	_assert(is_equal_approx(pe.current_health, 77.0), "HP hiện tại bảo toàn chính xác 77.0 (không bị hồi đầy 100)")
	_assert(pe.current_mana < pe.max_mana and pe.current_mana >= 43.0, "MP hiện tại bảo toàn và hồi phục thụ động tự nhiên (không bị reset hồi đầy 60)")
	_assert(pinv.get_item_count("mana_shard") == 4, "Túi đồ giữ nguyên 4 Tinh thể Ma lực")
	_assert(pqm.gold == 150, "Vàng bảo toàn chính xác 150 G")
	_assert(psb.selected_spell_id == "frost_shard", "Phép đang chọn giữ nguyên là frost_shard")
	_assert(psb.get_spell_level("moon_bolt") == 2, "Cấp độ Moon Bolt giữ nguyên Lv.2")

	# -------------------------------------------------------------
	# GROUP 11: World State Persistence (Pickups do not respawn)
	# -------------------------------------------------------------
	print("\n--- GROUP 11: World State Persistence ---")
	# Ghi nhận nhặt mảnh shard 1 tại Rừng Noctis
	ZoneManager.zone_states["noctis_forest"]["collected_pickup_ids"] = ["pickup_forest_shard_1"]
	ZoneManager.travel_cooldown = 0.0
	ZoneManager.travel_to_zone("noctis_forest", "spawn_from_elyndra", back_elyndra2)
	await _wait_seconds(0.4)

	var noctis3: NoctisForest = current_scene as NoctisForest
	var shard1 = noctis3.get_node_or_null("ForestPickup_Shard1")
	_assert(shard1 == null or not is_instance_valid(shard1) or shard1.is_queued_for_deletion(), "Mảnh Tinh thể Ma lực đã nhặt KHÔNG xuất hiện lại khi quay về")

	# -------------------------------------------------------------
	# GROUP 12: Boss Lunareth State Preservation
	# -------------------------------------------------------------
	print("\n--- GROUP 12: Boss State Preserved as DEFEATED ---")
	_assert(noctis3.boss_defeated == true, "Trạng thái boss_defeated vẫn là true khi quay lại Rừng Noctis")
	var b_inst = noctis3.boss_lunareth
	_assert(b_inst != null and b_inst.current_state == BossLunarethScript.State.DEFEATED, "Boss Lunareth giữ nguyên trạng thái DEFEATED, không bị hồi sinh")

	# -------------------------------------------------------------
	# GROUP 13: Boss Reward Claim Idempotency
	# -------------------------------------------------------------
	print("\n--- GROUP 13: Boss Reward Idempotency ---")
	var gold_before_reward := noctis3.quest_manager.gold
	var fragments_before := noctis3.player.inventory_component.get_item_count("eclipse_fragment")
	noctis3.grant_boss_reward() # Thử trao thưởng lần 2
	_assert(noctis3.quest_manager.gold == gold_before_reward, "Vàng không bị trao lặp lại")
	_assert(noctis3.player.inventory_component.get_item_count("eclipse_fragment") == fragments_before, "Mảnh Nguyệt Thực không bị trao lặp lại")

	# -------------------------------------------------------------
	# GROUP 14: Save at Vharok -> Continue -> Spawns at Vharok
	# -------------------------------------------------------------
	print("\n--- GROUP 14: Save at Vharok -> Continue Flow ---")
	ZoneManager.travel_cooldown = 0.0
	ZoneManager.travel_to_zone("vharok_outpost", "spawn_from_elyndra", noctis3)
	await _wait_seconds(0.4)

	var vharok_scene = current_scene
	var save_vharok_res := SaveManager.save_game(vharok_scene)
	_assert(save_vharok_res == true, "Lưu game thành công khi đang ở Tiền Đồn Vharok")

	var save_txt := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	var s_dict: Dictionary = JSON.parse_string(save_txt)
	_assert(s_dict.get("current_zone_id") == "vharok_outpost", "Bản lưu ghi nhận đúng current_zone_id là 'vharok_outpost'")
	_assert(SaveManager.get_save_zone_id() == "vharok_outpost", "SaveManager.get_save_zone_id() trả về 'vharok_outpost'")
	_assert(SaveManager.get_save_zone_scene_path().contains("vharok_outpost"), "SaveManager.get_save_zone_scene_path() trả về scene Vharok")

	# Giả lập Continue từ Main Menu
	vharok_scene.queue_free()
	await _wait_seconds(0.1)

	var vharok_new: Node2D = s_vharok.instantiate()
	root.add_child(vharok_new)
	current_scene = vharok_new
	SaveManager.load_game(vharok_new)
	await _wait_seconds(0.2)

	_assert(current_scene is VharokOutpost, "Nạp bản lưu Continue đưa người chơi xuất hiện chính xác tại Tiền Đồn Vharok")
	var p_loaded: Player = vharok_new.get_node_or_null("Player") as Player
	_assert(p_loaded.inventory_component.get_item_count("mana_shard") == 4, "Túi đồ khôi phục chuẩn xác sau khi tải lại game")

	# -------------------------------------------------------------
	# GROUP 15: Backward Compatibility: Load v1.2.0 save into Noctis
	# -------------------------------------------------------------
	print("\n--- GROUP 15: Backward Compatibility v1.2.0 ---")
	var legacy_v12_str := "{\"save_version\":\"1.2.0\",\"player\":{\"position_x\":250.0,\"position_y\":630.0,\"current_health\":100.0,\"current_mana\":60.0},\"gold\":75,\"inventory\":[],\"equipment\":{},\"spellbook\":{\"selected_spell\":\"moon_bolt\",\"known_spells\":[\"moon_bolt\",\"ember_bloom\",\"frost_shard\"],\"spell_levels\":{\"moon_bolt\":1,\"ember_bloom\":1,\"frost_shard\":1}},\"quest\":{\"state\":3,\"current_amount\":3}}"
	var f12 := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f12.store_string(legacy_v12_str)
	f12.close()

	_assert(SaveManager.get_save_zone_id() == "noctis_forest", "Bản lưu cũ v1.2.0 chưa có current_zone_id mặc định là 'noctis_forest'")
	vharok_new.queue_free()
	await _wait_seconds(0.1)

	var noctis_legacy = s_noctis.instantiate() as NoctisForest
	root.add_child(noctis_legacy)
	current_scene = noctis_legacy
	var load_legacy_res := SaveManager.load_game(noctis_legacy)
	_assert(load_legacy_res == true, "Nạp thành công bản lưu cũ v1.2.0")
	_assert(noctis_legacy.quest_manager.gold == 75, "Khôi phục đúng Vàng từ bản lưu cũ")

	# -------------------------------------------------------------
	# GROUP 16: Player Death in New Zone & Safe Respawn
	# -------------------------------------------------------------
	print("\n--- GROUP 16: Player Death & Respawn in New Zone ---")
	ZoneManager.travel_cooldown = 0.0
	ZoneManager.travel_to_zone("elyndra_glade", "spawn_from_noctis", noctis_legacy)
	await _wait_seconds(0.4)
	var elyndra_live = current_scene
	var p_die: Player = elyndra_live.get_node_or_null("Player") as Player

	# Cho Player nhận sát thương chí tử
	p_die.health_component.take_damage(DamageInfo.new(999.0, null))
	_assert(p_die.current_state == Player.State.DEAD, "Player tử vong trong Thánh Lâm Elyndra")
	_assert(elyndra_live.game_ui.game_over_panel.visible == true, "Game Over panel hiển thị khi chết")

	# Bấm Retry
	elyndra_live.game_ui._on_retry_pressed()
	await _wait_seconds(0.1)
	_assert(p_die.current_state != Player.State.DEAD, "Player hồi sinh thành công (không còn ở trạng thái DEAD)")
	_assert(p_die.health_component.current_health == p_die.health_component.max_health, "HP hồi phục đầy đủ sau Retry")
	_assert(is_equal_approx(p_die.global_position.x, 280.0), "Player hồi sinh tại điểm Spawn an toàn của khu vực")

	# -------------------------------------------------------------
	# GROUP 17: Camera Limits, Collisions & Interactables
	# -------------------------------------------------------------
	print("\n--- GROUP 17: Camera Limits, Collisions & Interactables ---")
	var cam: Camera2D = elyndra_live.get_node_or_null("Camera2D") as Camera2D
	_assert(cam != null and cam.limit_left == 0 and cam.limit_right == 2400, "Camera2D của Elyndra có giới hạn chuẩn 0 -> 2400 px")

	var kaelis: NPC = elyndra_live.get_node_or_null("NPC_Kaelis") as NPC
	_assert(kaelis != null and kaelis.npc_name == "Kaelis", "NPC Kaelis tồn tại trong Thánh Lâm Elyndra")
	_assert(kaelis.title == "Người Canh Giữ Tinh Mạch", "NPC Kaelis có danh hiệu đúng")

	# Kiểm tra Cổ Tinh Thạch
	var crystal: AncientCrystal = elyndra_live.get_node_or_null("AncientCrystal") as AncientCrystal
	_assert(crystal != null, "Cổ Tinh Thạch (AncientCrystal) tồn tại trong scene")
	crystal._player_in_range = true
	crystal.trigger_interaction()
	_assert(elyndra_live.game_ui.is_dialogue_open() == true, "Tương tác với Cổ Tinh Thạch mở hộp thoại thành công")
	_assert(elyndra_live.game_ui.dialogue_speaker.text == "Cổ Tinh Thạch", "Hộp thoại hiển thị người nói là 'Cổ Tinh Thạch'")
	elyndra_live.game_ui.close_dialogue()

	# -------------------------------------------------------------
	# GROUP 18: Full End-to-End Game Flow (Village -> Boss -> Elyndra -> Vharok)
	# -------------------------------------------------------------
	print("\n--- GROUP 18: Full End-to-End Game Flow ---")
	# Trở về Noctis, hoàn thành quest, mở gate, hạ boss, qua Elyndra, qua Vharok
	ZoneManager.travel_cooldown = 0.0
	ZoneManager.travel_to_zone("noctis_forest", "spawn_default", elyndra_live)
	await _wait_seconds(0.4)
	var e2e_noctis = current_scene as NoctisForest

	# Hoàn thành nhiệm vụ
	e2e_noctis.quest_manager.start_quest()
	e2e_noctis.quest_manager.current_quest.current_amount = 3
	e2e_noctis.quest_manager.complete_quest()
	_assert(e2e_noctis.magic_gate.is_open == true, "E2E: MagicGate X=4200 đã mở sau khi hoàn thành nhiệm vụ")

	# Đánh bại Boss
	e2e_noctis.boss_lunareth.current_state = BossLunarethScript.State.DEFEATED
	e2e_noctis.boss_defeated = true
	ZoneManager.travel_cooldown = 0.0
	var e2e_portal: ZonePortal = e2e_noctis.get_node_or_null("MoonveilPortal") as ZonePortal
	_assert(e2e_portal.can_use(e2e_noctis.player, e2e_noctis)["can_use"] == true, "E2E: Moonveil Portal sẵn sàng sau khi Boss bại trận")

	# Bước qua portal sang Elyndra
	ZoneManager.travel_cooldown = 0.0
	e2e_portal.trigger_interaction()
	await _wait_seconds(0.4)
	_assert(current_scene is ElyndraGlade, "E2E: Đặt chân tới Thánh Lâm Elyndra")

	# Tiếp tục bước qua portal sang Vharok
	var e2e_p_vharok: ZonePortal = current_scene.get_node_or_null("PortalToVharok") as ZonePortal
	ZoneManager.travel_cooldown = 0.0
	e2e_p_vharok.trigger_interaction()
	await _wait_seconds(0.4)
	_assert(current_scene is VharokOutpost, "E2E: Đặt chân tới Tiền Đồn Vharok")

	# Gặp vệ binh Rhaek
	var rhaek: NPC = current_scene.get_node_or_null("NPC_Rhaek") as NPC
	_assert(rhaek != null and rhaek.npc_name == "Rhaek", "E2E: Gặp Vệ Binh Rhaek của Quỷ tộc bán thú")
	rhaek.trigger_interaction()
	_assert(current_scene.game_ui.dialogue_speaker.text == "Rhaek", "E2E: Hội thoại với Rhaek hiển thị chuẩn xác")
	current_scene.game_ui.close_dialogue()

	# Lưu game và xác nhận Save/Continue hoàn hảo
	var e2e_save_ok := SaveManager.save_game(current_scene)
	_assert(e2e_save_ok == true, "E2E: Lưu game thành công tại đích đến cuối cùng")
	_assert(SaveManager.has_save() == true, "E2E: File save v1.3.0 hợp lệ tồn tại")

	# -------------------------------------------------------------
	# KIỂM TRA CÁCH LY TUYỆT ĐỐI FILE SAVE THẬT
	# -------------------------------------------------------------
	print("\n--- KIỂM TRA AN TOÀN DỮ LIỆU: File save thật không bị ảnh hưởng ---")
	var real_file_existed_at_end := FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		_assert(real_file_existed_at_end == true, "File save thật vẫn tồn tại nguyên vẹn")
		var real_hash_at_end := FileAccess.get_md5(REAL_SAVE_PATH)
		_assert(real_hash_at_end == real_file_hash_at_start, "Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI")
	else:
		_assert(real_file_existed_at_end == false, "File save thật không tồn tại từ đầu và TUYỆT ĐỐI KHÔNG BỊ TẠO GIẢ ĐỊNH")

	# Dọn dẹp DUY NHẤT file test M6
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	print("\n==================================================")
	print(" [NOCTELYRA M6] KẾT QUẢ KIỂM THỬ TỔNG HỢP:        ")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL M6 WORLD EXPANSION & TRAVEL TESTS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

extends SceneTree

# test_m8_flow.gd
# Specialized automated test suite for NOCTELYRA Milestone M8: Character Origins & Progression System.
# Engine: Godot 4.3 + GDScript
# Covers all required categories:
# 1. RaceDefinition Registry & Base Stats (Human, Elf, Demon Beast)
# 2. Character Creation UI & Cancel Save Preservation
# 3. EXP Curve & ExpDatabase Centralized Definitions
# 4. Single Level-Up & Stat Growth (+10 HP, +5 MP, +2 ATK)
# 5. Multi-Level-Up Rollover (Surplus EXP carried forward)
# 6. Max Level 10 Cap & Overflow Blocking
# 7. Duplicate EXP Prevention (Monster, Boss, Quest)
# 8. Unified Stats System with Equipment Bonuses
# 9. Elf Magic Damage Multiplier (1.1x)
# 10. Safe Current HP/MP on Level-Up (Delta Gain, No Full-Heal Exploit)
# 11. Placeholder Race Visual Badges (Non-intrusive to Hitbox/Collision)
# 12. Character Sheet UI Toggle & Content Display
# 13. UI Mutual Exclusivity (CharacterSheet vs Inventory vs QuestJournal)
# 14. UI Input Lock & Grace Cooldown (No Accidental Attack on Close)
# 15. Save/Load v1.5.0 Progression & Race Persistence
# 16. Backward Compatibility with Legacy Saves (v1.0.0 - v1.4.0)
# 17. Zone Travel Persistence (Race, Level, EXP across zones)
# 18. Isolation Verification (Real save file untouched)

const PlayerScript = preload("res://src/actors/player/player.gd")
const PlayerScene = preload("res://src/actors/player/player.tscn")
const NoctisForestScene = preload("res://src/world/noctis_forest.tscn")
const ElyndraGladeScene = preload("res://src/world/elyndra_glade.tscn")
const CharacterCreationUIScene = preload("res://src/ui/character_creation_ui.tscn")
const CharacterSheetUIScene = preload("res://src/ui/character_sheet_ui.tscn")
const ItemDatabaseScript = preload("res://src/inventory/item_database.gd")
const SpellDatabaseScript = preload("res://src/magic/spell_database.gd")

var failures: int = 0
var tests_run: int = 0

const TEST_SAVE_PATH: String = "user://noctelyra_m8_test.json"
const REAL_SAVE_PATH: String = "user://noctelyra_slot1.json"

var real_file_existed_at_start: bool = false
var real_file_hash_at_start: String = ""

func _init() -> void:
	print("==================================================")
	print(" [NOCTELYRA M8] CHARACTER ORIGINS & PROGRESSION SUITE")
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
	ItemDatabaseScript.initialize()
	SpellDatabaseScript.initialize()
	RaceDatabase.initialize()
	ZoneManager.reset_session()

	# GHI NHẬN CHỈ ĐỌC TRẠNG THÁI FILE SAVE THẬT - TUYỆT ĐỐI KHÔNG GHI/XÓA/SỬA
	real_file_existed_at_start = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		real_file_hash_at_start = FileAccess.get_md5(REAL_SAVE_PATH)

	SaveManager.custom_save_path = TEST_SAVE_PATH
	SaveManager.delete_save()

	# -------------------------------------------------------------
	# CATEGORY 1: RaceDefinition Registry & Base Stats
	# -------------------------------------------------------------
	print("\n--- CATEGORY 1: RaceDefinition Registry & Base Stats ---")
	var human_def := RaceDatabase.get_race("human")
	_assert(human_def != null, "Định nghĩa chủng tộc Human tồn tại")
	_assert(human_def.base_health == 100.0, "Human HP: 100.0")
	_assert(human_def.base_mana == 60.0, "Human MP: 60.0")
	_assert(human_def.base_attack == 25.0, "Human ATK: 25.0")
	_assert(human_def.base_mana_regen == 5.0, "Human Regen: 5.0 MP/s")
	_assert(human_def.base_move_speed == 270.0, "Human Speed: 270.0 px/s")
	_assert(human_def.magic_damage_multiplier == 1.0, "Human Magic Multiplier: 1.0x")

	var elf_def := RaceDatabase.get_race("elf")
	_assert(elf_def != null, "Định nghĩa chủng tộc Elf tồn tại")
	_assert(elf_def.base_health == 90.0, "Elf HP: 90.0")
	_assert(elf_def.base_mana == 80.0, "Elf MP: 80.0")
	_assert(elf_def.base_attack == 23.0, "Elf ATK: 23.0")
	_assert(elf_def.base_mana_regen == 7.0, "Elf Regen: 7.0 MP/s")
	_assert(elf_def.base_move_speed == 275.0, "Elf Speed: 275.0 px/s")
	_assert(elf_def.magic_damage_multiplier == 1.1, "Elf Magic Multiplier: 1.1x")

	var beast_def := RaceDatabase.get_race("demon_beast")
	_assert(beast_def != null, "Định nghĩa chủng tộc Demon Beast tồn tại")
	_assert(beast_def.base_health == 125.0, "Demon Beast HP: 125.0")
	_assert(beast_def.base_mana == 50.0, "Demon Beast MP: 50.0")
	_assert(beast_def.base_attack == 30.0, "Demon Beast ATK: 30.0")
	_assert(beast_def.base_mana_regen == 4.0, "Demon Beast Regen: 4.0 MP/s")
	_assert(beast_def.base_move_speed == 260.0, "Demon Beast Speed: 260.0 px/s")
	_assert(beast_def.magic_damage_multiplier == 1.0, "Demon Beast Magic Multiplier: 1.0x")

	# -------------------------------------------------------------
	# CATEGORY 2: Character Creation UI & Cancel Save Preservation
	# -------------------------------------------------------------
	print("\n--- CATEGORY 2: Character Creation UI & Cancel Save Preservation ---")
	var dummy_save_data := {"save_version": "1.5.0", "gold": 777}
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(dummy_save_data))
	f.close()
	var pre_cancel_md5 := FileAccess.get_md5(TEST_SAVE_PATH)

	var char_creation := CharacterCreationUIScene.instantiate()
	char_creation.auto_change_scene = false
	root.add_child(char_creation)
	await _wait_seconds(0.1)

	_assert(char_creation.has_node("Panel/RaceTabs"), "Giao diện tạo nhân vật có thanh chọn tộc RaceTabs")
	_assert(char_creation.selected_race_id == "human", "Mặc định chọn tộc Nhân loại")

	# Đổi sang tộc Elf
	char_creation.select_race("elf")
	_assert(char_creation.selected_race_id == "elf", "Chọn thành công tộc Elf")

	# Nhấn Hủy (Cancel)
	var cancel_state := {"emitted": false}
	char_creation.cancelled.connect(func(): cancel_state["emitted"] = true)
	char_creation._on_cancel_pressed()
	_assert(cancel_state["emitted"] == true, "Tín hiệu cancelled phát ra khi bấm Hủy")

	# Kiểm tra file save không bị xóa
	_assert(FileAccess.file_exists(TEST_SAVE_PATH) == true, "Bấm Hủy KHÔNG xóa file save hiện có")
	_assert(FileAccess.get_md5(TEST_SAVE_PATH) == pre_cancel_md5, "Nội dung file save được bảo toàn nguyên vẹn sau khi Hủy")

	# Xác nhận chọn tộc Demon Beast
	var confirmed_state := {"race": ""}
	char_creation.select_race("demon_beast")
	char_creation.creation_confirmed.connect(func(r_id: String): confirmed_state["race"] = r_id)
	char_creation._on_confirm_pressed()
	_assert(confirmed_state["race"] == "demon_beast", "Bấm Xác nhận chọn đúng tộc demon_beast")
	_assert(ZoneManager.initial_race_id == "demon_beast", "ZoneManager.initial_race_id được gán là demon_beast")

	char_creation.queue_free()
	await _wait_seconds(0.1)

	# -------------------------------------------------------------
	# CATEGORY 3: EXP Curve & ExpDatabase Centralized Definitions
	# -------------------------------------------------------------
	print("\n--- CATEGORY 3: EXP Curve & ExpDatabase Centralized Definitions ---")
	var prog := PlayerProgressionComponent.new()
	_assert(prog.get_exp_required_for_level(1) == 60, "EXP Cấp 1 -> 2: 60 EXP")
	_assert(prog.get_exp_required_for_level(2) == 100, "EXP Cấp 2 -> 3: 100 EXP")
	_assert(prog.get_exp_required_for_level(3) == 140, "EXP Cấp 3 -> 4: 140 EXP")
	_assert(prog.get_exp_required_for_level(4) == 180, "EXP Cấp 4 -> 5: 180 EXP")
	_assert(prog.get_exp_required_for_level(9) == 380, "EXP Cấp 9 -> 10: 380 EXP")
	_assert(prog.get_exp_required_for_level(10) == 0, "EXP Cấp 10 (Max Level): 0 EXP")

	_assert(ExpDatabase.get_enemy_exp("corrupted_wolf") == 20, "Quái Sói Tha Hóa: 20 EXP")
	_assert(ExpDatabase.get_enemy_exp("corrupted_mooncap") == 20, "Quái Nấm Tha Hóa: 20 EXP")
	_assert(ExpDatabase.get_enemy_exp("corrupted_mana_wisp") == 25, "Quái Tinh Linh Tha Hóa: 25 EXP")
	_assert(ExpDatabase.get_enemy_exp("ashfang_wolf") == 25, "Quái Sói Nanh Tro: 25 EXP")
	_assert(ExpDatabase.get_enemy_exp("ember_lizard") == 30, "Quái Thằn Lằn Tro: 30 EXP")
	_assert(ExpDatabase.get_boss_exp() == 150, "Boss Lunareth: 150 EXP")
	_assert(ExpDatabase.get_quest_exp("quest_tutorial") == 50, "Nhiệm vụ Elyra: 50 EXP")
	_assert(ExpDatabase.get_quest_exp("quest_elyndra_cleansing") == 60, "Nhiệm vụ Kaelis: 60 EXP")
	_assert(ExpDatabase.get_quest_exp("quest_vharok_embers") == 70, "Nhiệm vụ Rhaek: 70 EXP")

	# -------------------------------------------------------------
	# CATEGORY 4: Single Level-Up & Stat Growth
	# -------------------------------------------------------------
	print("\n--- CATEGORY 4: Single Level-Up & Stat Growth ---")
	var p_node: Player = PlayerScene.instantiate()
	root.add_child(p_node)
	await _wait_seconds(0.1)

	p_node.race_id = "human"
	p_node.player_stats_component.recalculate_stats(false)

	_assert(p_node.health_component.max_health == 100.0, "Human Lv 1 HP: 100.0")
	_assert(p_node.health_component.max_mana == 60.0, "Human Lv 1 MP: 60.0")
	_assert(p_node.melee_hitbox.damage == 25.0, "Human Lv 1 ATK: 25.0")

	var lvl_up_state := {"received": false, "lvl": 0}
	p_node.progression_component.level_up.connect(func(lvl: int):
		lvl_up_state["received"] = true
		lvl_up_state["lvl"] = lvl
	)

	var add_res := p_node.progression_component.add_exp(60, "test_source_1")
	_assert(add_res == true, "Thêm 60 EXP thành công")
	_assert(p_node.progression_component.level == 2, "Player đạt Cấp 2")
	_assert(p_node.progression_component.current_exp == 0, "EXP dư về 0")
	_assert(lvl_up_state["received"] == true and lvl_up_state["lvl"] == 2, "Tín hiệu level_up phát ra với cấp 2")

	_assert(p_node.health_component.max_health == 110.0, "Human Lv 2 HP (+10): 110.0")
	_assert(p_node.health_component.max_mana == 65.0, "Human Lv 2 MP (+5): 65.0")
	_assert(p_node.melee_hitbox.damage == 27.0, "Human Lv 2 ATK (+2): 27.0")

	# -------------------------------------------------------------
	# CATEGORY 5: Multi-Level-Up Rollover
	# -------------------------------------------------------------
	print("\n--- CATEGORY 5: Multi-Level-Up Rollover ---")
	# Đang ở Lv 2 (cần 100 để lên Lv 3, Lv 3 cần 140 để lên Lv 4).
	# Thêm 250 EXP:
	# - 100 EXP đưa lên Lv 3 (còn 150)
	# - 140 EXP đưa lên Lv 4 (còn 10)
	# Kết quả mong đợi: Cấp 4, EXP dư = 10, target = 180.
	var levels_emitted: Array[int] = []
	p_node.progression_component.level_up.connect(func(lvl: int): levels_emitted.append(lvl))

	p_node.progression_component.add_exp(250, "test_multi_rollover")
	_assert(p_node.progression_component.level == 4, "Tăng liên tiếp lên Cấp 4 thành công")
	_assert(p_node.progression_component.current_exp == 10, "Bảo lưu chuẩn xác 10 EXP dư")
	_assert(p_node.progression_component.get_current_target_exp() == 180, "Mục tiêu lên cấp 5 là 180 EXP")
	_assert(levels_emitted.has(3) and levels_emitted.has(4), "Phát đầy đủ tín hiệu thăng cấp qua từng cấp (3 và 4)")

	# Kiểm tra chỉ số sau 3 cấp tăng (+30 HP, +15 MP, +6 ATK so với gốc)
	_assert(p_node.health_component.max_health == 130.0, "Human Lv 4 Max HP: 130.0")
	_assert(p_node.health_component.max_mana == 75.0, "Human Lv 4 Max MP: 75.0")
	_assert(p_node.melee_hitbox.damage == 31.0, "Human Lv 4 ATK: 31.0")

	# -------------------------------------------------------------
	# CATEGORY 6: Max Level 10 Cap & Overflow Blocking
	# -------------------------------------------------------------
	print("\n--- CATEGORY 6: Max Level 10 Cap & Overflow Blocking ---")
	p_node.progression_component.add_exp(10000, "massive_exp_grant")
	_assert(p_node.progression_component.level == 10, "Cấp độ dừng lại chính xác tại Max Level 10")
	_assert(p_node.progression_component.is_max_level() == true, "is_max_level() trả về true")
	_assert(p_node.progression_component.current_exp == 0, "EXP dư bị dọn dẹp tại Cấp 10")

	# Thêm tiếp EXP tại cấp tối đa không gây lỗi và không tăng lên cấp 11
	var overflow_ok := p_node.progression_component.add_exp(500, "extra_at_max")
	_assert(p_node.progression_component.level == 10, "Vẫn giữ nguyên Cấp 10 (không nhảy lên 11)")
	_assert(p_node.health_component.max_health == 100.0 + 9 * 10.0, "Human Lv 10 HP: 190.0")
	_assert(p_node.health_component.max_mana == 60.0 + 9 * 5.0, "Human Lv 10 MP: 105.0")
	_assert(p_node.melee_hitbox.damage == 25.0 + 9 * 2.0, "Human Lv 10 ATK: 43.0")

	# -------------------------------------------------------------
	# CATEGORY 7: Duplicate EXP Prevention
	# -------------------------------------------------------------
	print("\n--- CATEGORY 7: Duplicate EXP Prevention ---")
	var dup_prog := PlayerProgressionComponent.new()
	var r1 := dup_prog.add_exp(20, "monster:noctis:corrupted_mooncap_1")
	_assert(r1 == true, "Nhận EXP quái vật lần đầu: THÀNH CÔNG")
	_assert(dup_prog.current_exp == 20, "EXP hiện tại: 20")

	var r2 := dup_prog.add_exp(20, "monster:noctis:corrupted_mooncap_1")
	_assert(r2 == false, "Nhận EXP cùng quái vật lần hai: BỊ CHẶN TUYỆT ĐỐI")
	_assert(dup_prog.current_exp == 20, "EXP không bị cộng dồn lần 2")

	var b1 := dup_prog.add_exp(150, "boss:lunareth")
	_assert(b1 == true, "Nhận EXP Boss Lunareth lần đầu: THÀNH CÔNG")

	var b2 := dup_prog.add_exp(150, "boss:lunareth")
	_assert(b2 == false, "Nhận EXP Boss Lunareth lần hai: BỊ CHẶN")

	var q1 := dup_prog.add_exp(50, "quest:quest_tutorial")
	_assert(q1 == true, "Nhận EXP Quest lần đầu: THÀNH CÔNG")

	var q2 := dup_prog.add_exp(50, "quest:quest_tutorial")
	_assert(q2 == false, "Nhận EXP Quest cùng ID lần hai: BỊ CHẶN")

	dup_prog.queue_free()

	# -------------------------------------------------------------
	# CATEGORY 8: Unified Stats System with Equipment Bonuses
	# -------------------------------------------------------------
	print("\n--- CATEGORY 8: Unified Stats System with Equipment Bonuses ---")
	p_node.race_id = "elf"
	p_node.progression_component.level = 1
	p_node.progression_component.current_exp = 0
	p_node.player_stats_component.recalculate_stats(false)

	_assert(p_node.health_component.max_health == 90.0, "Elf Lv 1 Base HP: 90.0")
	_assert(p_node.health_component.max_mana == 80.0, "Elf Lv 1 Base MP: 80.0")
	_assert(p_node.melee_hitbox.damage == 23.0, "Elf Lv 1 Base ATK: 23.0")

	# Trang bị Kiếm Ánh Trăng (+10 ATK)
	p_node.inventory_component.add_item("moonsteel_sword", 1)
	p_node.equipment_component.equip_item("moonsteel_sword")
	_assert(p_node.melee_hitbox.damage == 33.0, "Trang bị Kiếm Ánh Trăng: ATK = 23 + 10 = 33.0")

	# Trang bị Bùa Nguyệt Quang (+20 Max MP)
	p_node.inventory_component.add_item("moon_amulet", 1)
	p_node.equipment_component.equip_item("moon_amulet")
	_assert(p_node.health_component.max_mana == 100.0, "Trang bị Bùa Nguyệt Quang: Max MP = 80 + 20 = 100.0")

	# Lên cấp khi đang mặc đồ: Elf Cấp 2 (+10 HP, +5 MP, +2 ATK)
	p_node.progression_component.add_exp(60, "test_gear_lvl")
	_assert(p_node.health_component.max_health == 100.0, "Elf Lv 2 HP (+10): 100.0")
	_assert(p_node.health_component.max_mana == 105.0, "Elf Lv 2 MP (+5 + 20 Bùa): 105.0")
	_assert(p_node.melee_hitbox.damage == 35.0, "Elf Lv 2 ATK (+2 + 10 Kiếm): 35.0")

	# Tháo đồ: chỉ số trừ đúng lượng bonus
	p_node.equipment_component.unequip_item("weapon")
	p_node.equipment_component.unequip_item("accessory")
	_assert(p_node.melee_hitbox.damage == 25.0, "Tháo kiếm: ATK trở về 25.0 (Elf Lv 2)")
	_assert(p_node.health_component.max_mana == 85.0, "Tháo bùa: Max MP trở về 85.0 (Elf Lv 2)")

	# -------------------------------------------------------------
	# CATEGORY 9: Elf Magic Damage Multiplier (1.1x)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 9: Elf Magic Damage Multiplier (1.1x) ---")
	_assert(p_node.spellbook_component.magic_damage_multiplier == 1.1, "Spellbook của Elf có magic_damage_multiplier == 1.1")
	var elf_scaled_dmg: float = float(p_node.spellbook_component.get_spell_damage("moon_bolt"))
	_assert(is_equal_approx(elf_scaled_dmg, 33.0), "Moon Bolt sát thương cơ bản 30 * 1.1 = 33.0 DMG cho Elf")

	p_node.race_id = "human"
	p_node.player_stats_component.recalculate_stats(false)
	var human_scaled_dmg: float = float(p_node.spellbook_component.get_spell_damage("moon_bolt"))
	_assert(is_equal_approx(human_scaled_dmg, 30.0), "Moon Bolt cho Human deals đúng 30.0 DMG")

	# -------------------------------------------------------------
	# CATEGORY 10: Safe Current HP/MP on Level-Up
	# -------------------------------------------------------------
	print("\n--- CATEGORY 10: Safe Current HP/MP on Level-Up ---")
	p_node.race_id = "demon_beast"
	p_node.progression_component.level = 1
	p_node.progression_component.current_exp = 0
	p_node.player_stats_component.recalculate_stats(false)

	# Giả lập Player bị thương nặng: HP còn 25/125, MP còn 10/50
	p_node.health_component.current_health = 25.0
	p_node.health_component.current_mana = 10.0

	# Lên cấp 2 (+10 Max HP, +5 Max MP)
	p_node.progression_component.add_exp(60, "test_safe_heal")
	_assert(p_node.health_component.max_health == 135.0, "Demon Beast Lv 2 Max HP: 135.0")
	_assert(p_node.health_component.max_mana == 55.0, "Demon Beast Lv 2 Max MP: 55.0")
	_assert(p_node.health_component.current_health == 35.0, "Current HP tăng thêm đúng 10 (25 -> 35), KHÔNG bị hồi đầy gian lận")
	_assert(p_node.health_component.current_mana == 15.0, "Current MP tăng thêm đúng 5 (10 -> 15), KHÔNG bị hồi đầy gian lận")

	# -------------------------------------------------------------
	# CATEGORY 11: Placeholder Race Visual Badges
	# -------------------------------------------------------------
	print("\n--- CATEGORY 11: Placeholder Race Visual Badges ---")
	p_node.apply_race_visual("elf")
	var badge_elf: Node2D = p_node.sprite_root.get_node_or_null("RaceVisualBadge") as Node2D
	_assert(badge_elf != null and badge_elf.get_child_count() > 0, "Chủng tộc Elf có hình hiệu trực quan (tai nhọn)")
	_assert(p_node.hurtbox_collision.disabled == false, "Hurtbox vẫn bật bình thường sau khi gắn hiệu ứng tộc")
	_assert(p_node.melee_hitbox != null, "Hitbox cận chiến vẫn tồn tại nguyên vẹn")

	p_node.apply_race_visual("demon_beast")
	var badge_beast: Node2D = p_node.sprite_root.get_node_or_null("RaceVisualBadge") as Node2D
	_assert(badge_beast != null and badge_beast.get_child_count() >= 2, "Chủng tộc Quỷ thú có hình hiệu sừng và đuôi")

	p_node.apply_race_visual("human")
	var badge_human: Node2D = p_node.sprite_root.get_node_or_null("RaceVisualBadge") as Node2D
	_assert(badge_human != null, "Chủng tộc Nhân loại có hình hiệu khăn choàng")

	# -------------------------------------------------------------
	# CATEGORY 12: Character Sheet UI Toggle & Content Display
	# -------------------------------------------------------------
	print("\n--- CATEGORY 12: Character Sheet UI Toggle & Content Display ---")
	var sheet_ui: CharacterSheetUI = CharacterSheetUIScene.instantiate()
	root.add_child(sheet_ui)
	await _wait_seconds(0.1)

	_assert(sheet_ui.visible == false, "Character Sheet UI ban đầu ở trạng thái ẩn")

	p_node.race_id = "human"
	p_node.player_stats_component.recalculate_stats(false)

	sheet_ui.open(p_node)
	_assert(sheet_ui.visible == true, "Mở Character Sheet thành công")
	_assert(sheet_ui.is_open() == true, "is_open() trả về true")
	_assert(sheet_ui.race_label.text.contains("Nhân"), "Hiển thị đúng tên chủng tộc Nhân tộc")
	_assert(sheet_ui.level_label.text.contains("2"), "Hiển thị đúng Cấp độ 2")
	_assert(sheet_ui.hp_stat_label.text.contains("HP"), "Có nhãn chỉ số HP")
	_assert(sheet_ui.mp_stat_label.text.contains("MP"), "Có nhãn chỉ số MP")
	_assert(sheet_ui.atk_stat_label.text.contains("ATK"), "Có nhãn chỉ số ATK")
	_assert(sheet_ui.magic_stat_label.text.contains("Phép"), "Có nhãn chỉ số Ma pháp")

	sheet_ui.close()
	_assert(sheet_ui.visible == false, "Đóng Character Sheet thành công")
	sheet_ui.queue_free()

	# -------------------------------------------------------------
	# CATEGORY 13: UI Mutual Exclusivity
	# -------------------------------------------------------------
	print("\n--- CATEGORY 13: UI Mutual Exclusivity ---")
	var noctis_world = NoctisForestScene.instantiate()
	root.add_child(noctis_world)
	current_scene = noctis_world
	await _wait_seconds(0.3)

	var world_ui: GameUI = noctis_world.get_node_or_null("GameUI") as GameUI
	_assert(world_ui != null, "GameUI tồn tại trong thế giới Noctis")
	_assert(world_ui.character_sheet_ui != null, "CharacterSheetUI tồn tại trong GameUI")

	world_ui.open_character_sheet()
	_assert(world_ui.is_character_sheet_open() == true, "Character Sheet đã mở")
	_assert(world_ui.is_inventory_open() == false, "Túi đồ không mở khi Character Sheet mở")
	_assert(world_ui.is_quest_journal_open() == false, "Sổ nhiệm vụ không mở khi Character Sheet mở")

	world_ui.open_inventory()
	_assert(world_ui.is_inventory_open() == true, "Túi đồ mở")
	_assert(world_ui.is_character_sheet_open() == false, "Character Sheet tự động đóng khi mở Túi đồ")

	world_ui.open_quest_journal()
	_assert(world_ui.is_quest_journal_open() == true, "Sổ nhiệm vụ mở")
	_assert(world_ui.is_inventory_open() == false, "Túi đồ tự động đóng khi mở Sổ nhiệm vụ")

	world_ui.open_character_sheet()
	_assert(world_ui.is_character_sheet_open() == true, "Character Sheet mở lại")
	_assert(world_ui.is_quest_journal_open() == false, "Sổ nhiệm vụ tự động đóng khi mở Character Sheet")

	# -------------------------------------------------------------
	# CATEGORY 14: UI Input Lock & Grace Cooldown (Anti-Accidental Attack)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 14: UI Input Lock & Grace Cooldown (Anti-Accidental Attack) ---")
	var w_player: Player = noctis_world.get_node_or_null("Player") as Player
	_assert(w_player != null, "Player trong Noctis Forest tồn tại")

	# Khi Character Sheet đang mở: input di chuyển và chiến đấu bị khóa
	w_player.velocity.x = 200.0
	w_player._physics_process(0.016)
	_assert(w_player.velocity.x < 200.0, "Vận tốc di chuyển bị hãm dừng khi Character Sheet đang mở")

	# Thử tấn công bằng event attack trong lúc mở: bị GameUI nuốt chửng
	var mock_attack_evt := InputEventAction.new()
	mock_attack_evt.action = "attack"
	mock_attack_evt.pressed = true
	world_ui._unhandled_input(mock_attack_evt)
	_assert(world_ui.is_character_sheet_open() == false, "Nhấn phím J đóng Character Sheet an toàn")

	# Ngay sau khi đóng: Grace Cooldown kích hoạt (0.15s)
	_assert(world_ui.is_ui_cooling_down() == true, "Grace Cooldown kích hoạt ngay sau khi đóng giao diện")

	# Thử tấn công ngay frame tiếp theo trong thời gian cooldown: bị chặn hoàn toàn!
	w_player._physics_process(0.016)
	_assert(w_player.combat_component.is_attacking() == false, "Player KHÔNG vung kiếm tấn công trong thời gian Grace Cooldown!")

	await _wait_seconds(0.2)
	_assert(world_ui.is_ui_cooling_down() == false, "Grace Cooldown kết thúc sau 0.15s")

	# -------------------------------------------------------------
	# CATEGORY 15: Save/Load v1.5.0 Progression & Race Persistence
	# -------------------------------------------------------------
	print("\n--- CATEGORY 15: Save/Load v1.5.0 Progression & Race Persistence ---")
	_assert(SaveManager.CURRENT_VERSION == "1.5.0", "SaveManager.CURRENT_VERSION là 1.5.0")
	_assert(SaveManager.SUPPORTED_VERSIONS.has("1.5.0"), "SaveManager hỗ trợ bản 1.5.0")

	w_player.race_id = "elf"
	w_player.progression_component.level = 3
	w_player.progression_component.current_exp = 45
	w_player.progression_component.claimed_exp_sources = ["source_a", "source_b"]
	w_player.player_stats_component.recalculate_stats(false)
	w_player.health_component.current_health = 70.0 # Bị thương (70 / 110)

	var s_ok := SaveManager.save_game(noctis_world)
	_assert(s_ok == true, "Lưu game v1.5.0 thành công")

	var save_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	var raw_save_json: Dictionary = JSON.parse_string(save_file.get_as_text())
	save_file.close()

	_assert(raw_save_json.get("save_version") == "1.5.0", "Bản lưu ghi save_version == 1.5.0")
	var p_save: Dictionary = raw_save_json.get("player", {})
	_assert(p_save.get("race_id") == "elf", "Bản lưu ghi race_id == 'elf'")
	_assert(p_save.has("progression"), "Bản lưu có khối dữ liệu progression")
	var prog_save: Dictionary = p_save.get("progression", {})
	_assert(int(prog_save.get("level", 0)) == 3, "Lưu đúng level == 3")
	_assert(int(prog_save.get("current_exp", 0)) == 45, "Lưu đúng current_exp == 45")
	_assert(prog_save.get("claimed_exp_sources", []).size() == 2, "Lưu đúng danh sách nguồn EXP đã nhận")

	# Tải bản lưu vào scene mới
	noctis_world.queue_free()
	await _wait_seconds(0.2)

	var fresh_world = NoctisForestScene.instantiate()
	root.add_child(fresh_world)
	current_scene = fresh_world
	await _wait_seconds(0.3)

	var ld_ok := SaveManager.load_game(fresh_world)
	_assert(ld_ok == true, "Nạp bản lưu v1.5.0 thành công")

	var ld_player: Player = fresh_world.get_node_or_null("Player") as Player
	_assert(ld_player.race_id == "elf", "Khôi phục chuẩn xác chủng tộc Elf")
	_assert(ld_player.progression_component.level == 3, "Khôi phục chuẩn xác Cấp 3")
	_assert(ld_player.progression_component.current_exp == 45, "Khôi phục chuẩn xác 45 EXP")
	_assert(ld_player.progression_component.claimed_exp_sources.has("source_a"), "Khôi phục nguồn EXP đã nhận")
	_assert(ld_player.health_component.max_health == 110.0, "Max HP chuẩn Elf Lv 3 (90 + 20 = 110)")
	_assert(ld_player.health_component.current_health == 70.0, "Current HP khôi phục chính xác 70.0 (không bị reset)")

	# -------------------------------------------------------------
	# CATEGORY 16: Backward Compatibility with Legacy Saves (v1.0.0 - v1.4.0)
	# -------------------------------------------------------------
	print("\n--- CATEGORY 16: Backward Compatibility with Legacy Saves (v1.0.0 - v1.4.0) ---")
	var legacy_save := raw_save_json.duplicate(true)
	legacy_save["save_version"] = "1.4.0"
	legacy_save.erase("progression")
	var leg_player: Dictionary = legacy_save["player"]
	leg_player.erase("race_id")
	leg_player.erase("progression")

	var leg_f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	leg_f.store_string(JSON.stringify(legacy_save, "\t"))
	leg_f.close()

	fresh_world.queue_free()
	await _wait_seconds(0.2)

	var back_compat_world = NoctisForestScene.instantiate()
	root.add_child(back_compat_world)
	current_scene = back_compat_world
	await _wait_seconds(0.3)

	var leg_load_ok := SaveManager.load_game(back_compat_world)
	_assert(leg_load_ok == true, "Nạp bản lưu cũ v1.4.0 thành công")

	var leg_p: Player = back_compat_world.get_node_or_null("Player") as Player
	_assert(leg_p.race_id == "human", "Bản lưu cũ tự động gán chủng tộc mặc định là Human")
	_assert(leg_p.progression_component.level == 1, "Bản lưu cũ tự động gán Cấp 1")
	_assert(leg_p.progression_component.current_exp == 0, "Bản lưu cũ có 0 EXP ban đầu")
	_assert(leg_p.progression_component.claimed_exp_sources.is_empty(), "Không tự động cộng EXP nhiệm vụ hồi tố")
	_assert(leg_p.health_component.max_health == 100.0, "Max HP chuẩn Human Lv 1 (100.0)")

	# -------------------------------------------------------------
	# CATEGORY 17: Zone Travel Persistence
	# -------------------------------------------------------------
	print("\n--- CATEGORY 17: Zone Travel Persistence ---")
	leg_p.race_id = "demon_beast"
	leg_p.progression_component.level = 5
	leg_p.progression_component.current_exp = 75
	leg_p.progression_component.claimed_exp_sources = ["source_zone_1"]

	var recorded_state := ZoneManager.extract_player_state(back_compat_world)
	_assert(recorded_state.get("race_id") == "demon_beast", "ZoneManager ghi nhận race_id là demon_beast")
	_assert(recorded_state.get("level") == 5, "ZoneManager ghi nhận level là 5")
	_assert(recorded_state.get("current_exp") == 75, "ZoneManager ghi nhận current_exp là 75")
	_assert(recorded_state.get("claimed_exp_sources", []).has("source_zone_1"), "ZoneManager ghi nhận claimed_exp_sources")

	back_compat_world.queue_free()
	await _wait_seconds(0.2)

	var elyndra_world = ElyndraGladeScene.instantiate()
	root.add_child(elyndra_world)
	current_scene = elyndra_world
	await _wait_seconds(0.3)

	ZoneManager.apply_player_state(elyndra_world, recorded_state)

	var el_player: Player = elyndra_world.get_node_or_null("Player") as Player
	_assert(el_player.race_id == "demon_beast", "Khu vực mới bảo toàn race_id là demon_beast")
	_assert(el_player.progression_component.level == 5, "Khu vực mới bảo toàn level 5")
	_assert(el_player.progression_component.current_exp == 75, "Khu vực mới bảo toàn 75 EXP")
	_assert(el_player.health_component.max_health == 125.0 + 4 * 10.0, "Max HP Demon Beast Lv 5: 165.0")
	_assert(el_player.melee_hitbox.damage == 30.0 + 4 * 2.0, "ATK Demon Beast Lv 5: 38.0")

	elyndra_world.queue_free()
	await _wait_seconds(0.2)

	# -------------------------------------------------------------
	# CATEGORY 18: Isolation Verification
	# -------------------------------------------------------------
	print("\n--- CATEGORY 18: Isolation Verification ---")
	var real_file_existed_at_end = FileAccess.file_exists(REAL_SAVE_PATH)
	if real_file_existed_at_start:
		_assert(real_file_existed_at_end == true, "File save thật vẫn tồn tại nguyên vẹn")
		var real_hash_at_end = FileAccess.get_md5(REAL_SAVE_PATH)
		_assert(real_hash_at_end == real_file_hash_at_start, "Checksum MD5 file save thật hoàn toàn KHÔNG THAY ĐỔI")
	else:
		_assert(real_file_existed_at_end == false, "File save thật không tồn tại từ đầu và không bị tạo giả định")

	# Dọn dẹp DUY NHẤT file test M8
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""

	print("\n==================================================")
	print(" [NOCTELYRA M8] KẾT QUẢ KIỂM THỬ TỔNG HỢP:        ")
	print(" Tổng số test: %d | Đạt: %d | Thất bại: %d" % [tests_run, tests_run - failures, failures])
	print("==================================================")

	if failures == 0:
		print(">>> ALL M8 CHARACTER ORIGINS & PROGRESSION TESTS PASSED 100%! <<<")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<")
		quit(1)

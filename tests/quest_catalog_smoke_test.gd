extends SceneTree

## Smoke & Verification Test for Quest Catalog & QuestDefinition (Stage 2 Step 2)
## Validates:
## 1. QuestDefinition schema fields: is_main_quest, restore_health_on_complete, restore_mana_on_complete.
## 2. ContentCatalog uniqueness: no duplicate quest_id, no duplicate resource references.
## 3. Main vs Side quest classification: exactly one main quest (quest_noctis_purify), side quests false.
## 4. Main quest content & rewards: target_amount=3, reward_gold=50, restore_health/mana=true.
## 5. Journal lifecycle: all quests start, track objectives, and reach READY_TO_TURN_IN.

class FakeEnemy extends Node:
	var enemy_type_id: String = ""
	var enemy_id: String = ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- BẮT ĐẦU KIỂM THỬ DANH MỤC NHIỆM VỤ & QUEST DEFINITION (BƯỚC 2) ---")

	# 1. KIỂM THỬ SCHEMA QUESTDEFINITION
	var test_def := QuestDefinition.new()
	if not ("is_main_quest" in test_def and "restore_health_on_complete" in test_def and "restore_mana_on_complete" in test_def):
		_fail("QuestDefinition thiếu các trường mở rộng M8: is_main_quest / restore_health_on_complete / restore_mana_on_complete")
		return
	if test_def.is_main_quest != false or test_def.restore_health_on_complete != false or test_def.restore_mana_on_complete != false:
		_fail("Giá trị mặc định của các cờ mở rộng phải là false")
		return
	print("[PASS] 1. QuestDefinition schema hợp lệ với đầy đủ 3 trường mở rộng.")

	# 2. KIỂM THỬ DUY NHẤT & KHÔNG TRÙNG LẶP TRONG CONTENTCATALOG
	var catalog := ContentRegistry.catalog()
	var seen_ids := {}
	var seen_paths := {}
	var main_quest_count := 0
	var side_quest_count := 0

	for q in catalog.quests:
		if q == null or q.quest_id.is_empty():
			_fail("Catalog chứa QuestDefinition null hoặc quest_id rỗng!")
			return
		if seen_ids.has(q.quest_id):
			_fail("Phát hiện Quest ID trùng lặp trong ContentCatalog: " + q.quest_id)
			return
		seen_ids[q.quest_id] = true

		if not q.resource_path.is_empty():
			if seen_paths.has(q.resource_path):
				_fail("Phát hiện tài nguyên Quest đăng ký trùng trong ContentCatalog: " + q.resource_path)
				return
			seen_paths[q.resource_path] = true

		if q.is_main_quest:
			main_quest_count += 1
		else:
			side_quest_count += 1

	if seen_ids.size() != 3:
		_fail("Kỳ vọng chính xác 3 nhiệm vụ trong ContentCatalog, thực tế có: %d" % seen_ids.size())
		return
	print("[PASS] 2. ContentCatalog không có quest_id hoặc tài nguyên nào bị đăng ký trùng lặp (Tổng: 3).")

	# 3. PHÂN LOẠI NHIỆM VỤ CHÍNH VÀ NHIỆM VỤ PHỤ (MAIN VS SIDE CLASSIFICATION)
	if main_quest_count != 1:
		_fail("Kỳ vọng chính xác 1 Main Quest trong toàn bộ ContentCatalog, tìm thấy: %d" % main_quest_count)
		return
	if side_quest_count != 2:
		_fail("Kỳ vọng chính xác 2 Side Quest trong ContentCatalog, tìm thấy: %d" % side_quest_count)
		return

	var main_quest := ContentRegistry.get_quest("quest_noctis_purify")
	if main_quest == null or not main_quest.is_main_quest:
		_fail("quest_noctis_purify phải là Main Quest (is_main_quest = true)!")
		return

	var side1 := ContentRegistry.get_quest("quest_elyndra_cleansing")
	var side2 := ContentRegistry.get_quest("quest_vharok_embers")
	if side1 == null or side1.is_main_quest or side2 == null or side2.is_main_quest:
		_fail("quest_elyndra_cleansing và quest_vharok_embers phải là Side Quests (is_main_quest = false)!")
		return
	print("[PASS] 3. Phân loại Main/Side Quests chính xác (1 Main, 2 Side).")

	# 4. KIỂM THỬ CHI TIẾT DỮ LIỆU & PHẦN THƯỞNG MAIN QUEST (quest_noctis_purify)
	if main_quest.target_id != "corrupted_wolf":
		_fail("Main Quest target_id phải là 'corrupted_wolf', nhận: " + main_quest.target_id)
		return
	if main_quest.target_amount != 3:
		_fail("Main Quest target_amount phải là 3, nhận: %d" % main_quest.target_amount)
		return
	if main_quest.reward_gold != 50:
		_fail("Main Quest reward_gold phải là 50, nhận: %d" % main_quest.reward_gold)
		return
	if main_quest.reward_exp != 50:
		_fail("Main Quest reward_exp phải là 50, nhận: %d" % main_quest.reward_exp)
		return
	if not main_quest.restore_health_on_complete:
		_fail("Main Quest phải có restore_health_on_complete = true!")
		return
	if not main_quest.restore_mana_on_complete:
		_fail("Main Quest phải có restore_mana_on_complete = true!")
		return
	if main_quest.giver_name != "Eiran" or main_quest.giver_location.is_empty():
		_fail("Main Quest thiếu thông tin NPC Eiran hoặc khu vực!")
		return
	print("[PASS] 4. Dữ liệu Main Quest Eiran (3 quái, 50 vàng, 50 EXP, hồi full HP/MP) chuẩn xác 100%.")

	# 5. KIỂM THỬ VẬN HÀNH TIẾN ĐỘ NHẬT KÝ VỚI TOÀN BỘ NHIỆM VỤ (JOURNAL PROGRESSION)
	var player_scene := load("res://src/actors/player/player.tscn") as PackedScene
	if player_scene == null:
		_fail("Không tải được player.tscn")
		return
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame
	var journal := player.quest_journal_component
	var inventory := player.inventory_component
	if journal == null or inventory == null:
		_fail("Player thiếu quest journal hoặc inventory")
		player.queue_free()
		return

	for definition in catalog.quests:
		if definition == null:
			continue
		var preview := definition.format_dialogue(definition.active_dialogue, 1)
		for line in preview:
			if "{" in line or "}" in line:
				_fail("Dialogue còn token chưa thay thế: " + definition.quest_id)
				player.queue_free()
				return
		if not journal.start_quest(definition.quest_id):
			_fail("Không start được quest: " + definition.quest_id)
			player.queue_free()
			return
		if definition.quest_type == QuestDefinition.QuestType.KILL_ENEMY_TYPE:
			for index in definition.target_amount:
				var enemy := FakeEnemy.new()
				enemy.enemy_type_id = definition.target_id
				enemy.enemy_id = "%s_test_%d" % [definition.target_id, index]
				journal.register_enemy_kill(enemy)
				enemy.free()
		else:
			var remaining := inventory.add_item(definition.target_id, definition.target_amount)
			if remaining != 0:
				_fail("Không thêm đủ item cho quest: " + definition.quest_id)
				player.queue_free()
				return
			journal.update_item_collection(inventory)
		if journal.get_quest_state(definition.quest_id) != QuestDefinition.State.READY_TO_TURN_IN:
			_fail("Quest không đạt READY_TO_TURN_IN: " + definition.quest_id)
			player.queue_free()
			return

	player.queue_free()
	await process_frame
	print("[PASS] 5. Vận hành tiến độ của toàn bộ 3 nhiệm vụ trong nhật ký hoàn tất thành công.")

	print("QUEST_CATALOG_OK quests=%d" % catalog.quests.size())
	quit(0)

func _fail(message: String) -> void:
	push_error("LỖI TEST QUEST CATALOG: " + message)
	quit(1)

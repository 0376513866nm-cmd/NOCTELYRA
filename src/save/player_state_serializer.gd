class_name PlayerStateSerializer
extends RefCounted

## Chuyển trạng thái Player và các component thành Dictionary trung lập.
## Zone travel và save/load dùng cùng một schema để tránh lệch dữ liệu.

static func capture(world: Node) -> Dictionary:
	if world == null:
		return {}
	var player := world.get_node_or_null("Player") as Player
	if player == null:
		return {}

	var health := player.health_component
	var inventory := player.inventory_component
	var equipment := player.equipment_component
	var spellbook := player.spellbook_component
	var journal := player.quest_journal_component
	var stats := player.player_stats_component
	var progression := player.progression_component
	var wallet := player.wallet_component

	return {
		"race_id": stats.race_id if stats else "human",
		"level": progression.level if progression else 1,
		"current_exp": progression.current_exp if progression else 0,
		"claimed_exp_sources": progression.claimed_exp_sources.duplicate() if progression else [],
		"current_health": health.current_health if health else 100.0,
		"current_mana": health.current_mana if health else 60.0,
		"gold": wallet.gold if wallet else 0,
		"inventory": inventory.to_dict() if inventory else [],
		"equipment": equipment.to_dict() if equipment else {},
		"spellbook": spellbook.to_dict() if spellbook else {},
		"quest_journal": journal.to_dict() if journal else {}
	}

static func apply(world: Node, data: Dictionary) -> bool:
	if world == null or data.is_empty():
		return false
	var player := world.get_node_or_null("Player") as Player
	if player == null:
		return false

	var stats := player.player_stats_component
	var progression := player.progression_component
	var race_id := str(data.get("race_id", "human"))
	if not RaceDatabase.has_race(race_id):
		race_id = "human"
	if stats:
		stats.set_race(race_id)
	if progression:
		progression.from_dict({
			"level": int(data.get("level", 1)),
			"current_exp": int(data.get("current_exp", 0)),
			"claimed_exp_sources": data.get("claimed_exp_sources", [])
		})

	var equipment := player.equipment_component
	if equipment:
		equipment.load_from_dict(data.get("equipment", {}))
	var inventory := player.inventory_component
	if inventory:
		var inventory_data = data.get("inventory", [])
		if inventory_data is Array:
			inventory.load_from_dict(inventory_data)
	if stats:
		stats.recalculate_stats(false)

	var spellbook := player.spellbook_component
	if spellbook and data.get("spellbook", {}) is Dictionary:
		spellbook.from_dict(data.get("spellbook", {}))
	var journal := player.quest_journal_component
	if journal:
		journal.from_dict(data.get("quest_journal", {}))

	var health := player.health_component
	if health:
		health.current_health = clamp(float(data.get("current_health", health.max_health)), 0.0, health.max_health)
		health.current_mana = clamp(float(data.get("current_mana", health.max_mana)), 0.0, health.max_mana)
		health.health_changed.emit(health.current_health, health.max_health)
		health.mana_changed.emit(health.current_mana, health.max_mana)

	var saved_gold: int = maxi(0, int(data.get("gold", 0)))
	var wallet := player.wallet_component
	if wallet:
		wallet.set_gold(saved_gold)

	# Giai đoạn 2 Bước 3: Di chuyển dữ liệu Idempotent từ Legacy Quest sang Quest Journal
	_migrate_quest_data(data, journal, progression)
	return true

const KNOWN_LEGACY_ENEMY_IDS: Dictionary = {
	"enemy_forest_1": "corrupted_wolf",
	"enemy_forest_2": "corrupted_wolf",
	"enemy_forest_3": "corrupted_wolf",
	"elyndra_mooncap_1": "corrupted_mooncap",
	"elyndra_mooncap_2": "corrupted_mooncap",
	"elyndra_mooncap_3": "corrupted_mooncap",
	"elyndra_wisp_1": "corrupted_mana_wisp",
	"elyndra_wisp_2": "corrupted_mana_wisp",
	"vharok_wolf_1": "ashfang_wolf",
	"vharok_wolf_2": "ashfang_wolf",
	"vharok_wolf_3": "ashfang_wolf",
	"vharok_lizard_1": "ember_lizard",
	"vharok_lizard_2": "ember_lizard",
}

static func _classify_enemy_id(id_str: String) -> String:
	var clean_id := id_str.strip_edges()
	# Nhận diện và loại trừ ID credit giả (cả prefix mới và prefix trung gian cũ)
	if clean_id.begins_with("__legacy_credit_") or clean_id.begins_with("legacy_wolf_"):
		return ""

	if KNOWN_LEGACY_ENEMY_IDS.has(clean_id):
		return KNOWN_LEGACY_ENEMY_IDS[clean_id]

	var s := clean_id.to_lower()
	if s.find("mooncap") != -1:
		return "corrupted_mooncap"
	if s.find("wisp") != -1:
		return "corrupted_mana_wisp"
	if s.find("ashfang") != -1:
		return "ashfang_wolf"
	if s.find("lizard") != -1:
		return "ember_lizard"
	if s.find("wolf") != -1:
		return "corrupted_wolf"
	return ""

static func _migrate_quest_data(data: Dictionary, journal: QuestJournalComponent, progression: PlayerProgressionComponent) -> void:
	if journal == null:
		return

	var raw_journal: Dictionary = data.get("quest_journal", {})
	var raw_main: Dictionary = raw_journal.get("quest_noctis_purify", {})
	var journal_main_state: int = int(raw_main.get("state", 0))
	var journal_main_amount: int = int(raw_main.get("current_amount", 0))
	var journal_main_claimed: bool = bool(raw_main.get("reward_claimed", false))
	var journal_counted: Array = raw_main.get("counted_enemy_ids", [])

	var legacy_dict: Dictionary = data.get("legacy_quest", data.get("quest", {}))
	var legacy_state: int = clampi(int(legacy_dict.get("state", 0)), 0, 3)
	var legacy_amount: int = maxi(0, int(legacy_dict.get("current_amount", 0)))
	var legacy_killed: Array = data.get("killed_enemy_ids", data.get("defeated_enemy_ids", []))
	var legacy_claimed: bool = bool(legacy_dict.get("reward_claimed", false)) or (legacy_state == 3)

	# 1. Phân loại và bóc tách killed_enemy_ids theo chủng loại quái
	var wolf_candidates: Array[String] = []
	var other_candidates: Array[String] = []

	for k in legacy_killed:
		var id_str := str(k).strip_edges()
		if id_str.is_empty():
			continue
		var enemy_type := _classify_enemy_id(id_str)
		if enemy_type == "corrupted_wolf":
			if not id_str in wolf_candidates:
				wolf_candidates.append(id_str)
			journal.record_kill_history_entry("corrupted_wolf", id_str)
		elif not enemy_type.is_empty():
			journal.record_kill_history_entry(enemy_type, id_str)
		else:
			if not id_str in other_candidates:
				other_candidates.append(id_str)

	# 2. Quy tắc đối chiếu và hợp nhất trạng thái (Reconciliation):
	# Nếu một trong hai hệ thống đã hoàn thành (COMPLETED) hoặc đã nhận thưởng -> Đánh dấu COMPLETED và reward_claimed = true.
	var is_legacy_completed := (legacy_state == 3) or legacy_claimed
	var is_journal_completed := (journal_main_state == 3) or journal_main_claimed

	var final_state: int = 0
	var final_amount: int = 0
	var final_claimed: bool = false

	if is_legacy_completed or is_journal_completed:
		final_state = 3 # COMPLETED
		final_amount = 3
		final_claimed = true
	else:
		final_amount = clampi(maxi(legacy_amount, journal_main_amount), 0, 3)
		if legacy_state == 2 or journal_main_state == 2 or final_amount >= 3:
			final_state = 2 # READY_TO_TURN_IN
			final_amount = 3
		elif legacy_state == 1 or journal_main_state == 1 or final_amount > 0:
			final_state = 1 # ACTIVE
		else:
			final_state = 0 # NOT_STARTED
			final_amount = 0
		final_claimed = false

	# 3. Chuẩn hóa counted_enemy_ids cho quest_noctis_purify:
	# Đảm bảo counted_enemy_ids.size() == final_amount và không chứa quái khác loại.
	var final_counted: Array = []
	if final_amount > 0:
		# 1. Ưu tiên các ID đã có sẵn trong journal_counted (nếu là wolf hoặc generic)
		for jid in journal_counted:
			var sjid := str(jid).strip_edges()
			if sjid.is_empty():
				continue
			var ctype := _classify_enemy_id(sjid)
			if ctype == "corrupted_wolf" or ctype == "":
				if not sjid in final_counted:
					final_counted.append(sjid)
					if final_counted.size() == final_amount:
						break

		# 2. Bổ sung từ wolf_candidates đã xác thực
		if final_counted.size() < final_amount:
			for wid in wolf_candidates:
				if not wid in final_counted:
					final_counted.append(wid)
					if final_counted.size() == final_amount:
						break

		# 3. Bổ sung từ generic candidates nếu cần (bảo toàn tiến trình, nhưng KHÔNG đưa vào _kill_history["corrupted_wolf"])
		if final_counted.size() < final_amount:
			for oid in other_candidates:
				if not oid in final_counted:
					final_counted.append(oid)
					if final_counted.size() == final_amount:
						break

		# 4. Fallback ổn định nếu không có đủ ID (bảo toàn tiến trình, nhưng KHÔNG đưa vào _kill_history["corrupted_wolf"])
		var fallback_idx := 1
		while final_counted.size() < final_amount:
			var fid := "__legacy_credit_" + str(fallback_idx)
			fallback_idx += 1
			if not fid in final_counted:
				final_counted.append(fid)

	# Chỉ ghi nhận vào kill_history các ID thực sự là sói (hoặc known wolf mapping)
	for fc in final_counted:
		if _classify_enemy_id(str(fc)) == "corrupted_wolf":
			journal.record_kill_history_entry("corrupted_wolf", str(fc))

	# 4. Áp dụng đồng bộ vào QuestJournalComponent qua phương thức nội bộ có kiểm soát
	journal.reconcile_quest_state("quest_noctis_purify", final_state, final_amount, final_claimed, final_counted)

	# 5. Bảo vệ chống nhận EXP trùng lặp nếu Quest đã hoàn thành
	if (final_state == 3 or final_claimed) and progression != null:
		if not "quest:quest_tutorial" in progression.claimed_exp_sources:
			progression.claimed_exp_sources.append("quest:quest_tutorial")
		if not "quest:quest_noctis_purify" in progression.claimed_exp_sources:
			progression.claimed_exp_sources.append("quest:quest_noctis_purify")

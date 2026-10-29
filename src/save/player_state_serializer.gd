class_name PlayerStateSerializer
extends RefCounted

## Chuyển trạng thái Player và các component thành Dictionary trung lập.
## Zone travel và save/load dùng cùng một schema để tránh lệch dữ liệu.

static func capture(world: Node) -> Dictionary:
	if world == null:
		return {}
	var player := world.get_node_or_null("Player") as Player
	var quest_manager := world.get_node_or_null("QuestManager") as QuestManager
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
		"gold": wallet.gold if wallet else (quest_manager.gold if quest_manager else 0),
		"inventory": inventory.to_dict() if inventory else [],
		"equipment": equipment.to_dict() if equipment else {},
		"spellbook": spellbook.to_dict() if spellbook else {},
		"quest_journal": journal.to_dict() if journal else {},
		"legacy_quest": {
			"state": int(quest_manager.current_quest.current_state) if quest_manager and quest_manager.current_quest else 0,
			"current_amount": int(quest_manager.current_quest.current_amount) if quest_manager and quest_manager.current_quest else 0
		},
		"killed_enemy_ids": quest_manager._killed_enemy_ids.duplicate() if quest_manager else []
	}

static func apply(world: Node, data: Dictionary) -> bool:
	if world == null or data.is_empty():
		return false
	var player := world.get_node_or_null("Player") as Player
	var quest_manager := world.get_node_or_null("QuestManager") as QuestManager
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
	if journal and data.get("quest_journal", {}) is Dictionary:
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

	if quest_manager:
		quest_manager.gold = saved_gold
		quest_manager.gold_changed.emit(quest_manager.gold)
		var legacy_quest: Dictionary = data.get("legacy_quest", {})
		if quest_manager.current_quest and legacy_quest is Dictionary:
			var state: int = clampi(int(legacy_quest.get("state", 0)), 0, 3)
			quest_manager.current_quest.current_state = state as QuestData.State
			quest_manager.current_quest.current_amount = clamp(
				int(legacy_quest.get("current_amount", 0)),
				0,
				quest_manager.current_quest.target_amount
			)
		var killed = data.get("killed_enemy_ids", [])
		if killed is Array:
			quest_manager._killed_enemy_ids.assign(killed)
	return true

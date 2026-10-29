extends SceneTree

class FakeEnemy extends Node:
	var enemy_type_id: String = ""
	var enemy_id: String = ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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
		return

	for definition in ContentRegistry.catalog().quests:
		if definition == null:
			continue
		var preview := definition.format_dialogue(definition.active_dialogue, 1)
		for line in preview:
			if "{" in line or "}" in line:
				_fail("Dialogue còn token chưa thay thế: " + definition.quest_id)
				return
		if not journal.start_quest(definition.quest_id):
			_fail("Không start được quest: " + definition.quest_id)
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
				return
			journal.update_item_collection(inventory)
		if journal.get_quest_state(definition.quest_id) != QuestDefinition.State.READY_TO_TURN_IN:
			_fail("Quest không đạt READY_TO_TURN_IN: " + definition.quest_id)
			return

	print("QUEST_CATALOG_OK quests=%d" % ContentRegistry.catalog().quests.size())
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

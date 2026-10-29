class_name QuestActionService
extends RefCounted

static func execute(action: String, scene: Node) -> Dictionary:
	if action.is_empty() or action == "none" or scene == null:
		return {"handled": false}
	var quest_manager := scene.get_node_or_null("QuestManager") as QuestManager
	var player := scene.get_node_or_null("Player") as Player
	if player == null and scene.get_tree():
		var players = scene.get_tree().get_nodes_in_group(GameGroups.PLAYERS)
		if not players.is_empty():
			player = players[0] as Player

	if action.begins_with("start_quest:"):
		var quest_id := action.trim_prefix("start_quest:")
		var success := player != null and player.quest_journal_component != null and player.quest_journal_component.start_quest(quest_id)
		return {"handled": true, "success": success, "refresh_journal": success, "message": "Đã nhận nhiệm vụ mới!" if success else "Không thể nhận nhiệm vụ."}

	if action.begins_with("complete_quest:"):
		var quest_id := action.trim_prefix("complete_quest:")
		if player == null or player.quest_journal_component == null:
			return {"handled": true, "success": false, "message": "Không tìm thấy dữ liệu nhiệm vụ."}
		var result := player.quest_journal_component.turn_in_quest(quest_id, player.inventory_component, quest_manager)
		if bool(result.get("success", false)):
			SaveManager.save_game(scene)
			return {"handled": true, "success": true, "refresh_journal": true, "message": "Đã hoàn thành nhiệm vụ và nhận thưởng!"}
		return {"handled": true, "success": false, "message": str(result.get("reason", "Không thể hoàn thành nhiệm vụ."))}

	if quest_manager == null:
		return {"handled": false}
	if action == "start_quest":
		var started := quest_manager.start_quest()
		return {"handled": true, "success": started}
	if action == "complete_quest":
		var health := player.health_component if player else null
		var completed := quest_manager.complete_quest(health)
		if completed and player and player.progression_component:
			player.progression_component.add_exp(ExpDatabase.get_quest_exp("quest_tutorial"), "quest:quest_tutorial")
			SaveManager.save_game(scene)
		return {"handled": true, "success": completed}
	return {"handled": false}

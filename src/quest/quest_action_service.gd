class_name QuestActionService
extends RefCounted

static func execute(action: String, scene: Node) -> Dictionary:
	if action.is_empty() or action == "none" or scene == null:
		return {"handled": false}
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
		var result := player.quest_journal_component.turn_in_quest(quest_id, player.inventory_component)
		if bool(result.get("success", false)):
			SaveManager.save_game(scene)
			return {"handled": true, "success": true, "refresh_journal": true, "message": "Đã hoàn thành nhiệm vụ và nhận thưởng!"}
		return {"handled": true, "success": false, "message": str(result.get("reason", "Không thể hoàn thành nhiệm vụ."))}

	if action == "start_quest":
		var started := false
		if player and player.quest_journal_component:
			started = player.quest_journal_component.start_quest("quest_noctis_purify")
		return {"handled": true, "success": started}

	if action == "complete_quest":
		if player and player.quest_journal_component:
			var result := player.quest_journal_component.turn_in_quest("quest_noctis_purify", player.inventory_component)
			if bool(result.get("success", false)):
				SaveManager.save_game(scene)
				return {"handled": true, "success": true, "refresh_journal": true, "message": "Đã hoàn thành nhiệm vụ và nhận thưởng!"}
			return {"handled": true, "success": false, "message": str(result.get("reason", "Không thể hoàn thành nhiệm vụ."))}
		return {"handled": true, "success": false}

	return {"handled": false}

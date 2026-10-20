class_name SaveManager
extends RefCounted

## Hệ thống Lưu & Tải Tiến trình (Save/Load System) cho NOCTELYRA (M3)
## Lưu vào user://noctelyra_slot1.json với cơ chế ghi tạm nguyên tử (Atomic write) và kiểm tra toàn vẹn.

const SAVE_PATH: String = "user://noctelyra_slot1.json"
const TMP_PATH: String = "user://noctelyra_slot1.json.tmp"
const CURRENT_VERSION: String = "1.0.0"

static var should_load_on_start: bool = false

static func has_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	var test_json := JSON.new()
	var err := test_json.parse(text)
	if err != OK or not (test_json.data is Dictionary):
		return false
	var dict: Dictionary = test_json.data
	return dict.has("save_version")

static func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var err := DirAccess.remove_absolute(SAVE_PATH)
		return err == OK
	return true

static func save_game(world: Node) -> bool:
	if world == null:
		return false

	var player := world.get_node_or_null("Player") as Player
	var quest_mgr := world.get_node_or_null("QuestManager") as QuestManager
	var ui := world.get_node_or_null("GameUI") as GameUI

	if player == null or quest_mgr == null:
		return false

	var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
	var p_inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
	var p_eq := player.get_node_or_null("EquipmentComponent") as EquipmentComponent

	var save_data: Dictionary = {
		"save_version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {
			"position_x": player.global_position.x,
			"position_y": player.global_position.y,
			"current_health": clamp(p_health.current_health, 0.0, p_health.max_health) if p_health else 100.0,
			"current_mana": clamp(p_health.current_mana, 0.0, p_health.max_mana) if p_health else 60.0
		},
		"gold": max(0, quest_mgr.gold),
		"inventory": p_inv.to_dict() if p_inv else [],
		"equipment": p_eq.to_dict() if p_eq else {},
		"quest": {
			"state": int(quest_mgr.current_quest.current_state) if quest_mgr.current_quest else 0,
			"current_amount": int(quest_mgr.current_quest.current_amount) if quest_mgr.current_quest else 0
		},
		"defeated_enemy_ids": world.get("defeated_enemy_ids") if "defeated_enemy_ids" in world else []
	}

	var json_str := JSON.stringify(save_data, "\t")

	# 1. Ghi an toàn vào file tạm trước
	var tmp_file := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if tmp_file == null:
		push_error("Không thể tạo file lưu tạm: " + TMP_PATH)
		return false

	tmp_file.store_string(json_str)
	tmp_file.flush()
	tmp_file.close()

	# 2. Thay thế file chính bằng file tạm
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var rename_err := DirAccess.rename_absolute(TMP_PATH, SAVE_PATH)
	if rename_err != OK:
		# Fallback: sao chép nếu rename thất bại
		var copy_err := DirAccess.copy_absolute(TMP_PATH, SAVE_PATH)
		DirAccess.remove_absolute(TMP_PATH)
		if copy_err != OK:
			push_error("Lỗi khi hoàn tất ghi file save!")
			return false

	if ui:
		ui.show_notification("Đã lưu tiến trình game thành công!")

	return true

static func load_game(world: Node) -> bool:
	if world == null or not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()

	var test_json := JSON.new()
	var err := test_json.parse(text)
	if err != OK or not (test_json.data is Dictionary):
		push_warning("File save hỏng hoặc định dạng JSON sai, bỏ qua để bảo vệ game.")
		return false

	var data: Dictionary = test_json.data
	var version: String = str(data.get("save_version", ""))
	if version.is_empty():
		push_warning("Thiếu phiên bản save_version.")
		return false

	var player := world.get_node_or_null("Player") as Player
	var quest_mgr := world.get_node_or_null("QuestManager") as QuestManager
	var ui := world.get_node_or_null("GameUI") as GameUI

	# 1. Khôi phục Player (Vị trí & Chỉ số)
	if player and data.has("player"):
		var p_data: Dictionary = data["player"]
		var px: float = float(p_data.get("position_x", player.global_position.x))
		var py: float = float(p_data.get("position_y", player.global_position.y))
		player.global_position = Vector2(px, py)

		var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if p_health:
			p_health.current_health = float(p_data.get("current_health", 100.0))
			p_health.current_mana = float(p_data.get("current_mana", 60.0))
			p_health.emit_signal("health_changed", p_health.current_health, p_health.max_health)
			p_health.emit_signal("mana_changed", p_health.current_mana, p_health.max_mana)

	# 2. Khôi phục Inventory & Equipment
	if player:
		var p_inv := player.get_node_or_null("InventoryComponent") as InventoryComponent
		if p_inv and data.has("inventory") and (data["inventory"] is Array):
			p_inv.load_from_dict(data["inventory"])

		var p_eq := player.get_node_or_null("EquipmentComponent") as EquipmentComponent
		if p_eq and data.has("equipment") and (data["equipment"] is Dictionary):
			p_eq.load_from_dict(data["equipment"])

	# 3. Khôi phục Vàng & Nhiệm vụ
	if quest_mgr:
		var saved_gold: int = int(data.get("gold", 0))
		quest_mgr.gold = max(0, saved_gold)
		quest_mgr.emit_signal("gold_changed", quest_mgr.gold)

		if data.has("quest") and (data["quest"] is Dictionary):
			var q_data: Dictionary = data["quest"]
			var q_state: int = int(q_data.get("state", 0))
			var q_amt: int = int(q_data.get("current_amount", 0))
			if quest_mgr.current_quest:
				quest_mgr.current_quest.current_state = q_state as QuestData.State
				quest_mgr.current_quest.current_amount = clamp(q_amt, 0, quest_mgr.current_quest.target_amount)
				if ui:
					ui.update_quest_info(quest_mgr.current_quest)
					ui.update_gold(quest_mgr.gold)

	# 4. Khôi phục danh sách quái đã bị tiêu diệt
	var defeated: Array = data.get("defeated_enemy_ids", [])
	if "defeated_enemy_ids" in world:
		world.set("defeated_enemy_ids", defeated.duplicate())

	# Xóa bỏ các quái đã bị tiêu diệt khỏi Scene Tree để không respawn sai
	var enemies := world.get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy and not e.enemy_id.is_empty():
			if e.enemy_id in defeated:
				e.queue_free()

	if ui:
		ui.show_notification("Đã tải bản lưu thành công!")

	return true

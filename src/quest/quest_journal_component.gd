class_name QuestJournalComponent
extends Node

## Nhật ký Nhiệm vụ Mở rộng (Quest Journal Component) cho NOCTELYRA (Milestone M7)
## Quản lý trạng thái và tiến độ các nhiệm vụ phụ của Player (Kaelis, Rhaek,...),
## lọc quái vật theo chủng loại chính xác, theo dõi vật phẩm túi đồ,
## và trao thưởng an toàn kèm bảo vệ chống đếm trùng hoặc nhận thưởng hai lần.

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, current_amount: int, target_amount: int, state: int)
signal quest_ready(quest_id: String)
signal quest_completed(quest_id: String)
signal journal_changed()

const State = QuestDefinition.State

# Dữ liệu nội bộ lưu trữ theo quest_id:
# {
#   "state": int,
#   "current_amount": int,
#   "reward_claimed": bool,
#   "counted_enemy_ids": Array[String]
# }
var _quests: Dictionary = {}

func _ready() -> void:
	_ensure_default_quests()

func _ensure_default_quests() -> void:
	if not _quests.has("quest_elyndra_cleansing"):
		_quests["quest_elyndra_cleansing"] = {
			"state": State.NOT_STARTED,
			"current_amount": 0,
			"reward_claimed": false,
			"counted_enemy_ids": []
		}
	if not _quests.has("quest_vharok_embers"):
		_quests["quest_vharok_embers"] = {
			"state": State.NOT_STARTED,
			"current_amount": 0,
			"reward_claimed": false,
			"counted_enemy_ids": []
		}

func get_quest_state(quest_id: String) -> int:
	_ensure_default_quests()
	if _quests.has(quest_id):
		return int(_quests[quest_id].get("state", State.NOT_STARTED))
	return State.NOT_STARTED

func get_quest_progress(quest_id: String) -> int:
	_ensure_default_quests()
	if _quests.has(quest_id):
		return int(_quests[quest_id].get("current_amount", 0))
	return 0

func is_reward_claimed(quest_id: String) -> bool:
	_ensure_default_quests()
	if _quests.has(quest_id):
		return bool(_quests[quest_id].get("reward_claimed", false))
	return false

func start_quest(quest_id: String) -> bool:
	_ensure_default_quests()
	if not _quests.has(quest_id):
		return false

	var q: Dictionary = _quests[quest_id]
	if q.get("state", State.NOT_STARTED) != State.NOT_STARTED:
		return false

	q["state"] = State.ACTIVE
	q["current_amount"] = 0
	q["counted_enemy_ids"] = []

	var def := QuestDefinition.get_definition(quest_id)
	emit_signal("quest_started", quest_id)
	emit_signal("quest_updated", quest_id, 0, def.target_amount, State.ACTIVE)
	emit_signal("journal_changed")
	return true

func register_enemy_kill(enemy: Node) -> void:
	if enemy == null:
		return
	_ensure_default_quests()

	var enemy_type: String = ""
	if "enemy_type_id" in enemy:
		enemy_type = str(enemy.enemy_type_id)
	elif enemy.has_method("get") and enemy.get("enemy_type_id") != null:
		enemy_type = str(enemy.get("enemy_type_id"))

	var enemy_id_str: String = ""
	if "enemy_id" in enemy and not str(enemy.enemy_id).is_empty():
		enemy_id_str = str(enemy.enemy_id)
	else:
		enemy_id_str = "inst_" + str(enemy.get_instance_id())

	# 1. Kiểm tra nhiệm vụ Kaelis: Thanh Lọc Tinh Mạch (chỉ tính quái corrupted_mooncap)
	if enemy_type == "corrupted_mooncap":
		var q_id := "quest_elyndra_cleansing"
		var q: Dictionary = _quests[q_id]
		if q.get("state") == State.ACTIVE:
			var counted: Array = q.get("counted_enemy_ids", [])
			if not enemy_id_str in counted:
				counted.append(enemy_id_str)
				q["counted_enemy_ids"] = counted
				q["current_amount"] = q.get("current_amount", 0) + 1
				var def := QuestDefinition.get_definition(q_id)
				var cur: int = q["current_amount"]

				if cur >= def.target_amount:
					q["state"] = State.READY_TO_TURN_IN
					emit_signal("quest_ready", q_id)
				emit_signal("quest_updated", q_id, cur, def.target_amount, q["state"])
				emit_signal("journal_changed")

func update_item_collection(inventory: InventoryComponent) -> void:
	if inventory == null:
		return
	_ensure_default_quests()

	# Cập nhật nhiệm vụ Rhaek: Tàn Hỏa Hắc Nham (thu thập ember_core)
	var q_id := "quest_vharok_embers"
	var q: Dictionary = _quests[q_id]
	var st: int = q.get("state", State.NOT_STARTED)

	if st == State.ACTIVE or st == State.READY_TO_TURN_IN:
		var def := QuestDefinition.get_definition(q_id)
		var count: int = inventory.get_item_count(def.target_id)
		q["current_amount"] = count

		var prev_state := st
		if count >= def.target_amount:
			q["state"] = State.READY_TO_TURN_IN
			if prev_state != State.READY_TO_TURN_IN:
				emit_signal("quest_ready", q_id)
		else:
			q["state"] = State.ACTIVE

		emit_signal("quest_updated", q_id, count, def.target_amount, q["state"])
		emit_signal("journal_changed")

func can_turn_in(quest_id: String, inventory: InventoryComponent = null) -> bool:
	_ensure_default_quests()
	if not _quests.has(quest_id):
		return false
	var q: Dictionary = _quests[quest_id]
	if q.get("state") != State.READY_TO_TURN_IN:
		return false

	var def := QuestDefinition.get_definition(quest_id)
	if def.quest_type == QuestDefinition.QuestType.COLLECT_ITEMS:
		if inventory == null:
			return false
		if inventory.get_item_count(def.target_id) < def.target_amount:
			return false

	return true

func turn_in_quest(quest_id: String, inventory: InventoryComponent, quest_manager: QuestManager) -> Dictionary:
	_ensure_default_quests()
	if not can_turn_in(quest_id, inventory):
		return {"success": false, "reason": "Chưa đủ điều kiện hoàn thành!"}

	var q: Dictionary = _quests[quest_id]
	if q.get("reward_claimed", false):
		return {"success": false, "reason": "Phần thưởng đã nhận trước đó!"}

	var def := QuestDefinition.get_definition(quest_id)

	# 1. Trừ vật phẩm yêu cầu trong túi đồ nếu là nhiệm vụ thu thập
	if def.quest_type == QuestDefinition.QuestType.COLLECT_ITEMS and inventory:
		inventory.remove_item_by_id(def.target_id, def.target_amount)

	# 2. Đánh dấu hoàn thành
	q["state"] = State.COMPLETED
	q["reward_claimed"] = true

	# 3. Trao thưởng Vàng
	if quest_manager and def.reward_gold > 0:
		quest_manager.gold += def.reward_gold
		quest_manager.emit_signal("gold_changed", quest_manager.gold)

	# 4. Trao thưởng Vật phẩm
	if inventory:
		for item_rew in def.reward_items:
			var i_id: String = str(item_rew.get("item_id", ""))
			var amt: int = int(item_rew.get("amount", 1))
			if not i_id.is_empty():
				if inventory.can_add_item(i_id, amt):
					inventory.add_item(i_id, amt)
				else:
					# Túi đồ đầy: sinh drop pickup an toàn tại vị trí Player
					_spawn_reward_drop(i_id, amt, inventory.get_parent())

	emit_signal("quest_completed", quest_id)
	emit_signal("journal_changed")

	return {
		"success": true,
		"quest_id": quest_id,
		"reward_gold": def.reward_gold,
		"reward_items": def.reward_items
	}

func _spawn_reward_drop(item_id: String, amount: int, owner_node: Node) -> void:
	if owner_node == null:
		return
	var parent_world = owner_node.get_parent()
	if parent_world == null:
		return

	var p_scene: PackedScene = load("res://src/loot/item_pickup.tscn")
	if p_scene:
		var p := p_scene.instantiate() as ItemPickup
		if p:
			p.item_id = item_id
			p.amount = amount
			p.is_dynamic = true
			p.pickup_id = "quest_reward_" + item_id + "_" + str(Time.get_ticks_usec())
			p.global_position = owner_node.global_position if "global_position" in owner_node else Vector2(300, 630)
			parent_world.add_child.call_deferred(p)

func to_dict() -> Dictionary:
	_ensure_default_quests()
	return _quests.duplicate(true)

func from_dict(data: Dictionary) -> void:
	_ensure_default_quests()
	if data == null or data.is_empty():
		return

	for k in data.keys():
		if data[k] is Dictionary:
			var q_data: Dictionary = data[k]
			_quests[k] = {
				"state": int(q_data.get("state", State.NOT_STARTED)),
				"current_amount": int(q_data.get("current_amount", 0)),
				"reward_claimed": bool(q_data.get("reward_claimed", false)),
				"counted_enemy_ids": q_data.get("counted_enemy_ids", []).duplicate()
			}
	emit_signal("journal_changed")

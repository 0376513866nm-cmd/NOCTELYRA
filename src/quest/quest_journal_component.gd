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
var _kill_history: Dictionary = {} # { "corrupted_mooncap": ["elyndra_mooncap_1", ...] }

func _ready() -> void:
	_ensure_default_quests()
	var p := get_parent()
	if p:
		var inv := p.get_node_or_null("InventoryComponent") as InventoryComponent
		if inv and not inv.inventory_updated.is_connected(_on_inventory_updated):
			inv.inventory_updated.connect(_on_inventory_updated)

func _on_inventory_updated() -> void:
	var p := get_parent()
	if p:
		var inv := p.get_node_or_null("InventoryComponent") as InventoryComponent
		if inv:
			update_item_collection(inv)

func _ensure_default_quests() -> void:
	for definition in ContentRegistry.catalog().quests:
		if definition and not _quests.has(definition.quest_id):
			_quests[definition.quest_id] = {
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

	# 1. Nếu là nhiệm vụ diệt quái: đồng bộ số quái đã từng diệt trước đó (chống kẹt do diệt quái sớm)
	if def.quest_type == QuestDefinition.QuestType.KILL_ENEMY_TYPE:
		_sync_prior_kills(quest_id, def)
	# 2. Nếu là nhiệm vụ thu thập: đồng bộ vật phẩm sẵn có trong túi đồ
	elif def.quest_type == QuestDefinition.QuestType.COLLECT_ITEMS:
		var p := get_parent()
		var inv: InventoryComponent = p.get_node_or_null("InventoryComponent") as InventoryComponent if p else null
		if inv:
			update_item_collection(inv)

	emit_signal("quest_started", quest_id)
	emit_signal("quest_updated", quest_id, q["current_amount"], def.target_amount, q["state"])
	emit_signal("journal_changed")
	return true

func _sync_prior_kills(quest_id: String, def: QuestDefinition) -> void:
	if not _quests.has(quest_id):
		return
	var q: Dictionary = _quests[quest_id]
	var counted: Array = q.get("counted_enemy_ids", [])

	# 1. Lấy từ lịch sử kill của component
	var prior_kills: Array = _kill_history.get(def.target_id, [])
	for kid in prior_kills:
		var skid := str(kid)
		if not skid in counted:
			counted.append(skid)

	# 2. Lấy từ danh sách quái đã hạ gục của map hiện tại (trường hợp load save)
	if get_tree() and get_tree().current_scene:
		var scene = get_tree().current_scene
		if "defeated_enemy_ids" in scene and (scene.defeated_enemy_ids is Array):
			for did in scene.defeated_enemy_ids:
				var sdid := str(did)
				if def.target_id == "corrupted_mooncap" and sdid.find("mooncap") != -1:
					if not sdid in counted:
						counted.append(sdid)
						if not _kill_history.has("corrupted_mooncap"):
							_kill_history["corrupted_mooncap"] = []
						if not sdid in _kill_history["corrupted_mooncap"]:
							_kill_history["corrupted_mooncap"].append(sdid)

	q["counted_enemy_ids"] = counted
	q["current_amount"] = clamp(counted.size(), 0, def.target_amount)
	if q["current_amount"] >= def.target_amount:
		q["state"] = State.READY_TO_TURN_IN
		emit_signal("quest_ready", quest_id)

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

	# Luôn lưu vào lịch sử diệt quái (kể cả khi chưa nhận quest)
	if not _kill_history.has(enemy_type):
		_kill_history[enemy_type] = []
	if not enemy_id_str in _kill_history[enemy_type]:
		_kill_history[enemy_type].append(enemy_id_str)

	for definition in ContentRegistry.catalog().quests:
		if definition == null or definition.quest_type != QuestDefinition.QuestType.KILL_ENEMY_TYPE:
			continue
		if definition.target_id != enemy_type:
			continue
		var quest: Dictionary = _quests.get(definition.quest_id, {})
		if quest.get("state", State.NOT_STARTED) != State.ACTIVE:
			continue
		var counted: Array = quest.get("counted_enemy_ids", [])
		if enemy_id_str in counted:
			continue
		counted.append(enemy_id_str)
		quest["counted_enemy_ids"] = counted
		var current := mini(counted.size(), definition.target_amount)
		quest["current_amount"] = current
		if current >= definition.target_amount:
			quest["state"] = State.READY_TO_TURN_IN
			quest_ready.emit(definition.quest_id)
		quest_updated.emit(definition.quest_id, current, definition.target_amount, quest["state"])
		journal_changed.emit()

func update_item_collection(inventory: InventoryComponent) -> void:
	if inventory == null:
		return
	_ensure_default_quests()

	for definition in ContentRegistry.catalog().quests:
		if definition == null or definition.quest_type != QuestDefinition.QuestType.COLLECT_ITEMS:
			continue
		var quest: Dictionary = _quests.get(definition.quest_id, {})
		var previous_state := int(quest.get("state", State.NOT_STARTED))
		if previous_state not in [State.ACTIVE, State.READY_TO_TURN_IN]:
			continue
		var count := inventory.get_item_count(definition.target_id)
		var previous_count := int(quest.get("current_amount", -1))
		var new_state := State.READY_TO_TURN_IN if count >= definition.target_amount else State.ACTIVE
		if count == previous_count and new_state == previous_state:
			continue
		quest["current_amount"] = count
		quest["state"] = new_state
		if new_state == State.READY_TO_TURN_IN and previous_state != State.READY_TO_TURN_IN:
			quest_ready.emit(definition.quest_id)
		quest_updated.emit(definition.quest_id, count, definition.target_amount, new_state)
		journal_changed.emit()

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

	# Kiểm tra túi đồ có đủ chỗ chứa toàn bộ phần thưởng không
	if inventory != null and def.reward_items.size() > 0:
		var items_to_remove: Array = []
		if def.quest_type == QuestDefinition.QuestType.COLLECT_ITEMS:
			items_to_remove.append({"item_id": def.target_id, "amount": def.target_amount})
		if not inventory.can_receive_items(def.reward_items, items_to_remove):
			return false

	return true

func turn_in_quest(quest_id: String, inventory: InventoryComponent, quest_manager: QuestManager) -> Dictionary:
	_ensure_default_quests()
	if not _quests.has(quest_id):
		return {"success": false, "reason": "Nhiệm vụ không tồn tại!"}

	var q: Dictionary = _quests[quest_id]
	if q.get("state") != State.READY_TO_TURN_IN:
		return {"success": false, "reason": "Chưa đủ điều kiện hoàn thành!"}

	if q.get("reward_claimed", false):
		return {"success": false, "reason": "Phần thưởng đã nhận trước đó!"}

	var def := QuestDefinition.get_definition(quest_id)

	# Kiểm tra túi đồ trước: nếu không đủ chỗ chứa phần thưởng, hủy giao dịch an toàn
	if inventory != null and def.reward_items.size() > 0:
		var items_to_remove: Array = []
		if def.quest_type == QuestDefinition.QuestType.COLLECT_ITEMS:
			items_to_remove.append({"item_id": def.target_id, "amount": def.target_amount})
		if not inventory.can_receive_items(def.reward_items, items_to_remove):
			return {"success": false, "reason": "Túi đồ đã đầy! Hãy dọn chỗ trống trước khi trả nhiệm vụ."}

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
				inventory.add_item(i_id, amt)

	# 5. Trao thưởng EXP (Milestone M8)
	var exp_gained: int = def.reward_exp if def.reward_exp > 0 else ExpDatabase.get_quest_exp(quest_id)
	var parent_player := get_parent() as Player
	if parent_player and parent_player.progression_component:
		parent_player.progression_component.add_exp(exp_gained, "quest:" + quest_id)

	emit_signal("quest_completed", quest_id)
	emit_signal("journal_changed")

	return {
		"success": true,
		"quest_id": quest_id,
		"reward_gold": def.reward_gold,
		"reward_exp": exp_gained,
		"reward_items": def.reward_items
	}

func to_dict() -> Dictionary:
	_ensure_default_quests()
	var d := _quests.duplicate(true)
	d["_kill_history"] = _kill_history.duplicate(true)
	return d

func from_dict(data: Dictionary) -> void:
	_ensure_default_quests()
	if data == null or data.is_empty():
		return

	if data.has("_kill_history") and (data["_kill_history"] is Dictionary):
		_kill_history = data["_kill_history"].duplicate(true)

	for k in data.keys():
		if k == "_kill_history":
			continue
		if data[k] is Dictionary:
			var q_data: Dictionary = data[k]
			_quests[k] = {
				"state": int(q_data.get("state", State.NOT_STARTED)),
				"current_amount": int(q_data.get("current_amount", 0)),
				"reward_claimed": bool(q_data.get("reward_claimed", false)),
				"counted_enemy_ids": q_data.get("counted_enemy_ids", []).duplicate()
			}
	emit_signal("journal_changed")

class_name InventoryComponent
extends Node

## Quản lý dữ liệu túi đồ (Inventory) 16 ô cho NOCTELYRA (M3)
## Hoàn toàn tách biệt khỏi logic giao diện (UI)

signal inventory_updated()
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal item_used(item_id: String)

@export var max_slots: int = 16

# Mảng chứa Dictionary các ô đồ: [{ "item_id": String, "amount": int }, ...]
var slots: Array[Dictionary] = []

func _ready() -> void:
	if slots.is_empty():
		_initialize_slots()

func _initialize_slots() -> void:
	slots.clear()
	for i in range(max_slots):
		slots.append({ "item_id": "", "amount": 0 })

func clear() -> void:
	_initialize_slots()

func get_slot(index: int) -> Dictionary:
	if index >= 0 and index < slots.size():
		return slots[index]
	return { "item_id": "", "amount": 0 }

func is_slot_empty(index: int) -> bool:
	var s := get_slot(index)
	return str(s.get("item_id", "")).is_empty() or int(s.get("amount", 0)) <= 0

func can_add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not ItemDatabase.has_item(item_id):
		return false
	var item_def := ItemDatabase.get_item(item_id)
	var needed := amount

	# Kiểm tra các ô hiện có cùng loại nếu có thể stack
	if item_def.max_stack > 1:
		for s in slots:
			var s_id: String = str(s.get("item_id", ""))
			var s_amount: int = int(s.get("amount", 0))
			if s_id == item_id and s_amount < item_def.max_stack:
				var space: int = item_def.max_stack - s_amount
				needed -= space
				if needed <= 0:
					return true

	# Kiểm tra các ô trống còn lại
	for s in slots:
		var s_id: String = str(s.get("item_id", ""))
		var s_amount: int = int(s.get("amount", 0))
		if s_id.is_empty() or s_amount <= 0:
			needed -= item_def.max_stack
			if needed <= 0:
				return true

	return false

func add_item(item_id: String, amount: int = 1) -> int:
	if amount <= 0 or not ItemDatabase.has_item(item_id):
		return amount
	var item_def := ItemDatabase.get_item(item_id)
	var remaining := amount

	# 1. Điền vào các ô cùng loại chưa đầy nếu stack được
	if item_def.max_stack > 1:
		for i in range(slots.size()):
			if remaining <= 0:
				break
			var s := slots[i]
			if s.item_id == item_id and s.amount < item_def.max_stack:
				var can_take: int = min(remaining, item_def.max_stack - s.amount)
				s.amount += can_take
				remaining -= can_take

	# 2. Điền vào các ô trống mới
	for i in range(slots.size()):
		if remaining <= 0:
			break
		var s := slots[i]
		if s.item_id.is_empty() or s.amount <= 0:
			var can_take: int = min(remaining, item_def.max_stack)
			s.item_id = item_id
			s.amount = can_take
			remaining -= can_take

	var added_total: int = amount - remaining
	if added_total > 0:
		emit_signal("item_added", item_id, added_total)
		emit_signal("inventory_updated")

	return remaining

func remove_item_at(slot_idx: int, amount: int = 1) -> bool:
	if slot_idx < 0 or slot_idx >= slots.size() or amount <= 0:
		return false
	var s := slots[slot_idx]
	if s.item_id.is_empty() or s.amount <= 0:
		return false

	var item_id: String = s.item_id
	var to_remove: int = min(amount, s.amount)
	s.amount -= to_remove

	if s.amount <= 0:
		s.item_id = ""
		s.amount = 0

	emit_signal("item_removed", item_id, to_remove)
	emit_signal("inventory_updated")
	return true

func remove_item_by_id(item_id: String, amount: int = 1) -> bool:
	if amount <= 0 or not has_item(item_id, amount):
		return false
	var remaining := amount
	for i in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var s := slots[i]
		if s.item_id == item_id:
			var to_remove: int = min(remaining, s.amount)
			s.amount -= to_remove
			remaining -= to_remove
			if s.amount <= 0:
				s.item_id = ""
				s.amount = 0

	emit_signal("item_removed", item_id, amount)
	emit_signal("inventory_updated")
	return true

func remove_item(item_id: String, amount: int = 1) -> bool:
	return remove_item_by_id(item_id, amount)

func has_item(item_id: String, amount: int = 1) -> bool:
	var count := get_item_count(item_id)
	return count >= amount

func get_item_count(item_id: String) -> int:
	var count: int = 0
	for s in slots:
		if s.item_id == item_id:
			count += s.amount
	return count

func use_item_at(slot_idx: int, player: Player) -> bool:
	if slot_idx < 0 or slot_idx >= slots.size() or player == null:
		return false
	var s := slots[slot_idx]
	if s.item_id.is_empty() or s.amount <= 0:
		return false

	var item_def := ItemDatabase.get_item(s.item_id)
	if item_def == null or item_def.item_type != ItemDefinition.ItemType.CONSUMABLE:
		return false

	# Kiểm tra trạng thái sống của Player
	var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
	if p_health == null or not p_health.is_alive():
		return false # Không thể sử dụng bình khi đã chết

	# Áp dụng hiệu ứng
	var used := false
	if item_def.use_effect.has("heal_hp"):
		var heal_val: float = float(item_def.use_effect["heal_hp"])
		p_health.current_health = min(p_health.max_health, p_health.current_health + heal_val)
		p_health.emit_signal("health_changed", p_health.current_health, p_health.max_health)
		used = true

	if used:
		var item_id: String = s.item_id
		remove_item_at(slot_idx, 1)
		emit_signal("item_used", item_id)
		return true

	return false

func to_dict() -> Array:
	var arr: Array = []
	for s in slots:
		arr.append({
			"item_id": s.item_id,
			"amount": s.amount
		})
	return arr

func load_from_dict(arr: Array) -> void:
	_initialize_slots()
	for i in range(min(arr.size(), max_slots)):
		var entry = arr[i]
		if entry is Dictionary:
			var id: String = str(entry.get("item_id", ""))
			var amt: int = int(entry.get("amount", 0))
			if not id.is_empty() and amt > 0 and ItemDatabase.has_item(id):
				var def := ItemDatabase.get_item(id)
				slots[i].item_id = id
				slots[i].amount = clamp(amt, 1, def.max_stack)
			else:
				slots[i].item_id = ""
				slots[i].amount = 0
	emit_signal("inventory_updated")

class_name WalletComponent
extends Node

## Thành phần Quản lý Tiền tệ (Wallet Component) cho Player (M8 Stage 2)
## Đóng vai trò Single Source of Truth cho số vàng (gold) của người chơi.

signal gold_changed(new_gold: int)

@export var gold: int = 0:
	set(val):
		var clamped: int = maxi(0, val)
		if clamped != gold:
			gold = clamped
			emit_signal("gold_changed", gold)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	self.gold += amount

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	if gold >= amount:
		self.gold -= amount
		return true
	return false

func set_gold(amount: int) -> void:
	self.gold = amount

func get_gold() -> int:
	return gold

func to_dict() -> Dictionary:
	return {"gold": gold}

func from_dict(data: Dictionary) -> void:
	set_gold(int(data.get("gold", 0)))

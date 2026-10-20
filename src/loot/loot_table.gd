class_name LootTable
extends Resource

## Bảng rơi vật phẩm (Loot Table) cho Enemy trong NOCTELYRA (M3)
## Tách biệt hoàn toàn khỏi logic AI của Enemy.

# Mảng các quy tắc rơi: [{ "item_id": String, "chance": float, "min_amount": int, "max_amount": int }]
@export var drop_entries: Array[Dictionary] = [
	{
		"item_id": "mana_shard",
		"chance": 1.0, # 100% tỷ lệ rơi để kiểm thử nghiệm thu M3
		"min_amount": 1,
		"max_amount": 1
	}
]

func roll_drops() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in drop_entries:
		var chance: float = float(entry.get("chance", 1.0))
		if randf() <= chance:
			var min_amt: int = int(entry.get("min_amount", 1))
			var max_amt: int = int(entry.get("max_amount", 1))
			var amt := randi_range(min_amt, max_amt)
			if amt > 0:
				result.append({
					"item_id": str(entry.get("item_id", "mana_shard")),
					"amount": amt
				})
	return result

func spawn_loot(pos: Vector2, parent_node: Node) -> void:
	if parent_node == null:
		return
	var pickup_scene: PackedScene = preload("res://src/loot/item_pickup.tscn")
	var items := roll_drops()
	for i in range(items.size()):
		var item_info := items[i]
		var pickup := pickup_scene.instantiate() as ItemPickup
		pickup.item_id = item_info["item_id"]
		pickup.amount = item_info["amount"]
		pickup.is_dynamic = true
		pickup.pickup_id = "drop_" + str(Time.get_ticks_usec()) + "_" + str(randi() % 100000)
		pickup.global_position = pos + Vector2(float(i * 24 - (items.size() - 1) * 12), 0.0)
		parent_node.add_child.call_deferred(pickup)

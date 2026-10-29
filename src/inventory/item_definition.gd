class_name ItemDefinition
extends Resource

## Định nghĩa vật phẩm chuẩn cho NOCTELYRA (Milestone M3)

enum ItemType {
	MATERIAL,
	CONSUMABLE,
	WEAPON,
	ACCESSORY
}

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var icon: Texture2D = null
@export var placeholder_color: Color = Color(0.6, 0.2, 0.9, 1.0)
@export var max_stack: int = 99
@export var sell_value: int = 0
@export var stat_modifiers: Dictionary = {}
@export var use_effect: Dictionary = {}

func get_type_name() -> String:
	match item_type:
		ItemType.MATERIAL: return "Nguyên liệu"
		ItemType.CONSUMABLE: return "Tiêu hao"
		ItemType.WEAPON: return "Vũ khí"
		ItemType.ACCESSORY: return "Phụ kiện"
		_: return "Khác"

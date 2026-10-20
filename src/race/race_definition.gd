class_name RaceDefinition
extends Resource

## Định nghĩa Thuộc tính Chủng tộc (Race Definition) cho NOCTELYRA (Milestone M8)
## Chứa chỉ số cơ bản, tên hiển thị, mô tả lore, ưu/nhược điểm và màu sắc nhận diện.

@export var race_id: String = "human"
@export var display_name: String = "Nhân tộc"
@export var title: String = "Hậu Duệ Ánh Nguyệt"
@export var description: String = ""
@export var pros: String = ""
@export var cons: String = ""

# Chỉ số cơ bản cấp 1
@export var base_health: float = 100.0
@export var base_mana: float = 60.0
@export var base_attack: float = 25.0
@export var base_mana_regen: float = 5.0
@export var base_move_speed: float = 270.0
@export var magic_damage_multiplier: float = 1.0

# Thuộc tính tiện ích tương thích
var max_health: float:
	get: return base_health
var max_mana: float:
	get: return base_mana

# Nhận diện ngoại hình placeholder
@export var theme_color: Color = Color(0.35, 0.65, 1.0, 1.0) # Xanh lam ánh bạc
@export var aura_color: Color = Color(0.5, 0.8, 1.0, 0.4)

class_name ZoneSpawnPoint
extends Node2D

## Điểm xuất hiện người chơi trong khu vực (Milestone M6)
## Cung cấp tọa độ an toàn và hướng quay mặt khi dịch chuyển tới.

@export var spawn_point_id: String = "spawn_default"
@export var facing_direction: int = 1 # 1: Phải, -1: Trái

func _ready() -> void:
	add_to_group(GameGroups.ZONE_SPAWN_POINTS)

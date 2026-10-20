class_name ZoneDefinition
extends RefCounted

## Định nghĩa danh mục và thông số các vùng đất trong NOCTELYRA (Milestone M6)
## Cung cấp metadata, định danh duy nhất và đường dẫn scene chuẩn.

const ZONE_NOCTIS_FOREST: String = "noctis_forest"
const ZONE_ELYNDRA_GLADE: String = "elyndra_glade"
const ZONE_VHAROK_OUTPOST: String = "vharok_outpost"

const ZONES: Dictionary = {
	ZONE_NOCTIS_FOREST: {
		"zone_id": ZONE_NOCTIS_FOREST,
		"display_name": "Rừng Noctis",
		"sub_title": "Bìa Rừng Hắc Nguyệt — Làng Ánh Nguyệt",
		"scene_path": "res://src/world/noctis_forest.tscn",
		"default_spawn": "spawn_default"
	},
	ZONE_ELYNDRA_GLADE: {
		"zone_id": ZONE_ELYNDRA_GLADE,
		"display_name": "Elyndra — Thánh Lâm Tinh Linh",
		"sub_title": "Vùng Đất Thánh Của Tinh Linh Tinh Mạch",
		"scene_path": "res://src/world/elyndra_glade.tscn",
		"default_spawn": "spawn_from_noctis"
	},
	ZONE_VHAROK_OUTPOST: {
		"zone_id": ZONE_VHAROK_OUTPOST,
		"display_name": "Vharok — Tiền Đồn Quỷ tộc",
		"sub_title": "Lãnh Địa Gia Tộc Hắc Nham — Quỷ Tộc Bán Thú",
		"scene_path": "res://src/world/vharok_outpost.tscn",
		"default_spawn": "spawn_from_elyndra"
	}
}

static func is_valid_zone(zone_id: String) -> bool:
	return ZONES.has(zone_id)

static func get_zone_display_name(zone_id: String) -> String:
	if ZONES.has(zone_id):
		return ZONES[zone_id].get("display_name", zone_id)
	return zone_id

static func get_zone_sub_title(zone_id: String) -> String:
	if ZONES.has(zone_id):
		return ZONES[zone_id].get("sub_title", "")
	return ""

static func get_zone_scene_path(zone_id: String) -> String:
	if ZONES.has(zone_id):
		return ZONES[zone_id].get("scene_path", "")
	return "res://src/world/noctis_forest.tscn"

static func get_default_spawn(zone_id: String) -> String:
	if ZONES.has(zone_id):
		return ZONES[zone_id].get("default_spawn", "spawn_default")
	return "spawn_default"

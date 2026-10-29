class_name ZoneDefinition
extends Resource

const ZONE_NOCTIS_FOREST := "noctis_forest"
const ZONE_ELYNDRA_GLADE := "elyndra_glade"
const ZONE_VHAROK_OUTPOST := "vharok_outpost"

@export var zone_id: String = ""
@export var display_name: String = ""
@export var sub_title: String = ""
@export_file("*.tscn") var scene_path: String = ""
@export var default_spawn: String = "spawn_default"

static func is_valid_zone(id: String) -> bool:
	return ContentRegistry.get_zone(id) != null

static func get_zone_display_name(id: String) -> String:
	var definition := ContentRegistry.get_zone(id)
	return definition.display_name if definition else id

static func get_zone_sub_title(id: String) -> String:
	var definition := ContentRegistry.get_zone(id)
	return definition.sub_title if definition else ""

static func get_zone_scene_path(id: String) -> String:
	var definition := ContentRegistry.get_zone(id)
	return definition.scene_path if definition else "res://src/world/noctis_forest.tscn"

static func get_default_spawn(id: String) -> String:
	var definition := ContentRegistry.get_zone(id)
	return definition.default_spawn if definition else "spawn_default"

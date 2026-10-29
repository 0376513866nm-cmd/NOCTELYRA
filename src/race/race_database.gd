class_name RaceDatabase
extends RefCounted

static func initialize() -> void:
	ContentRegistry.catalog()

static func get_race(race_id: String) -> RaceDefinition:
	var definition := ContentRegistry.get_race(race_id)
	if definition:
		return definition
	return ContentRegistry.get_race("human")

static func has_race(race_id: String) -> bool:
	return ContentRegistry.get_race(race_id) != null

static func get_all_races() -> Array[RaceDefinition]:
	return ContentRegistry.catalog().races.duplicate()

static func get_all_race_ids() -> Array[String]:
	var result: Array[String] = []
	for definition in ContentRegistry.catalog().races:
		if definition and not definition.race_id.is_empty():
			result.append(definition.race_id)
	return result

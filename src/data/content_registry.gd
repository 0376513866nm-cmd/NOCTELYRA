class_name ContentRegistry
extends RefCounted

const CATALOG_PATH := "res://src/data/content_catalog.tres"

static var _catalog: ContentCatalog
static var _indexes_ready := false
static var _items_by_id: Dictionary = {}
static var _spells_by_id: Dictionary = {}
static var _races_by_id: Dictionary = {}
static var _quests_by_id: Dictionary = {}
static var _enemies_by_id: Dictionary = {}
static var _zones_by_id: Dictionary = {}

static func catalog() -> ContentCatalog:
	if _catalog == null:
		_catalog = load(CATALOG_PATH) as ContentCatalog
		if _catalog == null:
			push_error("ContentRegistry: không tải được " + CATALOG_PATH)
			_catalog = ContentCatalog.new()
	return _catalog

static func reset_cache() -> void:
	_catalog = null
	_indexes_ready = false
	_items_by_id.clear()
	_spells_by_id.clear()
	_races_by_id.clear()
	_quests_by_id.clear()
	_enemies_by_id.clear()
	_zones_by_id.clear()

static func _ensure_indexes() -> void:
	if _indexes_ready:
		return
	_items_by_id.clear()
	_spells_by_id.clear()
	_races_by_id.clear()
	_quests_by_id.clear()
	_enemies_by_id.clear()
	_zones_by_id.clear()
	for definition in catalog().items:
		if definition and not definition.item_id.is_empty():
			_items_by_id[definition.item_id] = definition
	for definition in catalog().spells:
		if definition and not definition.spell_id.is_empty():
			_spells_by_id[definition.spell_id] = definition
	for definition in catalog().races:
		if definition and not definition.race_id.is_empty():
			_races_by_id[definition.race_id] = definition
	for definition in catalog().quests:
		if definition and not definition.quest_id.is_empty():
			_quests_by_id[definition.quest_id] = definition
	for definition in catalog().enemies:
		if definition and not definition.enemy_type_id.is_empty():
			_enemies_by_id[definition.enemy_type_id] = definition
	for definition in catalog().zones:
		if definition and not definition.zone_id.is_empty():
			_zones_by_id[definition.zone_id] = definition
	_indexes_ready = true

static func get_item(item_id: String) -> ItemDefinition:
	_ensure_indexes()
	return _items_by_id.get(item_id) as ItemDefinition

static func get_spell(spell_id: String) -> SpellDefinition:
	_ensure_indexes()
	return _spells_by_id.get(spell_id) as SpellDefinition

static func get_race(race_id: String) -> RaceDefinition:
	_ensure_indexes()
	return _races_by_id.get(race_id) as RaceDefinition

static func get_quest(quest_id: String) -> QuestDefinition:
	_ensure_indexes()
	return _quests_by_id.get(quest_id) as QuestDefinition

static func get_enemy(enemy_type_id: String) -> EnemyDefinition:
	_ensure_indexes()
	return _enemies_by_id.get(enemy_type_id) as EnemyDefinition

static func get_zone(zone_id: String) -> ZoneDefinition:
	_ensure_indexes()
	return _zones_by_id.get(zone_id) as ZoneDefinition

static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	_validate_item_ids(errors)
	_validate_spell_ids(errors)
	_validate_race_ids(errors)
	_validate_quest_ids(errors)
	_validate_enemy_ids(errors)
	_validate_zones(errors)
	return errors

static func _validate_item_ids(errors: PackedStringArray) -> void:
	var seen := {}
	for definition in catalog().items:
		if definition == null or definition.item_id.is_empty():
			errors.append("Item thiếu item_id")
		elif seen.has(definition.item_id):
			errors.append("Item ID trùng: " + definition.item_id)
		else:
			seen[definition.item_id] = true

static func _validate_spell_ids(errors: PackedStringArray) -> void:
	var seen := {}
	for definition in catalog().spells:
		if definition == null or definition.spell_id.is_empty():
			errors.append("Spell thiếu spell_id")
		elif seen.has(definition.spell_id):
			errors.append("Spell ID trùng: " + definition.spell_id)
		else:
			seen[definition.spell_id] = true
		if definition and definition.projectile_scene == null:
			errors.append("Spell thiếu projectile_scene: " + definition.spell_id)

static func _validate_race_ids(errors: PackedStringArray) -> void:
	var seen := {}
	for definition in catalog().races:
		if definition == null or definition.race_id.is_empty():
			errors.append("Race thiếu race_id")
		elif seen.has(definition.race_id):
			errors.append("Race ID trùng: " + definition.race_id)
		else:
			seen[definition.race_id] = true

static func _validate_quest_ids(errors: PackedStringArray) -> void:
	var seen := {}
	for definition in catalog().quests:
		if definition == null or definition.quest_id.is_empty():
			errors.append("Quest thiếu quest_id")
		elif seen.has(definition.quest_id):
			errors.append("Quest ID trùng: " + definition.quest_id)
		else:
			seen[definition.quest_id] = true
		if definition == null:
			continue
		if definition.target_amount <= 0:
			errors.append("Quest có target_amount không hợp lệ: " + definition.quest_id)
		if definition.giver_name.is_empty() or definition.giver_location.is_empty():
			errors.append("Quest thiếu thông tin NPC/khu vực: " + definition.quest_id)
		if definition.offer_dialogue.is_empty() or definition.active_dialogue.is_empty() \
				or definition.ready_dialogue.is_empty() or definition.completed_dialogue.is_empty():
			errors.append("Quest thiếu hội thoại theo trạng thái: " + definition.quest_id)
		if definition.quest_type == QuestDefinition.QuestType.KILL_ENEMY_TYPE:
			if get_enemy(definition.target_id) == null:
				errors.append("Quest tham chiếu enemy không tồn tại: %s -> %s" % [definition.quest_id, definition.target_id])
		elif get_item(definition.target_id) == null:
			errors.append("Quest tham chiếu item không tồn tại: %s -> %s" % [definition.quest_id, definition.target_id])
		for reward in definition.reward_items:
			var reward_item_id := str(reward.get("item_id", ""))
			if reward_item_id.is_empty() or get_item(reward_item_id) == null:
				errors.append("Quest có reward item không tồn tại: %s -> %s" % [definition.quest_id, reward_item_id])

static func _validate_enemy_ids(errors: PackedStringArray) -> void:
	var seen := {}
	for definition in catalog().enemies:
		if definition == null or definition.enemy_type_id.is_empty():
			errors.append("Enemy thiếu enemy_type_id")
		elif seen.has(definition.enemy_type_id):
			errors.append("Enemy ID trùng: " + definition.enemy_type_id)
		else:
			seen[definition.enemy_type_id] = true

static func _validate_zones(errors: PackedStringArray) -> void:
	var seen := {}
	for definition in catalog().zones:
		if definition == null or definition.zone_id.is_empty():
			errors.append("Zone thiếu zone_id")
			continue
		if seen.has(definition.zone_id):
			errors.append("Zone ID trùng: " + definition.zone_id)
		else:
			seen[definition.zone_id] = true
		if definition.scene_path.is_empty() or not ResourceLoader.exists(definition.scene_path):
			errors.append("Zone scene không tồn tại: " + definition.zone_id)

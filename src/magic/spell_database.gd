class_name SpellDatabase
extends RefCounted

## Runtime index cho SpellDefinition. Thứ tự hotbar lấy từ hotkey_number.

static var _spells: Dictionary = {}
static var _initialized := false

static func initialize() -> void:
	if _initialized:
		return
	_spells.clear()
	for definition in ContentRegistry.catalog().spells:
		if definition and not definition.spell_id.is_empty():
			_spells[definition.spell_id] = definition
	_initialized = true

static func reset_cache() -> void:
	_spells.clear()
	_initialized = false

static func get_spell(id: String) -> SpellDefinition:
	initialize()
	return _spells.get(id, null)

static func has_spell(id: String) -> bool:
	initialize()
	return _spells.has(id)

static func get_all_spells() -> Array[SpellDefinition]:
	initialize()
	var result: Array[SpellDefinition] = []
	for definition in _spells.values():
		result.append(definition as SpellDefinition)
	result.sort_custom(func(a: SpellDefinition, b: SpellDefinition): return a.hotkey_number < b.hotkey_number)
	return result

static func get_spell_by_index(index: int) -> SpellDefinition:
	var spells := get_all_spells()
	return spells[index] if index >= 0 and index < spells.size() else null

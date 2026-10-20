class_name SpellDatabase
extends RefCounted

## Cơ sở dữ liệu phép thuật (Spell Registry) cho NOCTELYRA (Milestone M5)
## Quản lý đăng ký và tra cứu các SpellDefinition theo ID chuẩn.

static var _spells: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
	if _initialized:
		return
	_initialized = true
	_spells.clear()

	# 1. Nguyệt Quang Đạn (moon_bolt)
	var mb := SpellDefinition.new()
	mb.spell_id = "moon_bolt"
	mb.display_name = "Nguyệt Quang Đạn"
	mb.description = "Bắn quả cầu ma pháp ánh trăng bay thẳng gây sát thương cho một mục tiêu."
	mb.base_damage = 30.0
	mb.mana_cost = 12.0
	mb.cooldown = 0.5
	mb.projectile_speed = 550.0
	mb.level_damages = [30.0, 40.0, 55.0]
	mb.projectile_scene = preload("res://src/magic/projectiles/moon_bolt_projectile.tscn")
	mb.effect_type = SpellDefinition.EffectType.SINGLE_TARGET
	mb.icon_color = Color(0.25, 0.75, 1.0)
	mb.accent_color = Color(0.9, 0.98, 1.0)
	mb.hotkey_number = 1
	_spells[mb.spell_id] = mb

	# 2. Tinh Hỏa Bùng Nổ (ember_bloom)
	var eb := SpellDefinition.new()
	eb.spell_id = "ember_bloom"
	eb.display_name = "Tinh Hỏa Bùng Nổ"
	eb.description = "Bắn cầu lửa ma thuật phát nổ khi chạm mục tiêu, gây sát thương diện rộng bán kính 110 px."
	eb.base_damage = 22.0
	eb.mana_cost = 18.0
	eb.cooldown = 1.0
	eb.projectile_speed = 380.0
	eb.level_damages = [22.0, 30.0, 40.0]
	eb.projectile_scene = preload("res://src/magic/projectiles/ember_bloom_projectile.tscn")
	eb.effect_type = SpellDefinition.EffectType.EXPLOSION
	eb.effect_radius = 110.0
	eb.icon_color = Color(1.0, 0.45, 0.1)
	eb.accent_color = Color(1.0, 0.85, 0.2)
	eb.hotkey_number = 2
	_spells[eb.spell_id] = eb

	# 3. Hàn Tinh Tiễn (frost_shard)
	var fs := SpellDefinition.new()
	fs.spell_id = "frost_shard"
	fs.display_name = "Hàn Tinh Tiễn"
	fs.description = "Bắn mũi tên băng sắc bén, gây sát thương và làm chậm 35% tốc độ quái vật trong 2 giây."
	fs.base_damage = 20.0
	fs.mana_cost = 15.0
	fs.cooldown = 0.7
	fs.projectile_speed = 650.0
	fs.level_damages = [20.0, 28.0, 38.0]
	fs.projectile_scene = preload("res://src/magic/projectiles/frost_shard_projectile.tscn")
	fs.effect_type = SpellDefinition.EffectType.SLOW
	fs.slow_ratio = 0.35
	fs.slow_duration = 2.0
	fs.icon_color = Color(0.4, 0.9, 1.0)
	fs.accent_color = Color(0.85, 0.98, 1.0)
	fs.hotkey_number = 3
	_spells[fs.spell_id] = fs

static func get_spell(id: String) -> SpellDefinition:
	if not _initialized:
		initialize()
	if _spells.has(id):
		return _spells[id]
	return null

static func has_spell(id: String) -> bool:
	if not _initialized:
		initialize()
	return _spells.has(id)

static func get_all_spells() -> Array[SpellDefinition]:
	if not _initialized:
		initialize()
	var arr: Array[SpellDefinition] = []
	for k in ["moon_bolt", "ember_bloom", "frost_shard"]:
		if _spells.has(k):
			arr.append(_spells[k])
	return arr

static func get_spell_by_index(idx: int) -> SpellDefinition:
	if not _initialized:
		initialize()
	var ids: Array[String] = ["moon_bolt", "ember_bloom", "frost_shard"]
	if idx >= 0 and idx < ids.size():
		return get_spell(ids[idx])
	return null

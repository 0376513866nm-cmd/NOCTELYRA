class_name SpellDefinition
extends Resource

## Định nghĩa thông số phép thuật trong NOCTELYRA (Milestone M5)
## Chứa dữ liệu cốt lõi, công thức tính sát thương theo cấp và chi phí nâng cấp.

enum EffectType {
	SINGLE_TARGET,
	EXPLOSION,
	SLOW
}

@export var spell_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var base_damage: float = 20.0
@export var mana_cost: float = 15.0
@export var cooldown: float = 1.0
@export var projectile_speed: float = 500.0
@export var projectile_scene: PackedScene = null
@export var effect_type: EffectType = EffectType.SINGLE_TARGET
@export var effect_radius: float = 0.0
@export var slow_ratio: float = 0.0
@export var slow_duration: float = 0.0
@export var icon_color: Color = Color(0.4, 0.8, 1.0)
@export var accent_color: Color = Color(0.2, 0.6, 1.0)
@export var hotkey_number: int = 1
@export var level_damages: Array[float] = []

func get_damage_for_level(level: int) -> float:
	if level <= 0:
		return base_damage
	if not level_damages.is_empty():
		var idx := clampi(level - 1, 0, level_damages.size() - 1)
		return level_damages[idx]
	match level:
		1:
			return base_damage
		2:
			return base_damage * 1.2
		3:
			return base_damage * 1.4
		_:
			if level > 3:
				return base_damage * 1.4
			return base_damage

func get_upgrade_cost(current_level: int) -> int:
	match current_level:
		1:
			return 3 # 3 mana_shard để lên Cấp 2
		2:
			return 6 # 6 mana_shard để lên Cấp 3
		_:
			return -1 # Đã đạt cấp tối đa

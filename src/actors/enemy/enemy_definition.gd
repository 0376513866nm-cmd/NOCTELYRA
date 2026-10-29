class_name EnemyDefinition
extends Resource

enum AttackType {
	MELEE,
	LUNGE,
	RANGED
}

@export var enemy_type_id: String = "corrupted_wolf"
@export var display_name: String = "Quái Tha Hóa"
@export var max_health: float = 80.0
@export var move_speed: float = 120.0
@export var detection_range: float = 380.0
@export var attack_range: float = 55.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 1.2
@export var attack_type: AttackType = AttackType.MELEE
@export var patrol_radius: float = 150.0
@export var leash_distance: float = 500.0
@export var telegraph_duration: float = 0.4
@export var attack_duration: float = 0.25
@export var recovery_duration: float = 0.6
@export var lunge_speed: float = 450.0
@export var projectile_speed: float = 320.0
@export var projectile_damage: float = 12.0
@export var projectile_color: Color = Color(0.6, 0.4, 1.0, 1.0)
@export var is_flying: bool = false
@export var drop_item_id: String = ""

static func get_definition(type_id: String) -> EnemyDefinition:
	var definition := ContentRegistry.get_enemy(type_id)
	return definition if definition else ContentRegistry.get_enemy("corrupted_wolf")

static func create_default(type_id: String) -> EnemyDefinition:
	return get_definition(type_id)

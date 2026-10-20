class_name EnemyDefinition
extends Resource

## Định nghĩa thông số & cấu hình sinh vật (Enemy Definition) cho NOCTELYRA (Milestone M7)
## Hỗ trợ 3 kiểu tấn công (MELEE, LUNGE, RANGED), phạm vi đi tuần, leash distance,
## thời gian báo trước (telegraph) và thời gian nghỉ hồi phục (recovery).

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

# Thông số hành vi & di chuyển mở rộng
@export var patrol_radius: float = 150.0 # Bán kính đi tuần quanh điểm sinh ban đầu
@export var leash_distance: float = 500.0 # Khoảng cách tối đa so với điểm sinh trước khi từ bỏ đuổi
@export var telegraph_duration: float = 0.4 # Thời gian báo trước khi ra đòn
@export var attack_duration: float = 0.25 # Thời gian hiệu lực đòn đánh
@export var recovery_duration: float = 0.6 # Thời gian nghỉ hồi phục sau đòn đánh
@export var lunge_speed: float = 450.0 # Vận tốc lao đòn lunge (đối với LUNGE)
@export var projectile_speed: float = 320.0 # Vận tốc đạn (đối với RANGED)
@export var projectile_damage: float = 12.0
@export var projectile_color: Color = Color(0.6, 0.4, 1.0, 1.0)
@export var is_flying: bool = false # Sinh vật bay/lơ lửng, không chịu trọng lực rơi
@export var drop_item_id: String = "" # Vật phẩm đánh rơi

static func get_definition(type_id: String) -> EnemyDefinition:
	return create_default(type_id)

static func create_default(type_id: String) -> EnemyDefinition:
	var def := EnemyDefinition.new()
	def.enemy_type_id = type_id

	match type_id:
		"corrupted_mooncap":
			# Nấm Mộng Tha Hóa (Thánh Lâm Elyndra)
			def.display_name = "Nấm Mộng Tha Hóa"
			def.max_health = 60.0
			def.move_speed = 80.0 # Tốc độ chậm
			def.detection_range = 300.0
			def.attack_range = 50.0
			def.attack_damage = 12.0
			def.attack_cooldown = 1.4
			def.attack_type = AttackType.MELEE
			def.patrol_radius = 120.0
			def.leash_distance = 420.0
			def.telegraph_duration = 0.45
			def.recovery_duration = 0.6
			def.is_flying = false

		"corrupted_mana_wisp":
			# Linh Hồn Tinh Mạch (Thánh Lâm Elyndra)
			def.display_name = "Linh Hồn Tinh Mạch"
			def.max_health = 35.0 # Ít HP
			def.move_speed = 60.0 # Di chuyển lơ lửng chậm
			def.detection_range = 380.0
			def.attack_range = 280.0 # Tấn công tầm xa
			def.attack_damage = 10.0
			def.attack_cooldown = 1.8
			def.attack_type = AttackType.RANGED
			def.patrol_radius = 100.0
			def.leash_distance = 450.0
			def.telegraph_duration = 0.7 # Có thời gian niệm chú
			def.recovery_duration = 0.8
			def.projectile_speed = 320.0
			def.projectile_damage = 12.0
			def.projectile_color = Color(0.6, 0.4, 1.0, 1.0) # Tím ma thuật
			def.is_flying = true # Lơ lửng, không rơi xuống đất

		"ashfang_wolf":
			# Sói Tro (Tiền Đồn Vharok)
			def.display_name = "Sói Tro"
			def.max_health = 70.0
			def.move_speed = 180.0 # Di chuyển nhanh
			def.detection_range = 360.0
			def.attack_range = 140.0 # Lao vào từ cự ly vừa
			def.attack_damage = 18.0
			def.attack_cooldown = 1.8
			def.attack_type = AttackType.LUNGE
			def.patrol_radius = 160.0
			def.leash_distance = 550.0
			def.telegraph_duration = 0.5 # Báo trước rồi lao
			def.attack_duration = 0.28
			def.recovery_duration = 0.85 # Thời gian nghỉ hồi phục sau đòn lao
			def.lunge_speed = 460.0
			def.is_flying = false

		"ember_lizard":
			# Hỏa Tích Hắc Nham (Tiền Đồn Vharok)
			def.display_name = "Hỏa Tích Hắc Nham"
			def.max_health = 80.0
			def.move_speed = 75.0 # Chậm hơn sói
			def.detection_range = 320.0
			def.attack_range = 240.0 # Bắn cầu lửa
			def.attack_damage = 14.0
			def.attack_cooldown = 1.6
			def.attack_type = AttackType.RANGED
			def.patrol_radius = 110.0
			def.leash_distance = 420.0
			def.telegraph_duration = 0.6
			def.recovery_duration = 0.7
			def.projectile_speed = 280.0
			def.projectile_damage = 15.0
			def.projectile_color = Color(1.0, 0.45, 0.1, 1.0) # Cam lửa
			def.drop_item_id = "ember_core"
			def.is_flying = false

		_:
			# Mặc định: Sói Tha Hóa (Rừng Noctis)
			def.display_name = "Sinh Vật Tha Hóa"
			def.max_health = 80.0
			def.move_speed = 120.0
			def.detection_range = 380.0
			def.attack_range = 55.0
			def.attack_damage = 15.0
			def.attack_cooldown = 1.4
			def.attack_type = AttackType.MELEE
			def.patrol_radius = 150.0
			def.leash_distance = 650.0
			def.telegraph_duration = 0.4
			def.attack_duration = 0.65
			def.recovery_duration = 0.5
			def.is_flying = false

	return def

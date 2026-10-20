class_name PlayerStatsComponent
extends Node

## Hệ Thống Tính Chỉ Số Thống Nhất (Unified Stats System) cho NOCTELYRA (Milestone M8)
## Là NGUỒN DUY NHẤT tính toán chỉ số cuối cùng:
## Final Stats = Race Base Stats + Level Growth + Equipment Bonuses
## Đồng bộ và áp dụng an toàn sang HealthComponent, MeleeHitbox, SpellbookComponent, MovementData.

signal stats_updated()
signal race_changed(new_race_id: String)

@export var player: Player

# Thuộc tính chủng tộc hiện tại
var _race_id: String = "human"
var race_id: String:
	get:
		return _race_id
	set(val):
		if _race_id != val or base_health == 0.0:
			set_race(val)
		else:
			_race_id = val

# Chỉ số cơ bản của tộc (được nạp từ RaceDatabase)
var base_health: float = 100.0
var base_mana: float = 60.0
var base_attack: float = 25.0
var base_mana_regen: float = 5.0
var base_move_speed: float = 270.0
var magic_damage_multiplier: float = 1.0

# Chỉ số cuối cùng sau khi cộng cấp độ & trang bị
var final_max_health: float = 100.0
var final_max_mana: float = 60.0
var final_attack: float = 25.0
var final_mana_regen: float = 5.0
var final_move_speed: float = 270.0
var final_magic_multiplier: float = 1.0

# Hệ số tăng trưởng theo mỗi cấp độ (từ cấp 2 trở đi)
const GROWTH_PER_LEVEL_HP: float = 10.0
const GROWTH_PER_LEVEL_MP: float = 5.0
const GROWTH_PER_LEVEL_ATK: float = 2.0

func _ready() -> void:
	if player == null and get_parent() is Player:
		player = get_parent() as Player

	_bind_components()
	set_race(race_id)

func _bind_components() -> void:
	if player == null:
		return

	# Kết nối EquipmentComponent
	var eq := player.get_node_or_null("EquipmentComponent") as EquipmentComponent
	if eq and not eq.equipment_changed.is_connected(_on_equipment_changed):
		eq.equipment_changed.connect(_on_equipment_changed)

	# Kết nối PlayerProgressionComponent
	var prog := player.get_node_or_null("PlayerProgressionComponent") as PlayerProgressionComponent
	if prog and not prog.level_up.is_connected(_on_level_up):
		prog.level_up.connect(_on_level_up)

func set_race(new_race_id: String) -> void:
	var def := RaceDatabase.get_race(new_race_id)
	if def == null:
		def = RaceDatabase.get_race("human")

	_race_id = def.race_id
	base_health = def.base_health
	base_mana = def.base_mana
	base_attack = def.base_attack
	base_mana_regen = def.base_mana_regen
	base_move_speed = def.base_move_speed
	magic_damage_multiplier = def.magic_damage_multiplier

	# Cập nhật ngoại hình visual của Player nếu có
	if player and player.has_method("apply_race_visual"):
		player.apply_race_visual(race_id)

	recalculate_stats(false)
	emit_signal("race_changed", race_id)

func _on_equipment_changed(_slot_type: String, _item_id: String) -> void:
	recalculate_stats(false)

func _on_level_up(_new_level: int) -> void:
	# Khi lên cấp: tăng HP/MP hiện tại theo phần vừa được cộng thêm (không hồi đầy)
	recalculate_stats(true)

func recalculate_stats(is_level_up: bool = false) -> void:
	if player == null and get_parent() is Player:
		player = get_parent() as Player

	# 1. Lấy cấp độ hiện tại từ PlayerProgressionComponent
	var level: int = 1
	var prog := player.get_node_or_null("PlayerProgressionComponent") as PlayerProgressionComponent if player else null
	if prog:
		level = prog.level

	var lvl_diff: int = max(0, level - 1)
	var growth_hp: float = float(lvl_diff) * GROWTH_PER_LEVEL_HP
	var growth_mp: float = float(lvl_diff) * GROWTH_PER_LEVEL_MP
	var growth_atk: float = float(lvl_diff) * GROWTH_PER_LEVEL_ATK

	# 2. Lấy chỉ số thưởng từ trang bị hiện tại (EquipmentComponent)
	var eq_hp: float = 0.0
	var eq_mp: float = 0.0
	var eq_atk: float = 0.0

	var eq := player.get_node_or_null("EquipmentComponent") as EquipmentComponent if player else null
	if eq:
		var w_id := eq.get_equipped("weapon")
		if not w_id.is_empty() and ItemDatabase.has_item(w_id):
			var w_def := ItemDatabase.get_item(w_id)
			eq_atk += float(w_def.stat_modifiers.get("attack_bonus", 0.0))
			eq_hp += float(w_def.stat_modifiers.get("max_health_bonus", 0.0))
			eq_mp += float(w_def.stat_modifiers.get("max_mana_bonus", 0.0))

		var a_id := eq.get_equipped("accessory")
		if not a_id.is_empty() and ItemDatabase.has_item(a_id):
			var a_def := ItemDatabase.get_item(a_id)
			eq_atk += float(a_def.stat_modifiers.get("attack_bonus", 0.0))
			eq_hp += float(a_def.stat_modifiers.get("max_health_bonus", 0.0))
			eq_mp += float(a_def.stat_modifiers.get("max_mana_bonus", 0.0))

	# 3. Tính toán Final Stats thống nhất
	final_max_health = base_health + growth_hp + eq_hp
	final_max_mana = base_mana + growth_mp + eq_mp
	final_attack = base_attack + growth_atk + eq_atk
	final_mana_regen = base_mana_regen
	final_move_speed = base_move_speed
	final_magic_multiplier = magic_damage_multiplier

	# 4. Áp dụng đồng bộ vào các component tương ứng của Player
	if player:
		# HealthComponent
		var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if p_health:
			var prev_max_hp := p_health.max_health
			var prev_max_mp := p_health.max_mana

			p_health.max_health = final_max_health
			p_health.max_mana = final_max_mana
			p_health.mana_regen_rate = final_mana_regen

			if is_level_up:
				# Khi lên cấp: cộng thêm lượng Max HP/MP tăng thêm vào Current HP/MP (không hồi đầy)
				var hp_gain: float = max(0.0, final_max_health - prev_max_hp)
				var mp_gain: float = max(0.0, final_max_mana - prev_max_mp)
				p_health.current_health = min(final_max_health, p_health.current_health + hp_gain)
				p_health.current_mana = min(final_max_mana, p_health.current_mana + mp_gain)
			else:
				# Khi thay đồ/tháo đồ: giữ HP/MP trong giới hạn mới
				p_health.current_health = min(final_max_health, p_health.current_health)
				p_health.current_mana = min(final_max_mana, p_health.current_mana)

			p_health.emit_signal("health_changed", p_health.current_health, p_health.max_health)
			p_health.emit_signal("mana_changed", p_health.current_mana, p_health.max_mana)

		# Combat Hitbox
		if player.melee_hitbox:
			player.melee_hitbox.damage = final_attack

		# SpellbookComponent
		var p_sb := player.get_node_or_null("SpellbookComponent") as SpellbookComponent
		if p_sb:
			p_sb.magic_damage_multiplier = final_magic_multiplier

		# MovementData
		if player.movement_data:
			if player.has_method("_ensure_isolated_movement_data"):
				player._ensure_isolated_movement_data()
			player.movement_data.move_speed = final_move_speed

	emit_signal("stats_updated")

func get_race_definition() -> RaceDefinition:
	return RaceDatabase.get_race(race_id)

func to_dict() -> Dictionary:
	return {
		"race_id": race_id
	}

func from_dict(data: Dictionary) -> void:
	if data == null or data.is_empty():
		return
	var r_id := str(data.get("race_id", "human"))
	set_race(r_id)

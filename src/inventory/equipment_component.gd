class_name EquipmentComponent
extends Node

## Quản lý trang bị của Player (Weapon & Accessory) cho NOCTELYRA (M3)
## Đảm bảo tính toán chỉ số dựa trên Base Stats + Modifiers, không sửa gốc vĩnh viễn.

signal equipment_changed(slot_type: String, item_id: String)

@export var player: Player

var base_attack_damage: float = 25.0
var base_max_mana: float = 60.0

var equipped_weapon: String = ""
var equipped_accessory: String = ""

func _ready() -> void:
	if player == null and get_parent() is Player:
		player = get_parent() as Player

	_record_base_stats()

func _record_base_stats() -> void:
	if player:
		if player.melee_hitbox:
			base_attack_damage = player.melee_hitbox.damage
		var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if p_health:
			base_max_mana = p_health.max_mana

func get_equipped(slot_type: String) -> String:
	match slot_type:
		"weapon": return equipped_weapon
		"accessory": return equipped_accessory
		_: return ""

func is_slot_equipped(slot_type: String) -> bool:
	return not get_equipped(slot_type).is_empty()

func equip(item_id: String) -> String:
	if not ItemDatabase.has_item(item_id):
		return ""
	var def := ItemDatabase.get_item(item_id)
	var prev_item: String = ""

	match def.item_type:
		ItemDefinition.ItemType.WEAPON:
			prev_item = equipped_weapon
			equipped_weapon = item_id
			_recalculate_stats()
			emit_signal("equipment_changed", "weapon", item_id)
		ItemDefinition.ItemType.ACCESSORY:
			prev_item = equipped_accessory
			equipped_accessory = item_id
			_recalculate_stats()
			emit_signal("equipment_changed", "accessory", item_id)
		_:
			return "" # Không phải trang bị

	return prev_item

func equip_item(item_id: String) -> String:
	return equip(item_id)

func unequip(slot_type: String) -> String:
	var old_item: String = ""
	match slot_type:
		"weapon":
			old_item = equipped_weapon
			equipped_weapon = ""
			_recalculate_stats()
			emit_signal("equipment_changed", "weapon", "")
		"accessory":
			old_item = equipped_accessory
			equipped_accessory = ""
			_recalculate_stats()
			emit_signal("equipment_changed", "accessory", "")
		_:
			return ""

	return old_item

func unequip_item(slot_type: String) -> String:
	return unequip(slot_type)

func _recalculate_stats() -> void:
	if player:
		var p_stats := player.get_node_or_null("PlayerStatsComponent") as PlayerStatsComponent
		if p_stats:
			p_stats.recalculate_stats(false)
			return

	var total_attack := base_attack_damage
	var total_max_mana := base_max_mana

	# Cộng chỉ số từ Weapon
	if not equipped_weapon.is_empty() and ItemDatabase.has_item(equipped_weapon):
		var w_def := ItemDatabase.get_item(equipped_weapon)
		total_attack += float(w_def.stat_modifiers.get("attack_bonus", 0.0))

	# Cộng chỉ số từ Accessory
	if not equipped_accessory.is_empty() and ItemDatabase.has_item(equipped_accessory):
		var a_def := ItemDatabase.get_item(equipped_accessory)
		total_max_mana += float(a_def.stat_modifiers.get("max_mana_bonus", 0.0))

	# Áp dụng chỉ số vào Player
	if player:
		if player.melee_hitbox:
			player.melee_hitbox.damage = total_attack

		var p_health := player.get_node_or_null("HealthComponent") as HealthComponent
		if p_health:
			p_health.max_mana = total_max_mana
			# Không tạo MP vượt giới hạn sau khi tháo trang bị
			if p_health.current_mana > total_max_mana:
				p_health.current_mana = total_max_mana
			p_health.emit_signal("mana_changed", p_health.current_mana, p_health.max_mana)

func to_dict() -> Dictionary:
	return {
		"weapon": equipped_weapon,
		"accessory": equipped_accessory
	}

func load_from_dict(data: Dictionary) -> void:
	equipped_weapon = str(data.get("weapon", ""))
	equipped_accessory = str(data.get("accessory", ""))

	# Kiểm tra tồn tại trong DB và đúng loại trang bị (M3.1 validation)
	if not ItemDatabase.has_item(equipped_weapon) or ItemDatabase.get_item(equipped_weapon).item_type != ItemDefinition.ItemType.WEAPON:
		equipped_weapon = ""
	if not ItemDatabase.has_item(equipped_accessory) or ItemDatabase.get_item(equipped_accessory).item_type != ItemDefinition.ItemType.ACCESSORY:
		equipped_accessory = ""

	_recalculate_stats()
	emit_signal("equipment_changed", "weapon", equipped_weapon)
	emit_signal("equipment_changed", "accessory", equipped_accessory)

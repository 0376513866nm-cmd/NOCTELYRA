class_name SpellbookComponent
extends Node

## Bộ quản lý Sách Phép (SpellbookComponent) cho Player (Milestone M5)
## Quản lý danh sách phép đã học, phép đang chọn, cấp độ phép, thời gian hồi độc lập,
## và logic nâng cấp tiêu hao Tinh thể Ma lực (mana_shard).

signal spell_selected(spell_id: String)
signal spell_upgraded(spell_id: String, new_level: int)
signal spell_cast_success(spell_id: String)
signal spell_cast_failed(reason: String)

var known_spells: Array[String] = ["moon_bolt", "ember_bloom", "frost_shard"]
var spell_levels: Dictionary = {
	"moon_bolt": 1,
	"ember_bloom": 1,
	"frost_shard": 1
}
var selected_spell_id: String = "moon_bolt"
var cooldown_timers: Dictionary = {
	"moon_bolt": 0.0,
	"ember_bloom": 0.0,
	"frost_shard": 0.0
}

func _ready() -> void:
	SpellDatabase.initialize()
	if not known_spells.has(selected_spell_id):
		selected_spell_id = "moon_bolt"

func _process(delta: float) -> void:
	# Cập nhật cooldown độc lập cho từng phép
	for s_id in cooldown_timers.keys():
		var t: float = cooldown_timers[s_id]
		if t > 0.0:
			cooldown_timers[s_id] = max(0.0, t - delta)

func select_spell(spell_id: String) -> bool:
	if not known_spells.has(spell_id):
		return false
	if selected_spell_id != spell_id:
		selected_spell_id = spell_id
		emit_signal("spell_selected", selected_spell_id)
	return true

func select_spell_by_index(idx: int) -> bool:
	var spell := SpellDatabase.get_spell_by_index(idx)
	if spell and known_spells.has(spell.spell_id):
		return select_spell(spell.spell_id)
	return false

func select_spell_by_hotkey(hotkey_num: int) -> bool:
	return select_spell_by_index(hotkey_num - 1)

func get_selected_spell() -> SpellDefinition:
	return SpellDatabase.get_spell(selected_spell_id)

func get_spell_level(spell_id: String) -> int:
	return int(spell_levels.get(spell_id, 1))

func get_cooldown(spell_id: String) -> float:
	return float(cooldown_timers.get(spell_id, 0.0))

func is_on_cooldown(spell_id: String) -> bool:
	return get_cooldown(spell_id) > 0.0

func can_cast_selected(health_comp: HealthComponent) -> Dictionary:
	var spell := get_selected_spell()
	if spell == null:
		return {"can_cast": false, "reason": "CHƯA_CHỌN_PHÉP"}

	if is_on_cooldown(spell.spell_id):
		return {"can_cast": false, "reason": "COOLDOWN"}

	if health_comp:
		if not health_comp.is_alive():
			return {"can_cast": false, "reason": "PLAYER_DEAD"}
		if health_comp.current_mana < spell.mana_cost:
			return {"can_cast": false, "reason": "NOT_ENOUGH_MANA"}

	return {"can_cast": true, "reason": "OK"}

func cast_selected_spell(player: Node2D, facing_dir: int, health_comp: HealthComponent) -> bool:
	var check := can_cast_selected(health_comp)
	if not check.get("can_cast", false):
		emit_signal("spell_cast_failed", str(check.get("reason", "")))
		return false

	var spell := get_selected_spell()
	if spell == null or player == null:
		return false

	# Tiêu hao MP
	if health_comp:
		var ok := health_comp.consume_mana(spell.mana_cost)
		if not ok:
			emit_signal("spell_cast_failed", "NOT_ENOUGH_MANA")
			return false

	# Kích hoạt cooldown độc lập cho phép này
	cooldown_timers[spell.spell_id] = spell.cooldown

	# Tính sát thương theo cấp hiện tại
	var lvl := get_spell_level(spell.spell_id)
	var final_dmg := spell.get_damage_for_level(lvl)

	# Sinh projectile
	if spell.projectile_scene:
		var proj := spell.projectile_scene.instantiate() as Node2D
		if proj:
			var spawn_pos := player.global_position + Vector2(25.0 * float(facing_dir), -40.0)
			proj.global_position = spawn_pos
			if proj.has_method("setup"):
				proj.setup(Vector2(float(facing_dir), 0.0), player, final_dmg)

			var spawn_root: Node = null
			if player.get_tree() and player.get_tree().current_scene:
				spawn_root = player.get_tree().current_scene
			elif player.get_parent():
				spawn_root = player.get_parent()
			else:
				spawn_root = player

			if spawn_root:
				spawn_root.add_child(proj)

	emit_signal("spell_cast_success", spell.spell_id)
	return true

func upgrade_spell(spell_id: String, inventory: InventoryComponent, world: Node = null) -> Dictionary:
	var spell := SpellDatabase.get_spell(spell_id)
	if spell == null:
		return {"success": false, "message": "Không tìm thấy phép thuật!"}

	var cur_lvl := get_spell_level(spell_id)
	if cur_lvl >= 3:
		return {"success": false, "message": "%s đã đạt cấp tối đa (Cấp 3)!" % spell.display_name}

	# Chặn nâng cấp khi đang đánh Boss
	if world and SaveManager.is_boss_combat_active(world):
		return {"success": false, "message": "Không thể nâng cấp phép trong trận chiến Boss!"}

	var cost := spell.get_upgrade_cost(cur_lvl)
	if cost <= 0:
		return {"success": false, "message": "Không thể nâng cấp thêm!"}

	if inventory == null:
		return {"success": false, "message": "Không tìm thấy túi đồ!"}

	var current_shards := inventory.get_item_count("mana_shard")
	if current_shards < cost:
		return {
			"success": false,
			"message": "Không đủ Tinh thể Ma lực! (Cần %d, hiện có %d)" % [cost, current_shards]
		}

	# Trừ nguyên liệu và tăng cấp
	var removed := inventory.remove_item("mana_shard", cost)
	if not removed:
		return {"success": false, "message": "Lỗi khi trừ Tinh thể Ma lực!"}

	var new_lvl := cur_lvl + 1
	spell_levels[spell_id] = new_lvl
	emit_signal("spell_upgraded", spell_id, new_lvl)

	return {
		"success": true,
		"message": "Nâng cấp %s lên Cấp %d thành công!" % [spell.display_name, new_lvl]
	}

func to_dict() -> Dictionary:
	return {
		"selected_spell": selected_spell_id,
		"known_spells": known_spells.duplicate(),
		"spell_levels": spell_levels.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	if data == null or data.is_empty():
		return
	if data.has("selected_spell") and data["selected_spell"] is String:
		selected_spell_id = data["selected_spell"]
	if data.has("known_spells") and data["known_spells"] is Array:
		known_spells.clear()
		for sp in data["known_spells"]:
			known_spells.append(str(sp))
	if data.has("spell_levels") and data["spell_levels"] is Dictionary:
		var lvls: Dictionary = data["spell_levels"]
		for k in lvls.keys():
			var v = lvls[k]
			spell_levels[str(k)] = clamp(int(v), 1, 3)

	# Đảm bảo 3 phép mặc định luôn có mặt
	for def_id in ["moon_bolt", "ember_bloom", "frost_shard"]:
		if not known_spells.has(def_id):
			known_spells.append(def_id)
		if not spell_levels.has(def_id):
			spell_levels[def_id] = 1
		if not cooldown_timers.has(def_id):
			cooldown_timers[def_id] = 0.0

	if not known_spells.has(selected_spell_id):
		selected_spell_id = "moon_bolt"

	emit_signal("spell_selected", selected_spell_id)

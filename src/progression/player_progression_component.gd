class_name PlayerProgressionComponent
extends Node

## Quản lý Cấp độ & Tiến trình EXP (Player Progression Component) cho NOCTELYRA (M8)
## Hỗ trợ EXP lũy tiến: 60 + 40 * (level - 1), cấp tối đa Lv.10,
## bảo lưu EXP dư khi tăng nhiều cấp trong một lần, và chống nhận EXP trùng tuyệt đối.

signal exp_gained(amount: int, current_exp: int, target_exp: int)
signal level_up(new_level: int)
signal progression_updated()

const MAX_LEVEL: int = 10
const BASE_EXP: int = 60
const EXP_GROWTH: int = 40

var level: int = 1
var current_exp: int = 0
var claimed_exp_sources: Array[String] = []

func _ready() -> void:
	pass

func get_exp_required_for_level(lvl: int) -> int:
	if lvl >= MAX_LEVEL:
		return 0 # Đã đạt cấp tối đa
	return BASE_EXP + EXP_GROWTH * (lvl - 1)

func get_current_target_exp() -> int:
	return get_exp_required_for_level(level)

func is_max_level() -> bool:
	return level >= MAX_LEVEL

func has_claimed_source(source_id: String) -> bool:
	if source_id.is_empty():
		return false
	return source_id in claimed_exp_sources

func add_exp(amount: int, source_id: String = "") -> bool:
	if amount <= 0:
		return false

	# Bắt buộc chống nhận EXP trùng lặp
	if not source_id.is_empty():
		if source_id in claimed_exp_sources:
			return false
		claimed_exp_sources.append(source_id)

	if is_max_level():
		emit_signal("exp_gained", 0, current_exp, 0)
		emit_signal("progression_updated")
		return true

	current_exp += amount

	# Vòng lặp xử lý lên nhiều cấp nếu lượng EXP dư thừa đủ lớn
	while not is_max_level() and current_exp >= get_exp_required_for_level(level):
		current_exp -= get_exp_required_for_level(level)
		level += 1
		emit_signal("level_up", level)

	# Nếu đã đạt Max Level 10 thì không cho phép vượt cấp, xóa EXP dư thừa
	if is_max_level():
		current_exp = 0

	emit_signal("exp_gained", amount, current_exp, get_current_target_exp())
	emit_signal("progression_updated")
	return true

func to_dict() -> Dictionary:
	return {
		"level": level,
		"current_exp": current_exp,
		"claimed_exp_sources": claimed_exp_sources.duplicate()
	}

func from_dict(data: Dictionary) -> void:
	if data == null or data.is_empty():
		return
	level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
	current_exp = maxi(0, int(data.get("current_exp", 0)))
	if is_max_level():
		current_exp = 0

	claimed_exp_sources.clear()
	var raw_sources = data.get("claimed_exp_sources", [])
	if raw_sources is Array:
		for s in raw_sources:
			var s_str := str(s)
			if not s_str in claimed_exp_sources:
				claimed_exp_sources.append(s_str)

	emit_signal("progression_updated")

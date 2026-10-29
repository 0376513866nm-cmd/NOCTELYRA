class_name RaceDatabase
extends RefCounted

## Cơ sở Dữ liệu Chủng tộc (Race Database) cho NOCTELYRA (Milestone M8)
## Đăng ký và truy xuất định nghĩa 3 chủng tộc: Nhân tộc, Tinh Linh tộc, Quỷ tộc bán thú.

static var _races: Dictionary = {}

static func initialize() -> void:
	_ensure_initialized()

static func _ensure_initialized() -> void:
	if not _races.is_empty():
		return

	# 1. Nhân tộc (human)
	var human := RaceDefinition.new()
	human.race_id = "human"
	human.display_name = "Nhân tộc"
	human.title = "Người Bảo Vệ Làng Ánh Nguyệt"
	human.description = "Những chiến binh bền bỉ và kiên cường từ Rừng Noctis. Nhân tộc sở hữu khả năng thích nghi cao, thể chất và ma lực cân bằng, làm chủ mọi loại vũ khí và thuật pháp."
	human.pros = "Chỉ số cân bằng, dễ làm quen, tốc độ hồi phục ổn định."
	human.cons = "Không có chỉ số chuyên biệt vượt trội so với các tộc cổ xưa."
	human.base_health = 100.0
	human.base_mana = 60.0
	human.base_attack = 25.0
	human.base_mana_regen = 5.0
	human.base_move_speed = 270.0
	human.magic_damage_multiplier = 1.0
	human.theme_color = Color(0.3, 0.6, 1.0, 1.0) # Xanh lam / Bạc
	human.aura_color = Color(0.4, 0.7, 1.0, 0.3)
	_races["human"] = human

	# 2. Tinh Linh tộc (elf)
	var elf := RaceDefinition.new()
	elf.race_id = "elf"
	elf.display_name = "Tinh Linh tộc"
	elf.title = "Người Gìn Giữ Tinh Mạch Elyndra"
	elf.description = "Hậu duệ cổ xưa của Thánh Lâm Elyndra, gắn liền với dòng chảy Tinh Mạch tự nhiên. Sở hữu trí tuệ ma pháp siêu phàm, lượng mana dồi dào và sát thương phép thuật uy lực."
	elf.pros = "Nhiều MP (80), hồi MP nhanh (7/s), sát thương phép +10% (x1.1), di chuyển nhanh (275)."
	elf.cons = "HP cơ bản thấp (90), sức chống chịu vật lý mỏng manh."
	elf.base_health = 90.0
	elf.base_mana = 80.0
	elf.base_attack = 23.0
	elf.base_mana_regen = 7.0
	elf.base_move_speed = 275.0
	elf.magic_damage_multiplier = 1.1
	elf.theme_color = Color(0.2, 0.85, 0.55, 1.0) # Xanh ngọc bích / Tinh thể ma thuật
	elf.aura_color = Color(0.2, 0.9, 0.6, 0.4)
	_races["elf"] = elf

	# 3. Quỷ tộc bán thú (demon_beast)
	var beast := RaceDefinition.new()
	beast.race_id = "demon_beast"
	beast.display_name = "Quỷ tộc bán thú"
	beast.title = "Chiến Binh Tiền Đồn Vharok"
	beast.description = "Chủng tộc kiêu hãnh của Tiền Đồn Vharok, có nền văn minh rèn sắt và hiệp ước lâu đời. Họ tôn trọng danh dự, lời thề và sở hữu thể lực cuồn cuộn cùng sức tấn công cận chiến khủng khiếp."
	beast.pros = "Sinh mệnh dồi dào (125 HP), sức tấn công cận chiến vượt trội (30 ATK)."
	beast.cons = "Trữ lượng MP thấp (50), hồi MP chậm hơn (4/s), tốc độ di chuyển chậm hơn (260)."
	beast.base_health = 125.0
	beast.base_mana = 50.0
	beast.base_attack = 30.0
	beast.base_mana_regen = 4.0
	beast.base_move_speed = 260.0
	beast.magic_damage_multiplier = 1.0
	beast.theme_color = Color(0.85, 0.25, 0.45, 1.0) # Đỏ thẫm / Tím Hắc Nham
	beast.aura_color = Color(0.9, 0.3, 0.4, 0.4)
	_races["demon_beast"] = beast

static func get_race(race_id: String) -> RaceDefinition:
	_ensure_initialized()
	if _races.has(race_id):
		return _races[race_id]
	return _races.get("human", null)

static func has_race(race_id: String) -> bool:
	_ensure_initialized()
	return _races.has(race_id)

static func get_all_races() -> Array[RaceDefinition]:
	_ensure_initialized()
	var list: Array[RaceDefinition] = []
	list.append(_races["human"])
	list.append(_races["elf"])
	list.append(_races["demon_beast"])
	return list

static func get_all_race_ids() -> Array[String]:
	return ["human", "elf", "demon_beast"]

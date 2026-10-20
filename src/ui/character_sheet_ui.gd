class_name CharacterSheetUI
extends Control

## Giao diện Bảng Thông Tin Nhân Vật (Character Sheet UI) cho NOCTELYRA (Milestone M8)
## Phím tắt C bật/tắt, hiển thị chủng tộc, cấp độ, thanh tiến trình EXP, chỉ số HP/MP,
## sát thương cận chiến, hệ số ma pháp, hồi MP, tốc độ di chuyển và trang bị hiện tại.

signal sheet_opened()
signal sheet_closed()

@onready var close_btn: Button = $Panel/Header/CloseBtn

# Header / Profile
@onready var race_label: Label = $Panel/Content/ProfileBox/RaceLabel
@onready var race_desc_label: Label = $Panel/Content/ProfileBox/RaceDescLabel
@onready var level_label: Label = $Panel/Content/ProgressionBox/LevelLabel
@onready var exp_bar: ProgressBar = $Panel/Content/ProgressionBox/ExpBar
@onready var exp_label: Label = $Panel/Content/ProgressionBox/ExpLabel

# Stats
@onready var hp_stat_label: Label = $Panel/Content/StatsGrid/HPLabel
@onready var mp_stat_label: Label = $Panel/Content/StatsGrid/MPLabel
@onready var atk_stat_label: Label = $Panel/Content/StatsGrid/ATKLabel
@onready var magic_stat_label: Label = $Panel/Content/StatsGrid/MagicLabel
@onready var regen_stat_label: Label = $Panel/Content/StatsGrid/RegenLabel
@onready var speed_stat_label: Label = $Panel/Content/StatsGrid/SpeedLabel

# Equipment
@onready var weapon_label: Label = $Panel/Content/EquipBox/WeaponLabel
@onready var accessory_label: Label = $Panel/Content/EquipBox/AccessoryLabel

var player: Player = null

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(close)

func setup_player(p: Player) -> void:
	player = p
	if player:
		if player.player_stats_component:
			if not player.player_stats_component.stats_updated.is_connected(refresh):
				player.player_stats_component.stats_updated.connect(refresh)
		if player.progression_component:
			if not player.progression_component.progression_updated.is_connected(refresh):
				player.progression_component.progression_updated.connect(refresh)
	refresh()

func _ensure_player() -> void:
	if player == null and get_tree() and get_tree().current_scene:
		var p := get_tree().current_scene.get_node_or_null("Player") as Player
		if p:
			setup_player(p)

func open(p: Player = null) -> void:
	if p != null:
		setup_player(p)
	else:
		_ensure_player()
	visible = true
	refresh()
	emit_signal("sheet_opened")

func close() -> void:
	visible = false
	emit_signal("sheet_closed")

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func is_open() -> bool:
	return visible

func refresh() -> void:
	_ensure_player()
	if player == null:
		return

	var stats := player.player_stats_component
	var prog := player.progression_component
	var health := player.health_component
	var eq := player.equipment_component

	# 1. Chủng tộc
	if stats:
		var r_def := stats.get_race_definition()
		if r_def:
			if race_label:
				race_label.text = "Chủng tộc: %s (%s)" % [r_def.display_name, r_def.title]
				race_label.modulate = r_def.theme_color
			if race_desc_label:
				race_desc_label.text = "%s\nƯu điểm: %s | Nhược điểm: %s" % [r_def.description, r_def.pros, r_def.cons]

	# 2. Cấp độ & EXP
	if prog:
		var cur_lvl := prog.level
		var cur_exp := prog.current_exp
		var req_exp := prog.get_current_target_exp()

		if level_label:
			level_label.text = "Cấp độ: Lv.%d%s" % [cur_lvl, " (Tối đa)" if prog.is_max_level() else ""]

		if exp_bar:
			if prog.is_max_level():
				exp_bar.max_value = 100
				exp_bar.value = 100
			else:
				exp_bar.max_value = max(1, req_exp)
				exp_bar.value = cur_exp

		if exp_label:
			if prog.is_max_level():
				exp_label.text = "EXP: ĐÃ ĐẠT CẤP ĐỘ TỐI ĐA (MAX)"
			else:
				exp_label.text = "EXP: %d / %d (%d%%)" % [cur_exp, req_exp, int(float(cur_exp) / float(max(1, req_exp)) * 100.0)]

	# 3. Chỉ số chiến đấu thống nhất
	if stats and health:
		if hp_stat_label:
			hp_stat_label.text = "Sinh Lực (HP): %d / %d" % [int(health.current_health), int(stats.final_max_health)]
		if mp_stat_label:
			mp_stat_label.text = "Ma Lực (MP): %d / %d" % [int(health.current_mana), int(stats.final_max_mana)]
		if atk_stat_label:
			atk_stat_label.text = "Tấn Công Cận Chiến: %d ATK" % [int(stats.final_attack)]
		if magic_stat_label:
			magic_stat_label.text = "Hệ Số Phép Thuật: x%.1f" % [stats.final_magic_multiplier]
		if regen_stat_label:
			regen_stat_label.text = "Hồi Phục Ma Lực: %.1f MP/s" % [stats.final_mana_regen]
		if speed_stat_label:
			speed_stat_label.text = "Tốc Độ Di Chuyển: %d px/s" % [int(stats.final_move_speed)]

	# 4. Trang bị
	if eq:
		var w_id := eq.get_equipped("weapon")
		var a_id := eq.get_equipped("accessory")

		if weapon_label:
			if not w_id.is_empty() and ItemDatabase.has_item(w_id):
				var w_def := ItemDatabase.get_item(w_id)
				weapon_label.text = "Vũ khí: %s (+%d ATK)" % [w_def.display_name, int(w_def.stat_modifiers.get("attack_bonus", 0))]
			else:
				weapon_label.text = "Vũ khí: [Trống]"

		if accessory_label:
			if not a_id.is_empty() and ItemDatabase.has_item(a_id):
				var a_def := ItemDatabase.get_item(a_id)
				accessory_label.text = "Phụ kiện: %s (+%d Max MP)" % [a_def.display_name, int(a_def.stat_modifiers.get("max_mana_bonus", 0))]
			else:
				accessory_label.text = "Phụ kiện: [Trống]"

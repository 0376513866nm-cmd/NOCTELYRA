class_name CharacterCreationUI
extends Control

## Giao diện Chọn Chủng Tộc & Khởi Tạo Nhân Vật (Character Creation UI) cho NOCTELYRA (M8)
## Luồng New Game: Main Menu -> Chọn tộc (Human / Elf / Demon Beast) -> Xác nhận -> Noctis Forest.
## Tuyệt đối không xóa save cũ nếu người chơi nhấn Quay Lại (Cancel).

signal race_selected(race_id: String)
signal creation_confirmed(race_id: String)
signal creation_cancelled()
signal cancelled()
signal character_confirmed(race_id: String)

const GAME_SCENE_PATH: String = "res://src/world/noctis_forest.tscn"
@export var auto_change_scene: bool = true

# UI Elements
@onready var race_title_label: Label = $Panel/Content/Header/RaceTitleLabel
@onready var race_motto_label: Label = $Panel/Content/Header/RaceMottoLabel
@onready var desc_label: Label = $Panel/Content/DescLabel
@onready var pros_label: Label = $Panel/Content/ProsLabel
@onready var cons_label: Label = $Panel/Content/ConsLabel

# Stats Display
@onready var hp_label: Label = $Panel/Content/StatsGrid/HPLabel
@onready var mp_label: Label = $Panel/Content/StatsGrid/MPLabel
@onready var atk_label: Label = $Panel/Content/StatsGrid/ATKLabel
@onready var magic_label: Label = $Panel/Content/StatsGrid/MagicLabel
@onready var regen_label: Label = $Panel/Content/StatsGrid/RegenLabel
@onready var speed_label: Label = $Panel/Content/StatsGrid/SpeedLabel

# Race Tab Buttons
@onready var human_btn: Button = $Panel/RaceTabs/HumanBtn
@onready var elf_btn: Button = $Panel/RaceTabs/ElfBtn
@onready var beast_btn: Button = $Panel/RaceTabs/BeastBtn

# Action Buttons
@onready var confirm_btn: Button = $Panel/Actions/ConfirmBtn
@onready var back_btn: Button = $Panel/Actions/BackBtn

var selected_race_id: String = "human"

func _ready() -> void:
	if human_btn:
		human_btn.pressed.connect(func(): select_race("human"))
	if elf_btn:
		elf_btn.pressed.connect(func(): select_race("elf"))
	if beast_btn:
		beast_btn.pressed.connect(func(): select_race("demon_beast"))

	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

	select_race(selected_race_id)

func select_race(r_id: String) -> void:
	if not RaceDatabase.has_race(r_id):
		r_id = "human"
	selected_race_id = r_id

	var def := RaceDatabase.get_race(r_id)
	if def == null:
		return

	if race_title_label:
		race_title_label.text = def.display_name.to_upper()
		race_title_label.modulate = def.theme_color
	if race_motto_label:
		race_motto_label.text = def.title
	if desc_label:
		desc_label.text = def.description
	if pros_label:
		pros_label.text = "Ưu điểm: " + def.pros
	if cons_label:
		cons_label.text = "Nhược điểm: " + def.cons

	if hp_label:
		hp_label.text = "Sinh Lực: %d HP" % int(def.base_health)
	if mp_label:
		mp_label.text = "Ma Lực: %d MP" % int(def.base_mana)
	if atk_label:
		atk_label.text = "Tấn Công: %d ATK" % int(def.base_attack)
	if magic_label:
		magic_label.text = "Hệ Số Phép: x%.1f" % def.magic_damage_multiplier
	if regen_label:
		regen_label.text = "Hồi MP: %.1f MP/s" % def.base_mana_regen
	if speed_label:
		speed_label.text = "Tốc Độ: %d px/s" % int(def.base_move_speed)

	# Cập nhật style nút đang chọn
	_update_tab_highlights()
	emit_signal("race_selected", selected_race_id)

func _update_tab_highlights() -> void:
	if human_btn:
		human_btn.theme_type_variation = "FlatButton" if selected_race_id != "human" else ""
	if elf_btn:
		elf_btn.theme_type_variation = "FlatButton" if selected_race_id != "elf" else ""
	if beast_btn:
		beast_btn.theme_type_variation = "FlatButton" if selected_race_id != "demon_beast" else ""

func _select_race(r_id: String) -> void:
	select_race(r_id)

func _on_cancel_pressed() -> void:
	_on_back_pressed()

func _on_back_pressed() -> void:
	# Tuyệt đối không xóa bản lưu khi người chơi nhấn Quay Lại
	creation_cancelled.emit()
	cancelled.emit()
	visible = false

func _on_confirm_pressed() -> void:
	# Chỉ khi người chơi xác nhận bắt đầu New Game mới xóa bản lưu cũ và khởi tạo
	SaveManager.delete_save()
	SaveManager.should_load_on_start = false
	ZoneManager.reset_session()
	ZoneManager.initial_race_id = selected_race_id

	creation_confirmed.emit(selected_race_id)
	character_confirmed.emit(selected_race_id)

	if auto_change_scene and get_tree():
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

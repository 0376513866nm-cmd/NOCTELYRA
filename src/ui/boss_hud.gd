class_name BossHUD
extends Control

@onready var boss_bar_panel: Control = $BossBarPanel
@onready var boss_name_label: Label = $BossBarPanel/BossNameLabel
@onready var boss_phase_label: Label = $BossBarPanel/BossPhaseLabel
@onready var boss_hp_bar: ProgressBar = $BossBarPanel/BossHPBar
@onready var boss_hp_label: Label = $BossBarPanel/BossHPBar/BossHPLabel
@onready var boss_warning_label: Label = $BossWarningBanner
@onready var boss_announcement_label: Label = $BossAnnouncementBanner

var _warning_timer: float = 0.0
var _announcement_timer: float = 0.0

func _ready() -> void:
	hide_boss()

func _process(delta: float) -> void:
	if _warning_timer > 0.0:
		_warning_timer -= delta
		if _warning_timer <= 0.0 and boss_warning_label:
			boss_warning_label.visible = false

	if _announcement_timer > 0.0:
		_announcement_timer -= delta
		if _announcement_timer <= 0.0 and boss_announcement_label:
			boss_announcement_label.visible = false

func show_boss(boss_name: String = "Lunareth — Linh Lộc Nguyệt Thực", max_hp: float = 320.0) -> void:
	if boss_bar_panel:
		boss_bar_panel.visible = true
	if boss_name_label:
		boss_name_label.text = boss_name
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = max_hp
	if boss_hp_label:
		boss_hp_label.text = "HP: %d/%d" % [int(max_hp), int(max_hp)]
	set_phase(1)

func hide_boss() -> void:
	if boss_bar_panel:
		boss_bar_panel.visible = false
	if boss_warning_label:
		boss_warning_label.visible = false
	if boss_announcement_label:
		boss_announcement_label.visible = false
	_warning_timer = 0.0
	_announcement_timer = 0.0

func set_health(current: float, maximum: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = maximum
		boss_hp_bar.value = current
	if boss_hp_label:
		boss_hp_label.text = "HP: %d/%d" % [int(max(0, current)), int(maximum)]

func set_phase(phase: int) -> void:
	if boss_phase_label:
		if phase == 2:
			boss_phase_label.text = "[GIAI ĐOẠN 2 - HẮC NGUYỆT]"
			boss_phase_label.modulate = Color(1.0, 0.4, 0.9, 1.0)
			show_announcement("LUNARETH GIẢI PHÓNG HẮC NGUYỆT MA LỰC!")
		else:
			boss_phase_label.text = "[GIAI ĐOẠN 1]"
			boss_phase_label.modulate = Color(0.4, 0.9, 1.0, 1.0)

func show_warning(skill_name: String, duration: float = 3.0) -> void:
	if boss_warning_label:
		boss_warning_label.text = "⚠️ CẢNH BÁO: %s!" % skill_name.to_upper()
		boss_warning_label.visible = true
		_warning_timer = duration

func show_announcement(msg: String, duration: float = 2.5) -> void:
	if boss_announcement_label:
		boss_announcement_label.text = msg
		boss_announcement_label.visible = true
		_announcement_timer = duration

func is_boss_visible() -> bool:
	return boss_bar_panel != null and boss_bar_panel.visible

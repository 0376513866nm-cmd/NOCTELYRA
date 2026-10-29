class_name PauseMenuUI
extends Control

signal resume_requested()
signal settings_opened()
signal settings_closed()
signal save_requested()
signal quit_requested()

@onready var pause_panel: Panel = $Panel
@onready var resume_btn: Button = $Panel/ResumeBtn
@onready var settings_btn: Button = $Panel/SettingsBtn
@onready var save_btn: Button = $Panel/SaveBtn
@onready var quit_btn: Button = $Panel/QuitBtn

@onready var settings_panel: Panel = $SettingsPanel
@onready var zoom_out_btn: Button = $SettingsPanel/ZoomControls/ZoomOutBtn
@onready var zoom_label: Label = $SettingsPanel/ZoomControls/ZoomLabel
@onready var zoom_in_btn: Button = $SettingsPanel/ZoomControls/ZoomInBtn
@onready var zoom_reset_btn: Button = $SettingsPanel/ZoomControls/ZoomResetBtn
@onready var zoom_slider: HSlider = $SettingsPanel/ZoomSlider
@onready var fullscreen_btn: Button = $SettingsPanel/FullscreenBtn
@onready var fps_btn: Button = $SettingsPanel/FPSBtn
@onready var settings_close_btn: Button = $SettingsPanel/SettingsCloseBtn

func _ready() -> void:
	visible = false
	if pause_panel:
		pause_panel.visible = true
	if settings_panel:
		settings_panel.visible = false

	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if settings_close_btn:
		settings_close_btn.pressed.connect(_on_settings_close_pressed)

func open() -> void:
	visible = true
	if pause_panel:
		pause_panel.visible = true
	if settings_panel:
		settings_panel.visible = false

func close() -> void:
	visible = false
	if settings_panel:
		settings_panel.visible = false

func is_open() -> bool:
	return visible

func open_settings() -> void:
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = true
	settings_opened.emit()

func close_settings() -> void:
	if settings_panel:
		settings_panel.visible = false
	if pause_panel:
		pause_panel.visible = true
	settings_closed.emit()

func is_settings_open() -> bool:
	return settings_panel != null and settings_panel.visible

func _on_resume_pressed() -> void:
	resume_requested.emit()

func _on_settings_pressed() -> void:
	open_settings()

func _on_settings_close_pressed() -> void:
	close_settings()

func _on_save_pressed() -> void:
	save_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()

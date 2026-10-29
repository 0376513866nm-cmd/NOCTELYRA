class_name EndScreenUI
extends Control

signal retry_requested()
signal victory_dismissed()

@onready var game_over_panel: Control = $GameOverPanel
@onready var retry_button: Button = $GameOverPanel/Panel/RetryBtn
@onready var victory_panel: Control = $VictoryPanel
@onready var victory_title: Label = $VictoryPanel/Panel/Title
@onready var victory_subtitle: Label = $VictoryPanel/Panel/Subtitle
@onready var victory_continue_btn: Button = $VictoryPanel/Panel/ContinueBtn

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if victory_panel:
		victory_panel.visible = false

	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if victory_continue_btn:
		victory_continue_btn.pressed.connect(_on_victory_continue_pressed)

func show_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = true

func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false

func is_game_over_visible() -> bool:
	return game_over_panel != null and game_over_panel.visible

func show_victory(title: String, subtitle: String) -> void:
	if victory_panel:
		if victory_title:
			victory_title.text = title
		if victory_subtitle:
			victory_subtitle.text = subtitle
		victory_panel.visible = true

func hide_victory() -> void:
	if victory_panel:
		victory_panel.visible = false

func is_victory_visible() -> bool:
	return victory_panel != null and victory_panel.visible

func _on_retry_pressed() -> void:
	hide_game_over()
	retry_requested.emit()

func _on_victory_continue_pressed() -> void:
	hide_victory()
	victory_dismissed.emit()

extends Node2D

@onready var player: Player = $Player
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var pause_menu: Control = $CanvasLayer/PauseMenu

func _ready() -> void:
	pause_menu.visible = false
	if player:
		player.state_changed.connect(_on_player_state_changed)
		_on_player_state_changed("IDLE")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _on_player_state_changed(new_state: String) -> void:
	if state_label:
		state_label.text = "State: %s" % new_state

func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

func _on_resume_button_pressed() -> void:
	_toggle_pause()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

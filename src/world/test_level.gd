extends Node2D

@onready var player: Player = $Player
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var pause_controller: PauseController = $PauseController

func _ready() -> void:
	# Gameplay level đặt PROCESS_MODE_PAUSABLE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if player:
		player.state_changed.connect(_on_player_state_changed)
		_on_player_state_changed("IDLE")

func _on_player_state_changed(new_state: String) -> void:
	if state_label:
		state_label.text = "State: %s" % new_state

func _on_resume_button_pressed() -> void:
	var ctrl = pause_controller if pause_controller else get_node_or_null("PauseController")
	if ctrl:
		ctrl.resume()
	else:
		get_tree().paused = false
		var menu = get_node_or_null("CanvasLayer/PauseMenu")
		if menu:
			menu.visible = false

func _on_quit_button_pressed() -> void:
	get_tree().quit()

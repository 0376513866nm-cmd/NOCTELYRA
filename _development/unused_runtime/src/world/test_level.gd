extends Node2D

@onready var player: Player = $Player
@onready var state_label: Label = $CanvasLayer/HUD/StateLabel
@onready var hp_bar: ProgressBar = $CanvasLayer/HUD/VBoxBars/HPBar
@onready var mp_bar: ProgressBar = $CanvasLayer/HUD/VBoxBars/MPBar
@onready var pause_controller: PauseController = $PauseController

func _ready() -> void:
	# Gameplay level đặt PROCESS_MODE_PAUSABLE
	process_mode = Node.PROCESS_MODE_PAUSABLE

	if player:
		# Thêm Player vào group "players" để Enemy dễ nhận diện
		player.add_to_group("players")
		player.state_changed.connect(_on_player_state_changed)
		_on_player_state_changed("IDLE")

		var health_comp: HealthComponent = player.get_node_or_null("HealthComponent")
		if health_comp:
			health_comp.health_changed.connect(_on_player_health_changed)
			health_comp.mana_changed.connect(_on_player_mana_changed)
			_on_player_health_changed(health_comp.current_health, health_comp.max_health)
			_on_player_mana_changed(health_comp.current_mana, health_comp.max_mana)

func _on_player_state_changed(new_state: String) -> void:
	if state_label:
		state_label.text = "State: %s" % new_state

func _on_player_health_changed(cur: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_v
		hp_bar.value = cur

func _on_player_mana_changed(cur: float, max_v: float) -> void:
	if mp_bar:
		mp_bar.max_value = max_v
		mp_bar.value = cur

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

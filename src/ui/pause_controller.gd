class_name PauseController
extends Node

@export var pause_menu: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_menu:
		pause_menu.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var ui := _get_game_ui()
		if ui and ui.is_inventory_open():
			ui.close_inventory()
			get_viewport().set_input_as_handled()
			return

		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var ui := _get_game_ui()
	if ui:
		ui.toggle_pause_menu()
		return
	var tree := get_tree()
	if tree == null:
		return
	if tree.paused:
		resume()
	else:
		pause()

func pause() -> void:
	var ui := _get_game_ui()
	if ui:
		ui.open_pause_menu()
		return
	var tree := get_tree()
	if tree:
		tree.paused = true
	if pause_menu:
		pause_menu.visible = true
	_set_pause_input_lock(true)

func resume() -> void:
	var ui := _get_game_ui()
	if ui:
		ui.close_pause_menu()
		return
	var tree := get_tree()
	if tree:
		tree.paused = false
	if pause_menu:
		pause_menu.visible = false
	_set_pause_input_lock(false)

func _get_game_ui() -> GameUI:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		if "game_ui" in cur_scene and cur_scene.game_ui is GameUI:
			return cur_scene.game_ui
		var ui = cur_scene.get_node_or_null("GameUI") as GameUI
		if ui:
			return ui
	if get_tree():
		var uis = get_tree().get_nodes_in_group(GameGroups.GAME_UI)
		if uis.size() > 0:
			return uis[0] as GameUI
	return null

func _set_pause_input_lock(blocked: bool) -> void:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		var p = cur_scene.get_node_or_null("Player")
		if p and p.has_method("set_input_blocked"):
			p.set_input_blocked("pause_menu", blocked)

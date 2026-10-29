class_name PauseController
extends Node

@export var pause_menu: Control

func _ready() -> void:
	# PauseController luôn luôn xử lý input bất kể game đang pause hay không
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_menu:
		pause_menu.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# Nếu túi đồ đang mở thì Esc đóng túi đồ trước thay vì mở PauseMenu
		var cur_scene = get_tree().current_scene if get_tree() else null
		if cur_scene:
			var ui := cur_scene.get_node_or_null("GameUI") as GameUI
			if ui and ui.is_inventory_open():
				ui.close_inventory()
				get_viewport().set_input_as_handled()
				return

		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.paused:
		resume()
	else:
		pause()

func pause() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = true
	if pause_menu:
		pause_menu.visible = true
	_set_pause_input_lock(true)

func resume() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	if pause_menu:
		pause_menu.visible = false
	_set_pause_input_lock(false)

func _set_pause_input_lock(blocked: bool) -> void:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		var p = cur_scene.get_node_or_null("Player")
		if p and p.has_method("set_input_blocked"):
			p.set_input_blocked("pause_menu", blocked)

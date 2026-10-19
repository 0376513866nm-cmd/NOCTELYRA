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
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var is_paused := not tree.paused
	tree.paused = is_paused
	if pause_menu:
		pause_menu.visible = is_paused

func resume() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	if pause_menu:
		pause_menu.visible = false

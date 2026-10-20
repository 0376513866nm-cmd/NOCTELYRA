class_name InteractionCoordinator
extends Node

## Bộ điều phối input tập trung cho hệ thống tương tác và hội thoại (M2.1)
## Ngăn chặn race condition giữa NPC và GameUI do thứ tự node trong Scene Tree.

@export var game_ui: GameUI

func _ready() -> void:
	add_to_group("interaction_coordinator")
	_ensure_game_ui()

func _ensure_game_ui() -> void:
	if game_ui == null:
		var cur = get_tree().current_scene if get_tree() else null
		if cur:
			game_ui = cur.get_node_or_null("GameUI") as GameUI

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	_ensure_game_ui()

	# 1. Khi đang mở hội thoại: E chỉ chuyển sang câu tiếp theo hoặc đóng hội thoại
	if game_ui and game_ui.is_dialogue_open():
		game_ui.advance_dialogue()
		get_viewport().set_input_as_handled()
		return

	# 2. Khi hội thoại vừa đóng: grace cooldown ngăn chặn nhấn đúp re-open tức thì
	if game_ui and game_ui.is_dialogue_cooling_down():
		get_viewport().set_input_as_handled()
		return

	# 3. Khi chưa mở hội thoại: E dùng để kích hoạt tương tác với NPC gần nhất
	var target_npc := _find_nearby_interactable_npc()
	if target_npc:
		target_npc.trigger_interaction()
		get_viewport().set_input_as_handled()
		return

func _find_nearby_interactable_npc() -> NPC:
	var npcs = get_tree().get_nodes_in_group("npcs")
	for n in npcs:
		if n is NPC and n.is_interactable():
			return n
	return null

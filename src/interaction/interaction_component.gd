class_name InteractionComponent
extends Area2D

signal interaction_available(interactable: Node)
signal interaction_unavailable(interactable: Node)

@export var prompt_text: String = "Nhấn E để nói chuyện"
var is_player_nearby: bool = false
var _nearby_players: Array[Node] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Chỉ nhận Player (Layer 2)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		if not body in _nearby_players:
			_nearby_players.append(body)
		is_player_nearby = true
		emit_signal("interaction_available", get_parent())

func _on_body_exited(body: Node) -> void:
	if body in _nearby_players:
		_nearby_players.erase(body)
	if _nearby_players.size() == 0:
		is_player_nearby = false
		emit_signal("interaction_unavailable", get_parent())

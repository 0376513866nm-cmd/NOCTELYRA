class_name MagicGate
extends StaticBody2D

## Cổng Ma Pháp chặn lối vào Đấu trường Boss Lunareth (M4)
## Chỉ mở khóa sau khi hoàn thành và trả nhiệm vụ tiêu diệt quái vật cho Elyra.
## Ngăn cản tuyệt đối việc vượt qua bằng Dash hay Double Jump khi đang khóa.

signal gate_opened()

@export var is_open: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual_barrier: ColorRect = $VisualBarrier
@onready var runes: Label = $VisualBarrier/RuneLabel
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	if is_open:
		open_gate(false)
	else:
		close_gate()
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)

func open_gate(notify: bool = true) -> void:
	is_open = true
	if collision_shape:
		collision_shape.disabled = true
	if visual_barrier:
		visual_barrier.color = Color(0.2, 0.8, 1.0, 0.2)
	if runes:
		runes.text = "[PHONG ẤN ĐÃ GIẢI TRỪ]"
		runes.modulate = Color(0.4, 1.0, 0.8, 0.8)
	emit_signal("gate_opened")

func close_gate() -> void:
	is_open = false
	if collision_shape:
		collision_shape.disabled = false
	if visual_barrier:
		visual_barrier.color = Color(0.65, 0.15, 0.85, 0.85)
	if runes:
		runes.text = "[PHONG ẤN CỔ TỰ]\nCần hoàn thành nhiệm vụ Elyra!"
		runes.modulate = Color(1.0, 0.6, 0.9, 1.0)

func update_quest_status(quest: QuestData) -> void:
	if quest and quest.current_state == QuestData.State.COMPLETED:
		if not is_open:
			open_gate(true)
	else:
		if is_open:
			close_gate()

func _on_body_entered(body: Node) -> void:
	if body is Player and not is_open:
		var cur_scene = get_tree().current_scene if get_tree() else null
		if cur_scene and "game_ui" in cur_scene and cur_scene.game_ui:
			cur_scene.game_ui.show_notification("Cổng Ma Pháp bị phong ấn! Hãy hoàn thành nhiệm vụ của Elyra để giải trừ.")

class_name MagicGate
extends StaticBody2D

## Cổng Ma Pháp chặn lối vào Đấu trường Boss Lunareth (M4)
## Chỉ mở khóa sau khi hoàn thành và trả nhiệm vụ tiêu diệt quái vật cho Eiran.
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
		collision_shape.set_deferred("disabled", true)
	if visual_barrier:
		visual_barrier.color = Color(0.2, 0.8, 1.0, 0.2)
	if runes:
		runes.text = "[PHONG ẤN ĐÃ GIẢI TRỪ]"
		runes.modulate = Color(0.4, 1.0, 0.8, 0.8)
	emit_signal("gate_opened")

func close_gate() -> void:
	is_open = false
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if visual_barrier:
		visual_barrier.color = Color(0.65, 0.15, 0.85, 0.85)
	if runes:
		runes.text = "[PHONG ẤN CỔ TỰ]\nCần hoàn thành nhiệm vụ Eiran!"
		runes.modulate = Color(1.0, 0.6, 0.9, 1.0)

func update_quest_status(quest: Variant = null) -> void:
	var completed := false
	if quest is QuestData:
		completed = (quest.current_state == QuestData.State.COMPLETED)
	elif quest is int:
		completed = (quest == 3)
	elif quest is bool:
		completed = quest
	else:
		var p: Player = null
		if get_parent():
			p = get_parent().get_node_or_null("Player") as Player
		if p == null and get_tree() and get_tree().current_scene:
			p = get_tree().current_scene.get_node_or_null("Player") as Player
		if p and p.quest_journal_component:
			completed = (p.quest_journal_component.get_quest_state("quest_noctis_purify") == QuestDefinition.State.COMPLETED)
		elif not completed and get_parent():
			var qm = get_parent().get_node_or_null("QuestManager") as QuestManager
			if qm and qm.current_quest:
				completed = (qm.current_quest.current_state == QuestData.State.COMPLETED)

	if completed:
		if not is_open:
			open_gate(true)
	else:
		if is_open:
			close_gate()

func _on_body_entered(body: Node) -> void:
	if body is Player and not is_open:
		var cur_scene = get_tree().current_scene if get_tree() else null
		if cur_scene and "game_ui" in cur_scene and cur_scene.game_ui:
			cur_scene.game_ui.show_notification("Cổng Ma Pháp bị phong ấn! Hãy hoàn thành nhiệm vụ của Eiran để giải trừ.")

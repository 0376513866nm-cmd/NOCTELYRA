class_name AncientCrystal
extends Area2D

## Tinh Thạch Cổ (Ancient Crystal) trong Thánh Lâm Elyndra (Milestone M6)
## Cho phép người chơi tương tác bằng phím E để tìm hiểu cốt truyện và nguồn gốc ma lực.

@onready var prompt_label: Label = $PromptLabel
@onready var visual_crystal: Node2D = $VisualCrystal

var _player_in_range: bool = false
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2 # Player (Layer 2)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if prompt_label:
		prompt_label.text = "[E] Đọc văn tự Cổ Tinh Thạch"
		prompt_label.visible = false

func _process(delta: float) -> void:
	_anim_time += delta * 2.0
	if visual_crystal:
		var float_offset: float = sin(_anim_time * 2.0) * 4.0
		visual_crystal.position.y = -40.0 + float_offset

func is_interactable() -> bool:
	return _player_in_range

func trigger_interaction() -> void:
	var ui := _get_game_ui()
	if ui == null:
		return

	if ui.is_dialogue_open() or ui.is_dialogue_cooling_down():
		return

	var lore_lines: Array[String] = [
		"[Văn tự cổ phát sáng]: 'Từ thuở vạn vật phân chia, thế giới NOCTELYRA được bảo hộ bởi ba trụ cột ma mạch.'",
		"'Nhân tộc canh giữ Bìa Rừng và các cổ tự. Tinh Linh gìn giữ Thánh Lâm và sinh khí đất trời.'",
		"'Quỷ tộc bảo vệ Cổng Vực Sâu và sức mạnh địa nhiệt. Ba tộc hòa hợp thì ma triều êm ả, phân tranh thì bóng tối trỗi dậy.'",
		"'Kẻ mang dấu ấn Nguyệt Thực sẽ mở lối qua các vùng đất, kết nối lại những gì đã rạn nứt.'"
	]

	ui.show_dialogue("Cổ Tinh Thạch", lore_lines, "none")

func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _get_game_ui() -> GameUI:
	var cur = get_tree().current_scene if get_tree() else null
	if cur:
		var ui = cur.get_node_or_null("GameUI") as GameUI
		if ui: return ui
	var p = get_parent()
	if p:
		var ui = p.get_node_or_null("GameUI") as GameUI
		if ui: return ui
	return null

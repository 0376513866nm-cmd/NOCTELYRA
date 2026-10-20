class_name NPC
extends CharacterBody2D

signal dialogue_requested(npc: NPC, dialogue_lines: Array[String], quest_action: String)

@export var npc_name: String = "Elyra"
@export var title: String = "Người Hướng Dẫn Làng Ánh Nguyệt"

@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if interaction_component:
		interaction_component.interaction_available.connect(_on_interaction_available)
		interaction_component.interaction_unavailable.connect(_on_interaction_unavailable)

func _unhandled_input(event: InputEvent) -> void:
	if interaction_component and interaction_component.is_player_nearby:
		if event.is_action_pressed("interact"):
			trigger_interaction()
			get_viewport().set_input_as_handled()

func trigger_interaction() -> void:
	var quest_mgr: QuestManager = _get_quest_manager()
	var lines: Array[String] = []
	var action: String = "none"

	if quest_mgr and quest_mgr.current_quest:
		var q_state = quest_mgr.current_quest.current_state
		match q_state:
			QuestData.State.NOT_STARTED:
				lines = [
					"Chào dũng sĩ trẻ! Ta là Elyra, người trông coi Làng Ánh Nguyệt.",
					"Ma lực sâu trong Rừng Hắc Nguyệt đang hỗn loạn bất thường, khiến các sinh vật hoang dã bị tha hóa.",
					"Ngươi có thể tiến vào rừng tiêu diệt 3 sinh vật bị ma hóa để bảo vệ ranh giới làng được không?"
				]
				action = "start_quest"
			QuestData.State.ACTIVE:
				lines = [
					"Hãy cẩn trọng khi bước qua ranh giới Rừng Hắc Nguyệt.",
					"Ngươi đã diệt được %d/%d sinh vật ma hóa. Mau hoàn thành giúp dân làng nhé!" % [quest_mgr.current_quest.current_amount, quest_mgr.current_quest.target_amount]
				]
				action = "none"
			QuestData.State.READY_TO_TURN_IN:
				lines = [
					"Ngươi đã trở về an toàn! Ma khí quanh bìa rừng đã lắng dịu đáng kể.",
					"Xin hãy nhận 50 Vàng và ta sẽ dùng quang ma pháp thanh tẩy, hồi phục trọn vẹn sinh lực cho ngươi!"
				]
				action = "complete_quest"
			QuestData.State.COMPLETED:
				lines = [
					"Cảm ơn ngươi đã bảo vệ Làng Ánh Nguyệt.",
					"Hãy tiếp tục rèn luyện kỹ năng kiếm thuật (J) và ma pháp (K) để sẵn sàng cho những thử thách lớn hơn phía trước!"
				]
				action = "none"
	else:
		lines = ["Xin chào dũng sĩ! Chúc ngươi một ngày bình an dưới ánh sáng mặt trăng."]

	emit_signal("dialogue_requested", self, lines, action)

func _get_quest_manager() -> QuestManager:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		var mgr = cur_scene.get_node_or_null("QuestManager") as QuestManager
		if mgr:
			return mgr
	var p = get_parent()
	if p:
		var mgr = p.get_node_or_null("QuestManager") as QuestManager
		if mgr:
			return mgr
	return null

func _on_interaction_available(_node: Node) -> void:
	if prompt_label:
		prompt_label.visible = true

func _on_interaction_unavailable(_node: Node) -> void:
	if prompt_label:
		prompt_label.visible = false

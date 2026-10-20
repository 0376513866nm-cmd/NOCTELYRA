class_name NPC
extends CharacterBody2D

signal dialogue_requested(npc: NPC, dialogue_lines: Array[String], quest_action: String)

@export var npc_name: String = "Elyra"
@export var title: String = "Người Hướng Dẫn Làng Ánh Nguyệt"

@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	add_to_group("npcs")
	if prompt_label:
		prompt_label.visible = false
	if interaction_component:
		interaction_component.interaction_available.connect(_on_interaction_available)
		interaction_component.interaction_unavailable.connect(_on_interaction_unavailable)

func is_interactable() -> bool:
	return interaction_component != null and interaction_component.is_player_nearby

func _unhandled_input(event: InputEvent) -> void:
	# Nếu có InteractionCoordinator điều phối trung tâm thì để coordinator xử lý
	if get_tree() and get_tree().get_nodes_in_group("interaction_coordinator").size() > 0:
		return
	if is_interactable() and event.is_action_pressed("interact"):
		trigger_interaction()
		get_viewport().set_input_as_handled()

func trigger_interaction() -> void:
	# Không cho phép kích hoạt nếu hội thoại đang mở hoặc đang trong grace cooldown
	var cur_ui: GameUI = _get_game_ui()
	if cur_ui and (cur_ui.is_dialogue_open() or cur_ui.is_dialogue_cooling_down()):
		return

	var quest_mgr: QuestManager = _get_quest_manager()
	var lines: Array[String] = []
	var action: String = "none"

	if npc_name == "Kaelis":
		lines = [
			"Chào lữ khách từ Rừng Hắc Nguyệt. Ta là Kaelis, Người Canh Giữ Tinh Mạch của Thánh Lâm Elyndra.",
			"Ngươi mang theo ma lực thanh tẩy thuần khiết... Lunareth cuối cùng đã được giải thoát khỏi sự tha hóa bóng tối.",
			"Thánh Lâm này là nơi Tinh Mạch cổ xưa của NOCTELYRA hội tụ, nuôi dưỡng vạn vật bằng ma năng nguyên sơ.",
			"Cổ Tinh Thạch gần đây còn lưu giữ những ghi chép về nguồn gốc ma pháp thuở sơ khai, ngươi hãy thử chiêm nghiệm.",
			"Phía đông là Tiền Đồn Vharok của Quỷ tộc bán thú. Hãy giữ thái độ hòa hảo, họ là những chiến binh trọng danh dự."
		]
		action = "none"
	elif npc_name == "Rhaek":
		lines = [
			"Đứng lại, lữ khách! Ngươi đang diện kiến Tiền Đồn Vharok của Gia tộc Hắc Nham Quỷ tộc.",
			"Ta ngửi thấy mùi hương thảo mộc của Tinh Linh và ánh trăng của Rừng Noctis trên người ngươi.",
			"Nhân tộc và Tinh Linh thường nghĩ Quỷ tộc chúng ta là lũ dã thú cuồng sát... Đó là định kiến của kẻ yếu đuối!",
			"Quỷ tộc bán thú chúng ta sống theo luật danh dự, tôn thờ gia tộc và sức mạnh rèn giũa từ lửa dung nham.",
			"Miễn là ngươi không rút vũ khí gây hấn, Tiền Đồn Vharok luôn tôn trọng và tiếp đón những vị khách có thực lực."
		]
		action = "none"
	elif quest_mgr and quest_mgr.current_quest and npc_name == "Elyra":
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
	if cur_ui and not dialogue_requested.get_connections():
		cur_ui.show_dialogue(npc_name, lines, action)

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

func _get_game_ui() -> GameUI:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		var ui = cur_scene.get_node_or_null("GameUI") as GameUI
		if ui:
			return ui
	var p = get_parent()
	if p:
		var ui = p.get_node_or_null("GameUI") as GameUI
		if ui:
			return ui
	return null

func _on_interaction_available(_node: Node) -> void:
	if prompt_label:
		prompt_label.visible = true

func _on_interaction_unavailable(_node: Node) -> void:
	if prompt_label:
		prompt_label.visible = false

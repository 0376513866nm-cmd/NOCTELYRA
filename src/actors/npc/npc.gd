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
	var player: Player = _get_player()
	var lines: Array[String] = []
	var action: String = "none"

	if npc_name == "Kaelis":
		var p_journal = player.quest_journal_component if player else null
		var q_state = QuestDefinition.QuestState.NOT_STARTED
		if p_journal:
			q_state = p_journal.get_quest_state("quest_elyndra_cleansing")
		match q_state:
			QuestDefinition.QuestState.NOT_STARTED:
				lines = [
					"Chào lữ khách từ Rừng Hắc Nguyệt. Ta là Kaelis, Người Canh Giữ Tinh Mạch của Thánh Lâm Elyndra.",
					"Ma khí bóng tối đang len lỏi vào các bụi nấm, biến chúng thành Nấm Ma Hóa làm ô nhiễm dòng chảy Tinh Mạch.",
					"Ngươi có thể giúp ta tiêu diệt 3 Nấm Ma Hóa (Corrupted Mooncap) để thanh tẩy vùng này không?"
				]
				action = "start_quest:quest_elyndra_cleansing"
			QuestDefinition.QuestState.ACTIVE:
				var prog: int = p_journal.get_quest_progress("quest_elyndra_cleansing") if p_journal else 0
				lines = [
					"Hãy cẩn trọng khi bước qua những cụm nấm phát sáng ma thuật.",
					"Tiến độ hiện tại: %d/3 Nấm Ma Hóa. Cố gắng lên nhé lữ khách!" % prog
				]
				action = "none"
			QuestDefinition.QuestState.READY_TO_TURN_IN:
				lines = [
					"Thật phi thường! Dòng chảy Tinh Mạch đã bắt đầu lưu thông thanh khiết trở lại.",
					"Xin hãy nhận 80 Vàng và 2 Bình Máu như lời cảm tạ chân thành từ Thánh Lâm Elyndra!"
				]
				action = "complete_quest:quest_elyndra_cleansing"
			QuestDefinition.QuestState.COMPLETED:
				lines = [
					"Cảm ơn ngươi đã bảo vệ Thánh Lâm. Nơi này từng là điểm giao thoa hòa bình giữa Tinh Linh và Quỷ tộc bán thú từ thời cổ đại.",
					"Quỷ tộc ở Tiền Đồn Vharok tuy thô ráp nhưng rất coi trọng danh dự và hiệp ước. Hãy ghé thăm họ nếu ngươi cần thêm thử thách."
				]
				action = "none"
	elif npc_name == "Rhaek":
		var p_journal = player.quest_journal_component if player else null
		var q_state = QuestDefinition.QuestState.NOT_STARTED
		if p_journal:
			var inv = player.inventory_component if player else null
			p_journal.update_item_collection(inv)
			q_state = p_journal.get_quest_state("quest_vharok_embers")
		match q_state:
			QuestDefinition.QuestState.NOT_STARTED:
				lines = [
					"Đứng lại, lữ khách! Ta là Rhaek, Chiến Binh Tiền Đồn của Gia tộc Hắc Nham Quỷ tộc.",
					"Lò rèn của Tiền Đồn Vharok đang cạn kiệt năng lượng. Chúng ta cần Lõi Tàn Hỏa (Ember Core) từ đá núi lửa để duy trì ngọn lửa rèn.",
					"Hãy thu thập giúp ta 3 Lõi Tàn Hỏa, ta sẽ thù lao xứng đáng cho ngươi!"
				]
				action = "start_quest:quest_vharok_embers"
			QuestDefinition.QuestState.ACTIVE:
				var prog: int = p_journal.get_quest_progress("quest_vharok_embers") if p_journal else 0
				lines = [
					"Ngươi có thể tìm Lõi Tàn Hỏa quanh các mỏm đá vách núi hoặc tiêu diệt Lũ Thằn Lằn Tro Tàn (Ember Lizard).",
					"Ngươi hiện có %d/3 Lõi Tàn Hỏa. Hãy mau tìm đủ mang về đây!" % prog
				]
				action = "none"
			QuestDefinition.QuestState.READY_TO_TURN_IN:
				lines = [
					"Hahaha! Tốt lắm! Đúng là Lõi Tàn Hỏa rực lửa nguyên chất!",
					"Quỷ tộc bán thú luôn sòng phẳng: đây là 100 Vàng và 3 Mảnh Chân Ma dành cho lòng quả cảm của ngươi!"
				]
				action = "complete_quest:quest_vharok_embers"
			QuestDefinition.QuestState.COMPLETED:
				lines = [
					"Lò rèn của tiền đồn đã rực cháy trở lại! Ngươi đã chứng minh được dũng khí của một chiến binh thực thụ.",
					"Vùng đất cằn cỗi này còn nhiều mối đe dọa rình rập. Hãy giữ vững tinh thần cảnh giác, người bạn của Quỷ tộc!"
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

func _get_player() -> Player:
	var cur_scene = get_tree().current_scene if get_tree() else null
	if cur_scene:
		var p = cur_scene.get_node_or_null("Player") as Player
		if p:
			return p
	var par = get_parent()
	if par:
		var p = par.get_node_or_null("Player") as Player
		if p:
			return p
	if get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			return players[0] as Player
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

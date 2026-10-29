class_name NPC
extends CharacterBody2D

signal dialogue_requested(npc: NPC, dialogue_lines: Array[String], quest_action: String)

@export var npc_name: String = "Eiran"
@export var title: String = "Người Giữ Đèn Nguyệt"
@export var quest_id: String = ""

@onready var interaction_component: InteractionComponent = $InteractionComponent
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	add_to_group(GameGroups.NPCS)
	if prompt_label:
		prompt_label.visible = false
	if interaction_component:
		interaction_component.interaction_available.connect(_on_interaction_available)
		interaction_component.interaction_unavailable.connect(_on_interaction_unavailable)

func is_interactable() -> bool:
	return interaction_component != null and interaction_component.is_player_nearby

func _unhandled_input(event: InputEvent) -> void:
	# Nếu có InteractionCoordinator điều phối trung tâm thì để coordinator xử lý
	if get_tree() and get_tree().get_nodes_in_group(GameGroups.INTERACTION_COORDINATOR).size() > 0:
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

	if not quest_id.is_empty():
		var interaction := _get_catalog_quest_interaction(player)
		lines = interaction.get("lines", [])
		action = str(interaction.get("action", "none"))
	elif npc_name == "Kaelis":
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
				var inv := player.inventory_component if player else null
				if p_journal and not p_journal.can_turn_in("quest_elyndra_cleansing", inv):
					lines = [
						"Ngươi đã thanh tẩy Thánh Lâm, nhưng túi đồ của ngươi hiện đã đầy!",
						"Hãy dọn chỗ trống trong túi đồ trước khi nhận thưởng nhé."
					]
					action = "none"
				else:
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
				var inv := player.inventory_component if player else null
				if p_journal and not p_journal.can_turn_in("quest_vharok_embers", inv):
					lines = [
						"Ngươi đã thu thập đủ Lõi Tàn Hỏa, nhưng túi đồ của ngươi chật cứng rồi!",
						"Hãy dọn chỗ trống trong túi đồ rồi quay lại đây nhận thưởng. Quỷ tộc không để bạn hữu chịu thiệt!"
					]
					action = "none"
				else:
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
	elif quest_mgr and quest_mgr.current_quest and npc_name in ["Eiran", "Elyra"]:
		var q_state = quest_mgr.current_quest.current_state
		match q_state:
			QuestData.State.NOT_STARTED:
				lines = [
					"Mừng con đã trở về Tổ Ấm Đèn Nguyệt. Đêm nay gió rừng có chút xao động...",
					"Ma lực sâu trong Rừng Hắc Nguyệt đang hỗn loạn bất thường, khiến các sinh vật hoang dã bị tha hóa.",
					"Uống một ngụm trà thảo mộc ấm rồi tiến vào rừng tiêu diệt 3 sinh vật bị ma hóa giúp ta được không?"
				]
				action = "start_quest"
			QuestData.State.ACTIVE:
				lines = [
					"Hãy cẩn trọng khi bước qua ranh giới Rừng Hắc Nguyệt nhé.",
					"Tiến độ hiện tại: %d/%d sinh vật ma hóa. Mau hoàn thành rồi về sưởi ấm cạnh bếp lửa nhé!" % [quest_mgr.current_quest.current_amount, quest_mgr.current_quest.target_amount]
				]
				action = "none"
			QuestData.State.READY_TO_TURN_IN:
				lines = [
					"Con đã trở về an toàn rồi! Mầm và Lumi cứ ngóng con mãi ngoài hiên đấy.",
					"Ma khí quanh bìa rừng đã lắng dịu. Hãy nhận 50 Vàng và để ta dùng quang ma pháp thanh tẩy, hồi phục trọn vẹn sinh lực cho con!"
				]
				action = "complete_quest"
			QuestData.State.COMPLETED:
				lines = [
					"Cảm ơn con đã bảo vệ sự bình yên của Tổ Ấm Đèn Nguyệt.",
					"Mỗi khi mỏi mệt, con luôn có thể trở về đây ngồi bên bếp lửa để nghỉ ngơi và hồi phục.",
					"Hãy tiếp tục rèn luyện kỹ năng kiếm thuật (J) và ma pháp (K) để sẵn sàng cho những thử thách lớn hơn phía trước!"
				]
				action = "none"
	else:
		lines = ["Xin chào dũng sĩ! Chúc ngươi một ngày bình an dưới ánh sáng mặt trăng."]

	emit_signal("dialogue_requested", self, lines, action)
	if cur_ui and not dialogue_requested.get_connections():
		cur_ui.show_dialogue(npc_name, lines, action)

func _get_catalog_quest_interaction(player: Player) -> Dictionary:
	var definition := ContentRegistry.get_quest(quest_id)
	var journal := player.quest_journal_component if player else null
	var inventory := player.inventory_component if player else null
	if definition == null or journal == null:
		return {"lines": ["Ta chưa có nhiệm vụ nào dành cho ngươi lúc này."], "action": "none"}
	if definition.quest_type == QuestDefinition.QuestType.COLLECT_ITEMS:
		journal.update_item_collection(inventory)
	var state := journal.get_quest_state(quest_id)
	var progress := journal.get_quest_progress(quest_id)
	match state:
		QuestDefinition.State.NOT_STARTED:
			return {
				"lines": definition.format_dialogue(definition.offer_dialogue, progress),
				"action": "start_quest:" + quest_id
			}
		QuestDefinition.State.ACTIVE:
			return {
				"lines": definition.format_dialogue(definition.active_dialogue, progress),
				"action": "none"
			}
		QuestDefinition.State.READY_TO_TURN_IN:
			if not journal.can_turn_in(quest_id, inventory):
				return {
					"lines": definition.format_dialogue(definition.inventory_full_dialogue, progress),
					"action": "none"
				}
			return {
				"lines": definition.format_dialogue(definition.ready_dialogue, progress),
				"action": "complete_quest:" + quest_id
			}
		QuestDefinition.State.COMPLETED:
			return {
				"lines": definition.format_dialogue(definition.completed_dialogue, progress),
				"action": "none"
			}
	return {"lines": [], "action": "none"}

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
		var players = get_tree().get_nodes_in_group(GameGroups.PLAYERS)
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

class_name QuestJournalUI
extends Control

## Giao diện Sổ Nhiệm Vụ (Quest Journal) cho NOCTELYRA (M7)
## Phím tắt Q bật/tắt, hiển thị Nhiệm vụ Chính và các Nhiệm vụ Phụ từng vùng.

signal journal_opened()
signal journal_closed()

@onready var close_btn: Button = $Panel/Header/CloseBtn
@onready var quest_list_container: VBoxContainer = $Panel/ScrollContainer/QuestList

# Main quest remains a compatibility view for the legacy tutorial quest.
@onready var main_quest_card: PanelContainer = $Panel/ScrollContainer/QuestList/MainQuestCard
@onready var main_title_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/HeaderHBox/TitleLabel
@onready var main_badge_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/HeaderHBox/BadgeLabel
@onready var main_npc_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/NpcLabel
@onready var main_desc_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/DescLabel
@onready var main_progress_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/ProgressLabel
@onready var main_reward_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/RewardLabel

@onready var first_side_quest_card: PanelContainer = $Panel/ScrollContainer/QuestList/KaelisQuestCard
@onready var second_side_quest_card: PanelContainer = $Panel/ScrollContainer/QuestList/RhaekQuestCard

var _side_quest_cards: Dictionary = {}

func _ready() -> void:
	visible = false
	_prepare_side_quest_cards()
	if close_btn:
		close_btn.pressed.connect(close)

func open() -> void:
	visible = true
	refresh()
	emit_signal("journal_opened")

func close() -> void:
	visible = false
	emit_signal("journal_closed")

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func is_open() -> bool:
	return visible

func refresh() -> void:
	var player: Player = _get_player()
	var quest_mgr: QuestManager = _get_quest_manager()
	
	if player and player.quest_journal_component and player.inventory_component:
		player.quest_journal_component.update_item_collection(player.inventory_component)

	_refresh_main_quest(quest_mgr)
	_refresh_catalog_quests(player)

func _refresh_main_quest(quest_mgr: QuestManager = null) -> void:
	if not main_quest_card:
		return

	var player: Player = _get_player()
	var journal := player.quest_journal_component if player else null

	# Ưu tiên đọc trực tiếp từ QuestJournalComponent (Single Source of Truth)
	if journal != null:
		var def := ContentRegistry.get_quest("quest_noctis_purify")
		var q_title := def.title if def else "Ánh Sáng Bị Nuốt Chửng"
		var q_desc := def.description if def else "Ma lực tại Rừng Hắc Nguyệt đang mất cân bằng. Hãy tiêu diệt 3 sinh vật bị ma lực tha hóa để bảo vệ ngôi làng."
		var q_reward := "%d Vàng, Hồi phục toàn bộ HP & MP" % (def.reward_gold if def else 50)
		var state := journal.get_quest_state("quest_noctis_purify")
		var progress := journal.get_quest_progress("quest_noctis_purify")
		var target := def.target_amount if def else 3

		main_title_label.text = "Nhiệm Vụ Chính: " + q_title
		main_npc_label.text = "Người giao: Eiran | Khu vực: Rừng Hắc Nguyệt (Noctis Forest)"
		main_desc_label.text = q_desc
		main_reward_label.text = "Phần thưởng: " + q_reward

		match state:
			QuestDefinition.State.NOT_STARTED:
				main_badge_label.text = "[Chưa nhận]"
				main_badge_label.modulate = Color(0.7, 0.7, 0.7)
				main_progress_label.text = "Mục tiêu: Tiêu diệt %d sinh vật ma hóa (Chưa nhận - gặp Eiran)" % target
			QuestDefinition.State.ACTIVE:
				main_badge_label.text = "[Đang thực hiện]"
				main_badge_label.modulate = Color(1.0, 0.85, 0.3)
				main_progress_label.text = "Mục tiêu: Tiêu diệt %d/%d sinh vật ma hóa" % [progress, target]
			QuestDefinition.State.READY_TO_TURN_IN:
				main_badge_label.text = "[Sẵn sàng trả]"
				main_badge_label.modulate = Color(0.3, 0.9, 1.0)
				main_progress_label.text = "Mục tiêu: %d/%d sinh vật ma hóa (Gặp Eiran nhận thưởng!)" % [progress, target]
			QuestDefinition.State.COMPLETED:
				main_badge_label.text = "[Đã hoàn thành]"
				main_badge_label.modulate = Color(0.4, 1.0, 0.4)
				main_progress_label.text = "Mục tiêu: Đã hoàn thành (Cổng Ma Thuật Đấu Trường Đã Mở)"
		return

	if quest_mgr == null or quest_mgr.current_quest == null:
		main_title_label.text = "Nhiệm Vụ Chính: Thanh Tẩy Rừng Noctis"
		main_badge_label.text = "[Chưa nhận]"
		main_badge_label.modulate = Color(0.7, 0.7, 0.7)
		main_npc_label.text = "Người giao: Eiran | Khu vực: Rừng Hắc Nguyệt (Noctis Forest)"
		main_desc_label.text = "Tiêu diệt sinh vật ma hóa để bảo vệ Làng Ánh Nguyệt và mở Cổng Ma Thuật."
		main_progress_label.text = "Mục tiêu: Tiêu diệt 3 sinh vật ma hóa (0/3)"
		main_reward_label.text = "Phần thưởng: 50 Vàng, Hồi phục toàn bộ HP & MP"
		return

	var q = quest_mgr.current_quest
	main_title_label.text = "Nhiệm Vụ Chính: " + q.title
	main_npc_label.text = "Người giao: Eiran | Khu vực: Rừng Hắc Nguyệt (Noctis Forest)"
	main_desc_label.text = q.description
	main_reward_label.text = "Phần thưởng: %d Vàng, Hồi phục toàn bộ HP & MP" % q.reward_gold

	match q.current_state:
		QuestData.State.NOT_STARTED:
			main_badge_label.text = "[Chưa nhận]"
			main_badge_label.modulate = Color(0.7, 0.7, 0.7)
			main_progress_label.text = "Mục tiêu: Tiêu diệt 3 sinh vật ma hóa (Chưa nhận - gặp Eiran)"
		QuestData.State.ACTIVE:
			main_badge_label.text = "[Đang thực hiện]"
			main_badge_label.modulate = Color(1.0, 0.85, 0.3)
			main_progress_label.text = "Mục tiêu: Tiêu diệt %d/%d sinh vật ma hóa" % [q.current_amount, q.target_amount]
		QuestData.State.READY_TO_TURN_IN:
			main_badge_label.text = "[Sẵn sàng trả]"
			main_badge_label.modulate = Color(0.3, 0.9, 1.0)
			main_progress_label.text = "Mục tiêu: %d/%d sinh vật ma hóa (Gặp Eiran nhận thưởng!)" % [q.current_amount, q.target_amount]
		QuestData.State.COMPLETED:
			main_badge_label.text = "[Đã hoàn thành]"
			main_badge_label.modulate = Color(0.4, 1.0, 0.4)
			main_progress_label.text = "Mục tiêu: Đã hoàn thành (Cổng Ma Thuật Đấu Trường Đã Mở)"

func _prepare_side_quest_cards() -> void:
	_side_quest_cards.clear()
	var available_cards: Array[PanelContainer] = [first_side_quest_card, second_side_quest_card]
	var side_definitions: Array[QuestDefinition] = []
	for d in ContentRegistry.catalog().quests:
		if d and not d.is_main_quest:
			side_definitions.append(d)

	for index in side_definitions.size():
		var definition := side_definitions[index]
		var card: PanelContainer
		if index < available_cards.size():
			card = available_cards[index]
		else:
			card = first_side_quest_card.duplicate() as PanelContainer
			quest_list_container.add_child(card)
		card.name = "QuestCard_%s" % definition.quest_id
		card.visible = true
		_side_quest_cards[definition.quest_id] = card

	for index in range(side_definitions.size(), available_cards.size()):
		available_cards[index].visible = false

func _refresh_catalog_quests(player: Player) -> void:
	var journal: QuestJournalComponent = player.quest_journal_component if player else null
	for definition in ContentRegistry.catalog().quests:
		if definition == null or definition.is_main_quest:
			continue
		var card := _side_quest_cards.get(definition.quest_id) as PanelContainer
		if card == null:
			continue
		var title_label := card.get_node("VBox/HeaderHBox/TitleLabel") as Label
		var badge_label := card.get_node("VBox/HeaderHBox/BadgeLabel") as Label
		var npc_label := card.get_node("VBox/NpcLabel") as Label
		var desc_label := card.get_node("VBox/DescLabel") as Label
		var progress_label := card.get_node("VBox/ProgressLabel") as Label
		var reward_label := card.get_node("VBox/RewardLabel") as Label
		var state := journal.get_quest_state(definition.quest_id) if journal else QuestDefinition.State.NOT_STARTED
		var progress := journal.get_quest_progress(definition.quest_id) if journal else 0

		title_label.text = "Nhiệm Vụ Phụ: " + definition.title
		npc_label.text = "Người giao: %s | Khu vực: %s" % [definition.giver_name, definition.giver_location]
		desc_label.text = definition.description
		reward_label.text = "Phần thưởng: " + definition.get_reward_summary()
		_apply_badge_and_progress(
			badge_label,
			progress_label,
			state,
			progress,
			definition.target_amount,
			definition.get_target_display_name(),
			definition.giver_name
		)

func _apply_badge_and_progress(badge_lbl: Label, prog_lbl: Label, state: int, cur: int, target: int, target_name: String, npc_name: String) -> void:
	match state:
		QuestDefinition.QuestState.NOT_STARTED:
			badge_lbl.text = "[Chưa nhận]"
			badge_lbl.modulate = Color(0.7, 0.7, 0.7)
			prog_lbl.text = "Mục tiêu: %s (Chưa nhận - gặp %s)" % [target_name, npc_name]
		QuestDefinition.QuestState.ACTIVE:
			badge_lbl.text = "[Đang thực hiện]"
			badge_lbl.modulate = Color(1.0, 0.85, 0.3)
			prog_lbl.text = "Mục tiêu: %d/%d %s" % [cur, target, target_name]
		QuestDefinition.QuestState.READY_TO_TURN_IN:
			badge_lbl.text = "[Sẵn sàng trả]"
			badge_lbl.modulate = Color(0.3, 0.9, 1.0)
			prog_lbl.text = "Mục tiêu: %d/%d %s (Gặp %s nhận thưởng!)" % [cur, target, target_name, npc_name]
		QuestDefinition.QuestState.COMPLETED:
			badge_lbl.text = "[Đã hoàn thành]"
			badge_lbl.modulate = Color(0.4, 1.0, 0.4)
			prog_lbl.text = "Mục tiêu: Đã hoàn thành và nhận thưởng"

func _get_player() -> Player:
	if get_tree() and get_tree().current_scene:
		var p = get_tree().current_scene.get_node_or_null("Player") as Player
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

func _get_quest_manager() -> QuestManager:
	if get_tree() and get_tree().current_scene:
		var qm = get_tree().current_scene.get_node_or_null("QuestManager") as QuestManager
		if qm:
			return qm
	var par = get_parent()
	if par:
		var qm = par.get_node_or_null("QuestManager") as QuestManager
		if qm:
			return qm
	return null

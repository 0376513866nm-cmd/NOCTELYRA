class_name QuestJournalUI
extends Control

## Giao diện Sổ Nhiệm Vụ (Quest Journal) cho NOCTELYRA (M7)
## Phím tắt Q bật/tắt, hiển thị Nhiệm vụ Chính và các Nhiệm vụ Phụ từng vùng.

signal journal_opened()
signal journal_closed()

@onready var close_btn: Button = $Panel/Header/CloseBtn
@onready var quest_list_container: VBoxContainer = $Panel/ScrollContainer/QuestList

# Card references
@onready var main_quest_card: PanelContainer = $Panel/ScrollContainer/QuestList/MainQuestCard
@onready var main_title_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/HeaderHBox/TitleLabel
@onready var main_badge_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/HeaderHBox/BadgeLabel
@onready var main_npc_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/NpcLabel
@onready var main_desc_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/DescLabel
@onready var main_progress_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/ProgressLabel
@onready var main_reward_label: Label = $Panel/ScrollContainer/QuestList/MainQuestCard/VBox/RewardLabel

@onready var kaelis_quest_card: PanelContainer = $Panel/ScrollContainer/QuestList/KaelisQuestCard
@onready var kaelis_title_label: Label = $Panel/ScrollContainer/QuestList/KaelisQuestCard/VBox/HeaderHBox/TitleLabel
@onready var kaelis_badge_label: Label = $Panel/ScrollContainer/QuestList/KaelisQuestCard/VBox/HeaderHBox/BadgeLabel
@onready var kaelis_npc_label: Label = $Panel/ScrollContainer/QuestList/KaelisQuestCard/VBox/NpcLabel
@onready var kaelis_desc_label: Label = $Panel/ScrollContainer/QuestList/KaelisQuestCard/VBox/DescLabel
@onready var kaelis_progress_label: Label = $Panel/ScrollContainer/QuestList/KaelisQuestCard/VBox/ProgressLabel
@onready var kaelis_reward_label: Label = $Panel/ScrollContainer/QuestList/KaelisQuestCard/VBox/RewardLabel

@onready var rhaek_quest_card: PanelContainer = $Panel/ScrollContainer/QuestList/RhaekQuestCard
@onready var rhaek_title_label: Label = $Panel/ScrollContainer/QuestList/RhaekQuestCard/VBox/HeaderHBox/TitleLabel
@onready var rhaek_badge_label: Label = $Panel/ScrollContainer/QuestList/RhaekQuestCard/VBox/HeaderHBox/BadgeLabel
@onready var rhaek_npc_label: Label = $Panel/ScrollContainer/QuestList/RhaekQuestCard/VBox/NpcLabel
@onready var rhaek_desc_label: Label = $Panel/ScrollContainer/QuestList/RhaekQuestCard/VBox/DescLabel
@onready var rhaek_progress_label: Label = $Panel/ScrollContainer/QuestList/RhaekQuestCard/VBox/ProgressLabel
@onready var rhaek_reward_label: Label = $Panel/ScrollContainer/QuestList/RhaekQuestCard/VBox/RewardLabel

func _ready() -> void:
	visible = false
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
	_refresh_side_quests(player)

func _refresh_main_quest(quest_mgr: QuestManager) -> void:
	if not main_quest_card:
		return
	if quest_mgr == null or quest_mgr.current_quest == null:
		main_title_label.text = "Nhiệm Vụ Chính: Thanh Tẩy Rừng Noctis"
		main_badge_label.text = "[Chưa nhận]"
		main_badge_label.modulate = Color(0.7, 0.7, 0.7)
		main_npc_label.text = "Người giao: Elyra | Khu vực: Rừng Hắc Nguyệt (Noctis Forest)"
		main_desc_label.text = "Tiêu diệt sinh vật ma hóa để bảo vệ Làng Ánh Nguyệt và mở Cổng Ma Thuật."
		main_progress_label.text = "Mục tiêu: Tiêu diệt 3 sinh vật ma hóa (0/3)"
		main_reward_label.text = "Phần thưởng: 50 Vàng, Hồi phục toàn bộ HP & MP"
		return

	var q = quest_mgr.current_quest
	main_title_label.text = "Nhiệm Vụ Chính: " + q.title
	main_npc_label.text = "Người giao: Elyra | Khu vực: Rừng Hắc Nguyệt (Noctis Forest)"
	main_desc_label.text = q.description
	main_reward_label.text = "Phần thưởng: %d Vàng, Hồi phục toàn bộ HP & MP" % q.reward_gold

	match q.current_state:
		QuestData.State.NOT_STARTED:
			main_badge_label.text = "[Chưa nhận]"
			main_badge_label.modulate = Color(0.7, 0.7, 0.7)
			main_progress_label.text = "Mục tiêu: Tiêu diệt 3 sinh vật ma hóa (Chưa nhận - gặp Elyra)"
		QuestData.State.ACTIVE:
			main_badge_label.text = "[Đang thực hiện]"
			main_badge_label.modulate = Color(1.0, 0.85, 0.3)
			main_progress_label.text = "Mục tiêu: Tiêu diệt %d/%d sinh vật ma hóa" % [q.current_amount, q.target_amount]
		QuestData.State.READY_TO_TURN_IN:
			main_badge_label.text = "[Sẵn sàng trả]"
			main_badge_label.modulate = Color(0.3, 0.9, 1.0)
			main_progress_label.text = "Mục tiêu: %d/%d sinh vật ma hóa (Gặp Elyra nhận thưởng!)" % [q.current_amount, q.target_amount]
		QuestData.State.COMPLETED:
			main_badge_label.text = "[Đã hoàn thành]"
			main_badge_label.modulate = Color(0.4, 1.0, 0.4)
			main_progress_label.text = "Mục tiêu: Đã hoàn thành (Cổng Ma Thuật Đấu Trường Đã Mở)"

func _refresh_side_quests(player: Player) -> void:
	var journal = player.quest_journal_component if player else null

	# Quest 1: Elyndra Cleansing (Kaelis)
	if kaelis_quest_card:
		var q1_state = journal.get_quest_state("quest_elyndra_cleansing") if journal else QuestDefinition.QuestState.NOT_STARTED
		var q1_prog = journal.get_quest_progress("quest_elyndra_cleansing") if journal else 0
		kaelis_title_label.text = "Nhiệm Vụ Phụ: Thanh Tẩy Thánh Lâm"
		kaelis_npc_label.text = "Người giao: Kaelis | Khu vực: Thánh Lâm Elyndra (Elyndra Glade)"
		kaelis_desc_label.text = "Tiêu diệt các cây Nấm Ma Hóa đang ô nhiễm dòng chảy Tinh Mạch của Thánh Lâm."
		kaelis_reward_label.text = "Phần thưởng: 80 Vàng, 2 Bình Máu (health_potion)"
		_apply_badge_and_progress(kaelis_badge_label, kaelis_progress_label, q1_state, q1_prog, 3, "Nấm Ma Hóa (Corrupted Mooncap)", "Kaelis")

	# Quest 2: Vharok Embers (Rhaek)
	if rhaek_quest_card:
		var q2_state = journal.get_quest_state("quest_vharok_embers") if journal else QuestDefinition.QuestState.NOT_STARTED
		var q2_prog = journal.get_quest_progress("quest_vharok_embers") if journal else 0
		rhaek_title_label.text = "Nhiệm Vụ Phụ: Lửa Rèn Tiền Đồn"
		rhaek_npc_label.text = "Người giao: Rhaek | Khu vực: Tiền Đồn Vharok (Vharok Outpost)"
		rhaek_desc_label.text = "Thu thập Lõi Tàn Hỏa từ vách đá hoặc Thằn Lằn Tro Tàn để duy trì lò rèn Quỷ tộc."
		rhaek_reward_label.text = "Phần thưởng: 100 Vàng, 3 Mảnh Chân Ma (mana_shard)"
		_apply_badge_and_progress(rhaek_badge_label, rhaek_progress_label, q2_state, q2_prog, 3, "Lõi Tàn Hỏa (Ember Core)", "Rhaek")

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
		var players = get_tree().get_nodes_in_group("player")
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

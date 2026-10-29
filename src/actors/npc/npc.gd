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
	# Hợp nhất Eiran vào hệ Catalog Quest của QuestJournalComponent
	if quest_id.is_empty() and npc_name in ["Eiran", "Elyra"]:
		quest_id = "quest_noctis_purify"
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

	var player: Player = _get_player()
	var lines: Array[String] = []
	var action: String = "none"

	if not quest_id.is_empty():
		var interaction := _get_catalog_quest_interaction(player)
		lines = interaction.get("lines", [])
		action = str(interaction.get("action", "none"))
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

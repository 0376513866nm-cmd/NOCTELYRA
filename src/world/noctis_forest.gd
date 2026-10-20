class_name NoctisForest
extends Node2D

var player: Player
var game_ui: GameUI
var quest_manager: QuestManager
var pause_controller: PauseController
var npc_elyra: NPC

func _enter_tree() -> void:
	init_references()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	init_references()

func init_references() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if game_ui == null:
		game_ui = get_node_or_null("GameUI") as GameUI
	if quest_manager == null:
		quest_manager = get_node_or_null("QuestManager") as QuestManager
	if pause_controller == null:
		pause_controller = get_node_or_null("PauseController") as PauseController
	if npc_elyra == null:
		npc_elyra = get_node_or_null("NPC_Elyra") as NPC

	# Kết nối Player
	if player and not player.state_changed.is_connected(_on_player_state_changed):
		player.add_to_group("players")
		player.state_changed.connect(_on_player_state_changed)
		_on_player_state_changed("IDLE")

		var p_health: HealthComponent = player.get_node_or_null("HealthComponent")
		if p_health and not p_health.health_changed.is_connected(_on_player_health_changed):
			p_health.health_changed.connect(_on_player_health_changed)
			p_health.mana_changed.connect(_on_player_mana_changed)
			if game_ui:
				game_ui.update_player_hp(p_health.current_health, p_health.max_health)
				game_ui.update_player_mp(p_health.current_mana, p_health.max_mana)

	# Kết nối GameUI
	if game_ui and not game_ui.retry_requested.is_connected(_on_retry_requested):
		game_ui.retry_requested.connect(_on_retry_requested)
		if quest_manager and quest_manager.current_quest:
			game_ui.update_quest_info(quest_manager.current_quest)
			game_ui.update_gold(quest_manager.gold)

	# Kết nối QuestManager
	if quest_manager and not quest_manager.quest_started.is_connected(_on_quest_updated):
		quest_manager.quest_started.connect(_on_quest_updated)
		quest_manager.quest_progress_updated.connect(_on_quest_updated)
		quest_manager.quest_ready_to_turn_in.connect(_on_quest_updated)
		quest_manager.quest_completed.connect(_on_quest_updated)
		quest_manager.gold_changed.connect(_on_gold_changed)
		quest_manager.notification_posted.connect(_on_notification_posted)

	# Kết nối NPC Elyra
	if npc_elyra and not npc_elyra.dialogue_requested.is_connected(_on_npc_dialogue_requested):
		npc_elyra.dialogue_requested.connect(_on_npc_dialogue_requested)

	# Kết nối các quái vật trên map với QuestManager
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy and quest_manager and not e.enemy_defeated.is_connected(quest_manager.register_enemy_kill):
			e.enemy_defeated.connect(quest_manager.register_enemy_kill)

func _on_player_state_changed(st_name: String) -> void:
	if game_ui:
		game_ui.update_player_state(st_name)

func _on_player_health_changed(cur: float, max_v: float) -> void:
	if game_ui:
		game_ui.update_player_hp(cur, max_v)

func _on_player_mana_changed(cur: float, max_v: float) -> void:
	if game_ui:
		game_ui.update_player_mp(cur, max_v)

func _on_quest_updated(quest: QuestData) -> void:
	if game_ui:
		game_ui.update_quest_info(quest)

func _on_gold_changed(new_gold: int) -> void:
	if game_ui:
		game_ui.update_gold(new_gold)

func _on_notification_posted(msg: String) -> void:
	if game_ui:
		game_ui.show_notification(msg)

func _on_npc_dialogue_requested(npc: NPC, lines: Array[String], action: String) -> void:
	if game_ui:
		game_ui.show_dialogue(npc.npc_name, lines, action)

func _on_retry_requested() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if player:
		player.respawn()

func _on_resume_button_pressed() -> void:
	if pause_controller:
		pause_controller.resume()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

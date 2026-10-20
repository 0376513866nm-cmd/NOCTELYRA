class_name NoctisForest
extends Node2D

var player: Player
var game_ui: GameUI
var quest_manager: QuestManager
var pause_controller: PauseController
var npc_elyra: NPC
var interaction_coordinator: InteractionCoordinator
var defeated_enemy_ids: Array = []
var collected_pickup_ids: Array = []

func _enter_tree() -> void:
	init_references()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	init_references()
	if SaveManager.should_load_on_start:
		SaveManager.should_load_on_start = false
		SaveManager.load_game(self)

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
	if interaction_coordinator == null:
		interaction_coordinator = get_node_or_null("InteractionCoordinator") as InteractionCoordinator

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
		if player and game_ui.inventory_ui:
			game_ui.inventory_ui.setup_player(player)
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

	# Kết nối các quái vật trên map với QuestManager và ghi nhận ID quái đã diệt
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy:
			if quest_manager and not e.enemy_defeated.is_connected(quest_manager.register_enemy_kill):
				e.enemy_defeated.connect(quest_manager.register_enemy_kill)
			if not e.enemy_defeated.is_connected(_on_enemy_defeated):
				e.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(enemy_node: Node) -> void:
	if enemy_node is Enemy and not enemy_node.enemy_id.is_empty():
		if not enemy_node.enemy_id in defeated_enemy_ids:
			defeated_enemy_ids.append(enemy_node.enemy_id)

func register_collected_pickup(p_id: String) -> void:
	if not p_id.is_empty() and not p_id in collected_pickup_ids:
		collected_pickup_ids.append(p_id)

func get_dropped_pickups_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dyn_pickups = get_tree().get_nodes_in_group("dynamic_pickups")
	for p in dyn_pickups:
		if p is ItemPickup and is_instance_valid(p) and not p.is_picked_up and not p.is_queued_for_deletion():
			result.append({
				"pickup_id": p.pickup_id,
				"item_id": p.item_id,
				"amount": p.amount,
				"x": p.global_position.x,
				"y": p.global_position.y
			})
	return result

func restore_world_state(p_collected_ids: Array, p_dropped_pickups: Array, p_defeated_ids: Array) -> void:
	collected_pickup_ids.clear()
	for id in p_collected_ids:
		collected_pickup_ids.append(str(id))

	defeated_enemy_ids.clear()
	for id in p_defeated_ids:
		defeated_enemy_ids.append(str(id))

	# 1. Dọn các vật phẩm đặt sẵn đã từng nhặt
	var preplaced = get_tree().get_nodes_in_group("preplaced_pickups")
	for p in preplaced:
		if p is ItemPickup and not p.pickup_id.is_empty():
			if p.pickup_id in collected_pickup_ids:
				p.queue_free()

	# 2. Xóa các dynamic pickup cũ trước khi phục hồi danh sách lưu (tránh nhân bản)
	var existing_dyn = get_tree().get_nodes_in_group("dynamic_pickups")
	for p in existing_dyn:
		if is_instance_valid(p):
			p.queue_free()

	# 3. Phục hồi các vật phẩm quái rơi chưa nhặt
	var pickup_scene: PackedScene = preload("res://src/loot/item_pickup.tscn")
	for dp in p_dropped_pickups:
		if dp is Dictionary:
			var p := pickup_scene.instantiate() as ItemPickup
			p.pickup_id = str(dp.get("pickup_id", ""))
			p.item_id = str(dp.get("item_id", "mana_shard"))
			p.amount = max(1, int(dp.get("amount", 1)))
			p.is_dynamic = true
			var px: float = float(dp.get("x", 0.0))
			var py: float = float(dp.get("y", 0.0))
			p.global_position = Vector2(px, py)
			add_child(p)

	# 4. Xóa các quái đã chết
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy and not e.enemy_id.is_empty():
			if e.enemy_id in defeated_enemy_ids:
				e.queue_free()

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

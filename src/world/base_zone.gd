class_name BaseZone
extends Node2D

const SettingsManager = preload("res://src/ui/settings_manager.gd")

## Lớp cơ sở (Base Zone) cho tất cả các vùng đất trong NOCTELYRA (Milestone M6, M6.1)
## Cung cấp kiến trúc mở rộng thế giới, vòng lặp tham chiếu chung,
## đồng bộ trạng thái người chơi, camera bám sát player,
## và khởi tạo UI ổn định (tách biệt setup_signals và setup_ui).

@export var zone_id: String = "noctis_forest"
@export var zone_display_name: String = "Rừng Noctis"

var player: Player
var game_ui: GameUI
var quest_manager: QuestManager
var pause_controller: PauseController
var interaction_coordinator: InteractionCoordinator

var defeated_enemy_ids: Array = []
var collected_pickup_ids: Array = []

func _enter_tree() -> void:
	init_base_references()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	init_base_references()
	setup_signals()
	setup_camera()
	setup_ui()

	# 1. Tải Save nếu người chơi nhấn Continue từ Main Menu
	var loaded_save := false
	if SaveManager.should_load_on_start:
		SaveManager.should_load_on_start = false
		loaded_save = SaveManager.load_game(self)
	elif ZoneManager.session_player_data.is_empty():
		# Khởi tạo game mới với chủng tộc đã chọn (Milestone M8)
		if player and player.player_stats_component:
			var init_race := ZoneManager.initial_race_id if not ZoneManager.initial_race_id.is_empty() else "human"
			player.player_stats_component.set_race(init_race)
			var p_h := player.health_component
			if p_h:
				p_h.current_health = p_h.max_health
				p_h.current_mana = p_h.max_mana
				p_h.emit_signal("health_changed", p_h.current_health, p_h.max_health)
				p_h.emit_signal("mana_changed", p_h.current_mana, p_h.max_mana)

	# 2. Xử lý chuyển cảnh hoặc áp dụng trạng thái từ ZoneManager
	ZoneManager.on_zone_entered(self, not loaded_save)

	# 3. Đồng bộ lại UI & Camera ngay sau khi nạp Save hoặc chuyển vùng
	setup_ui()
	snap_camera_to_player()

func _process(delta: float) -> void:
	ZoneManager.update_cooldown(delta)

func init_base_references() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if game_ui == null:
		game_ui = get_node_or_null("GameUI") as GameUI
	if quest_manager == null:
		quest_manager = get_node_or_null("QuestManager") as QuestManager
	if pause_controller == null:
		pause_controller = get_node_or_null("PauseController") as PauseController
	if interaction_coordinator == null:
		interaction_coordinator = get_node_or_null("InteractionCoordinator") as InteractionCoordinator

func setup_signals() -> void:
	# Kết nối Player
	if player:
		if not player.is_in_group(GameGroups.PLAYERS):
			player.add_to_group(GameGroups.PLAYERS)
		if not player.state_changed.is_connected(_on_player_state_changed):
			player.state_changed.connect(_on_player_state_changed)

		var p_health: HealthComponent = player.get_node_or_null("HealthComponent")
		if p_health:
			if not p_health.health_changed.is_connected(_on_player_health_changed):
				p_health.health_changed.connect(_on_player_health_changed)
			if not p_health.mana_changed.is_connected(_on_player_mana_changed):
				p_health.mana_changed.connect(_on_player_mana_changed)

	# Kết nối GameUI
	if game_ui:
		if not game_ui.retry_requested.is_connected(_on_retry_requested):
			game_ui.retry_requested.connect(_on_retry_requested)

	# Kết nối QuestManager
	if quest_manager:
		if not quest_manager.quest_started.is_connected(_on_quest_updated):
			quest_manager.quest_started.connect(_on_quest_updated)
		if not quest_manager.quest_progress_updated.is_connected(_on_quest_updated):
			quest_manager.quest_progress_updated.connect(_on_quest_updated)
		if not quest_manager.quest_ready_to_turn_in.is_connected(_on_quest_updated):
			quest_manager.quest_ready_to_turn_in.connect(_on_quest_updated)
		if not quest_manager.quest_completed.is_connected(_on_quest_updated):
			quest_manager.quest_completed.connect(_on_quest_updated)
		if not quest_manager.gold_changed.is_connected(_on_gold_changed):
			quest_manager.gold_changed.connect(_on_gold_changed)
		if not quest_manager.notification_posted.is_connected(_on_notification_posted):
			quest_manager.notification_posted.connect(_on_notification_posted)

	# Kết nối tất cả NPC trong khu vực
	if get_tree():
		for n in get_tree().get_nodes_in_group(GameGroups.NPCS):
			if n is NPC and not n.dialogue_requested.is_connected(_on_npc_dialogue_requested):
				n.dialogue_requested.connect(_on_npc_dialogue_requested)

	# Kết nối tất cả Enemy trong khu vực
	if get_tree():
		for e in get_tree().get_nodes_in_group(GameGroups.ENEMIES):
			if e is Enemy and is_ancestor_of(e):
				if not e.enemy_respawned.is_connected(_on_enemy_respawned):
					e.enemy_respawned.connect(_on_enemy_respawned)
				if not e.enemy_defeated.is_connected(_on_enemy_defeated):
					e.enemy_defeated.connect(_on_enemy_defeated)
				if player and player.quest_journal_component:
					if not e.enemy_defeated.is_connected(player.quest_journal_component.register_enemy_kill):
						e.enemy_defeated.connect(player.quest_journal_component.register_enemy_kill)

func setup_camera() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if player == null:
		return

	var cam: Camera2D = get_node_or_null("Camera2D") as Camera2D
	if cam:
		var remote: RemoteTransform2D = player.get_node_or_null("RemoteTransform2D") as RemoteTransform2D
		if remote == null:
			remote = RemoteTransform2D.new()
			remote.name = "RemoteTransform2D"
			remote.update_scale = false
			player.add_child(remote)
		remote.remote_path = cam.get_path()
		cam.zoom = Vector2(SettingsManager.camera_zoom, SettingsManager.camera_zoom)

func snap_camera_to_player() -> void:
	if player == null:
		player = get_node_or_null("Player") as Player
	if player == null:
		return

	var cam: Camera2D = get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.global_position = player.global_position
		cam.reset_smoothing()

func setup_ui() -> void:
	if game_ui == null:
		game_ui = get_node_or_null("GameUI") as GameUI
	if game_ui == null:
		return

	if player == null:
		player = get_node_or_null("Player") as Player

	if player:
		# 1. Gắn Player vào InventoryUI
		if game_ui.inventory_ui:
			game_ui.inventory_ui.setup_player(player)

		# 2. Gắn SpellbookComponent vào SpellHotbar
		if game_ui.spell_hotbar and player.spellbook_component:
			game_ui.spell_hotbar.set_spellbook(player.spellbook_component)

		# 3. Cập nhật thanh HP và MP
		var p_health: HealthComponent = player.get_node_or_null("HealthComponent")
		if p_health:
			game_ui.update_player_hp(p_health.current_health, p_health.max_health)
			game_ui.update_player_mp(p_health.current_mana, p_health.max_mana)

		# 4. Cập nhật trạng thái Player
		_on_player_state_changed("IDLE")

		# 5. Kết nối sự kiện thăng cấp
		if player.progression_component and not player.progression_component.level_up.is_connected(_on_player_level_up):
			player.progression_component.level_up.connect(_on_player_level_up)

	# 6. Cập nhật Vàng và Nhiệm vụ
	if quest_manager:
		game_ui.update_gold(quest_manager.gold)
		if quest_manager.current_quest:
			game_ui.update_quest_info(quest_manager.current_quest)

	# 7. Cập nhật thông tin vùng đất (HUD zone label)
	if game_ui.has_method("set_current_zone"):
		game_ui.set_current_zone(zone_id)

func _on_player_level_up(new_level: int) -> void:
	if game_ui:
		game_ui.show_notification("✨ Thăng cấp! Bạn đã đạt Cấp %d!" % new_level)
		if player:
			var p_health: HealthComponent = player.get_node_or_null("HealthComponent")
			if p_health:
				game_ui.update_player_hp(p_health.current_health, p_health.max_health)
				game_ui.update_player_mp(p_health.current_mana, p_health.max_mana)
			if game_ui.character_sheet_ui and game_ui.character_sheet_ui.is_open():
				game_ui.character_sheet_ui.refresh()

func _on_npc_dialogue_requested(npc: NPC, lines: Array[String], action: String) -> void:
	if game_ui:
		game_ui.show_dialogue(npc.npc_name, lines, action)

func register_collected_pickup(p_id: String) -> void:
	if not p_id.is_empty() and not p_id in collected_pickup_ids:
		collected_pickup_ids.append(p_id)

func _on_enemy_defeated(enemy_node: Node) -> void:
	if enemy_node is Enemy and not enemy_node.enemy_id.is_empty():
		if not enemy_node.enemy_id in defeated_enemy_ids:
			defeated_enemy_ids.append(enemy_node.enemy_id)

	# M8: Trao EXP từ quái vật (chống nhận trùng bằng enemy_id duy nhất)
	if player == null:
		player = get_node_or_null("Player") as Player
	if player and player.progression_component:
		var e_type: String = str(enemy_node.enemy_type_id) if "enemy_type_id" in enemy_node else "corrupted_wolf"
		var exp_val: int = ExpDatabase.get_enemy_exp(e_type)
		var e_id_str: String = str(enemy_node.enemy_id) if ("enemy_id" in enemy_node and not str(enemy_node.enemy_id).is_empty()) else str(enemy_node.get_instance_id())
		var source_id: String = enemy_node.get_exp_source_id() if enemy_node is Enemy else "enemy:" + e_id_str
		player.progression_component.add_exp(exp_val, source_id)

func _on_enemy_respawned(enemy_node: Node) -> void:
	if enemy_node is Enemy:
		defeated_enemy_ids.erase(enemy_node.enemy_id)

func get_dropped_pickups_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dyn_pickups = get_tree().get_nodes_in_group(GameGroups.DYNAMIC_PICKUPS)
	for p in dyn_pickups:
		if p is ItemPickup and is_instance_valid(p) and not p.is_picked_up and not p.is_queued_for_deletion():
			# Chỉ lấy các pickup thuộc khu vực hiện tại
			if is_ancestor_of(p) or p.get_parent() == self:
				result.append({
					"pickup_id": p.pickup_id,
					"item_id": p.item_id,
					"amount": p.amount,
					"x": p.global_position.x,
					"y": p.global_position.y
				})
	return result

func restore_world_state(p_collected_ids: Array, p_dropped_pickups: Array, p_defeated_ids: Array) -> void:
	# Callers may pass the world's own arrays; do not clear their input by alias.
	p_collected_ids = p_collected_ids.duplicate()
	p_defeated_ids = p_defeated_ids.duplicate()
	collected_pickup_ids.clear()
	for id in p_collected_ids:
		collected_pickup_ids.append(str(id))

	defeated_enemy_ids.clear()
	for id in p_defeated_ids:
		defeated_enemy_ids.append(str(id))

	# 1. Dọn các vật phẩm đặt sẵn đã từng nhặt
	var preplaced = get_tree().get_nodes_in_group(GameGroups.PREPLACED_PICKUPS)
	for p in preplaced:
		if is_ancestor_of(p) and p is ItemPickup and not p.pickup_id.is_empty():
			if p.pickup_id in collected_pickup_ids:
				p.queue_free()

	# 2. Xóa các dynamic pickup cũ trước khi phục hồi danh sách lưu (tránh nhân bản)
	var existing_dyn = get_tree().get_nodes_in_group(GameGroups.DYNAMIC_PICKUPS)
	for p in existing_dyn:
		if is_ancestor_of(p) and is_instance_valid(p):
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
	var enemies = get_tree().get_nodes_in_group(GameGroups.ENEMIES)
	for e in enemies:
		if is_ancestor_of(e) and e is Enemy and not e.enemy_id.is_empty():
			if e.enemy_id in defeated_enemy_ids:
				e.restore_defeated_state()

func clear_player_projectiles() -> void:
	if get_tree():
		var projectiles := get_tree().get_nodes_in_group(GameGroups.PLAYER_PROJECTILES)
		for p in projectiles:
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()

func _on_retry_requested() -> void:
	clear_player_projectiles()
	if player:
		player.respawn()
	setup_ui()
	snap_camera_to_player()

func _on_player_state_changed(new_state_name: String) -> void:
	if game_ui:
		game_ui.update_player_state(new_state_name)

func _on_player_health_changed(current: float, maximum: float) -> void:
	if game_ui:
		game_ui.update_player_hp(current, maximum)

func _on_player_mana_changed(current: float, maximum: float) -> void:
	if game_ui:
		game_ui.update_player_mp(current, maximum)

func _on_quest_updated(_q: QuestData) -> void:
	if game_ui and quest_manager and quest_manager.current_quest:
		game_ui.update_quest_info(quest_manager.current_quest)
		game_ui.update_gold(quest_manager.gold)

func _on_gold_changed(new_gold: int) -> void:
	if game_ui:
		game_ui.update_gold(new_gold)

func _on_notification_posted(msg: String) -> void:
	if game_ui:
		game_ui.show_notification(msg)

func _on_resume_button_pressed() -> void:
	if pause_controller:
		pause_controller.resume()
	else:
		get_tree().paused = false
		if game_ui and game_ui.pause_menu:
			game_ui.pause_menu.visible = false

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")

class_name NoctisForest
extends Node2D

## Thế giới Bìa Rừng Noctis & Đấu trường Boss Lunareth (M4)
## Quản lý vòng lặp nhiệm vụ, quái vật, cổng ma pháp, đấu trường và Boss Lunareth.

var player: Player
var game_ui: GameUI
var quest_manager: QuestManager
var pause_controller: PauseController
var npc_elyra: NPC
var interaction_coordinator: InteractionCoordinator

# Boss & Đấu trường (M4)
const BossLunarethScript = preload("res://src/boss/boss_lunareth.gd")
const MagicGateScript = preload("res://src/world/magic_gate.gd")

var boss_lunareth: CharacterBody2D
var magic_gate: StaticBody2D
var arena_barrier: StaticBody2D
var arena_trigger: Area2D
var arena_checkpoint: Vector2 = Vector2(4120.0, 630.0)

var defeated_enemy_ids: Array = []
var collected_pickup_ids: Array = []

var boss_battle_started: bool = false
var boss_defeated: bool = false
var boss_reward_claimed: bool = false

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

	# Các thực thể Boss M4
	if magic_gate == null:
		magic_gate = get_node_or_null("MagicGate") as StaticBody2D
	if boss_lunareth == null:
		boss_lunareth = get_node_or_null("BossLunareth") as CharacterBody2D
	if arena_barrier == null:
		arena_barrier = get_node_or_null("Geometry/ArenaBarrier") as StaticBody2D
	if arena_trigger == null:
		arena_trigger = get_node_or_null("ArenaTrigger") as Area2D

	# Khởi tạo trạng thái rào chắn đấu trường
	if arena_barrier:
		arena_barrier.visible = false
		var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if b_col:
			b_col.disabled = true

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
		if player and game_ui.spell_hotbar and player.spellbook_component:
			game_ui.spell_hotbar.set_spellbook(player.spellbook_component)
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

	# Kết nối các quái vật trên map
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e is Enemy:
			if quest_manager and not e.enemy_defeated.is_connected(quest_manager.register_enemy_kill):
				e.enemy_defeated.connect(quest_manager.register_enemy_kill)
			if not e.enemy_defeated.is_connected(_on_enemy_defeated):
				e.enemy_defeated.connect(_on_enemy_defeated)

	# Kết nối Boss Lunareth (M4)
	if boss_lunareth and not boss_lunareth.boss_health_changed.is_connected(_on_boss_health_changed):
		boss_lunareth.boss_health_changed.connect(_on_boss_health_changed)
		boss_lunareth.boss_phase_changed.connect(_on_boss_phase_changed)
		boss_lunareth.boss_telegraph_started.connect(_on_boss_telegraph_started)
		boss_lunareth.boss_defeated.connect(_on_boss_defeated)

	# Kết nối Arena Trigger
	if arena_trigger and not arena_trigger.body_entered.is_connected(_on_arena_trigger_entered):
		arena_trigger.body_entered.connect(_on_arena_trigger_entered)

	# Đồng bộ trạng thái mở cổng theo nhiệm vụ
	if magic_gate and quest_manager and quest_manager.current_quest:
		magic_gate.update_quest_status(quest_manager.current_quest)

func is_boss_battle_active() -> bool:
	return boss_battle_started and not boss_defeated and boss_lunareth != null and boss_lunareth.current_state != BossLunarethScript.State.DEFEATED

func _on_arena_trigger_entered(body: Node) -> void:
	if body is Player and not boss_defeated and not boss_battle_started:
		start_boss_battle()

func start_boss_battle() -> void:
	boss_battle_started = true

	# Kích hoạt rào chắn đấu trường (Arena Boundary) khóa chặt lối vào
	if arena_barrier:
		arena_barrier.visible = true
		var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if b_col:
			b_col.disabled = false

	# Cập nhật checkpoint hồi sinh ngoài cổng đấu trường
	if player:
		player.spawn_position = arena_checkpoint

	# Đánh thức Boss
	if boss_lunareth:
		boss_lunareth.activate_boss()

	# Hiển thị HUD Boss
	if game_ui and boss_lunareth:
		game_ui.show_boss_hud()
		if boss_lunareth.health_component:
			game_ui.update_boss_hp(boss_lunareth.health_component.current_health, boss_lunareth.health_component.max_health)
		game_ui.update_boss_phase(1)
		game_ui.show_notification("Linh Lộc Lunareth xuất hiện!")

func _on_boss_health_changed(cur: float, max_v: float) -> void:
	if game_ui:
		game_ui.update_boss_hp(cur, max_v)

func _on_boss_phase_changed(new_phase: int) -> void:
	if game_ui:
		game_ui.update_boss_phase(new_phase)

func _on_boss_telegraph_started(skill_name: String, duration: float) -> void:
	if game_ui:
		game_ui.show_boss_warning(skill_name, duration)

func _on_boss_defeated() -> void:
	boss_battle_started = false
	boss_defeated = true
	clear_boss_projectiles()

	# Mở khóa rào chắn đấu trường
	if arena_barrier:
		arena_barrier.visible = false
		var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if b_col:
			b_col.disabled = true

	grant_boss_reward()

func grant_boss_reward() -> void:
	if boss_reward_claimed:
		return
	boss_reward_claimed = true

	# 1. Thưởng 100 Vàng
	if quest_manager:
		quest_manager.gold += 100
		quest_manager.emit_signal("gold_changed", quest_manager.gold)

	# 2. Thưởng vật phẩm Mảnh Nguyệt Thực (eclipse_fragment)
	if player and player.inventory_component:
		var inv: InventoryComponent = player.inventory_component
		if inv.can_add_item("eclipse_fragment", 1):
			inv.add_item("eclipse_fragment", 1)
			if game_ui:
				game_ui.show_notification("Đã nhận Mảnh Nguyệt Thực & 100 Vàng!")
		else:
			# Túi đầy: rơi đồ dưới dạng ItemPickup trên mặt đất tại vị trí Boss
			_spawn_boss_reward_pickup()
			if game_ui:
				game_ui.show_notification("Túi đồ đầy! Mảnh Nguyệt Thực đã rơi trên mặt đất.")

	# 3. Hiển thị thông báo chiến thắng & thanh tẩy thành công
	if game_ui:
		game_ui.show_victory_banner(
			"THANH TẨY THÀNH CÔNG!",
			"Linh Lộc Lunareth đã hồi phục tâm trí!\nRừng Noctis đã được thanh tẩy.\nNhận thưởng: 100 Vàng & Mảnh Nguyệt Thực."
		)

	# 4. Tự động lưu tiến trình game sau chiến thắng
	SaveManager.save_game(self)

func _spawn_boss_reward_pickup() -> void:
	var pickup_scene: PackedScene = preload("res://src/loot/item_pickup.tscn")
	var p := pickup_scene.instantiate() as ItemPickup
	p.pickup_id = "drop_boss_eclipse_fragment"
	p.item_id = "eclipse_fragment"
	p.amount = 1
	p.is_dynamic = true
	var drop_x: float = boss_lunareth.global_position.x if boss_lunareth else 5300.0
	p.global_position = Vector2(drop_x, 630.0)
	add_child(p)

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

func restore_boss_state(p_activated: bool, p_defeated: bool, p_reward: bool) -> void:
	boss_defeated = p_defeated
	boss_reward_claimed = p_reward
	clear_boss_projectiles()

	if boss_defeated:
		boss_battle_started = false
		if arena_barrier:
			arena_barrier.visible = false
			var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if b_col:
				b_col.disabled = true
		if magic_gate:
			magic_gate.open_gate(false)
		if boss_lunareth:
			boss_lunareth.purify_boss()
		if game_ui:
			game_ui.hide_boss_hud()
	else:
		boss_battle_started = false
		if arena_barrier:
			arena_barrier.visible = false
			var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if b_col:
				b_col.disabled = true
		if boss_lunareth:
			boss_lunareth.reset_boss()
		if magic_gate and quest_manager and quest_manager.current_quest:
			magic_gate.update_quest_status(quest_manager.current_quest)

func clear_boss_projectiles() -> void:
	var projectiles := get_tree().get_nodes_in_group("boss_projectiles")
	for p in projectiles:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			p.queue_free()

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
	# Mở cổng đấu trường ngay khi nhiệm vụ hoàn thành
	if magic_gate:
		magic_gate.update_quest_status(quest)

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

	# Xóa toàn bộ projectile của Boss khi Retry
	clear_boss_projectiles()

	# Xử lý Retry khi tử trận trong trận Boss (Yêu cầu F)
	if boss_battle_started and not boss_defeated:
		boss_battle_started = false
		if arena_barrier:
			arena_barrier.visible = false
			var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if b_col:
				b_col.disabled = true
		if boss_lunareth:
			boss_lunareth.reset_boss()
		if game_ui:
			game_ui.hide_boss_hud()

func _on_resume_button_pressed() -> void:
	if pause_controller:
		pause_controller.resume()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

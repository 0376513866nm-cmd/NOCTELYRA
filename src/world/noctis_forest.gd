class_name NoctisForest
extends BaseZone

## Thế giới Bìa Rừng Noctis & Đấu trường Boss Lunareth (M4, M6, M6.1)
## Quản lý vòng lặp nhiệm vụ, quái vật, cổng ma pháp, đấu trường và Boss Lunareth.

var npc_elyra: NPC

# Boss & Đấu trường (M4)
const BossLunarethScript = preload("res://src/boss/boss_lunareth.gd")
const MagicGateScript = preload("res://src/world/magic_gate.gd")

var boss_lunareth: CharacterBody2D
var magic_gate: StaticBody2D
var arena_barrier: StaticBody2D
var arena_trigger: Area2D
var arena_checkpoint: Vector2 = Vector2(4120.0, 630.0)

var boss_battle_started: bool = false
var boss_defeated: bool = false
var boss_reward_claimed: bool = false

func _init() -> void:
	zone_id = "noctis_forest"
	zone_display_name = "Rừng Noctis"

func _enter_tree() -> void:
	init_references()

func _ready() -> void:
	init_references()
	super._ready()

func init_references() -> void:
	init_base_references()
	if npc_elyra == null:
		npc_elyra = get_node_or_null("NPC_Elyra") as NPC
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
			b_col.set_deferred("disabled", true)

func setup_signals() -> void:
	super.setup_signals()

	# Kết nối NPC Elyra
	if npc_elyra and not npc_elyra.dialogue_requested.is_connected(_on_npc_dialogue_requested):
		npc_elyra.dialogue_requested.connect(_on_npc_dialogue_requested)

	# Kết nối các quái vật trên map (Chỉ qua QuestJournalComponent duy nhất từ BaseZone)
	var enemies = get_tree().get_nodes_in_group(GameGroups.ENEMIES) if get_tree() else []
	for e in enemies:
		if e is Enemy:
			if not e.enemy_defeated.is_connected(_on_enemy_defeated):
				e.enemy_defeated.connect(_on_enemy_defeated)

	# Kết nối tín hiệu hoàn thành nhiệm vụ từ QuestJournalComponent để mở Cổng Ma Pháp
	if player and player.quest_journal_component:
		if not player.quest_journal_component.quest_completed.is_connected(_on_journal_quest_completed):
			player.quest_journal_component.quest_completed.connect(_on_journal_quest_completed)

	# Kết nối Boss Lunareth (M4)
	if boss_lunareth and not boss_lunareth.boss_health_changed.is_connected(_on_boss_health_changed):
		boss_lunareth.boss_health_changed.connect(_on_boss_health_changed)
		boss_lunareth.boss_phase_changed.connect(_on_boss_phase_changed)
		boss_lunareth.boss_telegraph_started.connect(_on_boss_telegraph_started)
		boss_lunareth.boss_defeated.connect(_on_boss_defeated)

	# Kết nối Arena Trigger
	if arena_trigger and not arena_trigger.body_entered.is_connected(_on_arena_trigger_entered):
		arena_trigger.body_entered.connect(_on_arena_trigger_entered)

	# Kết nối Day/Night Cycle với GameUI
	var dnc = get_node_or_null("DayNightCycle")
	if dnc and game_ui:
		dnc.time_updated.connect(func(_h, time_str, phase, icon):
			if game_ui and is_instance_valid(game_ui) and game_ui.has_method("update_time_display"):
				game_ui.update_time_display(time_str, phase, icon)
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			var dnc = get_node_or_null("DayNightCycle")
			if dnc:
				dnc.toggle_time_phase()
				if game_ui:
					game_ui.show_notification("%s Đã đổi thời khắc: %s (%s)" % [dnc.get_phase_icon(), dnc.get_phase_name(), dnc.get_time_string()])

func setup_ui() -> void:
	super.setup_ui()
	# Đồng bộ trạng thái mở cổng theo QuestJournalComponent
	if magic_gate:
		magic_gate.update_quest_status()

func _on_journal_quest_completed(quest_id: String) -> void:
	if quest_id == "quest_noctis_purify" and magic_gate:
		magic_gate.open_gate(true)

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
			b_col.set_deferred("disabled", false)

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
			b_col.set_deferred("disabled", true)

	grant_boss_reward()

func grant_boss_reward() -> void:
	if boss_reward_claimed:
		return
	boss_reward_claimed = true

	# 1. Thưởng 100 Vàng
	if player and player.wallet_component:
		player.wallet_component.add_gold(100)
	elif quest_manager:
		quest_manager.gold += 100

	# 1b. Thưởng 150 EXP từ Boss Lunareth (M8)
	if player and player.progression_component:
		player.progression_component.add_exp(ExpDatabase.get_boss_exp(), "boss:lunareth")

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
				b_col.set_deferred("disabled", true)
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
				b_col.set_deferred("disabled", true)
		if boss_lunareth:
			boss_lunareth.reset_boss()
		if magic_gate and quest_manager and quest_manager.current_quest:
			magic_gate.update_quest_status(quest_manager.current_quest)

func clear_boss_projectiles() -> void:
	if get_tree():
		var projectiles := get_tree().get_nodes_in_group(GameGroups.BOSS_PROJECTILES)
		for p in projectiles:
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()

func clear_all_projectiles() -> void:
	clear_boss_projectiles()
	clear_player_projectiles()

func _on_quest_updated(quest: QuestData) -> void:
	super._on_quest_updated(quest)
	# Mở cổng đấu trường ngay khi nhiệm vụ hoàn thành
	if magic_gate:
		magic_gate.update_quest_status(quest)

func _on_retry_requested() -> void:
	super._on_retry_requested()

	# Xóa toàn bộ projectile của Boss và Player khi Retry
	clear_all_projectiles()

	# Xử lý Retry khi tử trận trong trận Boss
	if boss_battle_started and not boss_defeated:
		boss_battle_started = false
		if arena_barrier:
			arena_barrier.visible = false
			var b_col := arena_barrier.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if b_col:
				b_col.set_deferred("disabled", true)
		if boss_lunareth:
			boss_lunareth.reset_boss()
		if game_ui:
			game_ui.hide_boss_hud()

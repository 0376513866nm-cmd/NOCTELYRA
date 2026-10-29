class_name QuestManager
extends Node

signal quest_started(quest: QuestData)
signal quest_progress_updated(quest: QuestData)
signal quest_ready_to_turn_in(quest: QuestData)
signal quest_completed(quest: QuestData)
signal gold_changed(new_gold: int)
signal notification_posted(message: String)

@export var current_quest: QuestData
var _legacy_gold_buffer: int = 0

var gold: int:
	get:
		var p := _get_player()
		if p and p.wallet_component:
			return p.wallet_component.gold
		return _legacy_gold_buffer
	set(val):
		_legacy_gold_buffer = maxi(0, val)
		var p := _get_player()
		if p and p.wallet_component:
			if not p.wallet_component.gold_changed.is_connected(_on_wallet_gold_changed):
				p.wallet_component.gold_changed.connect(_on_wallet_gold_changed)
			p.wallet_component.set_gold(_legacy_gold_buffer)
		else:
			emit_signal("gold_changed", _legacy_gold_buffer)

var _killed_enemy_ids: Array[String] = []

func _ready() -> void:
	if current_quest == null:
		current_quest = QuestData.new()
	call_deferred("_sync_wallet_connection")

func _sync_wallet_connection() -> void:
	var p := _get_player()
	if p and p.wallet_component:
		if not p.wallet_component.gold_changed.is_connected(_on_wallet_gold_changed):
			p.wallet_component.gold_changed.connect(_on_wallet_gold_changed)
		if _legacy_gold_buffer > 0 and p.wallet_component.gold == 0:
			p.wallet_component.set_gold(_legacy_gold_buffer)

func _on_wallet_gold_changed(new_gold: int) -> void:
	_legacy_gold_buffer = new_gold
	emit_signal("gold_changed", new_gold)

func _get_player() -> Player:
	if get_parent():
		var p := get_parent().get_node_or_null("Player") as Player
		if p:
			return p
	if get_tree():
		if get_tree().current_scene:
			var p := get_tree().current_scene.get_node_or_null("Player") as Player
			if p:
				return p
		var players := get_tree().get_nodes_in_group(GameGroups.PLAYERS)
		if players.size() > 0:
			return players[0] as Player
	return null

func start_quest() -> bool:
	if current_quest == null or current_quest.current_state != QuestData.State.NOT_STARTED:
		return false
	current_quest.current_state = QuestData.State.ACTIVE
	current_quest.current_amount = 0
	_killed_enemy_ids.clear()
	emit_signal("quest_started", current_quest)
	emit_signal("notification_posted", "Đã nhận nhiệm vụ: %s" % current_quest.title)
	return true

func register_enemy_kill(enemy: Node) -> void:
	if current_quest == null or current_quest.current_state != QuestData.State.ACTIVE:
		return
	
	var kill_id: String = ""
	if enemy != null and "enemy_id" in enemy and not str(enemy.enemy_id).is_empty():
		kill_id = str(enemy.enemy_id)
	elif enemy != null:
		kill_id = "inst_" + str(enemy.get_instance_id())
	else:
		return

	if kill_id in _killed_enemy_ids:
		return # Đảm bảo mỗi quái chỉ tính 1 lần theo ID ổn định
	
	_killed_enemy_ids.append(kill_id)
	current_quest.current_amount += 1
	emit_signal("quest_progress_updated", current_quest)
	emit_signal("notification_posted", "Tiến độ: %d/%d sinh vật tha hóa" % [current_quest.current_amount, current_quest.target_amount])

	if current_quest.current_amount >= current_quest.target_amount:
		current_quest.current_state = QuestData.State.READY_TO_TURN_IN
		emit_signal("quest_ready_to_turn_in", current_quest)
		emit_signal("notification_posted", "Nhiệm vụ hoàn tất! Hãy về gặp Eiran để nhận thưởng.")

func complete_quest(player_health: HealthComponent = null) -> bool:
	if current_quest == null or current_quest.current_state != QuestData.State.READY_TO_TURN_IN:
		return false
	
	current_quest.current_state = QuestData.State.COMPLETED
	gold += current_quest.reward_gold

	if player_health:
		player_health.current_health = player_health.max_health
		player_health.current_mana = player_health.max_mana
		player_health.emit_signal("health_changed", player_health.current_health, player_health.max_health)
		player_health.emit_signal("mana_changed", player_health.current_mana, player_health.max_mana)

	emit_signal("quest_completed", current_quest)
	emit_signal("notification_posted", "Hoàn thành: Nhận %d Vàng & hồi đầy HP/MP!" % current_quest.reward_gold)
	return true

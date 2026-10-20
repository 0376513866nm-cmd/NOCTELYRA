class_name QuestManager
extends Node

signal quest_started(quest: QuestData)
signal quest_progress_updated(quest: QuestData)
signal quest_ready_to_turn_in(quest: QuestData)
signal quest_completed(quest: QuestData)
signal gold_changed(new_gold: int)
signal notification_posted(message: String)

@export var current_quest: QuestData
var gold: int = 0
var _killed_enemy_ids: Array[int] = []

func _ready() -> void:
	if current_quest == null:
		current_quest = QuestData.new()

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
	
	var enemy_id := enemy.get_instance_id()
	if enemy_id in _killed_enemy_ids:
		return # Đảm bảo mỗi quái chỉ tính 1 lần
	
	_killed_enemy_ids.append(enemy_id)
	current_quest.current_amount += 1
	emit_signal("quest_progress_updated", current_quest)
	emit_signal("notification_posted", "Tiến độ: %d/%d sinh vật tha hóa" % [current_quest.current_amount, current_quest.target_amount])

	if current_quest.current_amount >= current_quest.target_amount:
		current_quest.current_state = QuestData.State.READY_TO_TURN_IN
		emit_signal("quest_ready_to_turn_in", current_quest)
		emit_signal("notification_posted", "Nhiệm vụ hoàn tất! Hãy về gặp Elyra để nhận thưởng.")

func complete_quest(player_health: HealthComponent = null) -> bool:
	if current_quest == null or current_quest.current_state != QuestData.State.READY_TO_TURN_IN:
		return false
	
	current_quest.current_state = QuestData.State.COMPLETED
	gold += current_quest.reward_gold
	emit_signal("gold_changed", gold)

	if player_health:
		player_health.current_health = player_health.max_health
		player_health.current_mana = player_health.max_mana
		player_health.emit_signal("health_changed", player_health.current_health, player_health.max_health)
		player_health.emit_signal("mana_changed", player_health.current_mana, player_health.max_mana)

	emit_signal("quest_completed", current_quest)
	emit_signal("notification_posted", "Hoàn thành: Nhận %d Vàng & hồi đầy HP/MP!" % current_quest.reward_gold)
	return true

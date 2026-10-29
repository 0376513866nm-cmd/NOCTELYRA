class_name QuestDefinition
extends Resource

## Định nghĩa dữ liệu nhiệm vụ (Quest Definition) cho NOCTELYRA (Milestone M7)
## Hỗ trợ nhiệm vụ tiêu diệt quái theo chủng loại (KILL_ENEMY_TYPE)
## và thu thập vật phẩm từ túi đồ (COLLECT_ITEMS).

enum QuestType {
	KILL_ENEMY_TYPE,
	COLLECT_ITEMS
}

enum QuestState {
	NOT_STARTED = 0,
	ACTIVE = 1,
	READY_TO_TURN_IN = 2,
	COMPLETED = 3
}

const State = QuestState

@export var quest_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var giver_name: String = ""
@export var giver_location: String = ""
@export var quest_type: QuestType = QuestType.KILL_ENEMY_TYPE
@export var target_id: String = "" # enemy_type_id hoặc item_id
@export var target_amount: int = 3
@export var reward_gold: int = 0
@export var reward_exp: int = 0
@export var reward_items: Array[Dictionary] = [] # [{"item_id": "health_potion", "amount": 2}]
@export var offer_dialogue: Array[String] = []
@export var active_dialogue: Array[String] = []
@export var ready_dialogue: Array[String] = []
@export var inventory_full_dialogue: Array[String] = []
@export var completed_dialogue: Array[String] = []

func get_target_display_name() -> String:
	if quest_type == QuestType.KILL_ENEMY_TYPE:
		var enemy := ContentRegistry.get_enemy(target_id)
		return enemy.display_name if enemy else target_id
	var item := ContentRegistry.get_item(target_id)
	return item.display_name if item else target_id

func get_reward_summary() -> String:
	var parts: PackedStringArray = []
	if reward_gold > 0:
		parts.append("%d Vàng" % reward_gold)
	if reward_exp > 0:
		parts.append("%d EXP" % reward_exp)
	for reward in reward_items:
		var item_id := str(reward.get("item_id", ""))
		var item := ContentRegistry.get_item(item_id)
		parts.append("%d %s" % [int(reward.get("amount", 1)), item.display_name if item else item_id])
	return ", ".join(parts)

func format_dialogue(lines: Array[String], progress: int = 0) -> Array[String]:
	var formatted: Array[String] = []
	for line in lines:
		formatted.append(line.replace("{progress}", str(progress))
			.replace("{target}", str(target_amount))
			.replace("{target_name}", get_target_display_name())
			.replace("{reward}", get_reward_summary()))
	return formatted

static func get_definition(q_id: String) -> QuestDefinition:
	var definition := ContentRegistry.get_quest(q_id)
	if definition:
		return definition
	var fallback := QuestDefinition.new()
	fallback.quest_id = q_id
	fallback.title = "Nhiệm vụ chưa xác định"
	return fallback

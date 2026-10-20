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

static func get_definition(q_id: String) -> QuestDefinition:
	var def := QuestDefinition.new()
	def.quest_id = q_id

	match q_id:
		"quest_elyndra_cleansing":
			def.title = "Thanh Lọc Tinh Mạch"
			def.description = "Ma khí tha hóa đang lan tràn trong Thánh Lâm. Hãy tiêu diệt 3 Nấm Mộng Tha Hóa (Corrupted Mooncap) để ổn định dòng chảy Tinh Mạch."
			def.giver_name = "Kaelis"
			def.giver_location = "Thánh Lâm Elyndra"
			def.quest_type = QuestType.KILL_ENEMY_TYPE
			def.target_id = "corrupted_mooncap"
			def.target_amount = 3
			def.reward_gold = 80
			def.reward_exp = 60
			def.reward_items = [
				{"item_id": "health_potion", "amount": 2}
			]

		"quest_vharok_embers":
			def.title = "Tàn Hỏa Hắc Nham"
			def.description = "Thu thập 3 Lõi Tàn Hỏa (Ember Core) nằm rải rác trong khu vực Tiền Đồn Vharok để củng cố kết giới phòng ngự của Quỷ tộc."
			def.giver_name = "Rhaek"
			def.giver_location = "Tiền Đồn Vharok"
			def.quest_type = QuestType.COLLECT_ITEMS
			def.target_id = "ember_core"
			def.target_amount = 3
			def.reward_gold = 100
			def.reward_exp = 70
			def.reward_items = [
				{"item_id": "mana_shard", "amount": 3}
			]

		_:
			def.title = "Nhiệm vụ chưa xác định"
			def.description = ""

	return def

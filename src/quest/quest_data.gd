class_name QuestData
extends Resource

enum State {
	NOT_STARTED,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED
}

@export var id: String = "light_swallowed"
@export var title: String = "Ánh Sáng Bị Nuốt Chửng"
@export var description: String = "Ma lực tại Rừng Hắc Nguyệt đang mất cân bằng. Hãy tiêu diệt 3 sinh vật bị ma lực tha hóa để bảo vệ ngôi làng."
@export var target_amount: int = 3
@export var current_amount: int = 0
@export var reward_gold: int = 50
@export var current_state: State = State.NOT_STARTED

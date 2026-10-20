class_name ExpDatabase
extends RefCounted

## Định nghĩa Nguồn & Mức Thưởng EXP Tập Trung (Milestone M8)
## Cung cấp mức EXP chuẩn cho từng loại quái vật, Boss và nhiệm vụ.

const ENEMY_EXP_MAP: Dictionary = {
	"corrupted_wolf": 20,
	"corrupted_mooncap": 20,
	"corrupted_mana_wisp": 25,
	"ashfang_wolf": 25,
	"ember_lizard": 30
}

const BOSS_EXP: int = 150

const QUEST_EXP_MAP: Dictionary = {
	"quest_tutorial": 50,
	"quest_elyra": 50,
	"quest_noctis_purification": 50,
	"quest_elyndra_cleansing": 60,
	"quest_vharok_embers": 70
}

static func get_enemy_exp(enemy_type_id: String) -> int:
	return int(ENEMY_EXP_MAP.get(enemy_type_id, 20))

static func get_boss_exp() -> int:
	return BOSS_EXP

static func get_quest_exp(quest_id: String) -> int:
	return int(QUEST_EXP_MAP.get(quest_id, 50))

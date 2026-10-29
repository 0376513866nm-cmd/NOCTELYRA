class_name ContentCatalog
extends Resource

## Danh mục content duy nhất của game. Thêm content mới bằng cách tạo .tres
## và đăng ký tại content_catalog.tres, không cần sửa các database gameplay.

@export var items: Array[ItemDefinition] = []
@export var spells: Array[SpellDefinition] = []
@export var races: Array[RaceDefinition] = []
@export var quests: Array[QuestDefinition] = []
@export var enemies: Array[EnemyDefinition] = []
@export var zones: Array[ZoneDefinition] = []

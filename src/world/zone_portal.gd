class_name ZonePortal
extends Area2D

## Cổng Dịch chuyển Khu vực (Zone Portal) cho NOCTELYRA (Milestone M6)
## Quản lý phát hiện người chơi, điều kiện mở khóa, hiển thị nhãn và chuyển cảnh qua ZoneManager.

@export var portal_id: String = ""
@export var portal_name: String = "Cổng Dịch Chuyển"
@export var target_zone_id: String = "elyndra_glade"
@export var target_spawn_id: String = "spawn_from_noctis"
@export var is_locked: bool = false
@export var lock_reason: String = "Cổng ma pháp chưa được khai mở."
@export var portal_color: Color = Color(0.3, 0.8, 1.0, 0.8)

@onready var prompt_label: Label = $PromptLabel
@onready var visual_vortex: Node2D = $VisualVortex

var _player_in_range: bool = false
var _anim_time: float = 0.0

func _ready() -> void:
	add_to_group("zone_portals")
	collision_layer = 0
	collision_mask = 2 # Chỉ tương tác với Player (Layer 2)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_update_prompt_text()
	if prompt_label:
		prompt_label.visible = false

func _process(delta: float) -> void:
	# Hiệu ứng xoay / xung nhịp nhẹ của vòng ma pháp
	_anim_time += delta * 2.0
	if visual_vortex:
		visual_vortex.rotation += delta * 1.5
		var s: float = 1.0 + sin(_anim_time * 2.5) * 0.06
		visual_vortex.scale = Vector2(s, s)

func _update_prompt_text() -> void:
	if prompt_label:
		var dest_name := ZoneDefinition.get_zone_display_name(target_zone_id)
		prompt_label.text = "[E] Dịch chuyển đến %s" % dest_name

func is_interactable() -> bool:
	return _player_in_range and not ZoneManager.is_cooling_down()

func can_use(player: Player, world: Node) -> Dictionary:
	if player == null:
		return {"can_use": false, "reason": "Không tìm thấy người chơi!"}

	var p_health: HealthComponent = player.get_node_or_null("HealthComponent")
	if p_health and not p_health.is_alive():
		return {"can_use": false, "reason": "Người chơi đã tử vong!"}

	if ZoneManager.is_transitioning:
		return {"can_use": false, "reason": "Đang thực hiện dịch chuyển khu vực..."}

	if ZoneManager.is_cooling_down():
		return {"can_use": false, "reason": "Cổng đang hồi phục năng lượng..."}

	# Điều kiện đặc biệt: Cổng Moonveil Portal tại Rừng Noctis chỉ mở khi Boss Lunareth đã bị đánh bại
	if world:
		var cur_zone: String = ZoneManager.get_current_zone_id(world)
		if cur_zone == ZoneDefinition.ZONE_NOCTIS_FOREST and target_zone_id == ZoneDefinition.ZONE_ELYNDRA_GLADE:
			var b_def: bool = bool(world.get("boss_defeated")) if "boss_defeated" in world else false
			if not b_def:
				return {
					"can_use": false,
					"reason": "Cổng ma pháp chưa được khai mở. Hãy thanh tẩy Linh Lộc Lunareth trước!"
				}

	if is_locked:
		return {"can_use": false, "reason": lock_reason}

	return {"can_use": true, "reason": "OK"}

func trigger_interaction() -> void:
	var world := get_tree().current_scene if get_tree() else get_parent()
	var player: Player = null
	if world:
		player = world.get_node_or_null("Player") as Player
	if player == null and get_tree():
		var players := get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player = players[0] as Player

	var check := can_use(player, world)
	var ui := _get_game_ui()

	if not check.get("can_use", false):
		var reason_str: String = str(check.get("reason", lock_reason))
		if ui:
			ui.show_notification(reason_str)
		return

	# Thực hiện dịch chuyển qua ZoneManager
	ZoneManager.travel_to_zone(target_zone_id, target_spawn_id, world)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_in_range = true
		if prompt_label:
			_update_prompt_text()
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _get_game_ui() -> GameUI:
	var cur = get_tree().current_scene if get_tree() else null
	if cur:
		var ui = cur.get_node_or_null("GameUI") as GameUI
		if ui: return ui
	var p = get_parent()
	if p:
		var ui = p.get_node_or_null("GameUI") as GameUI
		if ui: return ui
	return null

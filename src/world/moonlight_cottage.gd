class_name MoonlightCottage
extends Node2D

## Ngôi Nhà Đèn Nguyệt ở rìa Rừng Noctis (The Moonlight Sanctuary Cottage)
## PNG cottage artwork, warm lights and the sanctuary healing area.

@export var heal_rate_percent: float = 0.06 # Hồi 6% HP/giây
@export var mana_rate_percent: float = 0.10 # Hồi 10% MP/giây

@onready var sanctuary_area: Area2D = $SanctuaryArea
@onready var warm_light: PointLight2D = get_node_or_null("WarmWindowLight") as PointLight2D
@onready var porch_light: PointLight2D = get_node_or_null("PorchLanternLight") as PointLight2D

var _player_inside: Player = null
var _flicker_timer: float = 0.0
var _notif_cooldown: float = 0.0
var _dnc: DayNightCycle = null

func _ready() -> void:
	if sanctuary_area:
		sanctuary_area.body_entered.connect(_on_sanctuary_entered)
		sanctuary_area.body_exited.connect(_on_sanctuary_exited)

func _get_dnc() -> DayNightCycle:
	if _dnc == null and get_tree():
		var nodes = get_tree().get_nodes_in_group(GameGroups.DAY_NIGHT_CYCLE)
		if nodes.size() > 0:
			_dnc = nodes[0] as DayNightCycle
	return _dnc

func _process(delta: float) -> void:
	var night_factor: float = 1.0
	var dnc := _get_dnc()
	if dnc:
		night_factor = dnc.get_night_intensity()

	# Hiệu ứng ánh sáng ấm nhấp nháy khẽ (Warm Fire & Candle Flicker)
	# Ban ngày tắt hoặc giữ dịu nhẹ (0.02 - 0.05) tránh hoàn toàn hiện tượng chói lóa / cháy sáng nhân vật
	_flicker_timer += delta * 6.0
	var flicker := 0.95 + sin(_flicker_timer) * 0.04 + cos(_flicker_timer * 1.7) * 0.03
	if warm_light:
		warm_light.energy = lerpf(0.0, 0.45, night_factor) * flicker
	if porch_light:
		porch_light.energy = lerpf(0.0, 0.50, night_factor) * flicker

	if _notif_cooldown > 0.0:
		_notif_cooldown -= delta

	# Hồi phục sinh lực & nội khí khi ở trong khu vực tổ ấm
	if _player_inside and is_instance_valid(_player_inside) and _player_inside.health_component:
		var hc = _player_inside.health_component
		if hc.is_alive():
			var hp_gain: float = float(hc.max_health) * heal_rate_percent * delta
			var mp_gain: float = float(hc.max_mana) * mana_rate_percent * delta
			hc.heal(hp_gain)
			hc.restore_mana(mp_gain)

			# Cập nhật thanh máu/mana trên UI nếu cần
			var ui := _get_game_ui()
			if ui:
				ui.update_player_hp(hc.current_health, hc.max_health)
				ui.update_player_mp(hc.current_mana, hc.max_mana)
				if _notif_cooldown <= 0.0 and (hc.current_health < hc.max_health - 1.0 or hc.current_mana < hc.max_mana - 1.0):
					ui.show_notification("🏡 Tổ Ấm Đèn Nguyệt: Đang sưởi ấm & hồi phục sinh lực...")
					_notif_cooldown = 12.0

func _on_sanctuary_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = body

func _on_sanctuary_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null

func _get_game_ui() -> GameUI:
	var tree := get_tree()
	if tree:
		var uis = tree.get_nodes_in_group(GameGroups.GAME_UI)
		if uis.size() > 0:
			return uis[0] as GameUI
	return null

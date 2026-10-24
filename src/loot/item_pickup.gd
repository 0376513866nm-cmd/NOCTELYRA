@tool
class_name ItemPickup
extends Area2D

## Vật phẩm rơi trên mặt đất (Loot Pickup) cho NOCTELYRA (M3.1)
## Hỗ trợ pickup_id ổn định cho vật phẩm đặt sẵn và khôi phục vật phẩm rơi động.

@export var item_id: String = "mana_shard"
@export var amount: int = 1
@export var pickup_id: String = ""
@export var is_dynamic: bool = false
@export var compact_visuals: bool = false:
	set(value):
		compact_visuals = value
		if is_node_ready():
			_apply_compact_visuals()

@onready var icon_sprite: Sprite2D = $IconSprite
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_y: float = 0.0
var _anim_time: float = 0.0
var is_picked_up: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_compact_visuals()
		return
	collision_layer = 0
	collision_mask = 2 # Player trên Layer 2
	_base_y = position.y
	_update_visuals()
	_apply_compact_visuals()
	body_entered.connect(_on_body_entered)

	if is_dynamic:
		add_to_group("dynamic_pickups")
	else:
		add_to_group("preplaced_pickups")
		# Nếu là vật phẩm đặt sẵn đã được lưu là đã nhặt thì tự hủy
		var cur_scene = get_tree().current_scene if get_tree() else null
		if cur_scene and "collected_pickup_ids" in cur_scene:
			if pickup_id in cur_scene.collected_pickup_ids:
				queue_free()

func setup(p_item_id: String, p_amount: int = 1) -> void:
	item_id = p_item_id
	amount = p_amount
	_update_visuals()

func _update_visuals() -> void:
	var def := ItemDatabase.get_item(item_id)
	if def:
		if label:
			if amount > 1:
				label.text = "%s x%d" % [def.display_name, amount]
			else:
				label.text = def.display_name
		if icon_sprite and def.icon:
			icon_sprite.texture = def.icon
	_apply_compact_visuals()

func _apply_compact_visuals() -> void:
	if not compact_visuals or not icon_sprite:
		return
	if icon_sprite.texture:
		var size: Vector2 = icon_sprite.texture.get_size()
		icon_sprite.scale = Vector2.ONE * (22.0 / maxf(size.x, size.y))
	if label:
		label.visible = false
	var shadow := get_node_or_null("GroundShadow") as Node2D
	if shadow:
		shadow.scale = Vector2(0.55, 0.55)
		shadow.position.y = 12.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Hiệu ứng trôi nổi nhẹ nhàng (bobbing effect)
	_anim_time += delta * 3.5
	position.y = _base_y + sin(_anim_time) * 4.0

func _on_body_entered(body: Node) -> void:
	if is_picked_up:
		return

	if body is Player:
		var inv := body.get_node_or_null("InventoryComponent") as InventoryComponent
		if inv == null:
			return

		# Kiểm tra xem túi đồ có đủ chỗ không
		if inv.can_add_item(item_id, amount):
			is_picked_up = true
			var left := inv.add_item(item_id, amount)
			var def := ItemDatabase.get_item(item_id)
			var item_name := def.display_name if def else item_id

			# Ghi nhận ID đã nhặt nếu là vật phẩm đặt sẵn
			if not is_dynamic and not pickup_id.is_empty():
				var cur_scene = get_tree().current_scene if get_tree() else null
				if cur_scene and cur_scene.has_method("register_collected_pickup"):
					cur_scene.register_collected_pickup(pickup_id)

			# Thông báo nhặt đồ lên HUD
			var ui := _get_game_ui()
			if ui:
				ui.show_notification("Đã nhặt: %s x%d" % [item_name, amount - left])

			queue_free()
		else:
			# Túi đồ đầy, không nhặt và giữ nguyên trên mặt đất
			var ui := _get_game_ui()
			if ui:
				ui.show_notification("Túi đồ đã đầy! Không thể nhặt thêm.")

func _get_game_ui() -> GameUI:
	var cur = get_tree().current_scene if get_tree() else null
	if cur:
		return cur.get_node_or_null("GameUI") as GameUI
	return null

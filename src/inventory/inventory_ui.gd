class_name InventoryUI
extends Control

## Giao diện Túi đồ (Inventory UI) 16 ô và 2 ô trang bị cho NOCTELYRA (M3)

signal inventory_opened()
signal inventory_closed()

@export var player: Player

@onready var grid_container: GridContainer = $Panel/MainHBox/LeftVBox/GridContainer
@onready var weapon_slot_btn: Button = $Panel/MainHBox/LeftVBox/EquipHBox/WeaponSlotBtn
@onready var accessory_slot_btn: Button = $Panel/MainHBox/LeftVBox/EquipHBox/AccessorySlotBtn
@onready var close_btn: Button = $Panel/TitleHBox/CloseBtn

# Bảng chi tiết vật phẩm
@onready var detail_icon: TextureRect = $Panel/MainHBox/RightVBox/DetailIcon
@onready var detail_name: Label = $Panel/MainHBox/RightVBox/DetailName
@onready var detail_type: Label = $Panel/MainHBox/RightVBox/DetailType
@onready var detail_desc: Label = $Panel/MainHBox/RightVBox/DetailDesc
@onready var detail_stats: Label = $Panel/MainHBox/RightVBox/DetailStats

# Nút hành động
@onready var use_btn: Button = $Panel/MainHBox/RightVBox/ActionHBox/UseBtn
@onready var equip_btn: Button = $Panel/MainHBox/RightVBox/ActionHBox/EquipBtn
@onready var unequip_btn: Button = $Panel/MainHBox/RightVBox/ActionHBox/UnequipBtn
@onready var drop_btn: Button = $Panel/MainHBox/RightVBox/ActionHBox/DropBtn

var _selected_slot_idx: int = -1
var _selected_equip_slot: String = "" # "weapon", "accessory", hoặc ""
var _slot_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(close)
	if use_btn:
		use_btn.pressed.connect(_on_use_pressed)
	if equip_btn:
		equip_btn.pressed.connect(_on_equip_pressed)
	if unequip_btn:
		unequip_btn.pressed.connect(_on_unequip_pressed)
	if drop_btn:
		drop_btn.pressed.connect(_on_drop_pressed)

	if weapon_slot_btn:
		weapon_slot_btn.pressed.connect(func(): _select_equip_slot("weapon"))
	if accessory_slot_btn:
		accessory_slot_btn.pressed.connect(func(): _select_equip_slot("accessory"))

	_setup_slots()
	_clear_details()

func setup_player(p: Player) -> void:
	player = p
	if player:
		var inv := player.inventory_component
		if inv and not inv.inventory_updated.is_connected(refresh):
			inv.inventory_updated.connect(refresh)
		var eq := player.equipment_component
		if eq and not eq.equipment_changed.is_connected(_on_equipment_changed):
			eq.equipment_changed.connect(_on_equipment_changed)
	refresh()

func _on_equipment_changed(_slot_type: String, _item_id: String) -> void:
	refresh()

func _ensure_player() -> void:
	if player == null:
		var cur = get_tree().current_scene if get_tree() else null
		if cur:
			var p = cur.get_node_or_null("Player") as Player
			if p:
				setup_player(p)

func _setup_slots() -> void:
	if grid_container == null:
		return
	_slot_buttons.clear()
	for child in grid_container.get_children():
		child.queue_free()

	for i in range(16):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.clip_contents = true

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_right = 1.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
		btn.add_child(icon)

		var lbl := Label.new()
		lbl.name = "Count"
		lbl.anchor_right = 1.0
		lbl.anchor_bottom = 1.0
		lbl.offset_right = -4
		lbl.offset_bottom = -2
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", 11)
		btn.add_child(lbl)

		var slot_idx := i
		btn.pressed.connect(func(): _select_slot(slot_idx))
		grid_container.add_child(btn)
		_slot_buttons.append(btn)

func open() -> void:
	_ensure_player()
	visible = true
	refresh()
	emit_signal("inventory_opened")

func close() -> void:
	visible = false
	_clear_details()
	emit_signal("inventory_closed")

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func is_open() -> bool:
	return visible

func refresh() -> void:
	_ensure_player()
	if player == null:
		return

	var inv := player.inventory_component
	var eq := player.equipment_component

	# 1. Cập nhật 16 ô đồ
	if inv:
		for i in range(min(_slot_buttons.size(), inv.slots.size())):
			var btn := _slot_buttons[i]
			var icon := btn.get_node_or_null("Icon") as TextureRect
			var lbl := btn.get_node_or_null("Count") as Label
			var s := inv.get_slot(i)

			if s.item_id.is_empty() or s.amount <= 0:
				if icon: icon.texture = null
				if lbl: lbl.text = ""
			else:
				var def := ItemDatabase.get_item(s.item_id)
				if icon and def:
					icon.texture = def.icon
				if lbl:
					lbl.text = str(s.amount) if s.amount > 1 else ""

	# 2. Cập nhật 2 ô trang bị
	if eq:
		if weapon_slot_btn:
			var w_id := eq.get_equipped("weapon")
			if w_id.is_empty():
				weapon_slot_btn.text = "Vũ khí: Trống"
				weapon_slot_btn.icon = null
			else:
				var w_def := ItemDatabase.get_item(w_id)
				weapon_slot_btn.text = "VK: " + (w_def.display_name if w_def else w_id)
				weapon_slot_btn.icon = w_def.icon if w_def else null

		if accessory_slot_btn:
			var a_id := eq.get_equipped("accessory")
			if a_id.is_empty():
				accessory_slot_btn.text = "Phụ kiện: Trống"
				accessory_slot_btn.icon = null
			else:
				var a_def := ItemDatabase.get_item(a_id)
				accessory_slot_btn.text = "PK: " + (a_def.display_name if a_def else a_id)
				accessory_slot_btn.icon = a_def.icon if a_def else null

	# Làm mới hiển thị chi tiết vật phẩm đang chọn
	if _selected_slot_idx >= 0:
		_select_slot(_selected_slot_idx)
	elif not _selected_equip_slot.is_empty():
		_select_equip_slot(_selected_equip_slot)
	else:
		_clear_details()

func _select_slot(index: int) -> void:
	_selected_slot_idx = index
	_selected_equip_slot = ""
	_ensure_player()

	if player == null or player.inventory_component == null:
		_clear_details()
		return

	var s := player.inventory_component.get_slot(index)
	if s.item_id.is_empty() or s.amount <= 0:
		_clear_details()
		return

	var def := ItemDatabase.get_item(s.item_id)
	if def == null:
		_clear_details()
		return

	_display_item_details(def, s.amount, false)

func _select_equip_slot(slot_type: String) -> void:
	_selected_slot_idx = -1
	_selected_equip_slot = slot_type
	_ensure_player()

	if player == null or player.equipment_component == null:
		_clear_details()
		return

	var item_id := player.equipment_component.get_equipped(slot_type)
	if item_id.is_empty():
		_clear_details()
		detail_name.text = "Ô trang bị %s (Đang trống)" % ("Vũ khí" if slot_type == "weapon" else "Phụ kiện")
		return

	var def := ItemDatabase.get_item(item_id)
	if def:
		_display_item_details(def, 1, true)

func _display_item_details(def: ItemDefinition, amount: int, is_equipped_slot: bool) -> void:
	if detail_icon:
		detail_icon.texture = def.icon
	if detail_name:
		detail_name.text = "%s (%d)" % [def.display_name, amount] if amount > 1 else def.display_name
	if detail_type:
		detail_type.text = "Loại: %s | Giá trị: %d G" % [def.get_type_name(), def.sell_value]
	if detail_desc:
		detail_desc.text = def.description

	var stat_text := ""
	if def.item_type == ItemDefinition.ItemType.WEAPON:
		stat_text = "+%d Sát thương đánh thường" % int(def.stat_modifiers.get("attack_bonus", 0))
	elif def.item_type == ItemDefinition.ItemType.ACCESSORY:
		stat_text = "+%d Max MP" % int(def.stat_modifiers.get("max_mana_bonus", 0))
	elif def.item_type == ItemDefinition.ItemType.CONSUMABLE:
		stat_text = "Hồi %d HP" % int(def.use_effect.get("heal_hp", 0))
	if detail_stats:
		detail_stats.text = stat_text

	# Cập nhật trạng thái các nút
	if is_equipped_slot:
		if use_btn: use_btn.disabled = true
		if equip_btn: equip_btn.disabled = true
		if unequip_btn: unequip_btn.disabled = false
		if drop_btn: drop_btn.disabled = true
	else:
		if use_btn:
			use_btn.disabled = (def.item_type != ItemDefinition.ItemType.CONSUMABLE)
		if equip_btn:
			equip_btn.disabled = not (def.item_type == ItemDefinition.ItemType.WEAPON or def.item_type == ItemDefinition.ItemType.ACCESSORY)
		if unequip_btn:
			unequip_btn.disabled = true
		if drop_btn:
			drop_btn.disabled = false

func _clear_details() -> void:
	if detail_icon: detail_icon.texture = null
	if detail_name: detail_name.text = "Chọn một vật phẩm để xem chi tiết"
	if detail_type: detail_type.text = ""
	if detail_desc: detail_desc.text = ""
	if detail_stats: detail_stats.text = ""
	if use_btn: use_btn.disabled = true
	if equip_btn: equip_btn.disabled = true
	if unequip_btn: unequip_btn.disabled = true
	if drop_btn: drop_btn.disabled = true

func _on_use_pressed() -> void:
	if _selected_slot_idx < 0 or player == null or player.inventory_component == null:
		return
	player.inventory_component.use_item_at(_selected_slot_idx, player)
	refresh()

func _on_equip_pressed() -> void:
	if _selected_slot_idx < 0 or player == null:
		return
	var inv := player.inventory_component
	var eq := player.equipment_component
	if inv == null or eq == null:
		return

	var s := inv.get_slot(_selected_slot_idx)
	if s.item_id.is_empty():
		return

	var def := ItemDatabase.get_item(s.item_id)
	if def == null:
		return

	var item_to_equip: String = s.item_id
	var prev_item := eq.equip(item_to_equip)
	inv.remove_item_at(_selected_slot_idx, 1)

	if not prev_item.is_empty():
		inv.add_item(prev_item, 1)

	refresh()

func _on_unequip_pressed() -> void:
	if _selected_equip_slot.is_empty() or player == null:
		return
	var inv := player.inventory_component
	var eq := player.equipment_component
	if inv == null or eq == null:
		return

	var item_id := eq.get_equipped(_selected_equip_slot)
	if item_id.is_empty():
		return

	if not inv.can_add_item(item_id, 1):
		var ui = get_parent() as GameUI
		if ui:
			ui.show_notification("Túi đồ đã đầy! Không thể tháo trang bị.")
		return

	var unequipped := eq.unequip(_selected_equip_slot)
	if not unequipped.is_empty():
		inv.add_item(unequipped, 1)

	refresh()

func _on_drop_pressed() -> void:
	if _selected_slot_idx < 0 or player == null:
		return
	var inv := player.inventory_component
	if inv == null:
		return

	var s := inv.get_slot(_selected_slot_idx)
	if s.item_id.is_empty() or s.amount <= 0:
		return

	var drop_id: String = s.item_id
	inv.remove_item_at(_selected_slot_idx, 1)

	# Sinh ItemPickup ra thế giới
	var pickup_scene: PackedScene = preload("res://src/loot/item_pickup.tscn")
	var pickup := pickup_scene.instantiate() as ItemPickup
	pickup.item_id = drop_id
	pickup.amount = 1
	var drop_pos := player.global_position + Vector2(float(player.facing_direction) * 45.0, 0.0)
	pickup.global_position = drop_pos
	if player.get_parent():
		player.get_parent().add_child(pickup)

	refresh()

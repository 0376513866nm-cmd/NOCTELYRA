class_name ItemDatabase
extends RefCounted

## Cơ sở dữ liệu vật phẩm (ItemRegistry) cho NOCTELYRA
## Cho phép tra cứu ItemDefinition ổn định theo item_id.

static var _items: Dictionary = {}
static var _is_initialized: bool = false

static func initialize() -> void:
	if _is_initialized:
		return
	_items.clear()

	# 1. Tinh thể Ma lực (mana_shard)
	var mana_shard = ItemDefinition.new()
	mana_shard.item_id = "mana_shard"
	mana_shard.display_name = "Tinh thể Ma lực"
	mana_shard.description = "Mảnh vỡ ngưng tụ ma lực bóng đêm rơi ra từ sinh vật tha hóa. Dùng làm nguyên liệu."
	mana_shard.item_type = ItemDefinition.ItemType.MATERIAL
	mana_shard.max_stack = 99
	mana_shard.sell_value = 5
	mana_shard.stat_modifiers = {}
	mana_shard.use_effect = {}
	mana_shard.icon = _create_placeholder_icon(Color(0.6, 0.2, 0.9, 1.0)) # Tím ma thuật
	register_item(mana_shard)

	# 2. Bình Sinh Lực (health_potion)
	var potion = ItemDefinition.new()
	potion.item_id = "health_potion"
	potion.display_name = "Bình Sinh Lực"
	potion.description = "Dược tễ thảo mộc ánh nguyệt, hồi phục ngay lập tức 30 HP (không vượt quá Max HP)."
	potion.item_type = ItemDefinition.ItemType.CONSUMABLE
	potion.max_stack = 20
	potion.sell_value = 15
	potion.stat_modifiers = {}
	potion.use_effect = {"heal_hp": 30.0}
	potion.icon = _create_placeholder_icon(Color(0.9, 0.2, 0.2, 1.0)) # Đỏ sinh mệnh
	register_item(potion)

	# 3. Kiếm Ánh Trăng (moonsteel_sword)
	var sword = ItemDefinition.new()
	sword.item_id = "moonsteel_sword"
	sword.display_name = "Kiếm Ánh Trăng"
	sword.description = "Thanh kiếm rèn từ thép ánh nguyệt tinh khiết. Khi trang bị, cộng thêm 10 sát thương đánh thường."
	sword.item_type = ItemDefinition.ItemType.WEAPON
	sword.max_stack = 1
	sword.sell_value = 100
	sword.stat_modifiers = {"attack_bonus": 10.0}
	sword.use_effect = {}
	sword.icon = _create_placeholder_icon(Color(0.4, 0.8, 1.0, 1.0)) # Xanh ánh thép
	register_item(sword)

	# 4. Bùa Nguyệt Quang (moon_amulet)
	var amulet = ItemDefinition.new()
	amulet.item_id = "moon_amulet"
	amulet.display_name = "Bùa Nguyệt Quang"
	amulet.description = "Dây chuyền khắc cổ ngữ bảo hộ của Làng Ánh Nguyệt. Khi trang bị, cộng thêm 20 Max MP."
	amulet.item_type = ItemDefinition.ItemType.ACCESSORY
	amulet.max_stack = 1
	amulet.sell_value = 120
	amulet.stat_modifiers = {"max_mana_bonus": 20.0}
	amulet.use_effect = {}
	amulet.icon = _create_placeholder_icon(Color(1.0, 0.85, 0.3, 1.0)) # Vàng ánh trăng
	register_item(amulet)

	# 5. Mảnh Nguyệt Thực (eclipse_fragment) - [MỚI M4: Phần thưởng Boss Lunareth]
	var fragment = ItemDefinition.new()
	fragment.item_id = "eclipse_fragment"
	fragment.display_name = "Mảnh Nguyệt Thực"
	fragment.description = "Mảnh tinh thể ngưng tụ từ ma lực hắc nguyệt đã được thanh tẩy của linh thú Lunareth. Cổ vật ma đạo quý hiếm."
	fragment.item_type = ItemDefinition.ItemType.MATERIAL
	fragment.max_stack = 99
	fragment.sell_value = 250
	fragment.stat_modifiers = {}
	fragment.use_effect = {}
	fragment.icon = _create_placeholder_icon(Color(0.85, 0.35, 0.95, 1.0)) # Tím nguyệt thực rực rỡ
	register_item(fragment)

	_is_initialized = true

static func register_item(item: ItemDefinition) -> void:
	if item and not item.item_id.is_empty():
		_items[item.item_id] = item

static func get_item(id: String) -> ItemDefinition:
	if not _is_initialized:
		initialize()
	return _items.get(id, null)

static func has_item(id: String) -> bool:
	if not _is_initialized:
		initialize()
	return _items.has(id)

static func get_all_items() -> Array[ItemDefinition]:
	if not _is_initialized:
		initialize()
	var arr: Array[ItemDefinition] = []
	for k in _items.keys():
		arr.append(_items[k])
	return arr

static func _create_placeholder_icon(base_color: Color) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.12, 0.12, 0.16, 1.0))
	for y in range(4, 28):
		for x in range(4, 28):
			img.set_pixel(x, y, base_color)
	for y in range(8, 24):
		for x in range(8, 24):
			var light_col := base_color.lightened(0.3)
			img.set_pixel(x, y, light_col)
	return ImageTexture.create_from_image(img)

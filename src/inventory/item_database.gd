class_name ItemDatabase
extends RefCounted

## Runtime index cho ItemDefinition. Dữ liệu nằm trong src/data/content/items.

static var _items: Dictionary = {}
static var _is_initialized := false

static func initialize() -> void:
	if _is_initialized:
		return
	_items.clear()
	for source in ContentRegistry.catalog().items:
		if source == null or source.item_id.is_empty():
			continue
		var item := source.duplicate(true) as ItemDefinition
		if item.icon == null:
			item.icon = _create_placeholder_icon(item.placeholder_color)
		_items[item.item_id] = item
	_is_initialized = true

static func reset_cache() -> void:
	_items.clear()
	_is_initialized = false

static func register_item(item: ItemDefinition) -> void:
	if item and not item.item_id.is_empty():
		_items[item.item_id] = item

static func get_item(id: String) -> ItemDefinition:
	initialize()
	return _items.get(id, null)

static func has_item(id: String) -> bool:
	initialize()
	return _items.has(id)

static func get_all_items() -> Array[ItemDefinition]:
	initialize()
	var result: Array[ItemDefinition] = []
	for item in _items.values():
		result.append(item as ItemDefinition)
	return result

static func _create_placeholder_icon(base_color: Color) -> ImageTexture:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.12, 0.12, 0.16, 1.0))
	for y in range(4, 28):
		for x in range(4, 28):
			image.set_pixel(x, y, base_color)
	for y in range(8, 24):
		for x in range(8, 24):
			image.set_pixel(x, y, base_color.lightened(0.3))
	return ImageTexture.create_from_image(image)

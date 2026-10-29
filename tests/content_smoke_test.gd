extends SceneTree

func _init() -> void:
	var content := load("res://src/data/content_catalog.tres") as ContentCatalog
	if content == null:
		push_error("Không tải được content catalog")
		quit(1)
		return
	var errors := ContentRegistry.validate()
	if not errors.is_empty():
		for message in errors:
			push_error(message)
		quit(1)
		return
	print("CONTENT_OK items=%d spells=%d races=%d quests=%d enemies=%d zones=%d" % [
		content.items.size(),
		content.spells.size(),
		content.races.size(),
		content.quests.size(),
		content.enemies.size(),
		content.zones.size()
	])
	quit(0)

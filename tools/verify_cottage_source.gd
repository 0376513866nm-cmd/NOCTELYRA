extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var map := (load("res://src/world/noctis_forest.tscn") as PackedScene).instantiate()
	root.add_child(map)
	current_scene = map
	for i in range(4):
		await process_frame
	var cottage := map.get_node("MoonlightCottage") as Node2D
	var art := cottage.get_node("CottageArt") as Sprite2D
	var source := (load("res://src/world/moonlight_cottage.tscn") as PackedScene).instantiate()
	var source_art := source.get_node("CottageArt") as Sprite2D
	var valid := cottage.scene_file_path == "res://src/world/moonlight_cottage.tscn" and art.texture.resource_path == source_art.texture.resource_path and art.transform == source_art.transform
	print("Runtime cottage scene: ", cottage.scene_file_path)
	print("Runtime texture: ", art.texture.resource_path, " dimensions=", art.texture.get_size())
	print("Runtime art transform matches edited source: ", art.transform == source_art.transform)
	print("Map placement preserved: ", cottage.position)
	print("Warm light retained: ", cottage.has_node("WarmWindowLight"))
	print("PASS" if valid else "FAIL")
	source.free()
	quit(0 if valid else 1)

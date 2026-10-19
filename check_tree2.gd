extends SceneTree

func _init() -> void:
	change_scene_to_file("res://src/world/test_level.tscn")
	# Đợi 1 frame để scene mount vào root tree
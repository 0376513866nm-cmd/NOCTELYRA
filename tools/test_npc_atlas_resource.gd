extends SceneTree

func _initialize() -> void:
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/atlas_tool_test/latest.json"))
	var frames := load("res://" + info.resource) as SpriteFrames
	if frames == null or frames.get_frame_count("idle") != 3 or frames.get_animation_speed("idle") != 8:
		push_error("Generated atlas could not be loaded as SpriteFrames")
		quit(1)
		return
	for i in range(3):
		var texture := frames.get_frame_texture("idle", i)
		if texture == null or texture.get_height() != 128:
			quit(1)
			return
	print("PASS: Godot loads relative atlas texture, three frames, 8 FPS")
	quit()

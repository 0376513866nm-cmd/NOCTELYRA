extends SceneTree

const TEST_SAVE := "user://noctelyra_refactor_smoke.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	SaveManager.custom_save_path = TEST_SAVE
	SaveManager.delete_save()
	ZoneManager.reset_session()
	var scene := load("res://src/world/noctis_forest.tscn") as PackedScene
	if scene == null:
		_fail("Không tải được noctis_forest.tscn")
		return
	var world := scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var player := world.get_node_or_null("Player") as Player
	if player == null or player.wallet_component == null:
		_fail("World thiếu Player hoặc WalletComponent")
		return
	player.global_position = Vector2(321.0, 456.0)
	player.wallet_component.set_gold(77)
	if not SaveManager.save_game(world):
		_fail("save_game thất bại")
		return
	player.global_position = Vector2.ZERO
	player.wallet_component.set_gold(0)
	if not SaveManager.load_game(world):
		_fail("load_game thất bại")
		return
	if player.global_position.distance_to(Vector2(321.0, 456.0)) > 0.1:
		_fail("Sai vị trí sau load")
		return
	if player.wallet_component.gold != 77:
		_fail("Sai gold sau load")
		return
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	print("SAVE_SCHEMA_OK version=" + SaveManager.CURRENT_VERSION)
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	SaveManager.delete_save()
	SaveManager.custom_save_path = ""
	quit(1)

class_name MainMenu
extends Control

## Màn hình chính (Main Menu) cho NOCTELYRA (M3 - M8)
## Cung cấp Continue (nếu có save), New Game -> Chọn Tộc (Character Creation), và Quit.

const GAME_SCENE_PATH: String = "res://src/world/noctis_forest.tscn"
const CharacterCreationUIScene = preload("res://src/ui/character_creation_ui.tscn")

@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var new_game_btn: Button = $Panel/VBox/NewGameBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn

@onready var confirm_dialog: Control = $ConfirmDialog
@onready var confirm_yes_btn: Button = $ConfirmDialog/Panel/HBox/YesBtn
@onready var confirm_no_btn: Button = $ConfirmDialog/Panel/HBox/NoBtn

var character_creation_ui: CharacterCreationUI = null

func _ready() -> void:
	if confirm_dialog:
		confirm_dialog.visible = false

	_ensure_character_creation_ui()
	_update_buttons()

	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

	if confirm_yes_btn:
		confirm_yes_btn.pressed.connect(_on_confirm_new_game)
	if confirm_no_btn:
		confirm_no_btn.pressed.connect(func(): confirm_dialog.visible = false)

func _ensure_character_creation_ui() -> void:
	if character_creation_ui == null:
		character_creation_ui = get_node_or_null("CharacterCreationUI") as CharacterCreationUI
	if character_creation_ui == null:
		character_creation_ui = CharacterCreationUIScene.instantiate() as CharacterCreationUI
		character_creation_ui.name = "CharacterCreationUI"
		add_child(character_creation_ui)
	character_creation_ui.visible = false
	if not character_creation_ui.creation_cancelled.is_connected(_on_creation_cancelled):
		character_creation_ui.creation_cancelled.connect(_on_creation_cancelled)

func _on_creation_cancelled() -> void:
	_update_buttons()

func _update_buttons() -> void:
	var has_valid_save := SaveManager.has_save()
	if continue_btn:
		continue_btn.disabled = not has_valid_save

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		ZoneManager.reset_session()
		get_tree().paused = false
		SaveManager.should_load_on_start = true
		var target_scene := SaveManager.get_save_zone_scene_path()
		var error := get_tree().change_scene_to_file(target_scene)
		if error != OK:
			SaveManager.should_load_on_start = false
			push_error("Could not continue saved game: " + error_string(error))

func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		if confirm_dialog:
			confirm_dialog.visible = true
	else:
		_open_character_creation()

func _on_confirm_new_game() -> void:
	if confirm_dialog:
		confirm_dialog.visible = false
	_open_character_creation()

func _open_character_creation() -> void:
	_ensure_character_creation_ui()
	if character_creation_ui:
		character_creation_ui.select_race("human")
		character_creation_ui.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

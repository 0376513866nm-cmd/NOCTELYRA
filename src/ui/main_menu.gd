class_name MainMenu
extends Control

## Màn hình chính (Main Menu) cho NOCTELYRA (M3)
## Cung cấp Continue (nếu có save), New Game (kèm xác nhận ghi đè), và Quit.

const GAME_SCENE_PATH: String = "res://src/world/noctis_forest.tscn"

@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var new_game_btn: Button = $Panel/VBox/NewGameBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn

@onready var confirm_dialog: Control = $ConfirmDialog
@onready var confirm_yes_btn: Button = $ConfirmDialog/Panel/HBox/YesBtn
@onready var confirm_no_btn: Button = $ConfirmDialog/Panel/HBox/NoBtn

func _ready() -> void:
	if confirm_dialog:
		confirm_dialog.visible = false

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

func _update_buttons() -> void:
	var has_valid_save := SaveManager.has_save()
	if continue_btn:
		continue_btn.disabled = not has_valid_save

func _on_continue_pressed() -> void:
	if SaveManager.has_save():
		SaveManager.should_load_on_start = true
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		if confirm_dialog:
			confirm_dialog.visible = true
	else:
		_start_new_game()

func _on_confirm_new_game() -> void:
	SaveManager.delete_save()
	_start_new_game()

func _start_new_game() -> void:
	SaveManager.should_load_on_start = false
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()

class_name GameUI
extends CanvasLayer

signal retry_requested()

@onready var hud: Control = $HUD
@onready var hp_bar: ProgressBar = $HUD/TopLeftBars/HPBar
@onready var mp_bar: ProgressBar = $HUD/TopLeftBars/MPBar
@onready var hp_label: Label = $HUD/TopLeftBars/HPBar/HPLabel
@onready var mp_label: Label = $HUD/TopLeftBars/MPBar/MPLabel
@onready var state_label: Label = $HUD/StateLabel
@onready var gold_label: Label = $HUD/GoldPanel/GoldLabel
@onready var quest_title_label: Label = $HUD/QuestPanel/VBox/QuestTitle
@onready var quest_progress_label: Label = $HUD/QuestPanel/VBox/QuestProgress
@onready var notification_label: Label = $HUD/NotificationLabel

@onready var dialogue_box: Control = $DialogueBox
@onready var dialogue_speaker: Label = $DialogueBox/Panel/SpeakerLabel
@onready var dialogue_text: Label = $DialogueBox/Panel/DialogueText
@onready var dialogue_hint: Label = $DialogueBox/Panel/NextHint

@onready var game_over_panel: Control = $GameOverPanel
@onready var retry_button: Button = $GameOverPanel/Panel/RetryBtn

@onready var pause_menu: Control = $PauseMenu

var _dialogue_lines: Array[String] = []
var _current_dialogue_idx: int = 0
var _current_quest_action: String = "none"
var _notif_timer: float = 0.0

func _ready() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if notification_label:
		notification_label.visible = false
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)

func _process(delta: float) -> void:
	if _notif_timer > 0.0:
		_notif_timer -= delta
		if _notif_timer <= 0.0 and notification_label:
			notification_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_box and dialogue_box.visible:
		if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("jump"):
			advance_dialogue()
			get_viewport().set_input_as_handled()

func show_dialogue(speaker: String, lines: Array[String], action: String = "none") -> void:
	_dialogue_lines = lines
	_current_dialogue_idx = 0
	_current_quest_action = action
	dialogue_speaker.text = speaker
	_display_current_line()
	dialogue_box.visible = true

func _display_current_line() -> void:
	if _current_dialogue_idx < _dialogue_lines.size():
		dialogue_text.text = _dialogue_lines[_current_dialogue_idx]
		if _current_dialogue_idx == _dialogue_lines.size() - 1:
			dialogue_hint.text = "[E / Phím bất kỳ để đóng]"
		else:
			dialogue_hint.text = "[E / Phím bất kỳ để tiếp tục]"

func advance_dialogue() -> void:
	_current_dialogue_idx += 1
	if _current_dialogue_idx < _dialogue_lines.size():
		_display_current_line()
	else:
		close_dialogue()

func close_dialogue() -> void:
	dialogue_box.visible = false
	var scene: Node = _get_active_scene()
	var quest_mgr: QuestManager = scene.get_node_or_null("QuestManager") as QuestManager if scene else null
	var player: Player = scene.get_node_or_null("Player") as Player if scene else null
	var p_health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent if player else null

	if quest_mgr:
		if _current_quest_action == "start_quest":
			quest_mgr.start_quest()
		elif _current_quest_action == "complete_quest":
			quest_mgr.complete_quest(p_health)
	_current_quest_action = "none"

func _get_active_scene() -> Node:
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return get_parent()

func is_dialogue_open() -> bool:
	return dialogue_box and dialogue_box.visible

func update_player_hp(cur: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_v
		hp_bar.value = cur
	if hp_label:
		hp_label.text = "HP: %d/%d" % [int(cur), int(max_v)]

func update_player_mp(cur: float, max_v: float) -> void:
	if mp_bar:
		mp_bar.max_value = max_v
		mp_bar.value = cur
	if mp_label:
		mp_label.text = "MP: %d/%d" % [int(cur), int(max_v)]

func update_player_state(st_name: String) -> void:
	if state_label:
		state_label.text = "State: %s" % st_name

func update_gold(amount: int) -> void:
	if gold_label:
		gold_label.text = "Vàng: %d G" % amount

func update_quest_info(quest: QuestData) -> void:
	if quest == null:
		return
	if quest_title_label:
		quest_title_label.text = "Nhiệm vụ: %s" % quest.title
	if quest_progress_label:
		match quest.current_state:
			QuestData.State.NOT_STARTED:
				quest_progress_label.text = "Tiến độ: Chưa nhận (Gặp Elyra)"
			QuestData.State.ACTIVE:
				quest_progress_label.text = "Tiêu diệt sinh vật: %d/%d" % [quest.current_amount, quest.target_amount]
			QuestData.State.READY_TO_TURN_IN:
				quest_progress_label.text = "Tiến độ: 3/3 (Về gặp Elyra nhận thưởng!)"
			QuestData.State.COMPLETED:
				quest_progress_label.text = "Trạng thái: Đã hoàn thành (+50 Vàng)"

func show_notification(msg: String) -> void:
	if notification_label:
		notification_label.text = msg
		notification_label.visible = true
		_notif_timer = 3.5

func show_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = true

func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false

func _on_retry_pressed() -> void:
	hide_game_over()
	emit_signal("retry_requested")

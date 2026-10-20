class_name GameUI
extends CanvasLayer

## Giao diện người dùng chính (HUD, Dialogue, GameOver, PauseMenu, BossHUD, Victory) cho NOCTELYRA (M4)

signal retry_requested()
signal victory_dismissed()

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

# Boss UI (M4)
@onready var boss_hud: Control = $HUD/BossBarPanel
@onready var boss_name_label: Label = $HUD/BossBarPanel/BossNameLabel
@onready var boss_phase_label: Label = $HUD/BossBarPanel/BossPhaseLabel
@onready var boss_hp_bar: ProgressBar = $HUD/BossBarPanel/BossHPBar
@onready var boss_hp_label: Label = $HUD/BossBarPanel/BossHPBar/BossHPLabel
@onready var boss_warning_label: Label = $HUD/BossWarningBanner
@onready var boss_announcement_label: Label = $HUD/BossAnnouncementBanner
@onready var victory_panel: Control = $VictoryPanel
@onready var victory_title: Label = $VictoryPanel/Panel/Title
@onready var victory_subtitle: Label = $VictoryPanel/Panel/Subtitle
@onready var victory_continue_btn: Button = $VictoryPanel/Panel/ContinueBtn

@onready var dialogue_box: Control = $DialogueBox
@onready var dialogue_speaker: Label = $DialogueBox/Panel/SpeakerLabel
@onready var dialogue_text: Label = $DialogueBox/Panel/DialogueText
@onready var dialogue_hint: Label = $DialogueBox/Panel/NextHint

@onready var game_over_panel: Control = $GameOverPanel
@onready var retry_button: Button = $GameOverPanel/Panel/RetryBtn

@onready var pause_menu: Control = $PauseMenu
@onready var save_btn: Button = $PauseMenu/Panel/SaveBtn
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var quest_journal_ui: QuestJournalUI = $QuestJournalUI
@onready var spell_hotbar: SpellHotbar = $HUD/SpellHotbar

@onready var zone_label: Label = $HUD/ZoneLabel
@onready var zone_banner: Control = $ZoneBanner
@onready var zone_banner_title: Label = $ZoneBanner/Panel/TitleLabel
@onready var zone_banner_subtitle: Label = $ZoneBanner/Panel/SubtitleLabel

var _dialogue_lines: Array[String] = []
var _current_dialogue_idx: int = 0
var _current_quest_action: String = "none"
var _notif_timer: float = 0.0
var _dialogue_cooldown: float = 0.0
var _warning_timer: float = 0.0
var _announcement_timer: float = 0.0
var _zone_banner_timer: float = 0.0

func _ready() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if notification_label:
		notification_label.visible = false
	if boss_hud:
		boss_hud.visible = false
	if boss_warning_label:
		boss_warning_label.visible = false
	if boss_announcement_label:
		boss_announcement_label.visible = false
	if victory_panel:
		victory_panel.visible = false
	if zone_banner:
		zone_banner.visible = false
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if save_btn:
		save_btn.pressed.connect(_on_save_pressed)
	if victory_continue_btn:
		victory_continue_btn.pressed.connect(_on_victory_continue_pressed)

func _process(delta: float) -> void:
	if _notif_timer > 0.0:
		_notif_timer -= delta
		if _notif_timer <= 0.0 and notification_label:
			notification_label.visible = false

	if _dialogue_cooldown > 0.0:
		_dialogue_cooldown -= delta

	if _warning_timer > 0.0:
		_warning_timer -= delta
		if _warning_timer <= 0.0 and boss_warning_label:
			boss_warning_label.visible = false

	if _announcement_timer > 0.0:
		_announcement_timer -= delta
		if _announcement_timer <= 0.0 and boss_announcement_label:
			boss_announcement_label.visible = false

	if _zone_banner_timer > 0.0:
		_zone_banner_timer -= delta
		if _zone_banner_timer <= 0.0 and zone_banner:
			zone_banner.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# Bật/tắt Sổ Nhiệm Vụ bằng phím Q
	if event.is_action_pressed("quest_journal"):
		if not is_dialogue_open():
			toggle_quest_journal()
			get_viewport().set_input_as_handled()
			return

	# Mở/đóng Túi đồ bằng phím I
	if event.is_action_pressed("inventory"):
		if not is_dialogue_open():
			toggle_inventory()
			get_viewport().set_input_as_handled()
			return

	# Phím ESC đóng Journal hoặc Inventory nếu đang mở
	if event.is_action_pressed("ui_cancel"):
		if is_quest_journal_open():
			close_quest_journal()
			get_viewport().set_input_as_handled()
			return
		if is_inventory_open():
			close_inventory()
			get_viewport().set_input_as_handled()
			return

	# Chặn các phím hành động khi đang mở hội thoại, trong thời gian hồi, hoặc đang mở túi đồ / sổ nhiệm vụ
	if is_dialogue_open() or is_dialogue_cooling_down() or is_inventory_open() or is_quest_journal_open():
		if event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("cast_spell") or event.is_action_pressed("dash") or event.is_action_pressed("spell_1") or event.is_action_pressed("spell_2") or event.is_action_pressed("spell_3") or event.is_action_pressed("spell_upgrade"):
			get_viewport().set_input_as_handled()
			return

	# Dự phòng nếu không có InteractionCoordinator trong scene
	if is_dialogue_open() and event.is_action_pressed("interact"):
		if get_tree() and get_tree().get_nodes_in_group("interaction_coordinator").size() == 0:
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
			dialogue_hint.text = "[E để đóng]"
		else:
			dialogue_hint.text = "[E để tiếp tục]"

func advance_dialogue() -> void:
	_current_dialogue_idx += 1
	if _current_dialogue_idx < _dialogue_lines.size():
		_display_current_line()
	else:
		close_dialogue()

func close_dialogue() -> void:
	dialogue_box.visible = false
	_dialogue_cooldown = 0.25 # Grace cooldown 0.25s
	var scene: Node = _get_active_scene()
	var quest_mgr: QuestManager = scene.get_node_or_null("QuestManager") as QuestManager if scene else null
	var player: Player = scene.get_node_or_null("Player") as Player if scene else null
	if player == null and get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Player
	var p_health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent if player else null

	if _current_quest_action.begins_with("start_quest:"):
		var q_id: String = _current_quest_action.substr(12)
		if player and player.quest_journal_component:
			player.quest_journal_component.start_quest(q_id)
			show_notification("Đã nhận nhiệm vụ mới!")
			update_quest_journal_ui()
	elif _current_quest_action.begins_with("complete_quest:"):
		var q_id: String = _current_quest_action.substr(15)
		if player and player.quest_journal_component:
			var res: Dictionary = player.quest_journal_component.turn_in_quest(q_id, player.inventory_component, quest_mgr)
			if bool(res.get("success", false)):
				show_notification("Đã hoàn thành nhiệm vụ và nhận thưởng!")
				update_quest_journal_ui()
				# Tự động lưu sau khi hoàn thành nhiệm vụ
				SaveManager.save_game(scene)
	elif quest_mgr:
		if _current_quest_action == "start_quest":
			quest_mgr.start_quest()
		elif _current_quest_action == "complete_quest":
			quest_mgr.complete_quest(p_health)
			# Tự động lưu sau khi hoàn thành nhiệm vụ và nhận thưởng
			SaveManager.save_game(scene)
	_current_quest_action = "none"

func _get_active_scene() -> Node:
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return get_parent()

func is_dialogue_open() -> bool:
	return dialogue_box and dialogue_box.visible

func is_dialogue_cooling_down() -> bool:
	return _dialogue_cooldown > 0.0

func toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.toggle()

func open_inventory() -> void:
	if inventory_ui:
		inventory_ui.open()

func close_inventory() -> void:
	if inventory_ui:
		inventory_ui.close()

func is_inventory_open() -> bool:
	return inventory_ui != null and inventory_ui.is_open()

func toggle_quest_journal() -> void:
	if quest_journal_ui:
		quest_journal_ui.toggle()

func open_quest_journal() -> void:
	if quest_journal_ui:
		quest_journal_ui.open()

func close_quest_journal() -> void:
	if quest_journal_ui:
		quest_journal_ui.close()

func is_quest_journal_open() -> bool:
	return quest_journal_ui != null and quest_journal_ui.is_open()

func update_quest_journal_ui() -> void:
	if quest_journal_ui and quest_journal_ui.is_open():
		quest_journal_ui.refresh()

func _on_save_pressed() -> void:
	var scene := _get_active_scene()
	# Chặn lưu game thủ công khi Boss đang giao chiến
	if scene and scene.has_method("is_boss_battle_active") and scene.is_boss_battle_active():
		show_notification("Không thể lưu game trong khi đang giao tranh với Boss!")
		return
	if SaveManager.is_boss_combat_active(scene):
		show_notification("Không thể lưu game trong khi đang giao tranh với Boss!")
		return
	var ok: bool = SaveManager.save_game(scene)
	if ok:
		show_notification("Đã lưu tiến trình thành công!")
	else:
		show_notification("Không thể lưu game lúc này!")

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
				quest_progress_label.text = "Trạng thái: Hoàn thành! (Cổng Đấu trường đã mở)"
	update_quest_journal_ui()

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

# --- HỆ THỐNG GIAO DIỆN BOSS (M4) ---

func show_boss_hud() -> void:
	if boss_hud:
		boss_hud.visible = true

func hide_boss_hud() -> void:
	if boss_hud:
		boss_hud.visible = false
	if boss_warning_label:
		boss_warning_label.visible = false
	if boss_announcement_label:
		boss_announcement_label.visible = false

func update_boss_hp(cur: float, max_v: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = max_v
		boss_hp_bar.value = cur
	if boss_hp_label:
		boss_hp_label.text = "HP: %d/%d" % [int(max(0, cur)), int(max_v)]

func update_boss_phase(phase: int) -> void:
	if boss_phase_label:
		if phase == 2:
			boss_phase_label.text = "[GIAI ĐOẠN 2 - HẮC NGUYỆT]"
			boss_phase_label.modulate = Color(1.0, 0.4, 0.9, 1.0)
			show_boss_announcement("LUNARETH GIẢI PHÓNG HẮC NGUYỆT MA LỰC!")
		else:
			boss_phase_label.text = "[GIAI ĐOẠN 1]"
			boss_phase_label.modulate = Color(0.4, 0.9, 1.0, 1.0)

func show_boss_warning(skill_name: String, duration: float) -> void:
	if boss_warning_label:
		boss_warning_label.text = "⚠️ CẢNH BÁO: %s!" % skill_name.to_upper()
		boss_warning_label.visible = true
		_warning_timer = max(0.6, duration)

func show_boss_announcement(msg: String, duration: float = 2.5) -> void:
	if boss_announcement_label:
		boss_announcement_label.text = msg
		boss_announcement_label.visible = true
		_announcement_timer = duration

func show_victory_banner(title: String, subtitle: String) -> void:
	hide_boss_hud()
	if victory_panel:
		if victory_title: victory_title.text = title
		if victory_subtitle: victory_subtitle.text = subtitle
		victory_panel.visible = true

func hide_victory_banner() -> void:
	if victory_panel:
		victory_panel.visible = false

func _on_victory_continue_pressed() -> void:
	hide_victory_banner()
	emit_signal("victory_dismissed")

# --- HỆ THỐNG GIAO DIỆN KHU VỰC & THẾ GIỚI (M6) ---

func set_current_zone(zone_id: String) -> void:
	if zone_label == null:
		zone_label = get_node_or_null("HUD/ZoneLabel") as Label
	if zone_label:
		zone_label.text = "📍 %s" % ZoneDefinition.get_zone_display_name(zone_id)

func show_zone_banner(zone_name: String, subtitle: String = "") -> void:
	if zone_banner == null:
		zone_banner = get_node_or_null("ZoneBanner") as Control
	if zone_banner_title == null:
		zone_banner_title = get_node_or_null("ZoneBanner/Panel/TitleLabel") as Label
	if zone_banner_subtitle == null:
		zone_banner_subtitle = get_node_or_null("ZoneBanner/Panel/SubtitleLabel") as Label

	if zone_banner:
		if zone_banner_title:
			zone_banner_title.text = zone_name
		if zone_banner_subtitle:
			if subtitle.is_empty():
				subtitle = ZoneDefinition.get_zone_sub_title(ZoneManager.current_zone_id)
			zone_banner_subtitle.text = subtitle
		zone_banner.visible = true
		_zone_banner_timer = 2.0

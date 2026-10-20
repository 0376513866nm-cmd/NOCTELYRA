class_name GameUI
extends CanvasLayer

const SettingsManager = preload("res://src/ui/settings_manager.gd")

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
@onready var pause_panel: Panel = $PauseMenu/Panel
@onready var resume_btn: Button = $PauseMenu/Panel/ResumeBtn
@onready var settings_btn: Button = $PauseMenu/Panel/SettingsBtn
@onready var save_btn: Button = $PauseMenu/Panel/SaveBtn
@onready var quit_btn: Button = $PauseMenu/Panel/QuitBtn

@onready var settings_panel: Panel = $PauseMenu/SettingsPanel
@onready var zoom_out_btn: Button = $PauseMenu/SettingsPanel/ZoomControls/ZoomOutBtn
@onready var zoom_label: Label = $PauseMenu/SettingsPanel/ZoomControls/ZoomLabel
@onready var zoom_in_btn: Button = $PauseMenu/SettingsPanel/ZoomControls/ZoomInBtn
@onready var zoom_reset_btn: Button = $PauseMenu/SettingsPanel/ZoomControls/ZoomResetBtn
@onready var zoom_slider: HSlider = $PauseMenu/SettingsPanel/ZoomSlider
@onready var fullscreen_btn: Button = $PauseMenu/SettingsPanel/FullscreenBtn
@onready var settings_close_btn: Button = $PauseMenu/SettingsPanel/SettingsCloseBtn

@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var quest_journal_ui: QuestJournalUI = $QuestJournalUI
@onready var character_sheet_ui: CharacterSheetUI = $CharacterSheetUI
@onready var spell_hotbar: SpellHotbar = $HUD/SpellHotbar

# Sidebar Nodes
@onready var sidebar_toggle_btn: Button = get_node_or_null("HUD/SidebarToggleBtn") as Button
@onready var sidebar: Control = get_node_or_null("Sidebar") as Control
@onready var sidebar_close_btn: Button = get_node_or_null("Sidebar/MainVBox/HeaderHBox/CloseBtn") as Button
@onready var tab_btn_stats: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Stats") as Button
@onready var tab_btn_quests: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Quests") as Button
@onready var tab_btn_inventory: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Inventory") as Button
@onready var tab_btn_settings: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Settings") as Button

@onready var panel_stats: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel") as Control
@onready var panel_quests: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel") as Control
@onready var panel_inventory: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/InventoryPanel") as Control
@onready var panel_settings: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel") as Control

@onready var sidebar_race_label: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/RaceLabel") as Label
@onready var sidebar_level_label: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/LevelExpLabel") as Label
@onready var sidebar_exp_bar: ProgressBar = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/ExpBar") as ProgressBar
@onready var sidebar_exp_label: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/ExpLabel") as Label
@onready var sidebar_stat_hp: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/StatHP") as Label
@onready var sidebar_stat_mp: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/StatMP") as Label
@onready var sidebar_stat_atk: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/StatATK") as Label
@onready var sidebar_stat_regen: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/StatRegen") as Label
@onready var sidebar_stat_speed: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/StatSpeed") as Label
@onready var sidebar_stat_magic: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/StatMagic") as Label
@onready var sidebar_equip_weapon: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/EquipWeapon") as Label
@onready var sidebar_equip_armor: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/EquipArmor") as Label
@onready var sidebar_equip_acc: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/EquipAccessory") as Label
@onready var sidebar_open_sheet_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel/OpenSheetBtn") as Button

@onready var sidebar_quest_title: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestTitle") as Label
@onready var sidebar_quest_status: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestStatus") as Label
@onready var sidebar_quest_desc: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestDesc") as Label
@onready var sidebar_quest_progress: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestProgress") as Label
@onready var sidebar_open_journal_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/OpenJournalBtn") as Button

@onready var sidebar_inv_gold: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/InventoryPanel/InvGoldLabel") as Label
@onready var sidebar_open_inv_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/InventoryPanel/OpenInvBtn") as Button

@onready var sidebar_zoom_out_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/ZoomControlsHBox/SidebarZoomOutBtn") as Button
@onready var sidebar_zoom_label: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/ZoomControlsHBox/SidebarZoomLabel") as Label
@onready var sidebar_zoom_in_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/ZoomControlsHBox/SidebarZoomInBtn") as Button
@onready var sidebar_zoom_reset_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/ZoomControlsHBox/SidebarZoomResetBtn") as Button
@onready var sidebar_zoom_slider: HSlider = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/SidebarZoomSlider") as HSlider
@onready var sidebar_fullscreen_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/SidebarFullscreenBtn") as Button
@onready var sidebar_save_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/SystemBtnsHBox/SidebarSaveBtn") as Button
@onready var sidebar_quit_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel/SystemBtnsHBox/SidebarQuitBtn") as Button

var _current_sidebar_tab: int = 0

@onready var zone_label: Label = $HUD/ZoneLabel
@onready var zone_banner: Control = $ZoneBanner
@onready var zone_banner_title: Label = $ZoneBanner/Panel/TitleLabel
@onready var zone_banner_subtitle: Label = $ZoneBanner/Panel/SubtitleLabel

var _dialogue_lines: Array[String] = []
var _current_dialogue_idx: int = 0
var _current_quest_action: String = "none"
var _notif_timer: float = 0.0
var _dialogue_cooldown: float = 0.0
var _ui_close_grace_cooldown: float = 0.0
var _warning_timer: float = 0.0
var _announcement_timer: float = 0.0
var _zone_banner_timer: float = 0.0

func _ready() -> void:
	if character_sheet_ui == null:
		character_sheet_ui = get_node_or_null("CharacterSheetUI") as CharacterSheetUI
	if character_sheet_ui:
		character_sheet_ui.visible = false
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
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if settings_close_btn:
		settings_close_btn.pressed.connect(_on_settings_close_pressed)
	if zoom_out_btn:
		zoom_out_btn.pressed.connect(_on_zoom_out_pressed)
	if zoom_in_btn:
		zoom_in_btn.pressed.connect(_on_zoom_in_pressed)
	if zoom_reset_btn:
		zoom_reset_btn.pressed.connect(_on_zoom_reset_pressed)
	if zoom_slider:
		zoom_slider.value_changed.connect(_on_zoom_slider_changed)
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
	if victory_continue_btn:
		victory_continue_btn.pressed.connect(_on_victory_continue_pressed)

	# Nạp cấu hình cài đặt và cập nhật UI
	# Kết nối các nút trong Sidebar
	if sidebar_toggle_btn:
		sidebar_toggle_btn.pressed.connect(toggle_sidebar)
	if sidebar_close_btn:
		sidebar_close_btn.pressed.connect(close_sidebar)
	if tab_btn_stats:
		tab_btn_stats.pressed.connect(func(): switch_sidebar_tab(0))
	if tab_btn_quests:
		tab_btn_quests.pressed.connect(func(): switch_sidebar_tab(1))
	if tab_btn_inventory:
		tab_btn_inventory.pressed.connect(func(): switch_sidebar_tab(2))
	if tab_btn_settings:
		tab_btn_settings.pressed.connect(func(): switch_sidebar_tab(3))
	if sidebar_open_sheet_btn:
		sidebar_open_sheet_btn.pressed.connect(open_character_sheet)
	if sidebar_open_journal_btn:
		sidebar_open_journal_btn.pressed.connect(open_quest_journal)
	if sidebar_open_inv_btn:
		sidebar_open_inv_btn.pressed.connect(open_inventory)
	if sidebar_zoom_out_btn:
		sidebar_zoom_out_btn.pressed.connect(_on_zoom_out_pressed)
	if sidebar_zoom_in_btn:
		sidebar_zoom_in_btn.pressed.connect(_on_zoom_in_pressed)
	if sidebar_zoom_reset_btn:
		sidebar_zoom_reset_btn.pressed.connect(_on_zoom_reset_pressed)
	if sidebar_zoom_slider:
		sidebar_zoom_slider.value_changed.connect(_on_zoom_slider_changed)
	if sidebar_fullscreen_btn:
		sidebar_fullscreen_btn.pressed.connect(_on_fullscreen_pressed)
	if sidebar_save_btn:
		sidebar_save_btn.pressed.connect(_on_save_pressed)
	if sidebar_quit_btn:
		sidebar_quit_btn.pressed.connect(_on_quit_pressed)

	switch_sidebar_tab(0)

	SettingsManager.load_settings()
	_update_settings_ui()

func _process(delta: float) -> void:
	if _notif_timer > 0.0:
		_notif_timer -= delta
		if _notif_timer <= 0.0 and notification_label:
			notification_label.visible = false

	if _dialogue_cooldown > 0.0:
		_dialogue_cooldown -= delta

	if _ui_close_grace_cooldown > 0.0:
		_ui_close_grace_cooldown -= delta

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
	# Bật/tắt Sidebar bằng phím Tab hoặc M
	if event.is_action_pressed("toggle_sidebar") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_TAB or event.keycode == KEY_M)):
		if not is_dialogue_open():
			toggle_sidebar()
			get_viewport().set_input_as_handled()
			return

	# Phím ESC đóng Sidebar nếu đang mở
	if event.is_action_pressed("ui_cancel") and is_sidebar_open():
		close_sidebar()
		get_viewport().set_input_as_handled()
		return

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

	# Bật/tắt Bảng Thông Tin Nhân Vật bằng phím C
	if event.is_action_pressed("character_sheet"):
		if not is_dialogue_open():
			toggle_character_sheet()
			get_viewport().set_input_as_handled()
			return

	# Phím ESC đóng Settings nếu đang mở trong PauseMenu
	if event.is_action_pressed("ui_cancel") and settings_panel and settings_panel.visible:
		_on_settings_close_pressed()
		get_viewport().set_input_as_handled()
		return

	# Phím tắt phóng to/thu nhỏ nhanh (Ctrl + '+' / Ctrl + '-')
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			SettingsManager.zoom_in(0.1)
			_update_settings_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			SettingsManager.zoom_out(0.1)
			_update_settings_ui()
			get_viewport().set_input_as_handled()
			return

	# Phím ESC đóng CharacterSheet, Journal hoặc Inventory nếu đang mở
	if event.is_action_pressed("ui_cancel"):
		if is_character_sheet_open():
			close_character_sheet()
			get_viewport().set_input_as_handled()
			return
		if is_quest_journal_open():
			close_quest_journal()
			get_viewport().set_input_as_handled()
			return
		if is_inventory_open():
			close_inventory()
			get_viewport().set_input_as_handled()
			return

	# Đóng Journal hoặc Character Sheet nếu đang mở bằng phím J (attack)
	if is_quest_journal_open() and event.is_action_pressed("attack"):
		close_quest_journal()
		get_viewport().set_input_as_handled()
		return
	if is_character_sheet_open() and event.is_action_pressed("attack"):
		close_character_sheet()
		get_viewport().set_input_as_handled()
		return

	# Chặn các phím hành động khi đang mở hội thoại, trong thời gian hồi, hoặc đang mở túi đồ / sổ nhiệm vụ / bảng nhân vật
	if is_dialogue_open() or is_dialogue_cooling_down() or is_ui_cooling_down() or is_inventory_open() or is_quest_journal_open() or is_character_sheet_open():
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
	_ui_close_grace_cooldown = 0.25
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
			else:
				var fail_reason: String = str(res.get("reason", "Túi đồ đã đầy! Hãy dọn chỗ trống trước khi trả nhiệm vụ."))
				show_notification(fail_reason)
	elif quest_mgr:
		if _current_quest_action == "start_quest":
			quest_mgr.start_quest()
		elif _current_quest_action == "complete_quest":
			quest_mgr.complete_quest(p_health)
			# M8: Thưởng EXP nhiệm vụ chính Elyra (chống nhận trùng)
			if player and player.progression_component:
				player.progression_component.add_exp(ExpDatabase.get_quest_exp("quest_tutorial"), "quest:quest_tutorial")
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

func is_ui_cooling_down() -> bool:
	return _ui_close_grace_cooldown > 0.0

func toggle_inventory() -> void:
	if is_inventory_open():
		close_inventory()
	else:
		if is_quest_journal_open():
			close_quest_journal()
		if is_character_sheet_open():
			close_character_sheet()
		open_inventory()

func open_inventory() -> void:
	if is_quest_journal_open():
		close_quest_journal()
	if is_character_sheet_open():
		close_character_sheet()
	if inventory_ui:
		inventory_ui.open()

func close_inventory() -> void:
	if inventory_ui:
		inventory_ui.close()
	_ui_close_grace_cooldown = 0.15

func is_inventory_open() -> bool:
	return inventory_ui != null and inventory_ui.is_open()

func toggle_quest_journal() -> void:
	if is_quest_journal_open():
		close_quest_journal()
	else:
		if is_inventory_open():
			close_inventory()
		if is_character_sheet_open():
			close_character_sheet()
		open_quest_journal()

func open_quest_journal() -> void:
	if is_inventory_open():
		close_inventory()
	if is_character_sheet_open():
		close_character_sheet()
	if quest_journal_ui:
		quest_journal_ui.open()

func close_quest_journal() -> void:
	if quest_journal_ui:
		quest_journal_ui.close()
	_ui_close_grace_cooldown = 0.15

func is_quest_journal_open() -> bool:
	return quest_journal_ui != null and quest_journal_ui.is_open()

func update_quest_journal_ui() -> void:
	if quest_journal_ui and quest_journal_ui.is_open():
		quest_journal_ui.refresh()

func toggle_character_sheet() -> void:
	if is_character_sheet_open():
		close_character_sheet()
	else:
		if is_inventory_open():
			close_inventory()
		if is_quest_journal_open():
			close_quest_journal()
		open_character_sheet()

func open_character_sheet() -> void:
	if is_inventory_open():
		close_inventory()
	if is_quest_journal_open():
		close_quest_journal()
	if character_sheet_ui:
		var scene := _get_active_scene()
		var player: Player = scene.get_node_or_null("Player") as Player if scene else null
		if player == null and get_tree():
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player = players[0] as Player
		character_sheet_ui.open(player)

func close_character_sheet() -> void:
	if character_sheet_ui:
		character_sheet_ui.close()
	_ui_close_grace_cooldown = 0.15

func is_character_sheet_open() -> bool:
	return character_sheet_ui != null and character_sheet_ui.is_open()

func update_character_sheet_ui() -> void:
	if character_sheet_ui and character_sheet_ui.is_open():
		character_sheet_ui.refresh()

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

var _current_gold: int = 0

func update_gold(amount: int) -> void:
	_current_gold = amount
	if gold_label:
		gold_label.text = "Vàng: %d G" % amount
	if sidebar_inv_gold:
		sidebar_inv_gold.text = "🪙 Vàng Sở Hữu: %d G" % amount

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

# --- HỆ THỐNG CÀI ĐẶT & THU PHÓNG MÀN HÌNH (SETTINGS & ZOOM) ---

func _on_resume_pressed() -> void:
	var scene = _get_active_scene()
	if scene and "pause_controller" in scene and scene.pause_controller:
		scene.pause_controller.resume()
	else:
		get_tree().paused = false
		if pause_menu:
			pause_menu.visible = false

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")

func _on_settings_pressed() -> void:
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = true
	_update_settings_ui()

func _on_settings_close_pressed() -> void:
	if settings_panel:
		settings_panel.visible = false
	if pause_panel:
		pause_panel.visible = true
	SettingsManager.save_settings()

func _on_zoom_out_pressed() -> void:
	SettingsManager.zoom_out(0.1)
	_update_settings_ui()

func _on_zoom_in_pressed() -> void:
	SettingsManager.zoom_in(0.1)
	_update_settings_ui()

func _on_zoom_reset_pressed() -> void:
	SettingsManager.set_zoom(1.0)
	_update_settings_ui()

func _on_zoom_slider_changed(val: float) -> void:
	SettingsManager.set_zoom(val)
	_update_settings_ui()

func _on_fullscreen_pressed() -> void:
	SettingsManager.toggle_fullscreen()
	_update_settings_ui()

func _update_settings_ui() -> void:
	var cur_z = SettingsManager.camera_zoom
	var zoom_pct_str = "%d%% (%.1fx)" % [roundi(cur_z * 100.0), cur_z]
	if zoom_label:
		zoom_label.text = zoom_pct_str
	if zoom_slider and not is_equal_approx(zoom_slider.value, cur_z):
		zoom_slider.value = cur_z
	if sidebar_zoom_label:
		sidebar_zoom_label.text = zoom_pct_str
	if sidebar_zoom_slider and not is_equal_approx(sidebar_zoom_slider.value, cur_z):
		sidebar_zoom_slider.value = cur_z

	var fs_text = "Toàn Màn Hình: BẬT" if SettingsManager.is_fullscreen else "Toàn Màn Hình: TẮT"
	if fullscreen_btn:
		fullscreen_btn.text = fs_text
	if sidebar_fullscreen_btn:
		sidebar_fullscreen_btn.text = fs_text

func is_sidebar_open() -> bool:
	return sidebar != null and sidebar.visible

func open_sidebar(tab_idx: int = -1) -> void:
	if sidebar:
		sidebar.visible = true
		if tab_idx >= 0:
			switch_sidebar_tab(tab_idx)
		_refresh_sidebar_content()

func close_sidebar() -> void:
	if sidebar:
		sidebar.visible = false

func toggle_sidebar() -> void:
	if is_sidebar_open():
		close_sidebar()
	else:
		open_sidebar()

func switch_sidebar_tab(tab_idx: int) -> void:
	_current_sidebar_tab = tab_idx
	if tab_btn_stats:
		tab_btn_stats.button_pressed = (tab_idx == 0)
	if tab_btn_quests:
		tab_btn_quests.button_pressed = (tab_idx == 1)
	if tab_btn_inventory:
		tab_btn_inventory.button_pressed = (tab_idx == 2)
	if tab_btn_settings:
		tab_btn_settings.button_pressed = (tab_idx == 3)

	if panel_stats:
		panel_stats.visible = (tab_idx == 0)
	if panel_quests:
		panel_quests.visible = (tab_idx == 1)
	if panel_inventory:
		panel_inventory.visible = (tab_idx == 2)
	if panel_settings:
		panel_settings.visible = (tab_idx == 3)

	_refresh_sidebar_content()

func _refresh_sidebar_content() -> void:
	var scene = _get_active_scene()
	if scene == null:
		return
	var player = scene.get_node_or_null("Player")
	if player:
		if sidebar_inv_gold:
			sidebar_inv_gold.text = "🪙 Vàng Sở Hữu: %d G" % _current_gold

		var r_name = "Nhân Loại (Human)"
		if player.race_id == "elf":
			r_name = "Tinh Linh (Elf)"
		elif player.race_id == "demon_beast":
			r_name = "Ma Thú (Demon Beast)"
		if sidebar_race_label:
			sidebar_race_label.text = "Chủng tộc: %s" % r_name

		var cur_lvl = 1
		var cur_exp = 0
		var target_exp = 60
		if player.progression_component:
			cur_lvl = player.progression_component.level
			cur_exp = player.progression_component.current_exp
			target_exp = player.progression_component.get_current_target_exp()
		if sidebar_level_label:
			sidebar_level_label.text = "Cấp độ: Lv %d — Tiến độ EXP" % cur_lvl
		if sidebar_exp_bar:
			sidebar_exp_bar.max_value = target_exp if target_exp > 0 else 100
			sidebar_exp_bar.value = cur_exp
		if sidebar_exp_label:
			var pct = (float(cur_exp) / float(target_exp) * 100.0) if target_exp > 0 else 100.0
			sidebar_exp_label.text = "%d / %d EXP (%d%%)" % [cur_exp, target_exp, roundi(pct)]

		if player.health_component and sidebar_stat_hp:
			sidebar_stat_hp.text = "❤️ Sinh Lực (HP): %d / %d" % [roundi(player.health_component.current_health), roundi(player.health_component.max_health)]
		if player.health_component and sidebar_stat_mp:
			sidebar_stat_mp.text = "💧 Nội Khí (MP): %d / %d" % [roundi(player.health_component.current_mana), roundi(player.health_component.max_mana)]
		if player.player_stats_component:
			var stats = player.player_stats_component
			if sidebar_stat_atk:
				sidebar_stat_atk.text = "⚔️ Sức Tấn Công (ATK): %d" % roundi(stats.final_attack)
			if sidebar_stat_regen:
				sidebar_stat_regen.text = "🌀 Hồi Phục: %.1f MP/s" % stats.final_mana_regen
			if sidebar_stat_speed:
				sidebar_stat_speed.text = "⚡ Tốc Độ Di Chuyển: %.0f px/s" % stats.final_move_speed
			if sidebar_stat_magic:
				sidebar_stat_magic.text = "✨ Hệ Số Phép Thuật: %.1fx" % stats.final_magic_multiplier

		if player.equipment_component:
			var eq = player.equipment_component
			if sidebar_equip_weapon:
				var w_name = "Chưa trang bị"
				if not eq.equipped_weapon.is_empty() and ItemDatabase.has_item(eq.equipped_weapon):
					var w_def = ItemDatabase.get_item(eq.equipped_weapon)
					if w_def:
						w_name = w_def.item_name
				sidebar_equip_weapon.text = "• Vũ khí: %s" % w_name
			if sidebar_equip_acc:
				var a_name = "Chưa trang bị"
				if not eq.equipped_accessory.is_empty() and ItemDatabase.has_item(eq.equipped_accessory):
					var a_def = ItemDatabase.get_item(eq.equipped_accessory)
					if a_def:
						a_name = a_def.item_name
				sidebar_equip_acc.text = "• Phụ kiện: %s" % a_name
			if sidebar_equip_armor:
				sidebar_equip_armor.text = "• Giáp: Áo Choàng Cơ Bản"

	if quest_title_label and sidebar_quest_title:
		sidebar_quest_title.text = quest_title_label.text
	if quest_progress_label and sidebar_quest_progress:
		sidebar_quest_progress.text = quest_progress_label.text

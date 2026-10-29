class_name GameUI
extends CanvasLayer

const SettingsManager = preload("res://src/ui/settings_manager.gd")
const SettingsUIController = preload("res://src/ui/controllers/settings_ui_controller.gd")
const SidebarController = preload("res://src/ui/controllers/sidebar_controller.gd")
const BossHUDClass = preload("res://src/ui/boss_hud.gd")
const WorldOverlayUIClass = preload("res://src/ui/world_overlay_ui.gd")
const EndScreenUIClass = preload("res://src/ui/end_screen_ui.gd")
const PauseMenuUIClass = preload("res://src/ui/pause_menu.gd")
const SidebarUIClass = preload("res://src/ui/sidebar_ui.gd")

## Giao diện người dùng chính (HUD, Dialogue, GameOver, PauseMenu, BossHUD, Victory) cho NOCTELYRA (M4)

signal retry_requested()
signal victory_dismissed()
signal input_lock_changed(reason: String, blocked: bool)
signal resume_requested()
signal save_requested()
signal quit_requested()
signal inventory_requested()
signal journal_requested()
signal hybrid_controls_changed(enabled: bool)

@onready var hud: Control = $HUD
@onready var hp_bar: ProgressBar = find_child("HPBar", true, false) as ProgressBar
@onready var mp_bar: ProgressBar = find_child("MPBar", true, false) as ProgressBar
@onready var hp_label: Label = find_child("HPLabel", true, false) as Label
@onready var mp_label: Label = find_child("MPLabel", true, false) as Label
@onready var state_label: Label = find_child("StateLabel", true, false) as Label
@onready var gold_label: Label = find_child("GoldLabel", true, false) as Label
@onready var coord_label: Label = find_child("CoordLabel", true, false) as Label
@onready var settings_gear_btn: Button = find_child("SettingsGearBtn", true, false) as Button
@onready var quest_title_label: Label = $HUD/QuestPanel/VBox/QuestTitle
@onready var quest_progress_label: Label = $HUD/QuestPanel/VBox/QuestProgress

# Sub-scenes (Extracted components)
@onready var boss_hud_controller: BossHUDClass = find_child("BossHUD", true, false) as BossHUDClass
@onready var world_overlay_ui: WorldOverlayUIClass = find_child("WorldOverlayUI", true, false) as WorldOverlayUIClass
@onready var end_screen_ui: EndScreenUIClass = find_child("EndScreenUI", true, false) as EndScreenUIClass
@onready var pause_menu_controller: PauseMenuUIClass = find_child("PauseMenu", true, false) as PauseMenuUIClass
@onready var sidebar_ui: SidebarUIClass = find_child("Sidebar", true, false) as SidebarUIClass

# Boss UI (M4) - Compatibility accessors
@onready var boss_hud: Control = boss_hud_controller.boss_bar_panel if boss_hud_controller else null
@onready var boss_name_label: Label = boss_hud_controller.boss_name_label if boss_hud_controller else null
@onready var boss_phase_label: Label = boss_hud_controller.boss_phase_label if boss_hud_controller else null
@onready var boss_hp_bar: ProgressBar = boss_hud_controller.boss_hp_bar if boss_hud_controller else null
@onready var boss_hp_label: Label = boss_hud_controller.boss_hp_label if boss_hud_controller else null
@onready var boss_warning_label: Label = boss_hud_controller.boss_warning_label if boss_hud_controller else null
@onready var boss_announcement_label: Label = boss_hud_controller.boss_announcement_label if boss_hud_controller else null

# End Screen UI - Compatibility accessors
@onready var victory_panel: Control = end_screen_ui.victory_panel if end_screen_ui else null
@onready var victory_title: Label = end_screen_ui.victory_title if end_screen_ui else null
@onready var victory_subtitle: Label = end_screen_ui.victory_subtitle if end_screen_ui else null
@onready var victory_continue_btn: Button = end_screen_ui.victory_continue_btn if end_screen_ui else null
@onready var game_over_panel: Control = end_screen_ui.game_over_panel if end_screen_ui else null
@onready var retry_button: Button = end_screen_ui.retry_button if end_screen_ui else null

@onready var dialogue_box: Control = $DialogueBox
@onready var dialogue_speaker: Label = $DialogueBox/Panel/SpeakerLabel
@onready var dialogue_text: Label = $DialogueBox/Panel/DialogueText
@onready var dialogue_hint: Label = $DialogueBox/Panel/NextHint

# Pause Menu UI - Compatibility accessors
@onready var pause_menu: Control = pause_menu_controller if pause_menu_controller else null
@onready var pause_panel: Panel = pause_menu_controller.pause_panel if pause_menu_controller else null
@onready var resume_btn: Button = pause_menu_controller.resume_btn if pause_menu_controller else null
@onready var settings_btn: Button = pause_menu_controller.settings_btn if pause_menu_controller else null
@onready var save_btn: Button = pause_menu_controller.save_btn if pause_menu_controller else null
@onready var quit_btn: Button = pause_menu_controller.quit_btn if pause_menu_controller else null

@onready var settings_panel: Panel = pause_menu_controller.settings_panel if pause_menu_controller else null
@onready var zoom_out_btn: Button = pause_menu_controller.zoom_out_btn if pause_menu_controller else null
@onready var zoom_label: Label = pause_menu_controller.zoom_label if pause_menu_controller else null
@onready var zoom_in_btn: Button = pause_menu_controller.zoom_in_btn if pause_menu_controller else null
@onready var zoom_reset_btn: Button = pause_menu_controller.zoom_reset_btn if pause_menu_controller else null
@onready var zoom_slider: HSlider = pause_menu_controller.zoom_slider if pause_menu_controller else null
@onready var fullscreen_btn: Button = pause_menu_controller.fullscreen_btn if pause_menu_controller else null
@onready var fps_btn: Button = find_child("FPSBtn", true, false) as Button
@onready var settings_close_btn: Button = pause_menu_controller.settings_close_btn if pause_menu_controller else null

@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var quest_journal_ui: QuestJournalUI = $QuestJournalUI
@onready var character_sheet_ui: CharacterSheetUI = $CharacterSheetUI
@onready var spell_hotbar: SpellHotbar = $HUD/SpellHotbar

# Sidebar Nodes
@onready var sidebar_toggle_btn: Button = get_node_or_null("HUD/SidebarToggleBtn") as Button
@onready var sidebar: Control = get_node_or_null("Sidebar")
@onready var touch_controls: Control = get_node_or_null("HUD/TouchControls") as Control
@onready var sidebar_close_btn: Button = get_node_or_null("Sidebar/MainVBox/HeaderHBox/CloseBtn") as Button
@onready var tab_btn_stats: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Stats") as Button
@onready var tab_btn_quests: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Quests") as Button
@onready var tab_btn_inventory: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Inventory") as Button
@onready var tab_btn_settings: Button = get_node_or_null("Sidebar/MainVBox/TabBar/TabBtn_Settings") as Button

@onready var panel_stats: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/StatsPanel") as Control
@onready var panel_quests: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel") as Control
@onready var panel_inventory: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/InventoryPanel") as Control
@onready var panel_settings: Control = get_node_or_null("Sidebar/MainVBox/ContentContainer/SettingsPanel") as Control

@onready var sidebar_race_label: Label = find_child("RaceLabel", true, false) as Label
@onready var sidebar_level_label: Label = find_child("LevelExpLabel", true, false) as Label
@onready var sidebar_exp_bar: ProgressBar = find_child("ExpBar", true, false) as ProgressBar
@onready var sidebar_exp_label: Label = find_child("ExpLabel", true, false) as Label
@onready var sidebar_stat_hp: Label = find_child("StatHP", true, false) as Label
@onready var sidebar_stat_mp: Label = find_child("StatMP", true, false) as Label
@onready var sidebar_stat_atk: Label = find_child("StatATK", true, false) as Label
@onready var sidebar_stat_regen: Label = find_child("StatRegen", true, false) as Label
@onready var sidebar_stat_speed: Label = find_child("StatSpeed", true, false) as Label
@onready var sidebar_stat_magic: Label = find_child("StatMagic", true, false) as Label
@onready var sidebar_equip_weapon: Label = find_child("EquipWeapon", true, false) as Label
@onready var sidebar_equip_armor: Label = find_child("EquipArmor", true, false) as Label
@onready var sidebar_equip_acc: Label = find_child("EquipAccessory", true, false) as Label
@onready var sidebar_open_sheet_btn: Button = find_child("OpenSheetBtn", true, false) as Button
@onready var sidebar_shard_label: Label = find_child("SpellUpgradeShardCount", true, false) as Label
@onready var sidebar_upgrade_moon_btn: Button = _get_spell_btn("SpellItem_Moon")
@onready var sidebar_upgrade_ember_btn: Button = _get_spell_btn("SpellItem_Ember")
@onready var sidebar_upgrade_frost_btn: Button = _get_spell_btn("SpellItem_Frost")
@onready var sidebar_spell_moon_lbl: Label = _get_spell_lbl("SpellItem_Moon")
@onready var sidebar_spell_ember_lbl: Label = _get_spell_lbl("SpellItem_Ember")
@onready var sidebar_spell_frost_lbl: Label = _get_spell_lbl("SpellItem_Frost")

@onready var sidebar_quest_title: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestTitle") as Label
@onready var sidebar_quest_status: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestStatus") as Label
@onready var sidebar_quest_desc: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestDesc") as Label
@onready var sidebar_quest_progress: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/SidebarQuestProgress") as Label
@onready var sidebar_open_journal_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/QuestsPanel/OpenJournalBtn") as Button

@onready var sidebar_inv_gold: Label = get_node_or_null("Sidebar/MainVBox/ContentContainer/InventoryPanel/InvGoldLabel") as Label
@onready var sidebar_open_inv_btn: Button = get_node_or_null("Sidebar/MainVBox/ContentContainer/InventoryPanel/OpenInvBtn") as Button

@onready var sidebar_zoom_out_btn: Button = find_child("SidebarZoomOutBtn", true, false) as Button
@onready var sidebar_zoom_label: Label = find_child("SidebarZoomLabel", true, false) as Label
@onready var sidebar_zoom_in_btn: Button = find_child("SidebarZoomInBtn", true, false) as Button
@onready var sidebar_zoom_reset_btn: Button = find_child("SidebarZoomResetBtn", true, false) as Button
@onready var sidebar_zoom_slider: HSlider = find_child("SidebarZoomSlider", true, false) as HSlider
@onready var sidebar_fullscreen_btn: Button = find_child("SidebarFullscreenBtn", true, false) as Button
@onready var sidebar_fps_btn: Button = find_child("SidebarFPSBtn", true, false) as Button
@onready var fps_panel: PanelContainer = find_child("FPSPanel", true, false) as PanelContainer
@onready var fps_label: Label = find_child("FPSLabel", true, false) as Label
@onready var sidebar_save_btn: Button = find_child("SidebarSaveBtn", true, false) as Button
@onready var sidebar_quit_btn: Button = find_child("SidebarQuitBtn", true, false) as Button
@onready var sidebar_hybrid_controls_btn: Button = find_child("SidebarHybridControlsBtn", true, false) as Button
@onready var sidebar_day_night_btn: Button = find_child("SidebarDayNightBtn", true, false) as Button
@onready var guide_toggle_btn: Button = find_child("GuideToggleBtn", true, false) as Button
@onready var guide_content: Control = find_child("GuideContent", true, false) as Control
@onready var time_btn: Button = get_node_or_null("HUD/TimePanel/TimeBtn") as Button

var _current_sidebar_tab: int = 0

# World Overlay UI (M6) - Compatibility accessors
@onready var notification_label: Label = world_overlay_ui.notification_label if world_overlay_ui else null
@onready var zone_label: Label = world_overlay_ui.zone_label if world_overlay_ui else null
@onready var zone_banner: Control = world_overlay_ui.zone_banner if world_overlay_ui else null
@onready var zone_banner_title: Label = world_overlay_ui.zone_banner_title if world_overlay_ui else null
@onready var zone_banner_subtitle: Label = world_overlay_ui.zone_banner_subtitle if world_overlay_ui else null

var _ui_close_grace_cooldown: float = 0.0
var _fps_update_timer: float = 0.0
var _connected_spellbook: SpellbookComponent = null
var _dialogue_controller: DialogueController
var _settings_controller: SettingsUIController
var _sidebar_controller: SidebarController
var _active_ui_locks: Dictionary = {}
var _cached_player: Node = null

func _set_input_lock(reason: String, blocked: bool) -> void:
	if blocked:
		if _active_ui_locks.has(reason):
			return
		_active_ui_locks[reason] = true
	else:
		if not _active_ui_locks.has(reason):
			return
		_active_ui_locks.erase(reason)
	emit_signal("input_lock_changed", reason, blocked)

func sync_locks_to_player(p: Node) -> void:
	if p == null:
		return
	_cached_player = p
	for reason in _active_ui_locks.keys():
		if p.has_method("set_input_blocked"):
			p.set_input_blocked(reason, true)

func _get_player_ref() -> Node:
	if _cached_player and is_instance_valid(_cached_player):
		return _cached_player
	var active_sc := _get_active_scene()
	if active_sc:
		var p = active_sc.get_node_or_null("Player")
		if p:
			_cached_player = p
			return _cached_player
	if get_tree():
		var players = get_tree().get_nodes_in_group(GameGroups.PLAYERS)
		if players.size() > 0:
			_cached_player = players[0]
			return _cached_player
	return null

func _initial_sync_player() -> void:
	var p = _get_player_ref()
	if p:
		if not input_lock_changed.is_connected(p.set_input_blocked):
			input_lock_changed.connect(p.set_input_blocked)
		sync_locks_to_player(p)


func _apply_safe_insets() -> void:
	var top_left_bars: Control = get_node_or_null("HUD/TopLeftBars") as Control
	if top_left_bars:
		top_left_bars.offset_left = 24.0
		top_left_bars.offset_right = 280.0

	var sidebar_node: Control = get_node_or_null("Sidebar") as Control
	if sidebar_node:
		sidebar_node.offset_left = -440.0

func _sync_extracted_components() -> void:
	if boss_hud_controller == null:
		boss_hud_controller = find_child("BossHUD", true, false) as BossHUDClass
	if boss_hud_controller:
		boss_hud = boss_hud_controller.boss_bar_panel
		boss_name_label = boss_hud_controller.boss_name_label
		boss_phase_label = boss_hud_controller.boss_phase_label
		boss_hp_bar = boss_hud_controller.boss_hp_bar
		boss_hp_label = boss_hud_controller.boss_hp_label
		boss_warning_label = boss_hud_controller.boss_warning_label
		boss_announcement_label = boss_hud_controller.boss_announcement_label

	if world_overlay_ui == null:
		world_overlay_ui = find_child("WorldOverlayUI", true, false) as WorldOverlayUIClass
	if world_overlay_ui:
		zone_label = world_overlay_ui.zone_label
		notification_label = world_overlay_ui.notification_label
		zone_banner = world_overlay_ui.zone_banner
		zone_banner_title = world_overlay_ui.zone_banner_title
		zone_banner_subtitle = world_overlay_ui.zone_banner_subtitle

	if end_screen_ui == null:
		end_screen_ui = find_child("EndScreenUI", true, false) as EndScreenUIClass
	if end_screen_ui:
		game_over_panel = end_screen_ui.game_over_panel
		retry_button = end_screen_ui.retry_button
		victory_panel = end_screen_ui.victory_panel
		victory_title = end_screen_ui.victory_title
		victory_subtitle = end_screen_ui.victory_subtitle
		victory_continue_btn = end_screen_ui.victory_continue_btn
		if not end_screen_ui.retry_requested.is_connected(_on_end_screen_retry_requested):
			end_screen_ui.retry_requested.connect(_on_end_screen_retry_requested)
		if not end_screen_ui.victory_dismissed.is_connected(_on_end_screen_victory_dismissed):
			end_screen_ui.victory_dismissed.connect(_on_end_screen_victory_dismissed)

	if pause_menu_controller == null:
		pause_menu_controller = find_child("PauseMenu", true, false) as PauseMenuUIClass
	if pause_menu_controller:
		pause_menu = pause_menu_controller
		pause_panel = pause_menu_controller.pause_panel
		resume_btn = pause_menu_controller.resume_btn
		settings_btn = pause_menu_controller.settings_btn
		save_btn = pause_menu_controller.save_btn
		quit_btn = pause_menu_controller.quit_btn
		settings_panel = pause_menu_controller.settings_panel
		zoom_out_btn = pause_menu_controller.zoom_out_btn
		zoom_label = pause_menu_controller.zoom_label
		zoom_in_btn = pause_menu_controller.zoom_in_btn
		zoom_reset_btn = pause_menu_controller.zoom_reset_btn
		zoom_slider = pause_menu_controller.zoom_slider
		fullscreen_btn = pause_menu_controller.fullscreen_btn
		fps_btn = pause_menu_controller.fps_btn
		settings_close_btn = pause_menu_controller.settings_close_btn
		if not pause_menu_controller.resume_requested.is_connected(_on_resume_pressed):
			pause_menu_controller.resume_requested.connect(_on_resume_pressed)
		if not pause_menu_controller.save_requested.is_connected(_on_save_pressed):
			pause_menu_controller.save_requested.connect(_on_save_pressed)
		if not pause_menu_controller.quit_requested.is_connected(_on_quit_pressed):
			pause_menu_controller.quit_requested.connect(_on_quit_pressed)
		if not pause_menu_controller.settings_opened.is_connected(_on_settings_pressed):
			pause_menu_controller.settings_opened.connect(_on_settings_pressed)
		if not pause_menu_controller.settings_closed.is_connected(_on_settings_close_pressed):
			pause_menu_controller.settings_closed.connect(_on_settings_close_pressed)

	if sidebar_ui == null:
		sidebar_ui = find_child("Sidebar", true, false) as SidebarUIClass
	if sidebar_ui:
		sidebar = sidebar_ui
		sidebar_close_btn = sidebar_ui.close_btn
		tab_btn_stats = sidebar_ui.tab_btn_stats
		tab_btn_quests = sidebar_ui.tab_btn_quests
		tab_btn_inventory = sidebar_ui.tab_btn_inventory
		tab_btn_settings = sidebar_ui.tab_btn_settings
		panel_stats = sidebar_ui.panel_stats
		panel_quests = sidebar_ui.panel_quests
		panel_inventory = sidebar_ui.panel_inventory
		panel_settings = sidebar_ui.panel_settings
		sidebar_race_label = sidebar_ui.race_label
		sidebar_level_label = sidebar_ui.level_label
		sidebar_exp_bar = sidebar_ui.exp_bar
		sidebar_exp_label = sidebar_ui.exp_label
		sidebar_stat_hp = sidebar_ui.stat_hp
		sidebar_stat_mp = sidebar_ui.stat_mp
		sidebar_stat_atk = sidebar_ui.stat_atk
		sidebar_stat_regen = sidebar_ui.stat_regen
		sidebar_stat_speed = sidebar_ui.stat_speed
		sidebar_stat_magic = sidebar_ui.stat_magic
		sidebar_equip_weapon = sidebar_ui.equip_weapon
		sidebar_equip_armor = sidebar_ui.equip_armor
		sidebar_equip_acc = sidebar_ui.equip_acc
		sidebar_open_sheet_btn = sidebar_ui.open_sheet_btn
		sidebar_shard_label = sidebar_ui.shard_label
		sidebar_upgrade_moon_btn = sidebar_ui.spell_moon_btn
		sidebar_upgrade_ember_btn = sidebar_ui.spell_ember_btn
		sidebar_upgrade_frost_btn = sidebar_ui.spell_frost_btn
		sidebar_spell_moon_lbl = sidebar_ui.spell_moon_lbl
		sidebar_spell_ember_lbl = sidebar_ui.spell_ember_lbl
		sidebar_spell_frost_lbl = sidebar_ui.spell_frost_lbl
		sidebar_quest_title = sidebar_ui.quest_title
		sidebar_quest_status = sidebar_ui.quest_status
		sidebar_quest_desc = sidebar_ui.quest_desc
		sidebar_quest_progress = sidebar_ui.quest_progress
		sidebar_open_journal_btn = sidebar_ui.open_journal_btn
		sidebar_inv_gold = sidebar_ui.inv_gold
		sidebar_open_inv_btn = sidebar_ui.open_inv_btn
		sidebar_zoom_out_btn = sidebar_ui.sidebar_zoom_out_btn
		sidebar_zoom_label = sidebar_ui.sidebar_zoom_label
		sidebar_zoom_in_btn = sidebar_ui.sidebar_zoom_in_btn
		sidebar_zoom_reset_btn = sidebar_ui.sidebar_zoom_reset_btn
		sidebar_zoom_slider = sidebar_ui.sidebar_zoom_slider
		sidebar_fullscreen_btn = sidebar_ui.sidebar_fullscreen_btn
		sidebar_fps_btn = sidebar_ui.sidebar_fps_btn
		sidebar_save_btn = sidebar_ui.sidebar_save_btn
		sidebar_quit_btn = sidebar_ui.sidebar_quit_btn
		sidebar_hybrid_controls_btn = sidebar_ui.sidebar_hybrid_controls_btn
		sidebar_day_night_btn = sidebar_ui.sidebar_day_night_btn
		guide_toggle_btn = sidebar_ui.guide_toggle_btn
		guide_content = sidebar_ui.guide_content

		if not sidebar_ui.closed.is_connected(_on_sidebar_closed):
			sidebar_ui.closed.connect(_on_sidebar_closed)
		if not sidebar_ui.tab_changed.is_connected(_on_sidebar_tab_changed):
			sidebar_ui.tab_changed.connect(_on_sidebar_tab_changed)
		if not sidebar_ui.inventory_requested.is_connected(open_inventory):
			sidebar_ui.inventory_requested.connect(open_inventory)
		if not sidebar_ui.journal_requested.is_connected(open_quest_journal):
			sidebar_ui.journal_requested.connect(open_quest_journal)
		if not sidebar_ui.character_sheet_requested.is_connected(open_character_sheet):
			sidebar_ui.character_sheet_requested.connect(open_character_sheet)
		if not sidebar_ui.save_requested.is_connected(_on_save_pressed):
			sidebar_ui.save_requested.connect(_on_save_pressed)
		if not sidebar_ui.quit_requested.is_connected(_on_quit_pressed):
			sidebar_ui.quit_requested.connect(_on_quit_pressed)
		if not sidebar_ui.hybrid_controls_toggled.is_connected(toggle_touch_controls):
			sidebar_ui.hybrid_controls_toggled.connect(toggle_touch_controls)
		if not sidebar_ui.day_night_toggled.is_connected(_on_toggle_day_night_pressed):
			sidebar_ui.day_night_toggled.connect(_on_toggle_day_night_pressed)
		if not sidebar_ui.spell_upgrade_requested.is_connected(_on_sidebar_upgrade_spell):
			sidebar_ui.spell_upgrade_requested.connect(_on_sidebar_upgrade_spell)
		if not sidebar_ui.zoom_in_requested.is_connected(_on_zoom_in_pressed):
			sidebar_ui.zoom_in_requested.connect(_on_zoom_in_pressed)
		if not sidebar_ui.zoom_out_requested.is_connected(_on_zoom_out_pressed):
			sidebar_ui.zoom_out_requested.connect(_on_zoom_out_pressed)
		if not sidebar_ui.zoom_reset_requested.is_connected(_on_zoom_reset_pressed):
			sidebar_ui.zoom_reset_requested.connect(_on_zoom_reset_pressed)
		if not sidebar_ui.zoom_slider_changed.is_connected(_on_zoom_slider_changed):
			sidebar_ui.zoom_slider_changed.connect(_on_zoom_slider_changed)
		if not sidebar_ui.fullscreen_toggled.is_connected(_on_fullscreen_pressed):
			sidebar_ui.fullscreen_toggled.connect(_on_fullscreen_pressed)
		if not sidebar_ui.fps_toggled.is_connected(_on_toggle_fps_pressed):
			sidebar_ui.fps_toggled.connect(_on_toggle_fps_pressed)

func _on_sidebar_tab_changed(tab_idx: int) -> void:
	_current_sidebar_tab = tab_idx
	_refresh_sidebar_content()

func _ready() -> void:
	_sync_extracted_components()
	if character_sheet_ui == null:
		character_sheet_ui = get_node_or_null("CharacterSheetUI") as CharacterSheetUI
	if character_sheet_ui:
		character_sheet_ui.visible = false
	if dialogue_box:
		dialogue_box.visible = false
	_dialogue_controller = DialogueController.new()
	_dialogue_controller.setup(dialogue_box, dialogue_speaker, dialogue_text, dialogue_hint)

	_settings_controller = SettingsUIController.new()
	_settings_controller.setup(
		pause_panel,
		settings_panel,
		zoom_label,
		zoom_slider,
		fullscreen_btn,
		sidebar_zoom_label,
		sidebar_zoom_slider,
		sidebar_fullscreen_btn,
		fps_btn,
		sidebar_fps_btn
	)
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
	if retry_button and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if save_btn and not save_btn.pressed.is_connected(_on_save_pressed):
		save_btn.pressed.connect(_on_save_pressed)
	if resume_btn and not resume_btn.pressed.is_connected(_on_resume_pressed):
		resume_btn.pressed.connect(_on_resume_pressed)
	if quit_btn and not quit_btn.pressed.is_connected(_on_quit_pressed):
		quit_btn.pressed.connect(_on_quit_pressed)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings_pressed):
		settings_btn.pressed.connect(_on_settings_pressed)
	if settings_close_btn and not settings_close_btn.pressed.is_connected(_on_settings_close_pressed):
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
	if fps_btn:
		fps_btn.pressed.connect(_on_toggle_fps_pressed)
	if victory_continue_btn:
		victory_continue_btn.pressed.connect(_on_victory_continue_pressed)
	if inventory_ui:
		inventory_ui.inventory_opened.connect(_on_modal_opened.bind("inventory"))
		inventory_ui.inventory_closed.connect(_on_modal_closed.bind("inventory"))
	if quest_journal_ui:
		quest_journal_ui.journal_opened.connect(_on_modal_opened.bind("quest_journal"))
		quest_journal_ui.journal_closed.connect(_on_modal_closed.bind("quest_journal"))
	if character_sheet_ui:
		character_sheet_ui.sheet_opened.connect(_on_modal_opened.bind("character_sheet"))
		character_sheet_ui.sheet_closed.connect(_on_modal_closed.bind("character_sheet"))
	add_to_group(GameGroups.GAME_UI)
	_apply_safe_insets()
	get_viewport().size_changed.connect(_apply_safe_insets)

	# Nạp cấu hình cài đặt và cập nhật UI
	# Kết nối các nút trong Sidebar
	# Nạp cài đặt trước để kiểm tra trạng thái phím ảo Hybrid
	SettingsManager.load_settings()

	# Thiết lập hiển thị điều khiển theo nền tảng:
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	var initial_touch_visible: bool = is_mobile or SettingsManager.hybrid_controls_enabled
	set_touch_controls_visible(initial_touch_visible)

	if sidebar_toggle_btn:
		sidebar_toggle_btn.pressed.connect(toggle_sidebar)
		sidebar_toggle_btn.visible = not initial_touch_visible
	if settings_gear_btn:
		# One menu entry: touch MENU in hybrid mode, HUD MENU otherwise.
		settings_gear_btn.visible = false
		settings_gear_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if sidebar_hybrid_controls_btn and sidebar_ui == null:
		sidebar_hybrid_controls_btn.pressed.connect(toggle_touch_controls)

	if touch_controls and touch_controls.has_signal("menu_pressed"):
		touch_controls.menu_pressed.connect(toggle_sidebar)

	if sidebar_ui == null:
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
		if sidebar_upgrade_moon_btn:
			sidebar_upgrade_moon_btn.pressed.connect(func(): _on_sidebar_upgrade_spell("moon_bolt"))
		if sidebar_upgrade_ember_btn:
			sidebar_upgrade_ember_btn.pressed.connect(func(): _on_sidebar_upgrade_spell("ember_bloom"))
		if sidebar_upgrade_frost_btn:
			sidebar_upgrade_frost_btn.pressed.connect(func(): _on_sidebar_upgrade_spell("frost_shard"))
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
		if sidebar_fps_btn:
			sidebar_fps_btn.pressed.connect(_on_toggle_fps_pressed)
		if guide_toggle_btn:
			guide_toggle_btn.pressed.connect(_on_guide_toggle_pressed)
		if sidebar_save_btn:
			sidebar_save_btn.pressed.connect(_on_save_pressed)
		if sidebar_quit_btn:
			sidebar_quit_btn.pressed.connect(_on_quit_pressed)
		if sidebar_day_night_btn:
			sidebar_day_night_btn.pressed.connect(_on_toggle_day_night_pressed)

	if time_btn:
		time_btn.pressed.connect(_on_toggle_day_night_pressed)

	switch_sidebar_tab(0)

	_update_settings_ui()
	call_deferred("_initial_sync_player")

func _process(delta: float) -> void:
	_check_connect_spellbook()

	var active_sc := _get_active_scene()
	if active_sc and coord_label:
		var p = active_sc.get_node_or_null("Player") as Node2D
		if p:
			coord_label.text = "[Bìa Rừng Noctis] X: %d - Y: %d" % [int(p.global_position.x), int(p.global_position.y)]

	if fps_panel:
		if SettingsManager.show_fps:
			fps_panel.visible = true
			_fps_update_timer -= delta
			if _fps_update_timer <= 0.0:
				_fps_update_timer = 0.25
				var cur_fps := Engine.get_frames_per_second()
				if fps_label:
					fps_label.text = "%d FPS" % cur_fps
					if cur_fps >= 55:
						fps_label.modulate = Color(0.35, 1.0, 0.45)
					elif cur_fps >= 30:
						fps_label.modulate = Color(1.0, 0.85, 0.25)
					else:
						fps_label.modulate = Color(1.0, 0.35, 0.35)
		else:
			fps_panel.visible = false

	if _dialogue_controller:
		_dialogue_controller.tick(delta)
		if _dialogue_controller.is_cooling_down():
			_set_input_lock("dialogue_cooldown", true)
		else:
			_set_input_lock("dialogue_cooldown", false)

	if _ui_close_grace_cooldown > 0.0:
		_ui_close_grace_cooldown -= delta
		_set_input_lock("ui_cooldown", true)
	else:
		_set_input_lock("ui_cooldown", false)

func _unhandled_input(event: InputEvent) -> void:
	if _handle_debug_shortcuts(event):
		return
	if _handle_dialogue_input(event):
		return
	if _handle_sidebar_shortcuts(event):
		return
	if _handle_modal_shortcuts(event):
		return
	if _handle_pause_shortcuts(event):
		return
	if _block_gameplay_actions_when_ui_open(event):
		return

func _handle_debug_shortcuts(event: InputEvent) -> bool:
	# Phím F1: Bật / Tắt phím ảo cảm ứng (Hybrid Controls)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle_touch_controls()
		if get_viewport():
			get_viewport().set_input_as_handled()
		return true

	# Phím F3: Bật / Tắt hiển thị FPS
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_on_toggle_fps_pressed()
		if get_viewport():
			get_viewport().set_input_as_handled()
		return true

	# Phím tắt phóng to/thu nhỏ nhanh (Ctrl + '+' / Ctrl + '-')
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			SettingsManager.zoom_in(0.1)
			_update_settings_ui()
			get_viewport().set_input_as_handled()
			return true
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			SettingsManager.zoom_out(0.1)
			_update_settings_ui()
			get_viewport().set_input_as_handled()
			return true

	return false

func _handle_dialogue_input(event: InputEvent) -> bool:
	if not is_dialogue_open():
		return false

	# Chạm màn hình bất kỳ hoặc click chuột trái để xem tiếp / đóng thoại
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		advance_dialogue()
		get_viewport().set_input_as_handled()
		return true

	# Dự phòng nếu không có InteractionCoordinator trong scene
	if event.is_action_pressed("interact"):
		if get_tree() and get_tree().get_nodes_in_group(GameGroups.INTERACTION_COORDINATOR).size() == 0:
			advance_dialogue()
			get_viewport().set_input_as_handled()
			return true

	return false

func _handle_sidebar_shortcuts(event: InputEvent) -> bool:
	# Bật/tắt Sidebar bằng phím Tab hoặc M
	if event.is_action_pressed("toggle_sidebar") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_TAB or event.keycode == KEY_M)):
		if not is_dialogue_open():
			toggle_sidebar()
			get_viewport().set_input_as_handled()
			return true

	# Phím ESC đóng Sidebar nếu đang mở
	if event.is_action_pressed("ui_cancel") and is_sidebar_open():
		close_sidebar()
		get_viewport().set_input_as_handled()
		return true

	return false

func _handle_modal_shortcuts(event: InputEvent) -> bool:
	# Bật/tắt Sổ Nhiệm Vụ bằng phím Q
	if event.is_action_pressed("quest_journal"):
		if not is_dialogue_open():
			toggle_quest_journal()
			get_viewport().set_input_as_handled()
			return true

	# Mở/đóng Túi đồ bằng phím I
	if event.is_action_pressed("inventory"):
		if not is_dialogue_open():
			toggle_inventory()
			get_viewport().set_input_as_handled()
			return true

	# Bật/tắt Bảng Thông Tin Nhân Vật bằng phím C
	if event.is_action_pressed("character_sheet"):
		if not is_dialogue_open():
			toggle_character_sheet()
			get_viewport().set_input_as_handled()
			return true

	# Phím ESC đóng Settings nếu đang mở trong PauseMenu
	if event.is_action_pressed("ui_cancel") and settings_panel and settings_panel.visible:
		_on_settings_close_pressed()
		get_viewport().set_input_as_handled()
		return true

	# Phím ESC đóng CharacterSheet, Journal hoặc Inventory nếu đang mở
	if event.is_action_pressed("ui_cancel"):
		if is_character_sheet_open():
			close_character_sheet()
			get_viewport().set_input_as_handled()
			return true
		if is_quest_journal_open():
			close_quest_journal()
			get_viewport().set_input_as_handled()
			return true
		if is_inventory_open():
			close_inventory()
			get_viewport().set_input_as_handled()
			return true

	# Đóng Journal hoặc Character Sheet nếu đang mở bằng phím J (attack)
	if is_quest_journal_open() and event.is_action_pressed("attack"):
		close_quest_journal()
		get_viewport().set_input_as_handled()
		return true
	if is_character_sheet_open() and event.is_action_pressed("attack"):
		close_character_sheet()
		get_viewport().set_input_as_handled()
		return true

	return false

func _handle_pause_shortcuts(event: InputEvent) -> bool:
	if pause_menu and pause_menu.visible and event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
		return true
	return false

func _block_gameplay_actions_when_ui_open(event: InputEvent) -> bool:
	# Chặn các phím hành động khi đang mở hội thoại, trong thời gian hồi, hoặc đang mở túi đồ / sổ nhiệm vụ / bảng nhân vật
	if is_dialogue_open() or is_dialogue_cooling_down() or is_ui_cooling_down() or is_inventory_open() or is_quest_journal_open() or is_character_sheet_open() or (pause_menu and pause_menu.visible):
		if event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("cast_spell") or event.is_action_pressed("dash") or event.is_action_pressed("spell_1") or event.is_action_pressed("spell_2") or event.is_action_pressed("spell_3") or event.is_action_pressed("spell_upgrade"):
			get_viewport().set_input_as_handled()
			return true
	return false

func show_dialogue(speaker: String, lines: Array[String], action: String = "none") -> void:
	if _dialogue_controller:
		_dialogue_controller.show_dialogue(speaker, lines, action)
	_set_input_lock("dialogue", true)

func _display_current_line() -> void:
	pass # Giữ API tương thích; hiển thị do DialogueController quản lý.

func advance_dialogue() -> void:
	if _dialogue_controller == null:
		return
	var action := _dialogue_controller.advance()
	if not action.is_empty():
		_set_input_lock("dialogue", false)
		_ui_close_grace_cooldown = 0.25
		_set_input_lock("ui_cooldown", true)
		_execute_quest_action(action)

func close_dialogue() -> void:
	if _dialogue_controller == null:
		return
	var action := _dialogue_controller.close()
	_set_input_lock("dialogue", false)
	_ui_close_grace_cooldown = 0.25
	_set_input_lock("ui_cooldown", true)
	_execute_quest_action(action)

func _execute_quest_action(action: String) -> void:
	var scene: Node = _get_active_scene()
	var result := QuestActionService.execute(action, scene)
	var message := str(result.get("message", ""))
	if not message.is_empty():
		show_notification(message)
	if bool(result.get("refresh_journal", false)):
		update_quest_journal_ui()

func _get_active_scene() -> Node:
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return get_parent()

func is_dialogue_open() -> bool:
	return _dialogue_controller != null and _dialogue_controller.is_open()

func is_dialogue_cooling_down() -> bool:
	return _dialogue_controller != null and _dialogue_controller.is_cooling_down()

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
	inventory_requested.emit()

func close_inventory() -> void:
	if inventory_ui:
		inventory_ui.close()

func _on_modal_opened(reason: String) -> void:
	_set_input_lock(reason, true)

func _on_modal_closed(reason: String) -> void:
	_set_input_lock(reason, false)
	_ui_close_grace_cooldown = maxf(_ui_close_grace_cooldown, 0.15)
	_set_input_lock("ui_cooldown", true)

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
	journal_requested.emit()

func close_quest_journal() -> void:
	if quest_journal_ui:
		quest_journal_ui.close()

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
			var players = get_tree().get_nodes_in_group(GameGroups.PLAYERS)
			if players.size() > 0:
				player = players[0] as Player
		character_sheet_ui.open(player)

func close_character_sheet() -> void:
	if character_sheet_ui:
		character_sheet_ui.close()

func is_character_sheet_open() -> bool:
	return character_sheet_ui != null and character_sheet_ui.is_open()

func update_character_sheet_ui() -> void:
	if character_sheet_ui and character_sheet_ui.is_open():
		character_sheet_ui.refresh()

func _on_save_pressed() -> void:
	save_requested.emit()
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

func update_quest_info(_unused_arg: Variant = null) -> void:
	var q_title: String = ""
	var q_state: int = 0
	var q_progress: int = 0
	var q_target: int = 3

	var p: Player = null
	if get_parent():
		p = get_parent().get_node_or_null("Player") as Player
	if p == null and get_tree() and get_tree().current_scene:
		p = get_tree().current_scene.get_node_or_null("Player") as Player
	if p and p.quest_journal_component:
		var def := ContentRegistry.get_quest("quest_noctis_purify")
		q_title = def.title if def else "Ánh Sáng Bị Nuốt Chửng"
		q_state = p.quest_journal_component.get_quest_state("quest_noctis_purify")
		q_progress = p.quest_journal_component.get_quest_progress("quest_noctis_purify")
		q_target = def.target_amount if def else 3
	else:
		return

	if quest_title_label:
		quest_title_label.text = "Nhiệm vụ: %s" % q_title
	if quest_progress_label:
		match q_state:
			0:
				quest_progress_label.text = "Tiến độ: Chưa nhận (Gặp Eiran)"
			1:
				quest_progress_label.text = "Tiêu diệt sinh vật: %d/%d" % [q_progress, q_target]
			2:
				quest_progress_label.text = "Tiến độ: 3/3 (Về gặp Eiran nhận thưởng!)"
			3:
				quest_progress_label.text = "Trạng thái: Hoàn thành! (Cổng Đấu trường đã mở)"
	update_quest_journal_ui()

func show_notification(msg: String) -> void:
	if world_overlay_ui:
		world_overlay_ui.show_notification(msg)
	elif notification_label:
		notification_label.text = msg
		notification_label.visible = true

func show_game_over() -> void:
	if end_screen_ui:
		end_screen_ui.show_game_over()
	elif game_over_panel:
		game_over_panel.visible = true
	_set_input_lock("game_over", true)

func hide_game_over() -> void:
	if end_screen_ui:
		end_screen_ui.hide_game_over()
	elif game_over_panel:
		game_over_panel.visible = false
	_set_input_lock("game_over", false)

func _on_end_screen_retry_requested() -> void:
	_set_input_lock("game_over", false)
	retry_requested.emit()

func _on_retry_pressed() -> void:
	hide_game_over()
	retry_requested.emit()

# --- HỆ THỐNG GIAO DIỆN BOSS (M4) ---

func show_boss_hud() -> void:
	if boss_hud_controller:
		boss_hud_controller.show_boss()
	elif boss_hud:
		boss_hud.visible = true

func hide_boss_hud() -> void:
	if boss_hud_controller:
		boss_hud_controller.hide_boss()
	else:
		if boss_hud:
			boss_hud.visible = false
		if boss_warning_label:
			boss_warning_label.visible = false
		if boss_announcement_label:
			boss_announcement_label.visible = false

func update_boss_hp(cur: float, max_v: float) -> void:
	if boss_hud_controller:
		boss_hud_controller.set_health(cur, max_v)
	else:
		if boss_hp_bar:
			boss_hp_bar.max_value = max_v
			boss_hp_bar.value = cur
		if boss_hp_label:
			boss_hp_label.text = "HP: %d/%d" % [int(max(0, cur)), int(max_v)]

func update_boss_phase(phase: int) -> void:
	if boss_hud_controller:
		boss_hud_controller.set_phase(phase)
	elif boss_phase_label:
		if phase == 2:
			boss_phase_label.text = "[GIAI ĐOẠN 2 - HẮC NGUYỆT]"
			boss_phase_label.modulate = Color(1.0, 0.4, 0.9, 1.0)
			show_boss_announcement("LUNARETH GIẢI PHÓNG HẮC NGUYỆT MA LỰC!")
		else:
			boss_phase_label.text = "[GIAI ĐOẠN 1]"
			boss_phase_label.modulate = Color(0.4, 0.9, 1.0, 1.0)

func show_boss_warning(skill_name: String, duration: float = 3.0) -> void:
	if boss_hud_controller:
		boss_hud_controller.show_warning(skill_name, duration)
	elif boss_warning_label:
		boss_warning_label.text = "⚠️ CẢNH BÁO: %s!" % skill_name.to_upper()
		boss_warning_label.visible = true

func show_boss_announcement(msg: String, duration: float = 2.5) -> void:
	if boss_hud_controller:
		boss_hud_controller.show_announcement(msg, duration)
	elif boss_announcement_label:
		boss_announcement_label.text = msg
		boss_announcement_label.visible = true

func show_victory_banner(title: String, subtitle: String) -> void:
	hide_boss_hud()
	if end_screen_ui:
		end_screen_ui.show_victory(title, subtitle)
	elif victory_panel:
		if victory_title: victory_title.text = title
		if victory_subtitle: victory_subtitle.text = subtitle
		victory_panel.visible = true
	_set_input_lock("victory", true)

func hide_victory_banner() -> void:
	if end_screen_ui:
		end_screen_ui.hide_victory()
	elif victory_panel:
		victory_panel.visible = false
	_set_input_lock("victory", false)
	_ui_close_grace_cooldown = 0.25
	_set_input_lock("ui_cooldown", true)

func _on_end_screen_victory_dismissed() -> void:
	hide_victory_banner()
	victory_dismissed.emit()

func _on_victory_continue_pressed() -> void:
	hide_victory_banner()
	victory_dismissed.emit()

# --- HỆ THỐNG GIAO DIỆN KHU VỰC & THẾ GIỚI (M6) ---

func set_current_zone(zone_id: String) -> void:
	if world_overlay_ui:
		world_overlay_ui.update_zone(zone_id)
	elif zone_label:
		zone_label.text = "📍 %s" % ZoneDefinition.get_zone_display_name(zone_id)

func show_zone_banner(zone_name: String, subtitle: String = "") -> void:
	if world_overlay_ui:
		world_overlay_ui.show_zone_banner(zone_name, subtitle)
	elif zone_banner:
		if zone_banner_title:
			zone_banner_title.text = zone_name
		if zone_banner_subtitle:
			if subtitle.is_empty():
				subtitle = ZoneDefinition.get_zone_sub_title(ZoneManager.current_zone_id)
			zone_banner_subtitle.text = subtitle
		zone_banner.visible = true

# --- HỆ THỐNG TẠM DỪNG (PAUSE MENU) ---

func open_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = true
	if get_tree():
		get_tree().paused = true
	_set_input_lock("pause_menu", true)

func close_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = false
	if get_tree():
		get_tree().paused = false
	_set_input_lock("pause_menu", false)

func toggle_pause_menu() -> void:
	if is_pause_menu_open():
		close_pause_menu()
	else:
		open_pause_menu()

func is_pause_menu_open() -> bool:
	return pause_menu != null and pause_menu.visible

# --- HỆ THỐNG CÀI ĐẶT & THU PHÓNG MÀN HÌNH (SETTINGS & ZOOM) ---

func _on_resume_pressed() -> void:
	close_pause_menu()
	resume_requested.emit()

func _on_quit_pressed() -> void:
	quit_requested.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")

func _on_settings_pressed() -> void:
	if _settings_controller:
		_settings_controller.open_settings()
	_update_hybrid_controls_ui()

func _on_settings_close_pressed() -> void:
	if _settings_controller:
		_settings_controller.close_settings()

func _on_zoom_out_pressed() -> void:
	if _settings_controller:
		_settings_controller.zoom_out(0.1)

func _on_zoom_in_pressed() -> void:
	if _settings_controller:
		_settings_controller.zoom_in(0.1)

func _on_zoom_reset_pressed() -> void:
	if _settings_controller:
		_settings_controller.reset_zoom()

func _on_zoom_slider_changed(val: float) -> void:
	if _settings_controller:
		_settings_controller.set_zoom_slider(val)

func _on_fullscreen_pressed() -> void:
	if _settings_controller:
		_settings_controller.toggle_fullscreen()

func _on_toggle_fps_pressed() -> void:
	if _settings_controller:
		_settings_controller.toggle_show_fps()
	else:
		SettingsManager.toggle_show_fps()
	_update_settings_ui()
	var state_str := "BẬT" if SettingsManager.show_fps else "TẮT"
	show_notification("Hiển thị FPS: " + state_str)

func _on_guide_toggle_pressed() -> void:
	if guide_content:
		guide_content.visible = not guide_content.visible
		if guide_toggle_btn:
			guide_toggle_btn.text = "📖 Hướng Dẫn Điều Khiển & Phím Tắt ▼ (Thu gọn)" if guide_content.visible else "📖 Hướng Dẫn Điều Khiển & Phím Tắt ▶"

func _update_settings_ui() -> void:
	if _settings_controller:
		_settings_controller.update_ui()
	_update_hybrid_controls_ui()

func is_sidebar_open() -> bool:
	if sidebar_ui:
		return sidebar_ui.is_open()
	return _sidebar_controller != null and _sidebar_controller.is_open()

func open_sidebar(tab_idx: int = -1) -> void:
	if sidebar_ui:
		sidebar_ui.open(tab_idx)
	elif _sidebar_controller:
		_sidebar_controller.open(tab_idx)
	if touch_controls:
		touch_controls.visible = false
	if sidebar_toggle_btn:
		sidebar_toggle_btn.visible = false
	if spell_hotbar:
		spell_hotbar.visible = false
	_refresh_sidebar_content()
	_set_input_lock("sidebar", true)

func close_sidebar() -> void:
	if sidebar_ui and sidebar_ui.is_open():
		sidebar_ui.close()
		return
	elif _sidebar_controller and _sidebar_controller.is_open():
		_sidebar_controller.close()
	_on_sidebar_closed()

func _on_sidebar_closed() -> void:
	var show_touch := SidebarUIClass.should_show_touch_controls()
	if touch_controls:
		touch_controls.visible = show_touch
		if show_touch and touch_controls.has_method("_sync_current_spell_icon"):
			touch_controls._sync_current_spell_icon()
	if sidebar_toggle_btn:
		sidebar_toggle_btn.visible = not show_touch
	if spell_hotbar:
		spell_hotbar.visible = not show_touch
	_set_input_lock("sidebar", false)
	_ui_close_grace_cooldown = 0.15
	_set_input_lock("ui_cooldown", true)

func toggle_sidebar() -> void:
	if is_sidebar_open():
		close_sidebar()
	else:
		open_sidebar()

func switch_sidebar_tab(tab_idx: int) -> void:
	_current_sidebar_tab = tab_idx
	if sidebar_ui:
		sidebar_ui.switch_tab(tab_idx)
	elif _sidebar_controller:
		_sidebar_controller.switch_tab(tab_idx)
	_refresh_sidebar_content()

func _refresh_sidebar_content() -> void:
	var scene := _get_active_scene()
	var player: Player = scene.get_node_or_null("Player") as Player if scene else null
	var q_title := quest_title_label.text if quest_title_label else ""
	var q_prog := quest_progress_label.text if quest_progress_label else ""
	if sidebar_ui:
		sidebar_ui.refresh_content(player, _current_gold, q_title, q_prog)
	elif _sidebar_controller:
		_sidebar_controller.refresh_content(player, _current_gold, q_title, q_prog)

func _on_sidebar_upgrade_spell(spell_id: String) -> void:
	var scene := _get_active_scene()
	if scene == null:
		return
	var player := scene.get_node_or_null("Player") as Player
	if player:
		var sb: SpellbookComponent = player.get_node_or_null("SpellbookComponent") as SpellbookComponent
		var inv: InventoryComponent = player.get_node_or_null("InventoryComponent") as InventoryComponent
		if sb and inv:
			var res := sb.upgrade_spell(spell_id, inv, scene)
			if res.has("message"):
				show_notification(str(res["message"]))
			_refresh_sidebar_content()

func _get_spell_btn(item_name: String) -> Button:
	var item = find_child(item_name, true, false)
	if item:
		return item.get_node_or_null("UpgradeBtn") as Button
	return null

func _get_spell_lbl(item_name: String) -> Label:
	var item = find_child(item_name, true, false)
	if item:
		return item.get_node_or_null("Label") as Label
	return null

func toggle_touch_controls() -> void:
	var next_enabled := not SettingsManager.hybrid_controls_enabled
	set_touch_controls_visible(next_enabled)
	SettingsManager.save_settings()
	var state_str: String = "BẬT" if next_enabled else "TẮT"
	show_notification("Phím ảo cảm ứng (Hybrid): " + state_str)

func set_touch_controls_visible(show: bool) -> void:
	SettingsManager.hybrid_controls_enabled = show
	if not is_sidebar_open():
		if touch_controls:
			touch_controls.visible = show
			if show and touch_controls.has_method("_sync_current_spell_icon"):
				touch_controls._sync_current_spell_icon()
		if sidebar_toggle_btn:
			sidebar_toggle_btn.visible = not show
		if spell_hotbar:
			spell_hotbar.visible = not show
	_update_hybrid_controls_ui()
	hybrid_controls_changed.emit(show)

func _update_hybrid_controls_ui() -> void:
	if sidebar_ui:
		sidebar_ui.update_hybrid_controls_btn(SettingsManager.hybrid_controls_enabled)
	if sidebar_hybrid_controls_btn:
		sidebar_hybrid_controls_btn.text = "BẬT" if SettingsManager.hybrid_controls_enabled else "TẮT"

func _check_connect_spellbook() -> void:
	if _connected_spellbook and is_instance_valid(_connected_spellbook):
		return
	var scene := _get_active_scene()
	if scene:
		var p = scene.get_node_or_null("Player") as Player
		if p and p.spellbook_component:
			_connected_spellbook = p.spellbook_component
			if not _connected_spellbook.spell_selected.is_connected(_on_player_spell_selected):
				_connected_spellbook.spell_selected.connect(_on_player_spell_selected)

func _on_player_spell_selected(spell_id: String) -> void:
	var spell := SpellDatabase.get_spell(spell_id)
	if spell:
		var prefix := "🌙"
		var key_num := "1"
		if spell_id == "ember_bloom":
			prefix = "🔥"
			key_num = "2"
		elif spell_id == "frost_shard":
			prefix = "❄️"
			key_num = "3"
		show_notification("%s Đã đổi ma pháp: %s (Phím %s / Cuộn chuột)" % [prefix, spell.display_name, key_num])

	if touch_controls and touch_controls.has_method("set_selected_spell"):
		touch_controls.set_selected_spell(spell_id)

func _on_toggle_day_night_pressed() -> void:
	var dnc = get_tree().get_first_node_in_group(GameGroups.DAY_NIGHT_CYCLE)
	if dnc:
		dnc.toggle_time_phase()
		show_notification("%s Đã đổi thời khắc: %s (%s)" % [dnc.get_phase_icon(), dnc.get_phase_name(), dnc.get_time_string()])

func update_time_display(time_str: String, phase: String, icon: String) -> void:
	var p_name := phase
	match phase:
		"dawn": p_name = "Bình Minh"
		"day":  p_name = "Ngày"
		"dusk": p_name = "Hoàng Hôn"
		_:      p_name = "Đêm"
	var text_fmt := "%s %s %s" % [icon, time_str, p_name]
	if time_btn:
		time_btn.text = text_fmt
	if sidebar_day_night_btn:
		sidebar_day_night_btn.text = "%s Đổi Thời Gian (%s)" % [icon, text_fmt]

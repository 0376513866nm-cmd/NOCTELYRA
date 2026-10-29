class_name SidebarUI
extends Control

const SettingsManager = preload("res://src/ui/settings_manager.gd")

signal closed()
signal opened()
signal tab_changed(tab_idx: int)
signal inventory_requested()
signal journal_requested()
signal character_sheet_requested()
signal save_requested()
signal quit_requested()
signal hybrid_controls_toggled()
signal day_night_toggled()
signal spell_upgrade_requested(spell_id: String)
signal zoom_in_requested()
signal zoom_out_requested()
signal zoom_reset_requested()
signal zoom_slider_changed(value: float)
signal fullscreen_toggled()
signal fps_toggled()

# Top controls
@onready var close_btn: Button = get_node_or_null("MainVBox/HeaderHBox/CloseBtn") as Button
@onready var tab_btn_stats: Button = get_node_or_null("MainVBox/TabBar/TabBtn_Stats") as Button
@onready var tab_btn_quests: Button = get_node_or_null("MainVBox/TabBar/TabBtn_Quests") as Button
@onready var tab_btn_inventory: Button = get_node_or_null("MainVBox/TabBar/TabBtn_Inventory") as Button
@onready var tab_btn_settings: Button = get_node_or_null("MainVBox/TabBar/TabBtn_Settings") as Button

# Panels
@onready var panel_stats: Control = get_node_or_null("MainVBox/ContentContainer/StatsPanel") as Control
@onready var panel_quests: Control = get_node_or_null("MainVBox/ContentContainer/QuestsPanel") as Control
@onready var panel_inventory: Control = get_node_or_null("MainVBox/ContentContainer/InventoryPanel") as Control
@onready var panel_settings: Control = get_node_or_null("MainVBox/ContentContainer/SettingsPanel") as Control

# Stats Panel controls
@onready var race_label: Label = find_child("RaceLabel", true, false) as Label
@onready var level_label: Label = find_child("LevelExpLabel", true, false) as Label
@onready var exp_bar: ProgressBar = find_child("ExpBar", true, false) as ProgressBar
@onready var exp_label: Label = find_child("ExpLabel", true, false) as Label
@onready var stat_hp: Label = find_child("StatHP", true, false) as Label
@onready var stat_mp: Label = find_child("StatMP", true, false) as Label
@onready var stat_atk: Label = find_child("StatATK", true, false) as Label
@onready var stat_regen: Label = find_child("StatRegen", true, false) as Label
@onready var stat_speed: Label = find_child("StatSpeed", true, false) as Label
@onready var stat_magic: Label = find_child("StatMagic", true, false) as Label
@onready var equip_weapon: Label = find_child("EquipWeapon", true, false) as Label
@onready var equip_armor: Label = find_child("EquipArmor", true, false) as Label
@onready var equip_acc: Label = find_child("EquipAccessory", true, false) as Label
@onready var open_sheet_btn: Button = find_child("OpenSheetBtn", true, false) as Button

# Spell Upgrade controls
@onready var shard_label: Label = find_child("SpellUpgradeShardCount", true, false) as Label
@onready var spell_moon_btn: Button = _get_spell_btn("SpellItem_Moon")
@onready var spell_ember_btn: Button = _get_spell_btn("SpellItem_Ember")
@onready var spell_frost_btn: Button = _get_spell_btn("SpellItem_Frost")
@onready var spell_moon_lbl: Label = _get_spell_lbl("SpellItem_Moon")
@onready var spell_ember_lbl: Label = _get_spell_lbl("SpellItem_Ember")
@onready var spell_frost_lbl: Label = _get_spell_lbl("SpellItem_Frost")

# Quests Panel controls
@onready var quest_title: Label = get_node_or_null("MainVBox/ContentContainer/QuestsPanel/SidebarQuestTitle") as Label
@onready var quest_status: Label = get_node_or_null("MainVBox/ContentContainer/QuestsPanel/SidebarQuestStatus") as Label
@onready var quest_desc: Label = get_node_or_null("MainVBox/ContentContainer/QuestsPanel/SidebarQuestDesc") as Label
@onready var quest_progress: Label = get_node_or_null("MainVBox/ContentContainer/QuestsPanel/SidebarQuestProgress") as Label
@onready var open_journal_btn: Button = get_node_or_null("MainVBox/ContentContainer/QuestsPanel/OpenJournalBtn") as Button

# Inventory Panel controls
@onready var inv_gold: Label = get_node_or_null("MainVBox/ContentContainer/InventoryPanel/InvGoldLabel") as Label
@onready var open_inv_btn: Button = get_node_or_null("MainVBox/ContentContainer/InventoryPanel/OpenInvBtn") as Button

# Settings Panel controls
@onready var sidebar_zoom_out_btn: Button = find_child("SidebarZoomOutBtn", true, false) as Button
@onready var sidebar_zoom_label: Label = find_child("SidebarZoomLabel", true, false) as Label
@onready var sidebar_zoom_in_btn: Button = find_child("SidebarZoomInBtn", true, false) as Button
@onready var sidebar_zoom_reset_btn: Button = find_child("SidebarZoomResetBtn", true, false) as Button
@onready var sidebar_zoom_slider: HSlider = find_child("SidebarZoomSlider", true, false) as HSlider
@onready var sidebar_fullscreen_btn: Button = find_child("SidebarFullscreenBtn", true, false) as Button
@onready var sidebar_fps_btn: Button = find_child("SidebarFPSBtn", true, false) as Button
@onready var sidebar_save_btn: Button = find_child("SidebarSaveBtn", true, false) as Button
@onready var sidebar_quit_btn: Button = find_child("SidebarQuitBtn", true, false) as Button
@onready var sidebar_hybrid_controls_btn: Button = find_child("SidebarHybridControlsBtn", true, false) as Button
@onready var sidebar_day_night_btn: Button = find_child("SidebarDayNightBtn", true, false) as Button
@onready var guide_toggle_btn: Button = find_child("GuideToggleBtn", true, false) as Button
@onready var guide_content: Control = find_child("GuideContent", true, false) as Control

var current_tab: int = 0

static func should_show_touch_controls() -> bool:
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	return is_mobile or SettingsManager.hybrid_controls_enabled

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

func _ready() -> void:
	visible = false
	if close_btn:
		close_btn.pressed.connect(close)
	if tab_btn_stats:
		tab_btn_stats.pressed.connect(func(): switch_tab(0))
	if tab_btn_quests:
		tab_btn_quests.pressed.connect(func(): switch_tab(1))
	if tab_btn_inventory:
		tab_btn_inventory.pressed.connect(func(): switch_tab(2))
	if tab_btn_settings:
		tab_btn_settings.pressed.connect(func(): switch_tab(3))

	if open_sheet_btn:
		open_sheet_btn.pressed.connect(func(): character_sheet_requested.emit())
	if open_journal_btn:
		open_journal_btn.pressed.connect(func(): journal_requested.emit())
	if open_inv_btn:
		open_inv_btn.pressed.connect(func(): inventory_requested.emit())

	if spell_moon_btn:
		spell_moon_btn.pressed.connect(func(): spell_upgrade_requested.emit("moon_bolt"))
	if spell_ember_btn:
		spell_ember_btn.pressed.connect(func(): spell_upgrade_requested.emit("ember_bloom"))
	if spell_frost_btn:
		spell_frost_btn.pressed.connect(func(): spell_upgrade_requested.emit("frost_shard"))

	if sidebar_zoom_out_btn:
		sidebar_zoom_out_btn.pressed.connect(func(): zoom_out_requested.emit())
	if sidebar_zoom_in_btn:
		sidebar_zoom_in_btn.pressed.connect(func(): zoom_in_requested.emit())
	if sidebar_zoom_reset_btn:
		sidebar_zoom_reset_btn.pressed.connect(func(): zoom_reset_requested.emit())
	if sidebar_zoom_slider:
		sidebar_zoom_slider.value_changed.connect(func(v): zoom_slider_changed.emit(v))
	if sidebar_fullscreen_btn:
		sidebar_fullscreen_btn.pressed.connect(func(): fullscreen_toggled.emit())
	if sidebar_fps_btn:
		sidebar_fps_btn.pressed.connect(func(): fps_toggled.emit())
	if sidebar_hybrid_controls_btn:
		sidebar_hybrid_controls_btn.pressed.connect(func(): hybrid_controls_toggled.emit())
	if sidebar_day_night_btn:
		sidebar_day_night_btn.pressed.connect(func(): day_night_toggled.emit())
	if sidebar_save_btn:
		sidebar_save_btn.pressed.connect(func(): save_requested.emit())
	if sidebar_quit_btn:
		sidebar_quit_btn.pressed.connect(func(): quit_requested.emit())
	if guide_toggle_btn:
		guide_toggle_btn.pressed.connect(toggle_guide)

	switch_tab(0)

func open(tab_idx: int = -1) -> void:
	var was_open := visible
	visible = true
	if tab_idx >= 0:
		switch_tab(tab_idx)
	if not was_open:
		opened.emit()

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func is_open() -> bool:
	return visible

func toggle() -> void:
	if is_open():
		close()
	else:
		open()

func switch_tab(tab_idx: int) -> void:
	current_tab = tab_idx
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
	tab_changed.emit(tab_idx)

func toggle_guide() -> void:
	if guide_content:
		guide_content.visible = not guide_content.visible
		if guide_toggle_btn:
			guide_toggle_btn.text = "📖 Hướng Dẫn Điều Khiển & Phím Tắt ▼ (Thu gọn)" if guide_content.visible else "📖 Hướng Dẫn Điều Khiển & Phím Tắt ▶"

func update_hybrid_controls_btn(enabled: bool) -> void:
	if sidebar_hybrid_controls_btn:
		sidebar_hybrid_controls_btn.text = "BẬT" if enabled else "TẮT"

func refresh_content(player: Node, gold: int, q_title_str: String, q_progress_str: String) -> void:
	if inv_gold:
		inv_gold.text = "🪙 Vàng Sở Hữu: %d G" % gold

	if player:
		_refresh_player_stats(player)
		_refresh_equipment(player)
		_refresh_spells(player)

	if quest_title and not q_title_str.is_empty():
		quest_title.text = q_title_str
	if quest_progress and not q_progress_str.is_empty():
		quest_progress.text = q_progress_str

func _refresh_player_stats(player: Node) -> void:
	var r_name := "Nhân Loại (Human)"
	if player.race_id == "elf":
		r_name = "Tinh Linh (Elf)"
	elif player.race_id == "demon_beast":
		r_name = "Ma Thú (Demon Beast)"
	if race_label:
		race_label.text = "Chủng tộc: %s" % r_name

	var cur_lvl := 1
	var cur_exp := 0
	var target_exp := 60
	if player.progression_component:
		cur_lvl = player.progression_component.level
		cur_exp = player.progression_component.current_exp
		target_exp = player.progression_component.get_current_target_exp()
	if level_label:
		level_label.text = "Cấp độ: Lv %d — Tiến độ EXP" % cur_lvl
	if exp_bar:
		exp_bar.max_value = target_exp if target_exp > 0 else 100
		exp_bar.value = cur_exp
	if exp_label:
		var pct := (float(cur_exp) / float(target_exp) * 100.0) if target_exp > 0 else 100.0
		exp_label.text = "%d / %d EXP (%d%%)" % [cur_exp, target_exp, roundi(pct)]

	if player.health_component and stat_hp:
		stat_hp.text = "❤️ Sinh Lực (HP): %d / %d" % [roundi(player.health_component.current_health), roundi(player.health_component.max_health)]
	if player.health_component and stat_mp:
		stat_mp.text = "💧 Nội Khí (MP): %d / %d" % [roundi(player.health_component.current_mana), roundi(player.health_component.max_mana)]
	if player.get("player_stats_component"):
		var stats = player.get("player_stats_component")
		if stat_atk:
			stat_atk.text = "⚔️ Sức Tấn Công (ATK): %d" % roundi(stats.final_attack)
		if stat_regen:
			stat_regen.text = "🌀 Hồi Phục: %.1f MP/s" % stats.final_mana_regen
		if stat_speed:
			stat_speed.text = "⚡ Tốc Độ Di Chuyển: %.0f px/s" % stats.final_move_speed
		if stat_magic:
			stat_magic.text = "✨ Hệ Số Phép Thuật: %.1fx" % stats.final_magic_multiplier

func _refresh_equipment(player: Node) -> void:
	if player.get("equipment_component") == null:
		return
	var eq = player.get("equipment_component")
	if equip_weapon:
		var w_name := "Chưa trang bị"
		if not eq.equipped_weapon.is_empty() and ItemDatabase.has_item(eq.equipped_weapon):
			var w_def := ItemDatabase.get_item(eq.equipped_weapon)
			if w_def:
				w_name = w_def.display_name
		equip_weapon.text = "• Vũ khí: %s" % w_name
	if equip_acc:
		var a_name := "Chưa trang bị"
		if not eq.equipped_accessory.is_empty() and ItemDatabase.has_item(eq.equipped_accessory):
			var a_def := ItemDatabase.get_item(eq.equipped_accessory)
			if a_def:
				a_name = a_def.display_name
		equip_acc.text = "• Phụ kiện: %s" % a_name
	if equip_armor:
		equip_armor.text = "• Giáp: Áo Choàng Cơ Bản"

func _refresh_spells(player: Node) -> void:
	var sb: SpellbookComponent = player.get_node_or_null("SpellbookComponent") as SpellbookComponent
	var inv: InventoryComponent = player.get_node_or_null("InventoryComponent") as InventoryComponent
	if sb and inv:
		var shards: int = inv.get_item_count("mana_shard")
		if shard_label:
			shard_label.text = "💎 Tinh Thể Ma Lực hiện có: %d" % shards
		_update_spell_row("moon_bolt", spell_moon_lbl, spell_moon_btn, sb, shards)
		_update_spell_row("ember_bloom", spell_ember_lbl, spell_ember_btn, sb, shards)
		_update_spell_row("frost_shard", spell_frost_lbl, spell_frost_btn, sb, shards)

func _update_spell_row(spell_id: String, lbl: Label, btn: Button, sb: SpellbookComponent, shards: int) -> void:
	var spell := SpellDatabase.get_spell(spell_id)
	if spell == null or lbl == null or btn == null:
		return
	var lvl: int = sb.get_spell_level(spell_id)
	var dmg: float = sb.get_spell_damage(spell_id)
	var prefix := "✦" if spell_id == "moon_bolt" else ("🔥" if spell_id == "ember_bloom" else "❄")
	lbl.text = "%s %s (Lv %d): %.0f DMG" % [prefix, spell.display_name, lvl, dmg]

	var cost: int = spell.get_upgrade_cost(lvl)
	if cost <= 0 or lvl >= 3:
		btn.text = "TỐI ĐA (MAX)"
		btn.disabled = true
	else:
		btn.text = "Lên Lv %d (%d 💎)" % [lvl + 1, cost]
		btn.disabled = (shards < cost)

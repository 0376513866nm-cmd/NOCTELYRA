class_name SidebarController
extends RefCounted

const SettingsManager = preload("res://src/ui/settings_manager.gd")

## Bộ điều khiển Sidebar (Stats, Quests, Inventory, Settings) cho GameUI
## Phụ trách quản lý trạng thái hiển thị, chuyển đổi tab và cập nhật nội dung dữ liệu bên trong Sidebar.

var sidebar_panel: Control
var touch_controls: Control
var toggle_btn: Button
var close_btn: Button
var spell_hotbar: Control

# Tab Buttons
var tab_btn_stats: Button
var tab_btn_quests: Button
var tab_btn_inventory: Button
var tab_btn_settings: Button

# Content Panels
var panel_stats: Control
var panel_quests: Control
var panel_inventory: Control
var panel_settings: Control

# Display Labels inside Panels
var race_label: Label
var level_label: Label
var exp_bar: ProgressBar
var exp_label: Label
var stat_hp: Label
var stat_mp: Label
var stat_atk: Label
var stat_regen: Label
var stat_speed: Label
var stat_magic: Label

var equip_weapon: Label
var equip_armor: Label
var equip_acc: Label

var shard_label: Label
var spell_moon_btn: Button
var spell_ember_btn: Button
var spell_frost_btn: Button
var spell_moon_lbl: Label
var spell_ember_lbl: Label
var spell_frost_lbl: Label

var quest_title: Label
var quest_progress: Label
var inv_gold: Label

var current_tab: int = 0

static func should_show_touch_controls() -> bool:
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	return is_mobile or SettingsManager.hybrid_controls_enabled

func is_open() -> bool:
	return sidebar_panel != null and sidebar_panel.visible

func open(tab_idx: int = -1) -> void:
	if sidebar_panel:
		sidebar_panel.visible = true
		if tab_idx >= 0:
			switch_tab(tab_idx)
	if touch_controls:
		touch_controls.visible = false
	if toggle_btn:
		toggle_btn.visible = false
	if spell_hotbar:
		spell_hotbar.visible = false

func close() -> void:
	if sidebar_panel:
		sidebar_panel.visible = false
	var show_touch := should_show_touch_controls()
	if touch_controls:
		touch_controls.visible = show_touch
		if show_touch and touch_controls.has_method("_sync_current_spell_icon"):
			touch_controls._sync_current_spell_icon()
	if toggle_btn:
		toggle_btn.visible = not show_touch
	if spell_hotbar:
		spell_hotbar.visible = not show_touch

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

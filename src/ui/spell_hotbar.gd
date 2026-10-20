class_name SpellHotbar
extends Control

## Thanh hiển thị & chọn phép thuật (Spell Hotbar UI) cho NOCTELYRA (Milestone M5)
## Hiển thị 3 ô phép [1], [2], [3], cấp độ, MP tiêu hao, viền highlight và thời gian hồi độc lập.
## Hỗ trợ chọn phép bằng phím hoặc nhấp chuột, kèm nút/phím tắt [U] để nâng cấp.

signal spell_selected_from_ui(spell_id: String)
signal spell_upgrade_requested()

@onready var slot1: Control = $Slots/Slot1
@onready var slot2: Control = $Slots/Slot2
@onready var slot3: Control = $Slots/Slot3
@onready var upgrade_btn: Button = $UpgradeBtn

var _spellbook: SpellbookComponent
var _slot_nodes: Array[Control] = []
var _spell_ids: Array[String] = ["moon_bolt", "ember_bloom", "frost_shard"]

func _ready() -> void:
	_slot_nodes = [slot1, slot2, slot3]
	_setup_slots()
	if upgrade_btn:
		upgrade_btn.pressed.connect(_on_upgrade_btn_pressed)

func _process(_delta: float) -> void:
	var sb := _get_spellbook()
	if sb == null:
		return

	_update_hotbar_display(sb)

func _get_spellbook() -> SpellbookComponent:
	if _spellbook and is_instance_valid(_spellbook):
		return _spellbook
	var scene := get_tree().current_scene
	if scene:
		var p = scene.get_node_or_null("Player")
		if p:
			_spellbook = p.get_node_or_null("SpellbookComponent") as SpellbookComponent
			if _spellbook:
				_connect_spellbook()
	return _spellbook

func set_spellbook(sb: SpellbookComponent) -> void:
	_spellbook = sb
	_connect_spellbook()

func _connect_spellbook() -> void:
	if _spellbook:
		if not _spellbook.spell_selected.is_connected(_on_spell_selected):
			_spellbook.spell_selected.connect(_on_spell_selected)
		if not _spellbook.spell_upgraded.is_connected(_on_spell_upgraded):
			_spellbook.spell_upgraded.connect(_on_spell_upgraded)

func _setup_slots() -> void:
	for i in range(_slot_nodes.size()):
		var slot_node := _slot_nodes[i]
		if slot_node:
			var idx := i
			slot_node.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_on_slot_clicked(idx)
			)

func _on_slot_clicked(idx: int) -> void:
	var sb := _get_spellbook()
	if sb and idx >= 0 and idx < _spell_ids.size():
		var s_id := _spell_ids[idx]
		sb.select_spell(s_id)
		emit_signal("spell_selected_from_ui", s_id)

func _on_upgrade_btn_pressed() -> void:
	emit_signal("spell_upgrade_requested")
	var scene := get_tree().current_scene
	if scene:
		var p = scene.get_node_or_null("Player")
		if p and p.has_method("_upgrade_current_spell"):
			p._upgrade_current_spell()

func _on_spell_selected(_spell_id: String) -> void:
	var sb := _get_spellbook()
	if sb:
		_update_hotbar_display(sb)

func _on_spell_upgraded(_spell_id: String, _new_level: int) -> void:
	var sb := _get_spellbook()
	if sb:
		_update_hotbar_display(sb)

func _update_hotbar_display(sb: SpellbookComponent) -> void:
	for i in range(_spell_ids.size()):
		if i >= _slot_nodes.size():
			continue
		var s_id := _spell_ids[i]
		var slot_node := _slot_nodes[i]
		if slot_node == null:
			continue

		var spell := SpellDatabase.get_spell(s_id)
		if spell == null:
			continue

		var is_selected := (sb.selected_spell_id == s_id)
		var lvl := sb.get_spell_level(s_id)
		var cd := sb.get_cooldown(s_id)

		# 1. Viền sáng (Highlight)
		var highlight := slot_node.get_node_or_null("Highlight") as Control
		if highlight:
			highlight.visible = is_selected

		# 2. Cấp độ (Lv.1 - Lv.3)
		var level_label := slot_node.get_node_or_null("LevelLabel") as Label
		if level_label:
			level_label.text = "Lv.%d" % lvl

		# 3. Tiêu hao MP
		var mana_label := slot_node.get_node_or_null("ManaLabel") as Label
		if mana_label:
			mana_label.text = "%d MP" % int(spell.mana_cost)

		# 4. Cooldown Overlay & Số đếm
		var cd_overlay := slot_node.get_node_or_null("CooldownOverlay") as Control
		var cd_label := slot_node.get_node_or_null("CooldownOverlay/CooldownLabel") as Label
		if cd > 0.0:
			if cd_overlay:
				cd_overlay.visible = true
			if cd_label:
				cd_label.text = "%.1fs" % cd
		else:
			if cd_overlay:
				cd_overlay.visible = false

	# Cập nhật tooltip / text của nút nâng cấp
	if upgrade_btn:
		var cur_spell := sb.get_selected_spell()
		if cur_spell:
			var cur_lvl := sb.get_spell_level(cur_spell.spell_id)
			if cur_lvl >= 3:
				upgrade_btn.text = "[U] Max Lv.3"
				upgrade_btn.disabled = true
			else:
				var cost := cur_spell.get_upgrade_cost(cur_lvl)
				upgrade_btn.text = "[U] Nâng cấp (%d Shard)" % cost
				upgrade_btn.disabled = false

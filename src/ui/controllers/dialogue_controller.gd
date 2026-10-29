class_name DialogueController
extends RefCounted

var _box: Control
var _speaker_label: Label
var _text_label: Label
var _hint_label: Label
var _lines: Array[String] = []
var _line_index := 0
var _pending_action := "none"
var _cooldown := 0.0

func setup(box: Control, speaker: Label, text: Label, hint: Label) -> void:
	_box = box
	_speaker_label = speaker
	_text_label = text
	_hint_label = hint

func tick(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)

func show_dialogue(speaker: String, lines: Array[String], action: String) -> void:
	_lines.assign(lines)
	_line_index = 0
	_pending_action = action
	if _speaker_label:
		_speaker_label.text = speaker
	_display_current_line()
	if _box:
		_box.visible = true

func advance() -> String:
	_line_index += 1
	if _line_index < _lines.size():
		_display_current_line()
		return ""
	return close()

func close() -> String:
	if _box:
		_box.visible = false
	_cooldown = 0.25
	var action := _pending_action
	_pending_action = "none"
	_lines.clear()
	_line_index = 0
	return action

func is_open() -> bool:
	return _box != null and _box.visible

func is_cooling_down() -> bool:
	return _cooldown > 0.0

func _display_current_line() -> void:
	if _line_index < 0 or _line_index >= _lines.size():
		return
	if _text_label:
		_text_label.text = _lines[_line_index]
	if _hint_label:
		var mobile := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
		var is_last := _line_index == _lines.size() - 1
		if mobile:
			_hint_label.text = "[Chạm / E để đóng]" if is_last else "[Chạm / E để tiếp tục]"
		else:
			_hint_label.text = "[E để đóng]" if is_last else "[E để tiếp tục]"

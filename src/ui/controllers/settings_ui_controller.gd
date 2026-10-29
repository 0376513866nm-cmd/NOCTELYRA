class_name SettingsUIController
extends RefCounted

const SettingsManager = preload("res://src/ui/settings_manager.gd")

var pause_panel: Panel
var settings_panel: Panel
var zoom_label: Label
var zoom_slider: HSlider
var fullscreen_btn: Button

var sidebar_zoom_label: Label
var sidebar_zoom_slider: HSlider
var sidebar_fullscreen_btn: Button

func setup(
	p_pause_panel: Panel,
	p_settings_panel: Panel,
	p_zoom_lbl: Label,
	p_zoom_sld: HSlider,
	p_fs_btn: Button,
	p_sb_zoom_lbl: Label,
	p_sb_zoom_sld: HSlider,
	p_sb_fs_btn: Button
) -> void:
	pause_panel = p_pause_panel
	settings_panel = p_settings_panel
	zoom_label = p_zoom_lbl
	zoom_slider = p_zoom_sld
	fullscreen_btn = p_fs_btn
	sidebar_zoom_label = p_sb_zoom_lbl
	sidebar_zoom_slider = p_sb_zoom_sld
	sidebar_fullscreen_btn = p_sb_fs_btn

func open_settings() -> void:
	if pause_panel:
		pause_panel.visible = false
	if settings_panel:
		settings_panel.visible = true
	update_ui()

func close_settings() -> void:
	if settings_panel:
		settings_panel.visible = false
	if pause_panel:
		pause_panel.visible = true
	SettingsManager.save_settings()

func is_settings_open() -> bool:
	return settings_panel != null and settings_panel.visible

func zoom_in(step: float = 0.1) -> void:
	SettingsManager.zoom_in(step)
	update_ui()

func zoom_out(step: float = 0.1) -> void:
	SettingsManager.zoom_out(step)
	update_ui()

func reset_zoom() -> void:
	SettingsManager.set_zoom(1.0)
	update_ui()

func set_zoom_slider(val: float) -> void:
	SettingsManager.set_zoom(val)
	update_ui()

func toggle_fullscreen() -> void:
	SettingsManager.toggle_fullscreen()
	update_ui()

func update_ui() -> void:
	var cur_z: float = SettingsManager.camera_zoom
	var zoom_pct_str := "%d%% (%.1fx)" % [roundi(cur_z * 100.0), cur_z]

	if zoom_label:
		zoom_label.text = zoom_pct_str
	if zoom_slider and not is_equal_approx(zoom_slider.value, cur_z):
		zoom_slider.set_value_no_signal(cur_z)

	if sidebar_zoom_label:
		sidebar_zoom_label.text = zoom_pct_str
	if sidebar_zoom_slider and not is_equal_approx(sidebar_zoom_slider.value, cur_z):
		sidebar_zoom_slider.set_value_no_signal(cur_z)

	var fs_text := "Toàn Màn Hình: BẬT" if SettingsManager.is_fullscreen else "Toàn Màn Hình: TẮT"
	if fullscreen_btn:
		fullscreen_btn.text = fs_text
	if sidebar_fullscreen_btn:
		sidebar_fullscreen_btn.text = fs_text

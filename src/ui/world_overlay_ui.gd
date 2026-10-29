class_name WorldOverlayUI
extends Control

@onready var zone_label: Label = $ZoneLabel
@onready var notification_label: Label = $NotificationLabel
@onready var zone_banner: Control = $ZoneBanner
@onready var zone_banner_title: Label = $ZoneBanner/Panel/TitleLabel
@onready var zone_banner_subtitle: Label = $ZoneBanner/Panel/SubtitleLabel

var _notif_timer: float = 0.0
var _zone_banner_timer: float = 0.0

func _ready() -> void:
	if zone_banner:
		zone_banner.visible = false
	if notification_label:
		notification_label.visible = false

func _process(delta: float) -> void:
	if _notif_timer > 0.0:
		_notif_timer -= delta
		if _notif_timer <= 0.0 and notification_label:
			notification_label.visible = false

	if _zone_banner_timer > 0.0:
		_zone_banner_timer -= delta
		if _zone_banner_timer <= 0.0 and zone_banner:
			zone_banner.visible = false

func update_zone(zone_id: String) -> void:
	if zone_label:
		zone_label.text = "📍 %s" % ZoneDefinition.get_zone_display_name(zone_id)

func show_notification(msg: String, duration: float = 3.5) -> void:
	if notification_label:
		notification_label.text = msg
		notification_label.visible = true
		_notif_timer = duration

func show_zone_banner(zone_name: String, subtitle: String = "", duration: float = 2.0) -> void:
	if zone_banner:
		if zone_banner_title:
			zone_banner_title.text = zone_name
		if zone_banner_subtitle:
			zone_banner_subtitle.text = subtitle
		zone_banner.visible = true
		_zone_banner_timer = duration

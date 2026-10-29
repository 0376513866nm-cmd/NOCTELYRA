class_name PetMoonBird
extends Node2D

## Thú cưng: Chim Trăng - "Lumi" (Moon Bird / Star Owlet)
## Sinh vật lai giữa cú tuyết nhỏ và bướm đêm phát quang, đậu trên hiên nhà ngắm nhìn trăng sao.
## Sẵn sàng kiến trúc bộ nhớ & tính cách cho AI LLM sau này.

signal bird_interacted(dialogue: String)

enum State {
	PERCH,
	FLIGHT_LOOP
}

@export var pet_name: String = "Lumi"
@export var perch_pos: Vector2 = Vector2(280.0, 485.0)

var personality: String = "Điềm tĩnh, quan sát nhiều, nói ít nhưng biết nhiều chuyện cổ xưa, thông thái"
var mood: String = "Thanh tịnh & tĩnh lặng"
var memory_log: Array[String] = [
	"Đã quen với việc nhìn ngắm những vì sao từ mái hiên",
	"Lắng nghe tiếng chuông gió pha lê mỗi khi gió thổi qua thung lũng"
]

@onready var visual_root: Node2D = $VisualRoot
@onready var speech_bubble: Control = $SpeechBubble
@onready var speech_label: Label = $SpeechBubble/Panel/Label
@onready var prompt_label: Label = $PromptLabel
@onready var wings: Node2D = $VisualRoot/Wings
@onready var ground_shadow: Polygon2D = get_node_or_null("GroundShadow")

var current_state: State = State.PERCH
var _state_timer: float = 12.0
var _speech_timer: float = 0.0
var _anim_time: float = 0.0
var _flight_progress: float = 0.0
var _flight_duration: float = 5.0

var _dialogues: Array[String] = [
	"Lumi chớp đôi mắt ngọc hổ phách to tròn, khẽ nghiêng đầu ngắm nhìn bạn. ✨",
	"Lumi hướng mắt về phía rừng sâu: 'Gió đêm nay mang theo hương hoa dạ nguyệt cổ xưa...' 🌙",
	"Lumi khẽ xòe đôi cánh phát quang lấp lánh như vệt bụi sao trời: 'Hoo-kuru~' 🌟",
	"Lumi lắng tai nghe tiếng chuông gió: 'Khi tâm hồn an tĩnh, con đường phía trước sẽ tự sáng soi.' 🎐"
]

func _ready() -> void:
	add_to_group("pets")
	add_to_group(GameGroups.INTERACTABLES)
	position = perch_pos
	if speech_bubble:
		speech_bubble.visible = false
	if prompt_label:
		prompt_label.visible = false

func _process(delta: float) -> void:
	_anim_time += delta * 3.0

	if _speech_timer > 0.0:
		_speech_timer -= delta
		if _speech_timer <= 0.0 and speech_bubble:
			speech_bubble.visible = false

	var player = _get_player()
	var dist := 9999.0
	if player:
		dist = global_position.distance_to(player.global_position)

	if prompt_label:
		prompt_label.visible = (dist <= 95.0 and _speech_timer <= 0.0 and current_state == State.PERCH)

	if ground_shadow:
		var floor_offset_y: float = 630.0 - global_position.y
		ground_shadow.position.y = floor_offset_y
		var factor: float = clampf(1.0 - (floor_offset_y / 300.0), 0.35, 0.95)
		ground_shadow.scale = Vector2(factor, factor * 0.7)
		ground_shadow.modulate.a = 0.35 * factor

	_state_timer -= delta

	match current_state:
		State.PERCH:
			# Nghiêng đầu nhẹ và nhấp nhô
			if visual_root:
				visual_root.position.y = sin(_anim_time * 1.5) * 1.5
				visual_root.rotation = sin(_anim_time * 0.8) * 0.08
			if _state_timer <= 0.0:
				_start_flight()

		State.FLIGHT_LOOP:
			_flight_progress += delta / _flight_duration
			# Vỗ cánh nhanh khi bay
			if wings:
				wings.scale.y = sin(_anim_time * 12.0)
			# Bay theo quỹ đạo hình oval / lemniscate trên không quanh hiên nhà
			var angle: float = _flight_progress * TAU
			var offset_x: float = sin(angle) * 75.0
			var offset_y: float = -absf(cos(angle)) * 45.0 - 15.0
			position = perch_pos + Vector2(offset_x, offset_y)

			if _flight_progress >= 1.0:
				position = perch_pos
				if wings:
					wings.scale.y = 1.0
				_change_state(State.PERCH)

func _start_flight() -> void:
	current_state = State.FLIGHT_LOOP
	_flight_progress = 0.0
	_flight_duration = randf_range(4.5, 6.0)

func _change_state(new_st: State) -> void:
	current_state = new_st
	match new_st:
		State.PERCH:
			_state_timer = randf_range(15.0, 30.0)

func is_interactable() -> bool:
	var player = _get_player()
	return player != null and global_position.distance_to(player.global_position) <= 95.0 and current_state == State.PERCH

func trigger_interaction() -> void:
	var msg = _dialogues.pick_random()
	show_speech(msg)
	emit_signal("bird_interacted", msg)

func show_speech(text: String, duration: float = 4.5) -> void:
	if speech_bubble and speech_label:
		speech_label.text = text
		speech_bubble.visible = true
		_speech_timer = duration

func _unhandled_input(event: InputEvent) -> void:
	if is_interactable() and event.is_action_pressed("interact"):
		trigger_interaction()
		if get_viewport():
			get_viewport().set_input_as_handled()

func _get_player() -> Player:
	var tree := get_tree()
	if not tree:
		return null
	var players = tree.get_nodes_in_group(GameGroups.PLAYERS)
	if players.size() > 0:
		return players[0] as Player
	return null

class_name PetMoonBat
extends Node2D

## Thú cưng: Dơi Trăng - "Kiki" (Moon Bat / Nocturnal Spirit Bat)
## Chú dơi huyền bí đáng yêu treo ngược dưới mái hiên nhà Đèn Nguyệt, ngắm nhìn trăng sao.
## Sẵn sàng kiến trúc bộ nhớ & tính cách cho AI LLM sau này.

signal bat_interacted(dialogue: String)
signal bird_interacted(dialogue: String) # Alias tương thích ngược cho test suite

enum State {
	PERCH,        # Treo ngược dưới mái hiên, cuộn cánh ấm áp
	FLIGHT_LOOP   # Mở rộng đôi cánh màng lượn vòng quanh ống khói & vườn cây
}

@export var pet_name: String = "Kiki"
@export var perch_pos: Vector2 = Vector2(285.0, 485.0)

var personality: String = "Nghịch ngợm, tò mò, thích treo ngược ngắm sao trời, lanh lợi, trung thành và giàu tình cảm"
var mood: String = "Háo hức & thư thái"
var memory_log: Array[String] = [
	"Thích treo ngược dưới mái hiên gỗ để đón những ngọn gió đêm",
	"Lắng nghe tiếng chuông gió pha lê reo và quan sát người lữ khách",
	"Đã từng thấy những luồng ma pháp tím le lói từ sâu trong rừng Noctis"
]

@onready var visual_root: Node2D = $VisualRoot
@onready var speech_bubble: Control = $SpeechBubble
@onready var speech_label: Label = $SpeechBubble/Panel/Label
@onready var prompt_label: Label = $PromptLabel
@onready var wings_spread: Node2D = $VisualRoot/WingsSpread
@onready var wings_folded: Node2D = $VisualRoot/WingsFolded
@onready var ears_node: Node2D = $VisualRoot/Ears
@onready var ground_shadow: Polygon2D = get_node_or_null("GroundShadow")

var current_state: State = State.PERCH
var _state_timer: float = 14.0
var _speech_timer: float = 0.0
var _anim_time: float = 0.0
var _flight_progress: float = 0.0
var _flight_duration: float = 5.2

var _dialogues: Array[String] = [
	"Kiki vẫy vẫy đôi tai to tròn, phát ra tiếng chít chít đáng yêu: 'Squeak-squeak! Đêm nay nhiều sao thật đấy!' 🦇✨",
	"Kiki hé đôi cánh màng nhung mềm mại: 'Em thích treo ngược ngắm nhìn thế giới, mọi thứ trông thú vị hơn nhiều!' 🌙",
	"Kiki chớp đôi mắt hổ phách lấp lánh: 'Phía rừng sâu có nhiều hoa dạ nguyệt lắm, nhưng cẩn thận lũ quái vật nhé!' 🐾",
	"Kiki dụi đầu vào ngón tay bạn ấm áp: 'Chitter~ Về nhà Đèn Nguyệt thật là bình yên!' 🏡",
	"Kiki phe phẩy đôi tai: 'Em nghe thấy tiếng suối reo từ thung lũng xa xăm... Một ngày thật tuyệt!' 🎐"
]

func _ready() -> void:
	add_to_group("pets")
	add_to_group(GameGroups.INTERACTABLES)
	position = perch_pos
	if speech_bubble:
		speech_bubble.visible = false
	if prompt_label:
		prompt_label.visible = false
	_update_pose_visuals()

func _process(delta: float) -> void:
	_anim_time += delta * 3.2

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

	# Cập nhật bóng đổ chiếu xuống mặt đất bên dưới
	if ground_shadow:
		var floor_offset_y: float = 630.0 - global_position.y
		ground_shadow.position.y = floor_offset_y
		var factor: float = clampf(1.0 - (floor_offset_y / 320.0), 0.3, 0.9)
		ground_shadow.scale = Vector2(factor, factor * 0.7)
		ground_shadow.modulate.a = 0.35 * factor

	_state_timer -= delta

	match current_state:
		State.PERCH:
			# Đung đưa nhẹ khi treo ngược và nhúc nhích tai
			if visual_root:
				visual_root.position.y = sin(_anim_time * 1.8) * 1.5
				visual_root.rotation = sin(_anim_time * 1.2) * 0.06
			if ears_node:
				ears_node.rotation = sin(_anim_time * 4.0) * 0.08
			if _state_timer <= 0.0:
				_start_flight()

		State.FLIGHT_LOOP:
			_flight_progress += delta / _flight_duration
			# Vỗ cánh màng nhịp nhàng khi bay
			if wings_spread:
				wings_spread.scale.y = sin(_anim_time * 14.0)
			# Bay theo quỹ đạo uốn lượn hình elip mềm mại quanh mái nhà
			var angle: float = _flight_progress * TAU
			var offset_x: float = sin(angle) * 85.0
			var offset_y: float = -absf(cos(angle)) * 50.0 - 20.0
			position = perch_pos + Vector2(offset_x, offset_y)
			# Nghiêng người theo hướng bay
			if visual_root:
				visual_root.rotation = cos(angle) * 0.25

			if _flight_progress >= 1.0:
				position = perch_pos
				if visual_root:
					visual_root.rotation = 0.0
				_change_state(State.PERCH)

func _update_pose_visuals() -> void:
	if current_state == State.PERCH:
		# Treo ngược: cuộn cánh ấm áp quanh thân
		if wings_folded:
			wings_folded.visible = true
		if wings_spread:
			wings_spread.visible = false
	else:
		# Đang bay: dang rộng đôi cánh màng
		if wings_folded:
			wings_folded.visible = false
		if wings_spread:
			wings_spread.visible = true

func _start_flight() -> void:
	current_state = State.FLIGHT_LOOP
	_flight_progress = 0.0
	_flight_duration = randf_range(4.5, 6.2)
	_update_pose_visuals()

func _change_state(new_st: State) -> void:
	current_state = new_st
	_update_pose_visuals()
	match new_st:
		State.PERCH:
			_state_timer = randf_range(16.0, 32.0)

func is_interactable() -> bool:
	var player = _get_player()
	return player != null and global_position.distance_to(player.global_position) <= 95.0 and current_state == State.PERCH

func trigger_interaction() -> void:
	var msg = _dialogues.pick_random()
	show_speech(msg)
	emit_signal("bat_interacted", msg)
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

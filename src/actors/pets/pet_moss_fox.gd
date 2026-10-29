class_name PetMossFox
extends CharacterBody2D

## Thú cưng: Cáo Rêu - "Mầm" (Moss Fox)
## Chú cáo nhỏ lông trắng tuyết, lưng phủ rêu xanh & hoa phát quang, quấn quýt bên bếp lửa.
## Sẵn sàng kiến trúc bộ nhớ & tính cách để tích hợp AI LLM sau này.

signal pet_interacted(dialogue: String)

enum State {
	SLEEP,
	IDLE,
	WANDER,
	GREET_PLAYER
}

@export var pet_name: String = "Mầm"
@export var speed: float = 45.0
@export var home_x: float = 430.0

# Các thuộc tính chuẩn bị cho AI LLM
var personality: String = "Tò mò, thích được vuốt ve, ham ăn, trung thành tuyệt đối"
var affection_level: int = 100
var hunger_level: float = 0.2 # 0.0: No, 1.0: Đói
var mood: String = "Bình yên & ấm áp"
var memory_log: Array[String] = [
	"Đã quen với mùi hương trà thảo mộc của Eiran",
	"Rất thích cuộn tròn bên than hồng của Bếp Lửa Trại",
	"Luôn chạy ra đón khi thấy bạn về nhà"
]

@onready var visual_root: Node2D = $ArtRoot
@onready var speech_bubble: Control = $SpeechBubble
@onready var speech_label: Label = $SpeechBubble/Panel/Label
@onready var prompt_label: Label = $PromptLabel
@onready var tail: Polygon2D = $VisualRoot/Tail

var current_state: State = State.SLEEP
var _state_timer: float = 6.0
var _speech_timer: float = 0.0
var _anim_time: float = 0.0
var _target_x: float = 430.0

var _dialogues: Array[String] = [
	"Mầm khẽ cọ đầu vào chân bạn, vẫy chiếc đuôi rêu phát sáng ấm áp~ 🐾",
	"Mầm vươn vai ngáp một cái thật dài, đôi mắt long lanh ngước nhìn bạn đầy tin cậy. ✨",
	"Mầm hếch chiếc mũi ươn ướt, tò mò ngửi hương thảo mộc trên áo bạn rồi kêu 'Yip!'. 🌿",
	"Mầm lăn một vòng trên cỏ, ngoe nguẩy chiếc đuôi đốm sao như muốn được vuốt ve. 💖"
]

func _ready() -> void:
	add_to_group("pets")
	add_to_group(GameGroups.INTERACTABLES)
	if speech_bubble:
		speech_bubble.visible = false
	if prompt_label:
		prompt_label.visible = false
	_target_x = global_position.x

func _process(delta: float) -> void:
	_anim_time += delta * 3.5

	if _speech_timer > 0.0:
		_speech_timer -= delta
		if _speech_timer <= 0.0 and speech_bubble:
			speech_bubble.visible = false

	# Kiểm tra người chơi ở gần
	var player := _get_player()
	var dist_to_player := 9999.0
	if player:
		dist_to_player = global_position.distance_to(player.global_position)

	if prompt_label:
		prompt_label.visible = (dist_to_player <= 75.0 and _speech_timer <= 0.0)

	# FSM (Finite State Machine)
	_state_timer -= delta
	match current_state:
		State.SLEEP:
			# Hiệu ứng thở nhẹ khi ngủ
			if visual_root:
				visual_root.scale.y = 1.0 + sin(_anim_time * 0.8) * 0.06
			if tail:
				tail.rotation = sin(_anim_time * 0.5) * 0.1
			if dist_to_player < 85.0:
				_change_state(State.GREET_PLAYER)
			elif _state_timer <= 0.0:
				_change_state(State.IDLE)

		State.IDLE:
			if visual_root:
				visual_root.scale.y = 1.0
			if tail:
				tail.rotation = sin(_anim_time * 2.5) * 0.25
			if dist_to_player < 85.0:
				_change_state(State.GREET_PLAYER)
			elif _state_timer <= 0.0:
				if randf() < 0.4:
					_target_x = home_x + randf_range(-60.0, 60.0)
					_change_state(State.WANDER)
				else:
					_change_state(State.SLEEP)

		State.WANDER:
			var diff := _target_x - global_position.x
			if abs(diff) > 5.0:
				velocity.x = sign(diff) * speed
				if visual_root:
					visual_root.scale.x = 1.0 if diff > 0 else -1.0
			else:
				velocity.x = 0.0
				_change_state(State.IDLE)
			move_and_slide()

		State.GREET_PLAYER:
			if player:
				var dir := player.global_position.x - global_position.x
				if visual_root:
					visual_root.scale.x = 1.0 if dir > 0 else -1.0
				# Vẫy đuôi nhanh mừng rỡ
				if tail:
					tail.rotation = sin(_anim_time * 6.0) * 0.45
			if dist_to_player > 130.0 or _state_timer <= 0.0:
				_change_state(State.IDLE)

func _change_state(new_st: State) -> void:
	current_state = new_st
	match new_st:
		State.SLEEP:
			_state_timer = randf_range(8.0, 16.0)
		State.IDLE:
			_state_timer = randf_range(3.0, 6.0)
		State.WANDER:
			_state_timer = randf_range(2.0, 4.0)
		State.GREET_PLAYER:
			_state_timer = 5.0

func is_interactable() -> bool:
	var player = _get_player()
	return player != null and global_position.distance_to(player.global_position) <= 75.0

func trigger_interaction() -> void:
	var msg = _dialogues.pick_random()
	show_speech(msg)
	emit_signal("pet_interacted", msg)
	_change_state(State.GREET_PLAYER)

func show_speech(text: String, duration: float = 4.0) -> void:
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

class_name DistantBirds
extends Node2D

## Đàn chim đêm viễn xứ (Distant Night Birds / Cranes) chao liệng qua bầu trời Noctis
## Xuất hiện từng đợt ngẫu nhiên (25-45s), bay lượn từ tốn tạo cảm giác thế giới bao la vô tận.

@export var bird_count: int = 5
@export var speed: float = 85.0
@export var spawn_interval_min: float = 25.0
@export var spawn_interval_max: float = 45.0
@export var flight_y_min: float = 80.0
@export var flight_y_max: float = 240.0

var _is_flying: bool = false
var _cooldown_timer: float = 4.0 # Khởi đầu xuất hiện sớm sau 4s
var _flock_progress: float = 0.0
var _flock_duration: float = 32.0
var _flock_start_x: float = -400.0
var _flock_end_x: float = 7200.0
var _base_y: float = 140.0
var _wing_phase: float = 0.0

var _bird_offsets: Array[Vector2] = [
	Vector2(0, 0),        # Chim đầu đàn
	Vector2(-32, 16),     # Cánh trái 1
	Vector2(-64, 32),     # Cánh trái 2
	Vector2(-28, -14),    # Cánh phải 1
	Vector2(-58, -28),    # Cánh phải 2
	Vector2(-90, 48),     # Cánh trái 3
	Vector2(-86, -42)     # Cánh phải 3
]

func _ready() -> void:
	z_index = -6

func _process(delta: float) -> void:
	_wing_phase += delta * 4.2

	if not _is_flying:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_start_flight()
	else:
		_flock_progress += delta / _flock_duration
		if _flock_progress >= 1.0:
			_is_flying = false
			_cooldown_timer = randf_range(spawn_interval_min, spawn_interval_max)
			queue_redraw()
		else:
			queue_redraw()

func _start_flight() -> void:
	_is_flying = true
	_flock_progress = 0.0
	_base_y = randf_range(flight_y_min, flight_y_max)
	_flock_duration = (_flock_end_x - _flock_start_x) / speed

func _draw() -> void:
	if not _is_flying:
		return

	var cur_x := lerpf(_flock_start_x, _flock_end_x, _flock_progress)
	var cur_y := _base_y + sin(_flock_progress * TAU * 1.6) * 30.0
	var head_pos := Vector2(cur_x, cur_y)

	# Màu bóng đen tím hòa vào bầu trời đêm
	var bird_col := Color(0.18, 0.16, 0.32, 0.75)

	var active_count: int = mini(bird_count, _bird_offsets.size())
	for i in range(active_count):
		var b_pos := head_pos + _bird_offsets[i]
		var wing_span := 16.0
		var flap := sin(_wing_phase + i * 0.45) * 6.0

		var left_tip := b_pos + Vector2(-wing_span * 0.55, flap)
		var center := b_pos + Vector2(0, 0)
		var right_tip := b_pos + Vector2(wing_span * 0.55, flap)
		var mid_left := b_pos + Vector2(-wing_span * 0.22, flap * 0.35)
		var mid_right := b_pos + Vector2(wing_span * 0.22, flap * 0.35)

		var pts := PackedVector2Array([left_tip, mid_left, center, mid_right, right_tip])
		draw_polyline(pts, bird_col, 2.0, true)

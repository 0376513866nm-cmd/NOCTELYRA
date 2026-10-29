class_name TouchScrollContainer
extends ScrollContainer

## Hỗ trợ cuộn cảm ứng (Touch Drag & Flick/Inertia Scrolling) mượt mà cho mobile/desktop
## Giải quyết triệt để vấn đề ScrollContainer của Godot mặc định không hỗ trợ vuốt cảm ứng trên Android.

@export var drag_deadzone: float = 10.0
@export var inertia_friction: float = 2600.0

var _touch_id: int = -1
var _start_pos: Vector2 = Vector2.ZERO
var _last_pos: Vector2 = Vector2.ZERO
var _is_scrolling: bool = false
var _velocity_y: float = 0.0
var _last_time: float = 0.0

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		_velocity_y = 0.0
		_is_scrolling = false
		_touch_id = -1
		return

	# Quán tính cuộn khi nhấc tay (Inertia / Fling momentum)
	if _touch_id == -1 and abs(_velocity_y) > 15.0:
		var prev_scroll: int = scroll_vertical
		scroll_vertical -= int(_velocity_y * delta)
		if scroll_vertical == prev_scroll:
			_velocity_y = 0.0
		else:
			_velocity_y = move_toward(_velocity_y, 0.0, inertia_friction * delta)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	# --- CẢM ỨNG MÀN HÌNH (Touch Screen on Mobile) ---
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			var global_rect: Rect2 = get_global_rect()
			if global_rect.has_point(st.position):
				_touch_id = st.index
				_start_pos = st.position
				_last_pos = st.position
				_is_scrolling = false
				_velocity_y = 0.0
				_last_time = float(Time.get_ticks_msec()) / 1000.0
		elif st.index == _touch_id:
			if _is_scrolling:
				get_viewport().set_input_as_handled()
			_touch_id = -1
			_is_scrolling = false

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		if sd.index == _touch_id:
			var dy_total: float = sd.position.y - _start_pos.y
			if not _is_scrolling and abs(dy_total) > drag_deadzone:
				_is_scrolling = true

			if _is_scrolling:
				var now: float = float(Time.get_ticks_msec()) / 1000.0
				var dt: float = max(0.001, now - _last_time)
				_velocity_y = sd.relative.y / dt
				_velocity_y = clampf(_velocity_y, -3500.0, 3500.0)
				_last_time = now

				scroll_vertical -= int(sd.relative.y)
				get_viewport().set_input_as_handled()

	# --- KÉO CHUỘT / GIẢ LẬP CẢM ỨNG (Mouse Drag on PC / Emulated) ---
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var global_rect: Rect2 = get_global_rect()
				if global_rect.has_point(mb.position):
					_touch_id = 9999
					_start_pos = mb.position
					_last_pos = mb.position
					_is_scrolling = false
					_velocity_y = 0.0
					_last_time = float(Time.get_ticks_msec()) / 1000.0
			elif _touch_id == 9999:
				if _is_scrolling:
					get_viewport().set_input_as_handled()
				_touch_id = -1
				_is_scrolling = false

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _touch_id == 9999:
			var dy_total: float = mm.position.y - _start_pos.y
			if not _is_scrolling and abs(dy_total) > drag_deadzone:
				_is_scrolling = true

			if _is_scrolling:
				var now: float = float(Time.get_ticks_msec()) / 1000.0
				var dt: float = max(0.001, now - _last_time)
				_velocity_y = mm.relative.y / dt
				_velocity_y = clampf(_velocity_y, -3500.0, 3500.0)
				_last_time = now

				scroll_vertical -= int(mm.relative.y)
				get_viewport().set_input_as_handled()

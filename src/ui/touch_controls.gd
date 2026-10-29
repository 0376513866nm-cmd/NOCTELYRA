class_name TouchControls
extends Control

## Cụm điều khiển cảm ứng tối ưu cho Mobile phong cách Liên Quân Mobile (Arena of Valor)
## - Cần gạt Analog Joystick: Đế cố định góc dưới bên trái, đàn hồi tức thì về tâm, không bay lung tung, không dây nối
## - Cụm nút hành động chuẩn Liên Quân: Đánh thường lớn nhất ở tâm, Nhảy/Lướt/Phép vệ tinh xung quanh
## - Đổi loại phép: Giữ nút Phép >= 0.2s bung Radial Menu 3 bóng phép (Băng, Lửa, Trăng)
## - Nút Nói chuyện / Tương tác [E]: Nằm ngay dưới nút MENU, tự động ẩn khi ở xa, chạm là mở thoại chuẩn xác
## - Tỉ lệ 18:9 (1440x720) căn chuẩn an toàn, camera nốt ruồi nằm trọn trong viền đen mép máy, không che màn game

signal menu_pressed()

class TouchButton:
	var id: String = ""
	var center: Vector2 = Vector2.ZERO
	var radius: float = 38.0
	var action: String = ""
	var label: String = ""
	var icon: String = ""
	var color_bg: Color = Color(0.1, 0.12, 0.18, 0.75)
	var color_border: Color = Color(0.4, 0.75, 1.0, 0.85)
	var color_pressed: Color = Color(0.3, 0.85, 1.0, 0.95)
	var touch_id: int = -1
	var is_pressed: bool = false
	var scale_anim: float = 1.0

class SpellOption:
	var spell_id: String = ""
	var label: String = ""
	var icon: String = ""
	var color: Color = Color.WHITE
	var angle: float = 0.0
	var center: Vector2 = Vector2.ZERO
	var radius: float = 28.0
	var is_hovered: bool = false

# --- JOYSTICK CỐ ĐỊNH GÓC DƯỚI BÊN TRÁI ---
var joystick_center: Vector2 = Vector2(145, 575)
var joystick_base_pos: Vector2 = Vector2(145, 575)
var joystick_base_radius: float = 65.0
var joystick_knob_radius: float = 28.0
var joystick_deadzone: float = 12.0
var _joystick_touch_id: int = -1
var _joystick_current_pos: Vector2 = Vector2(145, 575)

# --- ACTION BUTTONS ---
var buttons: Array[TouchButton] = []
var btn_attack: TouchButton
var btn_jump: TouchButton
var btn_cast: TouchButton
var btn_dash: TouchButton
var btn_menu: TouchButton
var btn_interact: TouchButton

# --- SPELL RADIAL SELECTOR ---
var spell_radial_options: Array[SpellOption] = []
var _is_spell_menu_open: bool = false
var _cast_touch_id: int = -1
var _cast_hold_timer: float = 0.0
var _cast_touch_pos: Vector2 = Vector2.ZERO
var _radial_anim_progress: float = 0.0
var _hovered_spell_id: String = ""

# Trạng thái ẩn/hiện nút tương tác E
var is_interact_visible: bool = false
var _connected_spellbook: SpellbookComponent = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_layout()
	_setup_spell_radial_options()
	resized.connect(_on_viewport_resized)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_sync_current_spell_icon()
	visibility_changed.connect(_on_controls_visibility_changed)

func _on_controls_visibility_changed() -> void:
	if not is_visible_in_tree():
		release_all_actions()

func release_all_actions() -> void:
	_reset_joystick()
	_cast_touch_id = -1
	_cast_hold_timer = 0.0
	_is_spell_menu_open = false
	for button in buttons:
		if button.is_pressed and not button.action.is_empty() and button.id not in ["menu", "interact"]:
			Input.action_release(button.action)
		button.touch_id = -1
		button.is_pressed = false
		button.scale_anim = 1.0
	queue_redraw()

func _exit_tree() -> void:
	release_all_actions()

func _on_viewport_resized() -> void:
	_setup_layout()
	_setup_spell_radial_options()
	queue_redraw()

func _setup_layout() -> void:
	buttons.clear()
	var vp_size := get_viewport_rect().size
	var w := vp_size.x
	var h := vp_size.y

	# --- BÊN TRÁI: JOYSTICK CỐ ĐỊNH CHUẨN GÓC DƯỚI TRÁI ---
	joystick_base_radius = 65.0
	joystick_knob_radius = 28.0
	joystick_deadzone = 12.0
	joystick_base_pos = Vector2(145.0, h - 145.0)
	joystick_center = joystick_base_pos
	_joystick_current_pos = joystick_base_pos

	# --- BÊN PHẢI: CỤM NÚT CHIẾN ĐẤU LIÊN QUÂN ---
	var right_hub := Vector2(w - 145.0, h - 145.0)

	# 1. NÚT ĐÁNH THƯỜNG (Lớn nhất - Trung tâm chuẩn Liên Quân)
	btn_attack = TouchButton.new()
	btn_attack.id = "attack"
	btn_attack.center = right_hub
	btn_attack.radius = 48.0
	btn_attack.action = "attack"
	btn_attack.label = "ĐÁNH"
	btn_attack.icon = "⚔"
	btn_attack.color_bg = Color(0.18, 0.12, 0.08, 0.75)
	btn_attack.color_border = Color(0.95, 0.65, 0.15, 0.9)
	btn_attack.color_pressed = Color(1.0, 0.75, 0.25, 0.95)
	buttons.append(btn_attack)

	# 2. NÚT NHẢY (Bóng trên - Hướng 12 giờ)
	btn_jump = TouchButton.new()
	btn_jump.id = "jump"
	btn_jump.center = right_hub + Vector2(10, -135)
	btn_jump.radius = 35.0
	btn_jump.action = "jump"
	btn_jump.label = "NHẢY"
	btn_jump.icon = "▲"
	btn_jump.color_bg = Color(0.08, 0.16, 0.18, 0.75)
	btn_jump.color_border = Color(0.25, 0.85, 0.7, 0.9)
	btn_jump.color_pressed = Color(0.4, 1.0, 0.85, 0.95)
	buttons.append(btn_jump)

	# 3. NÚT BẮN PHÉP (Bóng trên-trái - Hướng 10 giờ)
	btn_cast = TouchButton.new()
	btn_cast.id = "cast_spell"
	btn_cast.center = right_hub + Vector2(-115, -95)
	btn_cast.radius = 35.0
	btn_cast.action = "cast_spell"
	btn_cast.label = "TRĂNG"
	btn_cast.icon = "✦"
	btn_cast.color_bg = Color(0.15, 0.08, 0.2, 0.75)
	btn_cast.color_border = Color(0.75, 0.45, 0.95, 0.9)
	btn_cast.color_pressed = Color(0.9, 0.6, 1.0, 0.95)
	buttons.append(btn_cast)

	# 4. NÚT LƯỚT / DASH (Bóng ngang-trái - Hướng 8 giờ)
	btn_dash = TouchButton.new()
	btn_dash.id = "dash"
	btn_dash.center = right_hub + Vector2(-135, 15)
	btn_dash.radius = 33.0
	btn_dash.action = "dash"
	btn_dash.label = "LƯỚT"
	btn_dash.icon = "»"
	btn_dash.color_bg = Color(0.08, 0.14, 0.22, 0.75)
	btn_dash.color_border = Color(0.25, 0.65, 0.95, 0.9)
	btn_dash.color_pressed = Color(0.45, 0.85, 1.0, 0.95)
	buttons.append(btn_dash)

	# 5. NÚT MENU (Góc trên phải)
	btn_menu = TouchButton.new()
	btn_menu.id = "menu"
	btn_menu.center = Vector2(w - 55.0, 46.0)
	btn_menu.radius = 26.0
	btn_menu.action = "toggle_sidebar"
	btn_menu.label = "MENU"
	btn_menu.icon = "☰"
	btn_menu.color_bg = Color(0.12, 0.16, 0.22, 0.85)
	btn_menu.color_border = Color(0.4, 0.75, 1.0, 0.95)
	btn_menu.color_pressed = Color(0.6, 0.9, 1.0, 1.0)
	buttons.append(btn_menu)

	# 6. NÚT TƯƠNG TÁC / NÓI CHUYỆN [E] (Nằm ngay bên dưới nút Menu)
	btn_interact = TouchButton.new()
	btn_interact.id = "interact"
	btn_interact.center = Vector2(btn_menu.center.x, btn_menu.center.y + 62.0)
	btn_interact.radius = 26.0
	btn_interact.action = "interact"
	btn_interact.label = "NÓI/MỞ"
	btn_interact.icon = "💬"
	btn_interact.color_bg = Color(0.14, 0.18, 0.10, 0.85)
	btn_interact.color_border = Color(0.9, 0.85, 0.3, 0.95)
	btn_interact.color_pressed = Color(1.0, 1.0, 0.5, 1.0)
	buttons.append(btn_interact)

func _setup_spell_radial_options() -> void:
	spell_radial_options.clear()
	if btn_cast == null:
		return

	var radius_dist := 92.0

	# 1. Nguyệt Quang Đạn (TRĂNG) - Đỉnh trên chếch nhẹ sang trái (Hướng 11h)
	var opt_moon = SpellOption.new()
	opt_moon.spell_id = "moon_bolt"
	opt_moon.label = "TRĂNG"
	opt_moon.icon = "✦"
	opt_moon.color = Color(0.8, 0.5, 1.0)
	opt_moon.angle = -PI * 0.60
	opt_moon.center = btn_cast.center + Vector2(cos(opt_moon.angle), sin(opt_moon.angle)) * radius_dist
	spell_radial_options.append(opt_moon)

	# 2. Tinh Hỏa Bùng Nổ (LỬA) - Chếch góc trên bên trái (Hướng 9h30 - 10h), hoàn toàn thông thoáng
	var opt_fire = SpellOption.new()
	opt_fire.spell_id = "ember_bloom"
	opt_fire.label = "LỬA"
	opt_fire.icon = "flame"
	opt_fire.color = Color(1.0, 0.45, 0.2)
	opt_fire.angle = -PI * 0.85
	opt_fire.center = btn_cast.center + Vector2(cos(opt_fire.angle), sin(opt_fire.angle)) * radius_dist
	spell_radial_options.append(opt_fire)

	# 3. Hàn Tinh Tiễn (BĂNG) - Đỉnh chếch trên bên phải (Hướng 1h30), cách xa nút NHẢY hơn 45px không bao giờ chạm
	var opt_frost = SpellOption.new()
	opt_frost.spell_id = "frost_shard"
	opt_frost.label = "BĂNG"
	opt_frost.icon = "❄"
	opt_frost.color = Color(0.3, 0.85, 1.0)
	opt_frost.angle = -PI * 0.36
	opt_frost.center = btn_cast.center + Vector2(cos(opt_frost.angle), sin(opt_frost.angle)) * radius_dist
	spell_radial_options.append(opt_frost)

func set_selected_spell(spell_id: String) -> void:
	if btn_cast == null:
		return
	match spell_id:
		"moon_bolt":
			btn_cast.label = "TRĂNG"
			btn_cast.icon = "✦"
			btn_cast.color_border = Color(0.75, 0.45, 0.95, 0.9)
		"ember_bloom":
			btn_cast.label = "LỬA"
			btn_cast.icon = "flame"
			btn_cast.color_border = Color(1.0, 0.45, 0.2, 0.9)
		"frost_shard":
			btn_cast.label = "BĂNG"
			btn_cast.icon = "❄"
			btn_cast.color_border = Color(0.3, 0.85, 1.0, 0.9)
	queue_redraw()

func _sync_current_spell_icon() -> void:
	if btn_cast == null:
		return
	var player = _get_player()
	if player:
		var sb: SpellbookComponent = player.spellbook_component
		if sb == null:
			sb = player.get_node_or_null("SpellbookComponent") as SpellbookComponent
		if sb:
			_connected_spellbook = sb
			if not sb.spell_selected.is_connected(_on_player_spell_selected_for_touch):
				sb.spell_selected.connect(_on_player_spell_selected_for_touch)
			set_selected_spell(sb.selected_spell_id)
			return
		elif "spell_caster" in player and player.spell_caster:
			set_selected_spell(player.spell_caster.selected_spell)
			return

func _on_player_spell_selected_for_touch(s_id: String) -> void:
	set_selected_spell(s_id)

func _get_player() -> Player:
	var tree := get_tree()
	if not tree:
		return null
	var players = tree.get_nodes_in_group(GameGroups.PLAYERS)
	if players.size() > 0:
		return players[0] as Player
	if tree.current_scene:
		var p = tree.current_scene.get_node_or_null("Player") as Player
		if p:
			return p
	return null

func _check_can_interact() -> bool:
	var tree := get_tree()
	if not tree:
		return false

	# 1. Nếu đang mở hội thoại -> Hiển thị nút
	var game_uis := tree.get_nodes_in_group(GameGroups.GAME_UI)
	for gui in game_uis:
		if gui.has_method("is_dialogue_open") and gui.is_dialogue_open():
			return true

	# 2. Kiểm tra NPC có thể tương tác gần người chơi
	for n in tree.get_nodes_in_group(GameGroups.NPCS):
		if n.has_method("is_interactable") and n.is_interactable():
			return true

	# 3. Kiểm tra Cổng dịch chuyển
	for p in tree.get_nodes_in_group(GameGroups.ZONE_PORTALS):
		if p.has_method("is_interactable") and p.is_interactable():
			return true

	# 4. Kiểm tra vật thể tương tác
	for obj in tree.get_nodes_in_group(GameGroups.INTERACTABLES):
		if obj.has_method("is_interactable") and obj.is_interactable():
			return true

	return false

func _process(delta: float) -> void:
	# Đảm bảo kết nối và cập nhật tức thì icon phép với Player
	if _connected_spellbook == null or not is_instance_valid(_connected_spellbook):
		_sync_current_spell_icon()

	# Cập nhật trạng thái ẩn/hiện của nút tương tác E
	var can_int := _check_can_interact()
	if can_int != is_interact_visible:
		is_interact_visible = can_int
		queue_redraw()

	# Đếm thời gian giữ nút Phép để mở vòng chọn phép
	if _cast_touch_id != -1 and not _is_spell_menu_open:
		_cast_hold_timer += delta
		if _cast_hold_timer >= 0.20:
			_open_spell_radial_menu()

	# Hiệu ứng mượt nở ra / thu lại của vòng phép
	if _is_spell_menu_open:
		if _radial_anim_progress < 1.0:
			_radial_anim_progress = move_toward(_radial_anim_progress, 1.0, delta * 6.0)
			queue_redraw()
	else:
		if _radial_anim_progress > 0.0:
			_radial_anim_progress = move_toward(_radial_anim_progress, 0.0, delta * 7.0)
			queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Handle the real pointer once, not its emulated mouse/touch duplicate.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	# Xử lý Cảm ứng màn hình (Touch) hoặc Giả lập chuột (Mouse)
	if event is InputEventScreenTouch:
		_handle_touch_event(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_drag_event(event.index, event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_touch_event(0, event.position, event.pressed)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_handle_drag_event(0, event.position)

func _handle_touch_event(touch_id: int, pos: Vector2, is_pressed: bool) -> void:
	if is_pressed:
		# 1. Kiểm tra riêng nút Phép (hỗ trợ Chạm nhanh để bắn, Ấn giữ để đổi chiêu)
		if pos.distance_to(btn_cast.center) <= btn_cast.radius * 1.35:
			get_viewport().set_input_as_handled()
			_cast_touch_id = touch_id
			_cast_hold_timer = 0.0
			_cast_touch_pos = pos
			btn_cast.touch_id = touch_id
			btn_cast.is_pressed = true
			btn_cast.scale_anim = 0.88
			queue_redraw()
			return

		# 2. Kiểm tra các nút bên phải khác và Menu / Tương tác
		for btn in buttons:
			if btn.id == "cast_spell":
				continue
			# Nút tương tác [E] bị ẩn nếu không ở gần NPC/vật thể
			if btn.id == "interact" and not is_interact_visible:
				continue

			# Hitbox rộng rãi (tối thiểu 46px) giúp ngón tay chạm chuẩn xác
			var hit_radius := maxf(btn.radius * 1.45, 46.0)
			if pos.distance_to(btn.center) <= hit_radius:
				# Consume BEFORE opening a panel at the same coordinates as this press.
				get_viewport().set_input_as_handled()
				btn.touch_id = touch_id
				btn.is_pressed = true
				btn.scale_anim = 0.88
				if btn.id == "menu":
					menu_pressed.emit()
				elif btn.id == "interact":
					_trigger_interact()
				elif btn.action != "":
					Input.action_press(btn.action)
				queue_redraw()
				return

		# 3. Kiểm tra chạm vào vùng Joystick góc dưới bên trái
		# Đế cố định vững chắc, không bao giờ bay lên giữa màn hình
		if pos.x < 360.0 and pos.y > size.y * 0.45:
			if _joystick_touch_id == -1:
				get_viewport().set_input_as_handled()
				_joystick_touch_id = touch_id
				joystick_center = joystick_base_pos
				_update_joystick(pos)
				return
	else:
		# Thả ngón tay
		# Xử lý nút Phép
		if touch_id == _cast_touch_id:
			if _is_spell_menu_open:
				if _hovered_spell_id != "":
					_apply_selected_spell(_hovered_spell_id)
				_close_spell_radial_menu()
			else:
				# Nhấn nhả nhanh: Kích hoạt tung phép hiện tại
				Input.action_press("cast_spell")
				call_deferred("_release_cast_action")

			_cast_touch_id = -1
			_cast_hold_timer = 0.0
			btn_cast.touch_id = -1
			btn_cast.is_pressed = false
			btn_cast.scale_anim = 1.0
			queue_redraw()

		# Kiểm tra Joystick: Nhả tay tự động đàn hồi về tâm cố định
		if touch_id == _joystick_touch_id:
			_reset_joystick()

		# Kiểm tra các nút bên phải khác
		for btn in buttons:
			if btn.id == "cast_spell":
				continue
			if btn.touch_id == touch_id:
				btn.touch_id = -1
				btn.is_pressed = false
				btn.scale_anim = 1.0
				if btn.action != "" and btn.id != "menu" and btn.id != "interact":
					Input.action_release(btn.action)
				queue_redraw()

func _trigger_interact() -> void:
	var tree := get_tree()
	if not tree:
		return

	# 1. Nếu GameUI đang mở hội thoại -> Chuyển câu tiếp theo hoặc đóng (chỉ gọi 1 lần duy nhất)
	var game_uis := tree.get_nodes_in_group(GameGroups.GAME_UI)
	for gui in game_uis:
		if gui.has_method("is_dialogue_open") and gui.is_dialogue_open():
			gui.advance_dialogue()
			return

	# 2. Nếu có InteractionCoordinator trong Scene -> Gọi điều phối duy nhất
	var coords := tree.get_nodes_in_group(GameGroups.INTERACTION_COORDINATOR)
	if coords.size() > 0:
		var ev_press := InputEventAction.new()
		ev_press.action = "interact"
		ev_press.pressed = true
		coords[0]._unhandled_input(ev_press)
		return

	# Kiểm tra nếu đang trong thời gian hồi đối thoại hoặc Player đang bị khóa input
	for gui in game_uis:
		if gui.has_method("is_dialogue_cooling_down") and gui.is_dialogue_cooling_down():
			return
		if gui.has_method("is_ui_cooling_down") and gui.is_ui_cooling_down():
			return

	var players := tree.get_nodes_in_group(GameGroups.PLAYERS)
	if players.size() > 0:
		var p = players[0]
		if p.has_method("is_input_blocked") and p.is_input_blocked():
			return

	# 3. Kích hoạt trực tiếp NPC gần nhất
	for n in tree.get_nodes_in_group(GameGroups.NPCS):
		if n.has_method("is_interactable") and n.is_interactable() and n.has_method("trigger_interaction"):
			n.trigger_interaction()
			return

	# 4. Kích hoạt trực tiếp Cổng dịch chuyển
	for p in tree.get_nodes_in_group(GameGroups.ZONE_PORTALS):
		if p.has_method("is_interactable") and p.is_interactable() and p.has_method("trigger_interaction"):
			p.trigger_interaction()
			return

	# 5. Kích hoạt vật thể tương tác
	for obj in tree.get_nodes_in_group(GameGroups.INTERACTABLES):
		if obj.has_method("is_interactable") and obj.is_interactable() and obj.has_method("trigger_interaction"):
			obj.trigger_interaction()
			return

func _release_cast_action() -> void:
	Input.action_release("cast_spell")

func _handle_drag_event(touch_id: int, pos: Vector2) -> void:
	if touch_id == _joystick_touch_id:
		_update_joystick(pos)
	elif touch_id == _cast_touch_id and _is_spell_menu_open:
		_update_spell_radial_hover(pos)

func _update_joystick(pos: Vector2) -> void:
	var diff := pos - joystick_base_pos
	var dist := diff.length()

	if dist > joystick_base_radius:
		_joystick_current_pos = joystick_base_pos + diff.normalized() * joystick_base_radius
	else:
		_joystick_current_pos = pos

	if dist < joystick_deadzone:
		Input.action_release("move_left")
		Input.action_release("move_right")
	else:
		var norm := diff.normalized()
		# Mô phỏng bàn phím PC: di chuyển trái/phải với full lực 1.0
		if norm.x < -0.2:
			Input.action_press("move_left", 1.0)
			Input.action_release("move_right")
		elif norm.x > 0.2:
			Input.action_press("move_right", 1.0)
			Input.action_release("move_left")
		else:
			Input.action_release("move_left")
			Input.action_release("move_right")

	queue_redraw()

func _reset_joystick() -> void:
	_joystick_touch_id = -1
	joystick_center = joystick_base_pos
	_joystick_current_pos = joystick_base_pos
	Input.action_release("move_left")
	Input.action_release("move_right")
	queue_redraw()

# --- RADIAL SPELL SELECTOR LOGIC ---
func _open_spell_radial_menu() -> void:
	_is_spell_menu_open = true
	_hovered_spell_id = ""
	_radial_anim_progress = 0.0
	queue_redraw()

func _close_spell_radial_menu() -> void:
	_is_spell_menu_open = false
	_hovered_spell_id = ""
	queue_redraw()

func _update_spell_radial_hover(pos: Vector2) -> void:
	_hovered_spell_id = ""
	for opt in spell_radial_options:
		if pos.distance_to(opt.center) <= opt.radius * 1.55:
			opt.is_hovered = true
			_hovered_spell_id = opt.spell_id
		else:
			opt.is_hovered = false
	queue_redraw()

func _apply_selected_spell(spell_id: String) -> void:
	match spell_id:
		"moon_bolt":
			btn_cast.label = "TRĂNG"
			btn_cast.icon = "✦"
			btn_cast.color_border = Color(0.75, 0.45, 0.95, 0.9)
		"ember_bloom":
			btn_cast.label = "LỬA"
			btn_cast.icon = "flame"
			btn_cast.color_border = Color(1.0, 0.45, 0.2, 0.9)
		"frost_shard":
			btn_cast.label = "BĂNG"
			btn_cast.icon = "❄"
			btn_cast.color_border = Color(0.3, 0.85, 1.0, 0.9)

	var player = _get_player()
	if player:
		if player.spellbook_component:
			player.spellbook_component.select_spell(spell_id)
		elif "spell_caster" in player and player.spell_caster:
			player.spell_caster.selected_spell = spell_id
	queue_redraw()

# --- VẼ GIAO DIỆN (CANVAS DRAWING) ---
func _draw() -> void:
	# 1. Vẽ Cần Điều Khiển Analog (Joystick Cố Định)
	# A. Vòng đế mờ lớn cố định ở góc dưới trái
	draw_circle(joystick_center, joystick_base_radius, Color(0.06, 0.08, 0.12, 0.4))
	draw_arc(joystick_center, joystick_base_radius, 0.0, TAU, 48, Color(0.3, 0.7, 0.9, 0.5), 2.0, true)
	draw_arc(joystick_center, joystick_deadzone, 0.0, TAU, 24, Color(0.3, 0.7, 0.9, 0.2), 1.0, true)

	# B. Núm analog điều khiển tự do (không dây nối, đàn hồi về tâm khi nhả tay)
	var knob_col := Color(0.25, 0.65, 0.9, 0.8) if _joystick_touch_id != -1 else Color(0.18, 0.35, 0.5, 0.6)
	draw_circle(_joystick_current_pos, joystick_knob_radius, knob_col)
	draw_arc(_joystick_current_pos, joystick_knob_radius, 0.0, TAU, 32, Color(0.8, 0.95, 1.0, 0.9), 2.0, true)
	draw_circle(_joystick_current_pos, 8.0, Color(1.0, 1.0, 1.0, 0.8))

	# 2. Vẽ Các Phím Hành Động (Action Buttons)
	var font := ThemeDB.fallback_font
	for btn in buttons:
		# Nút tương tác [E] ẩn hoàn toàn nếu không ở gần NPC/vật thể tương tác
		if btn.id == "interact" and not is_interact_visible:
			continue

		var cur_radius := btn.radius * btn.scale_anim
		var bg_color := btn.color_pressed if btn.is_pressed else btn.color_bg
		var border_color := btn.color_pressed if btn.is_pressed else btn.color_border
		var border_width := 3.2 if btn.is_pressed else 2.2

		# Đổ bóng nền nút
		draw_circle(btn.center + Vector2(0, 3), cur_radius, Color(0, 0, 0, 0.4))
		# Thân nút
		draw_circle(btn.center, cur_radius, bg_color)
		# Viền phát sáng
		draw_arc(btn.center, cur_radius, 0.0, TAU, 36, border_color, border_width, true)
		draw_arc(btn.center, cur_radius - 4.0, 0.0, TAU, 32, Color(border_color.r, border_color.g, border_color.b, 0.3), 1.2, true)

		# Icon biểu tượng
		var icon_size := int(cur_radius * 0.78)
		var label_size := int(cur_radius * 0.38)
		var icon_str := btn.icon
		var label_str := btn.label

		if btn.id == "cast_spell" and (btn.label == "LỬA" or icon_str == "flame" or icon_str == "🔥"):
			_draw_vector_flame(btn.center + Vector2(0, -cur_radius * 0.14), cur_radius * 0.40, btn.is_pressed)
		else:
			var icon_w := font.get_string_size(icon_str, HORIZONTAL_ALIGNMENT_CENTER, -1, icon_size).x
			draw_string(font, btn.center + Vector2(-icon_w * 0.5, icon_size * 0.2), icon_str, HORIZONTAL_ALIGNMENT_CENTER, -1, icon_size, Color.WHITE)
		# Nhãn chữ dưới icon
		if label_str != "":
			var label_w := font.get_string_size(label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, label_size).x
			draw_string(font, btn.center + Vector2(-label_w * 0.5, cur_radius * 0.72), label_str, HORIZONTAL_ALIGNMENT_CENTER, -1, label_size, Color(0.9, 0.9, 0.9, 0.85))

	# 3. Vẽ Vòng Chọn Phép (Radial Spell Selector)
	if _radial_anim_progress > 0.01:
		for opt in spell_radial_options:
			var anim_pos := btn_cast.center.lerp(opt.center, _radial_anim_progress)
			var r := opt.radius * _radial_anim_progress

			# Tia sáng từ nút phép ra từng bóng phép
			var line_col := Color(opt.color.r, opt.color.g, opt.color.b, 0.45 * _radial_anim_progress)
			var line_w := 3.5 if opt.is_hovered else 1.8
			draw_line(btn_cast.center, anim_pos, line_col, line_w)

			# Quả cầu phép nổi
			var bg_col := Color(opt.color.r * 0.3, opt.color.g * 0.3, opt.color.b * 0.3, 0.9)
			if opt.is_hovered:
				bg_col = Color(opt.color.r, opt.color.g, opt.color.b, 0.95)
			draw_circle(anim_pos, r, bg_col)

			# Viền quả cầu
			var border_col := opt.color
			var border_w := 3.5 if opt.is_hovered else 2.0
			draw_arc(anim_pos, r, 0.0, TAU, 32, border_col, border_w, true)

			# Icon và nhãn
			var opt_icon_size := int(r * 0.85)
			var opt_lbl_size := int(r * 0.45)
			var text_col := Color.BLACK if opt.is_hovered else Color.WHITE
			var opt_lbl_w := font.get_string_size(opt.label, HORIZONTAL_ALIGNMENT_CENTER, -1, opt_lbl_size).x

			if opt.spell_id == "ember_bloom" or opt.icon == "flame" or opt.icon == "🔥":
				_draw_vector_flame(anim_pos + Vector2(0, -r * 0.14), r * 0.42, opt.is_hovered)
			else:
				var opt_icon_w := font.get_string_size(opt.icon, HORIZONTAL_ALIGNMENT_CENTER, -1, opt_icon_size).x
				draw_string(font, anim_pos + Vector2(-opt_icon_w * 0.5, opt_icon_size * 0.22), opt.icon, HORIZONTAL_ALIGNMENT_CENTER, -1, opt_icon_size, text_col)

			draw_string(font, anim_pos + Vector2(-opt_lbl_w * 0.5, r * 0.72), opt.label, HORIZONTAL_ALIGNMENT_CENTER, -1, opt_lbl_size, text_col)

func _draw_vector_flame(pos: Vector2, s: float, is_highlighted: bool) -> void:
	var outer_rel := [
		Vector2(0.0, -1.0),
		Vector2(0.18, -0.65),
		Vector2(0.42, -0.30),
		Vector2(0.55, 0.15),
		Vector2(0.42, 0.65),
		Vector2(0.18, 0.92),
		Vector2(0.0, 0.98),
		Vector2(-0.18, 0.92),
		Vector2(-0.42, 0.65),
		Vector2(-0.55, 0.15),
		Vector2(-0.40, -0.28),
		Vector2(-0.25, -0.15),
		Vector2(-0.10, -0.55)
	]
	var outer_pts := PackedVector2Array()
	for pt in outer_rel:
		outer_pts.append(pos + pt * s)

	var outer_col := Color(0.25, 0.05, 0.02, 0.95) if is_highlighted else Color(1.0, 0.48, 0.12, 1.0)
	draw_colored_polygon(outer_pts, outer_col)

	var is_s := s * 0.52
	var inner_rel := [
		Vector2(0.0, -0.75),
		Vector2(0.25, -0.20),
		Vector2(0.35, 0.35),
		Vector2(0.15, 0.85),
		Vector2(0.0, 0.92),
		Vector2(-0.15, 0.85),
		Vector2(-0.35, 0.35),
		Vector2(-0.25, -0.20)
	]
	var inner_pts := PackedVector2Array()
	for pt in inner_rel:
		inner_pts.append(pos + Vector2(0, s * 0.10) + pt * is_s)

	var inner_col := Color(1.0, 0.95, 0.45, 1.0)
	draw_colored_polygon(inner_pts, inner_col)

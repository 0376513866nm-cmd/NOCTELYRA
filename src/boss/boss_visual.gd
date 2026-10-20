class_name BossVisual
extends Node2D

## Bộ điều khiển hiển thị độc lập cho Boss Lunareth (M4)
## Cho phép phân tách hoàn toàn giữa logic FSM, Hitbox và Đồ họa.
## Dễ dàng thay thế bằng SpriteSheet trong tương lai mà không ảnh hưởng AI.

enum VisualState {
	IDLE,
	MOVE,
	TELEGRAPH_CHARGE,
	TELEGRAPH_SHOCKWAVE,
	ATTACK_CHARGE,
	ATTACK_STOMP,
	RECOVERY,
	PHASE_TRANSITION,
	DEFEATED
}

@onready var visual_root: Node2D = $VisualRoot
@onready var body_parts: Node2D = $VisualRoot/BodyParts
@onready var antlers_root: Node2D = $VisualRoot/BodyParts/Head/Antlers
@onready var eye: ColorRect = $VisualRoot/BodyParts/Head/Eye
@onready var lunar_mark: ColorRect = $VisualRoot/BodyParts/Head/LunarMark
@onready var telegraph_charge_rect: ColorRect = $TelegraphCharge
@onready var telegraph_shockwave_ring: ColorRect = $TelegraphShockwave
@onready var aura_rect: ColorRect = $VisualRoot/AuraRect

var current_visual_state: VisualState = VisualState.IDLE
var is_phase_2: bool = false
var _anim_timer: float = 0.0
var _hit_flash_timer: float = 0.0

# Bảng màu Phase 1 (Lam Nguyệt / Cyan Indigo)
const P1_BODY_COLOR: Color = Color(0.12, 0.18, 0.32, 1.0)
const P1_ANTLER_COLOR: Color = Color(0.25, 0.85, 0.95, 1.0)
const P1_AURA_COLOR: Color = Color(0.2, 0.6, 0.9, 0.25)

# Bảng màu Phase 2 (Hắc Nguyệt / Dark Eclipse Violet)
const P2_BODY_COLOR: Color = Color(0.22, 0.08, 0.28, 1.0)
const P2_ANTLER_COLOR: Color = Color(0.95, 0.2, 0.85, 1.0)
const P2_AURA_COLOR: Color = Color(0.8, 0.1, 0.6, 0.35)

# Bảng màu Thanh tẩy thành công (Moonlight Serene)
const CLEANSED_BODY_COLOR: Color = Color(0.88, 0.95, 1.0, 1.0)
const CLEANSED_ANTLER_COLOR: Color = Color(0.5, 0.9, 1.0, 0.9)
const CLEANSED_AURA_COLOR: Color = Color(1.0, 0.9, 0.6, 0.3)

func _ready() -> void:
	if telegraph_charge_rect:
		telegraph_charge_rect.visible = false
	if telegraph_shockwave_ring:
		telegraph_shockwave_ring.visible = false
	_apply_palette()

func reset_visual() -> void:
	is_phase_2 = false
	current_visual_state = VisualState.IDLE
	_anim_timer = 0.0
	_hit_flash_timer = 0.0
	if telegraph_charge_rect:
		telegraph_charge_rect.visible = false
	if telegraph_shockwave_ring:
		telegraph_shockwave_ring.visible = false
	if body_parts:
		body_parts.position = Vector2.ZERO
		body_parts.rotation = 0.0
		body_parts.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if antlers_root:
		antlers_root.rotation = 0.0
	_apply_palette()

func _process(delta: float) -> void:
	_anim_timer += delta

	# Xử lý chớp trắng khi nhận đòn (Hit Flash)
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			_apply_palette()

	# Hoạt ảnh thở / di chuyển / trạng thái
	match current_visual_state:
		VisualState.IDLE, VisualState.RECOVERY:
			var bob: float = sin(_anim_timer * 3.0) * 3.0
			body_parts.position.y = bob
			if antlers_root:
				antlers_root.rotation = sin(_anim_timer * 2.0) * 0.05
		VisualState.MOVE:
			var trot: float = sin(_anim_timer * 10.0) * 5.0
			body_parts.position.y = trot
			if antlers_root:
				antlers_root.rotation = sin(_anim_timer * 10.0) * 0.1
		VisualState.TELEGRAPH_CHARGE, VisualState.TELEGRAPH_SHOCKWAVE:
			# Chớp đỏ cảnh báo
			var pulse: float = (sin(_anim_timer * 16.0) + 1.0) * 0.5
			if telegraph_charge_rect and telegraph_charge_rect.visible:
				telegraph_charge_rect.modulate.a = 0.3 + pulse * 0.4
			if telegraph_shockwave_ring and telegraph_shockwave_ring.visible:
				telegraph_shockwave_ring.modulate.a = 0.3 + pulse * 0.4
		VisualState.PHASE_TRANSITION:
			# Rung lắc giải phóng ma lực
			body_parts.position.x = randf_range(-4.0, 4.0)
			body_parts.position.y = randf_range(-4.0, 4.0)
			if aura_rect:
				aura_rect.modulate.a = 0.5 + sin(_anim_timer * 20.0) * 0.3
		VisualState.DEFEATED:
			# Thả lỏng nằm nghỉ ngơi an lành
			body_parts.position.y = 20.0
			body_parts.position.x = 0.0
			if antlers_root:
				antlers_root.rotation = -0.2

func set_facing(dir: int) -> void:
	if visual_root:
		visual_root.scale.x = 1.0 if dir <= 0 else -1.0
	if telegraph_charge_rect:
		telegraph_charge_rect.scale.x = 1.0 if dir <= 0 else -1.0

func set_state(state: VisualState) -> void:
	current_visual_state = state
	if telegraph_charge_rect:
		telegraph_charge_rect.visible = (state == VisualState.TELEGRAPH_CHARGE)
	if telegraph_shockwave_ring:
		telegraph_shockwave_ring.visible = (state == VisualState.TELEGRAPH_SHOCKWAVE)

	if state == VisualState.PHASE_TRANSITION:
		is_phase_2 = true
		_apply_palette()
	elif state == VisualState.DEFEATED:
		_apply_defeated_palette()

func flash_hit() -> void:
	_hit_flash_timer = 0.15
	if body_parts:
		body_parts.modulate = Color(2.5, 2.5, 2.5, 1.0)

func _apply_palette() -> void:
	var body_col: Color = P2_BODY_COLOR if is_phase_2 else P1_BODY_COLOR
	var antler_col: Color = P2_ANTLER_COLOR if is_phase_2 else P1_ANTLER_COLOR
	var aura_col: Color = P2_AURA_COLOR if is_phase_2 else P1_AURA_COLOR

	if body_parts:
		body_parts.modulate = Color(1.0, 1.0, 1.0, 1.0)
		for child in body_parts.get_children():
			if child is ColorRect:
				child.color = body_col
	if antlers_root:
		for child in antlers_root.get_children():
			if child is ColorRect:
				child.color = antler_col
	if lunar_mark:
		lunar_mark.color = antler_col
	if aura_rect:
		aura_rect.color = aura_col

func _apply_defeated_palette() -> void:
	if body_parts:
		body_parts.modulate = Color(1.0, 1.0, 1.0, 1.0)
		for child in body_parts.get_children():
			if child is ColorRect:
				child.color = CLEANSED_BODY_COLOR
	if antlers_root:
		for child in antlers_root.get_children():
			if child is ColorRect:
				child.color = CLEANSED_ANTLER_COLOR
	if lunar_mark:
		lunar_mark.color = CLEANSED_ANTLER_COLOR
	if aura_rect:
		aura_rect.color = CLEANSED_AURA_COLOR

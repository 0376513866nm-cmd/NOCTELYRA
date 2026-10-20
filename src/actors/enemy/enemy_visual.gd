class_name EnemyVisual
extends Node2D

## Bộ điều khiển hiển thị đồ họa cho sinh vật (Enemy Visual Controller) cho NOCTELYRA (Milestone M7)
## Hỗ trợ 5 trạng thái hoạt ảnh: 'idle', 'move', 'attack', 'hit', 'death'.
## Dựng hình placeholder đặc trưng cho 4 chủng loại quái mới,
## sẵn sàng để thay thế bằng AnimatedSprite2D / SpriteFrames trong tương lai.

@export var enemy_type_id: String = "corrupted_wolf"

@onready var main_body: ColorRect = $MainBody
@onready var detail_node: Node2D = $DetailNode
@onready var eye_rect: ColorRect = $MainBody/EyeRect

var current_state: String = "idle"
var _base_color: Color = Color(0.8, 0.2, 0.2)
var _anim_time: float = 0.0

func _ready() -> void:
	apply_type_style(enemy_type_id)

func apply_type_style(type_id: String) -> void:
	enemy_type_id = type_id

	var sprite_root = get_node_or_null("SpriteRoot")
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

	# Xóa các chi tiết cũ nếu có
	if detail_node:
		for c in detail_node.get_children():
			c.queue_free()

	match type_id:
		"corrupted_wolf":
			# Sói Tha Hóa Rừng Noctis: Hoạt ảnh sprite hoàn chỉnh từ bản Thiên Khí
			_base_color = Color(0.8, 0.2, 0.2)
			if sprite_root:
				sprite_root.visible = true
			if main_body:
				main_body.visible = false
			if anim_player and anim_player.has_animation("idle"):
				anim_player.play("idle")
				anim_player.advance(0.0)

		"corrupted_mooncap":
			if sprite_root:
				sprite_root.visible = false
			if main_body:
				main_body.visible = true
			# Nấm Mộng Tha Hóa: Thân nấm màu tím xanh, mũ nấm có đốm sáng
			_base_color = Color(0.55, 0.25, 0.85) # Tím ma thuật
			if main_body:
				main_body.size = Vector2(28, 26)
				main_body.position = Vector2(-14, -26)
				main_body.color = _base_color

			if eye_rect:
				eye_rect.color = Color(0.3, 0.9, 1.0) # Mắt xanh lam dễ thương
				eye_rect.position = Vector2(4, 8)
				eye_rect.size = Vector2(6, 6)

			# Thêm mũ nấm và các đốm sáng
			if detail_node:
				var cap := ColorRect.new()
				cap.name = "MushroomCap"
				cap.size = Vector2(38, 16)
				cap.position = Vector2(-19, -38)
				cap.color = Color(0.4, 0.2, 0.75)
				detail_node.add_child(cap)

				var spot1 := ColorRect.new()
				spot1.size = Vector2(6, 6)
				spot1.position = Vector2(-12, -34)
				spot1.color = Color(0.6, 0.9, 1.0, 0.9) # Đốm sáng xanh lam
				detail_node.add_child(spot1)

				var spot2 := ColorRect.new()
				spot2.size = Vector2(6, 6)
				spot2.position = Vector2(6, -34)
				spot2.color = Color(0.8, 0.6, 1.0, 0.9) # Đốm sáng tím nhạt
				detail_node.add_child(spot2)

		"corrupted_mana_wisp":
			# Linh Hồn Tinh Mạch: Khối sáng lơ lửng hình cầu ma pháp
			_base_color = Color(0.4, 0.6, 1.0, 0.85) # Lam tinh thạch
			if main_body:
				main_body.size = Vector2(24, 24)
				main_body.position = Vector2(-12, -28)
				main_body.color = _base_color

			if eye_rect:
				eye_rect.color = Color(0.9, 0.95, 1.0) # Lõi năng lượng phát sáng
				eye_rect.position = Vector2(6, 6)
				eye_rect.size = Vector2(12, 12)

			if detail_node:
				var halo := ColorRect.new()
				halo.name = "ManaHalo"
				halo.size = Vector2(34, 34)
				halo.position = Vector2(-17, -33)
				halo.color = Color(0.6, 0.3, 0.95, 0.35) # Hào quang tím bao quanh
				detail_node.add_child(halo)

		"ashfang_wolf":
			# Sói Tro: Thân đen xám, vệt ma lực cam đỏ
			_base_color = Color(0.22, 0.22, 0.26) # Lông tro đen xám
			if main_body:
				main_body.size = Vector2(40, 26)
				main_body.position = Vector2(-20, -26)
				main_body.color = _base_color

			if eye_rect:
				eye_rect.color = Color(1.0, 0.2, 0.1) # Mắt đỏ rực
				eye_rect.position = Vector2(6, 4)
				eye_rect.size = Vector2(8, 6)

			if detail_node:
				var streak := ColorRect.new()
				streak.name = "FireStreak"
				streak.size = Vector2(28, 6)
				streak.position = Vector2(-14, -18)
				streak.color = Color(1.0, 0.45, 0.1, 0.85) # Vệt ma lực đỏ cam
				detail_node.add_child(streak)

		"ember_lizard":
			# Hỏa Tích Hắc Nham: Thân thấp, đá đen nham thạch với vảy lửa
			_base_color = Color(0.18, 0.16, 0.2) # Nham thạch đen
			if main_body:
				main_body.size = Vector2(36, 18)
				main_body.position = Vector2(-18, -18)
				main_body.color = _base_color

			if eye_rect:
				eye_rect.color = Color(1.0, 0.7, 0.1) # Mắt vàng cam
				eye_rect.position = Vector2(6, 3)
				eye_rect.size = Vector2(6, 5)

			if detail_node:
				var crest := ColorRect.new()
				crest.name = "FireCrest"
				crest.size = Vector2(22, 6)
				crest.position = Vector2(-11, -24)
				crest.color = Color(1.0, 0.35, 0.05, 0.9) # Gai lưng hỏa thạch
				detail_node.add_child(crest)

		_:
			# Mặc định: Sói tha hóa Rừng Noctis
			_base_color = Color(0.8, 0.2, 0.2)
			if sprite_root:
				sprite_root.visible = true
			if main_body:
				main_body.visible = false
			if anim_player and anim_player.has_animation("idle"):
				anim_player.play("idle")
				anim_player.advance(0.0)

func _process(delta: float) -> void:
	_anim_time += delta
	# Hiệu ứng lơ lửng tự nhiên cho sinh vật bay (Wisp)
	if enemy_type_id == "corrupted_mana_wisp" and current_state != "death":
		position.y = sin(_anim_time * 3.5) * 6.0

func set_visual_state(state_name: String) -> void:
	current_state = state_name

	var sprite_root = get_node_or_null("SpriteRoot")
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer

	if (enemy_type_id == "corrupted_wolf" or enemy_type_id == "") and sprite_root and anim_player:
		if main_body:
			main_body.visible = false
		sprite_root.visible = true
		if anim_player.has_animation(state_name):
			anim_player.play(state_name)
			anim_player.advance(0.0)
		return

	if sprite_root:
		sprite_root.visible = false
	if main_body:
		main_body.visible = true

	# Xử lý hiệu ứng màu / hình dạng placeholder
	match state_name:
		"idle":
			main_body.color = _base_color
			scale = Vector2.ONE
		"move":
			main_body.color = _base_color.lightened(0.1)
		"telegraph":
			# Báo trước đòn đánh: nhấp nháy màu vàng / đỏ cảnh báo
			main_body.color = Color(1.0, 0.85, 0.2)
		"attack":
			main_body.color = Color(1.0, 0.3, 0.1)
		"hit":
			main_body.color = Color(1.0, 1.0, 1.0) # Flash trắng khi trúng đòn
		"death":
			main_body.color = Color(0.3, 0.3, 0.3, 0.6)

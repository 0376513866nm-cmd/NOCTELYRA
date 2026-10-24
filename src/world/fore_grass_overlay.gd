class_name ForeGrassOverlay
extends Node2D

## Lớp cỏ tiền cảnh (Fore-Grass Overlay) cho NOCTELYRA
## Được vẽ ở z_index = 1 (trên mặt đất và trên đế giày của nhân vật),
## giúp bàn chân, móng vuốt của Player, Pet, NPC, Quái vật lún nhẹ tự nhiên vào thảm cỏ,
## xóa bỏ hoàn toàn cảm giác nhân vật bị trôi nổi/lơ lửng trên mặt kính phẳng.

@export var map_start_x: float = -100.0
@export var map_end_x: float = 6400.0
@export var ground_y: float = 0.0 # Tọa độ bề mặt đất tương đối (0 tại y=630)

var _grass_clusters: Array[Dictionary] = []

func _ready() -> void:
	z_index = 1
	_generate_procedural_tufts()
	queue_redraw()

func _generate_procedural_tufts() -> void:
	_grass_clusters.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 133742 # Hạt ngẫu nhiên cố định để cỏ không bị giật đổi hình mỗi lần chạy

	var cur_x: float = map_start_x
	while cur_x < map_end_x:
		# Bước nhảy ngẫu nhiên giữa các cụm cỏ dày dặn (8 - 18 px)
		cur_x += rng.randf_range(8.0, 18.0)
		var num_blades: int = rng.randi_range(2, 5)
		var cluster_type: int = rng.randi_range(0, 3) # 0, 1: cỏ xanh tươi sáng; 2: chồi non xanh chuối; 3: hoa dại hồng phấn
		var blades: Array = []

		for b in range(num_blades):
			var bx: float = cur_x + rng.randf_range(-3.0, 3.0)
			var h: float = rng.randf_range(5.0, 11.0) # Chiều cao cụm cỏ nhô lên trên đế giày (5 - 11 px)
			var tilt: float = rng.randf_range(-3.0, 3.0)
			blades.append({"x": bx, "height": h, "tilt": tilt})

		var col: Color
		match cluster_type:
			0: col = Color(0.32, 0.72, 0.28, 0.95) # Cỏ xanh thảo nguyên rực rỡ (Image 2)
			1: col = Color(0.48, 0.84, 0.32, 0.95) # Cỏ non xanh tươi sáng
			2: col = Color(0.24, 0.58, 0.22, 0.95) # Rêu sẫm đổ bóng
			_: col = Color(0.95, 0.45, 0.70, 0.95) # Bụi hoa dại hồng phấn (Image 2)

		_grass_clusters.append({
			"blades": blades,
			"color": col,
			"type": cluster_type
		})

func _draw() -> void:
	for cluster in _grass_clusters:
		var col: Color = cluster["color"]
		for blade in cluster["blades"]:
			var bx: float = blade["x"]
			var h: float = blade["height"]
			var tilt: float = blade["tilt"]
			
			# Vẽ từng ngọn cỏ nhô lên từ mặt đất ôm lấy bàn chân nhân vật
			var base_pt := Vector2(bx, ground_y + 1.0)
			var tip_pt := Vector2(bx + tilt, ground_y - h)
			draw_line(base_pt, tip_pt, col, 2.5)
			
			# Nụ hoa nhỏ ở đầu ngọn cỏ
			if cluster["type"] == 3:
				draw_circle(tip_pt, 2.0, Color(1.0, 0.85, 0.35, 0.95))

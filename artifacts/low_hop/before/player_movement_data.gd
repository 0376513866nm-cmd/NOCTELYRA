class_name PlayerMovementData
extends Resource

@export var move_speed: float = 270.0
@export var acceleration: float = 1800.0
@export var friction: float = 1600.0
@export var air_acceleration: float = 1200.0
@export var air_friction: float = 300.0
@export var gravity: float = 1100.0
@export var jump_velocity: float = -490.0
@export var double_jump_velocity: float = -450.0
@export var max_jumps: int = 2
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8
@export var auto_step_enabled: bool = true ## Bật/tắt tự động nhảy nhẹ qua thềm thấp
@export var auto_step_min_height: float = 10.0 ## Chiều cao thềm tối thiểu để kích hoạt (pixel)
@export var auto_step_max_height: float = 48.0 ## Chiều cao thềm tối đa để tự động nhảy (khối cao hơn cần bấm Space)
@export var auto_step_jump_velocity: float = -460.0 ## Lực bật nhảy thềm thấp (-460px/s đồng bộ thời gian với GIF, airtime ~0.76s bay lượn ngắm trọn hoạt ảnh)

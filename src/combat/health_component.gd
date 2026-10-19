class_name HealthComponent
extends Node

signal health_changed(current: float, max_val: float)
signal mana_changed(current: float, max_val: float)
signal damaged(amount: float, source: Node)
signal died()
signal invulnerability_started()
signal invulnerability_ended()

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_mana: float = 50.0
@export var current_mana: float = 50.0
@export var mana_regen_rate: float = 5.0 # MP hồi phục mỗi giây
@export var invulnerability_duration: float = 0.6 # Thời gian miễn nhiễm sát thương sau khi trúng đòn

var is_invulnerable: bool = false
var _invuln_timer: float = 0.0

func _ready() -> void:
	current_health = clamp(current_health, 0.0, max_health)
	current_mana = clamp(current_mana, 0.0, max_mana)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("mana_changed", current_mana, max_mana)

func _process(delta: float) -> void:
	# Cập nhật thời gian miễn nhiễm sát thương
	if is_invulnerable:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false
			emit_signal("invulnerability_ended")

	# Tự động hồi MP dần theo thời gian nếu chưa đầy
	if mana_regen_rate > 0.0 and current_mana < max_mana:
		current_mana = min(max_mana, current_mana + mana_regen_rate * delta)
		emit_signal("mana_changed", current_mana, max_mana)

func take_damage(damage: DamageInfo) -> bool:
	if is_invulnerable or current_health <= 0.0:
		return false

	var final_dmg := damage.amount
	current_health = max(0.0, current_health - final_dmg)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("damaged", final_dmg, damage.source)

	if invulnerability_duration > 0.0:
		is_invulnerable = true
		_invuln_timer = invulnerability_duration
		emit_signal("invulnerability_started")

	if current_health <= 0.0:
		emit_signal("died")

	return true

func consume_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed", current_mana, max_mana)
		return true
	return false

func is_alive() -> bool:
	return current_health > 0.0

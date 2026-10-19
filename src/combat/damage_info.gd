class_name DamageInfo
extends RefCounted

var amount: float = 10.0
var source: Node = null
var knockback_dir: Vector2 = Vector2.ZERO
var knockback_force: float = 0.0

func _init(p_amount: float = 10.0, p_source: Node = null, p_knockback_dir: Vector2 = Vector2.ZERO, p_knockback_force: float = 0.0) -> void:
	amount = p_amount
	source = p_source
	knockback_dir = p_knockback_dir
	knockback_force = p_knockback_force

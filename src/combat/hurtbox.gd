class_name Hurtbox
extends Area2D

signal hit_received(damage: DamageInfo)

@export var health_component: HealthComponent
@export var owner_node: Node

func _ready() -> void:
	if owner_node == null:
		owner_node = get_parent()

func apply_damage(damage: DamageInfo) -> bool:
	if health_component and health_component.is_alive():
		var taken = health_component.take_damage(damage)
		if taken:
			emit_signal("hit_received", damage)
		return taken
	return false

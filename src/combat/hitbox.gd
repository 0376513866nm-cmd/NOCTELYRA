class_name Hitbox
extends Area2D

signal hit_landed(target_hurtbox: Hurtbox)

@export var damage: float = 15.0
@export var knockback_force: float = 200.0
@export var owner_node: Node

var _already_hit_nodes: Array[Node] = []

func _ready() -> void:
	if owner_node == null:
		owner_node = get_parent()
	area_entered.connect(_on_area_entered)

func reset_hits() -> void:
	_already_hit_nodes.clear()

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.owner_node == owner_node:
			return # Không tự đánh trúng chính mình
		if hurtbox.owner_node in _already_hit_nodes:
			return # Đã trúng trong lượt đánh này rồi

		var knock_dir := Vector2.RIGHT
		if owner_node is Node2D and hurtbox.owner_node is Node2D:
			knock_dir = (hurtbox.owner_node.global_position - owner_node.global_position).normalized()
			if knock_dir == Vector2.ZERO:
				knock_dir = Vector2.RIGHT

		var dmg_info := DamageInfo.new(damage, owner_node, knock_dir, knockback_force)
		var success := hurtbox.apply_damage(dmg_info)
		if success:
			_already_hit_nodes.append(hurtbox.owner_node)
			emit_signal("hit_landed", hurtbox)

class_name CombatComponent
extends Node

signal attack_started()
signal attack_finished()
signal spell_cast()

@export var attack_cooldown: float = 0.35
@export var spell_cooldown: float = 0.6
@export var spell_mana_cost: float = 15.0
@export var melee_hitbox: Hitbox
@export var projectile_scene: PackedScene = preload("res://src/combat/magic_projectile.tscn")
@export var projectile_spawn_offset: Vector2 = Vector2(30, -40)

var _attack_timer: float = 0.0
var _spell_timer: float = 0.0
var _is_attacking: bool = false
var _attack_anim_duration: float = 0.25

func _ready() -> void:
	if melee_hitbox:
		melee_hitbox.monitoring = false
		melee_hitbox.visible = false

func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _spell_timer > 0.0:
		_spell_timer -= delta

	if _is_attacking:
		_attack_anim_duration -= delta
		if _attack_anim_duration <= 0.0:
			end_attack()

func can_attack() -> bool:
	return _attack_timer <= 0.0 and not _is_attacking

func can_cast_spell(health_comp: HealthComponent) -> bool:
	if _is_attacking:
		return false
	var owner_node := get_parent() as Node2D
	var spellbook: SpellbookComponent = null
	if owner_node:
		spellbook = owner_node.get_node_or_null("SpellbookComponent") as SpellbookComponent
	if spellbook:
		var check := spellbook.can_cast_selected(health_comp)
		return bool(check.get("can_cast", false))
	if _spell_timer > 0.0:
		return false
	if health_comp and health_comp.current_mana < spell_mana_cost:
		return false
	return true

func perform_attack(facing_dir: int) -> bool:
	if not can_attack():
		return false

	_is_attacking = true
	_attack_timer = attack_cooldown
	_attack_anim_duration = 0.22

	if melee_hitbox:
		melee_hitbox.reset_hits()
		melee_hitbox.monitoring = true
		melee_hitbox.visible = true
		# Căn chỉnh hitbox theo hướng mặt
		melee_hitbox.position.x = abs(melee_hitbox.position.x) * float(facing_dir)

	emit_signal("attack_started")
	return true

func end_attack() -> void:
	_is_attacking = false
	if melee_hitbox:
		melee_hitbox.monitoring = false
		melee_hitbox.visible = false
	emit_signal("attack_finished")

func cast_spell(owner_node: Node2D, facing_dir: int, health_comp: HealthComponent) -> bool:
	if _is_attacking:
		return false

	var spellbook: SpellbookComponent = null
	if owner_node:
		spellbook = owner_node.get_node_or_null("SpellbookComponent") as SpellbookComponent

	if spellbook:
		var success := spellbook.cast_selected_spell(owner_node, facing_dir, health_comp)
		if success:
			emit_signal("spell_cast")
		return success

	if not can_cast_spell(health_comp):
		return false

	if health_comp:
		var success := health_comp.consume_mana(spell_mana_cost)
		if not success:
			return false

	_spell_timer = spell_cooldown

	if projectile_scene and owner_node:
		var proj := projectile_scene.instantiate() as MagicProjectile
		var spawn_pos := owner_node.global_position + Vector2(projectile_spawn_offset.x * float(facing_dir), projectile_spawn_offset.y)
		proj.global_position = spawn_pos
		proj.setup(Vector2(float(facing_dir), 0.0), owner_node)
		var spawn_root: Node = owner_node.get_parent()
		if owner_node.get_tree() and owner_node.get_tree().current_scene:
			spawn_root = owner_node.get_tree().current_scene
		if spawn_root:
			spawn_root.add_child.call_deferred(proj)

	emit_signal("spell_cast")
	return true

func is_attacking() -> bool:
	return _is_attacking

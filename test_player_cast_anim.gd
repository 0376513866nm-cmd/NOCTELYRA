extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("==================================================")
	print(" [NOCTELYRA] TESTING PLAYER CAST / SHOOTING ANIMATION")
	print("==================================================")
	
	var player_scene = load("res://src/actors/player/player.tscn")
	assert(player_scene != null, "Player scene should load")
	
	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	
	var anim_player: AnimationPlayer = player.anim_player
	assert(anim_player != null, "AnimationPlayer must exist and be initialized")
	assert(anim_player.has_animation("cast"), "AnimationPlayer must have 'cast' animation")
	assert(anim_player.has_animation("idle"), "AnimationPlayer must have 'idle' animation")
	assert(anim_player.has_animation("run"), "AnimationPlayer must have 'run' animation")
	print("  [PASS] AnimationPlayer contains idle, run, and cast animations")
	
	var sprite_root = player.sprite_root
	var cast_sprite = sprite_root.get_node("CastSprite")
	var idle_sprite = sprite_root.get_node("IdleSprite")
	var run_sprite = sprite_root.get_node("RunSprite")
	assert(cast_sprite != null, "CastSprite must exist in SpriteRoot")
	assert(cast_sprite.texture != null, "CastSprite texture must be loaded")
	assert(cast_sprite.hframes == 4 and cast_sprite.vframes == 3, "CastSprite must be 4x3 frames")
	print("  [PASS] CastSprite configured properly with 4x3 frames")
	
	# Force IDLE animation test
	anim_player.play("idle")
	anim_player.advance(0.0)
	assert(idle_sprite.visible == true, "IdleSprite should be visible in idle")
	assert(cast_sprite.visible == false, "CastSprite should not be visible in idle")
	assert(run_sprite.visible == false, "RunSprite should not be visible in idle")
	print("  [PASS] Idle animation visibility is correct")
	
	# Force RUN animation test
	anim_player.play("run")
	anim_player.advance(0.0)
	assert(run_sprite.visible == true, "RunSprite should be visible in run")
	assert(idle_sprite.visible == false, "IdleSprite should not be visible in run")
	assert(cast_sprite.visible == false, "CastSprite should not be visible in run")
	print("  [PASS] Run animation visibility is correct")
	
	# Trigger casting animation
	player.play_cast_animation()
	assert(player.cast_anim_timer > 0.0, "cast_anim_timer should be positive")
	assert(cast_sprite.visible == true, "CastSprite should be visible when casting")
	assert(idle_sprite.visible == false, "IdleSprite should be hidden when casting")
	assert(run_sprite.visible == false, "RunSprite should be hidden when casting")
	print("  [PASS] Casting animation activated and CastSprite visible")
	
	# Advance time by 0.38s to finish cast
	player.cast_anim_timer = 0.0
	player._refresh_current_animation()
	assert(cast_sprite.visible == false, "CastSprite should be hidden after cast finishes")
	print("  [PASS] Casting finishes and returns seamlessly")
	
	# Test casting interrupted by Dash
	player.play_cast_animation()
	assert(player.cast_anim_timer > 0.0, "Casting restarted")
	player._change_state(Player.State.DASH)
	assert(player.cast_anim_timer == 0.0, "Dash immediately interrupts cast_anim_timer")
	print("  [PASS] Dash correctly cancels casting timer")
	
	# Test spell casting via CombatComponent
	var combat_comp = player.combat_component
	var health_comp = player.health_component
	health_comp.current_mana = 50.0
	var cast_success = combat_comp.cast_spell(player, 1, health_comp)
	assert(cast_success == true, "Spell cast should succeed")
	assert(player.cast_anim_timer > 0.0, "CombatComponent spell_cast signal properly triggers player casting animation")
	assert(cast_sprite.visible == true, "CastSprite visible during spell cast")
	print("  [PASS] CombatComponent.cast_spell triggers cast animation via signal")
	
	# Test melee attack via CombatComponent
	var attack_sprite = sprite_root.get_node("AttackSprite")
	assert(attack_sprite != null, "AttackSprite should exist in SpriteRoot")
	var atk_success = combat_comp.perform_attack(1)
	assert(atk_success == true, "perform_attack should succeed")
	assert(player.attack_anim_timer > 0.0, "attack_anim_timer should be active")
	assert(attack_sprite.visible == true, "AttackSprite should be visible during attack")
	assert(idle_sprite.visible == false, "IdleSprite should be hidden during attack")
	print("  [PASS] CombatComponent.perform_attack triggers attack animation via signal")
	
	player.queue_free()
	print("==================================================")
	print(">>> ALL PLAYER CAST ANIMATION TESTS PASSED! <<<")
	print("==================================================")
	quit(0)

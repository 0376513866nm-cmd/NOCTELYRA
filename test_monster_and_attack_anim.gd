extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("==================================================")
	print(" [NOCTELYRA] TESTING PLAYER ATTACK & MONSTER ANIMATIONS")
	print("==================================================")
	
	# --- 1. PLAYER ATTACK ANIMATION ---
	var player_scene = load("res://src/actors/player/player.tscn")
	assert(player_scene != null, "Player scene must load")
	var player = player_scene.instantiate()
	root.add_child(player)
	await process_frame
	
	var p_anim: AnimationPlayer = player.anim_player
	assert(p_anim != null, "Player AnimationPlayer must exist")
	assert(p_anim.has_animation("attack"), "Player must have 'attack' animation")
	
	var p_sprite_root = player.sprite_root
	var atk_sprite = p_sprite_root.get_node("AttackSprite")
	assert(atk_sprite != null, "Player AttackSprite must exist in SpriteRoot")
	assert(atk_sprite.texture != null, "Player AttackSprite texture must be loaded")
	assert(atk_sprite.hframes == 5 and atk_sprite.vframes == 2, "Player AttackSprite must be 5x2 frames")
	print("  [PASS] Player AttackSprite and animation properly configured (5x2 frames)")
	
	# Test attack trigger via CombatComponent
	var combat_comp = player.combat_component
	var atk_res = combat_comp.perform_attack(1)
	assert(atk_res == true, "perform_attack should succeed")
	assert(player.attack_anim_timer > 0.0, "attack_anim_timer should be active")
	assert(atk_sprite.visible == true, "AttackSprite should be visible during attack")
	print("  [PASS] Player attack triggered and AttackSprite is visible")
	
	# Advance time by 0.3s to finish attack
	player._physics_process(0.3)
	assert(player.attack_anim_timer == 0.0, "attack_anim_timer should expire")
	assert(atk_sprite.visible == false, "AttackSprite should be hidden after attack finishes")
	print("  [PASS] Player attack completes and returns seamlessly to idle")
	player.queue_free()
	
	# --- 2. MONSTER (CORRUPTED WOLF) ANIMATIONS ---
	var enemy_scene = load("res://src/actors/enemy/enemy.tscn")
	assert(enemy_scene != null, "Enemy scene must load")
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	
	var v_root = enemy.get_node("VisualRoot")
	assert(v_root != null, "Enemy VisualRoot must exist")
	var m_sprite_root = v_root.get_node("SpriteRoot")
	assert(m_sprite_root != null, "Enemy SpriteRoot must exist in VisualRoot")
	
	var m_anim: AnimationPlayer = v_root.get_node("AnimationPlayer")
	assert(m_anim != null, "Enemy AnimationPlayer must exist in VisualRoot")
	assert(m_anim.has_animation("idle"), "Monster must have idle animation")
	assert(m_anim.has_animation("move"), "Monster must have move animation")
	assert(m_anim.has_animation("telegraph"), "Monster must have telegraph animation")
	assert(m_anim.has_animation("attack"), "Monster must have attack animation")
	assert(m_anim.has_animation("hit"), "Monster must have hit animation")
	assert(m_anim.has_animation("death"), "Monster must have death animation")
	print("  [PASS] Monster AnimationPlayer has all 6 states (idle, move, telegraph, attack, hit, death)")
	
	var idle_sp = m_sprite_root.get_node("IdleSprite")
	var move_sp = m_sprite_root.get_node("MoveSprite")
	var atkm_sp = m_sprite_root.get_node("AttackSprite")
	var hit_sp = m_sprite_root.get_node("HitSprite")
	var dth_sp = m_sprite_root.get_node("DeathSprite")
	var main_body = v_root.get_node("MainBody")
	
	# Test IDLE state
	v_root.set_visual_state("idle")
	assert(m_sprite_root.visible == true, "Monster SpriteRoot should be visible for Corrupted Wolf")
	assert(main_body.visible == false, "Placeholder MainBody should be hidden for Corrupted Wolf")
	assert(idle_sp.visible == true, "IdleSprite should be visible on idle")
	print("  [PASS] Monster displays IdleSprite on 'idle' with placeholder hidden")
	
	# Test MOVE state
	v_root.set_visual_state("move")
	assert(move_sp.visible == true, "MoveSprite should be visible on move")
	assert(idle_sp.visible == false, "IdleSprite should be hidden on move")
	print("  [PASS] Monster switches to MoveSprite on 'move'")
	
	# Test ATTACK state
	v_root.set_visual_state("attack")
	assert(atkm_sp.visible == true, "AttackSprite should be visible on attack")
	assert(move_sp.visible == false, "MoveSprite should be hidden on attack")
	print("  [PASS] Monster switches to AttackSprite on 'attack'")
	
	# Test HIT state
	v_root.set_visual_state("hit")
	assert(hit_sp.visible == true, "HitSprite should be visible on hit")
	assert(atkm_sp.visible == false, "AttackSprite should be hidden on hit")
	print("  [PASS] Monster switches to HitSprite on 'hit'")
	
	# Test DEATH state
	v_root.set_visual_state("death")
	assert(dth_sp.visible == true, "DeathSprite should be visible on death")
	assert(hit_sp.visible == false, "HitSprite should be hidden on death")
	print("  [PASS] Monster switches to DeathSprite on 'death'")
	
	# Test other monster types fallback (e.g. corrupted_mooncap)
	v_root.apply_type_style("corrupted_mooncap")
	assert(m_sprite_root.visible == false, "SpriteRoot should be hidden for other monster types")
	assert(main_body.visible == true, "MainBody placeholder should be visible for other monster types")
	print("  [PASS] Non-wolf enemy types safely fallback to customized placeholder visuals")
	
	enemy.queue_free()
	print("==================================================")
	print(">>> ALL PLAYER ATTACK & MONSTER ANIM TESTS PASSED! <<<")
	print("==================================================")
	quit(0)

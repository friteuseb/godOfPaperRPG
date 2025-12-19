extends Node
## Battle Manager - Gère le système de combat tour par tour

signal battle_started(party: Array, enemies: Array)
signal battle_ended(victory: bool, rewards: Dictionary)
signal turn_started(character: Character)
signal turn_ended(character: Character)
signal action_executed(action: BattleAction)
signal damage_dealt(target: Character, amount: int, is_critical: bool)
signal character_died(character: Character)
signal message_displayed(message: String)

enum BattleState { INACTIVE, STARTING, PLAYER_TURN, ENEMY_TURN, EXECUTING_ACTION, VICTORY, DEFEAT }

var current_state: BattleState = BattleState.INACTIVE
var party: Array[Character] = []
var enemies: Array[Character] = []
var turn_order: Array[Character] = []
var current_turn_index: int = 0
var current_character: Character

var pending_action: BattleAction
var battle_log: Array[String] = []

# Récompenses accumulées
var total_exp: int = 0
var total_gold: int = 0
var loot: Array = []

func start_battle(party_members: Array[Character], enemy_group: Array[Character]) -> void:
	party = party_members
	enemies = enemy_group
	current_state = BattleState.STARTING

	total_exp = 0
	total_gold = 0
	loot.clear()
	battle_log.clear()

	# Calculer les récompenses potentielles
	for enemy in enemies:
		if enemy.has_meta("exp_reward"):
			total_exp += enemy.get_meta("exp_reward")
		else:
			total_exp += enemy.level * 20

		if enemy.has_meta("gold_reward"):
			total_gold += enemy.get_meta("gold_reward")
		else:
			total_gold += enemy.level * 10

	_log_message("Le combat commence !")
	battle_started.emit(party, enemies)

	# Petit délai avant de commencer
	await get_tree().create_timer(0.5).timeout
	_calculate_turn_order()
	_start_next_turn()

func _calculate_turn_order() -> void:
	turn_order.clear()

	# Combiner tous les combattants vivants
	var all_fighters: Array[Character] = []
	for p in party:
		if p.is_alive():
			all_fighters.append(p)
	for e in enemies:
		if e.is_alive():
			all_fighters.append(e)

	# Trier par vitesse (décroissant)
	all_fighters.sort_custom(func(a, b): return a.speed > b.speed)
	turn_order = all_fighters
	current_turn_index = 0

func _start_next_turn() -> void:
	# Vérifier les conditions de fin de combat
	if _check_battle_end():
		return

	# Trouver le prochain personnage vivant
	while current_turn_index < turn_order.size():
		current_character = turn_order[current_turn_index]
		if current_character.is_alive():
			break
		current_turn_index += 1

	# Si on a fait le tour, recalculer l'ordre
	if current_turn_index >= turn_order.size():
		_calculate_turn_order()
		if turn_order.is_empty():
			return
		current_character = turn_order[0]

	# Traiter les effets de statut au début du tour
	var status_messages = current_character.process_status_effects()
	for msg in status_messages:
		_log_message(msg)

	# Vérifier si le personnage peut agir
	var can_act = true
	for effect in current_character.status_effects:
		if not effect.can_act():
			can_act = false
			_log_message("%s est paralysé et ne peut pas agir !" % current_character.character_name)
			break

	turn_started.emit(current_character)

	if not can_act:
		await get_tree().create_timer(0.5).timeout
		_end_current_turn()
		return

	# Déterminer si c'est le tour du joueur ou de l'ennemi
	if current_character in party:
		current_state = BattleState.PLAYER_TURN
		# Attendre l'action du joueur via l'UI
	else:
		current_state = BattleState.ENEMY_TURN
		await get_tree().create_timer(0.3).timeout
		_execute_enemy_ai()

func _end_current_turn() -> void:
	turn_ended.emit(current_character)
	current_turn_index += 1
	_start_next_turn()

func _check_battle_end() -> bool:
	var party_alive = false
	for p in party:
		if p.is_alive():
			party_alive = true
			break

	var enemies_alive = false
	for e in enemies:
		if e.is_alive():
			enemies_alive = true
			break

	if not enemies_alive:
		_end_battle(true)
		return true
	elif not party_alive:
		_end_battle(false)
		return true

	return false

func _end_battle(victory: bool) -> void:
	if victory:
		current_state = BattleState.VICTORY
		_log_message("Victoire !")

		# Distribuer l'expérience
		var alive_members = GameManager.get_party_alive()
		var exp_per_member = total_exp / max(1, alive_members.size())

		for member in alive_members:
			member.add_experience(exp_per_member)

		GameManager.add_gold(total_gold)
		GameManager.stats.battles_won += 1
		GameManager.stats.enemies_defeated += enemies.size()

	else:
		current_state = BattleState.DEFEAT
		_log_message("Défaite...")
		GameManager.stats.battles_lost += 1

	var rewards = {
		"victory": victory,
		"exp": total_exp,
		"gold": total_gold,
		"loot": loot
	}

	battle_ended.emit(victory, rewards)

## Exécuter une action de combat
func execute_action(action: BattleAction) -> void:
	if current_state != BattleState.PLAYER_TURN and current_state != BattleState.ENEMY_TURN:
		return

	current_state = BattleState.EXECUTING_ACTION
	pending_action = action

	# Consommer le mana si nécessaire
	if action.skill and action.skill.mp_cost > 0:
		action.user.use_mana(action.skill.mp_cost)

	# Log de l'action
	var action_name = action.skill.skill_name if action.skill else "Attaque"
	_log_message("%s utilise %s !" % [action.user.character_name, action_name])

	action_executed.emit(action)

	# Attendre l'animation
	await get_tree().create_timer(0.3).timeout

	# Appliquer les effets
	_apply_action_effects(action)

	await get_tree().create_timer(0.5).timeout
	_end_current_turn()

func _apply_action_effects(action: BattleAction) -> void:
	var skill = action.skill
	if not skill:
		# Attaque basique
		_apply_basic_attack(action.user, action.targets[0])
		return

	match skill.damage_type:
		Skill.DamageType.PHYSICAL, Skill.DamageType.MAGICAL:
			for target in action.targets:
				_apply_damage(action.user, target, skill)
		Skill.DamageType.HEALING:
			for target in action.targets:
				_apply_healing(action.user, target, skill)
		Skill.DamageType.TRUE:
			for target in action.targets:
				var damage = skill.base_power
				target.take_damage(damage, false, true)
				_log_message("%s subit %d dégâts !" % [target.character_name, damage])
				damage_dealt.emit(target, damage, false)
				_check_death(target)

func _apply_basic_attack(user: Character, target: Character) -> void:
	var is_critical = randf() < user.critical_chance
	var base_damage = user.attack + (user.level * 2)

	if is_critical:
		base_damage = int(base_damage * 1.5)

	var result = target.take_damage(base_damage, false)

	if result.dodged:
		_log_message("%s esquive l'attaque !" % target.character_name)
	else:
		var msg = "%s subit %d dégâts" % [target.character_name, result.damage]
		if is_critical:
			msg += " (CRITIQUE !)"
		_log_message(msg + " !")

		damage_dealt.emit(target, result.damage, is_critical)
		GameManager.stats.total_damage_dealt += result.damage

		_check_death(target)

func _apply_damage(user: Character, target: Character, skill: Skill) -> void:
	var is_critical = randf() < user.critical_chance
	var damage = skill.calculate_damage(user, target)

	if is_critical:
		damage = int(damage * 1.5)

	var is_magical = skill.damage_type == Skill.DamageType.MAGICAL
	var result = target.take_damage(damage, is_magical)

	if result.dodged:
		_log_message("%s esquive %s !" % [target.character_name, skill.skill_name])
	else:
		var msg = "%s subit %d dégâts" % [target.character_name, result.damage]
		if is_critical:
			msg += " (CRITIQUE !)"
		_log_message(msg + " !")

		damage_dealt.emit(target, result.damage, is_critical)
		GameManager.stats.total_damage_dealt += result.damage

		# Appliquer l'effet de statut
		if skill.status_effect and randf() < skill.status_chance:
			var effect = skill.status_effect.duplicate_effect()
			target.add_status_effect(effect)
			_log_message("%s est affecté par %s !" % [target.character_name, effect.effect_name])

		_check_death(target)

func _apply_healing(user: Character, target: Character, skill: Skill) -> void:
	var heal_amount = skill.calculate_healing(user)
	var actual_heal = target.heal(heal_amount)
	_log_message("%s récupère %d HP !" % [target.character_name, actual_heal])

func _check_death(character: Character) -> void:
	if not character.is_alive():
		_log_message("%s est vaincu !" % character.character_name)
		character_died.emit(character)

func _execute_enemy_ai() -> void:
	# IA simple : attaque aléatoire sur un membre du groupe
	var alive_party = GameManager.get_party_alive()
	if alive_party.is_empty():
		return

	var target = alive_party[randi() % alive_party.size()]

	# Choisir une compétence ou attaque de base
	var skill_to_use: Skill = null

	if current_character.skills.size() > 0 and randf() < 0.6:
		# 60% de chance d'utiliser une compétence
		var usable_skills: Array[Skill] = []
		for s in current_character.skills:
			if current_character.can_use_skill(s):
				usable_skills.append(s)

		if usable_skills.size() > 0:
			skill_to_use = usable_skills[randi() % usable_skills.size()]

	var action = BattleAction.new()
	action.user = current_character
	action.skill = skill_to_use
	action.targets = [target]

	# Si la compétence cible tous les ennemis
	if skill_to_use and skill_to_use.target_type == Skill.TargetType.ALL_ENEMIES:
		action.targets = alive_party.duplicate()

	execute_action(action)

func _log_message(msg: String) -> void:
	battle_log.append(msg)
	message_displayed.emit(msg)
	print("[Battle] %s" % msg)

## Obtenir les cibles valides pour une compétence
func get_valid_targets(skill: Skill) -> Array[Character]:
	var targets: Array[Character] = []

	match skill.target_type:
		Skill.TargetType.SINGLE_ENEMY, Skill.TargetType.ALL_ENEMIES:
			for e in enemies:
				if e.is_alive():
					targets.append(e)
		Skill.TargetType.SINGLE_ALLY, Skill.TargetType.ALL_ALLIES:
			for p in party:
				if p.is_alive():
					targets.append(p)
		Skill.TargetType.SELF:
			targets.append(current_character)

	return targets

func get_current_character() -> Character:
	return current_character

func is_player_turn() -> bool:
	return current_state == BattleState.PLAYER_TURN

func is_battle_active() -> bool:
	return current_state != BattleState.INACTIVE and current_state != BattleState.VICTORY and current_state != BattleState.DEFEAT

func flee_battle() -> bool:
	# 50% de chance de fuite de base, modifié par la vitesse
	var avg_party_speed = 0.0
	var avg_enemy_speed = 0.0

	for p in party:
		avg_party_speed += p.speed
	avg_party_speed /= party.size()

	for e in enemies:
		avg_enemy_speed += e.speed
	avg_enemy_speed /= enemies.size()

	var flee_chance = 0.5 + (avg_party_speed - avg_enemy_speed) * 0.02
	flee_chance = clamp(flee_chance, 0.1, 0.9)

	if randf() < flee_chance:
		_log_message("Vous avez fui le combat !")
		current_state = BattleState.INACTIVE
		battle_ended.emit(false, {"fled": true})
		return true
	else:
		_log_message("Impossible de fuir !")
		_end_current_turn()
		return false

extends Resource
class_name Character
## Classe de base pour tous les personnages (joueurs et ennemis)

signal hp_changed(current_hp: int, max_hp: int)
signal mp_changed(current_mp: int, max_mp: int)
signal died()
signal leveled_up(new_level: int)
signal status_effect_added(effect: StatusEffect)
signal status_effect_removed(effect: StatusEffect)

@export var character_name: String = "Adventurer"
@export var character_class: CharacterClass
@export var level: int = 1
@export var experience: int = 0

# Stats de base
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_mp: int = 50
@export var current_mp: int = 50

# Attributs principaux
@export var strength: int = 10      # Dégâts physiques
@export var intelligence: int = 10  # Dégâts magiques et mana
@export var dexterity: int = 10     # Précision, esquive, vitesse
@export var constitution: int = 10  # HP et résistance
@export var luck: int = 10          # Critiques, drops, événements

# Stats dérivées (calculées)
var attack: int:
	get: return strength + (level * 2) + _get_equipment_bonus("attack")
var defense: int:
	get: return constitution + (level * 1) + _get_equipment_bonus("defense")
var magic_attack: int:
	get: return intelligence + (level * 2) + _get_equipment_bonus("magic_attack")
var magic_defense: int:
	get: return (intelligence + constitution) / 2 + _get_equipment_bonus("magic_defense")
var speed: int:
	get: return dexterity + _get_equipment_bonus("speed")
var critical_chance: float:
	get: return 0.05 + (luck * 0.005) + _get_equipment_bonus("critical_chance")
var dodge_chance: float:
	get: return 0.02 + (dexterity * 0.003) + _get_equipment_bonus("dodge_chance")

# Équipement
@export var equipment: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null
}

# Compétences apprises
@export var skills: Array[Skill] = []

# Effets de statut actifs
var status_effects: Array[StatusEffect] = []

# Référence visuelle
@export var sprite_name: String = "default_hero"
@export var portrait_name: String = "default_portrait"

func _init() -> void:
	pass

func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int, is_magical: bool = false, ignore_defense: bool = false) -> Dictionary:
	var result = {
		"damage": 0,
		"dodged": false,
		"blocked": false,
		"killed": false
	}

	# Vérifier l'esquive
	if randf() < dodge_chance:
		result.dodged = true
		return result

	# Calculer la réduction de dégâts
	var reduction = 0
	if not ignore_defense:
		if is_magical:
			reduction = magic_defense * 0.5
		else:
			reduction = defense * 0.5

	var final_damage = max(1, amount - int(reduction))
	current_hp = max(0, current_hp - final_damage)
	result.damage = final_damage

	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		result.killed = true
		died.emit()

	return result

func heal(amount: int) -> int:
	var actual_heal = min(amount, max_hp - current_hp)
	current_hp += actual_heal
	hp_changed.emit(current_hp, max_hp)
	return actual_heal

func restore_mana(amount: int) -> int:
	var actual_restore = min(amount, max_mp - current_mp)
	current_mp += actual_restore
	mp_changed.emit(current_mp, max_mp)
	return actual_restore

func use_mana(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		mp_changed.emit(current_mp, max_mp)
		return true
	return false

func can_use_skill(skill: Skill) -> bool:
	return current_mp >= skill.mp_cost and is_alive()

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= get_exp_for_next_level():
		level_up()

func get_exp_for_next_level() -> int:
	# Formule simple: 100 * niveau^1.5
	return int(100 * pow(level, 1.5))

func level_up() -> void:
	experience -= get_exp_for_next_level()
	level += 1

	# Augmentation des stats selon la classe
	if character_class:
		max_hp += character_class.hp_growth
		max_mp += character_class.mp_growth
		strength += character_class.str_growth
		intelligence += character_class.int_growth
		dexterity += character_class.dex_growth
		constitution += character_class.con_growth
		luck += character_class.luk_growth
	else:
		# Croissance par défaut
		max_hp += 10
		max_mp += 5
		strength += 2
		intelligence += 2
		dexterity += 2
		constitution += 2
		luck += 1

	# Full heal on level up
	current_hp = max_hp
	current_mp = max_mp

	# Apprendre de nouvelles compétences
	if character_class:
		for skill_data in character_class.learnable_skills:
			if skill_data.level == level and not skills.has(skill_data.skill):
				skills.append(skill_data.skill)

	leveled_up.emit(level)

func add_status_effect(effect: StatusEffect) -> void:
	# Vérifier si l'effet existe déjà
	for existing in status_effects:
		if existing.effect_name == effect.effect_name:
			# Rafraîchir la durée
			existing.duration = effect.duration
			return

	status_effects.append(effect)
	effect.apply(self)
	status_effect_added.emit(effect)

func remove_status_effect(effect: StatusEffect) -> void:
	effect.remove(self)
	status_effects.erase(effect)
	status_effect_removed.emit(effect)

func process_status_effects() -> Array[String]:
	var messages: Array[String] = []
	var to_remove: Array[StatusEffect] = []

	for effect in status_effects:
		var msg = effect.tick(self)
		if msg != "":
			messages.append(msg)

		effect.duration -= 1
		if effect.duration <= 0:
			to_remove.append(effect)

	for effect in to_remove:
		remove_status_effect(effect)
		messages.append("%s: %s s'est dissipé" % [character_name, effect.effect_name])

	return messages

func clear_status_effects() -> void:
	for effect in status_effects.duplicate():
		remove_status_effect(effect)

func _get_equipment_bonus(stat: String) -> float:
	var bonus = 0.0
	for slot in equipment:
		var item = equipment[slot]
		if item and item is Equipment:
			bonus += item.get_stat_bonus(stat)
	return bonus

func equip(item: Equipment) -> Equipment:
	var old_item = equipment[item.slot]
	equipment[item.slot] = item
	_recalculate_stats()
	return old_item

func unequip(slot: String) -> Equipment:
	var item = equipment[slot]
	equipment[slot] = null
	_recalculate_stats()
	return item

func _recalculate_stats() -> void:
	# Recalculer les HP/MP max avec l'équipement
	var hp_bonus = int(_get_equipment_bonus("max_hp"))
	var mp_bonus = int(_get_equipment_bonus("max_mp"))

	max_hp = (constitution * 5) + (level * 10) + hp_bonus
	max_mp = (intelligence * 3) + (level * 5) + mp_bonus

	current_hp = min(current_hp, max_hp)
	current_mp = min(current_mp, max_mp)

func to_dict() -> Dictionary:
	var skills_data = []
	for skill in skills:
		skills_data.append(skill.resource_path)

	var equipment_data = {}
	for slot in equipment:
		if equipment[slot]:
			equipment_data[slot] = equipment[slot].resource_path

	return {
		"name": character_name,
		"class_path": character_class.resource_path if character_class else "",
		"level": level,
		"experience": experience,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"max_mp": max_mp,
		"current_mp": current_mp,
		"strength": strength,
		"intelligence": intelligence,
		"dexterity": dexterity,
		"constitution": constitution,
		"luck": luck,
		"skills": skills_data,
		"equipment": equipment_data,
		"sprite_name": sprite_name,
		"portrait_name": portrait_name
	}

static func from_dict(data: Dictionary) -> Character:
	var character = Character.new()
	character.character_name = data.name
	character.level = data.level
	character.experience = data.experience
	character.max_hp = data.max_hp
	character.current_hp = data.current_hp
	character.max_mp = data.max_mp
	character.current_mp = data.current_mp
	character.strength = data.strength
	character.intelligence = data.intelligence
	character.dexterity = data.dexterity
	character.constitution = data.constitution
	character.luck = data.luck
	character.sprite_name = data.get("sprite_name", "default_hero")
	character.portrait_name = data.get("portrait_name", "default_portrait")

	if data.class_path != "":
		character.character_class = load(data.class_path)

	for skill_path in data.skills:
		if ResourceLoader.exists(skill_path):
			character.skills.append(load(skill_path))

	for slot in data.equipment:
		if data.equipment[slot]:
			character.equipment[slot] = load(data.equipment[slot])

	return character

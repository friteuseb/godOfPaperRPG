extends Resource
class_name Skill
## Définit une compétence utilisable en combat

enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }
enum DamageType { PHYSICAL, MAGICAL, TRUE, HEALING }
enum Element { NONE, FIRE, ICE, LIGHTNING, EARTH, LIGHT, DARK }

@export var skill_name: String = "Attack"
@export_multiline var description: String = "Une attaque basique."
@export var icon: Texture2D

@export var mp_cost: int = 0
@export var cooldown: int = 0  # Tours avant réutilisation

@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var element: Element = Element.NONE

# Formule de dégâts
@export var base_power: int = 100  # Puissance de base (100 = dégâts normaux)
@export var scaling_stat: String = "strength"  # Stat qui scale (strength, intelligence, dexterity)
@export var scaling_ratio: float = 1.0  # Multiplicateur de la stat

# Effets additionnels
@export var status_effect: StatusEffect
@export var status_chance: float = 0.0  # Chance d'appliquer l'effet (0.0 - 1.0)

# Animation
@export var animation_name: String = "slash"
@export var hit_sound: String = "battle_hit"

func calculate_damage(user: Character, target: Character) -> int:
	# Calculer les degats de base depuis les stats
	var stat_damage: float = 0.0
	match scaling_stat:
		"strength":
			stat_damage = user.strength * scaling_ratio
		"intelligence":
			stat_damage = user.intelligence * scaling_ratio
		"dexterity":
			stat_damage = user.dexterity * scaling_ratio * 0.8
		_:
			stat_damage = user.strength * 0.5

	# Ajouter bonus de niveau
	stat_damage += user.level * 2

	# Appliquer le modificateur de puissance (base_power / 100)
	# 100 = 100% des degats, 150 = 150% des degats
	var power_modifier: float = base_power / 100.0
	var base_damage: int = int(stat_damage * power_modifier)

	# Reduction par la defense cible
	var defense: float = 0.0
	if damage_type == DamageType.PHYSICAL:
		defense = target.defense
	elif damage_type == DamageType.MAGICAL:
		defense = target.magic_defense

	# La defense reduit un pourcentage des degats (diminishing returns)
	var defense_reduction: float = defense / (defense + 50.0)
	var final_damage: int = int(base_damage * (1.0 - defense_reduction * 0.5))
	final_damage = max(1, final_damage)

	# Variation aleatoire (90% - 110%)
	final_damage = int(final_damage * randf_range(0.9, 1.1))

	return final_damage

func calculate_healing(user: Character) -> int:
	# Soin de base depuis les stats
	var stat_heal: float = 0.0
	match scaling_stat:
		"intelligence":
			stat_heal = user.intelligence * scaling_ratio
		"constitution":
			stat_heal = user.constitution * scaling_ratio * 0.8
		_:
			stat_heal = user.intelligence * 0.5

	# Bonus de niveau
	stat_heal += user.level * 3

	# Appliquer le modificateur de puissance
	var power_modifier: float = base_power / 100.0
	var base_heal: int = int(stat_heal * power_modifier)

	# Variation aleatoire
	base_heal = int(base_heal * randf_range(0.95, 1.05))

	return max(1, base_heal)

func get_description_with_values(user: Character) -> String:
	var desc = description
	desc = desc.replace("{power}", str(base_power))
	desc = desc.replace("{mp}", str(mp_cost))
	return desc

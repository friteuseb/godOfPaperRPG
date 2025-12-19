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
	var base_damage = base_power

	# Ajouter le scaling de la stat
	match scaling_stat:
		"strength":
			base_damage += int(user.strength * scaling_ratio * 2)
		"intelligence":
			base_damage += int(user.intelligence * scaling_ratio * 2)
		"dexterity":
			base_damage += int(user.dexterity * scaling_ratio * 1.5)

	# Modificateur de niveau
	base_damage += user.level * 3

	# Réduction par la défense cible
	var defense = 0
	if damage_type == DamageType.PHYSICAL:
		defense = target.defense
	elif damage_type == DamageType.MAGICAL:
		defense = target.magic_defense

	var final_damage = max(1, base_damage - int(defense * 0.5))

	# Variation aléatoire (90% - 110%)
	final_damage = int(final_damage * randf_range(0.9, 1.1))

	return final_damage

func calculate_healing(user: Character) -> int:
	var base_heal = base_power

	match scaling_stat:
		"intelligence":
			base_heal += int(user.intelligence * scaling_ratio * 2)
		"constitution":
			base_heal += int(user.constitution * scaling_ratio * 1.5)

	base_heal += user.level * 2

	# Variation aléatoire
	base_heal = int(base_heal * randf_range(0.95, 1.05))

	return base_heal

func get_description_with_values(user: Character) -> String:
	var desc = description
	desc = desc.replace("{power}", str(base_power))
	desc = desc.replace("{mp}", str(mp_cost))
	return desc

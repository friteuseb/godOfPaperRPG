extends Resource
class_name StatusEffect
## Effet de statut pouvant être appliqué aux personnages

enum EffectType { BUFF, DEBUFF, DOT, HOT, STUN, OTHER }

@export var effect_name: String = "Poison"
@export_multiline var description: String = "Inflige des dégâts chaque tour."
@export var icon: Texture2D

@export var effect_type: EffectType = EffectType.DOT
@export var duration: int = 3  # Nombre de tours

# Modificateurs de stats (en pourcentage, 0.1 = +10%, -0.2 = -20%)
@export var attack_modifier: float = 0.0
@export var defense_modifier: float = 0.0
@export var magic_attack_modifier: float = 0.0
@export var magic_defense_modifier: float = 0.0
@export var speed_modifier: float = 0.0

# Dégâts/Soins par tour
@export var damage_per_turn: int = 0  # Dégâts fixes par tour
@export var damage_percent: float = 0.0  # Dégâts en % des HP max
@export var heal_per_turn: int = 0
@export var heal_percent: float = 0.0

# Effets spéciaux
@export var prevents_action: bool = false  # Stun, paralysie
@export var prevents_magic: bool = false  # Silence

# Valeurs temporaires stockées lors de l'application
var stored_attack_bonus: int = 0
var stored_defense_bonus: int = 0

func apply(target: Character) -> void:
	# Appliquer les modificateurs de stats
	if attack_modifier != 0:
		stored_attack_bonus = int(target.strength * attack_modifier)
		target.strength += stored_attack_bonus

	if defense_modifier != 0:
		stored_defense_bonus = int(target.constitution * defense_modifier)
		target.constitution += stored_defense_bonus

func remove(target: Character) -> void:
	# Retirer les modificateurs
	target.strength -= stored_attack_bonus
	target.constitution -= stored_defense_bonus
	stored_attack_bonus = 0
	stored_defense_bonus = 0

func tick(target: Character) -> String:
	var message = ""

	# Dégâts par tour
	if damage_per_turn > 0 or damage_percent > 0:
		var damage = damage_per_turn
		if damage_percent > 0:
			damage += int(target.max_hp * damage_percent)

		target.take_damage(damage, false, true)
		message = "%s subit %d dégâts de %s" % [target.character_name, damage, effect_name]

	# Soins par tour
	if heal_per_turn > 0 or heal_percent > 0:
		var heal = heal_per_turn
		if heal_percent > 0:
			heal += int(target.max_hp * heal_percent)

		target.heal(heal)
		message = "%s récupère %d HP grâce à %s" % [target.character_name, heal, effect_name]

	return message

func can_act() -> bool:
	return not prevents_action

func can_use_magic() -> bool:
	return not prevents_magic

func duplicate_effect() -> StatusEffect:
	var copy = StatusEffect.new()
	copy.effect_name = effect_name
	copy.description = description
	copy.icon = icon
	copy.effect_type = effect_type
	copy.duration = duration
	copy.attack_modifier = attack_modifier
	copy.defense_modifier = defense_modifier
	copy.magic_attack_modifier = magic_attack_modifier
	copy.magic_defense_modifier = magic_defense_modifier
	copy.speed_modifier = speed_modifier
	copy.damage_per_turn = damage_per_turn
	copy.damage_percent = damage_percent
	copy.heal_per_turn = heal_per_turn
	copy.heal_percent = heal_percent
	copy.prevents_action = prevents_action
	copy.prevents_magic = prevents_magic
	return copy

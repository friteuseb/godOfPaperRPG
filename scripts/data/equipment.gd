extends Item
class_name Equipment
## Équipement (armes, armures, accessoires)

enum EquipmentSlot { WEAPON, ARMOR, ACCESSORY }
enum WeaponType { SWORD, AXE, STAFF, BOW, DAGGER, MACE }
enum ArmorType { LIGHT, MEDIUM, HEAVY, ROBE }

@export var slot: String = "weapon"  # weapon, armor, accessory
@export var weapon_type: WeaponType = WeaponType.SWORD
@export var armor_type: ArmorType = ArmorType.MEDIUM

# Bonus de stats
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var magic_attack_bonus: int = 0
@export var magic_defense_bonus: int = 0
@export var speed_bonus: int = 0
@export var max_hp_bonus: int = 0
@export var max_mp_bonus: int = 0
@export var critical_chance_bonus: float = 0.0
@export var dodge_chance_bonus: float = 0.0

# Effets spéciaux
@export var special_effect: StatusEffect
@export var element: Skill.Element = Skill.Element.NONE

# Restrictions
@export var required_level: int = 1
@export var required_classes: Array[String] = []  # Vide = toutes les classes

func _init() -> void:
	item_type = ItemType.EQUIPMENT
	stackable = false
	max_stack = 1

func get_stat_bonus(stat: String) -> float:
	match stat:
		"attack": return attack_bonus
		"defense": return defense_bonus
		"magic_attack": return magic_attack_bonus
		"magic_defense": return magic_defense_bonus
		"speed": return speed_bonus
		"max_hp": return max_hp_bonus
		"max_mp": return max_mp_bonus
		"critical_chance": return critical_chance_bonus
		"dodge_chance": return dodge_chance_bonus
	return 0.0

func can_equip(character: Character) -> bool:
	if character.level < required_level:
		return false

	if required_classes.size() > 0 and character.character_class:
		if not required_classes.has(character.character_class.display_name):
			return false

	return true

func get_tooltip() -> String:
	var tooltip = "%s\n%s\n" % [item_name, description]

	if attack_bonus != 0:
		tooltip += "ATK +%d\n" % attack_bonus
	if defense_bonus != 0:
		tooltip += "DEF +%d\n" % defense_bonus
	if magic_attack_bonus != 0:
		tooltip += "M.ATK +%d\n" % magic_attack_bonus
	if magic_defense_bonus != 0:
		tooltip += "M.DEF +%d\n" % magic_defense_bonus
	if speed_bonus != 0:
		tooltip += "SPD +%d\n" % speed_bonus
	if max_hp_bonus != 0:
		tooltip += "HP +%d\n" % max_hp_bonus
	if max_mp_bonus != 0:
		tooltip += "MP +%d\n" % max_mp_bonus

	tooltip += "Prix: %d or" % price
	return tooltip

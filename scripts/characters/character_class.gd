extends Resource
class_name CharacterClass
## Définit une classe de personnage avec ses statistiques et compétences

@export var display_name: String = "Warrior"
@export var description: String = "Un combattant au corps à corps spécialisé dans les attaques physiques."
@export var icon: Texture2D

# Stats de base à la création
@export var base_hp: int = 120
@export var base_mp: int = 30
@export var base_strength: int = 14
@export var base_intelligence: int = 8
@export var base_dexterity: int = 10
@export var base_constitution: int = 12
@export var base_luck: int = 8

# Croissance par niveau
@export var hp_growth: int = 15
@export var mp_growth: int = 3
@export var str_growth: int = 3
@export var int_growth: int = 1
@export var dex_growth: int = 2
@export var con_growth: int = 2
@export var luk_growth: int = 1

# Compétences apprises par niveau
@export var learnable_skills: Array[LearnableSkill] = []

# Types d'armes utilisables
@export var usable_weapon_types: Array[String] = ["sword", "axe"]
@export var usable_armor_types: Array[String] = ["heavy", "medium"]

func create_character(name: String) -> Character:
	var character = Character.new()
	character.character_name = name
	character.character_class = self

	character.max_hp = base_hp
	character.current_hp = base_hp
	character.max_mp = base_mp
	character.current_mp = base_mp
	character.strength = base_strength
	character.intelligence = base_intelligence
	character.dexterity = base_dexterity
	character.constitution = base_constitution
	character.luck = base_luck

	# Ajouter les compétences de niveau 1
	for skill_data in learnable_skills:
		if skill_data.level <= 1:
			character.skills.append(skill_data.skill)

	return character

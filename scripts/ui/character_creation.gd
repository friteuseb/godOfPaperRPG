extends Control
## Ecran de creation de personnage - Style Knights of Pen and Paper

@onready var party_list: VBoxContainer = $TableLayer/PartyPanel/VBox/PartyList
@onready var class_list: VBoxContainer = $TableLayer/ClassPanel/VBox/ClassScroll/ClassList
@onready var name_input: LineEdit = $TableLayer/ClassPanel/VBox/NameInput/LineEdit
@onready var party_label: Label = $TableLayer/PartyPanel/VBox/Label
@onready var start_button: Button = $StartButton
@onready var add_button: Button = $TableLayer/ClassPanel/VBox/AddButton

var selected_class: CharacterClass = null
var class_buttons: Array[Button] = []

# Classes par défaut (seront chargées depuis les ressources)
var default_classes: Array[CharacterClass] = []

func _ready() -> void:
	_create_default_classes()
	_populate_class_list()
	_update_party_display()
	start_button.disabled = true

func _create_default_classes() -> void:
	# Guerrier
	var warrior = CharacterClass.new()
	warrior.display_name = "Guerrier"
	warrior.description = "Un combattant robuste spécialisé dans les attaques physiques et la défense."
	warrior.base_hp = 120
	warrior.base_mp = 30
	warrior.base_strength = 14
	warrior.base_intelligence = 8
	warrior.base_dexterity = 10
	warrior.base_constitution = 12
	warrior.base_luck = 8
	warrior.hp_growth = 15
	warrior.mp_growth = 3
	warrior.str_growth = 3
	warrior.int_growth = 1
	warrior.dex_growth = 2
	warrior.con_growth = 2
	warrior.luk_growth = 1
	default_classes.append(warrior)

	# Mage
	var mage = CharacterClass.new()
	mage.display_name = "Mage"
	mage.description = "Un lanceur de sorts puissant mais fragile, maîtrisant les arts arcanes."
	mage.base_hp = 70
	mage.base_mp = 100
	mage.base_strength = 6
	mage.base_intelligence = 16
	mage.base_dexterity = 8
	mage.base_constitution = 7
	mage.base_luck = 10
	mage.hp_growth = 8
	mage.mp_growth = 12
	mage.str_growth = 1
	mage.int_growth = 4
	mage.dex_growth = 1
	mage.con_growth = 1
	mage.luk_growth = 2
	default_classes.append(mage)

	# Voleur
	var rogue = CharacterClass.new()
	rogue.display_name = "Voleur"
	rogue.description = "Un combattant agile excellant dans les attaques rapides et les coups critiques."
	rogue.base_hp = 85
	rogue.base_mp = 50
	rogue.base_strength = 10
	rogue.base_intelligence = 10
	rogue.base_dexterity = 16
	rogue.base_constitution = 8
	rogue.base_luck = 14
	rogue.hp_growth = 10
	rogue.mp_growth = 5
	rogue.str_growth = 2
	rogue.int_growth = 2
	rogue.dex_growth = 4
	rogue.con_growth = 1
	rogue.luk_growth = 3
	default_classes.append(rogue)

	# Clerc
	var cleric = CharacterClass.new()
	cleric.display_name = "Clerc"
	cleric.description = "Un guérisseur sacré capable de soigner ses alliés et de repousser les ténèbres."
	cleric.base_hp = 90
	cleric.base_mp = 80
	cleric.base_strength = 8
	cleric.base_intelligence = 14
	cleric.base_dexterity = 8
	cleric.base_constitution = 10
	cleric.base_luck = 12
	cleric.hp_growth = 12
	cleric.mp_growth = 10
	cleric.str_growth = 1
	cleric.int_growth = 3
	cleric.dex_growth = 1
	cleric.con_growth = 2
	cleric.luk_growth = 2
	default_classes.append(cleric)

func _populate_class_list() -> void:
	for child in class_list.get_children():
		child.queue_free()

	class_buttons.clear()

	for char_class in default_classes:
		var button = Button.new()
		button.text = char_class.display_name
		button.custom_minimum_size = Vector2(0, 60)
		button.toggle_mode = true
		button.button_group = _get_or_create_button_group()

		var vbox = VBoxContainer.new()
		var name_label = Label.new()
		name_label.text = char_class.display_name
		var desc_label = Label.new()
		desc_label.text = char_class.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		button.pressed.connect(_on_class_selected.bind(char_class))
		class_list.add_child(button)
		class_buttons.append(button)

		# Ajouter description sous le bouton (style parchemin)
		var desc = Label.new()
		desc.text = char_class.description
		desc.add_theme_font_size_override("font_size", 10)
		desc.add_theme_color_override("font_color", Color(0.55, 0.45, 0.35, 1))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		class_list.add_child(desc)

var _button_group: ButtonGroup = null

func _get_or_create_button_group() -> ButtonGroup:
	if not _button_group:
		_button_group = ButtonGroup.new()
	return _button_group

func _on_class_selected(char_class: CharacterClass) -> void:
	selected_class = char_class
	AudioManager.play_ui_click()
	add_button.disabled = false

func _update_party_display() -> void:
	for child in party_list.get_children():
		child.queue_free()

	for i in range(GameManager.party.size()):
		var character = GameManager.party[i]
		var hbox = HBoxContainer.new()

		var info = Label.new()
		info.text = "%s - %s (Niv.%d)" % [character.character_name, character.character_class.display_name, character.level]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var remove_btn = Button.new()
		remove_btn.text = "X"
		remove_btn.pressed.connect(_on_remove_character.bind(i))
		hbox.add_child(remove_btn)

		party_list.add_child(hbox)

	party_label.text = "Ton Equipe (%d/4)" % GameManager.party.size()
	start_button.disabled = GameManager.party.is_empty()

func _on_add_character_pressed() -> void:
	if not selected_class:
		return

	if GameManager.party.size() >= 4:
		return

	var char_name = name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = _generate_random_name()

	var character = selected_class.create_character(char_name)
	character.sprite_name = selected_class.display_name.to_lower()

	# Ajouter des compétences de base
	_add_starting_skills(character)

	GameManager.add_to_party(character)
	AudioManager.play_ui_click()

	name_input.text = ""
	_update_party_display()

func _add_starting_skills(character: Character) -> void:
	# Créer une attaque de base pour tous
	var basic_attack = Skill.new()
	basic_attack.skill_name = "Attaque"
	basic_attack.description = "Une attaque physique basique."
	basic_attack.mp_cost = 0
	basic_attack.target_type = Skill.TargetType.SINGLE_ENEMY
	basic_attack.damage_type = Skill.DamageType.PHYSICAL
	basic_attack.base_power = 100
	basic_attack.scaling_stat = "strength"
	character.skills.append(basic_attack)

	# Compétences selon la classe
	match character.character_class.display_name:
		"Guerrier":
			var power_strike = Skill.new()
			power_strike.skill_name = "Frappe Puissante"
			power_strike.description = "Une attaque dévastatrice infligeant 150% de dégâts."
			power_strike.mp_cost = 8
			power_strike.target_type = Skill.TargetType.SINGLE_ENEMY
			power_strike.damage_type = Skill.DamageType.PHYSICAL
			power_strike.base_power = 150
			power_strike.scaling_stat = "strength"
			power_strike.scaling_ratio = 1.2
			character.skills.append(power_strike)

		"Mage":
			var fireball = Skill.new()
			fireball.skill_name = "Boule de Feu"
			fireball.description = "Lance une boule de feu sur tous les ennemis."
			fireball.mp_cost = 15
			fireball.target_type = Skill.TargetType.ALL_ENEMIES
			fireball.damage_type = Skill.DamageType.MAGICAL
			fireball.element = Skill.Element.FIRE
			fireball.base_power = 80
			fireball.scaling_stat = "intelligence"
			fireball.scaling_ratio = 1.5
			character.skills.append(fireball)

		"Voleur":
			var backstab = Skill.new()
			backstab.skill_name = "Attaque Sournoise"
			backstab.description = "Une attaque vicieuse avec +30% de chance de critique."
			backstab.mp_cost = 6
			backstab.target_type = Skill.TargetType.SINGLE_ENEMY
			backstab.damage_type = Skill.DamageType.PHYSICAL
			backstab.base_power = 120
			backstab.scaling_stat = "dexterity"
			backstab.scaling_ratio = 1.3
			character.skills.append(backstab)

		"Clerc":
			var heal = Skill.new()
			heal.skill_name = "Soin"
			heal.description = "Restaure les HP d'un allié."
			heal.mp_cost = 10
			heal.target_type = Skill.TargetType.SINGLE_ALLY
			heal.damage_type = Skill.DamageType.HEALING
			heal.base_power = 80
			heal.scaling_stat = "intelligence"
			heal.scaling_ratio = 1.2
			character.skills.append(heal)

func _generate_random_name() -> String:
	var names = ["Alex", "Robin", "Morgan", "Casey", "Jordan", "Taylor", "Quinn", "Avery",
				 "Riley", "Sage", "Rowan", "Phoenix", "River", "Sky", "Storm", "Ash"]
	return names[randi() % names.size()]

func _on_remove_character(index: int) -> void:
	if index < GameManager.party.size():
		GameManager.party.remove_at(index)
		AudioManager.play_ui_click()
		_update_party_display()

func _on_start_pressed() -> void:
	if GameManager.party.is_empty():
		return

	AudioManager.play_ui_click()
	DataManager.add_starting_items()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main/game_table.tscn"))

func _on_back_pressed() -> void:
	AudioManager.play_ui_click()
	GameManager.party.clear()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

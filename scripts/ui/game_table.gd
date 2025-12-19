extends Control
## Scène principale du jeu - La table de JDR avec environnements dynamiques

@onready var party_area: HBoxContainer = $TableTop/GameArea/PartyArea
@onready var enemy_area: HBoxContainer = $TableTop/GameArea/EnemyArea
@onready var location_label: Label = $TableTop/GameArea/LocationPanel/LocationLabel
@onready var message_label: Label = $ActionPanel/VBox/MessageLabel
@onready var gold_label: Label = $TopBar/GoldPanel/GoldLabel
@onready var time_label: Label = $TopBar/TimePanel/TimeLabel
@onready var action_buttons: HBoxContainer = $ActionPanel/VBox/ActionButtons
@onready var location_background: TextureRect = $BackgroundLayer/LocationBackground
@onready var base_background: ColorRect = $BackgroundLayer/BaseBackground

# Environment decoration containers
@onready var left_decor: VBoxContainer = $TableTop/EnvironmentLayer/LeftDecor
@onready var right_decor: VBoxContainer = $TableTop/EnvironmentLayer/RightDecor
@onready var top_decor: HBoxContainer = $TableTop/EnvironmentLayer/TopDecor
@onready var bottom_decor: HBoxContainer = $TableTop/EnvironmentLayer/BottomDecor

# Environment assets paths
const ENV_TREES := "res://assets/sprites/environment/trees/"
const ENV_VEGETATION := "res://assets/sprites/environment/vegetation/"
const ENV_ROCKS := "res://assets/sprites/environment/rocks/"
const ENV_PROPS := "res://assets/sprites/environment/props/"
const ENV_STATIONS := "res://assets/sprites/environment/stations/"

var current_location: String = "tavern"
var locations: Dictionary = {
	"tavern": {
		"name": "Taverne du Dragon Dore",
		"can_rest": true,
		"can_shop": true,
		"bg_color": Color(0.15, 0.1, 0.12, 1),
		"bg_modulate": Color(0.4, 0.3, 0.25, 0.3),
		"decorations": {
			"left": ["furniture", "chest"],
			"right": ["furniture", "chest"],
			"top": ["bonfire"],
			"bottom": ["vegetation"]
		}
	},
	"forest": {
		"name": "Foret Sombre",
		"enemy_level": 1,
		"enemies": ["goblin", "wolf", "mushroom", "slime"],
		"bg_color": Color(0.08, 0.15, 0.08, 1),
		"bg_modulate": Color(0.4, 0.6, 0.3, 0.5),
		"decorations": {
			"left": ["tree_large", "tree_medium", "vegetation"],
			"right": ["tree_large", "tree_medium", "vegetation"],
			"top": ["tree_small", "rocks"],
			"bottom": ["vegetation", "rocks"]
		}
	},
	"dungeon": {
		"name": "Donjon Abandonne",
		"enemy_level": 3,
		"enemies": ["skeleton", "bat", "spider"],
		"bg_color": Color(0.1, 0.08, 0.12, 1),
		"bg_modulate": Color(0.3, 0.25, 0.35, 0.4),
		"decorations": {
			"left": ["dungeon_props", "chest"],
			"right": ["dungeon_props", "esoteric"],
			"top": ["dungeon_props"],
			"bottom": ["rocks"]
		}
	},
	"mountain": {
		"name": "Mont Perilleux",
		"enemy_level": 5,
		"enemies": ["orc", "troll"],
		"bg_color": Color(0.12, 0.12, 0.15, 1),
		"bg_modulate": Color(0.5, 0.5, 0.6, 0.4),
		"decorations": {
			"left": ["rocks", "rocks"],
			"right": ["rocks", "rocks"],
			"top": ["tree_small"],
			"bottom": ["rocks", "vegetation"]
		}
	},
	"castle": {
		"name": "Chateau Maudit",
		"enemy_level": 8,
		"enemies": ["dark_knight", "ghost", "demon"],
		"bg_color": Color(0.08, 0.05, 0.1, 1),
		"bg_modulate": Color(0.3, 0.2, 0.4, 0.5),
		"decorations": {
			"left": ["esoteric", "dungeon_props"],
			"right": ["esoteric", "dungeon_props"],
			"top": ["esoteric"],
			"bottom": ["dungeon_props"]
		}
	}
}

# Decoration asset mappings
var decoration_assets: Dictionary = {
	"tree_large": {"path": ENV_TREES + "Size_05.png", "size": Vector2(64, 80), "modulate": Color(0.9, 1.0, 0.9)},
	"tree_medium": {"path": ENV_TREES + "Size_04.png", "size": Vector2(48, 64), "modulate": Color(0.85, 0.95, 0.85)},
	"tree_small": {"path": ENV_TREES + "Size_03.png", "size": Vector2(32, 48), "modulate": Color(0.8, 0.9, 0.8)},
	"vegetation": {"path": ENV_VEGETATION + "Vegetation.png", "size": Vector2(48, 32), "modulate": Color(0.7, 0.9, 0.6)},
	"rocks": {"path": ENV_ROCKS + "Rocks.png", "size": Vector2(40, 32), "modulate": Color(0.7, 0.7, 0.75)},
	"furniture": {"path": ENV_PROPS + "Furniture.png", "size": Vector2(48, 48), "modulate": Color(0.8, 0.7, 0.6)},
	"chest": {"path": ENV_PROPS + "chest_01.png", "size": Vector2(32, 32), "modulate": Color(0.9, 0.8, 0.5)},
	"dungeon_props": {"path": ENV_PROPS + "Dungeon_Props.png", "size": Vector2(40, 40), "modulate": Color(0.6, 0.6, 0.7)},
	"esoteric": {"path": ENV_PROPS + "Esoteric.png", "size": Vector2(40, 40), "modulate": Color(0.7, 0.5, 0.8)},
	"bonfire": {"path": ENV_STATIONS + "Bonfire.png", "size": Vector2(48, 48), "modulate": Color(1.0, 0.9, 0.7)}
}

var character_card_scene: PackedScene

func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.party_changed.connect(_update_party_display)

	_update_gold_display()
	_update_party_display()
	_update_location_display()
	_show_message("Bienvenue à la Taverne ! Votre aventure commence ici.")

func _process(_delta: float) -> void:
	time_label.text = "⏱️ " + GameManager.format_play_time()

func _update_party_display() -> void:
	# Nettoyer l'affichage actuel
	for child in party_area.get_children():
		child.queue_free()

	# Créer une carte pour chaque membre du groupe
	for character in GameManager.party:
		var card = _create_character_card(character, false)
		party_area.add_child(card)

func _update_enemy_display(enemies: Array[Character]) -> void:
	# Nettoyer l'affichage actuel
	for child in enemy_area.get_children():
		child.queue_free()

	# Créer une carte pour chaque ennemi
	for enemy in enemies:
		var card = _create_character_card(enemy, true)
		enemy_area.add_child(card)

func _create_character_card(character: Character, is_enemy: bool) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 150)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)

	# Sprite du personnage
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(sprite_container)

	var sprite_rect = TextureRect.new()
	sprite_rect.custom_minimum_size = Vector2(48, 48)
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# Charger le sprite approprié
	var sprite_name = character.sprite_name if character.sprite_name else "default"
	if is_enemy:
		# Utiliser le nom du personnage comme sprite (en minuscules, sans accents problématiques)
		sprite_name = character.character_name.to_lower().replace(" ", "_")
		sprite_rect.texture = SpriteLoader.get_enemy_sprite(sprite_name)
	else:
		sprite_rect.texture = SpriteLoader.get_character_sprite(sprite_name)

	sprite_container.add_child(sprite_rect)

	# Nom
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	# Classe et niveau
	var class_label = Label.new()
	var class_display = character.character_class.display_name if character.character_class else "???"
	class_label.text = "%s Niv.%d" % [class_display, character.level]
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 10)
	class_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(class_label)

	# Barre de HP
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100, 15)
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.text = "%d/%d" % [character.current_hp, character.max_hp]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(hp_label)

	# Barre de MP (seulement pour les alliés)
	if not is_enemy:
		var mp_bar = ProgressBar.new()
		mp_bar.custom_minimum_size = Vector2(100, 10)
		mp_bar.max_value = character.max_mp
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false
		# Couleur bleue pour le mana
		var mp_style = StyleBoxFlat.new()
		mp_style.bg_color = Color(0.2, 0.4, 0.8)
		mp_bar.add_theme_stylebox_override("fill", mp_style)
		vbox.add_child(mp_bar)

		# Barre d'XP
		var xp_bar = ProgressBar.new()
		xp_bar.custom_minimum_size = Vector2(100, 6)
		xp_bar.max_value = character.get_exp_for_next_level()
		xp_bar.value = character.experience
		xp_bar.show_percentage = false
		var xp_style = StyleBoxFlat.new()
		xp_style.bg_color = Color(0.8, 0.7, 0.2)
		xp_bar.add_theme_stylebox_override("fill", xp_style)
		vbox.add_child(xp_bar)

		var xp_label = Label.new()
		xp_label.text = "XP: %d/%d" % [character.experience, character.get_exp_for_next_level()]
		xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		xp_label.add_theme_font_size_override("font_size", 8)
		xp_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		vbox.add_child(xp_label)

	return card

func _update_gold_display() -> void:
	gold_label.text = "💰 %d Or" % GameManager.gold

func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = "💰 %d Or" % new_amount

func _update_location_display() -> void:
	var loc_data = locations.get(current_location, {})
	location_label.text = loc_data.get("name", "Lieu Inconnu")

	# Mettre à jour les boutons disponibles
	var can_rest = loc_data.get("can_rest", false)
	var can_shop = loc_data.get("can_shop", false)

	$ActionPanel/VBox/ActionButtons/RestButton.visible = can_rest
	$ActionPanel/VBox/ActionButtons/ShopButton.visible = can_shop

	# Mettre à jour le fond selon la localisation
	_update_background(loc_data)

func _update_background(loc_data: Dictionary) -> void:
	var bg_color = loc_data.get("bg_color", Color(0.12, 0.08, 0.15, 1))
	var bg_modulate = loc_data.get("bg_modulate", Color(0.5, 0.5, 0.5, 0.3))

	# Animation fluide du changement de couleur
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(base_background, "color", bg_color, 0.5)
	tween.tween_property(location_background, "modulate", bg_modulate, 0.5)

	# Update environment decorations
	_update_decorations(loc_data)

func _update_decorations(loc_data: Dictionary) -> void:
	# Clear all decoration containers
	_clear_container(left_decor)
	_clear_container(right_decor)
	_clear_container(top_decor)
	_clear_container(bottom_decor)

	var decorations = loc_data.get("decorations", {})

	# Populate each container
	_populate_decorations(left_decor, decorations.get("left", []), true)
	_populate_decorations(right_decor, decorations.get("right", []), true)
	_populate_decorations(top_decor, decorations.get("top", []), false)
	_populate_decorations(bottom_decor, decorations.get("bottom", []), false)

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _populate_decorations(container: Container, decor_list: Array, is_vertical: bool) -> void:
	for decor_name in decor_list:
		var asset_info = decoration_assets.get(decor_name, null)
		if not asset_info:
			continue

		var texture = load(asset_info.path)
		if not texture:
			continue

		var tex_rect = TextureRect.new()
		tex_rect.texture = texture
		tex_rect.custom_minimum_size = asset_info.size
		tex_rect.modulate = asset_info.modulate
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		# Add some visual variation
		tex_rect.modulate.a = randf_range(0.6, 1.0)

		# Random horizontal flip for variety
		if randf() > 0.5:
			tex_rect.flip_h = true

		container.add_child(tex_rect)

		# Fade in animation
		tex_rect.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(tex_rect, "modulate:a", asset_info.modulate.a * randf_range(0.7, 1.0), 0.5)

func _show_message(text: String) -> void:
	message_label.text = text

func _on_explore_pressed() -> void:
	AudioManager.play_ui_click()
	_show_location_selection()

func _show_location_selection() -> void:
	# Créer un dialogue de sélection de lieu
	var dialog = AcceptDialog.new()
	dialog.title = "Où voulez-vous aller ?"
	dialog.dialog_text = ""

	var vbox = VBoxContainer.new()

	for loc_id in locations:
		var loc_data = locations[loc_id]
		var btn = Button.new()
		btn.text = loc_data.name

		if loc_data.has("enemy_level"):
			btn.text += " (Niv.%d+)" % loc_data.enemy_level

		btn.pressed.connect(func():
			_travel_to(loc_id)
			dialog.queue_free()
		)
		vbox.add_child(btn)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered(Vector2(300, 250))

func _travel_to(location_id: String) -> void:
	current_location = location_id
	_update_location_display()

	var loc_data = locations[location_id]
	_show_message("Vous arrivez à %s." % loc_data.name)

	# Nettoyer les ennemis
	_update_enemy_display([])

	GameManager.current_location = location_id

func _on_battle_pressed() -> void:
	AudioManager.play_ui_click()

	var loc_data = locations.get(current_location, {})
	if not loc_data.has("enemies"):
		_show_message("Il n'y a pas d'ennemis ici. Explorez d'autres zones !")
		return

	_start_random_battle()

func _start_random_battle() -> void:
	var loc_data = locations[current_location]
	var enemy_templates = loc_data.get("enemies", [])
	var base_level = loc_data.get("enemy_level", 1)

	if enemy_templates.is_empty():
		_show_message("Pas d'ennemis dans cette zone.")
		return

	# Créer des ennemis
	var enemies: Array[Character] = []
	var num_enemies = randi_range(1, 3)

	for i in num_enemies:
		var enemy = _create_enemy(enemy_templates[randi() % enemy_templates.size()], base_level)
		enemies.append(enemy)

	_update_enemy_display(enemies)
	_show_message("Des ennemis apparaissent !")

	# Démarrer le combat après un court délai
	await get_tree().create_timer(0.5).timeout
	_open_battle_scene(enemies)

func _create_enemy(template_name: String, base_level: int) -> Character:
	var enemy = Character.new()
	var level = base_level + randi_range(-1, 2)
	level = max(1, level)

	match template_name:
		"goblin":
			enemy.character_name = "Gobelin"
			enemy.max_hp = 40 + (level * 10)
			enemy.strength = 8 + level
			enemy.dexterity = 10 + level
			enemy.constitution = 6 + level
		"wolf":
			enemy.character_name = "Loup"
			enemy.max_hp = 35 + (level * 8)
			enemy.strength = 10 + level
			enemy.dexterity = 12 + level
			enemy.constitution = 5 + level
		"mushroom":
			enemy.character_name = "Champignon"
			enemy.max_hp = 30 + (level * 8)
			enemy.strength = 6 + level
			enemy.dexterity = 4 + level
			enemy.constitution = 10 + level
			enemy.intelligence = 5 + level
		"slime":
			enemy.character_name = "Slime"
			enemy.max_hp = 45 + (level * 12)
			enemy.strength = 5 + level
			enemy.dexterity = 3 + level
			enemy.constitution = 15 + level
		"skeleton":
			enemy.character_name = "Squelette"
			enemy.max_hp = 50 + (level * 12)
			enemy.strength = 12 + level
			enemy.dexterity = 8 + level
			enemy.constitution = 8 + level
		"bat":
			enemy.character_name = "Chauve-souris Géante"
			enemy.max_hp = 25 + (level * 6)
			enemy.strength = 6 + level
			enemy.dexterity = 16 + level
			enemy.constitution = 4 + level
		"spider":
			enemy.character_name = "Araignée Géante"
			enemy.max_hp = 45 + (level * 10)
			enemy.strength = 10 + level
			enemy.dexterity = 14 + level
			enemy.constitution = 7 + level
		"orc":
			enemy.character_name = "Orc"
			enemy.max_hp = 80 + (level * 15)
			enemy.strength = 16 + level
			enemy.dexterity = 8 + level
			enemy.constitution = 12 + level
		"troll":
			enemy.character_name = "Troll"
			enemy.max_hp = 120 + (level * 20)
			enemy.strength = 20 + level
			enemy.dexterity = 6 + level
			enemy.constitution = 18 + level
		"dark_knight":
			enemy.character_name = "Chevalier Noir"
			enemy.max_hp = 100 + (level * 18)
			enemy.strength = 18 + level
			enemy.dexterity = 12 + level
			enemy.constitution = 16 + level
		"ghost":
			enemy.character_name = "Fantôme"
			enemy.max_hp = 60 + (level * 10)
			enemy.strength = 8 + level
			enemy.intelligence = 16 + level
			enemy.dexterity = 14 + level
		"demon":
			enemy.character_name = "Démon Mineur"
			enemy.max_hp = 150 + (level * 25)
			enemy.strength = 22 + level
			enemy.intelligence = 18 + level
			enemy.constitution = 20 + level
		_:
			enemy.character_name = "Monstre"
			enemy.max_hp = 50 + (level * 10)
			enemy.strength = 10 + level

	enemy.level = level
	enemy.current_hp = enemy.max_hp
	enemy.max_mp = 20
	enemy.current_mp = 20
	enemy.intelligence = enemy.intelligence if enemy.intelligence > 0 else 8
	enemy.luck = 8

	# Ajouter une attaque basique
	var basic_attack = Skill.new()
	basic_attack.skill_name = "Attaque"
	basic_attack.mp_cost = 0
	basic_attack.target_type = Skill.TargetType.SINGLE_ENEMY
	basic_attack.damage_type = Skill.DamageType.PHYSICAL
	basic_attack.base_power = 100
	enemy.skills.append(basic_attack)

	# Récompenses
	enemy.set_meta("exp_reward", level * 25)
	enemy.set_meta("gold_reward", level * 15 + randi_range(0, level * 5))

	return enemy

func _open_battle_scene(enemies: Array[Character]) -> void:
	# Charger la scène de combat
	var battle_scene = load("res://scenes/battle/battle_scene.tscn")
	if battle_scene:
		var battle_instance = battle_scene.instantiate()
		battle_instance.setup_battle(GameManager.party.duplicate(), enemies)
		battle_instance.battle_finished.connect(_on_battle_finished)
		add_child(battle_instance)
	else:
		# Fallback: combat simplifié si la scène n'existe pas
		_run_simple_battle(enemies)

func _run_simple_battle(enemies: Array[Character]) -> void:
	# Combat simplifié en attendant la scène complète
	_show_message("Combat en cours...")

	await get_tree().create_timer(1.0).timeout

	# Simuler le combat
	var party_power = 0
	for p in GameManager.party:
		party_power += p.attack + p.level * 5

	var enemy_power = 0
	for e in enemies:
		enemy_power += e.strength + e.level * 3

	var victory = party_power >= enemy_power * 0.7 or randf() < 0.7

	if victory:
		var total_exp = 0
		var total_gold = 0
		for e in enemies:
			total_exp += e.get_meta("exp_reward", 20)
			total_gold += e.get_meta("gold_reward", 10)

		# Distribuer l'EXP
		var exp_per_member = total_exp / GameManager.party.size()
		for member in GameManager.party:
			member.add_experience(exp_per_member)

		GameManager.add_gold(total_gold)
		GameManager.stats.battles_won += 1
		GameManager.stats.enemies_defeated += enemies.size()

		_show_message("Victoire ! +%d EXP, +%d Or" % [total_exp, total_gold])
	else:
		# Défaite - perdre un peu de HP
		for member in GameManager.party:
			member.take_damage(member.max_hp / 4, false, true)

		GameManager.stats.battles_lost += 1
		_show_message("Défaite... Vous avez été blessés.")

	_update_enemy_display([])
	_update_party_display()

func _on_battle_finished(victory: bool, rewards: Dictionary) -> void:
	if victory:
		_show_message("Victoire ! +%d EXP, +%d Or" % [rewards.get("exp", 0), rewards.get("gold", 0)])
	else:
		if rewards.get("fled", false):
			_show_message("Vous avez fui le combat.")
		else:
			_show_message("Défaite...")

	_update_enemy_display([])
	_update_party_display()

func _on_rest_pressed() -> void:
	AudioManager.play_ui_click()

	var cost = 10 * GameManager.party.size()
	if GameManager.gold < cost:
		_show_message("Pas assez d'or pour se reposer. (Coût: %d Or)" % cost)
		return

	GameManager.spend_gold(cost)
	GameManager.heal_party_percent(1.0)
	GameManager.restore_party_mana_percent(1.0)

	# Nettoyer les effets de statut
	for member in GameManager.party:
		member.clear_status_effects()

	_update_party_display()
	_show_message("Vous vous êtes bien reposés ! HP et MP restaurés. (-%d Or)" % cost)

func _on_shop_pressed() -> void:
	AudioManager.play_ui_click()
	_show_message("La boutique n'est pas encore disponible...")
	# TODO: Implémenter la boutique

func _on_quest_pressed() -> void:
	AudioManager.play_ui_click()
	_show_message("Le journal de quêtes n'est pas encore disponible...")
	# TODO: Implémenter le journal de quêtes

func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	_show_pause_menu()

func _show_pause_menu() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Menu"

	var vbox = VBoxContainer.new()

	var save_btn = Button.new()
	save_btn.text = "💾 Sauvegarder"
	save_btn.pressed.connect(func():
		GameManager.save_game(0)
		_show_message("Partie sauvegardée !")
		dialog.queue_free()
	)
	vbox.add_child(save_btn)

	var inventory_btn = Button.new()
	inventory_btn.text = "🎒 Inventaire"
	inventory_btn.pressed.connect(func():
		_show_message("Inventaire: %d objets" % DataManager.party_inventory.get_slot_count())
		dialog.queue_free()
	)
	vbox.add_child(inventory_btn)

	var stats_btn = Button.new()
	stats_btn.text = "📊 Statistiques"
	stats_btn.pressed.connect(func():
		_show_stats()
		dialog.queue_free()
	)
	vbox.add_child(stats_btn)

	var quit_btn = Button.new()
	quit_btn.text = "🚪 Menu Principal"
	quit_btn.pressed.connect(func():
		dialog.queue_free()
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
	)
	vbox.add_child(quit_btn)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered(Vector2(250, 200))

func _show_stats() -> void:
	var stats_text = """
Statistiques de partie:
━━━━━━━━━━━━━━━━━━
Combats gagnés: %d
Combats perdus: %d
Ennemis vaincus: %d
Or gagné: %d
Quêtes complétées: %d
Temps de jeu: %s
""" % [
		GameManager.stats.battles_won,
		GameManager.stats.battles_lost,
		GameManager.stats.enemies_defeated,
		GameManager.stats.gold_earned,
		GameManager.stats.quests_completed,
		GameManager.format_play_time()
	]
	_show_message(stats_text)

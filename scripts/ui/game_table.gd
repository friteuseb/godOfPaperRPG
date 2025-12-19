extends Control
## Scene principale du jeu - Style Knights of Pen and Paper
## La table de JDR avec le Maitre du Jeu et zone d'imagination

# === NODES ===
@onready var party_area: HBoxContainer = $TableLayer/ImaginationZone/PartyArea
@onready var enemy_area: HBoxContainer = $TableLayer/ImaginationZone/EnemyArea
@onready var location_label: Label = $TableLayer/ImaginationZone/LocationPanel/LocationLabel
@onready var location_background: TextureRect = $TableLayer/ImaginationZone/LocationBackground
@onready var adventure_background: ColorRect = $TableLayer/ImaginationZone/AdventureBackground
@onready var message_label: Label = $ActionPanel/VBox/MessageLabel
@onready var gold_label: Label = $TopBar/GoldPanel/GoldLabel
@onready var time_label: Label = $TopBar/TimePanel/TimeLabel
@onready var action_buttons: GridContainer = $ActionPanel/VBox/ActionButtons
@onready var gm_dialogue: Label = $TableLayer/GameMasterZone/GMPanel/HBox/VBox/GMDialogue
@onready var dice_label: Label = $TableLayer/GameMasterZone/GMPanel/HBox/DiceContainer/DiceLabel
@onready var candle_glow: ColorRect = $RoomLayer/CandleGlow

var current_location: String = "tavern"
var locations: Dictionary = {
	"tavern": {
		"name": "Taverne du Dragon Dore",
		"can_rest": true,
		"can_shop": true,
		"bg_color": Color(0.18, 0.12, 0.10, 1),
		"bg_modulate": Color(0.6, 0.45, 0.35, 0.5),
		"gm_intro": "\"Vous vous trouvez dans une taverne chaleureuse. L'odeur de ragout flotte dans l'air...\""
	},
	"forest": {
		"name": "Foret Sombre",
		"enemy_level": 1,
		"enemies": ["goblin", "wolf", "mushroom", "slime"],
		"bg_color": Color(0.10, 0.18, 0.10, 1),
		"bg_modulate": Color(0.4, 0.6, 0.3, 0.5),
		"gm_intro": "\"Les arbres anciens murmurent des secrets oublies. Attention aux creatures qui rodent...\""
	},
	"dungeon": {
		"name": "Donjon Abandonne",
		"enemy_level": 3,
		"enemies": ["skeleton", "bat", "spider"],
		"bg_color": Color(0.12, 0.10, 0.15, 1),
		"bg_modulate": Color(0.35, 0.30, 0.40, 0.5),
		"gm_intro": "\"L'air est humide et froid. Des os craquent sous vos pieds...\""
	},
	"mountain": {
		"name": "Mont Perilleux",
		"enemy_level": 5,
		"enemies": ["orc", "troll"],
		"bg_color": Color(0.15, 0.15, 0.18, 1),
		"bg_modulate": Color(0.5, 0.5, 0.6, 0.5),
		"gm_intro": "\"Le vent hurle entre les rochers. Des silhouettes massives se dessinent au loin...\""
	},
	"castle": {
		"name": "Chateau Maudit",
		"enemy_level": 8,
		"enemies": ["dark_knight", "ghost", "demon"],
		"bg_color": Color(0.10, 0.08, 0.12, 1),
		"bg_modulate": Color(0.35, 0.25, 0.45, 0.5),
		"gm_intro": "\"Une aura malefique emane de ces murs. Seuls les plus braves osent entrer...\""
	}
}

var character_card_scene: PackedScene
var candle_tween: Tween

func _ready() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.party_changed.connect(_update_party_display)

	# Connect level up signals for all party members
	for member in GameManager.party:
		if not member.leveled_up.is_connected(_on_character_leveled_up):
			member.leveled_up.connect(_on_character_leveled_up.bind(member))

	_update_gold_display()
	_update_party_display()
	_update_location_display()
	_start_candle_animation()

	_gm_speak("Bienvenue, aventuriers ! Votre quete epique commence ici, a la Taverne du Dragon Dore.")
	_show_message("Que souhaitez-vous faire ?")

func _process(_delta: float) -> void:
	time_label.text = GameManager.format_play_time()

func _start_candle_animation() -> void:
	# Animation de la lueur de bougie
	if candle_glow:
		_animate_candle()

func _animate_candle() -> void:
	if candle_tween:
		candle_tween.kill()
	candle_tween = create_tween()
	candle_tween.set_loops()
	candle_tween.tween_property(candle_glow, "color:a", randf_range(0.05, 0.12), randf_range(0.8, 1.5))
	candle_tween.tween_property(candle_glow, "color:a", randf_range(0.06, 0.10), randf_range(0.5, 1.0))

func _update_party_display() -> void:
	for child in party_area.get_children():
		child.queue_free()

	for character in GameManager.party:
		var card = _create_character_card(character, false)
		party_area.add_child(card)

func _update_enemy_display(enemies: Array[Character]) -> void:
	for child in enemy_area.get_children():
		child.queue_free()

	for enemy in enemies:
		var card = _create_character_card(enemy, true)
		enemy_area.add_child(card)

func _create_character_card(character: Character, is_enemy: bool) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 130)

	# Style parchemin pour les cartes
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.65, 0.52, 0.95) if not is_enemy else Color(0.55, 0.45, 0.40, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.42, 0.30, 0.18, 1) if not is_enemy else Color(0.50, 0.35, 0.30, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 2
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Sprite du personnage (style figurine)
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(sprite_container)

	var sprite_rect = TextureRect.new()
	sprite_rect.custom_minimum_size = Vector2(40, 40)
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var sprite_name = character.sprite_name if character.sprite_name else "default"
	if is_enemy:
		sprite_name = character.character_name.to_lower().replace(" ", "_")
		sprite_rect.texture = SpriteLoader.get_enemy_sprite(sprite_name)
	else:
		sprite_rect.texture = SpriteLoader.get_character_sprite(sprite_name)

	sprite_container.add_child(sprite_rect)

	# Socle de figurine
	var base = ColorRect.new()
	base.custom_minimum_size = Vector2(30, 4)
	base.color = Color(0.35, 0.25, 0.15, 0.8)
	var base_container = CenterContainer.new()
	base_container.add_child(base)
	vbox.add_child(base_container)

	# Nom
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.20, 0.15, 0.10, 1))
	vbox.add_child(name_label)

	# Classe et niveau
	var class_label = Label.new()
	var class_display = character.character_class.display_name if character.character_class else "???"
	class_label.text = "Niv.%d" % character.level
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 9)
	class_label.add_theme_color_override("font_color", Color(0.45, 0.35, 0.25, 1))
	vbox.add_child(class_label)

	# Barre de HP
	var hp_container = VBoxContainer.new()
	hp_container.add_theme_constant_override("separation", 0)
	vbox.add_child(hp_container)

	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(80, 10)
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false

	var hp_style_bg = StyleBoxFlat.new()
	hp_style_bg.bg_color = Color(0.18, 0.12, 0.08, 1)
	hp_style_bg.corner_radius_top_left = 2
	hp_style_bg.corner_radius_top_right = 2
	hp_style_bg.corner_radius_bottom_right = 2
	hp_style_bg.corner_radius_bottom_left = 2
	hp_bar.add_theme_stylebox_override("background", hp_style_bg)

	var hp_style_fill = StyleBoxFlat.new()
	hp_style_fill.bg_color = Color(0.75, 0.18, 0.15, 1)
	hp_style_fill.corner_radius_top_left = 2
	hp_style_fill.corner_radius_top_right = 2
	hp_style_fill.corner_radius_bottom_right = 2
	hp_style_fill.corner_radius_bottom_left = 2
	hp_bar.add_theme_stylebox_override("fill", hp_style_fill)

	hp_container.add_child(hp_bar)

	var hp_label = Label.new()
	hp_label.text = "%d/%d" % [character.current_hp, character.max_hp]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 8)
	hp_label.add_theme_color_override("font_color", Color(0.35, 0.25, 0.18, 1))
	hp_container.add_child(hp_label)

	# Barre de MP (seulement pour les allies)
	if not is_enemy and character.max_mp > 0:
		var mp_bar = ProgressBar.new()
		mp_bar.custom_minimum_size = Vector2(80, 6)
		mp_bar.max_value = character.max_mp
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false

		mp_bar.add_theme_stylebox_override("background", hp_style_bg)

		var mp_style_fill = StyleBoxFlat.new()
		mp_style_fill.bg_color = Color(0.15, 0.35, 0.75, 1)
		mp_style_fill.corner_radius_top_left = 2
		mp_style_fill.corner_radius_top_right = 2
		mp_style_fill.corner_radius_bottom_right = 2
		mp_style_fill.corner_radius_bottom_left = 2
		mp_bar.add_theme_stylebox_override("fill", mp_style_fill)

		hp_container.add_child(mp_bar)

	return card

func _update_gold_display() -> void:
	gold_label.text = "%d Or" % GameManager.gold

func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = "%d Or" % new_amount

func _update_location_display() -> void:
	var loc_data = locations.get(current_location, {})
	location_label.text = loc_data.get("name", "Lieu Inconnu")

	var can_rest = loc_data.get("can_rest", false)
	var can_shop = loc_data.get("can_shop", false)

	$ActionPanel/VBox/ActionButtons/RestButton.visible = can_rest
	$ActionPanel/VBox/ActionButtons/ShopButton.visible = can_shop

	_update_background(loc_data)

func _update_background(loc_data: Dictionary) -> void:
	var bg_color = loc_data.get("bg_color", Color(0.12, 0.15, 0.12, 1))
	var bg_modulate = loc_data.get("bg_modulate", Color(0.5, 0.5, 0.5, 0.4))

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(adventure_background, "color", bg_color, 0.5)
	tween.tween_property(location_background, "modulate", bg_modulate, 0.5)

func _gm_speak(text: String) -> void:
	# Le Maitre du Jeu parle
	if gm_dialogue:
		gm_dialogue.text = "\"%s\"" % text
		# Animation du de quand le MJ parle
		_roll_dice_animation()

func _roll_dice_animation() -> void:
	if dice_label:
		var dice_faces = ["🎲", "🎯", "✨", "🎲"]
		var tween = create_tween()
		for i in range(4):
			tween.tween_callback(func(): dice_label.text = dice_faces[i % dice_faces.size()])
			tween.tween_interval(0.1)
		tween.tween_callback(func(): dice_label.text = "🎲")

func _show_message(text: String) -> void:
	message_label.text = text

func _on_explore_pressed() -> void:
	AudioManager.play_ui_click()
	_show_location_selection()

func _show_location_selection() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Ou voulez-vous aller ?"
	dialog.dialog_text = ""

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

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
	dialog.popup_centered(Vector2(300, 280))

func _travel_to(location_id: String) -> void:
	current_location = location_id
	_update_location_display()

	var loc_data = locations[location_id]
	var gm_text = loc_data.get("gm_intro", "Vous arrivez dans un nouveau lieu...")
	_gm_speak(gm_text.trim_prefix("\"").trim_suffix("\""))
	_show_message("Vous etes arrives a %s." % loc_data.name)

	_update_enemy_display([])
	GameManager.current_location = location_id

func _on_battle_pressed() -> void:
	AudioManager.play_ui_click()

	var loc_data = locations.get(current_location, {})
	if not loc_data.has("enemies"):
		_gm_speak("Il n'y a pas de monstres ici. C'est un lieu sur.")
		_show_message("Explorez d'autres zones pour trouver des ennemis !")
		return

	_start_random_battle()

func _start_random_battle() -> void:
	var loc_data = locations[current_location]
	var enemy_templates = loc_data.get("enemies", [])
	var base_level = loc_data.get("enemy_level", 1)

	if enemy_templates.is_empty():
		_show_message("Pas d'ennemis dans cette zone.")
		return

	# Le MJ annonce le combat
	var battle_intros = [
		"Attention ! Des creatures hostiles approchent !",
		"Vous entendez des bruits de pas... Preparez-vous !",
		"Soudain, des ennemis surgissent de l'ombre !",
		"Le danger vous guette... Lancez l'initiative !"
	]
	_gm_speak(battle_intros[randi() % battle_intros.size()])

	var enemies: Array[Character] = []
	var num_enemies = randi_range(1, 3)

	for i in num_enemies:
		var enemy = _create_enemy(enemy_templates[randi() % enemy_templates.size()], base_level)
		enemies.append(enemy)

	_update_enemy_display(enemies)
	_show_message("Des ennemis apparaissent !")

	await get_tree().create_timer(0.8).timeout
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
			enemy.character_name = "Chauve-souris"
			enemy.max_hp = 25 + (level * 6)
			enemy.strength = 6 + level
			enemy.dexterity = 16 + level
			enemy.constitution = 4 + level
		"spider":
			enemy.character_name = "Araignee"
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
			enemy.character_name = "Fantome"
			enemy.max_hp = 60 + (level * 10)
			enemy.strength = 8 + level
			enemy.intelligence = 16 + level
			enemy.dexterity = 14 + level
		"demon":
			enemy.character_name = "Demon"
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

	var basic_attack = Skill.new()
	basic_attack.skill_name = "Attaque"
	basic_attack.mp_cost = 0
	basic_attack.target_type = Skill.TargetType.SINGLE_ENEMY
	basic_attack.damage_type = Skill.DamageType.PHYSICAL
	basic_attack.base_power = 100
	enemy.skills.append(basic_attack)

	enemy.set_meta("exp_reward", level * 25)
	enemy.set_meta("gold_reward", level * 15 + randi_range(0, level * 5))

	return enemy

func _open_battle_scene(enemies: Array[Character]) -> void:
	var battle_scene = load("res://scenes/battle/battle_scene.tscn")
	if battle_scene:
		var battle_instance = battle_scene.instantiate()
		battle_instance.setup_battle(GameManager.party.duplicate(), enemies)
		battle_instance.battle_finished.connect(_on_battle_finished)
		add_child(battle_instance)
	else:
		_run_simple_battle(enemies)

func _run_simple_battle(enemies: Array[Character]) -> void:
	_gm_speak("Le combat fait rage !")
	_show_message("Combat en cours...")

	await get_tree().create_timer(1.0).timeout

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

		var exp_per_member = total_exp / GameManager.party.size()
		for member in GameManager.party:
			member.add_experience(exp_per_member)

		GameManager.add_gold(total_gold)
		GameManager.stats.battles_won += 1
		GameManager.stats.enemies_defeated += enemies.size()

		_gm_speak("Excellent ! Vous avez terrasse vos ennemis !")
		_show_message("Victoire ! +%d EXP, +%d Or" % [total_exp, total_gold])
	else:
		for member in GameManager.party:
			member.take_damage(member.max_hp / 4, false, true)

		GameManager.stats.battles_lost += 1
		_gm_speak("Helas, vous avez ete vaincus... Mais l'aventure continue !")
		_show_message("Defaite... Vous avez ete blesses.")

	_update_enemy_display([])
	_update_party_display()

func _on_battle_finished(victory: bool, rewards: Dictionary) -> void:
	if victory:
		_gm_speak("Bravo, heros ! Vos ennemis sont vaincus !")
		_show_message("Victoire ! +%d EXP, +%d Or" % [rewards.get("exp", 0), rewards.get("gold", 0)])
	else:
		if rewards.get("fled", false):
			_gm_speak("Une retraite strategique... Sage decision.")
			_show_message("Vous avez fui le combat.")
		else:
			_gm_speak("Ne vous decouragez pas. L'echec forge les heros !")
			_show_message("Defaite...")

	_update_enemy_display([])
	_update_party_display()

func _on_rest_pressed() -> void:
	AudioManager.play_ui_click()

	var cost = 10 * GameManager.party.size()
	if GameManager.gold < cost:
		_gm_speak("Vous n'avez pas assez d'or pour une chambre...")
		_show_message("Pas assez d'or pour se reposer. (Cout: %d Or)" % cost)
		return

	GameManager.spend_gold(cost)
	GameManager.heal_party_percent(1.0)
	GameManager.restore_party_mana_percent(1.0)

	for member in GameManager.party:
		member.clear_status_effects()

	_update_party_display()
	_gm_speak("Vous passez une nuit reposante. Vos forces sont restaurees !")
	_show_message("HP et MP restaures ! (-%d Or)" % cost)

func _on_shop_pressed() -> void:
	AudioManager.play_ui_click()
	_gm_speak("Le marchand est absent pour le moment...")
	_show_message("La boutique n'est pas encore disponible...")

func _on_quest_pressed() -> void:
	AudioManager.play_ui_click()
	_show_quest_panel()

func _show_quest_panel() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Journal de Quetes"
	dialog.size = Vector2(480, 600)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(450, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)

	# Quetes actives
	var active_label = Label.new()
	active_label.text = "== Quetes Actives =="
	active_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55, 1))
	active_label.add_theme_font_size_override("font_size", 14)
	active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(active_label)

	var active_quests = QuestManager.get_active_quests()
	if active_quests.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Aucune quete en cours"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 1))
		main_vbox.add_child(empty_label)
	else:
		for quest in active_quests:
			var quest_panel = _create_quest_panel(quest, true, dialog)
			main_vbox.add_child(quest_panel)

	# Separateur
	var sep = HSeparator.new()
	sep.modulate = Color(0.55, 0.42, 0.25, 1)
	main_vbox.add_child(sep)

	# Quetes disponibles
	var available_label = Label.new()
	available_label.text = "== Quetes Disponibles =="
	available_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.55, 1))
	available_label.add_theme_font_size_override("font_size", 14)
	available_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(available_label)

	var available_quests = QuestManager.get_available_quests()
	if available_quests.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Pas de nouvelles quetes"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4, 1))
		main_vbox.add_child(empty_label)
	else:
		for quest in available_quests:
			var quest_panel = _create_quest_panel(quest, false, dialog)
			main_vbox.add_child(quest_panel)

	dialog.add_child(scroll)
	add_child(dialog)
	dialog.popup_centered()

func _create_quest_panel(quest: Quest, is_active: bool, parent_dialog: AcceptDialog) -> PanelContainer:
	var panel = PanelContainer.new()

	var style = StyleBoxFlat.new()
	if quest.is_completed:
		style.bg_color = Color(0.35, 0.50, 0.35, 0.9)
	elif is_active:
		style.bg_color = Color(0.50, 0.42, 0.30, 0.9)
	else:
		style.bg_color = Color(0.40, 0.35, 0.28, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.55, 0.42, 0.25, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Titre de la quete
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)

	var title = Label.new()
	title.text = quest.quest_name
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.95, 0.90, 0.70, 1))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title)

	var type_label = Label.new()
	match quest.quest_type:
		Quest.QuestType.MAIN:
			type_label.text = "[PRINCIPAL]"
			type_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 1))
		Quest.QuestType.SIDE:
			type_label.text = "[SECONDAIRE]"
			type_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1))
		_:
			type_label.text = ""
	type_label.add_theme_font_size_override("font_size", 10)
	title_hbox.add_child(type_label)

	# Description
	var desc = Label.new()
	desc.text = quest.description
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.80, 0.75, 0.60, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Objectifs (si actif)
	if is_active:
		var obj_label = Label.new()
		obj_label.text = quest.get_progress_text()
		obj_label.add_theme_font_size_override("font_size", 10)
		if quest.is_completed:
			obj_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1))
		else:
			obj_label.add_theme_color_override("font_color", Color(0.85, 0.80, 0.65, 1))
		vbox.add_child(obj_label)

	# Recompenses
	if quest.rewards:
		var rew_label = Label.new()
		rew_label.text = "Recompenses: %d XP, %d Or" % [quest.rewards.experience, quest.rewards.gold]
		rew_label.add_theme_font_size_override("font_size", 9)
		rew_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
		vbox.add_child(rew_label)

	# Bouton d'action
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 30)
	if is_active and quest.is_completed:
		btn.text = "Terminer la quete"
		btn.pressed.connect(func():
			if QuestManager.turn_in_quest(quest):
				_gm_speak("Quete terminee ! Vous recevez %d XP et %d Or !" % [quest.rewards.experience, quest.rewards.gold])
				_show_message("Quete '%s' terminee !" % quest.quest_name)
				_update_party_display()
				parent_dialog.queue_free()
		)
	elif not is_active:
		btn.text = "Accepter la quete"
		btn.pressed.connect(func():
			if QuestManager.start_quest(quest):
				_gm_speak("Nouvelle quete acceptee: %s" % quest.quest_name)
				_show_message("Quete '%s' acceptee !" % quest.quest_name)
				parent_dialog.queue_free()
		)
	else:
		btn.text = "En cours..."
		btn.disabled = true
	vbox.add_child(btn)

	return panel

func _on_menu_pressed() -> void:
	AudioManager.play_ui_click()
	_show_pause_menu()

func _show_pause_menu() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Menu"

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var save_btn = Button.new()
	save_btn.text = "Sauvegarder"
	save_btn.pressed.connect(func():
		GameManager.save_game(0)
		_gm_speak("Votre aventure a ete sauvegardee !")
		_show_message("Partie sauvegardee !")
		dialog.queue_free()
	)
	vbox.add_child(save_btn)

	var inventory_btn = Button.new()
	inventory_btn.text = "Inventaire"
	inventory_btn.pressed.connect(func():
		_show_message("Inventaire: %d objets" % DataManager.party_inventory.get_slot_count())
		dialog.queue_free()
	)
	vbox.add_child(inventory_btn)

	var stats_btn = Button.new()
	stats_btn.text = "Statistiques"
	stats_btn.pressed.connect(func():
		_show_stats()
		dialog.queue_free()
	)
	vbox.add_child(stats_btn)

	var quit_btn = Button.new()
	quit_btn.text = "Menu Principal"
	quit_btn.pressed.connect(func():
		dialog.queue_free()
		get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
	)
	vbox.add_child(quit_btn)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered(Vector2(250, 220))

func _show_stats() -> void:
	var stats_text = """Statistiques:
Combats gagnes: %d
Combats perdus: %d
Ennemis vaincus: %d
Or gagne: %d
Temps: %s""" % [
		GameManager.stats.battles_won,
		GameManager.stats.battles_lost,
		GameManager.stats.enemies_defeated,
		GameManager.stats.gold_earned,
		GameManager.format_play_time()
	]
	_gm_speak("Voici vos exploits, aventuriers !")
	_show_message(stats_text)

func _on_character_leveled_up(new_level: int, character: Character) -> void:
	_show_level_up_popup(character, new_level)
	_gm_speak("%s a atteint le niveau %d ! Ses pouvoirs grandissent !" % [character.character_name, new_level])
	AudioManager.play_ui_click()
	_update_party_display()

func _show_level_up_popup(character: Character, new_level: int) -> void:
	# Creer un popup de level up style parchemin
	var popup = PanelContainer.new()
	popup.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.75, 0.55, 0.98)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.55, 0.42, 0.25, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	popup.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	popup.add_child(vbox)

	# Titre
	var title = Label.new()
	title.text = "NIVEAU SUPERIEUR !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.20, 1))
	vbox.add_child(title)

	# Nom et niveau
	var name_label = Label.new()
	name_label.text = "%s -> Niv.%d" % [character.character_name, new_level]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10, 1))
	vbox.add_child(name_label)

	# Stats
	var stats_label = Label.new()
	stats_label.text = "HP: %d  MP: %d\nATK: %d  DEF: %d" % [character.max_hp, character.max_mp, character.attack, character.defense]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.35, 0.28, 0.18, 1))
	vbox.add_child(stats_label)

	add_child(popup)

	# Positionner au centre
	await get_tree().process_frame
	popup.position = (size - popup.size) / 2

	# Animation
	popup.modulate.a = 0
	popup.scale = Vector2(0.5, 0.5)
	popup.pivot_offset = popup.size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, 0.3)
	tween.tween_property(popup, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

	await get_tree().create_timer(2.5).timeout

	var fade_tween = create_tween()
	fade_tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(popup.queue_free)

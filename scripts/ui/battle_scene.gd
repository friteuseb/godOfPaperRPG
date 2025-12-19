extends Control
## Interface de combat style Knights of Pen and Paper
## Combat sur la table de JDR avec figurines

signal battle_finished(victory: bool, rewards: Dictionary)

@onready var enemy_zone: HBoxContainer = $BattleArena/EnemyZone
@onready var party_zone: HBoxContainer = $BattleArena/PartyZone
@onready var message_label: Label = $UILayer/MessagePanel/MessageLabel
@onready var turn_label: Label = $UILayer/ActionPanel/VBox/TurnLabel
@onready var action_buttons: HBoxContainer = $UILayer/ActionPanel/VBox/ActionButtons
@onready var target_buttons: HBoxContainer = $UILayer/ActionPanel/VBox/TargetButtons
@onready var skill_list: HBoxContainer = $UILayer/ActionPanel/VBox/SkillList
@onready var battle_title: Label = $BattleTitle

# Alias pour compatibilite
@onready var enemy_list: HBoxContainer = $BattleArena/EnemyZone
@onready var party_list: HBoxContainer = $BattleArena/PartyZone

var party: Array[Character] = []
var enemies: Array[Character] = []
var current_character: Character
var selected_skill: Skill
var waiting_for_target: bool = false

var enemy_widgets: Dictionary = {}
var party_widgets: Dictionary = {}

func setup_battle(party_members: Array[Character], enemy_group: Array[Character]) -> void:
	party = []
	enemies = []

	for p in party_members:
		party.append(p)
	for e in enemy_group:
		enemies.append(e)

func _ready() -> void:
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.turn_started.connect(_on_turn_started)
	BattleManager.message_displayed.connect(_on_message_displayed)
	BattleManager.damage_dealt.connect(_on_damage_dealt)
	BattleManager.character_died.connect(_on_character_died)

	await get_tree().create_timer(0.3).timeout

	if not party.is_empty() and not enemies.is_empty():
		BattleManager.start_battle(party, enemies)

func _on_battle_started(_party: Array, _enemies: Array) -> void:
	_update_all_displays()
	_set_action_buttons_visible(false)

func _update_all_displays() -> void:
	_update_party_display()
	_update_enemy_display()

func _update_party_display() -> void:
	for child in party_list.get_children():
		child.queue_free()
	party_widgets.clear()

	for character in party:
		var widget = _create_figurine_card(character, false)
		party_list.add_child(widget)
		party_widgets[character] = widget

func _update_enemy_display() -> void:
	for child in enemy_list.get_children():
		child.queue_free()
	enemy_widgets.clear()

	for enemy in enemies:
		var widget = _create_figurine_card(enemy, true)
		enemy_list.add_child(widget)
		enemy_widgets[enemy] = widget

func _create_figurine_card(character: Character, is_enemy: bool) -> Control:
	# Style carte figurine de JDR
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(95, 120)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.72, 0.65, 0.52, 0.95) if not is_enemy else Color(0.58, 0.48, 0.42, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.42, 0.30, 0.18, 1) if not is_enemy else Color(0.52, 0.38, 0.28, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 3
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Sprite du personnage (figurine)
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(sprite_container)

	var sprite_rect = TextureRect.new()
	sprite_rect.custom_minimum_size = Vector2(36, 36)
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
	var base_container = CenterContainer.new()
	var base = ColorRect.new()
	base.custom_minimum_size = Vector2(28, 4)
	base.color = Color(0.32, 0.22, 0.12, 0.9)
	base_container.add_child(base)
	vbox.add_child(base_container)

	# Nom
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08, 1))
	vbox.add_child(name_label)

	# Niveau
	var level_label = Label.new()
	level_label.text = "Niv.%d" % character.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 8)
	level_label.add_theme_color_override("font_color", Color(0.42, 0.32, 0.22, 1))
	vbox.add_child(level_label)

	# Container pour les barres
	var bars_container = VBoxContainer.new()
	bars_container.add_theme_constant_override("separation", 1)
	vbox.add_child(bars_container)

	# Barre de HP
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(75, 10)
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"

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

	bars_container.add_child(hp_bar)

	# Label HP
	var hp_label = Label.new()
	hp_label.text = "%d/%d" % [character.current_hp, character.max_hp]
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 8)
	hp_label.add_theme_color_override("font_color", Color(0.32, 0.22, 0.15, 1))
	hp_label.name = "HPText"
	bars_container.add_child(hp_label)

	# Barre de MP (allies seulement)
	if not is_enemy and character.max_mp > 0:
		var mp_bar = ProgressBar.new()
		mp_bar.custom_minimum_size = Vector2(75, 6)
		mp_bar.max_value = character.max_mp
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false
		mp_bar.name = "MPBar"

		mp_bar.add_theme_stylebox_override("background", hp_style_bg)

		var mp_style_fill = StyleBoxFlat.new()
		mp_style_fill.bg_color = Color(0.15, 0.35, 0.75, 1)
		mp_style_fill.corner_radius_top_left = 2
		mp_style_fill.corner_radius_top_right = 2
		mp_style_fill.corner_radius_bottom_right = 2
		mp_style_fill.corner_radius_bottom_left = 2
		mp_bar.add_theme_stylebox_override("fill", mp_style_fill)

		bars_container.add_child(mp_bar)

		var mp_label = Label.new()
		mp_label.text = "%d/%d" % [character.current_mp, character.max_mp]
		mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mp_label.add_theme_font_size_override("font_size", 7)
		mp_label.add_theme_color_override("font_color", Color(0.25, 0.35, 0.55, 1))
		mp_label.name = "MPText"
		bars_container.add_child(mp_label)

	# Indicateur de statut
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status_label)

	# Griser si mort
	if not character.is_alive():
		card.modulate = Color(0.5, 0.5, 0.5)

	return card

func _update_character_widget(character: Character) -> void:
	var widget = party_widgets.get(character)
	if not widget:
		widget = enemy_widgets.get(character)
	if not widget:
		return

	var hp_bar = widget.find_child("HPBar", true, false)
	var hp_text = widget.find_child("HPText", true, false)

	if hp_bar:
		hp_bar.value = character.current_hp
	if hp_text:
		hp_text.text = "%d/%d" % [character.current_hp, character.max_hp]

	var mp_bar = widget.find_child("MPBar", true, false)
	var mp_text = widget.find_child("MPText", true, false)

	if mp_bar:
		mp_bar.value = character.current_mp
	if mp_text:
		mp_text.text = "%d/%d" % [character.current_mp, character.max_mp]

	if not character.is_alive():
		widget.modulate = Color(0.5, 0.5, 0.5)

func _on_turn_started(character: Character) -> void:
	current_character = character
	turn_label.text = "Tour de: %s" % character.character_name

	_highlight_active_character(character)

	if character in party:
		_set_action_buttons_visible(true)
	else:
		_set_action_buttons_visible(false)

func _highlight_active_character(character: Character) -> void:
	# Reset tous les highlights
	for widget in party_widgets.values():
		widget.modulate = Color.WHITE
	for widget in enemy_widgets.values():
		widget.modulate = Color.WHITE

	# Griser les morts
	for p in party:
		if not p.is_alive() and party_widgets.has(p):
			party_widgets[p].modulate = Color(0.5, 0.5, 0.5)
	for e in enemies:
		if not e.is_alive() and enemy_widgets.has(e):
			enemy_widgets[e].modulate = Color(0.5, 0.5, 0.5)

	# Highlight actif avec effet dore
	var widget = party_widgets.get(character)
	if not widget:
		widget = enemy_widgets.get(character)
	if widget:
		widget.modulate = Color(1.15, 1.10, 0.85)
		# Animation de pulsation
		var tween = create_tween()
		tween.set_loops(2)
		tween.tween_property(widget, "modulate", Color(1.25, 1.15, 0.80), 0.3)
		tween.tween_property(widget, "modulate", Color(1.15, 1.10, 0.85), 0.3)

func _set_action_buttons_visible(visible: bool) -> void:
	action_buttons.visible = visible
	target_buttons.visible = false
	skill_list.visible = false

func _on_message_displayed(message: String) -> void:
	message_label.text = message

func _on_damage_dealt(target: Character, amount: int, is_critical: bool) -> void:
	_update_character_widget(target)
	# Jouer le son de dégâts
	if amount > 0:
		if is_critical:
			AudioManager.play_battle_critical()
		else:
			AudioManager.play_battle_hit_random()
	else:
		# Soin
		AudioManager.play_heal()
	# Animation de degats
	_show_damage_popup(target, amount, is_critical)

func _show_damage_popup(target: Character, amount: int, is_critical: bool) -> void:
	var widget = party_widgets.get(target)
	if not widget:
		widget = enemy_widgets.get(target)
	if not widget:
		return

	# Creer un label flottant pour les degats
	var damage_label = Label.new()
	damage_label.text = "-%d" % amount if amount > 0 else "+%d" % abs(amount)
	damage_label.add_theme_font_size_override("font_size", 16 if is_critical else 12)
	damage_label.add_theme_color_override("font_color", Color(1, 0.3, 0.2) if amount > 0 else Color(0.3, 1, 0.3))
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if is_critical:
		damage_label.text += " CRIT!"
		damage_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

	widget.add_child(damage_label)
	damage_label.position = Vector2(widget.size.x / 2 - 20, -10)

	# Animation
	var tween = create_tween()
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 30, 0.8)
	tween.parallel().tween_property(damage_label, "modulate:a", 0, 0.8)
	tween.tween_callback(damage_label.queue_free)

func _on_character_died(character: Character) -> void:
	_update_character_widget(character)
	# Son de mort différent pour allié ou ennemi
	if character in enemies:
		AudioManager.play_sfx("defeat", 0.1)
	var widget = party_widgets.get(character)
	if not widget:
		widget = enemy_widgets.get(character)
	if widget:
		# Animation de mort
		var tween = create_tween()
		tween.tween_property(widget, "modulate", Color(0.3, 0.3, 0.3), 0.5)

func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	_set_action_buttons_visible(false)

	if victory:
		AudioManager.play_victory()
		battle_title.text = "VICTOIRE !"
		message_label.text = "Bravo ! +%d EXP, +%d Or" % [rewards.exp, rewards.gold]

		# Check for level ups and show notifications
		await get_tree().create_timer(1.0).timeout
		for member in party:
			if member.is_alive():
				# Connect to check for level up during XP distribution
				pass
	else:
		if rewards.get("fled", false):
			AudioManager.play_battle_miss()
			battle_title.text = "FUITE"
			message_label.text = "Vous avez fui le combat..."
		else:
			AudioManager.play_defeat()
			battle_title.text = "DEFAITE"
			message_label.text = "Vous avez ete vaincus..."

	await get_tree().create_timer(2.0).timeout
	battle_finished.emit(victory, rewards)
	queue_free()

func _on_attack_pressed() -> void:
	AudioManager.play_ui_click()
	selected_skill = null
	_show_target_selection(true)

func _on_skill_pressed() -> void:
	AudioManager.play_ui_click()
	_show_skill_selection()

func _on_item_pressed() -> void:
	AudioManager.play_ui_click()
	message_label.text = "Les objets ne sont pas encore disponibles en combat."

func _on_flee_pressed() -> void:
	AudioManager.play_ui_click()
	BattleManager.flee_battle()

func _show_skill_selection() -> void:
	action_buttons.visible = false
	skill_list.visible = true

	for child in skill_list.get_children():
		child.queue_free()

	for skill in current_character.skills:
		var btn = Button.new()
		btn.text = "%s (%d)" % [skill.skill_name, skill.mp_cost]
		btn.custom_minimum_size = Vector2(110, 32)

		if not current_character.can_use_skill(skill):
			btn.disabled = true

		btn.pressed.connect(_on_skill_selected.bind(skill))
		skill_list.add_child(btn)

	var back_btn = Button.new()
	back_btn.text = "Retour"
	back_btn.pressed.connect(func():
		skill_list.visible = false
		action_buttons.visible = true
	)
	skill_list.add_child(back_btn)

func _on_skill_selected(skill: Skill) -> void:
	AudioManager.play_ui_click()
	selected_skill = skill
	skill_list.visible = false

	match skill.target_type:
		Skill.TargetType.SINGLE_ENEMY:
			_show_target_selection(true)
		Skill.TargetType.ALL_ENEMIES:
			_execute_skill_on_targets(_get_alive_enemies())
		Skill.TargetType.SINGLE_ALLY:
			_show_target_selection(false)
		Skill.TargetType.ALL_ALLIES:
			_execute_skill_on_targets(_get_alive_party())
		Skill.TargetType.SELF:
			_execute_skill_on_targets([current_character])

func _show_target_selection(target_enemies: bool) -> void:
	action_buttons.visible = false
	skill_list.visible = false
	target_buttons.visible = true

	for child in target_buttons.get_children():
		child.queue_free()

	var targets = _get_alive_enemies() if target_enemies else _get_alive_party()

	for target in targets:
		var btn = Button.new()
		btn.text = "%s (%d)" % [target.character_name, target.current_hp]
		btn.custom_minimum_size = Vector2(120, 32)
		btn.pressed.connect(_on_target_selected.bind(target))
		target_buttons.add_child(btn)

	var back_btn = Button.new()
	back_btn.text = "Retour"
	back_btn.pressed.connect(func():
		target_buttons.visible = false
		action_buttons.visible = true
	)
	target_buttons.add_child(back_btn)

func _on_target_selected(target: Character) -> void:
	AudioManager.play_ui_click()
	target_buttons.visible = false
	_execute_skill_on_targets([target])

func _execute_skill_on_targets(targets: Array) -> void:
	# Son de compétence
	if selected_skill and selected_skill.mp_cost > 0:
		AudioManager.play_spell_cast()

	var action = BattleAction.new()
	action.user = current_character
	action.skill = selected_skill
	action.targets = targets

	BattleManager.execute_action(action)

func _get_alive_enemies() -> Array[Character]:
	var alive: Array[Character] = []
	for e in enemies:
		if e.is_alive():
			alive.append(e)
	return alive

func _get_alive_party() -> Array[Character]:
	var alive: Array[Character] = []
	for p in party:
		if p.is_alive():
			alive.append(p)
	return alive

extends Control
## Interface de combat

signal battle_finished(victory: bool, rewards: Dictionary)

@onready var enemy_list: VBoxContainer = $BattlePanel/VBox/BattleArea/EnemyPanel/VBox/EnemyList
@onready var party_list: VBoxContainer = $BattlePanel/VBox/BattleArea/PartyPanel/VBox/PartyList
@onready var message_label: Label = $BattlePanel/VBox/MessagePanel/MessageLabel
@onready var turn_label: Label = $BattlePanel/VBox/ActionPanel/VBox/TurnLabel
@onready var action_buttons: HBoxContainer = $BattlePanel/VBox/ActionPanel/VBox/ActionButtons
@onready var target_buttons: HBoxContainer = $BattlePanel/VBox/ActionPanel/VBox/TargetButtons
@onready var skill_list: HBoxContainer = $BattlePanel/VBox/ActionPanel/VBox/SkillList

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

	# Copier les personnages pour éviter les modifications directes
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

	# Démarrer le combat après un court délai
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
		var widget = _create_character_widget(character, false)
		party_list.add_child(widget)
		party_widgets[character] = widget

func _update_enemy_display() -> void:
	for child in enemy_list.get_children():
		child.queue_free()
	enemy_widgets.clear()

	for enemy in enemies:
		var widget = _create_character_widget(enemy, true)
		enemy_list.add_child(widget)
		enemy_widgets[enemy] = widget

func _create_character_widget(character: Character, is_enemy: bool) -> Control:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 50)

	# Sprite
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

	hbox.add_child(sprite_rect)

	# Info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = "%s (Niv.%d)" % [character.character_name, character.level]
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	# HP Bar
	var hp_hbox = HBoxContainer.new()
	var hp_label = Label.new()
	hp_label.text = "HP:"
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_hbox.add_child(hp_label)

	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(80, 12)
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"
	hp_hbox.add_child(hp_bar)

	var hp_text = Label.new()
	hp_text.text = "%d/%d" % [character.current_hp, character.max_hp]
	hp_text.add_theme_font_size_override("font_size", 10)
	hp_text.name = "HPText"
	hp_hbox.add_child(hp_text)

	vbox.add_child(hp_hbox)

	# MP Bar (allies only)
	if not is_enemy:
		var mp_hbox = HBoxContainer.new()
		var mp_label = Label.new()
		mp_label.text = "MP:"
		mp_label.add_theme_font_size_override("font_size", 10)
		mp_hbox.add_child(mp_label)

		var mp_bar = ProgressBar.new()
		mp_bar.custom_minimum_size = Vector2(80, 12)
		mp_bar.max_value = character.max_mp
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false
		mp_bar.name = "MPBar"
		mp_hbox.add_child(mp_bar)

		var mp_text = Label.new()
		mp_text.text = "%d/%d" % [character.current_mp, character.max_mp]
		mp_text.add_theme_font_size_override("font_size", 10)
		mp_text.name = "MPText"
		mp_hbox.add_child(mp_text)

		vbox.add_child(mp_hbox)

	hbox.add_child(vbox)

	# Status indicator
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(status_label)

	# Griser si mort
	if not character.is_alive():
		hbox.modulate = Color(0.5, 0.5, 0.5)

	return hbox

func _update_character_widget(character: Character) -> void:
	var widget = party_widgets.get(character)
	if not widget:
		widget = enemy_widgets.get(character)
	if not widget:
		return

	# Trouver et mettre à jour les éléments
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

	# Griser si mort
	if not character.is_alive():
		widget.modulate = Color(0.5, 0.5, 0.5)

func _on_turn_started(character: Character) -> void:
	current_character = character
	turn_label.text = "Tour de: %s" % character.character_name

	# Highlight le personnage actif
	_highlight_active_character(character)

	if character in party:
		_set_action_buttons_visible(true)
	else:
		_set_action_buttons_visible(false)

func _highlight_active_character(character: Character) -> void:
	# Reset all highlights
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

	# Highlight active
	var widget = party_widgets.get(character)
	if not widget:
		widget = enemy_widgets.get(character)
	if widget:
		widget.modulate = Color(1.2, 1.2, 0.8)

func _set_action_buttons_visible(visible: bool) -> void:
	action_buttons.visible = visible
	target_buttons.visible = false
	skill_list.visible = false

func _on_message_displayed(message: String) -> void:
	message_label.text = message

func _on_damage_dealt(target: Character, amount: int, is_critical: bool) -> void:
	_update_character_widget(target)
	# TODO: Ajouter animation de dégâts

func _on_character_died(character: Character) -> void:
	_update_character_widget(character)

func _on_battle_ended(victory: bool, rewards: Dictionary) -> void:
	_set_action_buttons_visible(false)

	if victory:
		message_label.text = "🎉 VICTOIRE ! 🎉\n+%d EXP, +%d Or" % [rewards.exp, rewards.gold]
	else:
		if rewards.get("fled", false):
			message_label.text = "Vous avez fui le combat..."
		else:
			message_label.text = "💀 DÉFAITE 💀"

	# Attendre avant de fermer
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

	# Nettoyer
	for child in skill_list.get_children():
		child.queue_free()

	# Ajouter les compétences
	for skill in current_character.skills:
		var btn = Button.new()
		btn.text = "%s (%d MP)" % [skill.skill_name, skill.mp_cost]
		btn.custom_minimum_size = Vector2(120, 35)

		if not current_character.can_use_skill(skill):
			btn.disabled = true

		btn.pressed.connect(_on_skill_selected.bind(skill))
		skill_list.add_child(btn)

	# Bouton retour
	var back_btn = Button.new()
	back_btn.text = "↩ Retour"
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

	# Nettoyer
	for child in target_buttons.get_children():
		child.queue_free()

	var targets = _get_alive_enemies() if target_enemies else _get_alive_party()

	for target in targets:
		var btn = Button.new()
		btn.text = "%s (%d HP)" % [target.character_name, target.current_hp]
		btn.custom_minimum_size = Vector2(130, 35)
		btn.pressed.connect(_on_target_selected.bind(target))
		target_buttons.add_child(btn)

	# Bouton retour
	var back_btn = Button.new()
	back_btn.text = "↩ Retour"
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

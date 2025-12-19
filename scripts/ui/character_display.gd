extends Control
class_name CharacterDisplay
## Affiche un personnage avec son sprite, barres HP/MP et infos

signal clicked(character: Character)

@export var show_mp_bar: bool = true
@export var show_class_label: bool = true
@export var clickable: bool = false

var character: Character
var is_enemy: bool = false

@onready var sprite_rect: TextureRect
@onready var name_label: Label
@onready var class_label: Label
@onready var hp_bar: ProgressBar
@onready var hp_label: Label
@onready var mp_bar: ProgressBar
@onready var mp_label: Label
@onready var status_container: HBoxContainer

func _ready() -> void:
	_create_ui()
	if character:
		update_display()

func _create_ui() -> void:
	custom_minimum_size = Vector2(120, 180)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Sprite du personnage
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(sprite_container)

	sprite_rect = TextureRect.new()
	sprite_rect.custom_minimum_size = Vector2(64, 64)
	sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_container.add_child(sprite_rect)

	# Nom
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	# Classe et niveau
	class_label = Label.new()
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 10)
	class_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	class_label.visible = show_class_label
	vbox.add_child(class_label)

	# Barre HP
	var hp_container = VBoxContainer.new()
	hp_container.add_theme_constant_override("separation", 0)
	vbox.add_child(hp_container)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100, 12)
	hp_bar.show_percentage = false
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.8, 0.2, 0.2)
	hp_bar.add_theme_stylebox_override("fill", hp_style)
	hp_container.add_child(hp_bar)

	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 9)
	hp_container.add_child(hp_label)

	# Barre MP
	var mp_container = VBoxContainer.new()
	mp_container.add_theme_constant_override("separation", 0)
	mp_container.visible = show_mp_bar
	vbox.add_child(mp_container)

	mp_bar = ProgressBar.new()
	mp_bar.custom_minimum_size = Vector2(100, 8)
	mp_bar.show_percentage = false
	var mp_style = StyleBoxFlat.new()
	mp_style.bg_color = Color(0.2, 0.4, 0.8)
	mp_bar.add_theme_stylebox_override("fill", mp_style)
	mp_container.add_child(mp_bar)

	mp_label = Label.new()
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mp_label.add_theme_font_size_override("font_size", 9)
	mp_container.add_child(mp_label)

	# Conteneur d'effets de statut
	status_container = HBoxContainer.new()
	status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(status_container)

	# Gestion du clic
	if clickable:
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_gui_input)

func setup(char: Character, enemy: bool = false) -> void:
	character = char
	is_enemy = enemy

	if is_inside_tree():
		update_display()

	# Connecter les signaux
	if character:
		if character.hp_changed.is_connected(_on_hp_changed):
			character.hp_changed.disconnect(_on_hp_changed)
		if character.mp_changed.is_connected(_on_mp_changed):
			character.mp_changed.disconnect(_on_mp_changed)

		character.hp_changed.connect(_on_hp_changed)
		character.mp_changed.connect(_on_mp_changed)

func update_display() -> void:
	if not character or not is_inside_tree():
		return

	# Charger le sprite
	var sprite_name = character.sprite_name if character.sprite_name else "default"
	var texture: Texture2D

	if is_enemy:
		texture = SpriteLoader.get_enemy_sprite(sprite_name)
	else:
		texture = SpriteLoader.get_character_sprite(sprite_name)

	sprite_rect.texture = texture

	# Nom
	name_label.text = character.character_name

	# Classe
	if character.character_class:
		class_label.text = "%s Niv.%d" % [character.character_class.display_name, character.level]
	else:
		class_label.text = "Niv.%d" % character.level

	# HP
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	hp_label.text = "%d/%d" % [character.current_hp, character.max_hp]

	# MP
	if show_mp_bar:
		mp_bar.max_value = character.max_mp
		mp_bar.value = character.current_mp
		mp_label.text = "%d/%d" % [character.current_mp, character.max_mp]

	# Griser si mort
	if not character.is_alive():
		modulate = Color(0.5, 0.5, 0.5)
	else:
		modulate = Color.WHITE

	# Mettre à jour les effets de statut
	_update_status_icons()

func _update_status_icons() -> void:
	for child in status_container.get_children():
		child.queue_free()

	if not character:
		return

	for effect in character.status_effects:
		var icon = Label.new()
		match effect.effect_type:
			StatusEffect.EffectType.BUFF:
				icon.text = "⬆️"
			StatusEffect.EffectType.DEBUFF:
				icon.text = "⬇️"
			StatusEffect.EffectType.DOT:
				icon.text = "🔥"
			StatusEffect.EffectType.HOT:
				icon.text = "💚"
			StatusEffect.EffectType.STUN:
				icon.text = "💫"
			_:
				icon.text = "✨"
		icon.tooltip_text = "%s (%d tours)" % [effect.effect_name, effect.duration]
		status_container.add_child(icon)

func _on_hp_changed(_current: int, _max: int) -> void:
	update_display()

func _on_mp_changed(_current: int, _max: int) -> void:
	update_display()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(character)

func highlight(enabled: bool) -> void:
	if enabled:
		modulate = Color(1.2, 1.2, 0.8)
	else:
		if character and not character.is_alive():
			modulate = Color(0.5, 0.5, 0.5)
		else:
			modulate = Color.WHITE

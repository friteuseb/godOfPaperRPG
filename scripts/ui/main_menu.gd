extends Control
## Menu principal du jeu - Style Knights of Pen and Paper

@onready var continue_button: Button = $TableLayer/MenuContent/VBoxContainer/ContinueButton

func _ready() -> void:
	# Vérifier si une sauvegarde existe
	continue_button.visible = GameManager.has_save(0)

	# Animation d'entrée
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_new_game_pressed() -> void:
	AudioManager.play_ui_click()
	# Transition vers la création de personnage
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_start_new_game)

func _start_new_game() -> void:
	GameManager.new_game()
	get_tree().change_scene_to_file("res://scenes/main/character_creation.tscn")

func _on_continue_pressed() -> void:
	AudioManager.play_ui_click()
	if GameManager.load_game(0):
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main/game_table.tscn"))

func _on_options_pressed() -> void:
	AudioManager.play_ui_click()
	# TODO: Ouvrir le menu d'options
	print("Options - À implémenter")

func _on_quit_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().quit()

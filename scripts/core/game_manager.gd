extends Node
## Game Manager - Singleton gérant l'état global du jeu
## Gère les transitions entre scènes, la sauvegarde/chargement, et l'état de la partie

signal game_state_changed(new_state: GameState)
signal gold_changed(new_amount: int)
signal party_changed()

enum GameState { MAIN_MENU, EXPLORING, IN_BATTLE, IN_DIALOGUE, PAUSED, GAME_OVER }

var current_state: GameState = GameState.MAIN_MENU
var party: Array[Character] = []
var gold: int = 100
var current_location: String = "tavern"
var game_time: float = 0.0  # Temps de jeu en secondes
var difficulty: int = 1  # 1=Facile, 2=Normal, 3=Difficile

# Statistiques de partie
var stats: Dictionary = {
	"battles_won": 0,
	"battles_lost": 0,
	"enemies_defeated": 0,
	"gold_earned": 0,
	"quests_completed": 0,
	"total_damage_dealt": 0,
	"total_damage_taken": 0
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if current_state != GameState.MAIN_MENU and current_state != GameState.PAUSED:
		game_time += delta

func change_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	game_state_changed.emit(new_state)
	print("[GameManager] State changed: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])

func add_gold(amount: int) -> void:
	gold += amount
	if amount > 0:
		stats.gold_earned += amount
		AudioManager.play_gold_gain()
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func add_to_party(character: Character) -> bool:
	if party.size() < 4:
		party.append(character)
		party_changed.emit()
		return true
	return false

func remove_from_party(character: Character) -> void:
	party.erase(character)
	party_changed.emit()

func get_party_alive() -> Array[Character]:
	var alive: Array[Character] = []
	for c in party:
		if c.is_alive():
			alive.append(c)
	return alive

func is_party_dead() -> bool:
	return get_party_alive().is_empty()

func heal_party_percent(percent: float) -> void:
	for character in party:
		var heal_amount = int(character.max_hp * percent)
		character.heal(heal_amount)

func restore_party_mana_percent(percent: float) -> void:
	for character in party:
		var restore_amount = int(character.max_mp * percent)
		character.restore_mana(restore_amount)

func new_game() -> void:
	party.clear()
	gold = 100
	current_location = "tavern"
	game_time = 0.0
	stats = {
		"battles_won": 0,
		"battles_lost": 0,
		"enemies_defeated": 0,
		"gold_earned": 0,
		"quests_completed": 0,
		"total_damage_dealt": 0,
		"total_damage_taken": 0
	}
	change_state(GameState.EXPLORING)

func save_game(slot: int = 0) -> bool:
	var save_data = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_time": game_time,
		"gold": gold,
		"current_location": current_location,
		"difficulty": difficulty,
		"stats": stats,
		"party": []
	}

	for character in party:
		save_data.party.append(character.to_dict())

	var save_path = "user://save_%d.json" % slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[GameManager] Game saved to slot %d" % slot)
		return true
	return false

func load_game(slot: int = 0) -> bool:
	var save_path = "user://save_%d.json" % slot
	if not FileAccess.file_exists(save_path):
		print("[GameManager] No save file found in slot %d" % slot)
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()

		if parse_result == OK:
			var save_data = json.data
			gold = save_data.gold
			current_location = save_data.current_location
			game_time = save_data.game_time
			difficulty = save_data.get("difficulty", 1)
			stats = save_data.get("stats", stats)

			party.clear()
			for char_data in save_data.party:
				var character = Character.from_dict(char_data)
				party.append(character)

			change_state(GameState.EXPLORING)
			print("[GameManager] Game loaded from slot %d" % slot)
			return true
	return false

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists("user://save_%d.json" % slot)

func delete_save(slot: int = 0) -> bool:
	var save_path = "user://save_%d.json" % slot
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		return true
	return false

func format_play_time() -> String:
	var hours = int(game_time / 3600)
	var minutes = int(fmod(game_time, 3600) / 60)
	var seconds = int(fmod(game_time, 60))
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

extends Node
## Quest Manager - Gere les quetes du jeu

signal quest_started(quest: Quest)
signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_turned_in(quest: Quest)

var active_quests: Array[Quest] = []
var completed_quests: Array[String] = []  # IDs des quetes terminees
var available_quests: Array[Quest] = []

func _ready() -> void:
	# Connecter aux evenements de combat
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.character_died.connect(_on_enemy_killed)

	# Charger les quetes de base
	_load_starter_quests()

func _load_starter_quests() -> void:
	# Quete tutoriel: Premier combat
	var q1 = Quest.new()
	q1.quest_id = "tutorial_first_battle"
	q1.quest_name = "Premiers Pas"
	q1.description = "Prouvez votre valeur en remportant votre premier combat."
	q1.quest_type = Quest.QuestType.MAIN

	var obj1 = QuestObjective.new()
	obj1.type = Quest.ObjectiveType.WIN_BATTLES
	obj1.description = "Gagner un combat"
	obj1.target = "any"
	obj1.required_amount = 1
	q1.objectives.append(obj1)

	var rew1 = QuestRewards.new()
	rew1.experience = 50
	rew1.gold = 25
	q1.rewards = rew1

	available_quests.append(q1)

	# Quete: Chasse aux gobelins
	var q2 = Quest.new()
	q2.quest_id = "goblin_hunt"
	q2.quest_name = "Chasse aux Gobelins"
	q2.description = "Les gobelins terrorisent la region. Eliminez-en quelques-uns."
	q2.quest_type = Quest.QuestType.SIDE

	var obj2 = QuestObjective.new()
	obj2.type = Quest.ObjectiveType.KILL_ENEMIES
	obj2.description = "Eliminer des Gobelins"
	obj2.target = "gobelin"
	obj2.required_amount = 3
	q2.objectives.append(obj2)

	var rew2 = QuestRewards.new()
	rew2.experience = 100
	rew2.gold = 50
	q2.rewards = rew2

	available_quests.append(q2)

	# Quete: Exploration de la foret
	var q3 = Quest.new()
	q3.quest_id = "forest_explorer"
	q3.quest_name = "Exploration Forestiere"
	q3.description = "Explorez la Foret Sombre et vainquez ses creatures."
	q3.quest_type = Quest.QuestType.SIDE

	var obj3 = QuestObjective.new()
	obj3.type = Quest.ObjectiveType.WIN_BATTLES
	obj3.description = "Gagner des combats en foret"
	obj3.target = "forest"
	obj3.required_amount = 3
	q3.objectives.append(obj3)

	var rew3 = QuestRewards.new()
	rew3.experience = 150
	rew3.gold = 75
	q3.rewards = rew3

	available_quests.append(q3)

	# Quete: Devenir plus fort
	var q4 = Quest.new()
	q4.quest_id = "level_up_quest"
	q4.quest_name = "Entrainement"
	q4.description = "Gagnez de l'experience et montez de niveau."
	q4.quest_type = Quest.QuestType.SIDE

	var obj4 = QuestObjective.new()
	obj4.type = Quest.ObjectiveType.WIN_BATTLES
	obj4.description = "Gagner des combats"
	obj4.target = "any"
	obj4.required_amount = 5
	q4.objectives.append(obj4)

	var rew4 = QuestRewards.new()
	rew4.experience = 200
	rew4.gold = 100
	q4.rewards = rew4

	available_quests.append(q4)

func start_quest(quest: Quest) -> bool:
	if quest.is_active or quest.is_turned_in:
		return false

	if not quest.is_available():
		return false

	quest.start()
	active_quests.append(quest)
	available_quests.erase(quest)

	quest.quest_updated.connect(_on_quest_updated)
	quest.quest_completed.connect(_on_quest_completed)

	quest_started.emit(quest)
	return true

func turn_in_quest(quest: Quest) -> bool:
	if not quest.is_completed or quest.is_turned_in:
		return false

	quest.turn_in()
	active_quests.erase(quest)
	completed_quests.append(quest.quest_id)

	quest_turned_in.emit(quest)
	return true

func get_available_quests() -> Array[Quest]:
	var quests: Array[Quest] = []
	for q in available_quests:
		if q.is_available():
			quests.append(q)
	return quests

func get_active_quests() -> Array[Quest]:
	return active_quests

func get_completed_quests() -> Array[Quest]:
	var quests: Array[Quest] = []
	for q in active_quests:
		if q.is_completed and not q.is_turned_in:
			quests.append(q)
	return quests

func _on_battle_ended(victory: bool, _rewards: Dictionary) -> void:
	if not victory:
		return

	# Mettre a jour les quetes de type WIN_BATTLES
	for quest in active_quests:
		var location = GameManager.current_location
		quest.update_objective(Quest.ObjectiveType.WIN_BATTLES, "any", 1)
		quest.update_objective(Quest.ObjectiveType.WIN_BATTLES, location, 1)

func _on_enemy_killed(character: Character) -> void:
	# Mettre a jour les quetes de type KILL_ENEMIES
	var enemy_name = character.character_name.to_lower()

	for quest in active_quests:
		quest.update_objective(Quest.ObjectiveType.KILL_ENEMIES, enemy_name, 1)
		quest.update_objective(Quest.ObjectiveType.KILL_ENEMIES, "any", 1)

func _on_quest_updated(quest: Quest) -> void:
	quest_updated.emit(quest)

func _on_quest_completed(quest: Quest) -> void:
	quest_completed.emit(quest)

func to_dict() -> Dictionary:
	var active_data = []
	for q in active_quests:
		active_data.append(q.to_dict())

	return {
		"active_quests": active_data,
		"completed_quests": completed_quests
	}

func from_dict(data: Dictionary) -> void:
	completed_quests = data.get("completed_quests", [])

	# Restaurer les quetes actives
	for q_data in data.get("active_quests", []):
		for q in available_quests:
			if q.quest_id == q_data.quest_id:
				q.from_dict(q_data)
				if q.is_active:
					active_quests.append(q)
					available_quests.erase(q)
				break

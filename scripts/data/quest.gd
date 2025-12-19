extends Resource
class_name Quest
## Définit une quête avec ses objectifs et récompenses

signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)

enum QuestType { MAIN, SIDE, DAILY, BOUNTY }
enum ObjectiveType { KILL_ENEMIES, COLLECT_ITEMS, TALK_TO_NPC, REACH_LOCATION, WIN_BATTLES }

@export var quest_id: String = ""
@export var quest_name: String = "New Quest"
@export_multiline var description: String = ""
@export var quest_type: QuestType = QuestType.SIDE

@export var objectives: Array[QuestObjective] = []
@export var rewards: QuestRewards

@export var required_level: int = 1
@export var prerequisite_quests: Array[String] = []  # IDs des quêtes à compléter avant

var is_active: bool = false
var is_completed: bool = false
var is_turned_in: bool = false

func start() -> void:
	is_active = true
	for objective in objectives:
		objective.current_progress = 0
	quest_updated.emit(self)

func update_objective(objective_type: ObjectiveType, target: String, amount: int = 1) -> void:
	if not is_active or is_completed:
		return

	for objective in objectives:
		if objective.type == objective_type and objective.target == target:
			objective.current_progress = min(objective.current_progress + amount, objective.required_amount)
			quest_updated.emit(self)

	_check_completion()

func _check_completion() -> void:
	for objective in objectives:
		if objective.current_progress < objective.required_amount:
			return

	is_completed = true
	quest_completed.emit(self)

func turn_in() -> void:
	if not is_completed:
		return

	is_turned_in = true

	# Appliquer les récompenses
	if rewards:
		GameManager.add_gold(rewards.gold)
		for character in GameManager.party:
			character.add_experience(rewards.experience)

		for item_data in rewards.items:
			var item = DataManager.get_item(item_data.item_id)
			if item:
				DataManager.party_inventory.add_item(item, item_data.quantity)

	GameManager.stats.quests_completed += 1

func get_progress_text() -> String:
	var texts: Array[String] = []
	for objective in objectives:
		texts.append("%s: %d/%d" % [objective.description, objective.current_progress, objective.required_amount])
	return "\n".join(texts)

func is_available() -> bool:
	if is_active or is_turned_in:
		return false

	# Vérifier le niveau
	if GameManager.party.size() > 0:
		var max_level = 0
		for character in GameManager.party:
			max_level = max(max_level, character.level)
		if max_level < required_level:
			return false

	# Vérifier les prérequis
	# TODO: Implémenter la vérification des quêtes complétées

	return true

func to_dict() -> Dictionary:
	var obj_data = []
	for objective in objectives:
		obj_data.append({
			"type": objective.type,
			"target": objective.target,
			"progress": objective.current_progress
		})

	return {
		"quest_id": quest_id,
		"is_active": is_active,
		"is_completed": is_completed,
		"is_turned_in": is_turned_in,
		"objectives": obj_data
	}

func from_dict(data: Dictionary) -> void:
	is_active = data.is_active
	is_completed = data.is_completed
	is_turned_in = data.is_turned_in

	for i in min(objectives.size(), data.objectives.size()):
		objectives[i].current_progress = data.objectives[i].progress

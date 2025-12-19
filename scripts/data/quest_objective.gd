extends Resource
class_name QuestObjective
## Un objectif de quête

@export var type: Quest.ObjectiveType = Quest.ObjectiveType.KILL_ENEMIES
@export var description: String = "Kill enemies"
@export var target: String = ""  # ID de l'ennemi, item, NPC, ou lieu
@export var required_amount: int = 1
var current_progress: int = 0

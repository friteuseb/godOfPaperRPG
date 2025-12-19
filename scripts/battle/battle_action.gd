extends RefCounted
class_name BattleAction
## Représente une action de combat

var user: Character
var skill: Skill  # null pour une attaque basique
var targets: Array[Character] = []
var item: Item  # Pour utiliser un objet

func is_valid() -> bool:
	if not user or not user.is_alive():
		return false

	if targets.is_empty():
		return false

	if skill and not user.can_use_skill(skill):
		return false

	return true

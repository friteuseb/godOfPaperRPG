extends Item
class_name Consumable
## Objet consommable (potions, nourriture, etc.)

enum ConsumableEffect { HEAL_HP, HEAL_MP, HEAL_BOTH, CURE_STATUS, BUFF, REVIVE }

@export var effect: ConsumableEffect = ConsumableEffect.HEAL_HP
@export var effect_value: int = 50  # Valeur de l'effet (HP/MP restaurés, etc.)
@export var effect_percent: float = 0.0  # Effet en pourcentage (0.3 = 30% des HP max)
@export var status_to_cure: String = ""  # Nom de l'effet à soigner
@export var buff_effect: StatusEffect  # Buff à appliquer
@export var usable_in_battle: bool = true
@export var usable_outside_battle: bool = true

func _init() -> void:
	item_type = ItemType.CONSUMABLE
	stackable = true

func use(target: Character) -> bool:
	if not target.is_alive() and effect != ConsumableEffect.REVIVE:
		return false

	match effect:
		ConsumableEffect.HEAL_HP:
			var heal = effect_value
			if effect_percent > 0:
				heal += int(target.max_hp * effect_percent)
			target.heal(heal)
			return true

		ConsumableEffect.HEAL_MP:
			var restore = effect_value
			if effect_percent > 0:
				restore += int(target.max_mp * effect_percent)
			target.restore_mana(restore)
			return true

		ConsumableEffect.HEAL_BOTH:
			var heal_hp = effect_value
			var heal_mp = effect_value / 2
			if effect_percent > 0:
				heal_hp += int(target.max_hp * effect_percent)
				heal_mp += int(target.max_mp * effect_percent)
			target.heal(heal_hp)
			target.restore_mana(heal_mp)
			return true

		ConsumableEffect.CURE_STATUS:
			for status in target.status_effects.duplicate():
				if status_to_cure == "" or status.effect_name == status_to_cure:
					target.remove_status_effect(status)
			return true

		ConsumableEffect.BUFF:
			if buff_effect:
				target.add_status_effect(buff_effect.duplicate_effect())
				return true
			return false

		ConsumableEffect.REVIVE:
			if not target.is_alive():
				target.current_hp = int(target.max_hp * max(0.1, effect_percent))
				return true
			return false

	return false

func get_effect_description() -> String:
	match effect:
		ConsumableEffect.HEAL_HP:
			if effect_percent > 0:
				return "Restaure %d%% HP" % int(effect_percent * 100)
			return "Restaure %d HP" % effect_value
		ConsumableEffect.HEAL_MP:
			if effect_percent > 0:
				return "Restaure %d%% MP" % int(effect_percent * 100)
			return "Restaure %d MP" % effect_value
		ConsumableEffect.HEAL_BOTH:
			return "Restaure HP et MP"
		ConsumableEffect.CURE_STATUS:
			if status_to_cure != "":
				return "Soigne %s" % status_to_cure
			return "Soigne tous les statuts"
		ConsumableEffect.BUFF:
			if buff_effect:
				return buff_effect.effect_name
			return "Buff"
		ConsumableEffect.REVIVE:
			return "Ressuscite avec %d%% HP" % int(effect_percent * 100)
	return ""

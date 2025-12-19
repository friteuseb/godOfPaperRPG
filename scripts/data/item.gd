extends Resource
class_name Item
## Classe de base pour tous les objets

enum ItemType { CONSUMABLE, EQUIPMENT, KEY_ITEM, MATERIAL }

@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE
@export var price: int = 10  # Prix d'achat
@export var sell_price: int = 5  # Prix de vente
@export var stackable: bool = true
@export var max_stack: int = 99

func use(target: Character) -> bool:
	# À surcharger dans les classes dérivées
	return false

func get_tooltip() -> String:
	return "%s\n%s\nPrix: %d or" % [item_name, description, price]

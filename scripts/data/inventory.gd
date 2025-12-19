extends Resource
class_name Inventory
## Système d'inventaire

signal item_added(item: Item, quantity: int)
signal item_removed(item: Item, quantity: int)
signal inventory_changed()

@export var max_slots: int = 50
@export var items: Array[InventorySlot] = []

func add_item(item: Item, quantity: int = 1) -> int:
	## Ajoute un objet à l'inventaire. Retourne le nombre d'objets ajoutés.
	var added = 0

	if item.stackable:
		# Chercher un slot existant avec de la place
		for slot in items:
			if slot.item.resource_path == item.resource_path:
				var space = slot.item.max_stack - slot.quantity
				var to_add = min(space, quantity - added)
				slot.quantity += to_add
				added += to_add

				if added >= quantity:
					break

	# Ajouter dans de nouveaux slots si nécessaire
	while added < quantity and items.size() < max_slots:
		var new_slot = InventorySlot.new()
		new_slot.item = item

		if item.stackable:
			var to_add = min(item.max_stack, quantity - added)
			new_slot.quantity = to_add
			added += to_add
		else:
			new_slot.quantity = 1
			added += 1

		items.append(new_slot)

	if added > 0:
		item_added.emit(item, added)
		inventory_changed.emit()

	return added

func remove_item(item: Item, quantity: int = 1) -> int:
	## Retire un objet de l'inventaire. Retourne le nombre d'objets retirés.
	var removed = 0
	var slots_to_remove: Array[InventorySlot] = []

	for slot in items:
		if slot.item.resource_path == item.resource_path:
			var to_remove = min(slot.quantity, quantity - removed)
			slot.quantity -= to_remove
			removed += to_remove

			if slot.quantity <= 0:
				slots_to_remove.append(slot)

			if removed >= quantity:
				break

	for slot in slots_to_remove:
		items.erase(slot)

	if removed > 0:
		item_removed.emit(item, removed)
		inventory_changed.emit()

	return removed

func has_item(item: Item, quantity: int = 1) -> bool:
	var count = get_item_count(item)
	return count >= quantity

func get_item_count(item: Item) -> int:
	var count = 0
	for slot in items:
		if slot.item.resource_path == item.resource_path:
			count += slot.quantity
	return count

func get_items_by_type(type: Item.ItemType) -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for slot in items:
		if slot.item.item_type == type:
			result.append(slot)
	return result

func get_consumables() -> Array[InventorySlot]:
	return get_items_by_type(Item.ItemType.CONSUMABLE)

func get_equipment() -> Array[InventorySlot]:
	return get_items_by_type(Item.ItemType.EQUIPMENT)

func get_slot_count() -> int:
	return items.size()

func is_full() -> bool:
	return items.size() >= max_slots

func sort_by_type() -> void:
	items.sort_custom(func(a, b):
		if a.item.item_type != b.item.item_type:
			return a.item.item_type < b.item.item_type
		return a.item.item_name < b.item.item_name
	)
	inventory_changed.emit()

func sort_by_name() -> void:
	items.sort_custom(func(a, b):
		return a.item.item_name < b.item.item_name
	)
	inventory_changed.emit()

func clear() -> void:
	items.clear()
	inventory_changed.emit()

func to_dict() -> Array:
	var data = []
	for slot in items:
		data.append({
			"item_path": slot.item.resource_path,
			"quantity": slot.quantity
		})
	return data

func from_dict(data: Array) -> void:
	items.clear()
	for slot_data in data:
		if ResourceLoader.exists(slot_data.item_path):
			var slot = InventorySlot.new()
			slot.item = load(slot_data.item_path)
			slot.quantity = slot_data.quantity
			items.append(slot)
	inventory_changed.emit()

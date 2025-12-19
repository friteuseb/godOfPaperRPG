extends Node
## Data Manager - Gère le chargement des données du jeu (classes, ennemis, objets, etc.)

var character_classes: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var quests: Dictionary = {}

var party_inventory: Inventory

func _ready() -> void:
	party_inventory = Inventory.new()
	_load_all_data()

func _load_all_data() -> void:
	_load_resources("res://resources/classes", character_classes)
	_load_resources("res://resources/skills", skills)
	# Charger les items depuis le nouveau dossier data/items
	_load_resources_recursive("res://data/items", items)
	_load_resources("res://resources/enemies", enemies)
	_load_resources("res://resources/quests", quests)

	print("[DataManager] Loaded %d classes, %d skills, %d items, %d enemies, %d quests" % [
		character_classes.size(),
		skills.size(),
		items.size(),
		enemies.size(),
		quests.size()
	])

func _load_resources(path: String, target: Dictionary) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path + "/" + file_name
				var resource = load(full_path)
				if resource:
					var key = file_name.get_basename()
					target[key] = resource
			file_name = dir.get_next()
		dir.list_dir_end()

func _load_resources_recursive(path: String, target: Dictionary) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path + "/" + file_name
			if dir.current_is_dir() and not file_name.begins_with("."):
				# Charger récursivement les sous-dossiers
				_load_resources_recursive(full_path, target)
			elif file_name.ends_with(".tres"):
				var resource = load(full_path)
				if resource:
					var key = file_name.get_basename()
					target[key] = resource
					print("[DataManager] Loaded item: %s" % key)
			file_name = dir.get_next()
		dir.list_dir_end()

func get_character_class(class_id: String) -> CharacterClass:
	return character_classes.get(class_id)

func get_skill(skill_id: String) -> Skill:
	return skills.get(skill_id)

func get_item(item_id: String) -> Item:
	return items.get(item_id)

func get_enemy_template(enemy_id: String) -> Character:
	return enemies.get(enemy_id)

func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id)

func create_enemy(enemy_id: String, level_modifier: int = 0) -> Character:
	var template = enemies.get(enemy_id)
	if template:
		var enemy = template.duplicate()
		if level_modifier != 0:
			enemy.level += level_modifier
			# Ajuster les stats en fonction du niveau
			for _i in range(abs(level_modifier)):
				if level_modifier > 0:
					enemy.max_hp += 10
					enemy.strength += 2
					enemy.intelligence += 1
					enemy.dexterity += 1
				else:
					enemy.max_hp = max(10, enemy.max_hp - 10)
					enemy.strength = max(1, enemy.strength - 2)
			enemy.current_hp = enemy.max_hp
		return enemy
	return null

func get_random_enemies_for_area(area: String, count: int = 3) -> Array[Character]:
	var result: Array[Character] = []
	var area_enemies: Array = []

	# Filtrer les ennemis par zone
	for enemy_id in enemies:
		var enemy = enemies[enemy_id]
		if enemy.has_meta("area") and enemy.get_meta("area") == area:
			area_enemies.append(enemy_id)

	if area_enemies.is_empty():
		# Si pas d'ennemis spécifiques, prendre tous les ennemis
		area_enemies = enemies.keys()

	# Créer le groupe d'ennemis
	for i in count:
		if area_enemies.size() > 0:
			var enemy_id = area_enemies[randi() % area_enemies.size()]
			var enemy = create_enemy(enemy_id, randi_range(-1, 2))
			if enemy:
				result.append(enemy)

	return result

func add_starting_items() -> void:
	# Ajouter des objets de départ
	var potion_hp = get_item("potion_hp_small")
	if potion_hp:
		party_inventory.add_item(potion_hp, 3)

	var potion_mp = get_item("potion_mp_small")
	if potion_mp:
		party_inventory.add_item(potion_mp, 2)

	print("[DataManager] Starting items added. Inventory has %d slots" % party_inventory.get_slot_count())

func get_all_classes() -> Array:
	return character_classes.values()

func get_all_items() -> Array:
	return items.values()

func get_shop_items(shop_type: String) -> Array[Item]:
	var shop_items: Array[Item] = []

	for item in items.values():
		if item.has_meta("shop_type"):
			var types = item.get_meta("shop_type")
			if types is Array and shop_type in types:
				shop_items.append(item)
			elif types is String and types == shop_type:
				shop_items.append(item)

	return shop_items

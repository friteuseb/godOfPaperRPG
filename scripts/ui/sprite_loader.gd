extends Node
class_name SpriteLoader
## Utilitaire pour charger les sprites des personnages et ennemis

# Chemins des dossiers de sprites
const CHARACTERS_PATH = "res://assets/sprites/characters/"
const ENEMIES_PATH = "res://assets/sprites/enemies/"
const UI_PATH = "res://assets/sprites/ui/"
const EFFECTS_PATH = "res://assets/sprites/effects/"
const PORTRAITS_PATH = "res://assets/sprites/portraits/"

# Cache des textures chargées
static var texture_cache: Dictionary = {}

static func get_character_sprite(sprite_name: String) -> Texture2D:
	return _load_sprite(CHARACTERS_PATH, sprite_name)

static func get_enemy_sprite(sprite_name: String) -> Texture2D:
	return _load_sprite(ENEMIES_PATH, sprite_name)

static func get_portrait(portrait_name: String) -> Texture2D:
	return _load_sprite(PORTRAITS_PATH, portrait_name)

static func get_ui_sprite(sprite_name: String) -> Texture2D:
	return _load_sprite(UI_PATH, sprite_name)

static func get_effect_sprite(effect_name: String) -> Texture2D:
	return _load_sprite(EFFECTS_PATH, effect_name)

static func _load_sprite(base_path: String, sprite_name: String) -> Texture2D:
	var cache_key = base_path + sprite_name

	# Vérifier le cache
	if texture_cache.has(cache_key):
		return texture_cache[cache_key]

	# Essayer différentes extensions
	var extensions = [".png", ".webp", ".jpg", ".svg"]

	for ext in extensions:
		var full_path = base_path + sprite_name + ext
		print("[SpriteLoader] Trying: %s" % full_path)
		if ResourceLoader.exists(full_path):
			var texture = load(full_path)
			if texture:
				print("[SpriteLoader] SUCCESS: Loaded %s" % full_path)
				texture_cache[cache_key] = texture
				return texture

	# Sprite non trouvé, retourner un placeholder
	print("[SpriteLoader] NOT FOUND: %s%s" % [base_path, sprite_name])
	return _get_placeholder_texture()

static func _get_placeholder_texture() -> Texture2D:
	# Créer une texture placeholder simple
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.5, 0.5, 0.5, 1.0))

	# Dessiner un X pour indiquer un sprite manquant
	for i in range(32):
		image.set_pixel(i, i, Color.RED)
		image.set_pixel(31 - i, i, Color.RED)

	return ImageTexture.create_from_image(image)

# Précharger tous les sprites d'un dossier
static func preload_folder(folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var base_name = file_name.get_basename()
				_load_sprite(folder_path, base_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		print("[SpriteLoader] Preloaded folder: %s" % folder_path)

# Nettoyer le cache
static func clear_cache() -> void:
	texture_cache.clear()

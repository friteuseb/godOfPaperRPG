extends Node
## Audio Manager - Gère la musique et les effets sonores

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music: String = ""

var music_volume: float = 0.8
var sfx_volume: float = 1.0
var master_volume: float = 1.0

const MAX_SFX_PLAYERS = 8

func _ready() -> void:
	# Créer le lecteur de musique
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# Créer un pool de lecteurs SFX
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	# Créer les bus audio s'ils n'existent pas
	_setup_audio_buses()

func _setup_audio_buses() -> void:
	# Les bus sont normalement configurés dans le projet
	# Mais on peut les créer dynamiquement si nécessaire
	pass

func play_music(music_name: String, fade_duration: float = 1.0) -> void:
	if current_music == music_name:
		return

	var music_path = "res://assets/audio/music/%s.ogg" % music_name
	if not ResourceLoader.exists(music_path):
		music_path = "res://assets/audio/music/%s.mp3" % music_name

	if not ResourceLoader.exists(music_path):
		print("[AudioManager] Music not found: %s" % music_name)
		return

	var stream = load(music_path)
	if stream:
		if music_player.playing and fade_duration > 0:
			# Fade out puis play
			var tween = create_tween()
			tween.tween_property(music_player, "volume_db", -80, fade_duration)
			tween.tween_callback(func():
				music_player.stream = stream
				music_player.volume_db = linear_to_db(music_volume * master_volume)
				music_player.play()
			)
		else:
			music_player.stream = stream
			music_player.volume_db = linear_to_db(music_volume * master_volume)
			music_player.play()

		current_music = music_name

func stop_music(fade_duration: float = 1.0) -> void:
	if fade_duration > 0 and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()
	current_music = ""

func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	var sfx_path = "res://assets/audio/sfx/%s.wav" % sfx_name
	if not ResourceLoader.exists(sfx_path):
		sfx_path = "res://assets/audio/sfx/%s.ogg" % sfx_name

	if not ResourceLoader.exists(sfx_path):
		print("[AudioManager] SFX not found: %s" % sfx_name)
		return

	var stream = load(sfx_path)
	if stream:
		# Trouver un lecteur libre
		var player = _get_free_sfx_player()
		if player:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			if pitch_variation > 0:
				player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
			else:
				player.pitch_scale = 1.0
			player.play()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# Si tous occupés, utiliser le premier (interrompre)
	return sfx_players[0]

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume * master_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume * master_volume)

# SFX prédéfinis pour le jeu
func play_ui_click() -> void:
	play_sfx("ui_click")

func play_ui_hover() -> void:
	play_sfx("ui_hover", 0.1)

func play_battle_hit() -> void:
	play_sfx("battle_hit", 0.15)

func play_battle_miss() -> void:
	play_sfx("battle_miss")

func play_battle_critical() -> void:
	play_sfx("battle_critical")

func play_spell_cast() -> void:
	play_sfx("spell_cast", 0.1)

func play_level_up() -> void:
	play_sfx("level_up")

func play_gold_gain() -> void:
	play_sfx("gold_gain", 0.1)

func play_quest_complete() -> void:
	play_sfx("quest_complete")

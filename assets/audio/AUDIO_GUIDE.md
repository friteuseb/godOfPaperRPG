# Guide des fichiers audio

## Structure
```
assets/audio/
├── music/      # Musiques de fond (.ogg ou .mp3)
└── sfx/        # Effets sonores (.wav ou .ogg)
```

## Fichiers SFX attendus (dans sfx/)

### Interface utilisateur
- `ui_click.wav` - Clic sur bouton
- `ui_hover.wav` - Survol de bouton

### Combat
- `battle_hit.wav` - Coup qui touche
- `battle_miss.wav` - Coup esquive
- `battle_critical.wav` - Coup critique

### Magie
- `spell_cast.wav` - Lancement de sort

### Progression
- `level_up.wav` - Montee de niveau
- `gold_gain.wav` - Gain d'or
- `quest_complete.wav` - Quete terminee

## Fichiers musique attendus (dans music/)

- `main_menu.ogg` - Menu principal
- `tavern.ogg` - Taverne/repos
- `exploration.ogg` - Exploration
- `battle.ogg` - Combat
- `boss.ogg` - Combat de boss
- `victory.ogg` - Victoire

## Format recommande
- SFX: WAV 16-bit, 44.1kHz mono
- Musique: OGG Vorbis, 44.1kHz stereo, ~128kbps

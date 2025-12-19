# Guide d'Installation des Assets

## Structure des Dossiers

```
assets/
├── sprites/
│   ├── characters/     # Sprites des héros (guerrier.png, mage.png, etc.)
│   ├── enemies/        # Sprites des ennemis (gobelin.png, squelette.png, etc.)
│   ├── portraits/      # Portraits pour dialogues
│   ├── ui/             # Éléments d'interface
│   ├── effects/        # Effets visuels (explosions, magie)
│   └── backgrounds/    # Fonds de décor
├── fonts/              # Polices pixel art
└── audio/
    ├── music/          # Musiques de fond (.ogg, .mp3)
    └── sfx/            # Effets sonores (.wav, .ogg)
```

## Packs Recommandés (Gratuits)

### Personnages
1. **RPG Heroes & Classes** - https://beowulf.itch.io/rpg-heroes-classes-pixel-art-huge-pack
   - Renommer les fichiers: `warrior.png` → `guerrier.png`, etc.

2. **Cute Fantasy RPG** - https://kenmi-art.itch.io/cute-fantasy-rpg
   - Idéal pour un style mignon

### Ennemis
1. **Anokolisa RPG Pack** - https://anokolisa.itch.io/free-pixel-art-asset-pack-topdown-tileset-rpg-16x16-sprites
   - Inclut 8 types d'ennemis

### Effets Magiques
1. **Pixel Magic Effects** - https://itch.io/game-assets/free/tag-magic/tag-pixel-art

## Nommage des Fichiers

### Personnages (characters/)
- `guerrier.png` - Sprite du Guerrier
- `mage.png` - Sprite du Mage
- `voleur.png` - Sprite du Voleur
- `clerc.png` - Sprite du Clerc

### Ennemis (enemies/)
- `gobelin.png`
- `loup.png`
- `squelette.png`
- `chauve-souris_géante.png`
- `araignée_géante.png`
- `orc.png`
- `troll.png`
- `chevalier_noir.png`
- `fantôme.png`
- `démon_mineur.png`

### UI (ui/)
- `button_normal.png`
- `button_hover.png`
- `button_pressed.png`
- `panel_bg.png`
- `hp_bar_fill.png`
- `mp_bar_fill.png`
- `gold_icon.png`

## Format Recommandé

- **Taille**: 32x32, 64x64, ou 128x128 pixels
- **Format**: PNG avec transparence
- **Style**: Pixel art, pas d'anti-aliasing

## Import dans Godot

Après avoir placé les fichiers:
1. Godot les importe automatiquement
2. Pour le pixel art, désactiver le filtre:
   - Sélectionner l'image dans le FileSystem
   - Onglet "Import"
   - Décocher "Filter"
   - Cliquer "Reimport"

Ou globalement dans `Project > Project Settings > Rendering > Textures`:
- `Default Texture Filter` = `Nearest`

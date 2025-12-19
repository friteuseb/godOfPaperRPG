# God of Paper RPG

Un RPG tour par tour inspiré de *Knights of Pen and Paper*, développé avec Godot 4.

## 🎮 Description

God of Paper RPG est un jeu de rôle rétro où vous incarnez un groupe d'aventuriers autour d'une table de JDR virtuelle. Créez votre équipe, explorez des donjons, combattez des monstres et accomplissez des quêtes épiques !

## ✨ Fonctionnalités

- **Création de personnages** : Choisissez parmi 4 classes (Guerrier, Mage, Voleur, Clerc)
- **Combat tour par tour** : Système tactique avec compétences, magie et objets
- **Exploration** : Visitez différentes zones avec des ennemis uniques
- **Progression** : Gagnez de l'expérience, montez en niveau, améliorez vos stats
- **Sauvegarde** : Sauvegardez votre progression à tout moment

## 🚀 Installation

### Prérequis

- [Godot 4.2+](https://godotengine.org/download) (version standard ou .NET)

### Lancer le jeu

1. Ouvrez Godot 4
2. Cliquez sur "Importer"
3. Naviguez vers le dossier du projet
4. Sélectionnez `project.godot`
5. Cliquez sur "Ouvrir" puis "Importer & Éditer"
6. Appuyez sur F5 pour lancer le jeu

### Export Web

1. Dans Godot, allez dans `Projet > Exporter`
2. Ajoutez un preset "Web" si ce n'est pas fait
3. Cliquez sur "Exporter le projet"
4. Les fichiers seront dans le dossier `exports/web/`

## 🎯 Comment jouer

1. **Menu principal** : Nouvelle partie ou Continuer
2. **Création d'équipe** : Ajoutez jusqu'à 4 personnages
3. **Table de jeu** :
   - 🗺️ Explorer : Changez de zone
   - ⚔️ Combattre : Lancez un combat aléatoire
   - 🛏️ Se reposer : Restaurez HP/MP (coûte de l'or)
   - ☰ Menu : Sauvegarde et options

## 🗡️ Classes

| Classe | Description | Force | Spécialité |
|--------|-------------|-------|------------|
| Guerrier | Tank robuste | STR/CON | Dégâts physiques |
| Mage | Lanceur de sorts | INT | Dégâts de zone |
| Voleur | Assassin agile | DEX/LUK | Critiques |
| Clerc | Soigneur sacré | INT/CON | Soins |

## 📁 Structure du projet

```
godOfPaperRPG/
├── assets/          # Ressources (sprites, audio)
├── scenes/          # Scènes Godot (.tscn)
│   ├── main/        # Menus et écrans principaux
│   ├── battle/      # Scène de combat
│   └── ui/          # Éléments d'interface
├── scripts/         # Code GDScript
│   ├── core/        # Managers (Game, Audio)
│   ├── battle/      # Système de combat
│   ├── characters/  # Classes de personnages
│   ├── data/        # Items, quêtes, inventaire
│   └── ui/          # Contrôleurs d'interface
└── resources/       # Données (items, skills, enemies)
```

## 🛠️ Technologies

- **Moteur** : Godot 4.2
- **Langage** : GDScript
- **Rendu** : Compatibility (OpenGL ES 3.0 / WebGL 2.0)
- **Export** : Web (HTML5), Windows, Linux, macOS

## 📝 Roadmap

- [ ] Système de boutique
- [ ] Journal de quêtes
- [ ] Plus de classes et compétences
- [ ] Boss et donjons spéciaux
- [ ] Mode multijoueur local
- [ ] Assets pixel art personnalisés

## 📄 Licence

Ce projet est sous licence MIT.

---

*Développé avec ❤️ et 🎲*

# 109 — Dios llama · Improbables

Reviewed: 2026-08-28
Slice: nouveau pack Street de dix questions, quatre langues et dix stills verticaux
Tests: validation finale i18n + Street `26 runs, 2168 assertions, 0 failures`; chargeur + références `2 runs, 1739 assertions, 0 failures`; validation assets `10/10`, tous en `1024×1824`
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés

## Feeling

Le joueur doit ressentir la surprise, puis l’espérance : ce qui semblait disqualifier une personne n’a pas empêché Dieu de l’appeler. La dernière révélation ajoute l’appartenance — Rahab, étrangère à Jéricho, entre dans l’histoire de Jésus.

## 1 — Game experience

Boucle Street : obstacle apparent → identifier la personne → suspense/timer progressif → révélation courte « avant → après » → source biblique → points croissants → prochain renversement.

La courbe commence par les figures les plus accessibles (Moïse, Abraham et Sara, David), augmente la proximité des distracteurs (Moïse/Jérémie/Gédéon), puis finit sur Pierre, Paul et Rahab. Les points, le temps et l’intensité suivent exactement la courbe Street ; Rahab porte le slam à 25 points.

La formulation évite deux raccourcis doctrinaux : Moïse n’est pas diagnostiqué « bègue », et Abraham n’est pas dit stérile. Le texte parle de sa parole difficile, du soutien d’Aaron et de Sara qui ne pouvait pas avoir d’enfant.

## 2 — UI design

Le verbe reste compris en moins de deux secondes : reconnaître et choisir. Les questions tiennent sur mobile, les choix sont des noms courts, et chaque image garde une zone atmosphérique haute pour le HUD existant. Aucun nouveau chrome n’est requis.

États couverts par la boucle Street existante : idle, pressed, locked, success, failure, completed. Les images alternent contrastes Light/Dark sans changer les composants.

## 3 — Art direction

Le langage commun montre une personne dans l’ombre ou à un seuil, puis un axe de lumière or ouvre la mission. L’or reste lumière/signature, jamais texte décoratif.

- Celestial Dark : Moïse, Abraham et Sara, Gédéon, Joseph, Paul, Rahab.
- Celestial Light : David, Esther, Jérémie, Pierre.
- Motifs : seuil, chemin, ciel ouvert, appel, dignité du personnage.
- VFX runtime : verre et contraste pilotés par `quiz_stills.yml`; l’artwork porte déjà le mouvement de l’ombre vers la lumière.

Les dix stills sont des illustrations verticales originales, cohérentes en palette et lisibles à taille téléphone.

## Theme engine

N/A — pack Street ; aucune modification de l’atmosphère globale du hub.

## Four seats

N/A — Street solo.

| Seat | Verb tonight |
|---|---|
| Street | Reconnais la personne, choisis, découvre le renversement |

## Tension

WELCOME avec Moïse → EASY SUCCESS avec Abraham/Sara et David → CURIOSITY avec Gédéon → COMPETITION avec Joseph/Esther → SURPRISE avec Jérémie/Pierre → POWER-UP avec Paul → BIG FINAL avec Rahab.

Le pack deviendrait un quiz silencieux si les réponses n’expliquaient que le fait biblique. Ici, chaque réponse ferme la boucle en nommant le déplacement vécu sans transformer la difficulté en honte.

## Finale

N/A Live. Le dixième item Street est néanmoins un slam à 25 points et porte le renversement le moins attendu du pack.

## Languages

Copie lue en es, pt-BR, en et fr. Parité exacte des dix identifiants, choix et révélations. Le français utilise le tutoiement Street implicite et les espaces avant `?`; le portugais est brésilien ; l’anglais évite le ton de jeu télévisé ; l’espagnol reste la source.

`noche-i18n: PASS`

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Une seule promesse émotionnelle, répétée sans monotonie sur dix vies différentes.
- La précision biblique renforce le message au lieu de le refroidir.
- Les stills racontent le passage avant même la révélation écrite.
- La progression va du très connu au surprenant sans piéger le joueur.

## What feels weak

- Le score Social dépend encore des systèmes Street partagés (défis et partage), pas d’une mécanique propre au pack.

## Required before approval

- None.

## Evidence

La suite combinée `locale_files + quiz_definition` a aussi été lancée : `20 runs, 3228 assertions`. Son unique échec signale 39 stills manquants dans les packs de paraboles en cours dans le même workspace ; les dix chemins `improbables` sont présents et validés.

## Night director

Oui, je jouerais une autre question : chaque réponse promet un nouveau type de renversement, et la difficulté monte sans trahir le thème pastoral du pack.

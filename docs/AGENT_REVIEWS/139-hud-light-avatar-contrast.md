# M139 — Avatar HUD lisible en Celestial Light

Reviewed: 2026-08-29
Slice: reconnaître immédiatement son avatar dans le HUD Light
Tests: `bundle exec rails test test/components/hud/bar_component_test.rb test/integration/ui_chrome_test.rb` — 15 runs, 1 757 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — amélioration du composant HUD partagé
Copy: N/A — aucun texte modifié

## Feeling

Identité et fierté : le joueur doit reconnaître son emblème aussi vite en Light qu’en Dark.

## 1 — Game experience

Le HUD répond mieux à « qui suis-je ? » sans modifier sa navigation ni sa progression. L’avatar devient un repère immédiat au lieu d’un petit dessin perdu dans les anneaux ivoire.

## 2 — UI design

La règle est limitée à `data-hud-theme="celestial-light"`. Le noyau du médaillon devient bleu nuit, l’image utile passe de 90 % à 98 %, et l’anneau d’or gagne en séparation avec le fond clair. Les dimensions du composant et sa cible tactile ne changent pas.

## 3 — Art direction

Le médaillon Light reprend la profondeur du Dark sans assombrir le HUD : noyau marine, métal or, fin liseré ivoire. La saturation et le contraste de l’image augmentent légèrement uniquement en Light.

## Theme engine

N/A. Le sélecteur repose sur le thème sémantique existant et ne crée ni toggle ni markup parallèle.

## Four seats

Street — l’identité du joueur reste lisible avant le pack, les ressources et le menu.

## Tension

N/A. Cette tranche améliore l’identité, pas le rythme d’une ronde.

## Finale

N/A.

## Languages

N/A. Aucun texte modifié.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- L’emblème sombre occupe presque tout le médaillon et ne flotte plus dans le crème.
- L’or reste une bordure métallique, pas une nappe jaune.
- Le Dark est intact grâce au sélecteur strictement Light.

## What feels weak

- Les avatars sources très peu contrastés pourront encore demander un traitement propre à l’asset.

## Required before approval

- None.

## Evidence

- HUD Light inspecté à 390 × 844 et 1440 × 900.
- Taille d’image utile mesurée à environ 36,5 px sur mobile et 40,7 px sur desktop.
- Aucun débordement horizontal.
- Console : 0 erreur, 0 avertissement.
- Captures Light/Dark existantes comparées; aucune règle Dark modifiée.
- Aucun flux de permission ni message éditorial.

## Night director

Oui : l’identité est immédiate et laisse le pack courant rester le prochain verbe.

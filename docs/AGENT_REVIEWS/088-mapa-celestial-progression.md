# M88 — Carte céleste de progression

Reviewed: 2026-08-27
Slice: `/mapa`, progression d’aventure
Tests: `bin/rails test test/services/quizzes/world_test.rb test/i18n/locale_files_test.rb test/controllers/street_hub_controller_test.rb:524` — 12 runs, 190 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validated

## Feeling

Fierté, émerveillement et envie immédiate de débloquer le prochain pack.

## 1 — Game experience

La boucle est lisible : voir sa position → choisir une famille → toucher le prochain pack → jouer → revenir voir le chemin avancer. Le pack courant pulse, les packs terminés portent étoiles et validation, les packs verrouillés donnent un retour haptique discret.

## 2 — UI design

Le pack courant est compris en moins de deux secondes. Le HUD conserve l’identité et les ressources du joueur ; le dock garde Aventure active et les quatre destinations voisines accessibles. Les familles, stats, paliers et packs gardent des cibles tactiles larges. États couverts : courant, terminé, verrouillé avec indice, déverrouillage, catégorie active/atténuée, palier replié/ouvert et mouvement réduit.

## 3 — Art direction

Celestial Light assumé : nuages ivoire, îles sacrées, route lumineuse et or métallique. Le décor porte le voyage tandis que les cartes translucides restent secondaires.

## Theme engine

N/A — `/mapa` est un monde d’aventure Celestial Light dédié, pas un thème utilisateur.

## Four seats

N/A street — qui/où : position et palier ; quoi maintenant : pack courant ; autour : familles, récompenses et classement.

## Tension

Le chemin verrouillé, les coffres de dizaine et les paliers futurs rendent la prochaine récompense visible sans transformer la carte en écran administratif.

## Finale

N/A.

## Languages

Copie relue en es, pt-BR, en et fr ; test de parité vert.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 10 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le trajet, le prochain nœud et les paliers futurs racontent immédiatement l’aventure.
- Le HUD et le dock maintiennent l’orientation sans concurrencer la carte.
- Le rendu reste fidèle au mockup tout en affichant honnêtement les 17 packs existants.

## What feels weak

- Les paliers Maître et Légende restent volontairement vides tant que le catalogue ne contient pas ces packs.

## Required before approval

- None.

## Night director

Oui : le prochain nœud verrouillé et le coffre visible donnent une raison claire de lancer un pack.

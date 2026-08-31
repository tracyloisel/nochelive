# M155 — Le Cercle sous le chapitre

Reviewed: 2026-08-30
Slice: lire un chapitre, contribuer à un échange de rama, puis revenir naturellement au texte
Tests: suite Circle/liseuse ciblée — 66 runs, 731 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme (if `/` atmosphere): N/A — aucune surface Hub n’est modifiée.
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr validés par le test de parité.

## Feeling

Appartenance tranquille : « je peux poser une question ou aider quelqu’un sans quitter le chapitre ni entrer dans un fil social bruyant. »

## 1 — Game experience

La boucle est `lire → remarquer une question de la rama → répondre directement → voir l’échange prendre de la valeur → continuer la lecture`. Le composeur est déjà ouvert sous le chapitre ; le premier échange est déjà développé sur bureau. Sur mobile, une carte mène au fil focalisé, où un unique champ de réponse est ouvert immédiatement.

Les votes ne concernent que la conversation racine. Ils classent réellement l’onglet « Populaires » mais n’apparaissent pas comme une monnaie de réseau social sur chaque réponse. « Non résolus » reste une question sans réponse visible ; « Récentes » suit l’activité visible.

## 2 — UI design

Le verbe en deux secondes est « partager » ou « répondre ». Le Cercle se place après le chapitre, jamais dans un rail qui coupe la lecture. Le composeur compact donne le type question/réflexion, le contexte de verset et la confidentialité de rama sans modal ni étape intermédiaire. Les cartes ont une seule colonne éditoriale, un rail de vote vertical et une action de détail mobile.

Les états actifs, lecture seule, vide, focus profond, message nouvellement publié, validation, vote et modération restent explicites. La recette manuelle à 1440 × 900, 768 × 1024 et 390 × 844 confirme l’absence de débordement ; à 768 px, les cartes d’engagement passent sous le fil au lieu de l’écraser. Les contrôles tactiles du composeur atteignent 44 px.

## 3 — Art direction

La liseuse garde sa lumière ivoire et sa montagne dorée. L’or reste un signal rare — vote, bord de contexte, onglet actif et envoi — tandis que le texte et les cartes conservent une densité calme. Le Cercle ressemble à une continuité de l’Écriture, pas à un réseau séparé.

## Theme engine (hub `/` only, or N/A)

N/A — aucune atmosphère du Hub n’est modifiée.

## Four seats

N/A — boucle communautaire asynchrone : la place active est celle de la personne qui lit et choisit d’offrir une réponse attentionnée.

## Tension

Tension douce : une question non résolue attend une voix ; une réponse rend l’échange vivant, sans compétition individuelle. Le vote met en avant l’utilité d’un fil seulement quand le membre choisit l’onglet « Populaires ».

## Finale

N/A — aucune mécanique de soirée Live ni de couronne n’est modifiée.

## Languages

PASS — les nouveaux libellés du composeur, des filtres, de l’engagement communautaire et de la modération existent en espagnol, portugais brésilien, anglais et français.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9.5 |
| Impact visuel | 8.5 |
| Feedback | 9 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 8.5 |

## Verdict

PASS

## What works

- Le fil est lisible dans la cadence du chapitre, puis détaillé sur mobile sans doubler le composeur.
- Les trois tris représentent des règles de données réelles et sûres, pas des onglets décoratifs.
- Le vote hiérarchise une conversation ; il ne gamifie pas les réponses individuelles.
- Les aperçus de modération restent discrets dans le flux ; le vote complet est réservé au détail.

## What feels weak

- Le bouton Publier reste désactivé tant que le texte est vide, donc sa couleur est volontairement plus calme que l’état prêt à envoyer.

## Required before approval

- Aucun.

## Evidence (optional)

- Console navigateur sans erreur après les trois recettes responsive.
- Tests de contrôleur et de service couvrent le focus profond, la confidentialité, les votes de conversation, les tris et la parité des locales.

## Night director

Oui : je peux aider quelqu’un dans la même respiration que ma lecture, puis revenir à la parole sans avoir eu l’impression d’entrer dans un autre produit.

# M090 — La Parole dans le shell du jeu

Reviewed: 2026-08-27
Slice: parcours hebdomadaire, écran de question
Tests: `bin/rails test test/controllers/study_journey_test.rb` — 5 runs, 90 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A — aucune copie déplacée

## Feeling

Curiosité, découverte et continuité : le joueur doit sentir qu’il poursuit une aventure biblique, pas qu’il quitte le jeu pour ouvrir une page web.

## 1 — Game experience

Le lien périmé reprend désormais le parcours actif au lieu de casser la boucle sur une erreur Rails. La question garde le cycle anticipation → choix → révélation → explication → progression → question suivante.

## 2 — UI design

Le parcours utilise un canvas bord à bord sur téléphone, un plateau centré sur le hall à partir de 720 px, le HUD joueur commun en haut et le dock principal en bas. Le CTA suivant reste l’unique action dorée.

États couverts : question idle/pressed, réponse correcte/incorrecte, choix atténués, progression, parcours terminé et récupération d’un lien périmé.

## 3 — Art direction

Émotion : émerveillement calme. Composition : peinture biblique en haut, HUD local, arche ivoire en bas. Famille : Celestial Dark dictée par le ciel dramatique des Psaumes, avec or en signature et lumière volumétrique. Sur grand écran, le plateau vit dans le hall céleste au lieu de flotter sur un fond gris.

## Theme engine

N/A — ce n’est pas le hub.

## Four seats

N/A — aventure solo.

## Tension

La progression visible sur dix questions et le score entretiennent l’envie de continuer. La révélation reste immédiate ; aucune attente morte n’est ajoutée.

## Finale

La dixième réponse mène à la cérémonie de parcours existante.

## Languages

N/A — aucun nouveau texte joueur.

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
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le parcours est maintenant un écran de jeu plein cadre sur téléphone, encadré par le HUD et le dock communs.
- Un lien ancien ramène au parcours actif sans révéler ni ouvrir le parcours d’un autre joueur.
- Le décor et le HUD restent visibles avant la feuille de question.

## What feels weak

- Le parcours reste volontairement plus contemplatif que les packs Street ; son intensité repose sur la progression et la découverte.

## Required before approval

- None.

## Night director

Oui : la récupération transparente, la progression sur dix et le CTA unique préservent l’élan vers la question suivante.

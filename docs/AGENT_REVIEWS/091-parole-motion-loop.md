# M091 — La Parole, boucle animée

Reviewed: 2026-08-27
Slice: entrée, réponse, progression, question suivante et cérémonie du parcours
Tests: `bin/rails test test/controllers/study_journey_test.rb` — 6 runs, 121 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: PASS — es / pt-BR / fr / en relus

## Feeling

Curiosité calme, lumière reçue, puis envie immédiate de poursuivre.

## 1 — Game experience

La boucle est lisible : entrée coordonnée → choix pressé → micro-suspense → révélation locale → son/haptique → score et progression → explication → transition suivante. La révélation est identifiée par la réponse créée et ne se rejoue pas lors d’une revisite.

## 2 — UI design

HUD et dock restent stables. La cérémonie possède son propre défilement, un héros compact, un CTA visible dans la première moitié de l’écran et un plancher typographique lisible. Correct, erreur, progression et `+1` possèdent des mouvements distincts sans retarder l’interaction. `prefers-reduced-motion` neutralise les mouvements spatiaux et réduit les View Transitions.

## 3 — Art direction

Le ciel Celestial Dark respire très lentement par une lumière locale. L’or est réservé au progrès, au gain et au CTA. Aucun voile global ni animation décorative rapide ne couvre la peinture.

## Theme engine

N/A — ce n’est pas le hub.

## Four seats

N/A — aventure solo.

## Tension

Le délai de 140–160 ms avant révélation crée une respiration, sans transformer l’étude en jeu sous pression.

## Finale

La dixième question conserve la transition vers le titre, le médaillon animé, la lumière reçue, la progression annuelle et les personnes qui ont terminé la même semaine.

## Languages

PASS — les libellés de progression, estaca/rama et pagination sont natifs dans les quatre langues.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Les animations signifient une action ou un gain réel.
- La Parole utilise trois cues dédiés, distincts des sons de quiz : `study_light` pour la découverte juste, `study_miss` pour une erreur douce et `study_turn` pour le passage à la question suivante. Le feedback haptique accompagne toujours la révélation.
- Une revisite reste calme et ne rejoue pas la récompense.

## What feels weak

- L’estaca prioritaire n’apparaît que pour un profil rattaché à une rama ; un invité voit honnêtement la liste globale.

## Required before approval

- None.

## Night director

Oui : la réponse produit maintenant un payoff perceptible puis conduit directement à la prochaine envie.

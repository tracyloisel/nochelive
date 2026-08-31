# M159 — Invitation au direct dans le Hub

Reviewed: 2026-08-31
Slice: invitation contextuelle aux rappels de la prochaine Noche Live
Tests: `bundle exec rails test test/system/web_push_experience_test.rb` — 7 runs, 158 assertions, 2 failures, 1 error (préexistants/hors CSS : sélection du Live imminent, dialogue PWA, champ profil) ; scénario isolé ligne 185 — 1 run, 3 assertions, 1 failure avant le prompt (`.hub-live.is-imminent` absent)
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — aucune copie, règle d’audience, fréquence ou destination modifiée

## Feeling

Anticipation calme : le joueur sent que le direct approche et peut choisir d’être prévenu, sans subir une bannière technique ni une demande système automatique.

## 1 — Game experience

La boucle reste volontaire : contexte du Live → choix explicite → permission système → confirmation. Le refus reste visible, calme et réversible. Aucune permission n’est déclenchée au chargement.

## 2 — UI design

Le verbe principal reste l’activation du rappel. La composition devient compacte : médaillon, message, puis action. Le CTA conserve au moins 44 px, le refus 44 px, et le desktop n’étire plus le bouton sur toute la fenêtre. États conservés : idle, pressed, loading, success, failure, installation requise, réassignation, dismissed.

## 3 — Art direction

Le prompt devient un verre local traversé par le monde du Hub, avec liseré, reflet et médaillon d’or. Le CTA est un métal translucide, jamais un aplat jaune. La même anatomie consomme les tokens Celestial Light et Dark.

## Theme engine

Même partial, même logique et même structure dans les deux familles. Seuls les tokens du monde courant déterminent verre, texte, bordure, profondeur et or.

## Four seats

N/A — Home Street. Le prompt reste subordonné à la prochaine Noche Live et ne remplace ni le HUD, ni le hero, ni le carrousel de la rama.

## Tension

Le médaillon et le reflet donnent un signal d’imminence discret. Aucun pulse continu ni urgence artificielle.

## Finale

N/A.

## Languages

N/A — les clés existantes es, pt-BR, en et fr sont inchangées.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS WITH NOTES

## What works

- Le prompt ne concurrence plus la Home avec une bannière géante.
- Le monde reste visible sous un verre local Light/Dark.
- La permission reste consécutive à un appui explicite.

## What feels weak

- Le scénario système du Live imminent s’arrête actuellement avant l’apparition du prompt, car la classe attendue n’est plus rendue par la Home actuelle.

## Required before approval

- Réparer séparément le contrat de fixture/sélection `.hub-live.is-imminent` afin de rétablir les captures automatisées du prompt Noche Live.

## Night director

Oui : la proposition promet un bénéfice immédiat sans interrompre le joueur ni transformer la Home en panneau de réglages.

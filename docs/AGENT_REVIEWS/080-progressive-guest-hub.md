# M080 — Hub invité sans barrage

Reviewed: 2026-08-27
Slice: arrivée invité → prénom au premier quiz → reprise immédiate
Tests: `bin/rails test test/integration/progressive_street_identity_test.rb test/services/hubs/screen_test.rb test/i18n/locale_files_test.rb test/models/person_test.rb` — 28 runs, 289 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validated

## Feeling

Curiosité immédiate : le visiteur entre dans le monde avant qu’on lui demande quoi que ce soit, puis comprend que donner son prénom protège naturellement son aventure.

## 1 — Game experience

Le hub n’est plus une attente administrative. Anticipation (hero biblique) → action (Jouer) → prénom utile → quiz → progression sauvegardée. Le pack choisi reste mémorisé pendant la création du profil.

## 2 — UI design

Le HUD invité porte l’invitation de profil sans masquer le hero, les panneaux ni le dock. Au seuil du quiz, une seule question et un seul CTA. L’avatar reste une personnalisation ultérieure.

## 3 — Art direction

La composition existante reste intacte : artwork narratif, HUD, hero et or signature. Aucun formulaire n’est posé sur le premier regard. Aucun nouvel artwork ni VFX n’est nécessaire pour ce changement de friction.

## Theme engine

Une seule Home et le même markup en Celestial Light/Dark. Le profil invité ne crée ni thème ni branche CSS. Le thème continue de venir du manifest de l’artwork.

## Four seats

Street — qui : invité ou prénom dans le HUD ; où : rama absente clairement nommée ; quoi maintenant : Jouer ; autour de moi : Live, défis, communauté et progression restent visibles.

## Tension

Le quiz conserve sa boucle. Le prénom intervient exactement au moment où la récompense peut devenir personnelle, sans écran d’accueil mort.

## Finale

N/A — aucune manche Live modifiée.

## Languages

Les nouvelles invitations ont été relues en es, pt-BR, en et fr ; test de parité vert.

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

- Le monde précède l’identité.
- Le prénom a une raison immédiate et le pack choisi n’est pas perdu.
- Sans rama, la carte Live ne montre plus un événement arbitraire.

## What feels weak

- L’avatar temporaire est volontairement neutre jusqu’à la personnalisation de fiche.

## Required before approval

- None.

## Night director

Oui : le premier geste est désormais Jouer, et la seule interruption protège une récompense déjà désirée.

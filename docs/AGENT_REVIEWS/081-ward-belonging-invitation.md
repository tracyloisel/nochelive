# M081 — L’invitation à rejoindre sa paroisse

Reviewed: 2026-08-27
Slice: tuile Live sans paroisse → prénom invité → choix de la paroisse
Tests: `bin/rails test test/integration/progressive_street_identity_test.rb test/services/hubs/screen_test.rb test/controllers/street_profiles_controller_test.rb test/i18n/locale_files_test.rb` — 40 runs, 442 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validated

## Feeling

Appartenance : la paroisse n’est plus un réglage requis mais la promesse de retrouver son équipe, ses défis et sa place dans la Ligue.

## 1 — Game experience

Anticipation (une Noche près de soi) → désir social (amis, défis, Ligue) → action (trouver sa paroisse) → prénom utile pour l’invité → sélection. Un joueur déjà identifié va directement au choix.

## 2 — UI design

Le verbe « Trouver ma paroisse » est lisible en deux secondes. Le médaillon, le titre, trois bénéfices concrets et le CTA composent une invitation unique, visible sans animation d’entrée fragile et adaptée au mobile.

## 3 — Art direction

La tuile reprend les tokens de l’artwork actif : surface nocturne en Celestial Dark et surface claire en Celestial Light, avec l’or signature pour guider le regard sans ressembler à un formulaire.

## Theme engine

Une seule tuile et un seul markup. Sans artwork Live propre, elle hérite explicitement du mode et de l’atmosphère du backdrop du Hub ; aucun thème utilisateur ni skin dupliqué.

## Four seats

Street — qui : invité ou joueur identifié ; où : sa future paroisse ; quoi maintenant : la trouver ; autour de moi : une Noche proche, des défis entre amis et une place dans la Ligue.

## Tension

La tuile transforme une donnée manquante en prochaine promesse sociale. Le parcours s’arrête seulement le temps de demander le prénom indispensable à la création du profil.

## Finale

N/A — aucune manche Live modifiée.

## Languages

Le titre, la promesse, les trois bénéfices et le CTA ont été relus en es, pt-BR, en et fr ; test de parité vert.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- La valeur sociale précède la demande de donnée.
- Le parcours invité crée le profil avec le seul prénom puis reprend vers le choix de paroisse.
- Le thème est déterminé par l’image d’arrière-plan réellement utilisée.

## What feels weak

- L’avatar reste volontairement absent de ce parcours express et sera choisi plus tard.

## Required before approval

- None.

## Evidence

Vérification visuelle sur la Home locale : tuile visible, Celestial Dark, bénéfices et CTA lisibles dans le viewport.

## Night director

Oui : l’action promet désormais des personnes, des rendez-vous et un enjeu collectif, pas seulement un paramètre à renseigner.

# M175 — La Parole de Sagesse dans l’Aventure

Reviewed: 2026-09-03
Slice: un pack Street permanent de dix questions dans le parcours normal
Tests: `bundle exec rails test test/models/quiz_definition_test.rb test/services/quizzes/world_test.rb test/services/quizzes/start_pack_test.rb test/controllers/street_hub_controller_test.rb test/controllers/street_plays_controller_test.rb test/controllers/quiz_answers_controller_test.rb` — 77 runs, 5 018 assertions, 0 failures
Contract/media: `bundle exec rails test test/lib/expedition_fast_contract_test.rb test/lib/media_pipeline_test.rb` — 21 runs, 2 029 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: le master français et les copies es, en et pt-BR proviennent du dossier FAST validé

## Feeling

Curiosité puis liberté : découvrir que D&A 89 parle de désirs, de discernement et de gratitude, pas seulement d’une liste d’interdits.

## 1 — Game experience

Le pack devient l’étape 15, immédiatement après les débuts de l’Église. La boucle Street existante reste intacte : anticipation par le visuel, choix, révélation orale, points croissants, puis prochaine question. Le pack s’ouvre normalement lorsque `inicios` est terminé.

## 2 — UI design

La map conserve son langage de chemin numéroté : le pack occupe le nœud 15 du niveau Apprenti et la voie Sagesse. Les dix questions réutilisent la surface `/jugar` déjà prouvée à 390 × 667, y compris quatre vrais/faux à deux choix.

## 3 — Art direction

Les dix masters 9:16 approuvés sont exportés dans le catalogue média permanent. Huit scènes sont Celestial Light et deux Celestial Dark ; chaque question garde le traitement déterminé par le Conseil FAST, sans recadrage automatique ni nouvelle génération.

## Theme engine

N/A : aucun changement du monde visuel de la map ou de la Home.

## Four seats

Street solo : le joueur voit où il se trouve, le pack suivant et son état. Le Live du vendredi n’est pas modifié.

## Tension

La courbe permanente est respectée : 5, 5, 5, 8, 8, 8, 12, 12, 15, puis slam à 25 points ; les chronos commencent à la question 4.

## Finale

La question 10 reste le slam Street à 25 points. Aucun changement du système Live.

## Languages

Parité complète fr, es, en et pt-BR. Les IDs de choix et la bonne réponse sont identiques entre les quatre langues.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 8.5 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8.5 |

## Verdict

PASS

## What works

- L’emplacement historique est intelligible et ne casse pas la progression existante.
- Les vrais/faux deviennent un format runtime natif à deux choix.
- Les scènes validées restent la source de lumière et de contraste du quiz.

## What feels weak

- Comme tous les futurs packs de la map actuelle, son titre n’est mis en avant qu’à son déverrouillage ; avant cela, le chemin montre surtout son numéro.

## Required before approval

- None.

## Evidence

Map inspectée à 390 × 844, 768 × 1024 et 1440 × 900. Le DOM rendu expose `pack-dc89_word_of_wisdom`, nœud 15, catégorie `sagesse`, état verrouillé attendu pour le profil local. Aucune erreur ni alerte console.

## Night director

Oui : le pack alterne lecture du texte, situations concrètes et vrais/faux rapides, puis finit sur une question de révélation à fort enjeu de score.

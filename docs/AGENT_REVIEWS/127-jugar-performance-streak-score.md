# M127 — Jugar : série et points sous le cri

Reviewed: 2026-08-29
Slice: le résultat d’une bonne réponse, entre le cri et l’action suivante
Tests: `bundle exec rails test test/controllers/quiz_answers_controller_test.rb` — 8 runs, 176 assertions, 0 failures; `bundle exec rails test test/system/street_quiz_visual_test.rb -n '/correct answer performance/'` — 1 run, 79 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — le thème du quiz continue de venir de l’artwork via `Quizzes::Chrome`
Copy: `.agents/skills/noche-i18n/SKILL.md` — clés existantes relues en es, pt-BR, en et fr

## Feeling

Fierté immédiate et élan : la bonne réponse n’est plus seulement validée, elle fait monter une série visible et un score qui vit.

## 1 — Game experience

Boucle : réponse juste → cri → série et total apparaissent → `+N` rejoint la couronne → Lire ou Suivant. Le joueur comprend immédiatement ce qu’il vient de gagner et ce qu’il peut prolonger à la prochaine question. Les points bruts restent inchangés ; la série ne promet aucun multiplicateur fictif.

Paliers visuels réels : 1, 2, 3, 5 et 10 bonnes réponses consécutives. Une erreur conserve son feedback bienveillant et remet la série à zéro via le moteur existant.

## 2 — UI design

Sous le cri, une seule ligne de performance montre `SÉRIE` avec la flamme, cinq jalons de progression, puis `POINTS` avec la couronne, le total animé et le gain séparé. Le cri arrive d’abord ; la ligne de performance suit au temps Reward ; Lire et Suivant arrivent ensuite.

États couverts : première bonne réponse, série 2, série 10, score qui compte, mouvement réduit, Celestial Light, Celestial Dark, 390×844, 768×1024 et 1440×900. Les libellés restent au plancher typographique et le composant ne déborde jamais du monde du quiz.

## 3 — Art direction

La composition garde le décor comme monde. Le feedback flotte dans une zone de ciel avec une nappe locale sombre, deux filets d’or et des jalons en losange. Il a le rythme d’un jeu musical sans copier son habillage ni poser une carte de dashboard. Le bloc a été remonté au-dessus des visages et ne concurrence ni la peinture, ni la question, ni les actions.

## Theme engine

N/A. Le même markup hérite des tokens de l’artwork et a été contrôlé dans les deux familles célestes.

## Four seats

Street — qui : le joueur et sa série ; où : le pack et la question restent dans le HUD ; quoi maintenant : Lire ou Suivant ; autour de moi : la course amicale demeure au-dessus du monde sans masquer la performance.

## Tension

Les cinq jalons rendent la prochaine bonne réponse désirable. La tension vient de la continuité de la série, pas d’un multiplicateur de points inexistant.

## Finale

N/A pour la cérémonie finale. Le score brut produit ici continue d’alimenter sans conversion la cérémonie, les classements et les défis.

## Languages

noche-i18n: PASS. `street.card_streak_label`, `chrome.points_word`, `quiz.combo`, `chrome.points` et `street.points_gained` existent et restent naturels en español, português do Brasil, English et français.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 9 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 10 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le joueur voit simultanément sa série, son total et le gain de la réponse.
- L’animation réutilise le vrai compteur de score et respecte le mode mouvement réduit.
- Les visages restent lisibles et les actions ont leur propre temps d’entrée.

## What feels weak

- Le son reste celui du bon résultat et des paliers de série existants ; aucun nouveau cue n’était nécessaire pour cette tranche.

## Required before approval

- None.

## Evidence

- Captures : `tmp/street-shots/jugar-performance-{light,dark}-{390x844,768x1024,1440x900}.png`.
- Le test système vérifie la géométrie, le plancher typographique, l’absence de débordement et l’absence d’erreur navigateur sévère.

## Night director

Oui : le prochain jalon est visible, le total vient de bouger, et Suivant promet immédiatement une chance de prolonger la série.

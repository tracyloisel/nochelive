# M153 — Noche Watch, invitation Twitch

Reviewed: 2026-08-30
Slice: la page publique d’une Noche Live, de l’invitation au spectacle temps réel
Tests: `bundle exec rails test test/controllers/nights_controller_test.rb test/services/nights/projection_test.rb test/services/nights/broadcast_test.rb test/i18n/locale_files_test.rb test/integration/ui_chrome_test.rb` — 21 runs, 1856 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — cette surface adopte Celestial Dark depuis l’illustration du quiz
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr présents, YAML et test de parité verts

## Feeling

Appartenance immédiate à la rama, excitation d’un direct déjà vivant, compétition lisible et envie de rejoindre les joueurs plutôt que de seulement observer.

## 1 — Game experience

La boucle est maintenant visible sans console de présentateur : identifier la Noche et sa rama → voir le temps restant et l’activité → s’inscrire ou jouer → recevoir les événements du direct via la tuile défi → suivre équipes et progression → revenir en Watch après le score final. La date et le moteur pilotent l’expérience automatiquement. Une personne arrivée en cours de soirée garde une action claire pour rejoindre une équipe existante.

## 2 — UI design

Le verbe en deux secondes est « M’inscrire » ou « Jouer ». Le HUD partagé reste fixe en haut et reçoit uniquement le thème commun `celestial-dark`; aucune peau locale ou variante legacy n’a été créée. La notification mobile est fixe et utilise la grammaire de la tuile défi. Classement, événements et progression ont été désengorgés; la progression est regroupée par quiz avec dix segments compacts.

États couverts : planifié, lobby, live, terminé, inscrit, équipe à choisir, prêt à jouer, événement live, progression en attente/active/terminée et mouvement réduit.

## 3 — Art direction

Le visuel du quiz reste la scène principale. Un voile local, le sceau de rama et le métal doré du CTA construisent la hiérarchie sans ajouter une illustration concurrente. Les pictogrammes et emblèmes viennent du vocabulaire partagé du produit. La page s’identifie comme Noche Live au premier regard par la couronne, le direct, le code, la rama et le trio score/progression/événements.

## Theme engine

N/A — aucun changement du Hub `/`.

## Four seats

| Seat | Verb tonight |
|---|---|
| Host | N/A par décision produit : la Noche est automatique, sans rôle ni console de présentateur |
| Chapel (controller) | S’inscrire, choisir son équipe de rama, jouer la séquence de quiz |
| Remote | Rejoindre la même Noche et jouer avec la rama |
| TV / Twitch | Regarder le direct, lire classement/progression/événements, scanner et rejoindre |

## Tension

Le compte à rebours installe l’urgence. Pendant la partie, les changements de tête, séries et réponses alimentent la tuile live et le fil; les rails de questions matérialisent la distance restante. Sans ces événements la page deviendrait un tableau de scores calme, d’où leur priorité visuelle et leur présence persistante sur mobile.

## Finale

Cette tranche ne change pas la mécanique de dernière question. Le joueur garde l’écran de score final normal, puis revient à la Watch pour voir l’issue collective et le classement des équipes calculé par somme des points.

## Languages

Les nouvelles chaînes ont été relues en **es**, **pt-BR**, **en** et **fr**. YAML valide et test de parité vert.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8.5 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 8.5 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- La rama devient un signal d’identité avant le titre du quiz.
- Le CTA doré a une anatomie de commande de jeu, une promesse locale et une cible confortable.
- Le HUD partagé, le code, le statut live et la tuile événement restent lisibles sans se concurrencer.
- La tuile défi garde le direct visible sur mobile, y compris après défilement.
- Les équipes à joueurs passent devant les équipes vides en cas d’égalité à zéro, sans inventer de points.

## What feels weak

- Une Noche sans aucune réponse reste volontairement calme jusqu’au premier événement du moteur; le visuel, le compte à rebours et l’invitation portent alors seuls l’énergie.

## Required before approval

- None.

## Evidence

- Contrôle visuel réel : 1440×900, 768×1024, 390×844 et 844×390.
- Aucun débordement horizontal aux quatre formats.
- HUD et tuile live fixes validés avant et après défilement mobile.
- Console navigateur : 0 erreur, 0 avertissement.
- JavaScript : 43 tests, 43 réussites.
- `bundle exec rails zeitwerk:check` : vert.

## Night director

Oui : la page donne maintenant l’impression qu’une soirée existe déjà dans une communauté précise, et le prochain geste pour y entrer est évident.

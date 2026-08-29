# M136 — Coupe franche du legacy quiz et carte

Reviewed: 2026-08-29
Slice: suppression des chaînes mortes rencontrées dans le voisinage du moteur de défis, de `/jugar` et de `/mapa`
Tests: `bundle exec rails test test/controllers/street_hub_controller_test.rb test/controllers/street_plays_controller_test.rb test/controllers/quiz_answers_controller_test.rb test/models/sfx_test.rb test/i18n/locale_files_test.rb` — 60 runs, 1343 assertions, 0 failures; contrat HUD anti-legacy — 1 run, 2 assertions, 0 failures; `bundle exec rails zeitwerk:check` — PASS; `bundle exec rails assets:precompile` — PASS
UI: `.agents/skills/noche-ui/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — parité des quatre locales validée

## Décision

Le nouveau moteur ne conserve aucun ancien chemin « au cas où ». Dès qu'un élément
du domaine touché est confirmé sans appelant de production, sa chaîne entière est
retirée dans la même slice : implémentation, styles, contrôleur, traductions et tests.
Les documents historiques restent des décisions datées ; ils ne sont pas des
appelants runtime.

## Supprimé

- ancien rail de niveau du quiz et son contrôleur Stimulus ;
- ancien trail/map injecté dans le quiz et son service `Quizzes::Trail` ;
- ancienne carte à corde, ses partials de pack/porte/chemin et son contrôleur ;
- ancienne carte de partage de score, ses étoiles et `Quizzes::ShareCard` ;
- sélecteurs, keyframes, clés i18n et specs qui ne décrivaient que ces chemins ;
- assertions devenues fausses sur le son de coffre et la couleur d'une tuile supprimée.

## Conservé parce qu'actif

- la carte actuelle `mapa-*`, ses 28 nœuds et `hub_map_controller` ;
- `Quizzes::Jump`, encore appelé pour reprendre ou rejouer un pack ;
- la modale de partage actuelle, son toast et ses événements honnêtes ;
- le rail Campus, le suivi de performance, le fan-out multi-duels et les receipts.

## UI et validation

Le HUD Light n'est plus teinté par une classe de page : son apparence dépend de
`data-hud-theme`, comme le contrat sémantique du composant l'exige. Le rendu a été
contrôlé à 390×844 sur `/`, `/mapa` et `/jugar` : aucun débordement horizontal, aucun
sélecteur de l'ancien moteur, HUD et suivi de performance présents. La carte expose
28 nœuds actuels.

## Verdict

PASS — le successeur reste visible et jouable ; le code retiré n'a plus aucune
référence applicative ou asset compilé.

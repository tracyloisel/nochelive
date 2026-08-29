# M143 — Chercher une paroisse dans la lumière

Reviewed: 2026-08-29
Slice: `/buscar` et `/buscar?cambiar=1` — attente silencieuse, recherche, résultat et vide
Tests: `bundle exec rails test test/controllers/searches_controller_test.rb` + test système ciblé — 7 runs, 115 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés

## Feeling

Appartenance et confiance : la paroisse est une porte vers les autres joueurs, pas une formalité administrative.

## 1 — Game experience

La boucle est courte : reconnaître le décor → taper une ville ou partager sa position → voir un retour immédiat → choisir sa paroisse → continuer avec sa progression intacte. L’état initial reste silencieux : aucune paroisse n’est proposée sans saisie ni coordonnées. Une paire `lat` + `lng` présente dans l’URL lance bien la recherche de proximité.

## 2 — UI design

Le verbe se comprend en moins de deux secondes : saisir puis chercher, ou partager sa position. Le champ n’a plus de chrome natif cassé et l’action de recherche reste dorée. États inspectés : idle silencieux, focus/pressed, loading, résultat, vide et réduction de transparence/mouvement. Les targets interactives mesurent au moins 44 px. Le composant est tokenisé ; cette scène reste Celestial Light parce que l’artwork l’impose.

## 3 — Art direction

Émotion : être guidé vers sa communauté. Composition : HUD, titre court, panneau de verre haut dans l’image, église et chemin lumineux largement visibles. Monde : Celestial Light. L’or reste le médaillon et l’action ; le texte demeure ivoire sur l’artwork et encre dans le verre. Aucun VFX supplémentaire : le chemin peint fournit déjà le mouvement et l’appel.

## Theme engine

N/A — ce n’est pas le hub `/`. La famille Light découle de l’artwork de paroisse, pas d’un toggle.

## Four seats

N/A — surface street. Qui : le HUD conserve l’identité. Où : le joueur choisit sa paroisse. Maintenant : saisir ou utiliser sa position. Autour de moi : le résultat mène à la communauté locale.

## Tension

Utilitaire court : la tension est l’incertitude de trouver sa paroisse, résolue par un résultat lisible ou une issue officielle claire. Aucun faux mécanisme de quiz.

## Finale

N/A.

## Languages

Les libellés existants de recherche restent servis par `t()` dans les quatre langues. Aucun nouveau texte joueur n’est introduit par la règle de sélection.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- Le verre translucide laisse le chemin et l’église raconter l’histoire.
- Le champ, le bouton et les résultats gardent une géométrie stable de 390 à 1440 px.
- Aucun contenu communautaire n’est proposé avant une saisie ou des coordonnées explicites.

## What feels weak

- La recherche dépend encore du délai du locator officiel lorsque le répertoire local ne répond pas ; le statut couvre cette attente sans la rendre magique.

## Required before approval

- None.

## Evidence

- Captures inspectées : `buscar-phone.png`, `buscar-tablet.png`, `buscar-benidorm-star.png`, `buscar-desktop.png`.
- Navigateur réel inspecté à 390 × 844, 768 × 1024 et 1440 × 900 ; aucun débordement horizontal ni erreur console liée au changement.

## Night director

Oui : la page ne bloque plus l’élan. Elle fait sentir que choisir une paroisse rapproche immédiatement le joueur des siens.

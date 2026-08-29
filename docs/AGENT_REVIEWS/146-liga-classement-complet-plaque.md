# M146 — La porte vers le classement complet devient une plaque de Cour

Reviewed: 2026-08-29
Slice: `/liga`, CTA secondaire vers le classement complet
Tests: contrôleur — 10 runs, 121 assertions, 0 failures; système visuel — 1 run, 92 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — destination Liga, pas le Hub `/`
Copy: N/A — aucun libellé ni comportement éditorial modifié

## Feeling

Curiosité compétitive : la Cour continue au-delà des trois rivaux visibles et cette porte donne envie d’entrer dans le classement complet.

## 1 — Game experience

La boucle reste courte : aperçu du podium → envie de situer davantage de joueurs → ouverture du classement complet. Le CTA secondaire gagne en désirabilité sans concurrencer l’action de jeu principale « Continuer le quiz ».

## 2 — UI design

Le verbe reste immédiatement lisible. La structure passe d’une pilule web vide à une plaque en trois temps : couronne, libellé centré, flèche directionnelle. Le texte garde un plancher de 14 px sur téléphone et revient proprement sur deux lignes ; il tient sur une ligne dès la tablette. Les deux repères visuels font 44 × 44 px. Les états idle, hover, pressed, focus-visible et reduced-motion utilisent les interactions existantes de la Liga.

## 3 — Art direction

Celestial Light est imposé par la Cour. Le verre ivoire, le double liseré or, le médaillon de couronne et le sceau navy créent un objet cérémoniel identifiable comme Noche Live. L’or reste une signature et le bouton ne vole pas la priorité au CTA principal doré.

## Theme engine

N/A — aucun changement du Hub et aucune variante de thème. La plaque consomme les tokens de la Liga Celestial Light.

## Four seats

Street — qui : le joueur dans sa communauté ; où : Cour des Couronnes ; quoi maintenant : ouvrir le classement complet ; autour de moi : podium, rivaux et défis.

## Tension

Le podium crée la comparaison ; la plaque promet la profondeur du classement. Son statut secondaire évite de casser la tension du prochain quiz.

## Finale

N/A — aucune règle ni cérémonie de fin modifiée.

## Languages

N/A — le libellé existant et déjà traduit dans les quatre locales est inchangé.

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

- La silhouette rectangulaire sculptée rompt avec la pilule web générique.
- La couronne annonce le classement avant même la lecture.
- Le sceau navy fournit un point d’action contrasté sans devenir un second CTA doré.
- La profondeur glass, les liserés et l’éclat au survol appartiennent à la Cour.
- La typographie reste lisible à 14 px minimum sur 390 px.

## What feels weak

- Aucun défaut bloquant après la seconde passe typographique.

## Required before approval

- None.

## Evidence

- Mockup Liga Celestial Light ouvert avant modification.
- Captures interactives inspectées à 390 × 844, 768 × 1024 et 1280 × 720.
- Suite visuelle du projet exercée à 390 × 844, 768 × 1024 et 1440 × 900, y compris reduced-motion.
- Aucun overflow horizontal ; plaque de 68 px de haut ; repères latéraux 44 × 44 px.
- Parcours exercé : clic sur la plaque → `/liga?scope=ward&view=full` → panneau « Classement complet » présent.
- Console finale : 0 warning, 0 error.
- `street_leaderboards_controller_test` : 10 runs, 121 assertions, green.
- Test système Liga : 1 run, 92 assertions, green.

## Night director

Oui. Après le podium, la plaque fait sentir qu’il reste une Cour entière à explorer sans détourner du prochain quiz.

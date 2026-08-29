# M147 — Continuer le quiz devient la plaque d’or de la Cour

Reviewed: 2026-08-29
Slice: `/liga`, action primaire de reprise du parcours
Tests: contrôleur — 10 runs, 129 assertions, 0 failures; système visuel — 1 run, 92 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — destination Liga, pas le Hub `/`
Copy: N/A — libellés, sélection du pack et destination inchangés

## Feeling

Élan et progression : après avoir vu la distance qui le sépare d’un rival, le joueur doit sentir que reprendre son parcours est l’action évidente pour avancer.

## 1 — Game experience

La boucle reste intacte : comparaison dans la Cour → reprise du quiz → réponse → score → nouveau rang. La plaque dorée donne davantage de poids au prochain geste sans inventer une récompense ni modifier le pack choisi.

## 2 — UI design

« Continuer le quiz » reste le verbe principal et le seul CTA doré. Il reprend la structure en trois temps de la plaque du classement : médaillon Lecture, libellé centré, sceau fléché. La variante dorée conserve une hiérarchie nette au-dessus de la plaque ivoire secondaire. Le texte reste à 14 px minimum, revient sur deux lignes à 390 px et tient sur une ligne dès 768 px. Les repères latéraux mesurent 46 × 46 px. Idle, hover, pressed, focus-visible et reduced-motion sont couverts.

## 3 — Art direction

Celestial Light découle de la Cour. La surface mélange or translucide, lumière blanche, double liseré et flou d’arrière-plan. Le médaillon métallique à gauche évoque le départ d’une manche ; le sceau navy à droite donne la direction. La matière est apparentée au bouton du classement sans effacer la différence primaire/secondaire.

## Theme engine

N/A — aucun changement du Hub ou du moteur de thèmes. Les tokens or, navy et ivoire existants sont réutilisés.

## Four seats

Street — qui : le joueur classé ou en route vers le classement ; où : Cour des Couronnes ; quoi maintenant : reprendre son parcours ; autour de moi : rival, podium et classement.

## Tension

La distance en couronnes crée l’envie ; la plaque or transforme cette envie en prochaine action immédiate. Le classement complet reste disponible mais visuellement secondaire.

## Finale

N/A — aucune règle de manche ou cérémonie modifiée.

## Languages

N/A — les traductions et le nom dynamique du pack sont inchangés.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
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

- Le duo de plaques partage une grammaire sans avoir le même poids.
- Le verre doré reste lumineux et premium, sans redevenir un gros bouton jaune plein.
- Le médaillon Lecture annonce le quiz avant la lecture du pack.
- Le nom long du pack reste lisible sur téléphone et desktop.
- Le clic conserve exactement la destination `/jugar`.

## What feels weak

- Aucun défaut bloquant après inspection responsive.

## Required before approval

- None.

## Evidence

- Mockup Liga Celestial Light ouvert avant modification.
- Captures interactives inspectées à 390 × 844, 768 × 1024 et 1280 × 720.
- Suite visuelle exercée à 390 × 844, 768 × 1024 et 1440 × 900, y compris reduced-motion.
- Aucun overflow horizontal ; CTA de 71 px de haut ; repères latéraux 46 × 46 px.
- Parcours exercé : clic sur « Continuer le quiz » → `/jugar` → quiz et quatre choix présents, aucune réponse envoyée.
- Console finale : 0 warning, 0 error.
- `street_leaderboards_controller_test` : 10 runs, 129 assertions, green.
- Test système Liga : 1 run, 92 assertions, green.

## Night director

Oui. La distance au rival crée le désir, et la plaque dorée rend immédiatement évident le geste qui peut la réduire.

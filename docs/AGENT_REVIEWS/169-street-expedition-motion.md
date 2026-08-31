# M169 — Mouvement de la page Expéditions

Reviewed: 2026-08-31
Slice: `/mapa` — navigation Parcours complet / Expéditions, carousel et détail
Tests: `bundle exec rails test test/controllers/street_hub_controller_test.rb test/services/expeditions/presentation_test.rb test/system/street_map_expeditions_visual_test.rb` — 30 runs, 500 assertions, 0 failures ; contrat motion — 1 run, 69 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: N/A — aucun libellé ajouté dans cette itération

## Feeling

Curiosité immédiate, puis confiance : le monde reste stable pendant que le
joueur explore une autre lecture de sa progression. Une tuile choisie devient
une destination claire, pas un changement de page administratif.

## 1 — Game experience

La boucle de la carte est : apercevoir les expéditions → glisser ou choisir une
tuile → voir son statut et son rythme → ouvrir la prochaine porte. Le mouvement
sert cette boucle : le carousel répond immédiatement, les transitions de route
indiquent le sens, et le détail reçoit un seul payoff vertical. Aucun écran
d’attente ni cascade qui ralentit le choix.

## 2 — UI design

Verbe en deux secondes : `Découvrir`, puis `Ouvrir cette porte` ou `Continuer`.
Le HUD et le décor restent ancrés. L’entrée révèle d’abord le titre, puis les
onglets, puis le contenu ; les cartes ne sont pas animées une par une.

Les pressions tactiles sont distinctes du hover desktop. Les flèches gardent
44px de cible, le scroll natif conserve le snap horizontal, et
`prefers-reduced-motion` rend immédiatement tous les contenus visibles et
neutralise les transitions nommées.

## 3 — Art direction

Le mouvement suit la route céleste : avance latérale vers les Expéditions,
retour latéral vers le Parcours complet, et montée douce du héros lors de
l’ouverture d’une tuile. Le HUD ne quitte pas son ancrage ; les scrims restent
statiques pour que les titres blancs restent lisibles sur l’illustration.
L’or demeure réservé aux états actifs et aux CTA.

## Theme engine

N/A — `/mapa` utilise l’artwork street Celestial Light actuel. La grammaire de
mouvement ne dépend pas d’un thème utilisateur et reste compatible avec les
tokens de l’autre famille.

## Four seats

N/A — street solo, un téléphone.

## Tension

La carte crée une micro-anticipation sans imposer d’attente : le joueur voit le
prochain rythme (`3 jours`, `7 jours`, mois) et choisit son effort. Le carousel
est le geste d’exploration ; le héros confirme le choix ; la liste des portes
redonne immédiatement une prochaine action.

## Finale

N/A — aucune mécanique de quiz ou de finale n’est modifiée.

## Languages

N/A — aucune copie player-facing n’a été modifiée dans cette passe.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- Le mouvement de page et le mouvement du carousel ont des jobs distincts.
- Le sens de navigation est transmis par les View Transitions, avec une entrée
  CSS fonctionnelle si elles ne sont pas disponibles.
- Le mode réduit, les trois largeurs et les erreurs sévères de console sont
  couverts par le test système.

## What feels weak

- La direction latérale dépend du support natif des View Transitions ; le
  fallback conserve la hiérarchie mais pas le sens du trajet.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/map-expeditions/expeditions-390x844.png`
- `tmp/street-shots/map-expeditions/expedition-active-768x1024.png`
- `tmp/street-shots/map-expeditions/expedition-active-1440x900.png`
- `prefers-reduced-motion: reduce` vérifié par CDP ; console sévère vide.

## Night director

Oui. Le joueur peut scanner, glisser et choisir sans perdre son orientation. Le
prochain écran arrive comme une scène courte, pas comme un rechargement de
back-office.

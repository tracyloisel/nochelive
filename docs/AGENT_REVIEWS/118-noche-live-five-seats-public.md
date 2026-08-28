# M118 — Noche Live, cinq sièges et Public interactif

Reviewed: 2026-08-28
Slice: boucle complète lobby → manche → révélation → finale, sur cinq sièges
Tests: `bin/rails test` — 954 runs, 14 878 assertions, 0 failures, 0 errors
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — la refonte ne change pas le moteur du Hub
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents pour les nouveaux parcours

## Feeling

Entrer sans réfléchir, sentir immédiatement que la soirée est déjà en direct,
puis rester parce que chaque siège sait quoi regarder, quoi faire et quand le
résultat commun arrive. La finale doit donner la sensation d’un événement, pas
d’une page de résultats.

## 1 — Game experience

La boucle est désormais dirigée par le présentateur : intro, ouverture,
verrouillage, dévoilement, passage automatique perçu. Le joueur n’avance plus
la scène commune. Le Public peut répondre une fois, attendre sans spoiler, voir
son résultat, sa répartition et sa série, puis réagir. Les anciennes attentes
mortes deviennent des états contextualisés et reconnectables.

## 2 — UI design

Le verbe principal reste unique et doré. Joueur et Public gardent la scène au
profit d’un panneau jouable ; le présentateur garde son action au-dessus du
pupitre ; la TV garde prompt/révélation et score dans ses safe zones. Les états
open, locked, revealed, offline, finale et reduced-motion ont une expression
distincte.

## 3 — Art direction

Celestial Dark vient de la nuit biblique : bleu profond, rayon céleste, silhouettes
et or réservé à l’action ou au résultat. Le nouveau diptyque Salomon offre une
composition portrait aux téléphones et une vraie composition cinéma à la TV.
La cérémonie reste posée sur l’artwork au lieu de le remplacer par une carte.

## Four seats

| Seat | Verb tonight |
|---|---|
| Host | Conduire : une action principale, les réponses dans le pupitre |
| Chapel | Jouer puis regarder la salle et la TV pendant le suspense |
| Remote | Répondre avec la salle, sans révélation anticipée |
| Public | Pronostiquer, attendre le direct, comparer, réagir |
| TV / Twitch | Comprendre et ressentir sans téléphone obligatoire |

## Tension

La question est ouverte à tous les sièges compatibles, le choix devient
irréversible, puis le présentateur verrouille et dévoile. La finale conserve sa
mécanique de vol Casa tout en retardant score et vérité visuelle jusqu’à la
cue finale.

## Finale

Un retardataire peut encore voler la couronne. La bonne réponse est utilisée
en interne pour déterminer l’éligibilité au vol, mais le score et la vérité
visuelle attendent le couronnement. Joueur, Public et TV convergent ensuite vers
la même cérémonie.

## Languages

Les clés nouvelles sont parallèles dans es, pt-BR, en et fr. Le contenu YAML de
jeu reste localisé par le système existant.

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
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- cinq rôles réellement distincts autour d’un même état autoritaire ;
- entrée sans code, sans fiche obligatoire et sans écran de choix d’équipe ;
- Public anonyme utile, réactif et protégé du décalage Twitch ;
- hiérarchie de révélation et finale nettement plus spectaculaire ;
- responsive vérifié du 320×568 au 2560×1440, paysage inclus.

## What feels weak

- le lot 1 Public n’a volontairement ni progression globale ni mini-défis ;
- le ressenti du délai Twitch réel dépend encore d’une répétition humaine ;
- certains anciens styles Noche restent regroupés dans une grande feuille CSS
  et méritent une extraction ultérieure, sans bloquer ce lot.

## Required before approval

- Aucun veto logiciel. La répétition humaine multi-appareils reste requise avant
  une généralisation à une grande audience Twitch.

## Evidence

Parcours navigateur réels sur mobile, tablette, paysage et écrans TV ; tests
de service Public, anti-spoiler, attribution automatique, autorité de manche et
révélation différée ; deux illustrations finales portrait/paysage.

## Night director

Oui : le prochain geste est clair, la vérité n’arrive plus trop tôt et le Public
a enfin une raison concrète de garder l’écran ouvert entre deux cues du direct.

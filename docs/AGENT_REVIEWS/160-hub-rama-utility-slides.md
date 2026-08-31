# M160 — Défis et Vidéothèque dans le carrousel du Hub

Reviewed: 2026-08-31
Slice: deux destinations publiques intégrées au rail horizontal « À la rama »
Tests: scénarios ciblés — 10 runs, 173 assertions, 0 failures ; test visuel — 1 run, 863 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — clés existantes es, pt-BR, en et fr réutilisées

## Feeling

Appartenance et curiosité : les activités, défis et contenus de l’Église forment un même monde local à parcourir horizontalement.

## 1 — Game experience

Une seule boucle de découverte remplace deux boutons isolés : apercevoir → glisser → reconnaître l’illustration → ouvrir. Les doublons sous le rail disparaissent. Une lecture terminée ne revient plus dans « À faire maintenant ».

## 2 — UI design

Défis et Vidéothèque utilisent exactement le contrat des slides existantes : même hauteur, même largeur responsive, même snap, même cible tactile, même kicker, titre, détail et action. États couverts par le lien natif : idle, hover, pressed, focus-visible et reduced motion.

## 3 — Art direction

Défis reçoit une scène chaleureuse de jeu intergénérationnel ; Vidéothèque reçoit le sanctuaire audiovisuel céleste déjà produit. Les scrims locaux maintiennent la lecture dans Celestial Light et Dark.

## Theme engine

Le markup est unique. Les deux slides consomment le même rail et les mêmes matériaux quelle que soit la famille déterminée par l’artwork du Hub.

## Four seats

N/A — Home Street. Le rail répond à « qu’est-ce qui se passe autour de moi ? » sans toucher au HUD.

## Languages

Les clés déjà validées sont réutilisées dans les quatre locales ; aucune nouvelle copie.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## Evidence

Captures inspectées en Celestial Light et Dark à 390×844 et 1440×900, dont le rail défilé jusqu’aux deux nouvelles slides. Le test visuel couvre aussi 320×568, 768×1024, 1024×768, 1536×1024 et 1920×1080. Console sans erreur sévère.

## Night director

Oui : le rail donne maintenant envie de voir ce qui vient après l’événement local, au lieu de finir sur deux raccourcis administratifs.

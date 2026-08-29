# M141 — Liga, Cour des Couronnes

Reviewed: 2026-08-29
Slice: `/liga`, synthèse compétitive et classement complet
Tests: ciblés — 25 runs, 271 assertions, 0 failures; suite générale — 1 033 runs, 40 902 assertions, 9 failures et 4 errors hors de cette slice au premier passage
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents et parsables

## Feeling

Le joueur doit ressentir qu’il entre dans une cour vivante où sa prochaine victoire a une cible claire, même lorsqu’il est loin du podium.

## 1 — Game experience

La synthèse raconte podium → rival immédiat → écart → prochaine action → voisinage → défi. Le classement complet ne remplace pas cette boucle : il devient une vue de recherche et d’exploration paginée par fenêtres de 100. Le moteur de défi reste l’autorité pour le duel focal et l’invitation.

## 2 — UI design

Le verbe en deux secondes est « rattraper ». Une seule action or poursuit le pack courant. La recherche, les changements de portée et l’invitation gardent des états lisibles de chargement, succès et échec. La barre de position n’apparaît que dans la longue liste et disparaît quand la ligne du joueur est visible.

Le plan de mouvement suit la même lecture : arrivée dans la cour, révélation des places 2 et 3, consécration du rang 1, puis montée de la rivalité et de l’action. La cérémonie tient en 890 ms, ne se joue qu’une fois par session et disparaît entièrement avec `prefers-reduced-motion`. La spécification complète est dans `docs/LIGA_MOTION_PLAN.md`.

## 3 — Art direction

Celestial Light vient du décor de cour existant, avec encre marine sur ivoire, podium métallique argent–or–bronze et or réservé au score, au métal et à l’action principale. Le HUD et le dock partagés restent la silhouette de Noche Live.

## Theme engine

N/A — `/liga` est une destination Celestial Light. Aucun toggle de thème n’est ajouté et le markup reste compatible avec les tokens partagés.

## Four seats

Street — qui : le joueur courant et de vraies personnes; où : paroisse ou pieu; quoi maintenant : rejoindre le rival immédiat; autour de moi : trois rangs voisins et les défis en cours.

## Tension

L’écart de couronnes vers le rang supérieur donne une tension locale qui reste crédible même au rang 1 000. Le podium garde l’aspiration longue, le rival garde le prochain désir atteignable.

## Finale

N/A — la slice renvoie au prochain parcours et alimente ensuite les cérémonies de score existantes.

## Languages

Les nouvelles clés ont une parité es, pt-BR, en et fr. Les milliers utilisent le séparateur attendu par langue et les unités paroisse/ward/ala sont pluralisées.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- 1 000 joueurs produisent exactement 100 lignes serveur dans la vue complète.
- Les rangs restent globaux et les égalités sont ordonnées de façon stable.
- Le podium 2–1–3, la rivalité et le CTA reproduisent la hiérarchie du mockup sans fausses données.
- La chorégraphie d’entrée raconte aspiration → rival immédiat → action sans retarder la lecture, et les changements de rang utilisent un FLIP limité aux lignes proches du viewport.
- 390×844, 768×1024 et 1440×900 passent sans débordement horizontal ni erreur console.

## What feels weak

- Les avatars disponibles sont des médaillons animaux plutôt que les portraits humains du concept; la composition compense sans inventer d’assets.
- À très grande distance du podium, le rival local est volontairement plus important que le leader absolu.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/liga-celestial-light-390x844.png`
- `tmp/street-shots/liga-celestial-light-768x1024.png`
- `tmp/street-shots/liga-celestial-light-1440x900.png`
- `tmp/street-shots/liga-celestial-light-full-390x844.png`
- Contrat mouvement ciblé : 1 run, 92 assertions, 0 failure; première entrée, non-répétition dans la session et réduction des animations couverts.
- QA navigateur : 390×844, 768×1024 et 1440×900, aucun débordement et aucune erreur console; 25 px mesurés entre le HUD et le titre à 1440 px.
- La suite générale reste rouge sur des contrats et surfaces déjà modifiés hors Liga; le seul sélecteur Liga obsolète découvert dans `street_ward_picks_controller_test.rb` a été actualisé et repasse au vert.
- Le contrat d’architecture ciblé reste rouge sur deux écarts préexistants hors Liga (`application.css` et `chrome_menu_controller.js`); aucun des deux fichiers n’est touché par ce plan.

## Night director

Oui : l’écran ne me demande pas de contempler 1 000 noms, il me donne une personne à rejoindre et un parcours à jouer maintenant.

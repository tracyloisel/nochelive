# M126 — Le Campus revient, avec une iconographie de lecture

Reviewed: 2026-08-29  
Slice: `/desafios` — décor Campus + repères pack / points / urgence / rival  
Tests: 8 tests contrôleur / 80 assertions + 4 tests visuels / 45 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: N/A — aucun libellé ni comportement éditorial modifié

## Feeling

Appartenance et compétition studieuse : « je retrouve mon Campus, je vois le livre à
ouvrir et je comprends tout de suite où sont les points, le temps et mon rival ».

## 1 — Game experience

La boucle M125 ne change pas : prochain pack → points en jeu → activité réelle du
rival → action → résultat. Cette passe rend ses quatre temps reconnaissables avant
même de lire les libellés. L’icône livre désigne le prochain pack, la couronne les
points, le sablier l’urgence et les deux profils autour du livre la rivalité active.

Le décor Campus avait été remplacé par la cour céleste lors de la passe précédente.
Cette interprétation diluait le lieu social et la promesse de lecture. Le groupe qui
lit sous les pavillons revient comme LCP et reste visible derrière le HUD et le titre.

## 2 — UI design

Les quatre médaillons sont décoratifs (`alt=""`, `aria-hidden`) et ne remplacent
aucune information textuelle. Ils apparaissent dans le résumé, le prochain pack et
les en-têtes de section. Les détails sont réservés aux tailles 42–43 px ; dans les
compteurs, ils deviennent des repères de 18–23 px sans élargir les contrôles.

Le CTA principal reste à 46 px de haut. Les autres actions restent 44–46 px. Les
médaillons n’ajoutent aucun nouveau clic, aucune permission et aucun état de
chargement. Le rendu initial, le rival live, le français et le mouvement réduit ont
été exercés.

## 3 — Art direction

Univers : Campus des Écritures, Celestial Light naturel. Le monde vient du feuillage,
des pavillons dorés, des livres ouverts et de la lumière solaire. Le chrome conserve
l’ivoire, l’encre et l’or métal. Les médaillons générés reprennent l’émail bleu nuit,
l’or gravé, le papier ivoire et une touche d’émeraude ; ils restent des objets de jeu,
pas des emoji ou des pictogrammes SaaS.

Le recadrage mobile `50% 15%` garde les lecteurs au-dessus de la carte de titre. Le
scrim est local et laisse le décor respirer. Celestial Dark est N/A pour cet artwork.

## ImageGen

Mode : outil ImageGen intégré, avec l’art Campus comme référence de lumière et le
premier médaillon comme référence de famille. Sorties finales transparentes et
réduites à 128 × 128 px :

- `public/media/ui/duel-campus/pack.png` ;
- `public/media/ui/duel-campus/points.png` ;
- `public/media/ui/duel-campus/urgency.png` ;
- `public/media/ui/duel-campus/rival.png`.

Prompt partagé : « premium mobile-game UI icon, polished painted 3D, front-facing
circular medallion, readable at 24–40 px, navy enamel, engraved warm-gold rim, ivory
highlights, restrained emerald accent, sunlit Campus warmth, genuine transparent
alpha, no text, no logo, no scene, generous padding ». Variantes sujet : livre ouvert
et étoile ; couronne et trois gemmes ascendantes ; sablier et flamme ; deux profils
face à face autour d’un livre avec un éclair central. Les deux sorties qui avaient
simulé la transparence avec un damier ont été corrigées par une passe ImageGen
`background-extraction` qui ne change que le fond.

## Theme engine

N/A — `/desafios` n’est pas le Hub `/`.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Ouvrir le pack indiqué par le livre |
| Mon rival | Continuer son pack, signalé par la médaille face-à-face |
| Autour de moi | Lire points, pack et urgence avant d’inviter |
| Prochaine envie | Passer devant puis revenir voir le résultat |

## Tension

Le sablier renforce une échéance réelle ; il n’invente ni compte à rebours ni fausse
activité. Les points et la progression restent les faits qui font monter la tension.

## Finale

Inchangée : la dernière question du pack vaut toujours 25 points. Aucun calcul de
score ni cérémonie n’a été modifié.

## Languages

N/A — aucune copie n’a bougé. La capture française a néanmoins été rejouée jusqu’à
`#street_quiz` pour vérifier que l’iconographie ne provoque ni troncature ni overflow.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.7 |
| Clarté | 9.5 |
| Impact visuel | 9.3 |
| Feedback | 8.7 |
| Progression | 9.3 |
| Social | 9.4 |
| Immersion | 9.5 |
| Accessibilité | 9.1 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.3 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- le Campus est de nouveau l’univers immédiatement reconnu ;
- les lecteurs restent visibles aux trois viewports de référence ;
- le livre, les points, l’urgence et le rival ont une famille visuelle cohérente ;
- les icônes sont transparentes, légères (25–27 Ko chacune) et non verbales ;
- le CTA reste compact et l’information textuelle reste autonome ;
- aucune erreur console `SEVERE`, aucun overflow horizontal.

## What feels weak

- les médaillons de compteur sont volontairement petits et servent de repères, pas
  d’illustrations détaillées ;
- le rendu sur appareil physique reste à vérifier ;
- les formulations de M125 n’ont pas reçu de validation éditoriale dans cette passe.

## Required before production approval

- Validation éditoriale des formulations proposées dans M125 ;
- contrôle sur un iPhone et un Android physiques, notamment à luminosité extérieure.

## Evidence

- captures inspectées : 390×844, 768×1024, 1440×900, défi actif 390, français 390,
  mouvement réduit 390 ;
- fond LCP : `media/social/campus-scriptures-master-v1.png`, recadrage mobile 15 % ;
- quatre PNG RGBA, 128 × 128 px, 25–27 Ko ;
- console navigateur : 0 entrée `SEVERE` sur les vues de référence et active ;
- tests contrôleur : 8 / 80, verts ; tests visuels : 4 / 45, verts.

## Night director

Oui. Le joueur ne voit plus une page de défis générique posée dans un palais : il
revient dans un lieu où des gens lisent ensemble, puis le livre et le rival lui donnent
une raison immédiate de jouer le pack suivant.

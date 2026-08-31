# M156 — Hub cinématique Salt Lake City

Reviewed: 2026-08-30
Slice: Home Hub plein cadre → carrousel horizontal de la rama → installation Noche Live
Tests: 52 runs, 26 993 assertions, 0 failures across the targeted Hub, PWA, LCP/media and state suites
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — N/A, no locale copy or key moved

## Feeling

Émerveillement d’abord, appartenance ensuite : le joueur doit avoir l’impression d’entrer dans un monde biblique vivant, puis reconnaître immédiatement sa rama et son prochain geste.

## 1 — Game experience

La boucle est lisible en deux secondes : monde actuel → **Jouer** → vie locale à parcourir horizontalement → installer l’app pour revenir. Le contenu reste honnête : états Live, événements publiés, cercle et progression viennent des données réelles; les états invité, vide et annulé ne sont pas fabriqués.

## 2 — UI design

Le verbe primaire reste **Jouer**. Le HUD existant est hors du flux et n’a pas été refondu. Le hero est plein cadre; à 390 px il mesure 364 px, puis la rail commence immédiatement. Les cartes font 255 × 335 px avec 9 px de gouttière mobile. À 1440 px, les trois tuiles mesurent 443.5 / 385.9 / 505.4 px, avec 12 px d’écart. Cibles interactives ≥ 44 px, focus, reduced motion et forced colors sont couverts.

## 3 — Art direction

Salt Lake City Temple remplace Jérusalem pour le monde Coronas : granit clair, six flèches et statue de Moroni sont lisibles dans une nuit bleu profond. La composition landscape réserve le tiers gauche au titre et garde le temple comme point focal; la version portrait conserve le jeune héros du langage mobile du mockup avec le temple derrière lui. Les quatre illustrations de cartes partagent la même lumière ambre/bleu nuit et n’embarquent aucun texte rasterisé.

## Theme engine

Une seule Home et un seul markup. Le manifeste choisit Celestial Light/Dark depuis l’œuvre active, sans toggle. Le hero utilise une art direction 9:16 sous 768 px et 16:9 au-dessus; le même pipeline fournit AVIF, WebP et JPEG. La tuile PWA reste ivoire en Light et nocturne en Dark.

## Four seats

N/A — street loop.

| Seat | Verb tonight |
|---|---|
| Who | Reprendre son monde et sa progression |
| Where | Reconnaître sa rama et son contexte local |
| What now | Jouer, ouvrir un événement ou lire dans le cercle |
| Around me | Voir la prochaine Noche Live et la vie de la rama |

## Tension

Le hero donne l’anticipation, le bouton déclenche l’action, les cartes rendent visible la soirée à venir, et l’installation prépare le retour. L’écran n’est plus une grille de raccourcis silencieuse.

## Finale

N/A — Home street. La progression de saison reste visible sur desktop sans inventer une cérémonie.

## Languages

N/A — aucune nouvelle chaîne. Toute la surface continue d’utiliser les clés existantes.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 10 |
| Feedback | 8 |
| Progression | 9 |
| Social | 9 |
| Immersion | 10 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le hero Salt Lake est spectaculaire et immédiatement Noche Live sans gêner le HUD.
- La rail produit exactement le peek horizontal du mockup sur mobile et la composition éditoriale en trois panneaux sur desktop.
- L’installation est placée juste après le carrousel, mais ne s’affiche que lorsque l’offre PWA est honnêtement disponible.
- Les titres réels, y compris les plus longs, restent contenus dans les cartes.

## What feels weak

- Une rama sans événement ni cercle ne peut honnêtement montrer qu’une seule carte; le composant garde le comportement horizontal sans inventer du contenu.

## Required before approval

- None.

## Evidence

- Generated masters: `media/masters/media/hub/noche-hub-salt-lake-temple-{portrait,landscape}-v1.png`.
- Generated cards: `noche-hub-live-king-v1.png`, `noche-hub-service-bread-v1.png`, `noche-hub-circle-study-v1.png`, `noche-hub-rama-vigil-v1.png`.
- Prompt set: cinematic AAA mobile-game illustration, deep celestial navy, warm gold practical light, restrained sacred atmosphere, no typography/UI/watermark; Salt Lake architecture anchored on pale granite, six spires and Moroni.
- Responsive output: 54 checked variants for the five new asset keys, with no missing public file.
- Visual contract: 2 runs / 822 assertions; controller: 22 / 301; guest: 1 / 277; PWA: 3 / 87; screen/campus: 16 / 167; LCP/media: 8 / 25 339.

## Night director

Oui. La Home donne maintenant envie de toucher **Jouer**, puis de rester pour voir ce qui se passe dans sa rama; le décor n’est plus un fond, c’est une invitation.

# M117 — Guide d’installation iOS céleste

Reviewed: 2026-08-28
Slice: ouverture du guide iOS depuis la tuile d’installation du hub
Tests: hub + i18n — 38 runs, 777 assertions; visuel Light/Dark — 1 run, 38 assertions; 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: clés `pwa.*` existantes, inchangées dans es, pt-BR, en et fr

## Feeling

Appartenance et sérénité : l’app quitte le navigateur pour devenir une porte familière vers Noche Live.

## 1 — Game experience

Désir de garder l’aventure → ouverture cérémonielle du guide → quatre gestes concrets → ajout à l’écran d’accueil → retour à la tuile. Le parcours tient dans un seul écran mobile : pas de tutoriel à faire défiler, pas de perte du premier geste, pas de cul-de-sac de focus.

## 2 — UI design

Le premier frame montre immédiatement l’emblème, le bénéfice et le verbe. Les quatre étapes sont des cartes numérotées compactes, illustrées et lisibles en moins de deux secondes chacune. L’action « Compris » reste visible et stable. L’ouverture remet systématiquement le scroll à zéro, place le focus sur le cadre du guide sans déplacement visuel, puis le rend à la tuile à la fermeture.

## 3 — Art direction

Le guide est une feuille céleste arquée, signée par un apex doré. L’icône de Noche devient l’emblème; les illustrations iOS existantes restent les preuves pratiques. Un voile saturé, un glow très retenu et une montée courte donnent une ouverture de monde sans transformer l’aide en cérémonie disproportionnée.

## Theme engine

Un seul markup consomme les surfaces, encres, muteds, lignes et ombres sémantiques du monde courant. Celestial Light produit une feuille ivoire et Celestial Dark une carte nocturne; l’or reste la signature commune. Aucun toggle de thème n’est introduit.

## States

- Default: guide fermé, focus sur la tuile.
- Opening: voile + montée de la feuille + révélation cadencée des détails.
- Open: emblème, titre, quatre étapes et confirmation visibles sans scroll à 390 × 844.
- Compact: densité resserrée sous 700 px de hauteur.
- Reduced motion: toutes les animations du guide sont supprimées.
- Close/backdrop: fermeture sûre et retour du focus à la tuile déclencheuse.

## Languages

Les clés `pwa.kicker`, `pwa.ios_title`, `pwa.banner_hint`, `pwa.ios_share`, `pwa.ios_home`, `pwa.ios_web_app`, `pwa.ios_add` et `pwa.done` restent présentes en **es**, **pt-BR**, **fr** et **en**. Aucun texte n’est encodé dans une image.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS — 9/10 global.

## What works

- L’ouverture appartient désormais au monde Noche au lieu de ressembler à une page web blanche.
- La hiérarchie survit dans les familles Light et Dark avec le même DOM.
- Les quatre gestes et l’action finale tiennent ensemble dans le viewport mobile de référence.
- Le retour de focus et `prefers-reduced-motion` rendent la cérémonie robuste, pas seulement décorative.

## What feels weak

- Le dernier geste appartient toujours à l’interface iOS; Noche ne peut pas confirmer techniquement que l’icône a bien été ajoutée.

## Required before approval

- None.

# M144 — Changer de paroisse depuis la fiche

Reviewed: 2026-08-29
Slice: `/ficha` — accès à `/buscar?cambiar=1`
Tests: contrôleur + système ciblés — 9 runs, 122 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`

## Feeling

Contrôle et appartenance : le joueur sait quelle paroisse accompagne sa fiche et peut la corriger sans chercher dans le menu.

## 1 — Game experience

La chips de paroisse actuelle et la chips-action « Changer » sont voisines sous le titre. L’action mène directement au parcours de changement, sans étape administrative intermédiaire.

## 2 — UI design

« Enregistrer » reste l’unique action dorée et principale. « Changer » est une action secondaire à côté de la chips de paroisse, avec une cible d’au moins 44 × 44 px, un focus visible et un état pressé.

## 3 — Art direction

Les deux chips conservent le verre Celestial Light de la fiche. Leur espacement les distingue sans ajouter une nouvelle carte ni masquer l’artwork.

## Theme engine

N/A — la fiche actuelle est une surface Celestial Light déterminée par son artwork, sans toggle.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 8 |
| Feedback | 9 |
| Progression | 8 |
| Social | 9 |
| Immersion | 8 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## Editorial gate

L’action et sa destination ont été explicitement demandées. Elle réutilise les libellés déjà localisés `street.change_ward_short` et `street.change_ward`; aucun nouveau texte joueur n’est introduit.

## Evidence

- Contrôle d’intégration et clic réel vers `/buscar?cambiar=1`.
- Captures inspectées à 390 × 844, 768 × 1024 et 1440 × 900.
- Aucun débordement ; cible tactile ≥ 44 × 44 px ; console sans erreur sévère liée au changement.

## Remaining issues

- Aucun connu dans ce périmètre.

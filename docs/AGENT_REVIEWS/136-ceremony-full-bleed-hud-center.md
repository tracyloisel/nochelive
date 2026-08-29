# M136 — Cérémonie plein écran et HUD centré

Reviewed: 2026-08-29
Slice: payoff de fin de pack `/jugar`
Tests: pack Light — 1 run, 111 assertions, 0 failure; duel Dark — 1 run, 24 assertions, 0 failure; haptics — 3 tests, 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: N/A — aucun texte ni contenu éditorial modifié

## Feeling

Accomplissement, fierté et appartenance : la victoire doit occuper la scène entière, pas sembler enfermée dans une colonne web.

## 1 — Game experience

La boucle reste question → résultat → récompense → classement → prochaine envie. Le décor plein écran amplifie le payoff sans ajouter d’attente ni d’action administrative. Les récompenses, le coffre et les trois prochaines actions restent inchangés.

## 2 — UI design

Le décor est désormais full-bleed, tandis que le HUD et la pile de contenu restent dans la colonne de lecture. À partir de 720 px, le titre du pack occupe une colonne centrale symétrique ; identité à gauche et score, série et menu à droite ne peuvent plus déplacer son axe visuel. Le test mesure séparément le plein écran, le centre du HUD, le centre du titre et la largeur de la pile.

États concernés : completed et reward/content sequence. Idle, pressed, loading, failure, locked, unlocked, new et live ne changent pas.

## 3 — Art direction

Émotion : victoire partagée. Composition : illustration sociale Celestial Light en `cover` sur toute la fenêtre, rayon central derrière la récompense, chrome ivoire et or maintenu sur une colonne lisible. Le décor redevient le monde de la cérémonie plutôt qu'un fond de téléphone posé sur une page blanche.

## Theme engine

N/A — ce slice n'est pas le hub. Le mode Light/Dark continue de venir de `Quizzes::Chrome` et de l'artwork.

## Four seats

N/A — street solo. Verbe suivant : inviter avec ses couronnes, ouvrir le campus ou revenir à la carte.

## Tension

Fin de boucle street : le résultat et le coffre culminent avant que le classement et les prochaines actions reprennent la main. Aucun changement de score, de timing ou de mécanique.

## Finale

La fin du pack reste une cérémonie de couronnes ; ce correctif ne change pas les points ni la capacité à gagner.

## Languages

N/A — aucun texte ajouté ou déplacé.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9.4 |
| Impact visuel | 9.3 |
| Feedback | 9.0 |
| Progression | 9.0 |
| Social | 8.6 |
| Immersion | 9.5 |
| Accessibilité | 9.0 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.0 |

## Verdict

PASS

## What works

- Illustration sans gouttières blanches aux formats téléphone, tablette et desktop.
- HUD et titre du pack réellement centrés, indépendamment de l'asymétrie des contrôles.
- Colonne de lecture préservée pour les statistiques, le classement et les actions.

## What feels weak

- La source de cérémonie reste un master portrait ; le `cover` desktop privilégie donc le centre lumineux et rogne davantage le haut et le bas, sans couper le payoff ni les personnages.

## Required before approval

- None.

## Evidence

- Captures inspectées : 390 × 844, 768 × 1024, 1280 × 800, 1440 × 900, 1850 × 1900 et 1920 × 1080.
- Familles inspectées : Celestial Light (pack) et Celestial Dark (revanche), dont Dark à 390 × 844, 768 × 1024 et 1440 × 900.
- Géométrie automatisée : full-bleed, HUD centré, titre centré, pile centrée et largeur de colonne.
- Console navigateur sans entrée `SEVERE`. La vibration automatique sans activation a été supprimée ; le haptique reste disponible après interaction.

## Night director

Oui : la fin du pack ressemble maintenant à une arrivée dans un monde partagé. Le prochain désir reste visible immédiatement dans les trois actions de sortie.

# M137 — Défis Celestial Dark, Campus continu

Reviewed: 2026-08-29
Slice: la page `/desafios`, du prochain pack aux invitations envoyées
Tests: ciblés — 11 runs, 203 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md` — principes appliqués à une destination Street
Copy: N/A — aucune copie déplacée

## Feeling

Entrer de nuit dans un Campus vivant, sentir une course amicale déjà engagée, puis avoir envie d'ouvrir le prochain livre.

## 1 — Game experience

La boucle reste intacte : prochain pack → couronnes en jeu → duel → verdict → invitation suivante. Le décor continu relie les blocs en un seul lieu au lieu d'une suite de feuilles administratives. Le CTA de pack et l'urgence réelle restent les premières actions visibles.

## 2 — UI design

Le verbe à deux secondes est « jouer le prochain pack ». Le HUD, le dock, les compteurs, les panneaux, les résultats et les invitations consomment les tokens Celestial Dark. Les surfaces sont des verres navy lisibles, avec l'or réservé aux enjeux et actions. La grille des invitations reste 1 / 2 / 3 colonnes aux largeurs de référence.

## 3 — Art direction

Le Campus des Écritures a été rééclairé par ImageGen en nuit bleue accueillante : lune, feuillage profond et lanternes or retenues. La scène est une couche fixe plein écran ; les lecteurs restent bas dans le cadre avec de l'architecture au-dessus, loin du HUD. Les scrims sont locaux aux zones de texte, pas un voile gris global.

## Theme engine

Un seul markup. `body.is-celestial-dark` porte les tokens sémantiques et le HUD en déduit son thème. L'œuvre nocturne est déterministe pour cette destination, pas un toggle utilisateur et pas une branche parallèle.

## Four seats

Street — qui : Pili et ses rivaux nommés ; où : Campus des Écritures nocturne ; quoi maintenant : jouer le prochain pack ou répondre ; autour de moi : invitations, duels terminés et progression sociale.

## Tension

Elle monte par les couronnes, l'écart de score, la date limite et les scènes de victoire ou de défaite. Sans ces écarts et verdicts, la page retomberait dans une liste de quiz silencieuse.

## Finale

N/A — la page prépare et relance des duels Street ; la cérémonie de résultat reste portée par les cartes de derniers duels.

## Languages

N/A — aucune chaîne éditoriale modifiée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Le même Campus est perceptible en haut, entre les panneaux et jusqu'aux invitations envoyées.
- Le fond nocturne donne de la profondeur sans sacrifier les contrastes ni la lecture des scores.
- Le HUD ne touche aucun visage et le recadrage reste stable à 390, 768 et 1440 px.
- Les résultats conservent leurs scènes d'intensité à l'intérieur du monde Celestial Dark.

## What feels weak

- Sur téléphone, le décor devient volontairement abstrait derrière les grands panneaux ; il soutient l'atmosphère plus qu'il ne raconte toute la scène.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/temple-themed/duel-campus-390x844.png`
- `tmp/street-shots/temple-themed/duel-campus-outgoing-390x844.png`
- `tmp/street-shots/temple-themed/duel-campus-768x1024.png`
- `tmp/street-shots/temple-themed/duel-campus-results-1440x900.png`
- `tmp/street-shots/temple-themed/duel-campus-outgoing-1440x900.png`

## Night director

Oui. Le prochain duel ressemble maintenant à une rencontre qui m'attend quelque part dans le Campus, pas à une opération dans un tableau de bord.

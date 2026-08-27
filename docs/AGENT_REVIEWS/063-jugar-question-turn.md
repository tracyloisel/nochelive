# 063 — Street jugar: question-to-question turn

Reviewed: 2026-08-27
Slice: `/jugar` overlay Suivant → next ask. Métier inchangé.
Tests: `ui_chrome` (no duplicate `street-quiz` name, overlay VT pieces, `overlaySession`)
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A

## Feeling

Continuité. Le monde **tourne**, le HUD ne se casse pas. Envie de tapper la suivante tout de suite — pas un redémarrage de l’écran.

## 1 — Game experience

Boucle : résultat → Suivant → nouvelle peinture (fondu) + nouvelles pastilles, 🔥 et couronne **restent**. Plus de cut + re-entrée hub (still 0→1, HUD qui retombe, sheet qui remonte) à chaque question. Lock tap 220 ms sur le tour, 550 ms seulement à l’arrivée depuis le hub.

## 2 — UI design

View Transitions : still / sheet / dock / praise se fondent. HUD `animation: none`. Plus de `view-transition-name: street-quiz` en double (wrapper + `#street_quiz`) — ça abortait la transition.

États : `is-entering` (hub → jugar) · `is-turning` (question → question) · `is-settled` · `is-locked`.

## 3 — Art direction

Le tableau change, le chrome reste. Fondu d’opacité, **pas** de scale/translate sur le still (évite le zoom cheap).

## Theme engine

N/A.

## Four seats

Street — un siège. N/A live.

## Tension

Le Suivant est un battement, pas un chargement.

## Finale

N/A. Cérémonie pack inchangée.

## Languages

N/A.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.4 |
| Clarté | 8.6 |
| Impact visuel | 8.3 |
| Feedback | 8.5 |
| Progression | 8.5 |
| Social | 8.0 |
| Immersion | 8.6 |
| Accessibilité | 8.3 |
| Cohérence NocheLive | 8.6 |
| Envie de continuer | 8.6 |

## Verdict

**PASS** — le tour de question n’est plus un hard cut.

## What works

- Un nom VT, des pièces nommées, HUD stable.
- Entrée hub une fois ; ensuite `is-turning`.

## What feels weak

- Hauteur de sheet 3 vs 4 choix peut encore respirer un peu.
- `celestial_breath` stand-in (hors slice).

## Required before approval

- None.

## Night director

Je reste dans la scène. Je retape.

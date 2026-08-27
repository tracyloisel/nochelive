# 068 — Street jugar: no chase chip on the ask

Reviewed: 2026-08-27
Slice: `/jugar` overlay ask — drop the Carmen chase chip. Timer owns the band under the HUD. Hub rival card unchanged.
Tests: `street_plays_controller_test`, `ui_chrome_test`, `street_quiz_visual_test` — no `.street-shot-rival` on jugar
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: `.cursor/skills/noche-i18n/SKILL.md` — removed `street.shot_rival` / `shot_rival_gap` / `shot_rival_more` (es, pt-BR, en, fr). Hub `card_rival_gap` stays.

## Feeling

Tension du chrono. Curiosité vers la question. Pas « décoder une pastille ». La chasse reste au hub (appartenance), pas sur le combat.

Si on gardait la chip « pour le social » pendant l’ask → VETO : on ne comprenait pas, et elle volait le 11.

## 1 — Game experience

Boucle ask : still → penser → taper avant la fin. Le timer est l’objet de tension. Carmen / +42 pts / +1 autre n’avait pas de job humain (le verbe « à rattraper » n’était que dans l’aria). `Quizzes::Rival` continue d’alimenter le hub.

## 2 — UI design

2 secondes : HUD + chrono centré + feuille QCM. Light/Dark inchangés. Plus de verre encre 14,5 rem sous le HUD. MOCKUPS : timer seul sur le still.

## 3 — Art direction

Le tableau n’est plus recouvert d’une pastille TikTok sombre. Or = chrono, pas un deuxième système.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

Le compte à rebours se lit. Plus de collision avec le 11.

## Finale

N/A.

## Languages

Keys of the chip removed in four locales. Hub copy untouched.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.4 |
| Clarté | 8.8 |
| Impact visuel | 8.5 |
| Feedback | 8.2 |
| Progression | 8.0 |
| Social | 8.0 |
| Immersion | 8.5 |
| Accessibilité | 8.6 |
| Cohérence NocheLive | 8.6 |
| Envie de continuer | 8.3 |

## Verdict

**PASS** — l’ask est un combat ; la ligue reste au hub.

## What works

- Timer seul sous le HUD.
- Partial `street_shot_rival` et pipeline jugar `Quizzes::Rival` retirés.
- Hub `_rival_card` / `_friend_rail` inchangés.

## What feels weak

- L’écart Carmen n’est plus visible *pendant* le pack (volontaire). La cérémonie et le hub portent le social.

## Required before approval

- None.

## Evidence

UI: `/jugar` ask Light (Rois) — chrono lisible, pas de chip.

## Night director

Je joue encore une question : je vois le temps, pas un badge.

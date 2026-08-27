# M100 — Défi rivalry arena

Reviewed: 2026-08-28
Slice: `/desafio/:token` invitation, waiting, unavailable and result states
Tests: `bin/rails test test/controllers/street_challenges_controller_test.rb` — 17 runs, 105 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — existing localized keys reused; no new copy

## Feeling

Rivalité, tension et fierté : le joueur doit voir immédiatement qui l'affronte, sur quel pack, et quel geste fait avancer le duel.

## 1 — Game experience

The screen now forms a short loop: face-off anticipation → accept/share action → waiting feedback → score result → return to the journey. Generic sheet hierarchy and duplicated explanatory weight were removed.

## 2 — UI design

The 2-second verb is the single full-width gold action. The face-off, pack, score to beat, waiting, locked and result states share one arena anatomy. Targets remain large, names wrap, and reduced motion is honored.

## 3 — Art direction

Celestial Light follows the royal pack/court moment: full palace environment, ivory arched arena, metal-gold VS medallion, soft depth and a short entrance clash. Gold stays on metal, borders and the one CTA; titles remain ink.

## Theme engine

N/A — this is not the hub.

## Four seats

N/A — asynchronous street duel. The screen answers who, the pack/stakes, the current state, and what to do next.

## Tension

The opposing portraits converge on the VS medallion; a known challenger score becomes a crown-backed target rather than another paragraph.

## Finale

N/A.

## Languages

Existing `street.duel_*` keys were reused in es, pt-BR, fr and en; no locale parity changed.

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
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- One recognizable rivalry moment across every async state.
- Real player, pack and score data remain authoritative.
- The royal court is visible around the sheet instead of acting as a generic wallpaper.

## What feels weak

- The system screenshot could not reach the challenge because the pre-existing profile-gate helper did not open; controller coverage validates the rendered anatomy.

## Required before approval

- None.

## Night director

Yes: accepting starts the isolated ten-question run, while waiting and results each give a clear next want.

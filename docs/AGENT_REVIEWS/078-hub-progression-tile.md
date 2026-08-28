# 078 — Hub progression journey

Reviewed: 2026-08-27
Slice: truthful four-medallion journey in Celestial Light and Dark
Tests: focused `bin/rails test` — 66 runs, 2,128 assertions, 0 failures; full suite — 779 runs, 9,622 assertions, 94.86% coverage, with unrelated concurrent presenter deadlocks and platform-stat fixture-count failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — existing native `hub.progress` and pluralized `hub.packs_unlocked` retained in es, pt-BR, en, fr

## Feeling

Pride in the road already travelled, clarity about the current chapter, and curiosity about the gold-lit chapter ahead.

## 1 — Game experience

The tile now reads left to right as completed → current → locked future. The honest unlocked count supplies the result/reward, the focused halo supplies the next want, and the four-node catalog window keeps the journey moving without inventing chapter names.

## 2 — UI design

One four-column timeline fits at 390 × 844 with 14px labels, no overlap, attached state badges, a connector behind the medallions, and `aria-current="step"`. Finished, current/open, and locked states remain visibly distinct.

## 3 — Art direction

Light uses ivory paper, a fine warm border/shadow, muted landmark gold, green completion checks, and a radiant current medallion. Dark keeps identical geometry on deep translucent navy with cream labels, gold metal, and volumetric glow.

## Theme engine

PASS. One markup tree consumes `#street_world[data-hub-theme]` semantic tokens; no theme toggle or duplicated Home.

## Four seats

N/A — street hub. The tile strengthens “where am I?” and “what comes next?” while preserving the adventure hero as the primary verb.

## Tension

The connector makes prior success visible while the larger radiant focus and locked future create forward pull. No fake pack, score, or completion state is used.

## Finale

N/A — no live-night round or finale changed.

## Languages

PASS. Existing keys are native and pluralized: `Tu progreso`, `Seu caminho`, `Your path`, `Ta progression`; unlocked counts remain truthful in all four locales. Locale parity test passes.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 10 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Real QuizDefinition order and World states drive every medallion.
- Light and Dark screenshots preserve one layout while changing atmosphere.
- The focused chapter has a readable gold halo without obscuring labels.

## What feels weak

- Landmark symbols are intentionally generic architecture rather than bespoke art per pack.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/temple-themed/hub-progress-light-390x844.png`
- `tmp/street-shots/temple-themed/hub-progress-dark-390x844.png`

## Night director

Yes: the journey exposes visible achievement and a concrete next chapter instead of presenting a dashboard count.

## Follow-up — direct map door (2026-08-28)

The tile header now exposes one explicit, 44px-high `Ouvrir la carte` action with a compass. It routes to `/mapa` while leaving the horizontal chapter rail scrollable and the Parole journey independently interactive. The same semantic tokens carry the affordance in Celestial Light and Dark; keyboard focus, press feedback, and reduced motion are covered. Conseil scores remain at least 8/10: this closes the only clarity gap between seeing progress and entering the adventure map. Focused evidence: 390 × 844 browser check, no horizontal overflow, successful click to `/mapa`, no console warnings or errors; controller test: 1 run, 43 assertions, 0 failures.

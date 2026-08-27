# 067 — Street ceremony time is think time

Reviewed: 2026-08-27
Slice: pack-complete **Temps total** is the sum of time spent answering each question, not wall clock from pack open (scripture / résultat / Suivant excluded).
Tests: `bin/rails test` — 757 runs, 9470 assertions, 0 failures; line coverage 95.22% of `app/`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A (`/jugar` ceremony metric, not `/`)
Copy: N/A — existing `street.ceremony_stat_time` labels

## Feeling

Pride that the clock is **theirs** — how fast they thought, not how long they lingered on the verse.

## 1 — Game experience

The score hall already shows time as a trophy stat. Wall clock punished reading scripture and sitting on the result. Think-time (ask → tap / expire) is the loop the player can own. Pause between questions is not a penalty.

## 2 — UI design

Same overlay, same `mm:ss`. The number got honest. No new chrome.

## 3 — Art direction

N/A — no still or token change.

## Theme engine

N/A.

## Four seats

Street — un siège (tú). N/A live.

## Tension

A fast pack still looks fast on the board.

## Finale

N/A night. Street pack-complete clock.

## Languages

N/A.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.2 |
| Clarté | 8.6 |
| Impact visuel | 8.0 |
| Feedback | 8.5 |
| Progression | 8.3 |
| Social | 8.0 |
| Immersion | 8.2 |
| Accessibilité | 8.1 |
| Cohérence NocheLive | 8.5 |
| Envie de continuer | 8.3 |

## Verdict

**PASS** — ceremony time matches how the player played the questions.

## What works

- `asked_at` on the current ask; `duration_ms` on each answer
- Sum on `Complete.summary`; cap at the question clock when timed
- Legacy rows without `duration_ms` still use wall clock

## What feels weak

- The HUD countdown is still a deadline, not a stopwatch — by design
- Mid-pack runs opened before this migrate fall back to `opened_at` for the current ask only

## Required before approval

- None.

## Evidence

Service tests: submit / expire / complete think-time vs wall clock.

## Night director

Would I play another pack? Yes — reading the verse no longer inflates the trophy time.

# 046 — Hub feed scrolls; header and Continuer stay

Reviewed: 2026-08-26
Slice: street hub — tiles in an inner scroll; lockup + Continuer stay on screen; card top gloss follows the rounded corners
Tests: `bin/rails test` (see session)
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: N/A
UI: `.cursor/skills/noche-ui/SKILL.md` — no 5-tab dock; gold stays Jugar

## Four seats

N/A (street). Hub job: read tiles, play. Header and Continuer never leave.

## Tension

N/A.

## Finale

N/A.

## Languages

N/A.

## Verdict

PASS WITH NOTES

## What works

- `.street-hub-feed` scrolls between the ink lockup and the gold Continuer.
- Card `::before` wash uses the card’s top radius, so the gold border no longer nicks at the corners.

## What feels weak

- Short hub still shows marble under the last tile. That is the hall, not a missing tile.

## Required before approval

- None.

## Evidence

UI: pinned chrome + inner feed. Copy unchanged.

## Night director

Would I still see Continuer after a long défi? Yes. Friday four-seat? No — street.

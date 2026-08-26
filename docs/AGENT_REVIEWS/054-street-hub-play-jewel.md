# 054 — Hub pack tile: gold Jouer jewel

Reviewed: 2026-08-26
Slice: Quizz royal briefing replaces the ink Continuer text with a compact gold-leaf **Jouer** hex (stars, ink type on metal). Dock gold Continuer / Jugar stays. No sofa `.btn`.
Tests: `bin/rails test` (see session)
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — existing `street.world_play` (Jugar / Jogar / Jouer / Play). No new keys.
UI: `.cursor/skills/noche-ui/SKILL.md` — gold metal CTA on the tile; ink for pack words; not `.btn`

## Four seats

N/A (street). Hub job: read the pack, tap Jouer on the tile or Jugar on the dock.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS** — reused `street.world_play` in all four locales. Tile always says Play, even with an open run (dock still Continuer).

## Verdict

PASS WITH NOTES

## What works

- Compact hex (~2.15rem), gold leaf, flanking stars, Fraunces ink — same family as the dock jewel, not a sofa pill.
- Open run: tile link → `/jugar`. First visit: `button_to` pack start. Map stays in Más.

## What feels weak

- Two gold CTAs (tile + dock). The tile is the pack hit; the dock is the thumb hit. Same verb on first visit.

## Required before approval

- None.

## Evidence

UI: gold metal, not gold type on cream. Copy: tú / você / tu / you.

## Night director

Would I tap Jouer on the kings card? Yes. Friday four-seat? No — street.

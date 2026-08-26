# 032 — Abuelos type floor + iPad / desktop / XL columns

Reviewed: 2026-08-26
Slice: readable type never below 14px; hub / paper / jugar / live seats scale as a phone composition on the marble hall (not a dashboard).
Tests: `bin/rails test test/integration/ui_chrome_test.rb test/system/street_quiz_visual_test.rb test/system/night_temple_visual_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no strings moved)

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged one gold next. Stage is a scaled phone arch on the hall from 720. |
| Equipo en sala | Unchanged Buzz. Same arch column — QCM/Buzz no longer stretch to 1920. |
| Jugador en casa | Unchanged remote pick. Type `--type-ask` / `--type-choice` grow at iPad / desktop / XL. |
| Espectador | Unchanged *Solo ver*. Watch stays 16:9 cinema; caption and scores use the type tokens. |

## Tension

N/A (chrome / type, not a round).

## Finale

Unchanged. Pack ceremony monument uses `--street-ceremony-col` (22.75 → 28 → 32 → 36). Night immersive ceremony stays full-bleed hall.

## Languages

N/A.

## Verdict

PASS WITH NOTES

## What works

- `--type-min` (14px) on every readable micro-label (dock, COURONNES, REJOUER, LEYENDA, pack titles). Tokens bump at 720 / 1024 / 1440.
- Hub / paper-hall column: 24.375 → 32.5 → 36 → 40. Liga keeps 32.5 → 38 → 48.
- Jugar / casa / sala / presenter: `--street-play-col` 28 / 32 / 36 from 720, chrome pinned to the arch. Watch stays cinema.
- iPad landscape (`max-height: 860px`) compacts the hub so the current node stays above CONTINUER.

## What feels weak

- Five dock labels at 14px wrap (CLASSEMENT). Honest wrap beats 10px type.
- Level-star numeral shares `--type-min`; the star grew to 1.85rem so it still fits.

## Required before approval

- Recapture hub / jugar / ceremony / night seats at iPad + desktop + XL and compare to the mockup composition (not pixel size).

## Night director

Would I play another round on the family iPad? Yes — the hall still frames a phone, and an abuelo can read HUB, Pack 6, and the QCM without leaning in.

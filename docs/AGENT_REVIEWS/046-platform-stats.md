# 046 — Platform stats carta

Reviewed: 2026-08-26
Slice: Public `/cifras` on the carta sheet. Four marble chapters (house, path, gatherings, world league). Not a live night.
Tests: `bin/rails test` slice — 31 runs, 372 assertions, 0 failures (`platform/stats`, `quizzes/leaderboard`, `pages`, `ward_adds`, `locale_files`). Menu order + ui chrome assertions green.
Gate: `.cursor/skills/noche-ui/SKILL.md` — leftover family, not a quiz reel
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr

## Four seats

N/A. Paper hall reading, not a live night. Same seat as carta 036.

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage |
| Equipo en sala | Unchanged Buzz |
| Jugador en casa | Unchanged remote A/B |
| Espectador | Unchanged *Solo ver* |

## Tension

N/A.

## Finale

Unchanged.

## Languages

noche-i18n: **PASS**
- es: ficha / rama, Cifras, Encuentros; **Noche Live** untouched
- pt-BR: ficha / ala, você-adjacent *a gente*; no ramo / ficheiro
- fr: fiche / paroisse; thin space before `:`; **Noche Live** untouched
- en: play name / ward, honour — not *please select* or *claimed units* as CMS

## Verdict

PASS

## What works

- Ivory `.charter-sheet.is-stats` with four `stats-chapter` blocks and marble tiles, not a flat `dl`.
- Honest counters: fichas not night seats, claimed ramas not the empty directory, street `QuizAnswer` including guests, chapel teams not solo casa, world = sum of best packs via `Quizzes::Leaderboard.pack_best_totals`.
- Paper podium for top 3 (gold badge as metal, ink names). Empty world if nobody finished a pack.
- Menu + `/nosotros` + `/legal` all open `/cifras`.

## What feels weak

- No mockup PNG for Cifras — invented in the leftover-hall / carta family.
- Country falls back to ISO-2 when the rama has no `country_name`.

## Required before approval

- None.

## Night director

Would I play another round? Yes — the house can now point at its own numbers without a dashboard.

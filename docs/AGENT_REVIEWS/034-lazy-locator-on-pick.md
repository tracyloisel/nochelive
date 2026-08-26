# 034 — Lazy locator: create the rama on first enter

Reviewed: 2026-08-26
Slice: street search may show a congregación the Church Maps API returns even if we do not have a row yet; picking it upserts one listed rama. Night seats unchanged.
Tests: `bin/rails test`
Gate: `.cursor/skills/noche-night/SKILL.md` — street, not a Friday night
Copy: `.cursor/skills/noche-i18n/SKILL.md` — N/A (no new user-facing strings)

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage. |
| Equipo en sala | Unchanged Buzz. |
| Jugador en casa | Unchanged remote A/B. Street first visit: **tú** — find the rama (ours or the Church’s list), then play. |
| Espectador | Unchanged *Solo ver*. |

## Tension

N/A (street welcome). Search talks to the locator; persist waits for Enter.

## Finale

Unchanged.

## Languages

noche-i18n: **N/A** — picker copy from 031 unchanged.

## Verdict

PASS WITH NOTES — no world dump, no Church HTTP in CI, first joiner is just the first ficha, RAMA still merged.

## What works

- `Wards::QueryLocator` uses Church `locations/search` for the typed query and `locations/identify` for one nearby unit. Silent in test unless a fake transport is injected.
- Empty arrival is search + optional nearby card, not a dump of listed ramas, not a country browse.
- `Wards::Ensure` + `Wards::Enter(church_unit_id:)` create a listed row on pick. Empty league stays honest until a ficha exists.
- Search merges local ILIKE with locator hits; Benidorm chapel does not appear twice.

## What feels weak

- Identify needs the phone’s geolocation permission. If it is denied, the sheet is search-only until they type.

## Required before approval

- None. Do not run a 30k import for this slice.

## Night director

Would a family in a city we have never stored still find their rama if the Church Maps API knows it? Yes — type the city, enter, they are first. Do we download the world first? No.

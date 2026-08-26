# 039 — Hub column follows viewport media queries

Reviewed: 2026-08-26
Slice: first-visit `/` was pinned to the ceremony phone width, so a desktop window stayed mobile and resizing did nothing past 36rem.
Tests: `bin/rails test test/integration/ui_chrome_test.rb test/controllers/street_hub_controller_test.rb test/system/street_quiz_visual_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no strings moved)

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged one gold next. Stage still uses `--street-play-col` on the hall from 720. |
| Equipo en sala | Unchanged Buzz. Same play-col arch. |
| Jugador en casa | Unchanged remote pick. |
| Espectador | Unchanged *Solo ver*. Watch stays 16:9. |

## Tension

N/A (chrome / column, not a round).

## Finale

Unchanged. Pack ceremony still uses `--street-ceremony-col`. Arrival `/` no longer borrows that token for the hub column.

## Languages

N/A.

## Verdict

PASS WITH NOTES

## What works

- `--street-hub-col` / play / ceremony / type tokens are set on `:root, body` at 720 / 1024 / 1440, so they actually win over inherited defaults when the window is desktop-sized.
- First-visit profile gate uses the same hub column as the signed-in map (24.375 → 36 → 44 → 52), not the ceremony monument (22.75 → 36). Hall still shows at the sides; the ivory door does not become a 1920 directory.
- Liga and charter body overrides stay more specific, so those boards keep their own widths.

## What feels weak

- Growth is still stepped (three jumps), not fluid between breakpoints. Dragging a window that is already ≥1440 will not widen past 52rem — that cap is the mockup.

## Required before approval

- Recapture wizard + hub at iPad / desktop / XL after this lands.

## Night director

Would I play another round on the family iMac? Yes — opening `/` on a wide browser now shows the door on the hall column that belongs to that window, not a leftover phone strip.

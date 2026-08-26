# 037 — Rama nights as a hall feed

Reviewed: 2026-08-26
Slice: rama profile sits on the marble hall (no ivory sheet); one night poster per row with date and missionary names
Tests: `bin/rails test test/controllers/ward_profiles_controller_test.rb test/integration/ui_chrome_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md` — no rama mockup PNG; hall feed is the clearer layout for this leftover surface
Copy: `.cursor/skills/noche-i18n/SKILL.md` — existing `t()` keys only (`home.memories`, `home.enter_night`, `presenter.missionaries`)

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | Unchanged gold next on stage. Host still opens from one gold **Abrir la noche** when nothing is live. |
| Equipo en sala | Unchanged Buzz. |
| Jugador en casa | Unchanged remote A/B. Live rama **Entrar** still goes to the name screen. |
| Espectador | Unchanged *Solo ver* quiet on the live profile. |

## Tension

N/A (rama street, not a Friday night).

## Finale

Unchanged.

## Languages

noche-i18n: **PASS**
- es: *Misioneros* / *Noches de la rama* — chapel, not CMS.
- pt-BR: *Missionários* / *Noites da ala*.
- fr: *Missionnaires* / *Soirées de la paroisse* — vous on the paroisse door, names as stored.
- en: *Missionaries* / *Ward nights* — meetinghouse, never temple.

## Verdict

PASS WITH NOTES — ivory sheet is gone on this page only; join/gates/fichas keep `.hall-sheet`.

## What works

- Marble hall is the canvas. Ink title, pin, and gold Entrar sit on it.
- Each noche is a 16:10 poster, then date, then missionary names when the night has them.
- Finished nights still open the souvenir; live nights still open the door.

## What feels weak

- Nights without named missionaries only show the date. That is honest, not a filler.
- Theme title repeats when several nights share Reyes y Profetas.

## Required before approval

- None.

## Night director

Would I play another round? Yes — the rama is now a list of remembered nights, not an Instagram grid on a cream card.

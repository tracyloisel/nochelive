# 057 — Hub pulse instead of Continuer

Reviewed: 2026-08-26
Slice: Street hub dock drops gold Continuer / Jugar. Ink pulse: players this month, questions this month, people in the house now. `/pulso` turbo-frame reloads every 5s. Map page keeps the gold play jewel. Play on the hub is the pack tile.
Tests: `bin/rails test` slice — pulse / hub / locale 37 runs, 634 assertions, 0 failures. Hub visual flow (guest hub, map, Jouer jewel) green. A few jugar/wizard system tests flake in the full visual file and are unchanged by this dock.
Gate: leftover street hub, not a live night — `.cursor/skills/noche-ui/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr

## Four seats

N/A. Street hub footer. Live night seats unchanged.

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
- es: *jugadores este mes para … preguntas* / *en línea ahora* — tú street, no CMS *usuarios conectados*
- pt-BR: *neste mês* / *jogando agora* — ala not ramo
- fr: *ce mois-ci pour* / *en ligne en ce moment* — tu street
- en: *this month for* / *playing now* — not *contestants* or *online users*

## Verdict

PASS WITH NOTES

## What works

- One gold play hit on the hub: the pack tile jewel. Dock is house numbers, ink on marble, gold live-dot as metal.
- Honest month: street `QuizAnswer` this calendar month, fichas + guest devices. Online: `PersonDevice.live` ∪ night `Player.live`, no double-count of a ficha.
- Numbers move without a full page reload: `turbo-frame#street_pulse` + `street-pulse` Stimulus, 5s, `expires_now`, pause when the tab is hidden.
- `/mapa` still has Continuer / Jugar in the dock.

## What feels weak

- Spec mockup still draws a wide gold Jugar bar. Product already had two gold CTAs (tile + dock); this keeps the tile and spends the dock on the house.
- Guests without a ficha do not heartbeat, so they do not appear in *en línea*.
- First paint is the server count; the next tick is 5s later.

## Required before approval

- None.

## Evidence

UI: ink words, gold metal dot, no gold type on cream. Copy: street tú / você / tu / you.

## Night director

Would I tap Jouer on the kings card? Yes. Would I look down and feel the house breathing? Yes — Friday four-seat is unchanged.

# 022 — Street quiz gaming competition

Reviewed: 2026-08-25
Slice: street quiz solo progression, profile gate, rama leaderboard
Tests: `bin/rails test` — 451 runs, 5028 assertions, 0 failures (95.76% coverage)
Gate: `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | N/A (street quiz is home solo) |
| Equipo en sala | N/A |
| Jugador en casa | Pick ficha on device, climb pack map, see rama rank |
| Espectador | N/A |

## Tension

Street packs already curve points (5→25 slam). This slice adds visible rank pressure within the ward and a celebratory pack finish with leaderboards — personal rivalry without a live night.

## Finale

N/A for live finale. Pack 10 still slams; win screen shows pack + total rama boards so the last question feels like a level boss payout.

## Languages

New keys `street.gate_*`, `street.board_*`, `street.rank_in_ward`, `street.next_pack`, `street.points_gained` in es, en, fr, pt-BR. pt-BR uses *ala*; fr uses *paroisse*.

## Verdict

PASS WITH NOTES

## What works

- Profile gate on `/` before play: rama pick (Benidorm shortcut) then ficha pick/create — no detour through hogar search.
- Cut-the-Rope-style map replaces horizontal trail; pack candy + rope between stops.
- Chrome shows rama rank + title during play; `+N` points pop on correct answers.
- Pack complete screen: burst score, rank line, pack + total leaderboards, gold next-pack CTA.
- Services: `Quizzes::Leaderboard`, `Quizzes::Standings`; `Complete.summary` enriched.

## What feels weak

- Map is static CSS zigzag — no candy bounce animation yet.
- Guest mode has no rank/leaderboard (by design); copy could nudge toward creating a ficha.
- Leaderboard only counts finished runs; mid-pack rivals invisible until they finish.

## Required before approval

- None for this slice. Optional: animate map current step; mini-board peek on asking sheet.

## Evidence

UI soul: tighter sheet padding, gaming win/board CSS. i18n gate reviewed in four locales.

## Night director

Would I play another pack? Yes — rank on chrome and the win boards make the solo loop feel like a mobile game, not a form.

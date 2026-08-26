# 028 — Street jugar + hub mockup parity

Reviewed: 2026-08-25
Slice: remaining gaps vs `mockup-street-jugar-temple-adventure.png` and `mockup-street-hub-temple-ui.png`
Tests: `test/services/quizzes/rival_test.rb`, `test/controllers/street_plays_controller_test.rb`, `test/controllers/street_hub_controller_test.rb`, `test/integration/ui_chrome_test.rb`, `test/system/street_quiz_visual_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md` (street, not night seats)
Copy: N/A — `shot_rival_gap` already in es / pt-BR / en / fr

## Four seats

N/A (street pack, not live night).

## Tension

N/A.

## Finale

N/A.

## Languages

No new copy. Brand unchanged. XP / league figures use `number_with_delimiter` (locale grouping only).

## Verdict

PASS WITH NOTES

## What works

- Score pill is a large cream serif chip (honest run score, not a fake 24).
- Rival chip stacks cream name over gold `+N pts`; guests still see the ward leader.
- Question sheet uses a small upward bump + 4-point star, not a deep inverted notch.
- Next/prev: swipe or tap the painting; right-swipe / tap-right clicks **Suivant** once the answer is in; left rewinds. The sheet itself does not skip.
- Hub lockup star sits above the ink wordmark; concentric gold oculus arcs sit behind the title. Ink lockup is **Noche Live** only (no WORLD HUB pill).
- Hub recapture 2026-08-26 ~16:56: MAPA is a door card on `/` (rope lives on `/mapa`); league pins just above gold Jugar. Avatar left, hamburger right. No five-tab bar. Ranking stays in the drawer.

## What feels weak

- Mockup right icon is people; mute + language live in the ivory drawer on hub and jugar.
- Mockup gold “NOCHE LIVE” is not shipped (ui-soul veto). Ink lockup with LIVE hairlines instead.
- Hub chrome is avatar + hamburger + drawer mute (product KEEP), not the mockup’s gear/trophy-only chrome.
- Mockup 5-tab dock is not shipped; tests require no `.street-hub-nav` on hub or `/liga`.
- Mockup 3-node rope on hub first-fold is not shipped; tests require `.street-map-path` count 0 on `/` and a MAPA door to `/mapa`.

## Required before approval

- Done: hub recaptured 2026-08-26 ~16:56 after MAPA moved to a door + `/mapa`. Jugar ask still 16:20 (ivory apex bump + gold-leaf star). KEEP leftovers: honest scores, 3 choices, drawer chrome, growing column, no 5-tab bar, rope on `/mapa`.

## Night director

Would I play another round? Yes — the ask screen now has a face to chase and a painting you can actually swipe.

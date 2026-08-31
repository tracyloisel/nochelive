# M164 — Hub Hero collision-safe copy

Reviewed: 2026-08-31
Slice: responsive Hero copy and competitive cockpit spacing
Tests: `bundle exec rails test test/system/hub_streaming_rails_visual_test.rb` — 2 runs, 1174 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — no scoring or live-night loop changed
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — the exact long title and lede are visual regression fixtures, not shipped copy changes

## Feeling

The story title should feel monumental and calm. It must finish speaking before progress and Play begin, even when the real editorial title occupies two lines.

## 1 — Game experience

The opening beat now reads in a stable sequence: story, context, progress, Play, then league pulse. The primary action no longer appears to cut through the chapter introduction.

## 2 — UI design

Tablet composition uses normal flow with an incompressible 16 px minimum gap and a bottom-anchored cockpit. Desktop keeps the cinematic absolute composition but gives the two-line title a wider measure and a higher safe position. Progress and Play keep equal height and alignment.

## 3 — Art direction

The local Light glass remains compact and the Dark title remains directly on the scene. No global veil was added. The Salt Lake Temple crop and the unchanged HUD retain their previously approved safe area.

## Theme engine

The same markup and responsive geometry serve Celestial Light and Dark. Only the artwork-authored materials change; the collision rule is shared.

## Four seats

| Seat | Result |
|---|---|
| Street player | Reads the full title before seeing the next action |
| Ward member | Keeps progress, rank and recent gain in one aligned cockpit |
| Guest | Unchanged |
| Ward-only visitor | Unchanged |

## Tension

The visual pause between narrative and cockpit makes Play feel like the response to the chapter rather than a control pasted across it.

## Finale

N/A — this is the Hub entry tableau.

## Languages

No locale file changed. The regression check deliberately uses a long French title to protect translations with comparable expansion.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.8 |
| Clarté | 9.7 |
| Impact visuel | 9.5 |
| Feedback | 9.2 |
| Progression | 9.4 |
| Social | 9.1 |
| Immersion | 9.6 |
| Accessibilité | 9.6 |
| Cohérence NocheLive | 9.6 |
| Envie de continuer | 9.4 |

## Verdict

PASS

## What works

- “LA VIE DU SAUVEUR” stays on two lines at tablet and desktop sizes.
- Story and cockpit retain at least 16 px of visible air in Light and Dark.
- The cockpit remains inside the Hero and progress stays aligned with Play.
- The HUD and Salt Lake artwork safe crop are untouched.

## What feels weak

- Very long unbroken words still depend on the browser's normal overflow behavior; current localized chapter titles contain natural break points.

## Required before approval

- None.

## Evidence

- Long-copy geometry exercised at 768×1024, 1024×768 and 1440×900 in both Celestial families.
- Visual screenshots inspected in all four combinations.
- The normal viewport matrix still passes from 320×568 through 1920×1080.
- Console remains clean; all visible controls retain the existing 44 px minimum target contract.

## Night director

Yes. The Hero now breathes like a title card, then hands control to the player with an unambiguous Play beat.

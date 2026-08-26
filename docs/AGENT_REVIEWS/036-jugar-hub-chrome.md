# 036 — Jugar keeps hub chrome

Reviewed: 2026-08-26
Slice: `/jugar` cream head no longer grows its own mute disc and language flag. Same chrome as the hub: avatar left, hamburger right, sound + language in the ivory drawer.
Tests: `test/helpers/application_helper_test.rb`, `test/controllers/street_plays_controller_test.rb`, `test/integration/ui_chrome_test.rb`, `test/system/street_quiz_visual_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md` (street chrome, not a night seat)
Copy: N/A

## Four seats

N/A (street pack). Live-night mute + flag on `#night_play` / presenter stay as chrome-tools.

## Tension

N/A.

## Finale

Unchanged.

## Languages

No new copy. Language switch stays reachable mid-pack, inside the hamburger (`lang-switch.is-drawer`).

## Verdict

PASS

## What works

- Hub and jugar share `chrome_tools_in_drawer?` (`is-street-play`). No floating `.chrome-tools` on the cream head.
- `is-split` keeps the face on the left and the hamburger on the right of the phone arch.
- Mockup people-icon KEEP is retired; product chrome is the hub drawer.

## What feels weak

- Temple mockup still paints hamburger left + people right. Product does not copy that.

## Required before approval

- None.

## Night director

Would I play another round? Yes — the cream head is the quiz, not a second control strip.

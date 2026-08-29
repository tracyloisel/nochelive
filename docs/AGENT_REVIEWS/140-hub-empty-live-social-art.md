# M140 — Empty Live and social art restored

Reviewed: 2026-08-29
Slice: Hub `/`, no-ward Live and online-friends states
Tests: 56 runs, 928 assertions, 0 failures, 0 errors
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — no game loop changed
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no player-visible copy changed

## Feeling

Anticipation and belonging. Even before choosing a parish, the player should see a live show worth joining and real people worth meeting, not two administrative white boxes.

## 1 — Game experience

The street loop stays honest: choose a parish to unlock the nearby Live and online-friends context. The empty states now preview the social promise without inventing a date, friend, score or presence.

## 2 — UI design

The two-second verbs remain **Trouver ma paroisse** and **Choisir ma paroisse**. Both actions remain visible and enabled. Copy sits on compact local glass while artwork owns the card. The same markup serves Light and Dark, responsive AVIF/WebP variants load at each viewport, and no horizontal overflow appears.

## 3 — Art direction

The no-ward Live card restores the dedicated Noche game-show stage over the whole ticket. The online empty state restores a friends-at-the-Campus illustration with a top/bottom local scrim. Celestial Light keeps the gold daylight and faces vivid; Celestial Dark deepens the same scene with navy contrast instead of replacing it with a blank panel.

## Theme engine

PASS. Artwork selection remains driven by the existing Hub result and media manifest. Light/Dark share one ERB tree; only semantic theme tokens, scrims and filters differ. No theme toggle or parallel component was introduced.

## Four seats

N/A — street Hub. The cards clarify what is around the player and which single action unlocks it.

## Tension

Street loop only. The stage and gathering create anticipation before parish selection; the CTA resolves that anticipation directly.

## Finale

N/A — no round, scoring or ceremony logic changed.

## Languages

N/A — localized strings were not changed.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- The Live illustration remains present even in `ward_missing` and `none` states.
- The online empty state is now a social scene, with a small readable copy cartouche instead of a full white veil.
- Both images use existing responsive manifest variants and remain legible in Celestial Light and Dark.
- Real online rows still prioritize avatars and do not add the empty-state illustration.

## What feels weak

- At 768 px the right rail is intentionally narrow, so headings and promises wrap more than on desktop; all content remains visible and unclipped.

## Required before approval

- None.

## Evidence

- Personally inspected Celestial Light and Dark at 390 × 844, 768 × 1024 and 1440 × 900.
- No horizontal overflow at any required viewport.
- Stage and friends illustrations loaded from responsive generated AVIF/WebP assets.
- `Trouver ma paroisse` and `Choisir ma paroisse` remained visible, enabled and linked to their existing destinations.
- Browser console: 0 warnings and 0 errors.
- `bundle exec rails test test/services/hubs/screen_test.rb test/controllers/street_hub_controller_test.rb test/integration/progressive_street_identity_test.rb`: 55 runs, 800 assertions, green.
- `bundle exec rails test test/system/hub_campus_visual_test.rb`: 1 run, 128 assertions, green across the full Light/Dark viewport matrix.
- Editorial approval: N/A; no copy, destination, notification or content rule changed.

## Night director

Yes. The empty state now sells the night and the people before asking for parish setup, so the next tap feels like entering the world rather than completing a form.

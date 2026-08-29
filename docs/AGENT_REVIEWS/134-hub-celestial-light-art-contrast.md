# M134 — Celestial Light tile artwork contrast

Reviewed: 2026-08-29
Slice: Hub `/`, visual hierarchy of one continuous street memory
Tests: `bundle exec rails test test/controllers/street_hub_controller_test.rb` — 30 runs, 665 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no copy moved

## Feeling

Wonder and invitation: Celestial Light should feel radiant, not bleached. The player reads the next verb immediately while still seeing the world, faces, and journey behind it.

## 1 — Game experience

The existing street loop is unchanged. Clearer art and progression thumbnails make the next adventure, Campus, map, and media routes easier to recognize without adding a new decision or interruption.

## 2 — UI design

The same markup serves Light and Dark. Light uses local ivory scrims behind copy, stronger image contrast, and intentional locked-state desaturation. Key controls and links remain at least 44 px at 390×844, 768×1024, and 1440×900.

## 3 — Art direction

Existing illustrations already have the required range and composition, so regeneration was unnecessary. The pass removes the accidental milky layer from the hero, study, live, Campus, progress, video, and community tiles while retaining gold edges and readable ink.

## Theme engine

PASS. Celestial Light overrides are scoped to `[data-hub-theme="light"]`; Celestial Dark remains driven by its artwork manifest and keeps its original contrast. No user toggle and no forked layout were introduced.

## Four seats

N/A — street hub. The player can identify who they are, the current world, the next action, and nearby social activity.

## Tension

Street loop: the stronger current/focus thumbnail and protected locked state clarify what is open now and what remains ahead.

## Finale

N/A — this slice does not change a game finale.

## Languages

N/A — no localized copy changed.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Artwork remains legible and saturated where it carries the emotion.
- Ivory stays local to copy and statistics instead of washing the whole card.
- Locked progression remains visibly locked without muting completed and current packs.
- Light and Dark retain distinct atmospheres with one shared Hub.

## What feels weak

- The intentionally soft editorial painting in the adventure hero is still lower-contrast than the photographic tiles, but faces and scenery now remain visible.

## Required before approval

- None.

## Evidence

- Visual QA: 390×844, 768×1024, and 1440×900 in Celestial Light and Celestial Dark.
- Browser console: 0 warnings and 0 errors.
- Controller suite: 30 runs, 665 assertions, 0 failures.

## Night director

Yes. The hub now shows a place worth entering before it asks for the next tap, and the progression rail makes the next unlock feel tangible.

# M163 — Hub voyage, complete rail and aftercare

Reviewed: 2026-08-31
Slice: the Hub from its first voyage control through the post-carousel priorities
Tests: `bundle exec rails test test/system/hub_streaming_rails_visual_test.rb` — 2 runs, 1126 assertions, 0 failures; guest and install visual suites — 5 runs, 555 assertions, 0 failures; targeted controller contract — 1 run, 13 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — street Hub loop, no live-night mechanics moved
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — existing localized labels were reused; no player-facing wording or delivery policy changed

## Feeling

The player should feel that Home is a living journey, not a long page: the opening artwork can be explored, the Rama rail lands as a complete deck, and the next personal action continues in the same world instead of falling into an unfinished utility area.

## 1 — Game experience

The opening anticipation now has an explicit previous → current position → next loop. The rail resolves cleanly before the install offer and the personal priority, so each section gives one next desire rather than disappearing into a clipped edge. Anonymous and ward-only sessions keep honest public routes and dedicated identity states.

## 2 — UI design

The voyage has 44 px previous/next controls, tactile dots, a live `current / total` counter, edge-disabled states, keyboard focus and reduced-motion behavior. The carousel scrollport owns the full card height plus 12 px of breathing room, so every lower border and focus/hover edge is visible. Install, identity, notification and priority surfaces consume the same semantic Light/Dark tokens.

## 3 — Art direction

Salt Lake Temple artwork now begins below the opaque HUD at tablet and desktop sizes; the spires and Moroni remain visible while the HUD itself is unchanged. Celestial Light settles into a warm pearl field and keeps narrative cards cinematic with a short local navy scrim. Celestial Dark retains its deep-blue glass and volumetric gold. No new artwork was needed: the curated portrait and landscape masters already contain the correct composition.

## Theme engine

One Home and one controller serve both artwork-selected families. The new materials are semantic token mixes, not a user toggle or duplicated markup. The Salt Lake safe-area adjustment is bound to its artwork manifest key instead of changing unrelated hero crops.

## Four seats

| Seat | Verb tonight |
|---|---|
| Street player | Explore the voyage, Play, then choose the next priority |
| Ward member | Scan the complete Rama deck without losing card edges |
| Guest | Use public challenge/video routes without fabricated personal activity |
| Ward-only visitor | Choose a linked player from a dedicated glass state |

## Tension

The numbered voyage control makes another chapter visibly available. The complete lower edge of each Rama card preserves the feeling of a deliberate deck, while the priority artwork creates a clear next beat after installation.

## Finale

N/A. This slice improves discovery and continuity on Home; scoring and the live finale are unchanged.

## Languages

N/A — the voyage reuses `hub.continue` and the existing localized rail previous/next labels in es, pt-BR, en and fr.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.7 |
| Clarté | 9.5 |
| Impact visuel | 9.4 |
| Feedback | 9.2 |
| Progression | 9.1 |
| Social | 9.0 |
| Immersion | 9.5 |
| Accessibilité | 9.4 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.2 |

## Verdict

PASS

## What works

- The opening tableau finally announces that it is navigable on every viewport.
- Salt Lake Temple is visible beneath the HUD without modifying HUD anatomy.
- The Rama cards retain their complete bottom border, shadow and focus/hover treatment.
- Light priorities keep rich artwork instead of a full-card milky wash.
- Install, no-player and anonymous states remain honest and visually integrated.

## What feels weak

- The voyage intentionally does not auto-advance; motion remains player-controlled so the hero never steals attention from Play.

## Required before approval

- None.

## Evidence

- Visually inspected 320×568, 390×844, 768×1024, 1024×768, 1440×900, 1536×1024 and 1920×1080 in Celestial Light and Dark.
- Screenshots reviewed for top, Rama rail, utility cards, priorities and forced colors.
- Previous/next interaction, disabled edges, hover, focus, reduced motion and forced colors exercised.
- Console clean; no horizontal overflow; visible controls are at least 44 px; card bottoms keep at least 8 px inside the scrollport.
- Existing PWA wording, selection and permission timing are unchanged; no editorial approval gate was introduced.

## Night director

Yes. The Hub now has a readable rhythm: notice another destination, play, scan what is happening around the Rama, and continue into one strong next action.

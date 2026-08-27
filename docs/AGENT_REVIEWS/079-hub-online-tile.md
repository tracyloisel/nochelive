# 079 — Hub amis en ligne

Reviewed: 2026-08-27
Slice: truthful social presence and ranking invitation
Tests: focused `bin/rails test test/services/hubs/screen_test.rb test/controllers/street_hub_controller_test.rb test/i18n/locale_files_test.rb` — 57 runs, 1098 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and parity-tested

## Feeling

Belonging first, then friendly competition: two real people are visibly present, their progress is legible, and the ranking is the immediate next want.

## 1 — Game experience

Presence creates anticipation; real names, levels, and crowns show meaningful progress; the ranking CTA turns that social proof into competition. Empty state remains honest and still offers the ranking.

## 2 — UI design

The tile reads in two seconds: friends online, truthful count, two rows, then one full-width ranking verb. Real avatars, serif names, quiet metadata, vivid green presence, and a 44px CTA remain readable at 390×844.

## 3 — Art direction

Celestial Light uses warm ivory, a restrained warm shadow, and gold hairlines. Celestial Dark keeps the same geometry on translucent navy glass with cream names and gold metal. No user theme toggle and no flat-black skin.

## Theme engine

The same markup consumes local semantic tokens under `#street_world[data-hub-theme="light"|"dark"]`. Only atmosphere changes; dimensions, hierarchy, content, and interaction remain identical.

## Four seats

Street hub: who is around me is now immediate and truthful. Live-night seat behavior is unchanged.

## Tension

Seeing another person’s crowns creates a light competitive pull toward the Liga without inventing activity or scores.

## Finale

N/A — no live-night finale behavior changed.

## Languages

PASS — `hub.online`, `hub.online_count`, `hub.online_meta`, and `hub.see_ranking` read naturally in es, pt-BR, en, and fr.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- `PersonDevice.live` drives the count and rows; self is excluded.
- Crowns use `Quizzes::Leaderboard.pack_best_totals`; levels use the player rank thresholds.
- The CTA opens the honest `/liga` route.
- Light and Dark screenshots match the same 334×272 mobile geometry.

## What feels weak

- Presence intentionally expires after 25 seconds; development seed data must be refreshed by a normal heartbeat during long manual review sessions.

## Required before approval

- None.

## Evidence

- `tmp/street-shots/temple-themed/hub-online-light-390x844.png`
- `tmp/street-shots/temple-themed/hub-online-dark-390x844.png`
- Full suite: 779 runs, 9665 assertions, 94.86% coverage; two pre-existing `Platform::StatsTest` ward-count failures reproduce in isolation.

## Night director

Yes. The tile turns an otherwise static hub stop into a believable “they are here now” social beat with an immediate competitive next action.

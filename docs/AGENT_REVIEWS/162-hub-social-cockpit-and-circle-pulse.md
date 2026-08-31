# M162 — Hub social cockpit and Circle pulse

Reviewed: 2026-08-31
Slice: one opening Home tableau and its Rama carousel
Tests: `bundle exec rails test test/system/hub_streaming_rails_visual_test.rb` — 2 runs, 940 assertions, 0 failures; targeted service/controller suite — 45 runs, 465 assertions, 1 pre-existing unrelated menu assertion failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — street Hub loop, no live-night rules moved
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr present, parsed and visually exercised

## Feeling

The player should feel momentum and belonging before tapping Play: where they stand, who just moved, and what their ward is discussing are visible without turning Home into an analytics dashboard.

## 1 — Game experience

The opening loop is now story → personal progress → Play → social position → recent ward movement. The Circle card similarly moves from a static doorway to a factual seven-day pulse. No synthetic notifications or fabricated activity are shown.

## 2 — UI design

Progress and Play share one row, baseline and height from tablet upward. The primary action keeps the full gold command treatment. Ranking and recent gains occupy a quiet glass strip beneath it. On the smallest phone, the ranking remains but the gain ticker yields space to the story. Card hover no longer moves into the carousel clipping boundary; emphasis comes from an inset gold edge and image scale.

## 3 — Art direction

The cockpit reads as one ceremonial instrument over the full-width Salt Lake City artwork. Gold remains reserved for action, position and fresh activity. The carousel starts lower on desktop so the social strip and Rama heading never collide.

## Theme engine

One markup and one data model serve Celestial Light and Dark. The artwork-selected theme remains authoritative; no toggle or theme-specific content fork was added.

## Four seats

| Seat | Verb tonight |
|---|---|
| Street player | Play, see my place, notice my ward moving |
| Ward member | Recognize recent points and Forum activity |
| Guest | Play without a fabricated rank or local activity |
| Reader | Open the Forum from an honest activity pulse |

## Tension

The rival gap makes the next leaderboard place concrete. Recent positive gains show that the ward is moving now; the empty state remains calm and truthful when it is not.

## Finale

N/A. This changes the desire to begin or continue a Street journey, not scoring or the live finale.

## Languages

PASS — es uses rama, pt-BR uses ala, fr uses paroisse, and en uses ward. Relative freshness copy is native in all four locales.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9.2 |
| Impact visuel | 9.1 |
| Feedback | 9.0 |
| Progression | 9.2 |
| Social | 9.3 |
| Immersion | 9.0 |
| Accessibilité | 9.0 |
| Cohérence NocheLive | 9.3 |
| Envie de continuer | 9.1 |

## Verdict

PASS

## What works

- Play and progress finally read as one aligned decision.
- Rank, rival gap and recent gains are real ward-scoped data.
- Circle activity is aggregate-only, protecting private post copy and author identity.
- Quiet, active, read-only, guest and narrow-screen states remain honest.

## What feels weak

- The product has no per-member Forum read receipt yet, so the card deliberately says “this week” rather than claiming “unread”.

## Required before approval

- None.

## Evidence

- Visual matrix: 320×568, 390×844, 768×1024, 1024×768, 1440×900, 1536×1024 and 1920×1080, in both artwork-selected theme families.
- Browser console clean; no horizontal overflow; all interactive targets remain at least 44×44 px.

## Night director

Yes. The next round now has a visible social reason: catch the person ahead, join the ward movement, then come back to see the position change.

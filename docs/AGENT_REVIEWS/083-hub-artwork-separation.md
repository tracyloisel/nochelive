# M83 — Hub artwork separation

Reviewed: 2026-08-27
Slice: Home hero, next LIVE card, and the hub scroll surface
Tests: targeted hub service/controller tests — 28 runs, 165 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no user-facing copy changed

## Feeling

Curiosity for the biblical adventure, then anticipation for a distinct live game-show night.

## 1 — Game experience

The two primary cards now promise two different experiences at a glance: solo adventure and collective spectacle. Scrolling remains touch- and wheel-native without a browser rail cutting through the game frame.

## 2 — UI design

The two-second verbs remain **Jouer** and **Voir le programme**. No markup or routes were forked. Idle, pressed, loading, live, and empty behavior remain unchanged.

## 3 — Art direction

The royal world backdrop uses Solomon's temple, the adventure hero keeps David's anointing, and LIVE uses a dedicated Celestial Dark violet/gold cultural-hall stage. The repeated-poster effect is removed.

## Theme engine

One Home and the same semantic tokens remain. The backdrop is still manifest-selected; the LIVE card owns an event-specific still and declares Dark/glorious independently.

## Four seats

Street hub: who / where / what now / around me remains intact. The LIVE preview now communicates the future room spectacle instead of borrowing street-quiz media.

## Tension

The home sequence rises from personal progress to immediate adventure, then reveals a larger social event.

## Finale

N/A — no round or scoring change.

## Languages

N/A — no copy moved.

## Scores (/10)

- Fun: 8
- Clarté: 9
- Impact visuel: 9
- Feedback: 8
- Progression: 8
- Social: 9
- Immersion: 9
- Accessibilité: 9
- Cohérence NocheLive: 9
- Envie de continuer: 9

## Verdict

PASS

## What works

- Three visual layers now have three clear jobs.
- The visible browser scrollbar is gone without disabling scrolling.
- The LIVE image reads as a populated, multigenerational game-show night.

## What feels weak

- The dedicated LIVE artwork is currently shared by all scheduled themes; future nights can opt into theme-specific stage variants without changing the card.

## Required before approval

- None.

## Night director

Yes: the home now promises both a next quiz and a bigger collective moment instead of showing the same painting repeatedly.

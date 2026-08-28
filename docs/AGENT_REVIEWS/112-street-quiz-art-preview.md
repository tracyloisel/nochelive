# M112 — Street quiz art preview

Reviewed: 2026-08-28
Slice: one constant visual breath before every street-quiz question
Tests: targeted quiz suite — 27 runs, 256 assertions; UI contract suite — 22 runs, 1,626 assertions; targeted system test — 1 run, 10 assertions; 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A — no player-facing copy moved

## Feeling

Curiosity and wonder: see the biblical scene, anticipate the ask, then play.

## 1 — Game experience

The street loop becomes illustration → question → choice → result → reward → next illustration. Every ask receives the same 1.1-second beat; the delay does not grow with intensity. A pointer press skips the beat immediately, so anticipation never becomes forced waiting. Timed questions receive their full response window after the reveal.

## 2 — UI design

The server renders an explicit `is-art-preview` state, preventing a first-paint flash of the sheet. During preview the question dock and timer are non-interactive and visually absent. Reveal lifts the translucent sheet and staggers choices. The question card has no backdrop blur and no named View Transition snapshot; contrast comes from its tinted surface, gold hairline, and shadow. Reduced-motion users receive the question immediately. Existing Light/Dark tokens and geometry are unchanged.

States: art preview → revealing/locked → live ask → picked/locked → settled → next preview. Loading, failure, completed, and ceremony behavior are unchanged.

## 3 — Art direction

The painting owns the frame for one short beat while the compact HUD preserves player context. The lower scrim is removed during preview, so the illustration is not dimmed for UI that is not yet present. The scene remains Celestial Light or Dark according to its artwork; no new theme or arbitrary color is introduced.

## Theme engine

N/A — `/jugar` street slice, no hub atmosphere change.

## Four seats

N/A — solo street quiz. The player sees who they are, pack/progress, score/streak, then the next action.

## Tension

The street rhythm gains a constant anticipation beat. Question stakes and rewards still carry the rising curve; delay length remains deliberately flat.

## Finale

Unchanged.

## Languages

N/A — no copy added or changed.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- Constant cadence makes the art preview a recognizable Noche Live ritual.
- Tap-to-reveal and reduced motion prevent dead waiting.
- The countdown is clamped and released with the question, not consumed behind the artwork.
- Next artwork was already prefetched, so the beat does not expose loading chrome.

## What feels weak

- Early tap release is enforced precisely by the browser countdown; the server keeps the small preview cushion as a reliability guard.

## Required before approval

- None.

## Evidence

- `node --check` passes for both changed Stimulus controllers.
- Targeted Rails, UI contract, and mobile system tests pass; the preview screenshot is sharp and the question card has no `backdrop-filter`, `street-sheet`, or `street-dock` legacy path.

## Night director

Yes. The next round begins with curiosity instead of immediately dropping another word card over the painting.

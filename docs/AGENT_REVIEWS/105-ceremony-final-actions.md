# M105 — Ceremony final actions

Reviewed: 2026-08-28
Slice: the post-score decision from “Retour à la carte” downward
Tests: challenge service — 8 runs, 22 assertions, 0 failures; targeted controller blocked before execution by pending unrelated migration `20260828220000_create_identity_transfers`; local browser funnel passed
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: N/A — existing localized keys remain unchanged

## Feeling

Accomplishment first, then friendly rivalry and belonging. The score has landed; the player should leave cleanly or turn the result into the next shared game.

## 1 — Game experience

The result now turns pride into the next shared game. The gold action creates or reopens a score challenge and launches native sharing; the challenge inbox and map remain available as secondary exits. A pending duel is surfaced as status, not as loose copy on the painting.

Loop: result → reward → share the score → friend sees the exact score to beat → duel → rematch.

## 2 — UI design

Two-second verb: **Partager mon score**. It is the only gold, full-width, breathing CTA. For a signed-in player it carries the completed run id into challenge creation, so the score on the ceremony becomes the score shown to the invitee. **Voir les défis** and **Retour à la carte** sit below as equal ivory exits; on phone all three stack, and from 540 px the two exits share one row.

States covered: idle, hover, pressed, focus-visible, completed, challenge waiting, challenge available, guest, and reduced motion. Mobile targets are 44 px minimum. Existing `--type-min`, gold, ink, ivory, hairline, spacing, duration, and easing tokens drive the block.

## 3 — Art direction

Emotion: pride asking to be passed to someone specific. Composition: faceted gold share ticket with the painted share medallion, then engraved ivory challenge and compass exits. World: celestial gateway. Family: Celestial Light from the artwork. Gold now marks the viral continuation, not the passive exit.

## Theme engine

N/A — this is the fixed Celestial Light pack ceremony gateway, not the hub.

## Four seats

N/A — street loop. Who: the current player. Where: completed pack. What now: share this score. Around me: pending rival, challenge inbox, and the map exit.

## Tension

The quiz tension has resolved, but the precise score immediately creates a new social stake: “can you beat 65?”

## Finale

This is the street pack payoff. It does not alter a live-night finale.

## Languages

No copy moved or changed. Existing `street.*` keys continue to render in es, pt-BR, en, and fr.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 9 |
| Social | 10 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- One dominant gold share action, then two clearly secondary exits.
- Compass, challenge crest, share crest, and continuation arrow make each verb recognizable before the copy is read.
- The ceremony CTA sends the finished run to challenge creation; the generated duel keeps the exact completed score as `challenger_score`.
- Pending-duel copy has contrast and an immediately recognizable hourglass medallion.
- Phone and short-landscape layouts preserve 44 px targets and 14 px minimum type.

## What feels weak

- The two new controller assertions cannot currently start because the working tree contains an unapplied identity-transfer migration outside this slice.

## Required before approval

- No design veto. Apply or resolve the identity-transfer migration in its owning slice, then run the two targeted controller assertions.

## Evidence

- Local browser, `/jugar`, completed Plaques pack, then `/desafios`.
- 390 × 844: share 361 × 56 px; challenge 361 × 51 px; map 361 × 51 px; no clipped label.
- Clicking the ceremony share CTA created a pending Plaques duel showing the completed **65** as the score to beat.
- Browser console: 0 warnings, 0 errors.

## Night director

Yes. The ceremony no longer encourages the player to leave first; it turns the earned score into the next person’s challenge.

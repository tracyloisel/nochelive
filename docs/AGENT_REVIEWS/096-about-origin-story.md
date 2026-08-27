# M096 — About origin story

Reviewed: 2026-08-28
Slice: `/nosotros`, from legacy temple paper to an Iglesia-style human origin journey
Tests: `bin/rails test test/controllers/ward_adds_controller_test.rb test/i18n/locale_files_test.rb` — 9 runs, 225 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validated

## Feeling

Belonging and generosity: this began around one table and is meant to travel to many more.

## 1 — Game experience

The page now follows a short narrative loop: full-screen promise → origin → open contribution → future → personal invitation. The contact block is the next want, not a directory card at the top.

## 2 — UI design

The purpose reads in two seconds. Three numbered chapters replace an undifferentiated wall of text. The legacy `paper_hall` shell is absent; the persistent Iglesia dock keeps the page inside the same journey language. GitHub is the one gold action; contact channels remain clearly labeled, large targets.

## 3 — Art direction

The warm Benidorm family-night illustration is now the full-screen world, transitioning into Celestial Dark editorial chapters. The community is the hero; restrained gold signs the page without gold headlines. Mobile cropping keeps faces in frame and no legacy temple background remains.

## Theme engine

N/A — not the hub.

## Four seats

N/A — editorial page.

## Tension

N/A — the rhythm is editorial reveal, not a round.

## Finale

N/A.

## Languages

New copy is present in es, pt-BR, en, and fr. Locale parity tests pass.

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
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- The first screen explains the gift before introducing its maker.
- The new artwork makes the origin tangible and survives the 390 px crop.
- The open-source and private-initiative facts remain explicit.

## What feels weak

- This remains an editorial page, so payoff is intentionally quieter than a playable surface.

## Required before approval

- None.

## Evidence

Browser review at 390 × 844 confirms `legacyHall: 0`, one full-screen hero, and the Iglesia body shell. Targeted controller and locale tests green.

## Night director

Yes: the page creates a credible desire to join or bring the next Noche Live to another branch.

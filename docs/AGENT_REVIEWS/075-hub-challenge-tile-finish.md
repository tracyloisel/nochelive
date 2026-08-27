# 075 — Hub défi tile finish

Reviewed: 2026-08-27
Slice: finish the interrupted **Défi en cours** tile — honest active face-off and completed score race
Tests: `bin/rails test test/services/hubs/screen_test.rb test/services/quizzes/ensure_hub_duel_test.rb test/controllers/street_hub_controller_test.rb test/i18n/locale_files_test.rb`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Rivalry before the first tap: LoopDefi sees Pili waiting across a physical ivory VS capsule. Once both players finish, the same tile becomes an honest score race.

## 1 — Game experience

Loop: spot a real rival → tap the face-off → play/open the named défi → see both real scores. The development task now creates a `challenger_done` duel through `Quizzes::StartPack`, `Submit`, `Advance`, `Complete`, and `ChallengeCreate`; it does not recycle a resolved result or invent a score.

## 2 — UI design

The active state is a large two-avatar VS object. The scored state carries kicker, chevron, rival avatar/name/status, you | VS | them bar, and finish-first footer. Real scores sit at the bar ends; VS remains centered. Idle/pressed use the existing link and press system; empty remains the existing challenge rail.

## 3 — Art direction

Dark is charcoal, cream, and gold with a generous ivory arena. Light is ivory paper with ink typography and gold hairlines. The same ERB changes atmosphere only through `#street_world[data-hub-theme]`.

## Theme engine (hub `/`)

One component consumes semantic hub tokens. Celestial Dark comes from the current Rois artwork manifest; the Light browser pass switches the same DOM to the Light token family for visual verification. No user toggle and no duplicated Home.

## Four seats

Street hub: who (HUD) / where (rama) / what now (Jouer) / around me (named active duel).

| Seat | Verb tonight |
|---|---|
| Host | N/A street |
| Chapel (controller) | N/A street |
| Remote | N/A street |
| TV / Twitch | N/A street |

## Tension

An unfinished duel holds the stare without leaking one player’s score. Both scores appear only after both are present, turning the tile into a readable chase.

## Finale

N/A street pack.

## Languages

`hub.rival_finished` is native in es / pt-BR / en / fr. French keeps the thin space in the existing finish-first footer.

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
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- Real animal avatars make the rivalry immediate.
- Active and scored states never imply a missing score.
- Light/Dark dimensions and information architecture stay identical.

## What feels weak

- Resolved challenge routes return to the hub result state rather than a separate ceremony.

## Required before approval

- None.

## Evidence

- Seed: `bin/rails noche:hub_challenge` → `LoopDefi vs Pili · challenger_done · 40/`.
- Dark 390×844: `tmp/street-shots/temple-themed/hub-challenge-dark-phone.png`.
- Light 390×844: `tmp/street-shots/temple-themed/hub-challenge-light-phone.png`.

## Night director

I would tap it: the active face-off creates a social promise, and the scored state makes the rematch desire visible.

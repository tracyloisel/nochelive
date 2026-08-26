# 040 — Street challenge playable and scored

Reviewed: 2026-08-26
Slice: `/desafio` + hub banner + ceremony result — async friend challenge scores and play
Tests: `test/services/quizzes/challenge_*_test.rb`, `test/controllers/street_challenges_controller_test.rb`, `test/controllers/street_hub_controller_test.rb`, `test/controllers/street_profiles_controller_test.rb`
Gate: street pack (not live-night seats)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — new `street.duel_*` keys in es, pt-BR, en, fr

## Four seats

N/A (street pack, not live night). Street player: accept a friend’s pack, play the same ten questions, see who won.

## Tension

N/A.

## Finale

The pack ceremony now pays the duel: waiting copy + share while the friend plays; face-off scores when both are done. Hub shows the same waiting or result without needing the original link.

## Languages

New keys read in **es**, **pt-BR**, **en**, **fr**: waiting, score to beat, share again, play the challenge, create failed. Tú / você / tu / you for one phone. noche-i18n: PASS.

## Verdict

PASS WITH NOTES

## What works

- Accepting a challenge starts a **fresh** run on that pack even if the map still has it locked — a friend who never opened pack 2 can still play the invite.
- Scores only come from **finished** runs. A second phone cannot steal the opponent slot. In-progress world runs are not reused, so both sides answer the same ten questions.
- Result renders inside the ceremony turbo replace (not a dead sibling on `/jugar`). Hub keeps the token through the ficha gate and auto-starts after pick. Guest skip is blocked while a challenge is pending.
- Share create failures toast instead of going silent.

## What feels weak

- No push when the friend finishes; the challenger sees the result on the next hub visit.
- OG preview image for the share link is still out of scope.

## Required before approval

- None for this slice.

## Evidence

Reliability: `ChallengeResolve.after_run!` locks the row; `ChallengeAccept` starts with `StartPack(challenge: true)`. Playability: locked-pack accept test + ficha auto-start + ceremony turbo result.

## Night director

Would I send the link to my sister who has never opened the map? Yes — she picks a ficha and plays that pack.

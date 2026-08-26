# 042 — Conseil Noche: défis inbox, hub, scores

Reviewed: 2026-08-26
Slice: deepen `/desafios` + hub banner + ceremony wait — named rama challenges that can be found again
Tests: `bin/rails test` — 645 runs, 7147 assertions, 0 failures (94.71%)
Gate: street pack (not live-night seats) — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — new `duel_waiting_named` / `duel_playing_named` / `duel_inbox_open` / `duel_pack_with_score` in es, pt-BR, en, fr
UI: `.cursor/skills/noche-ui/SKILL.md` — Liga sibling sheet, not a fifth hub tab, not a mockup of its own (nearest seat: `/liga`)

## Four seats

N/A (street, one phone). Street seat (tú): accept or send a pack challenge inside the rama; see who won without a WhatsApp link.

## Tension

N/A. The street job is the wait: someone in the rama has a score to beat, then you play the same ten questions.

## Finale

N/A. Pack ceremony still pays the duel. Named wait no longer asks you to share a link the friend already has.

## Languages

noche-i18n: **PASS**
- **es** — tú, rama, pack. «Cuando %{name} acepte…» / «ya está jugando este pack.»
- **pt-BR** — você, ala, pacote. No ramo/ward calque.
- **fr** — tu (one phone), paroisse, parcours. Thin space unused (no ? ! in the new lines).
- **en** — you, ward (already the liga word), pack. No *contestants*.

Homonyms use `Person#display_name` (Carmen García / Carmen López). Keys present in all four files; locale parity test green.

## Verdict

PASS WITH NOTES

## What works

- Hub picks the duel you can **act on** (accept / play) before a waiting outgoing or a result. Visiting the hub as challenger no longer pins your own token, so a ficha switch cannot accept your invite as someone else.
- Named wait (hub, `/desafio`, ceremony) names the person and points to **Ver desafíos**. Share-again stays for the anonymous WhatsApp path only.
- Liga keeps a quiet **Desafíos** (not `btn-gold`). Incoming count is ink in a gold-hairline disc — not a LIVE chip. Inbox rows sit like liga rows; if someone already challenged you, **Desafiar** drops to navy so Accept/Play stays the gold verb.
- Pack picker shows your score on that pack. Rivals without a liga total show — , not 0.

## What feels weak

- Still no push when the friend finishes. The challenger sees the result on the next hub or inbox visit (now more likely, because a fresh result ranks above waiting).
- OG image for the public `/desafio/:token` link remains out of scope.
- Hub crowding: duel CTA clipped, map gone — see [043](043-street-hub-map-page.md).

## Required before approval

- None for this slice.

## Evidence

Reliability: `ChallengeScreen` phase rank; hub `pin_challenge_token!`; `ChallengeInbox.actionable_count`. UI: liga quiet-link + inbox rows. Copy: tú / você / tu / you.

## Night director

Would I challenge Carmen García from Liga and trust Pili to find Accept on her phone without me texting the token? Yes. Would I ship this as a Friday four-seat round? No — it is street, and it should stay street.

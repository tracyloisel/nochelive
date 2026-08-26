# 041 — Street défis inbox from Liga

Reviewed: 2026-08-26
Slice: `/desafios` member challenges + quiet link from `/liga` — not a fifth hub tab
Tests: `bin/rails test` — 641 runs, 7094 assertions, 0 failures (94.74%)
Gate: street pack (not live-night seats)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — new `street.duel_inbox*` / `duel_pick*` keys in es, pt-BR, en, fr

## Four seats

N/A (street pack). Street player: open Desafíos from Liga, accept a named duel, or send one to someone in the rama.

## Tension

N/A.

## Finale

N/A.

## Languages

New keys read in **es**, **pt-BR**, **en**, **fr**. Tú / você / tu / you. Liga stays a quiet-link, not a gold CTA. noche-i18n: PASS.

## Verdict

PASS WITH NOTES

## What works

- `/liga` has one quiet **Desafíos** link. `/desafios` is the same marble sheet: incoming Accept, waiting, one gold **Desafiar** to a rama member on a pack you already finished, recent results.
- Named create sets the opponent. WhatsApp `/desafio/:token` still creates an anonymous share (JSON). Same-pair reuse does not steal the anonymous open duel.
- No ficha → pick a card, then return to the inbox (`street_return`).

## What feels weak

- No push when the friend finishes; you still see the result on the next visit.
- Rivals with no liga score show 0 until they have finished a pack.

## Required before approval

- None for this slice.

## Evidence

Inbox is a Liga sibling, not a hub dock. `ChallengeCreate` Denied codes (`self` / `ward` / `score`) keep named duels inside the rama.

## Night director

Would I challenge Carmen from the standings without leaving the rama? Yes — one gold send, then she sees Accept on her inbox.

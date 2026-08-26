# 045 — Street défis lisibles, victoires, ping live

Reviewed: 2026-08-26
Slice: `/desafios` ivory sheet + stacked tiles + named results; live-first rivals; in-app Turbo ping + Décliner — not OS Web Push
Tests: `bin/rails test` — 663 runs, 7269 assertions, 0 failures (94.78%)
Gate: street pack (not live-night seats) — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — new `duel_waiting_link` / `duel_you_won` / `duel_decline` / `duel_played` keys in es, pt-BR, en, fr
UI: `.cursor/skills/noche-ui/SKILL.md` — Liga sibling; ivory `.hall-sheet` on the hall; no mockup of its own; no `.gate`; ink on paper

## Four seats

N/A (street, one phone). Street seat (tú): read a waiting tile, see a win, challenge a live neighbor, or accept/decline a ping without leaving the app.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS**
- **es** — tú, rama, pack. «Has ganado contra %{name}» / «Envía el enlace…»
- **pt-BR** — você, ala, pacote. «Você ganhou de %{name}». Recusar, not recusar o convite calque.
- **fr** — tu (one phone), paroisse, parcours. «Tu as gagné contre %{name}». Décliner.
- **en** — you, ward, pack. «You won against %{name}». Decline.

Keys present in all four files; locale parity test green.

## Verdict

PASS WITH NOTES

## What works

- Waiting tiles stack: pack + one sentence + full-width share. Recents sit above «choose who», so a Carmen result is the job, not a quiet link under the fold.
- Same pair + pack after a resolved duel is `Denied :played`. The row shows Ganaste / Perdiste / Empate instead of gold Défier. Live devices sort first, green presence dot, no LIVE chip.
- Named create pings a live opponent over Turbo (`#street_duel_ping`) with Accepter + Décliner. Night seats (play / watch / presenter) do not subscribe.

## What feels weak

- Still no OS Web Push when the phone is locked. If Carmen is not live at send time, she only sees the inbox on the next visit.
- Anonymous WhatsApp share still has no named face.

## Required before approval

- None for this slice.

## Evidence

Reliability: `ChallengeCreate` `:played`, `ChallengeDecline` status `declined`, `ChallengeNotify` only if `PersonDevice`/`Player` live. UI: ivory hall-sheet, stacked cards. Copy: tú / você / tu / you.

## Night director

Would I understand the waiting tile and see that I already beat Carmen on this pack? Yes. Would I ship phone-lock push this Friday? No — that is a later PWA slice.

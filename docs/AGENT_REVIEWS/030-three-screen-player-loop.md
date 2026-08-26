# 030 — Three-screen player loop (tick 8)

Reviewed: 2026-08-26
Slice: street hub parcours — full scrollable pack path, replay finished nodes, longer helix, Liga flush on Continuer. Prior: MAPA ivory flag, XL current, CORONAS pill, title nowrap.
Tests: `bin/rails test test/controllers/street_hub_controller_test.rb test/services/quizzes/start_pack_test.rb test/services/quizzes/world_test.rb test/system/street_quiz_visual_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: `street.pack_replay` in es / pt-BR / en / fr. No gold “Jouer le pack” on nodes.

## Four seats

Hub is street, not a night. Ceremony monument and lobby wait unchanged.

## Tension

N/A (chrome + parcours).

## Finale

Street pack complete only. Replay of a finished pack starts a new run via `Quizzes::StartPack` (existing service). Night ceremony untouched.

## Languages

noche-i18n: PASS — `pack_replay` is a quiet body verb: es Otra vez / pt-BR De novo / fr Rejouer / en Play again.

## Gap matrix (tick 8)

| Screen | Gap | Priority | Fixed? |
|---|---|---|---|
| Path | 3-node clip only | P0 | **yes** — all packs, locked above / current / finished below, map `overflow-y: auto` |
| Replay | Finished packs dead | P0 | **yes** — tap node → `StartPack`, ink “Otra vez”, dock stays the one gold CTA |
| Rope | 1.4rem gaps, reads as nubs | P0 | **yes** — 4.25rem brown-gold helix between thumbs |
| Liga | Floated mid-column over empty flex | P0 | **yes** — map `flex: 1`, league `flex-shrink: 0` last block above dock |
| Titles | Wrap on 390 plaque | P0 | **yes** — nowrap + 0.58rem, tighter plaque |
| MAPA | Wide 127×26 flag | P1 | **yes** — tighter ivory box, sticky pin while the path scrolls |
| League wards | Fake mockup parishes | KEEP | live one-parish board |

## Verdict

PASS WITH NOTES — first fold still aims at current XL + neighbors + league + Jugar. Mute and flag stay. Live names/scores kept.

## What works

- Hall is the canvas; `.street-map-track` stays `background: none`.
- MAPA stays an ivory title-only flag (sticky over the scrolling path).
- Current is still XL gold rim, star left, CORONAS pill right.
- One gold CTA remains dock JOUER/CONTINUER.

## What feels weak

- Helix is still a CSS hatch, not a photographed braid.
- Live league is still one parish (not the mockup’s fake wards) — KEEP.
- Very long later titles (`Pack 10 — Avant de naître`) may still feel tight on the 390 plaque.

## Required before approval

- Recapture `tmp/street-shots/temple-themed/hub-phone.png` at 390×844.

## Night director

Can I scroll the pilgrimage? Yes — the map is the scrollport, current lands in the middle. Can I replay a finished pack without a second gold Jugar? Yes — tap the node. Does Liga sit on Continuer? Yes. Does the rope read as rope between thumbs? Yes — 4.25rem helix.

## Evidence

Playwright phone shot this tick (390×844): `tmp/street-shots/temple-themed/hub-phone.png`.
Mockup: `tmp/street-shots/temple-mockups/mockup-street-hub-temple-ui.png`.

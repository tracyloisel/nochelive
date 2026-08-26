# 023 — Street world hub

Reviewed: 2026-08-25
Slice: street quiz gamification — hub `/`, reel `/jugar`, duels, share
Tests: `bin/rails test` — 482 runs, 0 failures (94.54% coverage)
Gate: `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Four seats

| Seat | Verb tonight |
|---|---|
| Presentador | N/A |
| Equipo en sala | N/A |
| Jugador en casa | Browse map, play pack, challenge friend async |
| Espectador | N/A |

## Tension

Sequential pack unlock + ward league strip + rival gap on `/jugar` chrome. Pack ceremony (chest, stars, rank-up) returns to hub with visible progress.

## Finale

N/A for live night. Street pack 10 slam unchanged; ceremony is the solo boss payout.

## Languages

New keys `street.world_*`, `street.card_*`, `street.ceremony_*`, `street.duel_*`, `street.share_*` in es, en, fr, pt-BR.

## Verdict

PASS WITH NOTES

## What works

- `/` hub: player card, zigzag pack path, league strip, friend rail, inline profile wizard.
- `/jugar` reel: level rail, rival chip, no map in sheet, pack-complete ceremony.
- Services: `Quizzes::World`, `Stars`, `StartPack`, `Rival`, `Streak`, `ChallengeCreate/Accept/Resolve`, enriched `Complete`.
- `StreetDuel` async PvP via `/desafio/:token`.
- `street_share_controller` Web Share + clipboard fallback.
- `street_motion_controller` pack ceremony + duel reveal (reduced-motion safe).

## What feels weak

- OG image generation for share cards is out of scope.
- Weekly league reset not implemented.
- Duel result on `/jugar` only renders when a finished open run exists — resolved duels after hub return need a dedicated result route (iteration 5).

## Iteration 5 gaps

- Dedicated duel-result screen or hub card after both players finish (today: partial exists but `/jugar` requires open run).
- Push/in-app notification when a challenge arrives (banner only via link/session).
- OG share image generation for social previews.
- Weekly league reset + season ceremony.

## Iteration 2 polish (2026-08-25)

- Map: fixed `is-current` class on pack cards, gold beacon arrow + pulse ring on load scroll.
- Hub return `?rank_up=1`: player-card gold ring (2s) synced with `level_up` SFX via `data-stage-sfx` + `street_hub_controller`.
- Friend rail stagger entrance; rival chip slide-down on `/jugar`.
- Ceremony: tighter star-pop (130ms stagger) + board-rise (90ms), `correct_gold` at star reveal, skip clears phase timers.
- Desktop hub: centered column layout + `hub-desktop.png` in visual test.

## Iteration 3 polish (2026-08-25)

- Profile wizard: warm paper scrim + opaque panel; map/friend rail/league/dock hidden while gate open (`is-profile-gate`).
- Visual tests: hub-phone waits for current-pack beacon; `rank-up-phone` via `/?rank_up=1` with signed-in profile.

## Iteration 4 polish (2026-08-25)

- Duel banner: VS face-off layout (rival avatars, gold metal border, pack label, accept CTA); loads from `?desafio=` or `session[:pending_duel_token]`.
- Duel result: winner gold ring + loser dim; `duelReveal` sequence on connect (reduced-motion instant).
- Share card: score hero, ward name, stars, ghost CTA in ceremony/duel footers (one gold CTA per screen); toast uses `street.share_copied` i18n via data attribute.
- Jugar juice: stronger correct/wrong choice states; `street_level_rail_controller` re-triggers dot fill on turbo replace; timer pulse last 5s on street reel.
- Hub juice: finished-pack star pop on load; league strip crown/trophy medals #1–#3; invite plus bounce.
- Visual tests: `duel-banner-phone.png`, `share-card-phone.png`, `jugar-ceremony-desktop.png`.
- Integration: full duel accept → finish → resolve flow in `street_challenges_controller_test`.

## Iteration 6 — temple celestial UI (2026-08-25)

- Visual direction: SLC celestial room → mobile game. Luminous ivory marble, oculus radial light, gold-leaf borders/arches/stars, ink titles and scores (never gold body text).
- CSS tokens: `--temple-marble`, `--temple-oculus`, `--temple-gold-leaf`, `--temple-gold-border` scoped to `body.is-street-hub` / `body.is-street-play`.
- Hub: oculus sunburst, column hints, hub title + map path header card, hex gold **Jugar** CTA.
- Jugar: arched marble sheet with apex star, level rail star bookends, temple chrome on score/rival chips.
- Ceremony: gold arch frame, ink score hero (was gold — fixed), marble boards.
- Media: `config/media/street_world.yml` for adventure still brief; `script/generate_quiz_media.rb` merges world style with `quiz_stills.yml` scenes. `chapel_world.yml` unchanged for live night.
- Visual tests: copies in `tmp/street-shots/temple-themed/` (`hub-phone`, `ceremony-phone`, `01-ask-phone`, etc.).

## Iteration 7 — large-rama leaderboards (~600 members) (2026-08-25)

- `Quizzes::Leaderboard`: scoped person loading (no `@ward.people` bulk), pagination (`offset`/`page`), name search (`q`), `include_you` context row when rank is outside top-N mini board.
- `Quizzes::Standings`: single leaderboard call per board (was 4 redundant calls with `limit: 100`).
- `Quizzes::Rival`: fetches person at rank−1 by offset (fixes bug when user rank > 100).
- `/liga` full standings page: paginated list (25/page), pack tabs, name search, temple `.street-board` chrome.
- Hub: player card shows `#X de N`; league strip top-3 + “Ver clasificación”; ceremony mini boards top-5 + your rank context row.
- Fichas index: search + pagination (48/page); presenter guest link uses name search (no 600-option `<select>`).
- Tests: bulk ward fixtures in `leaderboard_test`, `rival_test`, `street_leaderboards_controller_test`.

## Required before approval

- None for this slice.

## Evidence

UI soul + noche-ui updated for `#street_world` / `/jugar` split. SFX: `chest`, `level_up`, `correct_gold` on ceremony via `data-stage-sfx`.

## Night director

Would I tap the next pack on the map? Yes — the hub feels like a mobile game home, not a form with a quiz behind it.

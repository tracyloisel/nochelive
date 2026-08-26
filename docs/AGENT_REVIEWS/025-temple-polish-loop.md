# 025 — Temple mockup polish loop

Reviewed: 2026-08-26 (hub mockup loop tick 16)
Slice: street hub `#street_world` vs `mockup-street-hub-temple-ui.png` — remaining metal after tick 13
Tests: `PARALLEL_WORKERS=1 bin/rails test test/controllers/street_hub_controller_test.rb` (8/72) + `test/system/street_quiz_visual_test.rb --name "/hub league strip|hub map and jugar/"` (2/46) — 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (MAPA star is CSS metal; no new `t()` keys)

## Hub mockup loop (tick 16)

c8285f94 / 7e62c5f9 / de7041fe (tick 13) had finished by edit time — merged, did not revert rope spans or 8rem hero. Remaining screenshot misses: gold helix on the XL still, brown hemp cord, beige MAPA ribbon, hex JUGAR, machined cog.

| Change | Why |
|---|---|
| Hemp helix (`#4a320c`…`#d4b46a`) + cards `z-index: 2` / rope spans `z-index: 3` | Brown twisted cord **between** nodes; thumbs cover the spine (mockup rope sits behind packs) |
| Current glow 28px halo; locked/done `2.65rem` | XL aura without eating gutters; small nodes closer to mockup squares |
| Pointer `#c9a23a` + rim glow | Solid gold 4-point, not brown metal |
| MAPA champagne ribbon + `star4` (not gold-leaf `+`) | Ink title on beige; gold star is metal |
| LIGA rule tips 0.46rem with highlight facet | Reads closer to 3D diamonds |
| Cog 8 short teeth, small bore, bronze `#8a6410` | Clock gear vs 6-tooth floral |
| Hex JUGAR (`1.15rem` points) + gold `star8` flanks | Mockup pointed bar, not a pill |

First fold still holds (`assert_above_hub_dock`). Mute + flag stay.

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`

### Remaining gaps vs mockup

- XP / league use fixture Pili / Carmen (`95 / 110`), not mockup Andrés / 7,850 / María G.
- Avatars are fichas, not painted explorers.
- Pack stills are catalog adventure art, not Desierto Dorado / Selva Escondida.
- Mute + flag stay on hub (product); mockup hides them.
- Guest path is 2 nodes, no league — `hub-guest-phone`.
- Current hero is 8rem, not mockup full-bleed square (first-fold cap).
- Cog is 8-tooth bronze; at 1.35rem the teeth can still read as a ring of squares.

---

Reviewed: 2026-08-26 (hub mockup loop tick 13)
Slice: street hub `#street_world` vs `mockup-street-hub-temple-ui.png` — remaining metal after tick 9 + iter 2
Tests: `PARALLEL_WORKERS=1 bin/rails test test/controllers/street_hub_controller_test.rb` (8/72) + `test/system/street_quiz_visual_test.rb --name "/hub league strip|hub map and jugar/"` (2/46) — 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (MAPA `+` is CSS decoration; no new `t()` keys)

## Hub mockup loop (tick 13)

Merged tick 9 / iter 2 (8rem hero, `star4` pointer, 2.25rem braid, 6-tooth cog, MAPA card, LIGA title) — did not revert. The screenshot still showed a hairline cord, hex `+ JUGAR +`, and a sunburst gear.

| Change | Why |
|---|---|
| `.street-map-rope` spans between nodes (`1.15rem` × `2.25rem`, z-index 1) + tighter current glow | Cord paints **in the gutters**; 48px thumb glow was eating the braid |
| Locked/done thumbs `2.15rem` (rope `2.25rem`) | Helix peeks at the sides of small nodes |
| `star4` inner radius + `#8a6410` fill | Solid 4-point metal, not a plus |
| MAPA title `::after` `+` + slightly wider card | Ribbon matches mockup “MAPA DE VIAJE +” |
| LIGA title `0.88rem` display | Rank name reads as the strip header |
| Gear teeth shorter/wider (6-tooth) | Mechanical cog vs sunburst |
| JUGAR pill (`border-radius: 999px`, no hex clip) + `star8` flanks | Mockup wide gold **bar**, not chevron ends / plus signs |

First fold on 390×844 still holds (`assert_above_hub_dock`). Mute + flag stay.

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`

### Remaining gaps vs mockup

- XP / league use fixture Pili / Carmen (`95 / 110`), not mockup Andrés / 7,850 / María G.
- Avatars are fichas, not painted explorers.
- Pack stills are catalog adventure art, not Desierto Dorado / Selva Escondida.
- Mute + flag stay on hub (product); mockup hides them.
- Guest path is 2 nodes, no league — `hub-guest-phone`.
- Current hero is 8rem, not mockup full-bleed square (first-fold cap).
- JUGAR flanks are 8-point stars (read as sparkles), not the mockup’s hairline 8-point metal.

---

Reviewed: 2026-08-25 (hub mockup loop iteration 2)
Slice: street hub `#street_world` vs `mockup-street-hub-temple-ui.png` — remaining iter-1 gaps, merged with tick 9
Tests: `PARALLEL_WORKERS=1 bin/rails test test/controllers/street_hub_controller_test.rb test/system/street_quiz_visual_test.rb` — 19 runs, 213 assertions, 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no new strings). MAPA / LIGA / JUGAR keep existing `t()` keys in es, pt-BR, en, fr.

## Hub mockup loop (iteration 2)

Merged tick 9 metal (8rem hero, `star4` pointer, braid) instead of reverting. The remaining miss was the cord sitting on `path::before` *behind* the track, so thumbs ate it.

| Change | Why |
|---|---|
| Braid on `.street-map-track::before` + 1.15rem gutters | Free-standing gold helix **between** nodes, not a wash behind the thumbs |
| Current thumb `8rem` (locked/done `2.85rem` from tick 9) | Largest square that still keeps 3 nodes + LIGA + JUGAR above the dock on 390×844 |
| Star pointer `star4` picto, `#a37a12`, tight rim shadow | Solid 4-point gold metal on the left, not a faint clip-path glow |
| `gear` picto → 6-tooth cog (alias `cog`) | Settings no longer reads as a sunburst of rays |
| MAPA DE VIAJE gold banner + compass rose watermark | Card left of the path |
| `LIGA …` flex title + gold rules with diamond tips | League name visible |
| Hex JUGAR kept (dark serif + `star4` flanks) | Match mockup; mute + flag stay |

noche-i18n: PASS — no new copy. es Mapa de viaje / Liga %{rank}; pt-BR Mapa da jornada / Liga; en Journey map / league; fr Carte du voyage / Ligue.

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`, `hub-league-phone.png`.

### Remaining gaps vs mockup

- XP / league use fixture Pili / Carmen (`95 / 110`), not mockup Andrés / 7,850 / María G.
- Avatars are fichas (turtle / dolphin), not painted explorers.
- Pack stills are catalog adventure art, not Desierto Dorado / Selva Escondida.
- Mute + flag stay on hub (product); mockup hides them.
- Guest path is 2 nodes, no league — `hub-guest-phone`.
- Gear is a 6-tooth cog; at 1.35rem it can still read a bit floral vs a machined clock gear.
- Hero is 8rem, not mockup full-bleed square — first-fold cap with league + JUGAR.
- League decorative tips are small squares more than 3D diamonds.

---

Reviewed: 2026-08-25 (hub mockup loop tick 9)
Slice: street hub `#street_world` vs `mockup-street-hub-temple-ui.png` — current hero thumb, solid 4-point star, braided rope
Tests: `PARALLEL_WORKERS=1 bin/rails test test/system/street_quiz_visual_test.rb --name "/hub league strip|hub map and jugar/"` — 2 runs, 44 assertions, 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no new strings)

## Hub mockup loop (tick 9)

Tick 3 matched composition (locked / current / done + league + JUGAR above the dock). This tick is metal weight only — no fake Andrés / 7850 XP; mute + flag stay.

| Change | Before | After |
|---|---|---|
| Current pack thumb | `5.5rem` square | `8rem` square hero (locked/done `2.85rem`) |
| Star pointer | `2.65rem` clip-path, gold-leaf wash (faint on marble) | `3.5rem` solid 4-point `star4` picto, `#8a6410` metal + tight rim shadow, glued left of the current still |
| Rope | `20px` diagonal stripe | `2.25rem` (~36px) gold cylinder with visible braid grooves (gold core); track gap `--space-4` so the cord reads between nodes |

First fold on 390×844: 3 nodes + league + JUGAR still above the dock (`assert_above_hub_dock`). XP / avatars / pack stills stay live fixture data.

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`

### Remaining gaps vs mockup

- XP / league use fixture Pili / Carmen, not mockup Andrés / 7,850 / María….
- Mute + flag stay on hub (UI soul); mockup hides them.
- Guest path is still 2 nodes — `hub-guest-phone`.
- Pack stills are catalog adventure art, not mockup Desierto Dorado.

---

Reviewed: 2026-08-25 (hub mockup loop iteration 1)
Slice: street hub `#street_world` vs `mockup-street-hub-temple-ui.png` — recreate layout, not a skin
Tests: `PARALLEL_WORKERS=1 bin/rails test test/controllers/street_hub_controller_test.rb test/system/street_quiz_visual_test.rb` — 19 runs, 198 assertions, 0 failures; hub re-run 3/74 after hex CTA
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: `street.league_named` — es Liga %{rank} / pt-BR Liga %{rank} / en %{rank} league / fr Ligue %{rank}

## Hub mockup loop (iteration 1)

Recreate the mockup column on `/`: hall with columns at the 9:16 edges, WORLD HUB between gold rules, player card (compass, gold rank banner, 12-point level star + XP), 3-node rope (locked above / current XL + 4-point star + CORONAS / finished below), MAPA DE VIAJE card, LIGA strip, hexagonal JUGAR, 5-tab dock.

| Mockup | This tick |
|---|---|
| Hall columns L/R + oculus | **yes** — `marble-hall.jpg` on `.sky` (`cover`). Not force-regenerated; columns already at phone edges. |
| Rounded-square gear + trophy | **yes** |
| WORLD HUB between gold lines + diamonds | **yes** — ink words, gold metal rules |
| Avatar compass, gold rank banner, 12-point star + XP row, RACHA | **yes** (signed-in). Guest still “Elige ficha”. |
| Locked above, current XL + star pointer, finished below | **yes** — DOM order + `1fr auto 1fr` thumbs on the rope |
| MAPA DE VIAJE card + compass | **yes** |
| LIGA + diamond 1/2/3, crowns, top 3 | **yes** — `league_named` with rank title |
| Wide gold JUGAR, hexagonal ends, 4-point stars | **yes** |
| 5-tab dock, HUB gold/active | **yes** — compass / shop / podium |
| Mute off the JUGAR bar | **yes** — chrome-tools under trophy |

Hall plate not force-regenerated this tick.

noche-i18n: PASS — league title interpolates the live rank (es Liga Guerrero / pt-BR Liga / en Guerrero league / fr Ligue). WORLD HUB stays the brand kicker in all four.

## Remaining pixel gaps vs mockup

- Mute + flag still sit under the trophy (UI soul). Mockup hides them.
- Braided rope is easy to miss behind the thumbs; it shows in the gutters, not as a free-standing cord.
- Current thumb is 5.5rem (XL vs locked/done, not mockup-scale square) so 3 nodes + league still fit above JUGAR.
- XP is live rank math (`95 / 110`), not mockup `7,850 / 10,000`.
- Avatars are fichas (turtle / dolphin), not the mockup explorer painting.
- Pack stills are catalog adventure art, not mockup Desierto Dorado / Selva Escondida.
- League names/scores are ward fixtures (Carmen / Pili), not María G. / Santiago R. / Valeria T.
- Guest path (`hub-guest-phone`) is 2 nodes and has no league — honest empty ficha.
- Gear icon reads closer to a sunburst than a mechanical cog.

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png` (signed-in canonical), `hub-league-phone.png`, `hub-desktop.png`, `hub-guest-phone.png`.

---

Reviewed: 2026-08-25 (hub first-fold tick 6)
Slice: street hub first fold vs `mockup-street-hub-temple-ui.png`
Tests: `PARALLEL_WORKERS=1 bin/rails test test/system/street_quiz_visual_test.rb --name "/hub league strip|hub map and jugar/"` — 2 runs, 40 assertions, 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no new strings)

## Hub first fold (tick 6)

Tick 3 (`32507915`) had just landed composition + the visual-test filename fix. CSS/ERB were not mid-edit by regen time, and first fold already matched the mockup column, so this tick **skipped code**.

Canonical `hub-phone.png` is the signed-in 3-node + league shot (guest stays on `hub-guest-phone`). Guest test runs first in this filter; signed-in test writes `hub-phone` last.

| Mockup element | Status |
|---|---|
| 3-node locked → current XL → done | **yes** |
| XL current + left star + CORONAS | **yes** |
| League title + 3 columns above dock | **yes** — `LIGA GUERRERO` |
| Marble columns in hall plate | **yes** |
| Wide gold JUGAR + 5-tab dock | **yes** |
| `hub-phone` = signed-in (not guest overwrite) | **yes** this regen |

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`, `hub-league-phone.png`, `hub-guest-phone.png`, `hub-desktop.png`.

### Remaining gaps vs mockup

- Current thumb is 5.5rem (readable XL vs locked/done, not mockup-scale square).
- Star pointer is a faint 4-point in the left gutter, not a solid metal star glued to the still.
- Rope reads as a thin gold line vs mockup braid thickness.
- Guest path is still 2 nodes — `hub-guest-phone`.
- XP / league use fixture Pili / Carmen, not mockup Andrés / 7,850 / María….
- Mute + flag stay on hub (UI soul); mockup hides them.

---

Reviewed: 2026-08-25 (hub first-fold tick 3)
Slice: street hub first fold vs `mockup-street-hub-temple-ui.png`
Tests: `PARALLEL_WORKERS=1 bin/rails test test/controllers/street_hub_controller_test.rb` (8 runs) + hub visual tests (signed-in + guest). 0 failures.
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no new strings)

## Hub first fold (tick 3)

`hub-phone.png` was the guest shot (2 nodes, no league), so it could not match the mockup column. Pack thumbs also sat in a padded row left of the rope, and mute/lang sat on JUGAR / PERFIL.

| Change | Why |
|---|---|
| Rope nodes `1fr auto 1fr` | Thumbs sit on the braided rope; star pointer in the left gutter; labels to the right |
| Mute/lang `inset` under the trophy row | Chrome tools stay off the dock (mockup has a clean 5-tab bar) |
| Rounded wide JUGAR (no hex clip) | Mockup + noche-ui: gold bar, not hex |
| `hub-phone` from signed-in 3-node + 3-slot league | Canonical first-fold shot matches mockup composition |
| Guest remains `hub-guest-phone` | Honest new-player path is still 2 nodes, no league |

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`

### Remaining gaps vs mockup

- Guest path is still 2 nodes (no finished pack) — `hub-guest-phone`.
- XP uses real rank thresholds, not mockup `7,850 / 10,000`.
- Mute + flag stay on hub (UI soul); mockup hides them.
- League names/scores are fixture data, not mockup María / Santiago / Valeria.

---

Reviewed: 2026-08-25 (hub first-fold tick)
Slice: street hub first fold — locked pack + league above dock on 390×844
Tests: `PARALLEL_WORKERS=1 bin/rails test test/system/street_quiz_visual_test.rb` — 11 runs, 104 assertions, 0 failures
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: N/A (no new strings)

## Hub first fold (this tick)

Locked pack and league sat under the JUGAR + 5-tab dock until you scrolled. First fold on phone now matches the mockup column: player card, 3-node rope, league strip (signed-in), wide JUGAR, dock — without scrolling.

| Change | Why |
|---|---|
| `#street_world` `--street-hub-dock-clearance` (~10.25rem + safe area) | Map/league clear the fixed dock when you do scroll |
| Tighter hub gap, brand, player card, map header, pack thumbs | 3 nodes + league fit above the dock |
| Rope nodes are horizontal (thumb + meta); current thumb 5.25rem | Stacked locked/finished nodes were pushing the fold |
| Friend invite rail hidden on hub | Mockup has no rail on the first screen; invite is an icon on the player card + Amigos tab |
| Visual asserts `assert_above_hub_dock` for 3 nodes + league | Signed-in `hub-league-phone`; guest `hub-phone` (2 nodes, no league) |

Hall plate not regenerated in this tick.

---

Reviewed: 2026-08-25 (hall plate regen — credits restored)
Slice: force-regenerate hub marble hall JPG after OpenRouter 402
Tests: not run (script + media only; hub CSS untouched)
Gate: `.cursor/skills/noche-ui/SKILL.md`

OpenRouter key OK (`GET /api/v1/key` 200; ~$32 remaining). `ruby script/generate_temple_ui.rb --force` wrote `public/media/temple/marble-hall.jpg` (600KB, 1024×1824, flux.2-flex). Prompt matches mockup `tmp/street-shots/temple-mockups/mockup-street-hub-temple-ui.png`: SLC celestial hall, fluted ivory columns + gold capitals, oculus, arched windows, depth, no UI/text/logos. No 402 this run. `temple_hall_bg_src` still prefers `/media/temple/marble-hall.jpg`. Quiz stills `--all --force` already running (pid 20407, ttys010) — not stalled; log `tmp/generate_quiz_media.log` is behind (buffered from an earlier 402). Story stills 22/22, not re-run.

---

Reviewed: 2026-08-25 (hub scene tick)
Slice: mockup-faithful street hub scene (not a cream-card skin)
Tests: `bin/rails test` — 485 runs, 0 failures; coverage 94.47%. Hub visual shots refreshed.
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: `street.pack_coming_soon`, `street.card_xp` — es, pt-BR, en, fr

## Hub scene redesign (this tick)

Recreate `tmp/street-shots/temple-mockups/mockup-street-hub-temple-ui.png` as the `/` scene.

| Mockup element | Status |
|---|---|
| Immersive marble hall (columns, oculus) as the canvas | **yes** — `#street_world` / `.sky` uses `--temple-hall-bg` (`marble-hall.jpg`); cream column overlays removed. Hall plate force-regen succeeded 2026-08-25 after credits restored (prior `--force` hit 402). |
| 3-node path on braided gold rope | **yes** — `Quizzes::World.path` (finished / current / locked). Cards sit on the rope. |
| Current XL hero + gold glow + side star + CORONAS ribbon | **yes** |
| Locked padlock + “próximamente” | **yes** — `pack_coming_soon` |
| Completed check overlay | **yes** |
| Wide gold JUGAR bar (not hex) | **yes** — `world_play` / `world_continue` |
| Horizontal LIGA strip top 3 → `/liga` | **yes** — never dumps all rows |
| Player card: avatar ring, rank, XP `current / next`, racha | **yes** |
| Sticky header + WORLD HUB pill | **yes** (kept) |
| 5-tab dock | **yes** — Hub · Tienda · Ranking · Amigos · Perfil |

noche-i18n: PASS — es Próximamente / pt-BR Em breve / en Coming soon / fr Prochainement; XP is digits; FR `league_see_all` grammar fix (le classement).

## Remaining gaps vs mockup

- Hall plate regenerated 2026-08-25 (`marble-hall.jpg`, mockup-faithful empty aisle).
- First fold: locked pack + league sit above the dock (this tick). Friend rail is hidden on hub; player invite stays on the card.
- Player invite link stays on the card (product keep; mockup hides it).
- XP uses real rank thresholds (e.g. `95 / 110`), not mockup `7,850 / 10,000`.
- New-player path is 2 nodes (no completed pack yet).

Screenshots: `tmp/street-shots/temple-themed/hub-phone.png`, `hub-desktop.png`.

---

Reviewed: 2026-08-25 (tick 5)
Slice: visual parity vs temple mockups — street hub/jugar/ceremony (night live untouched)
Tests: `bin/rails test` — 484 runs, 0 failures; coverage 94.54%
Gate: `.cursor/skills/noche-ui/SKILL.md`
Copy: `street.ceremony_score_label`, `street.shot_rival_gap` — es, pt-BR, en, fr

## Gap matrix

| Screen | Gap | Priority | Fixed? |
|---|---|---|---|
| Hub phone/desktop | Full marble-column interior photo (mockup) vs CSS oculus/columns | P2 | partial — `temple-marble-hall.svg` + column scrim |
| Hub phone | Locked pack + league under dock on first fold | P0 | **yes** this tick — 3 nodes + league above JUGAR |
| Hub phone | League panel below fold on guest profile gate | P3 | yes — `hub-league-phone` signed-in shot |
| Hub | XP bar only when ficha signed in (mockup always shows) | P3 | no — by design |
| Hub dock | 4 tabs vs mockup 5 (no TIENDA) | P3 | no — TIENDA `is-soon` stub ships |
| Jugar ask | Outer gold arch frame on still + apex arch | P0 | **yes** tick 2 |
| Jugar ask | Celestial level rail — star bookends, glow pill, dot halo | P0 | **yes** tick 2 |
| Jugar ask | Rival chip prominence (mockup Carmen +5) | P1 | **yes** tick 5 — shot overlay + gap pill |
| Jugar ask | NOCHE LIVE logo header on reel | P3 | no — reel has no brand lockup |
| Ceremony phone/desktop | Gold arch victory frame (3-star crown) | P0 | **yes** tick 2 |
| Ceremony | Chest light burst / particles | P1 | **yes** tick 2 (CSS glow) |
| Ceremony | Marble temple interior backdrop | P2 | **yes** tick 5 — column scrim + immersive hall |
| Ceremony | Marble pedestal boards with ward temple icons | P2 | partial — `.street-board` chrome |
| Ceremony | Score label "Puntaje total" above hero | P1 | **yes** tick 5 |
| Night play | Arched marble sheet + star ticks | P1 | yes (prior slice) |
| Night watch | Gold hairline on scoreboard emblems | P1 | **yes** tick 2 |
| Night presenter | Marble desk + gold ticks | P1 | yes (prior slice) |
| Night join | Arched sheet + apex star | P1 | yes (prior slice) |
| Media stills | `chapel_world.yml` / adventure stills not regenerated | P2 | no — OpenRouter not run |

## Tick 5 fixes

- **Hub**: league strip + XP visible in signed-in visual test; guest hub shot `hub-guest-phone`; brand lockup + 5-tab dock (TIENDA soon).
- **Jugar**: rival chip on `play-shot` overlay (avatar, name, `+N pts` pill); total gap fallback when no pack gap.
- **Ceremony**: `street.ceremony_score_label` in template; `street-ceremony-column-scrim` (oculus + column hints); immersive mode hides pack still.
- **Tests**: fixture quiz runs for leaderboard; `sign_in_fixture_person!` + cookie reset; `hub-league-phone`, `01-ask-rival-phone`, ceremony scrim assertions.

## Tick 2 fixes (retained)

- **Jugar**: thicker gold arch on `play-shot` + apex arch glow; celestial level rail in marble pill with star halos and dot pulse.
- **Ceremony**: triple-star arch crown, stronger victory arch border, chest radial glow on star phase.
- **Night watch**: gold border + glow on scoreboard emblems.

## Screenshots (tick 5)

Street: `tmp/street-shots/temple-themed/` — hub-guest-phone, hub-league-phone, hub-desktop, 01-ask-rival-phone, 01-ask-phone/desktop, ceremony-phone, jugar-ceremony-desktop, rank-up-phone, duel-banner-phone, share-card-phone, wizard-phone, hub-pack-unlock-phone, 07-four-bars-settled.

Mockups: `tmp/street-shots/temple-mockups/` — mockup-street-hub-temple-ui, mockup-street-jugar-temple-adventure, mockup-street-ceremony-temple-victory.

## Iteration 6 priorities

1. **P2** — Hub map path: center-column rope layout closer to mockup (packs on vertical spine vs zigzag).
2. **P2** — Ceremony ward boards: temple icon per row on `.street-board`.
3. **P2** — Run `script/generate_quiz_media.rb` when `OPENROUTER_API_KEY` set (adventure stills + chapel_world).
4. **P3** — Jugar reel brand lockup under oculus (subtle ink) — optional parity with mockup header.
5. **P3** — Night play outer gold arch (separate night loop).

## Verdict

PASS WITH NOTES — tick 5 closes hub league/rival/ceremony-scrim gaps; photo-real marble interiors and media regen remain iteration 6.

# M166 — Salt Lake Temple Celestial Light

Reviewed: 2026-08-31
Slice: artwork-authored Light world for the Hub Hero
Tests: `bundle exec rails test test/services/hubs/backdrop_test.rb test/services/hubs/screen_test.rb test/system/hub_streaming_rails_visual_test.rb` — 29 runs, 1235 assertions, 0 failures; `bundle exec rails media:build_responsive` — 527 assets, 5067 variants
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — no quiz or live-night rules changed
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no player-facing wording changed

## Feeling

Salt Lake City should feel like the same sacred destination at a new narrative hour: Dark is solemn moonlight; Light is hopeful sunrise.

## 1 — Game experience

The current Light chapter now enters a visually distinct Salt Lake world instead of falling back to the unrelated Jerusalem scene. Salt Lake is also the explicit Celestial Light fallback when a chapter, such as “La vie du Sauveur”, has no more specific Light artwork. The chapter, progress and Play loop are unchanged.

## 2 — UI design

Landscape composition reserves the left field for navy title glass and the right field for the full temple. Portrait composition reserves the lower-left temple and right-side explorer while keeping HUD-safe sky above. Existing cockpit spacing and dots-only voyage control remain intact.

## 3 — Art direction

Two curated masters were generated from the approved night compositions: a 1672×941 temple landscape and a 941×1672 explorer portrait. Powder-blue sky, ivory stone, champagne sunrise, gardens and subtle haze establish Celestial Light without whitening the whole UI.

## Theme engine

`salt-lake-temple-dawn` is an explicit Light manifest world with separate backdrop and Hero assets. `salt-lake-temple-night` remains the Dark counterpart. The same Hub markup selects either world deterministically from the active chapter's mode and tags.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.9 |
| Clarté | 9.7 |
| Impact visuel | 9.8 |
| Feedback | 9.2 |
| Progression | 9.4 |
| Social | 9.0 |
| Immersion | 9.8 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.8 |
| Envie de continuer | 9.5 |

## Verdict

PASS

## What works

- Salt Lake is unmistakable in Light and Dark.
- Moroni and the major spires remain visible below the unchanged HUD.
- Desktop keeps low-detail copy space; mobile keeps the explorer-led mockup composition.
- AVIF, WebP and JPEG variants are generated for every authored rendition.
- The theme choice is explicit in the manifest rather than inferred from image brightness.

## What feels weak

- The retired Jerusalem Light scene remains in the catalog as a reusable world, but no longer wins the active `coronas` Light match.

## Required before approval

- None.

## Evidence

- Celestial Light inspected at 390×844, 768×1024 and 1440×900.
- Celestial Dark regression inspected at the same Hero contract.
- Backdrop selection, resumable Light question, responsive media and full Hub visual matrix pass.
- Console clean; no horizontal overflow; HUD anatomy unchanged.

## Night director

Yes. The player now enters Salt Lake at sunrise in Light and returns to the same sacred destination under moonlight in Dark.

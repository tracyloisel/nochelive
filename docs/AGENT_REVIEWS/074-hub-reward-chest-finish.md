# 074 — Hub reward chest completion

Reviewed: 2026-08-27
Slice: hub `/` Continuer l’aventure reward capsule, transparent 3D chest, and honest live +N
Tests: hierarchy correction 4 focused runs, 239 assertions, 0 failures; browser system check included at 390 × 844
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — existing `hub.reward` remains native in es, pt-BR, en, fr

## Feeling

Anticipation and accomplishment: the player sees a tangible treasure still available in this pack, not a decorative badge or fabricated demo score.

## 1 — Game experience

The promise shrinks with actual progress. After the first settled question, the control renders the remaining curve rather than the original total. **Jouer** remains the single action; the reward capsule supports the next want without competing with it.

## 2 — UI design

The mockup anatomy is preserved: ivory pill, chest left, small tan/gold uppercase label, live +N and crown. The hierarchy correction centers unequal controls rather than stretching them: at 390 × 844, **Jouer** is about 130 × 46 CSS pixels while Récompense is 120 × 39 (86% of the CTA height) and its chest is about 43 × 32. Idle is visible for a positive remainder; zero remains hidden. Light and Dark share the same markup and dimensions.

## 3 — Art direction

The shipped `public/media/temple/reward-chest.png` is a genuine RGBA knockout: warm walnut, polished brass bands and latch, soft dimensional light. Gold reads as metal. The ivory prize ticket remains coherent over Celestial Light and Celestial Dark rather than becoming a flat black social chip.

## Theme engine (hub `/`)

Same Home and semantic tokens. Browser verification kept the ivory reward surface and metallic gold hierarchy under both Light and Dark theme selectors; no user toggle or duplicated component was added.

## Four seats

Street hub: who / where / what now / around me. Live-night seats are N/A.

## Tension

The live remainder decreases as questions settle, making the unopened value legible and preserving the stronger final questions in the promise.

## Finale

Unchanged.

## Languages

`hub.reward` remains Recompensa / Recompensa / Reward / Récompense. CSS supplies caps; no new copy was introduced. noche-i18n: PASS.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- The rendered number is proven against a settled run, so `+150` is never painted as static mockup data.
- The chest keeps transparent edges and dimensional brass/wood material at phone size.
- The capsule is a reward promise while **Jouer** remains the obvious verb.

## What feels weak

- The small-caps label is intentionally quiet; the live +N remains the accessible information-bearing line.

## Required before approval

- None for this slice.

## Evidence

- Browser: 390 × 844, live value `+103`; Jouer 129.6 × 45.6, Récompense 120 × 39.2, chest 43.2 × 32 CSS pixels.
- Dark live render and Light-token preview: identical proportions; ivory surface remains `rgb(255, 253, 249)`.
- Screenshot: `tmp/street-shots/temple-themed/hub-phone.png`.
- Full suite reached 94.96% line coverage but is currently red from parallel workspace changes outside this slice: 9 `street_leaderboards`/ward-pick errors around `street_digest`, one leaderboard selection failure, and two platform-stat count failures.

## Night director

Would I tap another round? Yes: the chest is desirable, the remaining value is truthful, and the next action is still immediate.

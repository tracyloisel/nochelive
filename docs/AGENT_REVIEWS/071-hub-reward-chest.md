# 071 — Hub continue-card Récompense chest

Reviewed: 2026-08-27
Slice: hub `/` Continuer l’aventure reward control matches the ivory prize capsule (3D chest, RÉCOMPENSE, live +N crown)
Tests: `bin/rails test test/controllers/street_hub_controller_test.rb test/helpers/application_helper_test.rb test/services/hubs/screen_test.rb test/i18n/locale_files_test.rb`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated (no new keys)

## Feeling

Anticipation + prize. The pack still has a chest to open. Not “see remaining XP in a chip.”

## 1 — Game experience

Street loop: see the world → want the next step → tap Jouer. The capsule is the remaining curve (`Hubs::Screen` `hero.reward`), never a painted +150. A pack already in progress shows the honest leftover. Dead admin: none — the control is not tappable; Jouer is still the one gold verb.

## 2 — UI design

2-second verb stays gold **Jouer**. The prize is a ticket beside it: ivory pill, 3D chest left, kicker + live +N crown right. Same markup in Light and Dark. States: idle (remaining > 0), hidden (0 remaining). Tokens: `--hub-reward-paper` (temple ivory on both families), `--gold-deep` kicker, `--gold-primary` metal value. Uppercase via CSS on `t("hub.reward")`.

## 3 — Art direction

Emotion: this is loot, not a badge. Composition: closed wooden chest, brass bands, circular latch, slight 3/4. Asset: `public/media/temple/reward-chest.png` (OpenRouter flux.2-flex, knockout to alpha). Gold is metal on the object and the +N, not a cream headline. Ivory pill stays a prize ticket in Dark (same as the live card paper).

## Theme engine (hub `/`)

Same Home. Tokens only. No forked markup, no user toggle. Scenes A/B/C still one Hub.

## Four seats

Street — who / where / what now / around me. N/A live night.

| Seat | Verb tonight |
|---|---|
| Host | N/A |
| Chapel (controller) | N/A |
| Remote | N/A |
| TV / Twitch | N/A |

## Tension

Remaining points shrink as the pack is answered. The chest is a promise of the rest of the curve, including the 25-point last ask.

## Finale

Unchanged.

## Languages

Existing `hub.reward`: es Recompensa / pt-BR Recompensa / en Reward / fr Récompense. Uppercase is CSS. noche-i18n: PASS.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 8 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- Live remaining curve points, not a fake 150.
- 3D chest on an ivory prize ticket instead of a flat SVG chip.

## What feels weak

- Camera on the generated chest is still a hair above true eye-level vs the mockup crop.
- Crown picto is the product crown (gold-filled), not a custom three-point gradient glyph.

## Required before approval

- None.

## Evidence (optional)

OpenRouter still via `script/generate_temple_ui.rb` (`reward-chest.png`).

## Night director

Would I tap Jouer to open that chest? Yes — the prize reads as an object now.

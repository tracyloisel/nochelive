# M64 — Hub continue card as cinematic overlay

Reviewed: 2026-08-27
Slice: street hub `/` continue-the-adventure hero matches the Dark (and Light) mockup card — still as world, copy on the painting, gold Jouer, reward chest
Tests: `bin/rails test test/services/hubs/screen_test.rb test/controllers/street_hub_controller_test.rb test/i18n/locale_files_test.rb test/integration/ui_chrome_test.rb` — 53 runs, 1853 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Wonder + anticipation. The painting is the door. Jouer is the gold verb. The chest says the pack still has a prize. Not “open the quiz CMS.”

## 1 — Game experience

Street loop: see the world → want the next step → tap Jouer → pack ask. Voyage stills remain a swipe of previous / current / next so the path is visible, but Jouer on the current card stays the one gold verb (locked next is “Suivant”, not a second gold). Reward is remaining curve points, not a fake +150. Info still opens `/mapa`.

## 2 — UI design

2-second verb: gold **Jouer** on the hero. Anatomy from `mockup-street-hub-celestial-dark.png` / Light twin: gold kicker Continuer, serif quiz title (pack kicker), étape pill + pack name, lede, Jouer, Récompense +N crown, (i) to the map, dots under the card. Title is ink (Light) / cream (Dark) — not gold on cream or on the beam. Same markup both families.

States: idle (current pack), pressed/launch (hub-play), locked next (lock + voyage_next, no gold), finished previous (replay Jouer).

## 3 — Art direction

Emotion: walk into the still. Composition: subject on the right, local left scrim, gold hairline card. Light = frost over the temple; Dark = cinematic night + volumetric gold. No stacked gold headlines. Décor tells the story.

## Theme engine (hub `/`)

Same Home. Tokens only (`--text-primary`, `--border-gold`, `--button-primary`, overlays). No forked markup, no user toggle. Scenes A/B/C still one Hub.

## Four seats

Street — who / where / what now / around me. N/A live night.

| Seat | Verb tonight |
|---|---|
| Host | N/A |
| Chapel (controller) | N/A |
| Remote | N/A |
| TV / Twitch | N/A |

## Tension

Street pack: étape n/total on the card, chest of remaining points. Next locked slide teases without letting them cheat the path.

## Finale

Unchanged.

## Languages

es Continuar la aventura / pt-BR Continuar a aventura / en Continue the adventure / fr Continuer l’aventure. Reward / step / Jouer already in four locales. noche-i18n: PASS.

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
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- The still is the card. Copy no longer sits in a dark tray under a cropped strip.
- Pack kicker is the shouted title (Quiz de Moïse / Quiz real); pack name sits beside the étape pill.
- Live step, lede, remaining points. Mockup copy not faked.

## What feels weak

- Voyage is still three slides (honest path), not the mockup’s four demo dots.
- Chest is the picto, not a 3D render.

## Required before approval

- None. Browser pass vs Dark mockup; keep live scores.

## Evidence (optional)

—

## Night director

Would I tap Jouer? Yes — the painting is asking.

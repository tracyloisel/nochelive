# 073 — Hub Notre communauté tile

Reviewed: 2026-08-27
Slice: hub `/` `.hub-community` restyle to Celestial Light and Dark mockups (3 cols, gold/ink icons, live Pulse, two-line labels). Pulse math unchanged.
Tests: `bin/rails test test/controllers/street_hub_controller_test.rb test/i18n/locale_files_test.rb`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Belonging. This is *our* house tonight — people, questions, ramas — not a stats widget. The gold radio says someone is here now.

## 1 — Game experience

Loop: glance the house → see live count → feel the month (players / questions / ramas) → tap `/cifras` if curious. No admin. Pulse numbers stay real (`Platform::Pulse` + listed wards). Dead screen killed: overlapping labels, cartoon pictos, fake 12 / 360 / 5.

## 2 — UI design

Same ERB. Tokens from `data-hub-theme` on `#street_world`. 2-second read: kicker + live line + three columns. States: idle (numbers), live (gold radio + `street.pulse_live`), pressed (pulse link to cifras). Labels wrap two lines, `--type-min` 14px, `--space-2` (8px) column gap. Light: grey icons, serif charcoal numbers, small-caps labels, faint column rules. Dark: gold icons, cream numbers, muted labels, gold hairline card.

## 3 — Art direction

Emotion: chapel family, not a dashboard. Gold = metal (kicker, radio, Dark icons, border) — never gold headlines on Light cream. Temple glyph is pillars (Dark) / meetinghouse steeple (Light); no crucifix (ADR-009). Glyphs rasterized from `script/community_icons/` (Flux filled the chroma frame).

## Theme engine (hub `/`)

Same Home. `--surface-primary`, `--text-primary`, `--text-muted`, `--gold-primary`, `--ink`, `--font-display`. No user toggle, no forked markup. Scenes A/B/C still one Hub.

## Four seats

Street hub — who / where / what now / **around me**. Community is the house heartbeat, not a live seat.

| Seat | Verb tonight |
|---|---|
| Host | N/A |
| Chapel (controller) | N/A |
| Remote | N/A |
| TV / Twitch | N/A |

## Tension

The live count can tick while you stay on `/`. The month numbers are pride, not a chase.

## Finale

N/A street.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**. Two-line keys added; full-sentence keys remain for aria. Spanish source: Jugadores / este mes, Preguntas / respondidas, Ramas / participan. pt-BR Alas (not ramo). FR Paroisses / participent (Light mockup). EN Wards / playing.

noche-i18n: PASS
es native chapel · pt-BR Alas participam · fr participent · en playing (not “wards taking part”)

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 8 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- Live Pulse stays; cifras link still the door.
- Light and Dark share one tile; gold stays metal.

## What feels weak

- Icons are flat glyphs, not painted metal. Sharp at 28px; not a treasure still.

## Required before approval

- None.

## Night director

Would I feel less alone on the hub? Yes — someone is online, and the house has a count.

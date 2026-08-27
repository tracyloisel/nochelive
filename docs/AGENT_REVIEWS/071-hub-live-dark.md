# 071 — Hub next Noche Live card: Celestial Dark twin

Reviewed: 2026-08-27
Slice: follow-up to 069. The next-LIVE card family follows **its still**, not a user toggle and not the hub world when the images disagree. Reyes y Profetas uses the tagged dark backdrop (`coronas-ungido` / David anointed); Light stills keep the ivory ticket. The still manifest now passes both mode and atmosphere to the card.
Tests: targeted Light/Dark scenarios — 19 runs, 135 assertions, 0 failures
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — N/A (no new copy)

## Feeling

Saturday is coming — and the ticket matches the night. A stormy Reyes still is a night-glass invitation, not an ivory flyer glued onto Sinai. Belonging + anticipation, not “open the CMS.”

## 1 — Game experience

Loop: see the next live → feel the wait (honest hours) → tap **Voir le programme** (`/noches`) or gold **Entrer** if playing. Same loop as 069. What was dead: a Light paper ticket on a Dark still (the previous slice forced `--hub-live-paper: temple-ivory`). Tension is still the real `starts_at`. Reward is walking into the program already inside the night’s atmosphere.

## 2 — UI design

2-second verb unchanged: program (gold hairline, calendar) on the photo; gold fill stays **Jouer** on the hero (Entrer only when `playing`). Same anatomy. Theme via `data-hub-live-theme="light|dark"` and `data-hub-live-atmosphere` from the still manifest — not `prefers-color-scheme`, not a user toggle, not the hub world’s `data-hub-theme` when the card still disagrees. The same component consumes local semantic tokens for surface, ink, wash, digits, border, shadow and program CTA.

Light: ivory left 90° wash, ink type, white digit boxes, ivory program, gold-deep metal.
Dark: night-glass 90° wash, cream type, dark glass digits with cream numerals, glass program + gold hairline + gold calendar. LIVE pill stays red. States: none (compact Light empty), scheduled/soon/imminent, playing.

## 3 — Art direction

Décor tells the story. Reyes y Profetas → `ungio_david.jpg` (quiz still `mode: dark`) + night wash. Chapel `worship.jpg` remains the Light fallback / Light-tagged still. Gold = metal. No flat black social skin. No gold headlines on cream.

## Theme engine (hub `/`)

Same Home. Nested family on `.hub-live` from the **card still** (`Hubs::Backdrop.tagged` + `Quizzes::Chrome.mode_for`). Hub world can stay Dark (pack still) while the live card is Light (chapel still), and the inverse. When the card has no still of its own (`ward_missing` or no scheduled night), it inherits mode + atmosphere from the actual hub backdrop instead of forcing Light. `dramatic`, `solemn`, `peaceful` and `glorious` refine the local glow without duplicating markup. Scenes A/B/C still one Hub.

## Four seats

Street hub — who / where / what now / around me. The card is the “around me” live door.

| Seat | Verb tonight |
|---|---|
| Host | N/A |
| Chapel (controller) | N/A |
| Remote | N/A |
| TV / Twitch | N/A |

## Tension

Unchanged: real hours, no fake `09`.

## Finale

Unchanged.

## Languages

N/A — existing `hub.*` keys. noche-i18n: PASS (no new strings).

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Mode is chosen from the still: tagged hub backdrop for the night theme, then `Quizzes::Chrome.mode_for` on that image, else chapel Light.
- Dark twin is the same ticket: cream on night glass, volumetric gold, not a TikTok skin.

## What feels weak

- Empty card (no night) stays Light paper with no still — honest, a little quiet.

## Required before approval

- None.

## Night director

Would I tap the program? Yes — the hall (or the anointing night) is already on the ticket.

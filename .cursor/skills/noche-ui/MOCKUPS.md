# Temple mockups — the spec

These PNGs **are** the product. Open the matching file before editing CSS/ERB. A working screen that does not match its mockup is unfinished.

Street stills: biblical adventure (peril + grace) per `config/media/street_world.yml`. Night stills: meetinghouse light per `config/media/chapel_world.yml` — never a Christus / celestial-room set. The Solomon painting in the night mockups is **round media**, not UI chrome.

## Catalog

| Surface | Mockup | Shot to compare |
|---|---|---|
| Street hub `/` | `tmp/street-shots/temple-mockups/mockup-street-hub-temple-ui.png` | `tmp/street-shots/temple-themed/hub-phone.png` |
| Street arrival (first visit) | hall `marble-hall.jpg` + ivory search sheet | `tmp/street-shots/temple-themed/wizard-phone.png` |
| Street jugar ask | `tmp/street-shots/temple-mockups/mockup-street-jugar-temple-adventure.png` | `tmp/street-shots/temple-themed/01-ask-phone.png` |
| Street pack ceremony | `tmp/street-shots/temple-mockups/mockup-street-ceremony-temple-victory.png` | `tmp/street-shots/temple-themed/jugar-ceremony-desktop.png` |
| Presenter stage | `tmp/night-shots/temple-mockups/mockup-night-presenter-temple.png` | `tmp/night-shots/temple-themed/presenter-stage.png` |
| TV /watch 16:9 | `tmp/night-shots/temple-mockups/mockup-night-watch-temple.png` | `tmp/night-shots/temple-themed/watch-board.png` |
| Casa QCM | `tmp/night-shots/temple-mockups/mockup-night-casa-quiz-temple.png` | `tmp/night-shots/temple-themed/play-quiz-ask.png` (+ `play-quiz-casa` when the test exists) |
| Sala Buzz | `tmp/night-shots/temple-mockups/mockup-night-sala-buzz-temple.png` | `tmp/night-shots/temple-themed/play-buzz-open.png` |

Same night, same still: *La elección de Salomón*. Four seats, four verbs, one painting.

## Painting vs product KEEP

Ship the chrome. Do **not** fake the painting’s demo data or violate a hard don’t to “look more like the PNG.”

| Mockup may show | Product keeps |
|---|---|
| Gold “NOCHE LIVE” letters on cream | **Ink** lockup. Gold = metal only |
| People / trophy icon top-right on jugar | Same chrome as the hub: avatar left, hamburger right. Mute + language live **in the drawer** |
| Hub chrome stacked (mute, flag, trophy, WORLD HUB) | Avatar left, hamburger right. Mute + language + ranking live **in the drawer**. Ink lockup is **Noche Live** only |
| Andrés / 7,850 XP / María G. | Live ficha, rank math, league fixtures |
| Watch scores 10 / 6 / 4, “Las Hermanas” | Live `cached_score` + real team names (wrap, no ellipsis) |
| Presenter desk covering half the still | Desk **peek** so Solomon’s face still reads; full desk is a summon |
| Casa without a drag pip | No grab-handle on ask if the sheet is not a drag dock |
| Literal temple interior as UI | Chrome is marble tokens; stills follow chapel/street YAML |

## Anatomy — street hub

Marble hall is the canvas (columns at 9:16 edges, oculus). No reel, no ticks.

1. Ink lockup **Noche Live**. Avatar left, hamburger right. Mute, language, and ranking live in the ivory drawer.
2. Player card: avatar ring, gold rank banner, 12-point level star, XP `current / next`, racha.
3. **3-node rope**: locked padlock above / current XL hero + CORONAS + 4-point star pointer / finished check below. Brown-gold **braided helix between** nodes.
4. MAPA DE VIAJE card. Horizontal LIGA top 3 → `/liga`.
5. Wide gold **Jugar** bar (pointed / hex metal, star flanks). Ranking, history, and play live in the hamburger; profile is the avatar. **No 5-tab dock.**

First fold on 390×844: 3 nodes + league + Jugar above the CTA.

Desktop is the same hub composition on the hall, column **grows** (not a stretched glass stack, chrome never at the window edges). iPad 36rem / desktop 44rem / XL 52rem. Locked padlock sits **above** the node; finished check sits **below**. MAPA title has no trailing star (it reads as a plus). Readable type never drops below `--type-min` (14px).

## Anatomy — street jugar ask

Three bands, gold-trimmed phone arch.

1. **Cream head**: ink Noche Live + LIVE hairlines + vaulted gold arcs + **level rail** (10 dots, star bookends). Avatar left, hamburger right. Mute + language live in the ivory drawer. No story ticks, no X.
2. **Still**: rounded adventure painting. Rival chip top-left (avatar, cream name, gold `+N pts`). Score star pill top-right. Settled: navy **Leer 1 Samuel 16:13** pill + compact gold **Siguiente** on a local bottom scrim — never gold type on the painting.
3. **Ivory arched sheet**: small 4-point apex bump, centered ink question, gold star rule, **rounded-rect** choices. No color marks. Picked = gold border + star. No map, no pack title, no grab-handle. **The choice list is the last block** — never Next, scripture, or chips under the rects. Settled: pack + progress + verdict + **the same ivory rounded-rects**; share wash **grows**, then left **green tick** / **red crosses** appear — never a yellow sheet flash or inverted poll fill; navy **Leer** + cite pill and gold **Siguiente** live on the still, above the sheet.

## Anatomy — street ceremony

Full-bleed marble hall + god rays. Bee lockup Noche / Live / Quiz callejero. Brush **Pack completo**. Monument: double gold arch around an ivory stele (3 stars, puntaje, chest + laurels) sitting on a marble **plinth block** (mejores + tu rama) — not stacked iOS cards. Gold **Volver al mapa** + ghost **Desafiar**. No share card, no cream column scrim.

## Anatomy — presenter (`#night_presenter`)

Phone **stage**, not the player three-band.

1. Full-bleed round still. Thin gold arch. Short top scrim only.
2. Chrome: close X, **story ticks** + star bookends, mute + flag, gold **code-chip** (night code, navy on gold).
3. Cream overlay caption (not gold type, not ink-on-painting): `Ronda N de T`, title + emblem, question.
4. **One** gold next in the dock (Abrir / Cerrar buzzer / Revelar…). Quiet **Más**. Never a second gold pill. Never `Remoto: grado`.
5. Marble **desk peek**: gold pip + apex star, Lista / Fichas, tabs Respuestas / Marcador. Painting still peeks.

## Anatomy — TV (`#night_watch`)

**16:9 cinema.** Not a phone. Not a swipe reel. No sheet.

1. Full-bleed still, thin gold arch, corner stars.
2. Chrome: code chip only. No ticks, no X, no mute, no LIVE, no sala/casa HUD.
3. Short bottom caption scrim: cream title + question. Must not cover half the painting.
4. One marble **lower-third**: gold hairline top, emblem + wrapping name + score-as-metal. Team names wrap two lines — never “Casa de…”.

## Anatomy — casa QCM (`#night_play` remote)

Three-band temple **phone**, live-night head (not street rail).

1. Cream head: ink Noche Live + hairlines, **story ticks** + star bookends (not 10-dot level rail), mute + flag, **timer as object** (fat `22 s` + thick gold bar).
2. Still: round painting, gold arch. Team chip (Casa / emblem) top-left — not street rival Carmen. Score pill top-right.
3. Ivory arched sheet: apex star, ink title + question, gold star rule, **rounded-rect choices** (3 on Salomón). No red/green V/F marks. Picked = gold border + star. No grab-handle on ask. **Choices are the last block** in the sheet.

Casa’s verb is the pick. Never a wait-toy “when the room is done.”

## Anatomy — sala Buzz (`#night_play` room)

Same head + still as casa. Different job in the sheet.

1. Sheet **mid** so the painting peeks. Grip OK (sheet drags).
2. Ink title + question on ivory.
3. Hero = circular **gold medallion** Buzz: metallic disc, glow ring, bell, navy **Buzz** on gold (ink on metal, not gold type on cream). Hint `¡Sé el primero!`
4. Not a rectangle `btn-gold`. Not QCM. The chapel is loud.

## New surfaces

No mockup? Extend the **nearest seat**: same still, same marble, different verb. Write a PNG into `tmp/street-shots/temple-mockups/` or `tmp/night-shots/temple-mockups/` before inventing a layout. Never invent a black skin, Stories-on-a-form, or a `.gate` dashboard.

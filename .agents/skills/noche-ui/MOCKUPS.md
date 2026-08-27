# Temple mockups — Celestial Light spec

Charter (PRIORITY): [noche-conseil](../noche-conseil/SKILL.md). These PNGs **are** the product. Open the matching file before editing CSS/ERB. A working screen that does not match its mockup is unfinished. Hub `/` has **both** Light and Dark specs (same layout) — theme engine: [noche-hub-theme](../noche-hub-theme/SKILL.md). Other surfaces below are Celestial Light until a Dark PNG exists.

Theme follows the **artwork and the narrative moment** (noche-art) — never a user dark-mode toggle. Sinai, Flood, Gethsemane, Bethlehem night, crucifixion → **Celestial Dark** (night blue, volumetric gold). Do not force ivory marble onto those stills. Do not ship a flat black social skin and call it Dark.

Street stills: biblical adventure (peril + grace) per `config/media/street_world.yml`. Night stills: meetinghouse light per `config/media/chapel_world.yml` — never a Christus / celestial-room set. The Solomon painting in the night mockups is **round media**, not UI chrome.

## Catalog

| Surface | Mockup | Shot to compare |
|---|---|---|
| Street hub `/` Light | `tmp/street-shots/temple-mockups/mockup-street-hub-celestial-light.png` | `tmp/street-shots/temple-themed/hub-phone.png` |
| Street hub `/` Dark | `tmp/street-shots/temple-mockups/mockup-street-hub-celestial-dark.png` | same composition as Light |
| Street arrival (first visit) | hall `marble-hall.jpg` + ivory search sheet | `tmp/street-shots/temple-themed/wizard-phone.png` |
| Street jugar overlay Light | `tmp/street-shots/temple-mockups/mockup-street-jugar-temple-adventure.png` (world/crop) | `tmp/street-shots/temple-themed/01-ask-phone.png` |
| Street jugar overlay Dark | `tmp/street-shots/temple-mockups/mockup-street-jugar-celestial-dark.png` | same HUD / sheet / A-B-C / settled anatomy |
| Street pack ceremony | `tmp/street-shots/temple-mockups/mockup-street-ceremony-celestial-light.png` | `tmp/street-shots/temple-themed/ceremony-phone.png` |
| Street Liga `/liga` | `tmp/street-shots/temple-mockups/mockup-street-liga-celestial-light.jpg` | `tmp/street-shots/temple-themed/liga-phone.png` |
| Street Défis `/desafios` | same celestial court world; rivalry hero is product anatomy | `tmp/street-shots/temple-themed/duels-phone.png` |
| Presenter stage | `tmp/night-shots/temple-mockups/mockup-night-presenter-temple.png` | `tmp/night-shots/temple-themed/presenter-stage.png` |
| TV /watch 16:9 | `tmp/night-shots/temple-mockups/mockup-night-watch-temple.png` | `tmp/night-shots/temple-themed/watch-board.png` |
| Casa QCM | `tmp/night-shots/temple-mockups/mockup-night-casa-quiz-temple.png` | `tmp/night-shots/temple-themed/play-quiz-ask.png` (+ `play-quiz-casa` when the test exists) |
| Sala Buzz | `tmp/night-shots/temple-mockups/mockup-night-sala-buzz-temple.png` | `tmp/night-shots/temple-themed/play-buzz-open.png` |

Same night, same still: *La elección de Salomón*. Four seats, four verbs, one painting.

## Painting vs product KEEP

Ship the chrome. Do **not** fake the painting’s demo data or violate a hard don’t to “look more like the PNG.”

| Mockup may show | Product keeps |
|---|---|
| Gold “NOCHE LIVE” letters on cream | **Ink** lockup on Light. Gold = metal only |
| People / trophy icon top-right on jugar | Same chrome as the hub: avatar left, hamburger right. Mute + language live **in the drawer** |
| Tracy / LÉGENDE / 633 XP / 2 851 couronnes / Carmen Sanchez / 09:28:47 | Live ficha, rank, crowns, streak, défi, next night |
| Light hero = temple still; Dark hero = Moses / pack still | Artwork follows the current pack and the moment (noche-art) |
| Watch scores 10 / 6 / 4, “Las Hermanas” | Live `cached_score` + real team names (wrap, no ellipsis) |
| Presenter desk covering half the still | Desk **peek** so Solomon’s face still reads; full desk is a summon |
| Casa without a drag pip | No grab-handle on ask if the sheet is not a drag dock |
| Literal temple interior as UI | Chrome is marble tokens; stills follow chapel/street YAML |

## Anatomy — street hub

Same composition in **Celestial Light** and **Celestial Dark**. Not a marble-hall rope map. Not a Stories reel. No story ticks.

1. **HUD** — who I am: avatar + name + rank, XP bar (`current / next`), couronnes, série (flame), hamburger. Mute + language in the drawer.
2. **Continuer l’aventure** — hero card (carousel dots): pack still, étape, gold **Jouer**, reward chest. The CTA is obvious before reading.
3. **Prochaine Noche Live** — LIVE event card: date, title, countdown, **Voir le programme**.
4. **Around me** — Défi en cours (vs named rival) + Amis en ligne.
5. **Progression + communauté** — packs unlocked (Exode / Rois / Prophètes…) + parish stats.
6. **Quick actions** — Défis, Inviter, Classement only (honest routes). No Boutique / Missions stubs.
7. **Dock** — Accueil / Aventure / Live / Église / Profil. Accueil is the gold active tab. Live is gold/white at rest; red pulse only if a night is `playing`.

Phone-width column; chrome pins to the column. Type never drops below `--type-min` (14px). Light: glass cards on ivory/sky. Dark: glass cards on night blue, volumetric gold.

## Anatomy — street jugar (overlay)

Full-bleed still is the world. No cream web head. Light **or** Dark follows `Quizzes::Chrome` for that still (`config/media/quiz_stills.yml`). Spec PNG: `mockup-street-jugar-celestial-dark.png` (composition for both families). KEEP: live score, live %, live name, mute + language in the drawer.

1. **HUD** (glass on the painting, same anatomy Light and Dark): avatar + name + rank + level | pack title + `n / 10` + compact gold dots | crown **run.score** | fire **combo** | hamburger inside the capsule. Mute/lang in the drawer. Accueil in the drawer returns to `/`. After a hit, `+N` lives in the scene then flies to the crown — never printed beside the score. Combo is consecutive hits in this run (miss = 0); it survives **Suivant**. Points are never multiplied.
2. **World**: fullscreen still behind the HUD. Local top/bottom scrims only. Timer object stays on the still (timer + halo unchanged). No chase chip on the ask.
3. **Glass sheet** (bottom): gold hairline, apex star, book kicker `quiz.from_the_book`, **serif** question, pill **A / B / C** game buttons. Picked = gold border. No grab-handle.
4. **Settled = same sheet**: question stays; letters become green tick / red cross + real tally wash + %. **Super !** (or kind miss `quiz.almost`) on the still; `+N` flies to the crown. **Lire** glass (secondary) left, gold **Suivant** right — both **above** the sheet, never under the choices.

## Anatomy — street ceremony

Full-bleed celestial gateway still + god rays (Celestial Light). Same **jugar HUD** (avatar, pack 10/10 dots, crown + last-hit delta, fire combo + tag, hamburger). Shout serif gold (`INCROYABLE` family) + ink subtitle. Gold **medallion** (crown, SCORE TOTAL, score-as-metal, POINTS) + laurels + chest on a disc plinth. Ivory **stats** row (answered / correct / max streak / time). Two glass boards: Meilleurs joueurs (this pack) + Ta paroisse (total, people in the rama). Gold pill **Retour à la carte**, ghost **Défier**, quiet **Partager mon score**. Three-act payoff (world → count-up/chest → stats/CTA breathe). No bee lockup, no double-arch stele, no share card. KEEP: live scores/names; mute + language in the hamburger.

## Anatomy — Liga and Défis

One palace world: `public/media/temple/celestial-court.jpg`, one master crop with CSS `cover`; no viewport-specific generated duplicates.

**Liga**: engraved title + sibling Défis capsule; Rama/Pack scope rail; search and one custom FILTRES sheet (never native selects); 2–1–3 podium in the hall; ranks 4+ on glass; fixed Ta position bar that dissolves when `#liga-you` enters view. A rival row opens the challenge sheet. First visit reveals in 700–900 ms; Turbo revisits do not replay the entrance. Rank changes use FLIP.

**Défis**: stake rivalry is the hero, with both ward scores, animated meter and honest one-ward empty state. Then active async matches, live-first rival picker across every listed ward in the same stake, personal head-to-head, and recent results. The phone creates and plays an isolated 10-question run; send, your-turn, victory and defeat have explicit visual, haptic and named sound feedback.

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

No mockup? Extend the **nearest seat**: same still, same family (Light or Dark from the artwork), different verb. Write a PNG into `tmp/street-shots/temple-mockups/` or `tmp/night-shots/temple-mockups/` before inventing a layout. Never invent Stories-on-a-form, a `.gate` dashboard, or a flat black social skin. Celestial Dark is a first-class family when the moment demands it.

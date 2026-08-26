---
name: noche-ui
description: >-
  Temple UI director for Noche Live. Proposes and maintains screens from
  canonical mockups: street hub/jugar/ceremony and the four live-night seats
  (presenter, TV watch, casa QCM, sala Buzz). Use when changing ERB, CSS,
  Stimulus, play-reel, sheets, ticks, ceremony, presenter dock, watch TV,
  home, join, gold type, chrome, or when a screen drifts from
  tmp/*-shots/temple-mockups/.
---

# Noche Live UI

You are the **temple UI director** who designed these screens. The PNGs in [MOCKUPS.md](MOCKUPS.md) are the spec — not mood boards, not a later polish pass. Open the matching mockup **before** editing. A round that works in the database but looks like Instagram Stories on a form, a black TikTok skin, or a stack of admin cards is unfinished.

**Ink for words. Gold for metal** (arches, borders, stars, one CTA, Buzz disc, score-as-metal). Luminous ivory marble, oculus light, gold-leaf on metal only. Shared `--temple-*` tokens. Never gold type on cream, never gold on the painting’s light-beam, never stacked gold headlines.

Do **not** treat the whole app as Reels. Do **not** restore old `.gate` dashboards. Do not unwind peek-pass or overlay-contrast CSS.

Family night: huge hits, sofa vs casa. Copy is i18n (es, pt-BR, en, fr) — noche-i18n.

## Spec first

Read [MOCKUPS.md](MOCKUPS.md). Compare `tmp/*-shots/temple-themed/` to the mockup. Close chrome gaps. Product KEEP (mute in the hamburger on street, ink lockup, live scores) is listed there — do not violate a hard don’t to copy demo data.

| Product | Mockup |
|---|---|
| `/` `#street_world` | `mockup-street-hub-temple-ui.png` |
| `/jugar` ask | `mockup-street-jugar-temple-adventure.png` |
| `/jugar` pack complete | `mockup-street-ceremony-temple-victory.png` |
| `#night_presenter` | `mockup-night-presenter-temple.png` |
| `#night_watch` 16:9 | `mockup-night-watch-temple.png` |
| `#night_play` casa QCM | `mockup-night-casa-quiz-temple.png` |
| `#night_play` sala Buzz | `mockup-night-sala-buzz-temple.png` |

Street ≠ night. Do not put a 10-dot **level rail** on a live round. Do not put **story ticks** on the hub or jugar. Do not put Gran final / four seats on a street pack.

## Hard don’ts (never ship)

| Don’t | Do |
|---|---|
| Gold type on cream, gold on the light-beam, stacked gold headlines | Ink (`--ink`) on paper; cream overlay type only on a **local** scrim. Gold = emblem, **one** CTA, trophy, Buzz metal, score-as-metal |
| Word-card sheet beheading the still; fake gold grab-handle on a non-drag form | Painting visible. No handle if the sheet cannot be dragged |
| Stories ticks on home, join, ceremony-as-form, fichas, roster, lobby, pick-team | Ticks = **live round timeline only** (play + presenter stage) |
| Universal costume: ticks + LIVE 0 + X + mute + handle on every surface | One job per screen. Mute in the hamburger on hub and jugar; mute + flag on live play and presenter. X only where swipe-down exit needs it (play, presenter). **No X on home/join/ceremony/fichas/roster.** No LIVE chip |
| Presenter: grado A, five equal pills, Lista/Fichas FABs, pause/end/next all gold | **One** sequential gold next. Pause / end / Lista / Fichas in Más or desk |
| Ceremony shouting Gran Final over **0–0**; “Este viernes” flyer under the result | One hero (name, emblem, score). Honest empty or tie |
| Home: night code or search as the hero; Stories ticks on the hub | Hub mockup. `/noches` is the paper feed. Search and night code in the hamburger |
| Join: iOS springboard tile; equal-weight presenter | **Entrar** as a real button. Presenter / Solo ver as `.quiet-link` |
| Watch: four headcounts + iOS score pills + LIVE 0; phone sheet on the TV | Cinema 16:9: still + short caption + **one** scoreboard strip |
| Casa wait-toy while the room buzzes; sala QCM instead of Buzz | Casa = pick; sala = slam. Same still, different sheet |
| Flat yellow circle labeled Buzz | Gold **medallion** (metal disc, bell, navy Buzz on gold) |
| Color-coded V/F or A/B choice marks on temple QCM | Rounded-rect, gold hairline; picked = gold border + star |
| Scripture, Next, or chips under the QCM choices | The choice list is the **last** block in the sheet. Street settled: scripture + next sit on the still |
| Full-screen milky veil | Cream type + **local** top/bottom scrims only |
| Burger layers as four mystery discs | Labels on each layer, or one peel verb |
| Timer as a yellow hairline | Timer as a readable object (fat numerals + thick gold bar) |
| Copy “Solo esta noche” changed while tests pin the Spanish literal | `t()` + locales + tests. Four languages |

```erb
<%# BAD — gold words on cream; Stories ticks on a form; tile CTA %>
<h1 class="stand-up">GRAN FINAL</h1>
<button class="btn btn-gold picto-btn"><%= picto("door") %><span>Entrar</span></button>

<%# GOOD — ink words; gold metal/CTA; row button %>
<h1>Campeones</h1>
<button class="btn btn-gold"><%= picto("door") %>Entrar</button>
```

## Four live-night seats

One night, one still, four verbs. Chrome is celestial marble. Implementation uses `#night_play` / `#night_watch` / `#night_presenter` and `story` + `sheet` — that is **how** we ship the mockup, not a competing look.

| Seat | Verb | Shape |
|---|---|---|
| Presentador | One gold next (Cerrar buzzer, Revelar…) | Stage: still + cream caption + dock. Marble desk **peek** (Lista / Fichas, Respuestas / Marcador) |
| Equipo en sala | Slam | Three-band phone: cream head (ticks + timer) + still + ivory sheet with gold **Buzz** medallion |
| Jugador en casa | Grade A/B pick | Same three-band head; sheet is QCM rounded-rects, picked gold + star |
| Espectador | Opt-in Solo ver | 16:9 cinema: still + short cream caption + one marble score strip |

Watch has **no sheet**. Presenter is **not** the player three-band. Casa and sala share a head; they must not share a verb.

Join / lobby / pick-team keep shipped layouts, same arched marble sheet — strip Story residue (ticks, LIVE 0, décor X, fake handle). Ceremony / finale: gold arch, ink score hero, marble podium. `scored_finale?` before any coronation shout.

```text
PLAY (casa or sala)
  .play-shot     round painting — faces visible
  .play-chrome   ticks + star bookends + timer object + score pill — no LIVE 0
  .play-sheet    ivory arch + apex star; QCM or Buzz; mid/peek

PRESENTER
  .stage-shot    same painting
  .stage-dock    ONE gold next + quiet Más
  .stage-desk    peek; summon for answers/score

WATCH
  .watch-shot    full-bleed 16:9
  .watch-caption short scrim, cream type
  .watch-board   one strip, gold hairline, wrapping names
```

```erb
<%# BAD — dashboard night %>
<section class="play-card">
  <header class="team-bar">…</header>
  <%= button_to "Buzz", …, class: "btn btn-gold" %>
</section>

<%# GOOD — live seat %>
<section class="play-card play-reel" data-controller="story">
  <div class="play-shot"><%= render "shared/story_pages", … %></div>
  <div class="play-chrome">…ticks, timer, score…</div>
  <div class="play-sheet" data-controller="sheet">…QCM or Buzz medallion…</div>
</section>
```

Do **not** put a live round in a padded `.play-card` with a `.team-bar` on the chrome. Score lives in `.story-score` / `.score-pop`. Ticks sit at the very top, only while a round is the job.

## Street kit

Mobile game loop, not a night. Same marble language. Adventure stills, not chapel pews.

| Surface | Shape |
|---|---|
| Hub `/` | Hall canvas. Player card, 3-node rope map, MAPA, LIGA top 3, gold Jugar. **No reel. No 5-tab dock.** Same composition, **column grows with the window**: 390 / iPad 36rem / desktop 44rem / XL 52rem, centered on the hall. Avatar / hamburger pin to that column, not the browser corners. Type floor `--type-min` (14px+) for abuelos. Mute and language live in the drawer. |
| Jugar ask | Cream head + level rail + still + ivory QCM sheet (choices last). Same chrome as the hub: avatar left, hamburger right, mute + language in the drawer. From 720, **phone arch** on the hall (28 / 32 / 36rem), never a stretched QCM. |
| Jugar settled | Same three-band. Navy **Leer** + cite pill + gold next live **on the still**. Sheet ends at the rounded-rect bars. |
| Pack ceremony | Hall + god rays + ivory stele in a **double gold arch** on a marble plinth (not stacked cards) + chest + Volver / Desafiar |
| Cards | `.street-card` `.is-player` `.is-pack` `.is-rival` `.is-duel`. Marble, gold border, ink titles |
| Duels | Async `/desafio/:token`. Face-to-face after both finish |

Hub pack stills are thumbnails on the rope, not full-bleed. Wizard is an inline marble panel, not a blocking veil.

## When the reel is not required

Hub, `/noches`, fichas, roster, gates, presenter **lists** are not shot+sheet quizzes. You may design a clearer layout for *new* work in that family — still temple marble, still not `.gate` cards, still not a fake reel.

**Noches (`/noches`)** — paper feed. Ink wordmark. One gold **Ven a la Iglesia** CTA (`church.invite` → `/iglesia`). Search lives in the hamburger. Próximamente + last 10 nights. Paintings on **cards**. No X, ticks, mute.

**Buscar** — form is the job. Listed Benidorm shows without typing.

**Join** — Entrar is a pill. Presenter / Solo ver quiet. Guest may keep `Solo esta noche` if tests pin it.

**Rama** — emblem, name, chapel pin (Maps, no embed) on the marble hall (no ivory sheet). One night poster per row, with date and missionary names under it. **One** gold CTA (Entrar *or* Abrir la noche). Live: Solo ver quiet.

If you touch a non-quiz screen: strip Story residue. Do not peel the still off and drop a paper `.gate` card.

## Canvas

| Token | Role |
|---|---|
| `--paper` | Page background |
| `--surface` | Cards and sheets |
| `--ink` | Text on paper |
| `--muted` / `--parchment` | Secondary |
| `--line` | Hairlines |
| `--gold` | Metal and one CTA — not headlines |
| `--type-min` `--type-ui` `--type-ask` `--type-choice` `--type-hit` | Abuelos floor (14px+) and ask/choice/CTA; bump at 720 / 1024 / 1440 |
| `--street-play-col` `--street-ceremony-col` | Phone-arch width for jugar / live seats / ceremony monument |
| `--temple-marble`, `--temple-ivory`, `--temple-oculus`, `--temple-gold-leaf`, `--temple-gold-border`, `--temple-gold-hairline`, `--temple-star` | Celestial chrome |
| `--fire` | Alerts, streaks |
| `--story-type` / `--story-shadow` | Overlay on stills |

Navy is a **secondary button fill**, never the page. No new palette, no dark mode, no CSS framework. 8px scale. Padding `--space-6` phone, `--space-7` presenter/watch. Stacks use **gap**. Never `margin: 4px`.

## Overlay contrast

Chrome **on stills** (play, watch, presenter): cream type + local scrims. Do not replace with ink-on-paper veils or a milky wash.

| Token | Role |
|---|---|
| `--story-type` / `--story-type-soft` | Overlay captions |
| `--scrim-top` | `.play-chrome` / `.watch-chrome` / `.stage-chrome` |
| `--scrim-bottom` | `.watch-caption` / `.stage-caption` — short |
| `--scrim-board` | `.watch-board` only — never a second tall wash |

Player sheets and the presenter desk stay `--paper` / `--ink`.

## Gestures (live play + presenter only)

Already on `story` + `sheet`. Do not invent a second swipe engine.

| Gesture | Result |
|---|---|
| Swipe down | Leave (`story#exit`) |
| Swipe left / right, tap edges | Previous / next round |
| Swipe up | Open the sheet |
| Drag grip | `peek` → `mid` → `open` — omit grip if not a drag dock |

Keep the Spanish skip line tests assert. Drawing must **peek** above the sheet. Watch does not swipe.

Street jugar next/prev: swipe or tap the **painting** (right advances after answering). After a settle, **Siguiente** is a compact gold pill on the still (not a dock under the QCM). Scripture is a navy pill: short verb (`quiz.read` — Leer / Ler / Read / Lire) + cite (`1 Samuel 16:13`). No `story` swipe on hub. The ivory sheet **never** puts another block under the QCM choices.

## Motion

`<body data-controller="stage press motion">`. Pressable: `.btn`, `.choice-btn`, `.team-pick`, `.buzz`, `.emblem-choice`, `.choice-chip`, `.story-tick`, `.picture-card`, `.quiet-link`. View Transitions meta. Stable ids `#night_play`, `#night_watch`, `#night_presenter`. Honor `prefers-reduced-motion`. Street ceremonies/duels: `street_motion_controller`.

Timed ask: inset `.timer-halo` on `#street_quiz` / `#night_play` / `#night_watch` (orange when remaining ≤ 40% of the question, red when remaining ≤ 20%), one pulse per second — not a tick sound. Matching numeral/bar: `.play-timer.is-warn` / `.is-low`. A freshly opened ask must not start orange. Street correct settle: `.street-praise` cream type on the still with a **local** scrim (never gold on the painting).

## Controls

| Class | Use |
|---|---|
| `.btn.btn-gold` | The **one** primary action |
| `.btn.btn-navy` | Strong secondary |
| `.btn.btn-ghost` | Tertiary |
| `.quiet-link` | Más, Presenter, Solo ver |
| `.buzz` | Sala slam — medallion, on the sheet |
| `.story-tick` | Live round dots only |
| `.play-sheet-grip` | Only if draggable |
| `.picto-btn` | Avoid for primary doors |

Phone primary is full width **inside the sheet**.

## Checklist

- [ ] Opened the mockup PNG for this surface (or documented why none exists)
- [ ] Live seats match the four-seat kit (casa pick / sala Buzz / TV cinema / presenter one gold)
- [ ] No gold headlines on cream or on the light-beam
- [ ] Ticks only on a live round; level rail only on jugar
- [ ] Hub is the marble hall map; `/jugar` is three-band ask or hall ceremony; `/noches` is paper
- [ ] No LIVE chip; mute where the kit says; no X on home/join/ceremony/fichas
- [ ] Painting visible; no fake handle
- [ ] Watch caption + board are short; names wrap
- [ ] Presenter: one gold next; no grado A
- [ ] Ceremony is one hero or an honest empty/tie
- [ ] Did **not** checkout `.gate` cards; peek-pass / overlay contrast intact
- [ ] Gestures stay on `story` / `sheet`
- [ ] Gap tokens; `t()` + four locales; tests updated
- [ ] Screenshots vs mockup (or curl) before done

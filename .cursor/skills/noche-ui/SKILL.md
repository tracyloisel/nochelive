---
name: noche-ui
description: >-
  Designs Noche Live's warm-white UI: live quiz is a still-first reel; other
  screens keep what shipped (never restore old .gate dashboards). Use when
  changing ERB, CSS, Stimulus, play-reel, sheets, ticks, ceremony, presenter
  dock, watch TV, home, join, gold type, chrome, or when a screen looks like
  Instagram Stories on a form.
---

# Noche Live UI

Read this before writing or restyling any screen. A future change that reintroduces a **Hard don’t** is unfinished.

Stay warm white — never a black TikTok skin. **Ink for words. Gold for metal** (emblems, one CTA, trophies).

**Do not treat the whole app as Reels.** TikTok itself has several layouts. Noche Live does too.

**Do not restore the old gate-card / dashboard screens.** Home, join, pick-team, lobby, fichas, roster, missionaries, rama / create-night gates, and presenter desk lists already shipped as stills and sheets. Never `git checkout` pre-reel views. Do not unwind peek-pass or overlay-contrast CSS. Non-quiz screens may use a clearer layout *later*; that is not a license to rewind to `.gate` cards.

Family night still matters (huge hit targets, sofa vs casa). Questions, titles, and stand-up are **readable type**. Copy is I18n in es, pt-BR, en, and fr — see noche-i18n.

## Hard don’ts (never ship)

| Don’t | Do |
|---|---|
| Gold type on cream, gold on the painting’s light-beam, stacked gold headlines | Ink (`--ink`) for titles, questions, stand-up, rank names. Cream overlay type only on a **local** scrim. Gold = emblem, **one** CTA, trophy, score-as-metal |
| Word-card sheet beheading the still; fake gold grab-handle on a form that is not a drag-sheet | Live quiz: painting visible, **thin action dock**. If the sheet cannot be dragged, **no handle** |
| Stories ticks on home, join, ceremony-as-form, fichas, roster, lobby, pick-team | Ticks = **live round timeline only** (play round, presenter stage during a round) |
| Universal costume: ticks + LIVE 0 + X + mute + handle on every surface | One job per screen. Mute on live quiz only. X only where swipe-down exit needs a visible control (play round, presenter stage). **No X on home/join/ceremony/fichas/roster.** No LIVE chip |
| Presenter: grado A, five equal pills, Lista/Fichas FABs, pause/end/next all gold | **One** sequential gold next. Pause / end / Lista / Fichas in overflow or desk |
| Ceremony shouting Gran Final / ¡TODOS DE PIE! over **0–0**; “Este viernes” flyer under the result | One hero (name, emblem, score). Honest empty or tie. Prefer last-round still, not the theme flyer |
| Home: night code or search form as the hero; Stories ticks on the street quiz; `/noches` dressed as a live reel | `/` is the street-quiz reel (`#street_quiz`). `/noches` is the paper night feed. Mute on the street quiz. Flag language control sits under mute. Noches live in the hamburger |
| Join: iOS springboard tile (icon stacked over label); equal-weight presenter; next-card peek stealing the footer | **Entrar** as a real button (label **with** icon, row). Presenter / Solo ver as quieter links |
| Watch: four headcounts + iOS score pills + LIVE 0 | Cinema: still + question + **one** scoreboard lower-third |
| Full-screen milky veil over the painting | Cream type + **local** top/bottom scrims only |
| Burger layers as four mystery discs | Labels on each layer, or one peel verb |
| Timer as a yellow hairline | Timer as a readable object (fat numerals + thick bar) |
| Copy “Solo esta noche” changed while tests still pin a Spanish literal | Use `t()`; update locale files **and** tests in the same change. Four languages: noche-i18n |

```erb
<%# BAD — gold words on cream; Stories ticks on a form; tile CTA %>
<h1 class="stand-up">GRAN FINAL</h1>
<p class="round-title">La elección de Salomón</p>
<button class="btn btn-gold picto-btn"><%= picto("door") %><span>Entrar</span></button>

<%# GOOD — ink words; gold metal/CTA; row button %>
<h1>Campeones</h1>
<p class="round-title">La elección de Salomón</p>
<button class="btn btn-gold"><%= picto("door") %>Entrar</button>
```

## When the reel is required

**Live quiz / live night** is a Stories reel: a picture fills the phone or TV, **thin** chrome floats, actions sit on a dock you can pull (watch has no sheet). Overlay contrast (cream type + local scrims) stays.

| Surface | Shape |
|---|---|
| Play round (including burger finale) | `.play-reel`: `.play-shot` + thin `.play-chrome` (ticks + timer + score) + `.play-sheet` dock |
| Presenter **stage during a round** | `.console.is-stage`: `.stage-shot` + overlay + peek `.desk-sheet`. One gold next in `.stage-dock` |
| TV /watch **during a round** | `.watch.is-board`: `.watch-shot` + thin chrome (code) + caption + **one** `.watch-board` lower-third. No sheet, no presence HUD |

Rank-up and ceremony stay in-night (still + sheet/caption). Ceremony is **one hero**, not a mid-round form and not a Friday poster.

```text
REEL (live quiz only)
  .play-shot     the screen is a picture — faces must remain visible
  .play-chrome   ticks + readable timer + score — not LIVE 0 + five pills + décor X
  .play-sheet    question / buzz / choices; mid/peek so the painting shows
                 handle only if the sheet is actually draggable

PRESENTER STAGE (during a round)
  .stage-reel    shot + overlay
  .stage-dock    ONE gold next action
  desk           answers/score when summoned; Lista/Fichas live here or in Más

WATCH (during a round)
  .watch-shot    full-bleed still
  .watch-caption question / shout over a bottom scrim
  .watch-board   emblem + score, one strip
```

A live round without a full-bleed still and a thin dock is unfinished. It is not a stack of admin cards.

```erb
<%# BAD — dashboard night for a live round %>
<section class="play-card">
  <header class="team-bar">…</header>
  <%= button_to "Buzz", …, class: "btn btn-gold" %>
</section>

<%# GOOD — live quiz / play round %>
<section class="play-card play-reel" data-controller="story">
  <div class="play-shot"><%= render "shared/story_pages", … %></div>
  <div class="play-chrome">…ticks, timer, score…</div>
  <div class="play-sheet" data-controller="sheet">…</div>
</section>
```

Do **not** put a live round in a padded `.play-card` with a `.team-bar` on the chrome. Score lives in `.score-pop`. Ticks sit at the **very top**, and only while a round is the job.

## When the reel is not required

**Everywhere else** may pick the best layout **in the future** — a gate card, a form, a desk, a feed. That freedom is for *new* work.

What is on disk **now** stays (still + sheet wrapper is OK), except **home**, which is the street-quiz reel, and **`/noches`**, which is the paper night feed:

- Home (`#street_quiz`: still-first pack QCM, no ticks, no X, no story swipe)
- Nights (`/noches`, `home-paper`: title, Quién somos, Buscar, upcoming + past)
- Join / name, pick-team, lobby waiting
- Fichas, roster, missionaries
- Rama / create-night gates, presenter claim / wait
- Presenter desk lists

If you touch one of them: **strip Story residue** (ticks, LIVE 0, décor X, fake handle). Do **not** peel the still off and drop a paper `.gate` card. Do **not** force shot + sheet onto a *new* non-quiz screen just because play is a reel.

## Canvas

| Token | Role |
|---|---|
| `--paper` | Page background |
| `--surface` | Cards and sheets |
| `--ink` | Text on paper (titles, questions, stand-up) |
| `--muted` / `--parchment` | Secondary text |
| `--line` | Hairline borders |
| `--gold` | **Metal and one CTA** — not headlines |
| `--fire` | Alerts, streaks |
| `--story-type` | Overlay captions on stills (with `--story-shadow`) |

Navy is a **secondary button fill**, never the page. No new palette, no dark mode, no CSS framework.

Use the 8px scale. Card / sheet padding is `--space-6` on phone, `--space-7` on presenter/watch desks. Stacks use **gap**. Never one-off `margin: 4px`.

## Overlay contrast (chrome on stills)

Applies to chrome **on stills**: play, watch, presenter stage. Keep this system. Do not replace it with ink-on-paper veils or a milky full-screen wash.

Overlay copy on the still is **cream**, not `--ink` and not `--gold`. Soft vertical scrims sit only under chrome (top) and watch/presenter captions (bottom).

| Token | Role |
|---|---|
| `--story-type` | Overlay captions |
| `--story-type-soft` | Secondary overlay copy |
| `--story-shadow` | Halo so cream reads on gold or night stills |
| `--scrim-top` | `.play-chrome` / `.watch-chrome` / `.stage-chrome` |
| `--scrim-bottom` | `.watch-caption` / `.stage-caption` — short, local |
| `--scrim-board` | `.watch-board` strip only — never a second tall wash |

The pull-up sheet and presenter desk stay `--paper` / `--ink`. Do not pick colors per illustration.

## Gestures (live reel only)

Already on `story` + `sheet`. Do not invent a second swipe engine.

| Gesture | Result |
|---|---|
| Swipe down | Leave the night (`story#exit`) |
| Swipe left / right, tap edges | Previous / next round |
| Swipe up | Open the sheet |
| Drag sheet grip | Snap `peek` → `mid` → `open` — omit the grip if the sheet is not a drag dock |

Keep the Spanish skip line tests assert (`Desliza abajo…`). On a live reel, the drawing must **peek** above the sheet (`peek` / `mid`). A sheet that covers the still is unfinished.

Watch is a picture board for the TV, not a reel you swipe. Stills are full-bleed. No sheet. No card stack.

## Motion

`<body data-controller="stage press motion">`.

- **Press**: add a pressable class (`.btn`, `.choice-btn`, `.team-pick`, `.buzz`, `.emblem-choice`, `.choice-chip`, `.story-tick`, `.picture-card`, `.quiet-link`) so `press_controller.js` ripples.
- **Screens**: keep `<meta name="view-transition" content="same-origin">`.
- **Live updates**: stable ids `#night_play`, `#night_watch`, `#night_presenter`.
- **Arrive**: `.is-arriving` / `@keyframes arrive`.

Honor `prefers-reduced-motion`. Never `animation: none` globally except in that media query.

## Controls

| Class | Use |
|---|---|
| `.btn.btn-gold` | The **one** primary action on that screen |
| `.btn.btn-navy` | Strong secondary |
| `.btn.btn-ghost` | Tertiary / cancel |
| `.quiet-link` | Presenter / Solo ver / overflow text actions |
| `.btn-tiny` | Compact chrome; still ≥ 44×44 if it is the only hit |
| `.buzz` | Round-level slam only, on the sheet |
| `.story-tick` | Round dots — live round only |
| `.play-sheet-grip` | Sheet handle — only if draggable |
| `.picto-btn` | Avoid for primary doors (it stacks icon over label like an app tile) |

On the phone column, the primary button is full width **inside the sheet**, label beside a small icon. In `.console-actions` and `.cluster` they shrink to content.

## Surfaces

**Home** — street quiz reel (`#street_quiz`, `.play-reel.is-quiz.is-street`). Pack title + `3 / 10` in ink on the sheet. One gold **Siguiente** after a tap. Scripture is a `.quiet-link`. No ticks, no X, no `story` swipe. Mute stays visible. Flag language control sits under mute. **Noches** (`/noches`) live in the hamburger. Search stays `/buscar`.

**Noches (`/noches`)** — paper feed, not a reel. Ink wordmark (`Noche Live`). No full-bleed painting behind the page. Two quiet doors: Quién somos (`/nosotros`) and Buscar (`/buscar`). Then **Próximamente** and the last 10 finished nights. Paintings live **on night cards**. No X, no ticks, no gold, no mute.

**Buscar** — dedicated place search. Form is the job of that page. Listed Benidorm shows without typing.

**Join** — name screen for a night. `Entrar` is a pill, not a springboard tile. Presenter and Solo ver are `.quiet-link`. Guest play may keep the string `Solo esta noche` if tests pin it; do not use a trash/cup glyph. No X on the still.

**Rama profile** — Instagram-like: emblem, name, chapel pin (Maps link, no embed), N noches, grid. **One** gold CTA. Live night → Entrar. Else if host → Abrir la noche. Never both gold. Live: Solo ver as `.quiet-link`. Host fichas / secreto stay quiet.

**Play** — ticks, fat timer, score. No LIVE chip. Question and round title in ink on the sheet. Burger layers labeled. Mid/peek so Solomon’s face is not under the card.

**Watch** — cinema. No sala/casa/en-vivo HUD. Lower-third = emblems + scores on a **short** board scrim; the caption scrim must not cover half the painting. Team names wrap (two lines), they do not ellipsis into “Casa de…”.

**Presenter** — `presenter_next_action` is the only gold in the dock. Never print `Remoto: grado`. Phase is not a developer banner (`open` / `OPEN`).

**Ceremony** — `scored_finale?` before any coronation shout. Champion = giant emblem, name, score. Tie = names + scores, no fake 1.º cards of zero. Empty = “La noche cierra.” still, no Gran Final skin. Do not park the result on `media/nights/*.jpg` if a round still exists (`ceremony_still_src`).

## Checklist

- [ ] Live quiz / watch-during-round / presenter-stage-during-round is shot + thin chrome (+ sheet on play)
- [ ] No gold headlines on cream or on the light-beam
- [ ] Ticks only on a live round timeline
- [ ] Home is the street-quiz reel (`#street_quiz`); `/noches` is paper (title, Quién somos, Buscar, upcoming + past nights); search is `/buscar`
- [ ] Street quiz has no Story costume (ticks, LIVE 0, X, fake handle); mute is visible; flag language control sits under mute; one gold Siguiente after a tap
- [ ] Join/ceremony/fichas/roster have no Story costume (ticks, LIVE 0, X, fake handle)
- [ ] Play chrome has no LIVE chip
- [ ] Painting visible (mid/peek); no handle if the sheet is not a drag dock
- [ ] Watch caption + board scrims are local and short; names on the strip wrap
- [ ] Presenter dock has one gold next; no grado A on stage
- [ ] Ceremony is one hero or an honest empty/tie
- [ ] Watch is still + question + one scoreboard strip
- [ ] Burger layers are labeled; timer is a readable object
- [ ] You did **not** checkout or rewrite gates back to old `.gate` cards
- [ ] Overlay chrome still uses cream type + local scrims (no paper veil)
- [ ] Peek-pass / contrast CSS was not unwound
- [ ] Gestures stay on `story` / `sheet`
- [ ] Padding uses gap tokens
- [ ] Copy in tests still matches (or tests updated in this change); new strings exist in es, pt-BR, en, fr
- [ ] Verify the flow in the browser (or curl + screenshots)

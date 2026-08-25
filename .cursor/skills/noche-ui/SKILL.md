---
name: noche-ui
description: >-
  Designs Noche Live's white Stories/TikTok-like reel: full-bleed shot, overlay
  chrome, bottom sheet, swipe, press ripples, and Hotwire views. Use when
  changing ERB, CSS, Stimulus, layout, play-reel, stage-reel, sheets, ticks,
  buttons, padding, or when the UI looks like a dashboard of cards.
---

# Noche Live UI

Read this before writing or restyling any screen.

**Every** user-facing screen is a **Stories reel**: a picture fills the phone (or the TV), chrome floats on top, actions sit on a sheet you pull. That includes home, join, lobby, pick-team, rank-up, ceremony, and a finished night. Watch is the same picture-first grammar without a sheet. Stay warm white — never a black TikTok skin.

## Canvas

| Token | Role |
|---|---|
| `--paper` | Page background |
| `--surface` | Cards and sheets |
| `--ink` | Text |
| `--muted` | Secondary text |
| `--line` | Hairline borders |
| `--gold` | Primary CTA, scores, live moments |
| `--fire` | Alerts, streaks |

Navy is a **secondary button fill**, never the page.

## Layouts

| Mode | When | Shape |
|---|---|---|
| **Reel** | Home, join, lobby, pick-team, play, rank-up, ceremony, presenter | Full viewport. `.play-reel` / `.console.is-stage` |
| **Board** | Watch TV | Full-bleed still + overlay chrome. No sheet, no card stack |

```text
REEL
  .play-shot     story stills (the screen is a picture)
  .play-chrome   ticks, timer, close, score, LIVE — thin overlay
  .play-sheet    grip + question / form / wait / ceremony (peek / mid / open)

PRESENTER
  .stage-reel    same idea: shot + overlay + .desk-sheet
  desk           text-first for the adult; the shot stays the round still

WATCH
  .watch-shot    full-bleed still
  .watch-chrome  LIVE, code — thin overlay
  .watch-caption shout / prompt / ceremony over the picture
```

Overlay copy on the still is **cream**, not `--ink`. Soft vertical scrims sit only under chrome (top) and watch/presenter captions (bottom). Never a milky paper veil over the picture.

| Token | Role |
|---|---|
| `--story-type` | Overlay captions (ticks row, watch lede, presenter overlay title) |
| `--story-type-soft` | Secondary overlay copy |
| `--story-shadow` | Halo so cream reads on gold or night stills |
| `--scrim-top` | `.play-chrome` / `.watch-chrome` / `.stage-chrome` |
| `--scrim-bottom` | `.watch-caption` / `.stage-caption` |

The pull-up sheet and presenter desk stay `--paper` / `--ink`. Do not pick colors per illustration.

Do **not** put a live night, lobby, rank-up, or ceremony in a padded `.play-card` with a `.team-bar` on the chrome. Score lives in `.score-pop`. Ticks sit at the **very top**, like Stories. Sheet padding stays on the 8px scale (`--space-6` on phone, `--space-7` on presenter/watch desks). Never one-off `margin: 4px`.

```erb
<%# BAD — dashboard night %>
<section class="play-card">
  <header class="team-bar">…</header>
  <p class="lede">…</p>
  <%= button_to "Buzz", …, class: "btn btn-gold" %>
</section>

<%# GOOD — every night screen %>
<section class="play-card play-reel" data-controller="story">
  <div class="play-shot"><%= render "shared/story_pages", … %></div>
  <div class="play-chrome">…ticks, timer, story-close…</div>
  <div class="play-sheet" data-controller="sheet">…</div>
</section>
```

## Gestures

Already on `story` + `sheet`. Do not invent a second swipe engine.

| Gesture | Result |
|---|---|
| Swipe down | Leave the night (`story#exit`) |
| Swipe left / right, tap edges | Previous / next round |
| Swipe up | Open the sheet |
| Drag sheet grip | Snap `peek` → `mid` → `open` |

Keep the Spanish skip line tests assert (`Desliza abajo…`). The drawing must **peek** above the sheet (`peek` / `mid`). A sheet that covers the still is unfinished.

Watch is a picture board for the TV, not a reel you swipe. Stills are full-bleed. No sheet. No card stack.

## Motion

`<body data-controller="stage press motion">`.

- **Press**: add a pressable class (`.btn`, `.choice-btn`, `.team-pick`, `.buzz`, `.emblem-choice`, `.choice-chip`, `.story-tick`, `.picture-card`) so `press_controller.js` ripples. Do not invent a second click animation.
- **Screens**: keep `<meta name="view-transition" content="same-origin">`.
- **Live updates**: stable ids `#night_play`, `#night_watch`, `#night_presenter`.
- **Arrive**: `.is-arriving` / `@keyframes arrive`.

Honor `prefers-reduced-motion`. Never `animation: none` globally except in that media query.

## Controls

| Class | Use |
|---|---|
| `.btn.btn-gold` | Primary action |
| `.btn.btn-navy` | Strong secondary |
| `.btn.btn-ghost` | Tertiary / cancel |
| `.btn-tiny` | Compact chrome; still ≥ 44×44 if it is the only hit |
| `.buzz` | Round-level slam only, on the sheet |
| `.story-tick` | Round dots in the chrome |
| `.play-sheet-grip` | Sheet handle |

On the phone column, buttons are full width **inside the sheet**. In `.console-actions` and `.cluster` they shrink to content. Presenter **desk** is text-first for the adult; the **shot** stays picture-first.

## Kid-first

A six-year-old who cannot read must still play (home, name, play, watch):

- The **picture is the round**. Sheet text is a caption. Never restyle by deleting Spanish strings tests assert.
- Hit targets are huge: slam `.buzz`, picture cards, colored choice shapes.
- Multiple-choice uses the same color+shape on phone and TV (`.choice-gold` circle, `.choice-fire` square, `.choice-navy` triangle, `.choice-deep` star).
- Location is sofa / house cards, not a text radio row.
- Waiting is a bouncing emblem or hourglass, Spanish line kept as caption.

Use `picto("door")`, `.picto-btn`, `.picture-card`, `choice_mark(index)`. Add `is-kid` on player/home/watch bodies.

## Checklist

- [ ] Every screen is shot + chrome + sheet (watch: shot + chrome, no sheet)
- [ ] Story still peeks above the sheet; ticks sit at the top
- [ ] Gestures stay on `story` / `sheet` (no second swipe library)
- [ ] No padded `.play-card` + `.team-bar` as the live layout
- [ ] Sheet/desk padding uses gap tokens, not magic pixels
- [ ] Pressable elements use existing button/tick/buzz classes
- [ ] Copy in tests still matches
- [ ] Verify the flow in the browser (or curl + screenshots)

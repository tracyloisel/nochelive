---
name: noche-ui
description: >-
  Designs and implements Noche Live's white, tactile UI: spacing scale, press
  ripples, screen/stream transitions, and Hotwire views. Use when changing ERB,
  CSS, Stimulus, layout, buttons, padding, margin, animation, or when the UI
  looks flat or cramped.
---

# Noche Live UI

Read this before writing or restyling any screen.

## Canvas

Warm white product, not a night-sky theme.

| Token | Role |
|---|---|
| `--paper` | Page background |
| `--surface` | Cards |
| `--ink` | Text |
| `--muted` | Secondary text |
| `--line` | Hairline borders |
| `--gold` | Primary CTA, scores, live moments |
| `--fire` | Alerts, streaks |

Navy is a **secondary button fill**, never the page.

## Spacing

Use the 8px scale in `application.css`. Default stack gap is `--space-5` (24px). Card padding is `--space-6` (32px) on phone, `--space-7` on presenter/watch.

```erb
<section class="play-card">
  <header class="team-bar">…</header>
  <p class="lede">…</p>
</section>
```

Do **not** set one-off `margin: 4px` / `padding: 8px` on new blocks. Put the block in a stacked parent (`.gate`, `.play-card`, `.console`, `.watch`, `.join-form`, `.cluster`) and let `gap` work.

```css
/* BAD */
.foo { margin-top: 6px; padding: 8px; }

/* GOOD */
.foo { display: flex; flex-direction: column; gap: var(--space-4); padding: var(--space-5); }
```

## Motion

Already wired on `<body data-controller="stage press motion">`.

- **Press**: do not invent a second click animation. Add a pressable class (`.btn`, `.choice-btn`, `.team-pick`, `.buzz`, `.emblem-choice`, `.choice-chip`) so `press_controller.js` can ripple.
- **Screens**: Turbo Drive uses `<meta name="view-transition" content="same-origin">`. Do not disable it.
- **Live updates**: `motion_controller.js` wraps Turbo Streams/Frames in `startViewTransition`. New surfaces should keep a **stable id** (`#night_play`, `#night_watch`, `#night_presenter`) so the transition has an anchor.
- **Arrive**: new cards use `.is-arriving` / `@keyframes arrive`. Prefer that over JS timeouts.

Honor `prefers-reduced-motion` (already in CSS). Never `animation: none` globally except in that media query.

## Controls

| Class | Use |
|---|---|
| `.btn.btn-gold` | Primary action |
| `.btn.btn-navy` | Strong secondary |
| `.btn.btn-ghost` | Tertiary / cancel |
| `.btn-tiny` | Compact, still ≥ 44×44 if it's the only hit target; presenter chips may be shorter |
| `.buzz` | Round-level slam only |

Buttons are full width on the phone column (`.shell`). In `.console-actions` and `.cluster` they shrink to content.

## Kid-first (player screens)

A six-year-old who cannot read must still be able to play. On home, name, play, and watch:

- The **picture is the control**. Text is a caption under or beside it. Never restyle by deleting Spanish strings tests assert.
- Hit targets are huge: slam `.buzz`, picture cards, colored choice shapes.
- Multiple-choice uses the same color+shape on the phone and the TV (`.choice-gold` circle, `.choice-fire` square, `.choice-navy` triangle, `.choice-deep` star) so kids match pictures, not words.
- Location is two picture cards (sofa / house), not a text radio row.
- Waiting is a bouncing emblem or hourglass, with the Spanish wait line kept as caption.
- Presenter console stays text-first for the adult host.

Use `picto("door")`, `.picto-btn`, `.picture-card`, and `choice_mark(index)`. Add `is-kid` on player/home/watch bodies.

## Checklist before finishing UI work

- [ ] Padding and gap come from tokens, not magic pixels
- [ ] Adjacent actions sit in `.cluster` or `.console-actions` (never inline with raw text)
- [ ] Inputs have 16px+ type, comfortable padding, visible focus ring
- [ ] Pressable elements use existing button classes
- [ ] Copy in tests still matches (do not restyle by rewriting Spanish strings)
- [ ] Verify the flow in the browser (or curl + screenshots if no browser tools)
